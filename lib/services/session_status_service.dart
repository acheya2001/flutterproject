import 'package:cloud_firestore/cloud_firestore.dart';

/// 📊 Service pour gérer les statuts de session intelligents
class SessionStatusService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📊 Statuts de session possibles
  static const String STATUS_EN_ATTENTE_PARTICIPANTS = 'en_attente_participants';
  static const String STATUS_EN_COURS_REMPLISSAGE = 'en_cours_remplissage';
  static const String STATUS_TERMINE = 'termine';
  static const String STATUS_ENVOYE_AGENCE = 'envoye_agence';

  /// 🔄 Mettre à jour le statut d'une session selon les participants
  static Future<void> updateSessionStatus(String sessionId) async {
    try {
      final sessionDoc = await _firestore
          .collection('accident_sessions_complete')
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) return;

      final sessionData = sessionDoc.data()!;
      final participants = List<Map<String, dynamic>>.from(
        sessionData['participants'] ?? []
      );

      final newStatus = _calculateSessionStatus(participants);
      
      await _firestore
          .collection('accident_sessions_complete')
          .doc(sessionId)
          .update({
        'statut': newStatus,
        'lastStatusUpdate': FieldValue.serverTimestamp(),
      });

      // Si terminé, créer le sinistre
      if (newStatus == STATUS_TERMINE) {
        await _createSinistreFromSession(sessionId, sessionData);
      }
    } catch (e) {
      print('❌ Erreur mise à jour statut session: $e');
    }
  }

  /// 📊 Calculer le statut selon les participants
  static String _calculateSessionStatus(List<Map<String, dynamic>> participants) {
    if (participants.isEmpty) {
      return STATUS_EN_ATTENTE_PARTICIPANTS;
    }

    final totalParticipants = participants.length;
    final participantsRejoints = participants.where((p) => p['aRejoint'] == true).length;
    final participantsTermines = participants.where((p) => p['formulaireComplete'] == true).length;

    if (participantsTermines == totalParticipants && totalParticipants > 0) {
      return STATUS_TERMINE;
    } else if (participantsRejoints == totalParticipants && totalParticipants > 0) {
      return STATUS_EN_COURS_REMPLISSAGE;
    } else {
      return STATUS_EN_ATTENTE_PARTICIPANTS;
    }
  }

  /// 🚨 Créer un sinistre à partir d'une session terminée
  static Future<void> _createSinistreFromSession(
    String sessionId, 
    Map<String, dynamic> sessionData
  ) async {
    try {
      final participants = List<Map<String, dynamic>>.from(
        sessionData['participants'] ?? []
      );

      // Créer un sinistre pour chaque participant
      for (final participant in participants) {
        final agenceId = participant['agenceId'];
        if (agenceId != null) {
          await _firestore
              .collection('agences')
              .doc(agenceId)
              .collection('sinistres_recus')
              .add({
            'sessionId': sessionId,
            'participantId': participant['id'],
            'dateReception': FieldValue.serverTimestamp(),
            'statut': 'nouveau',
            'traite': false,
            'sessionData': sessionData,
            'participantData': participant,
          });
        }
      }

      // Marquer la session comme envoyée
      await _firestore
          .collection('accident_sessions_complete')
          .doc(sessionId)
          .update({
        'statut': STATUS_ENVOYE_AGENCE,
        'dateEnvoi': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Erreur création sinistre: $e');
    }
  }

  /// 👤 Ajouter un participant à une session
  static Future<void> addParticipantToSession({
    required String sessionId,
    required Map<String, dynamic> participantData,
  }) async {
    try {
      final sessionRef = _firestore
          .collection('accident_sessions_complete')
          .doc(sessionId);

      await _firestore.runTransaction((transaction) async {
        final sessionDoc = await transaction.get(sessionRef);
        
        if (!sessionDoc.exists) {
          throw Exception('Session non trouvée');
        }

        final sessionData = sessionDoc.data()!;
        final participants = List<Map<String, dynamic>>.from(
          sessionData['participants'] ?? []
        );

        // Vérifier si le participant n'existe pas déjà
        final existingIndex = participants.indexWhere(
          (p) => p['id'] == participantData['id']
        );

        if (existingIndex >= 0) {
          // Mettre à jour le participant existant
          participants[existingIndex] = {
            ...participants[existingIndex],
            ...participantData,
            'aRejoint': true,
            'dateRejoint': FieldValue.serverTimestamp(),
          };
        } else {
          // Ajouter un nouveau participant
          participants.add({
            ...participantData,
            'aRejoint': true,
            'dateRejoint': FieldValue.serverTimestamp(),
            'formulaireComplete': false,
          });
        }

        transaction.update(sessionRef, {
          'participants': participants,
          'lastUpdate': FieldValue.serverTimestamp(),
        });
      });

      // Mettre à jour le statut de la session
      await updateSessionStatus(sessionId);
    } catch (e) {
      throw Exception('Erreur ajout participant: $e');
    }
  }

  /// ✅ Marquer le formulaire d'un participant comme terminé
  static Future<void> markParticipantFormComplete({
    required String sessionId,
    required String participantId,
    required Map<String, dynamic> formData,
  }) async {
    try {
      final sessionRef = _firestore
          .collection('accident_sessions_complete')
          .doc(sessionId);

      await _firestore.runTransaction((transaction) async {
        final sessionDoc = await transaction.get(sessionRef);
        
        if (!sessionDoc.exists) {
          throw Exception('Session non trouvée');
        }

        final sessionData = sessionDoc.data()!;
        final participants = List<Map<String, dynamic>>.from(
          sessionData['participants'] ?? []
        );

        // Trouver et mettre à jour le participant
        final participantIndex = participants.indexWhere(
          (p) => p['id'] == participantId
        );

        if (participantIndex >= 0) {
          participants[participantIndex] = {
            ...participants[participantIndex],
            'formulaireComplete': true,
            'formData': formData,
            'dateCompletion': FieldValue.serverTimestamp(),
          };

          transaction.update(sessionRef, {
            'participants': participants,
            'lastUpdate': FieldValue.serverTimestamp(),
          });
        }
      });

      // Mettre à jour le statut de la session
      await updateSessionStatus(sessionId);
    } catch (e) {
      throw Exception('Erreur completion formulaire: $e');
    }
  }

  /// 📱 Obtenir le statut d'une session en temps réel
  static Stream<Map<String, dynamic>> getSessionStatusStream(String sessionId) {
    return _firestore
        .collection('accident_sessions_complete')
        .doc(sessionId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return {'exists': false};
      }

      final data = doc.data()!;
      final participants = List<Map<String, dynamic>>.from(
        data['participants'] ?? []
      );

      final totalParticipants = participants.length;
      final participantsRejoints = participants.where((p) => p['aRejoint'] == true).length;
      final participantsTermines = participants.where((p) => p['formulaireComplete'] == true).length;

      return {
        'exists': true,
        'statut': data['statut'] ?? STATUS_EN_ATTENTE_PARTICIPANTS,
        'totalParticipants': totalParticipants,
        'participantsRejoints': participantsRejoints,
        'participantsTermines': participantsTermines,
        'participants': participants,
        'sessionData': data,
      };
    });
  }

  /// 🏷️ Obtenir le libellé d'un statut
  static String getStatusLabel(String status) {
    switch (status) {
      case STATUS_EN_ATTENTE_PARTICIPANTS:
        return 'En attente des participants';
      case STATUS_EN_COURS_REMPLISSAGE:
        return 'En cours de remplissage';
      case STATUS_TERMINE:
        return 'Terminé';
      case STATUS_ENVOYE_AGENCE:
        return 'Envoyé à l\'agence';
      default:
        return 'Statut inconnu';
    }
  }

  /// 🎨 Obtenir la couleur d'un statut
  static String getStatusColor(String status) {
    switch (status) {
      case STATUS_EN_ATTENTE_PARTICIPANTS:
        return 'orange';
      case STATUS_EN_COURS_REMPLISSAGE:
        return 'blue';
      case STATUS_TERMINE:
        return 'green';
      case STATUS_ENVOYE_AGENCE:
        return 'purple';
      default:
        return 'grey';
    }
  }

  /// 📊 Obtenir les statistiques d'une session
  static Future<Map<String, dynamic>> getSessionStats(String sessionId) async {
    try {
      final sessionDoc = await _firestore
          .collection('accident_sessions_complete')
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) {
        return {'error': 'Session non trouvée'};
      }

      final data = sessionDoc.data()!;
      final participants = List<Map<String, dynamic>>.from(
        data['participants'] ?? []
      );

      return {
        'sessionId': sessionId,
        'codePublic': data['codePublic'],
        'statut': data['statut'],
        'dateCreation': data['dateOuverture'],
        'totalParticipants': participants.length,
        'participantsRejoints': participants.where((p) => p['aRejoint'] == true).length,
        'participantsTermines': participants.where((p) => p['formulaireComplete'] == true).length,
        'progression': participants.isEmpty ? 0 : 
            (participants.where((p) => p['formulaireComplete'] == true).length / participants.length * 100).round(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
