import 'dart:io';
import 'package:flutter/foundation.dart'; // Provides Uint8List and ChangeNotifier
import '../models/session_constat_model.dart';
import '../models/conducteur_session_info.dart';
import '../models/proprietaire_info.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/firebase_email_service.dart';
import '../../conducteur/models/conducteur_info_model.dart';
import '../../conducteur/models/vehicule_accident_model.dart';
import '../../conducteur/models/assurance_info_model.dart';
import '../../constat/models/temoin_model.dart';

class SessionProvider with ChangeNotifier {
  final SessionService _sessionService;

  // Constructeur simplifié
  SessionProvider({
    required SessionService sessionService,
  }) : _sessionService = sessionService;

  // Variables d'état simplifiées

  SessionConstatModel? _currentSession;
  SessionConstatModel? get currentSession => _currentSession;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  Future<String?> creerSession({
    required int nombreConducteurs,
    required List<String> emailsInvites,
    required String createdBy, // ID de l'utilisateur créateur
    String? userEmail, // Email de l'utilisateur créateur, si disponible
    DateTime? dateAccident,
    String? lieuAccident,
  }) async {
    debugPrint('[SessionProvider] === DÉBUT CRÉATION SESSION ===');
    debugPrint('[SessionProvider] Paramètres: nombreConducteurs=$nombreConducteurs, emails=$emailsInvites');
    _setLoading(true);
    _setError(null);
    try {
      debugPrint('[SessionProvider] Génération du code session...');
      final sessionCode = _genererCodeSession();
      debugPrint('[SessionProvider] Code généré: $sessionCode');
      final now = DateTime.now();

      debugPrint('[SessionProvider] Création des infos conducteurs...');
      Map<String, ConducteurSessionInfo> conducteursInfo = {};

      conducteursInfo['A'] = ConducteurSessionInfo(
        position: 'A',
        userId: createdBy,
        email: userEmail, // Email du créateur
        isInvited: false,
        hasJoined: true,
        isCompleted: false,
        joinedAt: now,
        isProprietaire: true,
      );
      debugPrint('[SessionProvider] Conducteur A créé');

      final positions = ['B', 'C', 'D', 'E', 'F'];
      for (int i = 0; i < nombreConducteurs - 1; i++) {
        if (i >= positions.length) break;
        final position = positions[i];
        final email = i < emailsInvites.length ? emailsInvites[i].trim() : null;
        
        conducteursInfo[position] = ConducteurSessionInfo(
          position: position,
          userId: null,
          email: email,
          isInvited: email != null && email.isNotEmpty,
          hasJoined: false,
          isCompleted: false,
          isProprietaire: true,
        );
      }

      final session = SessionConstatModel(
        id: '', 
        sessionCode: sessionCode,
        dateAccident: dateAccident ?? now,
        lieuAccident: lieuAccident ?? '',
        nombreConducteurs: nombreConducteurs,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
        status: SessionStatus.draft,
        conducteursInfo: conducteursInfo,
        invitationsSent: emailsInvites.where((e) => e.isNotEmpty).toList(),
        validationStatus: {},
      );

      debugPrint('[SessionProvider] Appel SessionService.creerSession...');
      final sessionId = await _sessionService.creerSession(session);
      debugPrint('[SessionProvider] Session créée avec ID: $sessionId');
      _currentSession = session.copyWith(id: sessionId);

      debugPrint('[SessionProvider] Envoi des invitations...');
      for (String email in emailsInvites) {
        if (email.isNotEmpty) {
          debugPrint('[SessionProvider] Envoi invitation à: $email');

          // 🔥 Utiliser Firebase + SendGrid amélioré (fonctionne maintenant)
          debugPrint('[SessionProvider] 🔥 Envoi avec Firebase + SendGrid amélioré...');
          await FirebaseEmailService.envoyerInvitation(
            email: email,
            sessionCode: sessionCode,
            sessionId: sessionId,
          );

          debugPrint('[SessionProvider] ✅ Invitation traitée pour: $email');

          debugPrint('[SessionProvider] Invitation traitée pour: $email');
        }
      }

      debugPrint('[SessionProvider] Finalisation...');
      _setLoading(false);
      notifyListeners();
      debugPrint('[SessionProvider] === SESSION CRÉÉE AVEC SUCCÈS ===');
      return sessionId;
    } catch (e) {
      _setError('Erreur création session: $e');
      _setLoading(false);
      debugPrint('Erreur création session: $e');
      return null;
    }
  }

  Future<SessionConstatModel?> getSession(String sessionId) async {
    _setLoading(true);
    _setError(null);
    try {
      final session = await _sessionService.getSession(sessionId);
      _currentSession = session;
      _setLoading(false);
      notifyListeners();
      return session;
    } catch (e) {
      _setError('Erreur récupération session: $e');
      _setLoading(false);
      debugPrint('Erreur récupération session: $e');
      return null;
    }
  }
  
  Future<SessionConstatModel?> getSessionByCode(String sessionCode) async {
    _setLoading(true);
    _setError(null);
    try {
      final session = await _sessionService.getSessionByCode(sessionCode);
      _currentSession = session;
      _setLoading(false);
      notifyListeners();
      return session;
    } catch (e) {
      _setError('Erreur récupération session par code: $e');
      _setLoading(false);
      debugPrint('Erreur récupération session par code: $e');
      return null;
    }
  }

  /// Recherche une session par son code
  Future<SessionConstatModel?> rechercherSessionParCode(String sessionCode) async {
    try {
      debugPrint('[SessionProvider] Recherche session par code: $sessionCode');
      final session = await _sessionService.getSessionByCode(sessionCode);
      debugPrint('[SessionProvider] Session trouvée: ${session.id}');
      return session;
    } catch (e) {
      debugPrint('[SessionProvider] Erreur recherche session: $e');
      return null;
    }
  }

  /// Marque un conducteur comme ayant rejoint la session
  Future<void> marquerConducteurRejoint({
    required String sessionId,
    required String position,
    required String userId,
  }) async {
    try {
      debugPrint('[SessionProvider] Marquage conducteur rejoint: $position dans session $sessionId');
      await _sessionService.marquerConducteurRejoint(sessionId, position, userId);

      // Mettre à jour la session locale si c'est la session courante
      if (_currentSession?.id == sessionId) {
        final updatedInfo = _currentSession!.conducteursInfo[position]?.copyWith(
          hasJoined: true,
          joinedAt: DateTime.now(),
          userId: userId,
        );

        if (updatedInfo != null) {
          final updatedConducteurs = Map<String, ConducteurSessionInfo>.from(_currentSession!.conducteursInfo);
          updatedConducteurs[position] = updatedInfo;

          _currentSession = _currentSession!.copyWith(conducteursInfo: updatedConducteurs);
          notifyListeners();
        }
      }

      debugPrint('[SessionProvider] Conducteur marqué comme rejoint avec succès');
    } catch (e) {
      debugPrint('[SessionProvider] Erreur marquage conducteur: $e');
      rethrow;
    }
  }

  Future<SessionConstatModel?> rejoindreSession(String sessionCode, String userId) async {
    _setLoading(true);
    _setError(null);
    try {
      // Note: SessionService.rejoindreSession devrait mettre à jour le statut du conducteur dans Firestore
      final session = await _sessionService.rejoindreSession(sessionCode, userId);
      _currentSession = session;
      _setLoading(false);
      notifyListeners();
      return session;
    } catch (e) {
      _setError('Erreur rejoindre session: $e');
      _setLoading(false);
      debugPrint('Erreur rejoindre session: $e');
      return null;
    }
  }

  Future<bool> sauvegarderConducteurDansSession({
    required String sessionId,
    required String position,
    required ConducteurInfoModel conducteurInfo,
    required VehiculeAccidentModel vehiculeInfo,
    required AssuranceInfoModel assuranceInfo,
    required bool isProprietaire,
    ProprietaireInfo? proprietaireInfo,
    required List<int> circonstances,
    required List<String> degatsApparents,
    required List<TemoinModel> temoins,
    required List<File> photosAccident, // Liste de fichiers pour les photos
    File? photoPermis,
    File? photoCarteGrise,
    File? photoAttestation, // Paramètre ajouté
    Uint8List? signature, // Bytes pour la signature
    required String observations,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      // SessionService.sauvegarderConducteur devrait gérer l'upload des fichiers
      // et retourner les URLs pour mettre à jour ConducteurSessionInfo
      await _sessionService.sauvegarderConducteur(
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
        photosAccident: photosAccident, // Transmettre la liste de fichiers
        photoPermis: photoPermis,
        photoCarteGrise: photoCarteGrise,
        photoAttestation: photoAttestation, // Transmettre le fichier
        signature: signature, // Transmettre les bytes
        observations: observations,
      );

      // Après la sauvegarde, il est préférable de re-fetch la session pour avoir les données à jour
      // y compris les URLs des fichiers uploadés.
      final updatedSession = await _sessionService.getSession(sessionId);
      _currentSession = updatedSession;
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur sauvegarde conducteur: $e');
      _setLoading(false);
      debugPrint('Erreur sauvegarde conducteur: $e');
      return false;
    }
  }

  String _genererCodeSession() {
    final now = DateTime.now();
    final randomPart = (DateTime.now().microsecondsSinceEpoch % 100000).toString().padLeft(5, '0');
    return 'CS${now.year%100}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}$randomPart';
  }

  void clearSession() {
    _currentSession = null;
    notifyListeners();
  }
}