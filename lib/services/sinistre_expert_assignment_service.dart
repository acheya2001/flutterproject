import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'constat_agent_notification_service.dart';
import 'dart:math';

/// 🔧 Service d'affectation d'experts aux sinistres
class SinistreExpertAssignmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔍 Rechercher des experts disponibles pour un sinistre
  static Future<List<Map<String, dynamic>>> findAvailableExperts({
    required String compagnieId,
    required String agenceId,
    String? gouvernorat,
    String? specialiteRequise,
    bool onlyAvailable = true,
  }) async {
    try {
      debugPrint('[SINISTRE_EXPERT] 🔍 Recherche experts pour compagnie: $compagnieId');

      // Rechercher d'abord dans l'agence
      Query expertsQuery = _firestore
          .collection('users')
          .where('role', isEqualTo: 'expert')
          .where('agenceId', isEqualTo: agenceId)
          .where('isActive', isEqualTo: true);

      if (onlyAvailable) {
        expertsQuery = expertsQuery.where('isDisponible', isEqualTo: true);
      }

      final agenceExperts = await expertsQuery.get();
      List<Map<String, dynamic>> experts = [];

      // Traiter les experts de l'agence
      for (var doc in agenceExperts.docs) {
        final expertData = doc.data() as Map<String, dynamic>;
        expertData['id'] = doc.id;
        expertData['source'] = 'agence';
        expertData['priority'] = 1; // Priorité haute pour experts de l'agence

        // Vérifier la spécialité si requise
        if (specialiteRequise != null) {
          final specialitesRaw = expertData['specialites'];
          final specialites = specialitesRaw is List
              ? specialitesRaw.map((e) => e.toString()).toList()
              : <String>[];
          if (!specialites.contains(specialiteRequise)) continue;
        }

        // Vérifier le gouvernorat si spécifié
        if (gouvernorat != null) {
          final gouvernoratsRaw = expertData['gouvernoratsIntervention'];
          final gouvernoratsIntervention = gouvernoratsRaw is List
              ? gouvernoratsRaw.map((e) => e.toString()).toList()
              : <String>[];
          if (!gouvernoratsIntervention.contains(gouvernorat)) continue;
        }

        experts.add(expertData);
      }

      // Si pas assez d'experts dans l'agence, chercher dans la compagnie
      if (experts.length < 3) {
        final compagnieExpertsQuery = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'expert')
            .where('compagnieId', isEqualTo: compagnieId)
            .where('isActive', isEqualTo: true)
            .where('isDisponible', isEqualTo: true)
            .get();

        for (var doc in compagnieExpertsQuery.docs) {
          final expertData = doc.data() as Map<String, dynamic>;
          
          // Éviter les doublons
          if (experts.any((e) => e['id'] == doc.id)) continue;

          expertData['id'] = doc.id;
          expertData['source'] = 'compagnie';
          expertData['priority'] = 2; // Priorité moyenne pour experts de la compagnie

          // Vérifier la spécialité si requise
          if (specialiteRequise != null) {
            final specialitesRaw = expertData['specialites'];
            final specialites = specialitesRaw is List
                ? specialitesRaw.map((e) => e.toString()).toList()
                : <String>[];
            if (!specialites.contains(specialiteRequise)) continue;
          }

          // Vérifier le gouvernorat si spécifié
          if (gouvernorat != null) {
            final gouvernoratsRaw = expertData['gouvernoratsIntervention'];
            final gouvernoratsIntervention = gouvernoratsRaw is List
                ? gouvernoratsRaw.map((e) => e.toString()).toList()
                : <String>[];
            if (!gouvernoratsIntervention.contains(gouvernorat)) continue;
          }

          experts.add(expertData);
        }
      }

      // Trier par priorité puis par note moyenne
      experts.sort((a, b) {
        final priorityA = a['priority'] as int? ?? 999;
        final priorityB = b['priority'] as int? ?? 999;
        final priorityCompare = priorityA.compareTo(priorityB);
        if (priorityCompare != 0) return priorityCompare;

        final noteA = (a['noteMoyenne'] as num?)?.toDouble() ?? 0.0;
        final noteB = (b['noteMoyenne'] as num?)?.toDouble() ?? 0.0;
        return noteB.compareTo(noteA);
      });

      debugPrint('[SINISTRE_EXPERT] ✅ ${experts.length} experts trouvés');
      return experts;

    } catch (e) {
      debugPrint('[SINISTRE_EXPERT] ❌ Erreur recherche experts: $e');
      return [];
    }
  }

  /// 📝 Affecter un expert à un sinistre
  static Future<Map<String, dynamic>> assignExpertToSinistre({
    required String sinistreId,
    required String expertId,
    required String agentId,
    String? commentaire,
    int? delaiIntervention, // en heures
  }) async {
    try {
      debugPrint('[SINISTRE_EXPERT] 📝 Affectation expert $expertId au sinistre $sinistreId');

      // Récupérer les données de l'expert
      final expertDoc = await _firestore.collection('users').doc(expertId).get();
      if (!expertDoc.exists) {
        return {
          'success': false,
          'error': 'Expert introuvable',
        };
      }

      final expertData = expertDoc.data()!;

      // Récupérer les données du sinistre
      final sinistreDoc = await _firestore.collection('sinistres').doc(sinistreId).get();
      if (!sinistreDoc.exists) {
        return {
          'success': false,
          'error': 'Sinistre introuvable',
        };
      }

      final sinistreData = sinistreDoc.data()!;

      // Générer un ID de mission
      final missionId = _generateMissionId();
      final now = DateTime.now();
      final delaiInterventionFinal = delaiIntervention ?? 24; // 24h par défaut
      final dateEcheance = now.add(Duration(hours: delaiInterventionFinal));

      // Créer la mission d'expertise
      final missionData = {
        'id': missionId,
        'sinistreId': sinistreId,
        'expertId': expertId,
        'agentId': agentId,
        'compagnieId': sinistreData['compagnieId'],
        'agenceId': sinistreData['agenceId'],
        'statut': 'assignee',
        'dateAssignation': FieldValue.serverTimestamp(),
        'dateEcheance': Timestamp.fromDate(dateEcheance),
        'delaiIntervention': delaiInterventionFinal,
        'commentaireAssignation': commentaire,
        'expertInfo': {
          'nom': expertData['nom'],
          'prenom': expertData['prenom'],
          'email': expertData['email'],
          'telephone': expertData['telephone'],
          'codeExpert': expertData['codeExpert'],
          'specialites': expertData['specialites'],
        },
        'sinistreInfo': {
          'numeroSinistre': sinistreData['numeroSinistre'] ?? sinistreId,
          'dateAccident': sinistreData['dateAccident'],
          'lieuAccident': sinistreData['lieuAccident'] ?? sinistreData['lieu'],
          'typeAccident': sinistreData['typeAccident'] ?? sinistreData['typeSinistre'],
        },
        'progression': {
          'etapeActuelle': 'assignee',
          'etapesCompletees': [],
          'pourcentageAvancement': 0,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Créer la mission
      await _firestore.collection('missions_expertise').doc(missionId).set(missionData);

      // Mettre à jour le sinistre
      await _firestore.collection('sinistres').doc(sinistreId).update({
        'statut': 'expertise_assignee',
        'expertId': expertId,
        'expertNom': '${expertData['prenom']} ${expertData['nom']}',
        'missionId': missionId,
        'dateAssignationExpert': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Marquer l'expert comme occupé
      await _firestore.collection('users').doc(expertId).update({
        'isDisponible': false,
        'expertisesEnCours': FieldValue.increment(1),
        'derniereMission': missionId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour aussi dans la collection experts
      await _firestore.collection('experts').doc(expertId).update({
        'isDisponible': false,
        'expertisesEnCours': FieldValue.increment(1),
        'derniereMission': missionId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Créer une notification pour l'expert
      await _createExpertNotification(
        expertId: expertId,
        missionId: missionId,
        sinistreId: sinistreId,
        message: 'Nouvelle mission d\'expertise assignée',
      );

      // Créer une notification pour le conducteur
      if (sinistreData['conducteurDeclarantId'] != null) {
        await _createConducteurNotification(
          conducteurId: sinistreData['conducteurDeclarantId'],
          sinistreId: sinistreId,
          expertNom: '${expertData['prenom']} ${expertData['nom']}',
          message: 'Un expert a été assigné à votre sinistre',
        );
      }

      // Mettre à jour le statut dans constats_finalises si sessionId existe
      final sessionId = sinistreData['sessionId'];
      if (sessionId != null) {
        await ConstatAgentNotificationService.mettreAJourStatutExpertAssigne(
          sessionId: sessionId,
          expertInfo: {
            'id': expertId,
            'nom': expertData['nom'],
            'prenom': expertData['prenom'],
            'codeExpert': expertData['codeExpert'],
            'telephone': expertData['telephone'],
            'email': expertData['email'],
          },
          missionId: missionId,
        );
      }

      debugPrint('[SINISTRE_EXPERT] ✅ Expert assigné avec succès');

      return {
        'success': true,
        'missionId': missionId,
        'expertNom': '${expertData['prenom']} ${expertData['nom']}',
        'dateEcheance': dateEcheance.toIso8601String(),
        'message': 'Expert assigné avec succès',
      };

    } catch (e) {
      debugPrint('[SINISTRE_EXPERT] ❌ Erreur affectation expert: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🔄 Changer l'expert assigné à un sinistre
  static Future<Map<String, dynamic>> reassignExpert({
    required String sinistreId,
    required String newExpertId,
    required String agentId,
    String? raisonChangement,
  }) async {
    try {
      debugPrint('[SINISTRE_EXPERT] 🔄 Réassignation expert pour sinistre $sinistreId');

      // Récupérer le sinistre
      final sinistreDoc = await _firestore.collection('sinistres').doc(sinistreId).get();
      if (!sinistreDoc.exists) {
        return {
          'success': false,
          'error': 'Sinistre introuvable',
        };
      }

      final sinistreData = sinistreDoc.data()!;
      final oldExpertId = sinistreData['expertId'];
      final oldMissionId = sinistreData['missionId'];

      // Libérer l'ancien expert
      if (oldExpertId != null) {
        await _firestore.collection('users').doc(oldExpertId).update({
          'isDisponible': true,
          'expertisesEnCours': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await _firestore.collection('experts').doc(oldExpertId).update({
          'isDisponible': true,
          'expertisesEnCours': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Marquer l'ancienne mission comme annulée
      if (oldMissionId != null) {
        await _firestore.collection('missions_expertise').doc(oldMissionId).update({
          'statut': 'annulee',
          'raisonAnnulation': raisonChangement ?? 'Réassignation expert',
          'dateAnnulation': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Assigner le nouvel expert
      return await assignExpertToSinistre(
        sinistreId: sinistreId,
        expertId: newExpertId,
        agentId: agentId,
        commentaire: 'Réassignation - ${raisonChangement ?? 'Changement d\'expert'}',
      );

    } catch (e) {
      debugPrint('[SINISTRE_EXPERT] ❌ Erreur réassignation expert: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 📊 Obtenir les statistiques d'affectation
  static Future<Map<String, dynamic>> getAssignmentStats({
    required String agenceId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      Query missionsQuery = _firestore
          .collection('missions_expertise')
          .where('agenceId', isEqualTo: agenceId)
          .where('dateAssignation', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('dateAssignation', isLessThanOrEqualTo: Timestamp.fromDate(end));

      final missionsSnapshot = await missionsQuery.get();
      final missions = missionsSnapshot.docs;

      final totalMissions = missions.length;
      final missionsAssignees = missions.where((m) => (m.data() as Map<String, dynamic>)['statut'] == 'assignee').length;
      final missionsEnCours = missions.where((m) => (m.data() as Map<String, dynamic>)['statut'] == 'en_cours').length;
      final missionsTerminees = missions.where((m) => (m.data() as Map<String, dynamic>)['statut'] == 'terminee').length;
      final missionsAnnulees = missions.where((m) => (m.data() as Map<String, dynamic>)['statut'] == 'annulee').length;

      // Calculer le délai moyen d'intervention
      final delaisMoyens = missions
          .where((m) => (m.data() as Map<String, dynamic>)['dateIntervention'] != null)
          .map((m) {
            final data = m.data() as Map<String, dynamic>;
            final dateAssignation = (data['dateAssignation'] as Timestamp).toDate();
            final dateIntervention = (data['dateIntervention'] as Timestamp).toDate();
            return dateIntervention.difference(dateAssignation).inHours;
          })
          .toList();

      final delaiMoyenIntervention = delaisMoyens.isNotEmpty
          ? delaisMoyens.reduce((a, b) => a + b) / delaisMoyens.length
          : 0.0;

      return {
        'totalMissions': totalMissions,
        'missionsAssignees': missionsAssignees,
        'missionsEnCours': missionsEnCours,
        'missionsTerminees': missionsTerminees,
        'missionsAnnulees': missionsAnnulees,
        'tauxCompletion': totalMissions > 0 ? (missionsTerminees / totalMissions * 100).round() : 0,
        'delaiMoyenIntervention': delaiMoyenIntervention.round(),
        'periode': {
          'debut': start.toIso8601String(),
          'fin': end.toIso8601String(),
        },
      };

    } catch (e) {
      debugPrint('[SINISTRE_EXPERT] ❌ Erreur stats affectation: $e');
      return {
        'totalMissions': 0,
        'missionsAssignees': 0,
        'missionsEnCours': 0,
        'missionsTerminees': 0,
        'missionsAnnulees': 0,
        'tauxCompletion': 0,
        'delaiMoyenIntervention': 0,
      };
    }
  }

  /// 🔔 Créer une notification pour l'expert
  static Future<void> _createExpertNotification({
    required String expertId,
    required String missionId,
    required String sinistreId,
    required String message,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': expertId,
        'userRole': 'expert',
        'type': 'mission_assignee',
        'title': 'Nouvelle Mission',
        'message': message,
        'data': {
          'missionId': missionId,
          'sinistreId': sinistreId,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[SINISTRE_EXPERT] ❌ Erreur notification expert: $e');
    }
  }

  /// 🔔 Créer une notification pour le conducteur
  static Future<void> _createConducteurNotification({
    required String conducteurId,
    required String sinistreId,
    required String expertNom,
    required String message,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': conducteurId,
        'userRole': 'conducteur',
        'type': 'expert_assigne',
        'title': 'Expert Assigné',
        'message': '$message - Expert: $expertNom',
        'data': {
          'sinistreId': sinistreId,
          'expertNom': expertNom,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[SINISTRE_EXPERT] ❌ Erreur notification conducteur: $e');
    }
  }

  /// 🆔 Générer un ID de mission
  static String _generateMissionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'MISSION_${timestamp}_$random';
  }

  /// 📋 Récupérer les missions d'un expert
  static Future<List<Map<String, dynamic>>> getExpertMissions(String expertId) async {
    try {
      debugPrint('[SINISTRE_EXPERT] 🔍 Recherche missions pour expert: $expertId');

      // Requête simplifiée sans orderBy pour éviter le problème d'index
      final missionsQuery = await _firestore
          .collection('missions_expertise')
          .where('expertId', isEqualTo: expertId)
          .get();

      List<Map<String, dynamic>> missions = [];
      for (var doc in missionsQuery.docs) {
        final missionData = doc.data();
        missionData['id'] = doc.id;
        missions.add(missionData);
      }

      // Trier manuellement par date d'assignation (plus récent en premier)
      missions.sort((a, b) {
        final dateA = a['dateAssignation'] as Timestamp?;
        final dateB = b['dateAssignation'] as Timestamp?;

        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;

        return dateB.compareTo(dateA); // Ordre décroissant
      });

      debugPrint('[SINISTRE_EXPERT] ✅ ${missions.length} missions trouvées pour expert $expertId');
      return missions;

    } catch (e) {
      debugPrint('[SINISTRE_EXPERT] ❌ Erreur récupération missions expert: $e');
      return [];
    }
  }

  /// 📋 Récupérer les sinistres avec experts assignés pour un agent
  static Future<List<Map<String, dynamic>>> getAgentSinistresWithExperts(String agentId) async {
    try {
      final sinistresQuery = await _firestore
          .collection('sinistres')
          .where('agentId', isEqualTo: agentId)
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> sinistres = [];
      for (var doc in sinistresQuery.docs) {
        final sinistreData = doc.data();
        sinistreData['id'] = doc.id;

        // ✅ Protection contre les valeurs null
        sinistreData['statut'] = sinistreData['statut'] ?? 'en_attente';
        sinistreData['typeSinistre'] = sinistreData['typeSinistre'] ?? 'Accident';
        sinistreData['lieu'] = sinistreData['lieu'] ?? sinistreData['lieuAccident'] ?? 'Non spécifié';
        sinistreData['description'] = sinistreData['description'] ?? 'Aucune description';
        sinistreData['conducteurNom'] = sinistreData['conducteurNom'] ?? 'Conducteur inconnu';
        sinistreData['vehiculeInfo'] = sinistreData['vehiculeInfo'] ?? {};

        // Assurer que les champs de date sont présents
        if (sinistreData['dateSinistre'] == null && sinistreData['dateAccident'] != null) {
          sinistreData['dateSinistre'] = sinistreData['dateAccident'];
        }
        if (sinistreData['dateSinistre'] == null) {
          sinistreData['dateSinistre'] = sinistreData['createdAt'] ?? Timestamp.now();
        }

        // Récupérer les informations de la mission si elle existe
        if (sinistreData['missionId'] != null) {
          try {
            final missionDoc = await _firestore
                .collection('missions_expertise')
                .doc(sinistreData['missionId'])
                .get();

            if (missionDoc.exists) {
              final missionData = missionDoc.data() ?? {};
              // Protection contre les valeurs null dans les données de mission
              missionData['statut'] = missionData['statut'] ?? 'assignee';
              missionData['expertNom'] = missionData['expertNom'] ?? 'Expert inconnu';
              sinistreData['missionData'] = missionData;
            }
          } catch (e) {
            debugPrint('[SINISTRE_EXPERT] ⚠️ Erreur récupération mission ${sinistreData['missionId']}: $e');
            // Continuer sans les données de mission
          }
        }

        sinistres.add(sinistreData);
      }

      debugPrint('[SINISTRE_EXPERT] ✅ ${sinistres.length} sinistres récupérés pour agent $agentId');
      return sinistres;

    } catch (e) {
      debugPrint('[SINISTRE_EXPERT] ❌ Erreur récupération sinistres agent: $e');
      return [];
    }
  }
}
