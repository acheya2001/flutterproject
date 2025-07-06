import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../features/constat/models/session_constat_model.dart';
import '../../features/constat/models/conducteur_session_info.dart';
import '../../features/constat/models/proprietaire_info.dart';
import '../../features/conducteur/models/conducteur_info_model.dart';
import '../../features/conducteur/models/vehicule_accident_model.dart';
import '../../features/conducteur/models/assurance_info_model.dart';
import '../../features/constat/models/temoin_model.dart';

class SessionService {
  // Simulation d'une base de données locale
  static final Map<String, SessionConstatModel> _sessions = {};
  static final Map<String, String> _sessionCodes = {}; // code -> sessionId

  Future<String> creerSession(SessionConstatModel session) async {
    try {
      // Simuler un délai réseau
      await Future.delayed(const Duration(milliseconds: 500));
      
      final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
      final sessionWithId = session.copyWith(id: sessionId);
      
      _sessions[sessionId] = sessionWithId;
      _sessionCodes[session.sessionCode] = sessionId;
      
      debugPrint('Session créée: $sessionId avec code ${session.sessionCode}');
      return sessionId;
    } catch (e) {
      debugPrint('Erreur création session: $e');
      rethrow;
    }
  }

  Future<SessionConstatModel> getSession(String sessionId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      final session = _sessions[sessionId];
      if (session == null) {
        throw Exception('Session non trouvée pour ID: $sessionId');
      }
      
      return session;
    } catch (e) {
      debugPrint('Erreur récupération session: $e');
      rethrow;
    }
  }

  Future<SessionConstatModel> getSessionByCode(String sessionCode) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      final sessionId = _sessionCodes[sessionCode];
      if (sessionId == null) {
        throw Exception('Code de session invalide ou session non trouvée pour code: $sessionCode');
      }
      
      return getSession(sessionId);
    } catch (e) {
      debugPrint('Erreur récupération session par code: $e');
      rethrow;
    }
  }

  Future<SessionConstatModel> rejoindreSession(String sessionCode, String userId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final session = await getSessionByCode(sessionCode);
      
      String? positionToJoin;
      // Find an available position for the joining user
      // Prefer invited positions first
      for (var entry in session.conducteursInfo.entries) {
        if (entry.value.isInvited && entry.value.email != null /* could check email match if needed */ && !entry.value.hasJoined) {
          positionToJoin = entry.key;
          break;
        }
      }
      // If no invited spot, find any non-joined spot (if logic allows open joining)
      if (positionToJoin == null) {
        for (var entry in session.conducteursInfo.entries) {
          if (!entry.value.hasJoined) { // Simplified: any non-joined spot
            positionToJoin = entry.key;
            break;
          }
        }
      }
      
      if (positionToJoin == null) {
        throw Exception('Aucune place disponible ou invitation correspondante dans cette session.');
      }
      
      final conducteurInfoToUpdate = session.conducteursInfo[positionToJoin]!;
      final updatedInfo = conducteurInfoToUpdate.copyWith(
        userId: userId, // Assign the joining user's ID
        hasJoined: true,
        joinedAt: DateTime.now(),
      );
      
      final updatedConducteursInfo = Map<String, ConducteurSessionInfo>.from(session.conducteursInfo);
      updatedConducteursInfo[positionToJoin] = updatedInfo;
      
      final updatedSession = session.copyWith(
        conducteursInfo: updatedConducteursInfo,
        updatedAt: DateTime.now(),
      );
      
      _sessions[session.id] = updatedSession;
      debugPrint('Utilisateur $userId a rejoint la session $sessionCode en tant que conducteur $positionToJoin');
      return updatedSession;
    } catch (e) {
      debugPrint('Erreur rejoindre session: $e');
      rethrow;
    }
  }

  Future<void> sauvegarderConducteur({
    required String sessionId,
    required String position,
    required ConducteurInfoModel conducteurInfo, // From conducteur/models
    required VehiculeAccidentModel vehiculeInfo, // From conducteur/models
    required AssuranceInfoModel assuranceInfo,   // From conducteur/models
    required bool isProprietaire,
    ProprietaireInfo? proprietaireInfo,
    required List<int> circonstances,
    required List<String> degatsApparents,
    required List<TemoinModel> temoins,
    required List<File> photosAccident, // These would be uploaded and URLs stored
    File? photoPermis,
    File? photoCarteGrise,
    File? photoAttestation,
    Uint8List? signature, // This would be uploaded and URL stored
    required String observations,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      
      final session = _sessions[sessionId];
      if (session == null) {
        throw Exception('Session non trouvée pour sauvegarde conducteur');
      }
      
      // Simuler l'upload des fichiers et obtenir des URLs (non implémenté ici)
      // List<String> photosAccidentUrls = await _uploadFiles(photosAccident);
      // String? photoPermisUrl = photoPermis != null ? await _uploadFile(photoPermis) : null;
      // ... etc. for other files and signature

      final conducteurSessionInfoToUpdate = session.conducteursInfo[position];
      if (conducteurSessionInfoToUpdate == null) {
        throw Exception('Position $position non trouvée dans la session $sessionId');
      }

      final updatedInfo = conducteurSessionInfoToUpdate.copyWith(
        conducteurInfo: conducteurInfo, // This is now correctly typed
        vehiculeInfo: vehiculeInfo,     // This is now correctly typed
        assuranceInfo: assuranceInfo,   // This is now correctly typed
        isProprietaire: isProprietaire,
        proprietaireInfo: proprietaireInfo, // This will be null if isProprietaire is true and proprietaireInfo is not provided
        circonstances: circonstances,
        degatsApparents: degatsApparents,
        temoins: temoins,
        observations: observations,
        // photosAccidentUrls: photosAccidentUrls,
        // photoPermisUrl: photoPermisUrl,
        // ... etc. for other URLs
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      
      final updatedConducteursInfo = Map<String, ConducteurSessionInfo>.from(session.conducteursInfo);
      updatedConducteursInfo[position] = updatedInfo;

      final updatedSession = session.copyWith(
        conducteursInfo: updatedConducteursInfo,
        updatedAt: DateTime.now(),
      );
      
      _sessions[sessionId] = updatedSession;
      debugPrint('Conducteur $position sauvegardé dans session $sessionId');
    } catch (e) {
      debugPrint('Erreur sauvegarde conducteur: $e');
      rethrow;
    }
  }

  /// Marque un conducteur comme ayant rejoint la session
  Future<void> marquerConducteurRejoint(String sessionId, String position, String userId) async {
    try {
      debugPrint('[SessionService] Marquage conducteur rejoint: $position dans session $sessionId pour user $userId');
      await Future.delayed(const Duration(milliseconds: 300));

      final session = _sessions[sessionId];
      if (session == null) {
        throw Exception('Session non trouvée pour ID: $sessionId');
      }

      final conducteurInfo = session.conducteursInfo[position];
      if (conducteurInfo == null) {
        throw Exception('Position $position non trouvée dans la session');
      }

      final updatedInfo = conducteurInfo.copyWith(
        userId: userId,
        hasJoined: true,
        joinedAt: DateTime.now(),
      );

      final updatedConducteursInfo = Map<String, ConducteurSessionInfo>.from(session.conducteursInfo);
      updatedConducteursInfo[position] = updatedInfo;

      final updatedSession = session.copyWith(
        conducteursInfo: updatedConducteursInfo,
        updatedAt: DateTime.now(),
      );

      _sessions[sessionId] = updatedSession;
      debugPrint('[SessionService] Conducteur marqué comme rejoint avec succès');
    } catch (e) {
      debugPrint('[SessionService] Erreur marquage conducteur: $e');
      rethrow;
    }
  }
}
