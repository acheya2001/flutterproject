import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/session_constat_model.dart';
import '../models/conducteur_session_info.dart';
import '../models/proprietaire_info.dart';
import '../../../core/services/email_service.dart';
import '../../../core/services/session_service.dart';
import '../../conducteur/models/conducteur_info_model.dart';
import '../../conducteur/models/vehicule_accident_model.dart';
import '../../conducteur/models/assurance_info_model.dart';
import '../../conducteur/models/temoin_model.dart';

class SessionProvider with ChangeNotifier {
  final SessionService _sessionService = SessionService();
  final EmailService _emailService = EmailService();

  SessionConstatModel? _currentSession;
  SessionConstatModel? get currentSession => _currentSession;

  Future<String> creerSession({
    required int nombreConducteurs,
    required List<String> emailsInvites,
    required String createdBy,
  }) async {
    try {
      final sessionCode = _genererCodeSession();
      final now = DateTime.now();

      // Créer les infos des conducteurs
      Map<String, ConducteurSessionInfo> conducteursInfo = {};
      
      // Conducteur A (créateur)
      conducteursInfo['A'] = ConducteurSessionInfo(
        position: 'A',
        userId: createdBy,
        isInvited: false,
        hasJoined: true,
        isCompleted: false,
        joinedAt: now,
        isProprietaire: true,
      );

      // Autres conducteurs
      final positions = ['B', 'C', 'D', 'E', 'F'];
      for (int i = 0; i < nombreConducteurs - 1; i++) {
        final position = positions[i];
        final email = i < emailsInvites.length ? emailsInvites[i] : null;
        
        conducteursInfo[position] = ConducteurSessionInfo(
          position: position,
          email: email,
          isInvited: email != null,
          hasJoined: false,
          isCompleted: false,
          isProprietaire: true,
        );
      }

      final session = SessionConstatModel(
        id: '',
        sessionCode: sessionCode,
        dateAccident: now,
        lieuAccident: '',
        nombreConducteurs: nombreConducteurs,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
        status: SessionStatus.draft,
        conducteursInfo: conducteursInfo,
        invitationsSent: emailsInvites,
        validationStatus: {},
      );

      final sessionId = await _sessionService.creerSession(session);

      // Envoyer les invitations par email
      for (String email in emailsInvites) {
        await _emailService.envoyerInvitation(
          email: email,
          sessionCode: sessionCode,
          sessionId: sessionId,
        );
      }

      _currentSession = session.copyWith(id: sessionId);
      notifyListeners();

      return sessionId;
    } catch (e) {
      debugPrint('Erreur création session: $e');
      rethrow;
    }
  }

  Future<SessionConstatModel> getSession(String sessionId) async {
    try {
      final session = await _sessionService.getSession(sessionId);
      _currentSession = session;
      notifyListeners();
      return session;
    } catch (e) {
      debugPrint('Erreur récupération session: $e');
      rethrow;
    }
  }

  Future<SessionConstatModel> rejoindreSession(String sessionCode, String userId) async {
    try {
      final session = await _sessionService.rejoindreSession(sessionCode, userId);
      _currentSession = session;
      notifyListeners();
      return session;
    } catch (e) {
      debugPrint('Erreur rejoindre session: $e');
      rethrow;
    }
  }

  Future<void> sauvegarderConducteurDansSession({
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
    required List<File> photosAccident,
    File? photoPermis,
    File? photoCarteGrise,
    File? photoAttestation,
    Uint8List? signature,
    required String observations,
  }) async {
    try {
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
        photosAccident: photosAccident,
        photoPermis: photoPermis,
        photoCarteGrise: photoCarteGrise,
        photoAttestation: photoAttestation,
        signature: signature,
        observations: observations,
      );

      // Mettre à jour la session locale
      if (_currentSession?.id == sessionId) {
        final updatedInfo = _currentSession!.conducteursInfo[position]?.copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
          conducteurInfo: conducteurInfo,
          vehiculeInfo: vehiculeInfo,
          assuranceInfo: assuranceInfo,
          isProprietaire: isProprietaire,
          proprietaireInfo: proprietaireInfo,
          circonstances: circonstances,
          degatsApparents: degatsApparents,
          observations: observations,
        );

        if (updatedInfo != null) {
          _currentSession = _currentSession!.copyWith(
            conducteursInfo: {
              ..._currentSession!.conducteursInfo,
              position: updatedInfo,
            },
          );
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Erreur sauvegarde conducteur: $e');
      rethrow;
    }
  }

  String _genererCodeSession() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString();
    final random = (timestamp.hashCode % 100000).toString().padLeft(5, '0');
    return 'SESS_$random';
  }

  void clearSession() {
    _currentSession = null;
    notifyListeners();
  }
}
