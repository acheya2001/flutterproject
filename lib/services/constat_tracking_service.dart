import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 📊 Service de suivi des constats pour le conducteur
class ConstatTrackingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📋 Récupérer le statut complet d'un constat pour une session
  static Future<Map<String, dynamic>?> getConstatStatus(String sessionId) async {
    try {
      print('🔍 [TRACKING] Recherche statut pour session: $sessionId');

      // 1. Chercher dans les constats finalisés (priorité)
      final constatDoc = await _firestore
          .collection('constats_finalises')
          .doc(sessionId)
          .get();

      if (constatDoc.exists) {
        final data = constatDoc.data()!;
        print('✅ [TRACKING] Constat trouvé dans constats_finalises');

        return {
          'sessionId': sessionId,
          'statut': data['statut'] ?? 'finalise',
          'dateEnvoi': data['dateEnvoi'],
          'agentInfo': data['agentInfo'],
          'expertAssigne': data['expertAssigne'],
          'dateAssignationExpert': data['dateAssignationExpert'],
          'delaiInterventionHeures': data['delaiInterventionHeures'],
          'commentaireAssignation': data['commentaireAssignation'],
          'source': 'constat_finalise',
          'updatedAt': data['updatedAt'],
        };
      }

      // 2. Chercher dans les constats agents (sans orderBy pour éviter l'index)
      final constatAgentQuery = await _firestore
          .collection('constats_agents')
          .where('sessionId', isEqualTo: sessionId)
          .get();

      if (constatAgentQuery.docs.isNotEmpty) {
        // Trier manuellement par date
        final docs = constatAgentQuery.docs;
        docs.sort((a, b) {
          final dateA = a.data()['dateEnvoiPdf'] as Timestamp?;
          final dateB = b.data()['dateEnvoiPdf'] as Timestamp?;
          if (dateA == null || dateB == null) return 0;
          return dateB.compareTo(dateA);
        });

        final constatData = docs.first.data();
        print('✅ [TRACKING] Constat trouvé dans constats_agents');

        return {
          'sessionId': sessionId,
          'statut': 'envoye_agent',
          'dateEnvoi': constatData['dateEnvoiPdf'],
          'agentInfo': {
            'nom': constatData['agentNom'],
            'prenom': constatData['agentPrenom'],
            'email': constatData['agentEmail'],
            'agenceNom': constatData['agenceNom'],
          },
          'source': 'constat_agent',
          'statutTraitement': constatData['statutTraitement'] ?? 'nouveau',
          'dateVu': constatData['dateVu'],
          'dateTraitement': constatData['dateTraitement'],
          'commentairesAgent': constatData['commentairesAgent'],
        };
      }

      // 3. Chercher dans les envois de constats (sans orderBy)
      final envoiQuery = await _firestore
          .collection('envois_constats')
          .where('sessionId', isEqualTo: sessionId)
          .get();

      if (envoiQuery.docs.isNotEmpty) {
        // Trier manuellement par date
        final docs = envoiQuery.docs;
        docs.sort((a, b) {
          final dateA = a.data()['dateEnvoi'] as Timestamp?;
          final dateB = b.data()['dateEnvoi'] as Timestamp?;
          if (dateA == null || dateB == null) return 0;
          return dateB.compareTo(dateA);
        });

        final envoiData = docs.first.data();
        print('✅ [TRACKING] Envoi trouvé dans envois_constats');

        return {
          'sessionId': sessionId,
          'statut': envoiData['statut'] ?? 'envoye',
          'dateEnvoi': envoiData['dateEnvoi'],
          'agentInfo': envoiData['agentInfo'],
          'lu': envoiData['lu'] ?? false,
          'source': 'envoi_constat',
          'statutTraitement': envoiData['statutTraitement'] ?? 'nouveau',
          'dateTraitement': envoiData['dateTraitement'],
          'commentairesAgent': envoiData['commentairesAgent'],
        };
      }

      print('❌ [TRACKING] Aucun constat trouvé pour session: $sessionId');
      return null;

    } catch (e) {
      print('❌ [TRACKING] Erreur récupération statut: $e');
      return null;
    }
  }

  /// 🔧 Récupérer les informations d'assignation d'expert
  static Future<Map<String, dynamic>?> getExpertAssignmentInfo(String sessionId) async {
    try {
      print('🔍 [TRACKING] Recherche assignation expert pour session: $sessionId');

      // 1. Chercher dans les missions d'expertise (sans orderBy)
      final missionQuery = await _firestore
          .collection('missions_expertise')
          .where('sessionId', isEqualTo: sessionId)
          .get();

      if (missionQuery.docs.isNotEmpty) {
        // Trier manuellement par date
        final docs = missionQuery.docs;
        docs.sort((a, b) {
          final dateA = a.data()['dateCreation'] as Timestamp?;
          final dateB = b.data()['dateCreation'] as Timestamp?;
          if (dateA == null || dateB == null) return 0;
          return dateB.compareTo(dateA);
        });

        final missionData = docs.first.data();
        final expertId = missionData['expertId'];

        // Récupérer les détails de l'expert
        final expertDoc = await _firestore
            .collection('users')
            .doc(expertId)
            .get();

        if (expertDoc.exists) {
          final expertData = expertDoc.data()!;
          print('✅ [TRACKING] Mission expertise trouvée');

          return {
            'missionId': docs.first.id,
            'expertId': expertId,
            'expertInfo': {
              'nom': expertData['nom'],
              'prenom': expertData['prenom'],
              'telephone': expertData['telephone'],
              'email': expertData['email'],
              'codeExpert': expertData['codeExpert'],
              'specialites': expertData['specialites'],
            },
            'statutMission': missionData['statut'] ?? 'assignee',
            'dateAssignation': missionData['dateCreation'],
            'delaiIntervention': missionData['delaiIntervention'],
            'commentaire': missionData['commentaire'],
            'progression': missionData['progression'] ?? 0,
            'dateVisite': missionData['dateVisite'],
            'rapportFinal': missionData['rapportFinal'],
            'evaluation': missionData['evaluation'],
            'source': 'mission_expertise',
          };
        }
      }

      // 2. Chercher dans les assignations d'experts (sans orderBy)
      final assignationQuery = await _firestore
          .collection('expert_assignations')
          .where('sessionId', isEqualTo: sessionId)
          .get();

      if (assignationQuery.docs.isNotEmpty) {
        // Trier manuellement par date
        final docs = assignationQuery.docs;
        docs.sort((a, b) {
          final dateA = a.data()['dateAssignation'] as Timestamp?;
          final dateB = b.data()['dateAssignation'] as Timestamp?;
          if (dateA == null || dateB == null) return 0;
          return dateB.compareTo(dateA);
        });

        final assignationData = docs.first.data();
        final expertId = assignationData['expertId'];

        // Récupérer les détails de l'expert
        final expertDoc = await _firestore
            .collection('users')
            .doc(expertId)
            .get();

        if (expertDoc.exists) {
          final expertData = expertDoc.data()!;
          print('✅ [TRACKING] Assignation expert trouvée');

          return {
            'assignationId': docs.first.id,
            'expertId': expertId,
            'expertInfo': {
              'nom': expertData['nom'],
              'prenom': expertData['prenom'],
              'telephone': expertData['telephone'],
              'email': expertData['email'],
              'codeExpert': expertData['codeExpert'],
            },
            'statutMission': assignationData['status'] ?? 'assigne',
            'dateAssignation': assignationData['dateAssignation'],
            'progression': assignationData['progression'] ?? 0,
            'rapportFinal': assignationData['rapportFinal'],
            'evaluation': assignationData['evaluation'],
            'source': 'expert_assignation',
          };
        }
      }

      print('❌ [TRACKING] Aucune assignation expert trouvée pour session: $sessionId');
      return null;

    } catch (e) {
      print('❌ [TRACKING] Erreur récupération assignation expert: $e');
      return null;
    }
  }

  /// 📊 Récupérer le statut complet (constat + expert)
  static Future<Map<String, dynamic>> getCompleteStatus(String sessionId) async {
    try {
      print('🔍 [TRACKING] Récupération statut complet pour session: $sessionId');

      final constatStatus = await getConstatStatus(sessionId);
      final expertAssignment = await getExpertAssignmentInfo(sessionId);

      return {
        'sessionId': sessionId,
        'constat': constatStatus,
        'expert': expertAssignment,
        'hasConstat': constatStatus != null,
        'hasExpert': expertAssignment != null,
        'timestamp': DateTime.now().toIso8601String(),
      };

    } catch (e) {
      print('❌ [TRACKING] Erreur récupération statut complet: $e');
      return {
        'sessionId': sessionId,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 📋 Récupérer tous les constats du conducteur avec leur statut
  static Future<List<Map<String, dynamic>>> getConducteurConstats(String conducteurId) async {
    try {
      print('🔍 [TRACKING] Récupération constats pour conducteur: $conducteurId');

      final List<Map<String, dynamic>> constats = [];

      // Récupérer les sessions du conducteur
      final sessionsQuery = await _firestore
          .collection('sessions_collaboratives')
          .where('conducteurCreateur', isEqualTo: conducteurId)
          .orderBy('dateCreation', descending: true)
          .get();

      for (final sessionDoc in sessionsQuery.docs) {
        final sessionData = sessionDoc.data();
        final sessionId = sessionDoc.id;

        // Récupérer le statut complet pour chaque session
        final completeStatus = await getCompleteStatus(sessionId);

        constats.add({
          'sessionId': sessionId,
          'codeSession': sessionData['codeSession'],
          'dateCreation': sessionData['dateCreation'],
          'statut': sessionData['statut'],
          'tracking': completeStatus,
        });
      }

      print('✅ [TRACKING] ${constats.length} constats trouvés pour le conducteur');
      return constats;

    } catch (e) {
      print('❌ [TRACKING] Erreur récupération constats conducteur: $e');
      return [];
    }
  }

  /// 🔔 Créer une notification de suivi pour le conducteur
  static Future<void> createTrackingNotification({
    required String conducteurId,
    required String sessionId,
    required String type, // 'constat_envoye', 'expert_assigne', 'expertise_terminee'
    required String title,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'recipientId': conducteurId,
        'type': type,
        'title': title,
        'message': message,
        'sessionId': sessionId,
        'data': additionalData ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'constat_tracking',
      });

      print('✅ [TRACKING] Notification créée: $type pour session $sessionId');
    } catch (e) {
      print('❌ [TRACKING] Erreur création notification: $e');
    }
  }
}
