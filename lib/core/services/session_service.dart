import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../features/constat/models/session_constat_model.dart'; // Adjusted path
import '../../features/constat/models/conducteur_info_model.dart'; // Adjusted path
import '../../features/constat/models/vehicule_accident_model.dart'; // Adjusted path
import '../../features/constat/models/assurance_info_model.dart'; // Adjusted path
import '../../features/constat/models/temoin_model.dart ';
import '../../features/constat/models/proprietaire_info.dart'; // Adjusted path

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
      
      debugPrint('Session créée: $sessionId');
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
        throw Exception('Session non trouvée');
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
        throw Exception('Code de session invalide');
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
      
      // Trouver la position du conducteur
      String? position;
      for (var entry in session.conducteursInfo.entries) {
        if (entry.value.email != null && !entry.value.hasJoined) {
          position = entry.key;
          break;
        }
      }
      
      if (position == null) {
        throw Exception('Aucune place disponible dans cette session');
      }
      
      // Marquer comme rejoint
      final updatedInfo = session.conducteursInfo[position]!.copyWith(
        userId: userId,
        hasJoined: true,
        joinedAt: DateTime.now(),
      );
      
      final updatedSession = session.copyWith(
        conducteursInfo: {
          ...session.conducteursInfo,
          position: updatedInfo,
        },
      );
      
      _sessions[session.id] = updatedSession;
      
      return updatedSession;
    } catch (e) {
      debugPrint('Erreur rejoindre session: $e');
      rethrow;
    }
  }

  Future<void> sauvegarderConducteur({
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
      await Future.delayed(const Duration(milliseconds: 800));
      
      final session = _sessions[sessionId];
      if (session == null) {
        throw Exception('Session non trouvée');
      }
      
      // Simuler l'upload des fichiers
      if (photosAccident.isNotEmpty) {
        debugPrint('Upload de ${photosAccident.length} photos d\'accident');
      }
      if (photoPermis != null) {
        debugPrint('Upload photo permis');
      }
      if (photoCarteGrise != null) {
        debugPrint('Upload photo carte grise');
      }
      if (photoAttestation != null) {
        debugPrint('Upload photo attestation');
      }
      if (signature != null) {
        debugPrint('Upload signature');
      }
      
      // Mettre à jour les informations du conducteur
      final updatedInfo = session.conducteursInfo[position]?.copyWith(
        conducteurInfo: conducteurInfo,
        vehiculeInfo: vehiculeInfo,
        assuranceInfo: assuranceInfo,
        isProprietaire: isProprietaire,
        proprietaireInfo: proprietaireInfo,
        circonstances: circonstances,
        degatsApparents: degatsApparents,
        observations: observations,
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      
      if (updatedInfo != null) {
        final updatedSession = session.copyWith(
          conducteursInfo: {
            ...session.conducteursInfo,
            position: updatedInfo,
          },
          updatedAt: DateTime.now(),
        );
        
        _sessions[sessionId] = updatedSession;
        debugPrint('Conducteur $position sauvegardé dans session $sessionId');
      }
    } catch (e) {
      debugPrint('Erreur sauvegarde conducteur: $e');
      rethrow;
    }
  }
}