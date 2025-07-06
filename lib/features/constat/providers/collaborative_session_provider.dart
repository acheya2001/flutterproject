import 'package:flutter/foundation.dart';
import '../../../core/services/firestore_session_service.dart';
import '../../../core/services/firebase_email_service.dart';
import '../../../core/exceptions/app_exceptions.dart';
import '../models/session_constat_model.dart';
import '../models/conducteur_session_info.dart';
import '../../conducteur/models/conducteur_info_model.dart';
import '../../conducteur/models/vehicule_accident_model.dart';
import '../../conducteur/models/assurance_info_model.dart';
import '../models/proprietaire_info.dart';
import '../models/temoin_model.dart';

/// 🚀 Provider professionnel pour les sessions collaboratives
/// 
/// Gère l'état et les opérations des sessions collaboratives avec
/// gestion d'erreurs robuste et feedback utilisateur.
class CollaborativeSessionProvider extends ChangeNotifier {
  static final CollaborativeSessionProvider _instance = CollaborativeSessionProvider._internal();
  factory CollaborativeSessionProvider() => _instance;
  CollaborativeSessionProvider._internal();

  final FirestoreSessionService _sessionService = FirestoreSessionService();

  // État du provider
  SessionConstatModel? _currentSession;
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  // Getters
  SessionConstatModel? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;
  bool get hasSession => _currentSession != null;

  /// 🔄 Met à jour l'état de chargement
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// ❌ Met à jour l'erreur
  void _setError(String? error) {
    _error = error;
    _successMessage = null;
    notifyListeners();
  }

  /// ✅ Met à jour le message de succès
  void _setSuccess(String? message) {
    _successMessage = message;
    _error = null;
    notifyListeners();
  }

  /// 🧹 Efface les messages
  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  /// 📝 Crée une nouvelle session collaborative
  Future<String?> creerSessionCollaborative({
    required int nombreConducteurs,
    required List<String> emailsInvites,
    required String createdBy,
    String? userEmail,
    DateTime? dateAccident,
    String? lieuAccident,
    Map<String, dynamic>? coordonnees,
  }) async {
    try {
      debugPrint('[CollaborativeSession] === CRÉATION SESSION ===');
      _setLoading(true);
      clearMessages();

      // Validation des paramètres
      if (nombreConducteurs < 2 || nombreConducteurs > 6) {
        throw const DataValidationException('Le nombre de conducteurs doit être entre 2 et 6');
      }

      if (emailsInvites.length != nombreConducteurs - 1) {
        throw const DataValidationException('Nombre d\'emails incorrect');
      }

      // Validation des emails
      for (final email in emailsInvites) {
        if (!_isValidEmail(email)) {
          throw InvalidEmailException(email);
        }
      }

      // Génération du code de session
      final sessionCode = _generateSessionCode();
      final now = DateTime.now();

      // Construction des informations des conducteurs
      final Map<String, ConducteurSessionInfo> conducteursInfo = {};

      // Conducteur A (créateur)
      conducteursInfo['A'] = ConducteurSessionInfo(
        position: 'A',
        userId: createdBy,
        email: userEmail,
        isInvited: false,
        hasJoined: true,
        isCompleted: false,
        joinedAt: now,
        isProprietaire: true,
      );

      // Autres conducteurs (invités)
      final positions = ['B', 'C', 'D', 'E', 'F'];
      for (int i = 0; i < nombreConducteurs - 1; i++) {
        final position = positions[i];
        final email = emailsInvites[i].trim();

        conducteursInfo[position] = ConducteurSessionInfo(
          position: position,
          userId: null,
          email: email,
          isInvited: true,
          hasJoined: false,
          isCompleted: false,
          isProprietaire: true,
        );
      }

      // Création du modèle de session
      final session = SessionConstatModel(
        id: '', // Sera défini par Firestore
        sessionCode: sessionCode,
        dateAccident: dateAccident ?? now,
        lieuAccident: lieuAccident ?? '',
        coordonnees: coordonnees,
        nombreConducteurs: nombreConducteurs,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
        status: SessionStatus.draft,
        conducteursInfo: conducteursInfo,
        invitationsSent: emailsInvites,
        validationStatus: {},
      );

      // Sauvegarde dans Firestore
      final sessionId = await _sessionService.creerSessionCollaborative(session);
      _currentSession = session.copyWith(id: sessionId);

      // Envoi des invitations par email
      await _envoyerInvitations(sessionCode, sessionId, emailsInvites);

      _setSuccess('Session créée avec succès ! Invitations envoyées.');
      debugPrint('[CollaborativeSession] ✅ Session créée: $sessionId');
      
      return sessionId;

    } on AppException catch (e) {
      debugPrint('[CollaborativeSession] ❌ Erreur métier: ${e.message}');
      _setError(ExceptionHandler.getLocalizedMessage(e));
      return null;
    } catch (e) {
      debugPrint('[CollaborativeSession] ❌ Erreur inattendue: $e');
      final appException = ExceptionHandler.handleFirebaseError(e);
      _setError(ExceptionHandler.getLocalizedMessage(appException));
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// 🚪 Rejoint une session existante
  Future<SessionConstatModel?> rejoindreSession(String sessionCode, String userId) async {
    try {
      debugPrint('[CollaborativeSession] === REJOINDRE SESSION ===');
      _setLoading(true);
      clearMessages();

      // Validation du code
      if (sessionCode.trim().isEmpty) {
        throw const InvalidSessionCodeException('Code vide');
      }

      // Recherche et jointure de la session
      final session = await _sessionService.rejoindreSession(sessionCode.trim().toUpperCase(), userId);
      
      if (session == null) {
        throw SessionNotFoundException(sessionCode);
      }

      _currentSession = session;
      _setSuccess('Connecté à la session avec succès !');
      
      debugPrint('[CollaborativeSession] ✅ Session rejointe');
      return session;

    } on AppException catch (e) {
      debugPrint('[CollaborativeSession] ❌ Erreur métier: ${e.message}');
      _setError(ExceptionHandler.getLocalizedMessage(e));
      return null;
    } catch (e) {
      debugPrint('[CollaborativeSession] ❌ Erreur inattendue: $e');
      final appException = ExceptionHandler.handleFirebaseError(e);
      _setError(ExceptionHandler.getLocalizedMessage(appException));
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// 💾 Sauvegarde les données d'un conducteur
  Future<bool> sauvegarderDonneesConducteur({
    required String sessionId,
    required String position,
    required ConducteurInfoModel conducteurInfo,
    required VehiculeAccidentModel vehiculeInfo,
    required AssuranceInfoModel assuranceInfo,
    required bool isProprietaire,
    ProprietaireInfo? proprietaireInfo,
    List<String>? circonstances,
    List<String>? degatsApparents,
    List<TemoinModel>? temoins,
    List<String>? photosAccidentUrls,
    String? photoPermisUrl,
    String? photoCarteGriseUrl,
    String? photoAttestationUrl,
    String? signatureUrl,
    String? observations,
  }) async {
    try {
      debugPrint('[CollaborativeSession] === SAUVEGARDE DONNÉES ===');
      _setLoading(true);
      clearMessages();

      await _sessionService.sauvegarderDonneesConducteur(
        sessionId: sessionId,
        position: position,
        conducteurInfo: conducteurInfo,
        vehiculeInfo: vehiculeInfo,
        assuranceInfo: assuranceInfo,
        isProprietaire: isProprietaire,
        proprietaireInfo: proprietaireInfo,
        circonstances: circonstances,
        degatsApparents: degatsApparents,
        temoins: temoins,
        photosAccidentUrls: photosAccidentUrls,
        photoPermisUrl: photoPermisUrl,
        photoCarteGriseUrl: photoCarteGriseUrl,
        photoAttestationUrl: photoAttestationUrl,
        signatureUrl: signatureUrl,
        observations: observations,
      );

      // Vérifier si la session est complète
      final isComplete = await _sessionService.verifierSessionComplete(sessionId);
      
      if (isComplete) {
        _setSuccess('Constat terminé ! Tous les conducteurs ont validé leurs informations.');
      } else {
        _setSuccess('Données sauvegardées avec succès !');
      }

      debugPrint('[CollaborativeSession] ✅ Données sauvegardées');
      return true;

    } on AppException catch (e) {
      debugPrint('[CollaborativeSession] ❌ Erreur métier: ${e.message}');
      _setError(ExceptionHandler.getLocalizedMessage(e));
      return false;
    } catch (e) {
      debugPrint('[CollaborativeSession] ❌ Erreur inattendue: $e');
      final appException = ExceptionHandler.handleFirebaseError(e);
      _setError(ExceptionHandler.getLocalizedMessage(appException));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 📧 Envoie les invitations par email
  Future<void> _envoyerInvitations(String sessionCode, String sessionId, List<String> emails) async {
    for (final email in emails) {
      if (email.trim().isNotEmpty) {
        try {
          await FirebaseEmailService.envoyerInvitation(
            email: email.trim(),
            sessionCode: sessionCode,
            sessionId: sessionId,
            customMessage: 'Un conducteur vous invite à rejoindre une session de constat collaboratif.',
          );
          debugPrint('[CollaborativeSession] ✅ Invitation envoyée à: $email');
        } catch (e) {
          debugPrint('[CollaborativeSession] ❌ Erreur envoi email $email: $e');
          // Continue avec les autres emails même si un échoue
        }
      }
    }
  }

  /// 🔑 Génère un code de session unique
  String _generateSessionCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'SESS_$random';
  }

  /// ✅ Valide le format d'un email
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email.trim());
  }

  /// 🧹 Réinitialise le provider
  void reset() {
    _currentSession = null;
    _isLoading = false;
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  /// 📊 Obtient le statut de la session actuelle
  String getSessionStatus() {
    if (_currentSession == null) return 'Aucune session';
    
    final validatedCount = _currentSession!.validationStatus.values.where((v) => v).length;
    final totalCount = _currentSession!.nombreConducteurs;
    
    return '$validatedCount/$totalCount conducteurs ont terminé';
  }

  /// 🎯 Trouve la position d'un utilisateur dans la session
  String? getUserPosition(String userId) {
    if (_currentSession == null) return null;
    
    for (final entry in _currentSession!.conducteursInfo.entries) {
      if (entry.value.userId == userId) {
        return entry.key;
      }
    }
    return null;
  }
}
