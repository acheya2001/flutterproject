import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 📊 Service de statistiques pour Admin Compagnie
class AdminCompagnieStatsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📊 Récupérer les statistiques globales de la compagnie
  static Future<Map<String, dynamic>> getCompagnieGlobalStats(String compagnieId) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_STATS] 📊 Récupération stats globales pour: $compagnieId');

      // Récupérer toutes les agences
      final agencesQuery = await _firestore
          .collection('agences')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      int totalAgences = agencesQuery.docs.length;
      int totalAgents = 0;
      int totalActiveAgents = 0;
      int totalAdminsAgence = 0;
      List<Map<String, dynamic>> agencesDetails = [];

      // Pour chaque agence, récupérer ses statistiques
      for (var agenceDoc in agencesQuery.docs) {
        final agenceData = agenceDoc.data();
        agenceData['id'] = agenceDoc.id;

        // Compter les agents de cette agence
        final agentsQuery = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'agent')
            .where('agenceId', isEqualTo: agenceDoc.id)
            .get();

        final agenceAgents = agentsQuery.docs.length;
        final agenceActiveAgents = agentsQuery.docs.where((doc) => doc.data()['isActive'] == true).length;

        // Compter les admins de cette agence
        final adminsQuery = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'admin_agence')
            .where('agenceId', isEqualTo: agenceDoc.id)
            .get();

        final agenceAdmins = adminsQuery.docs.length;

        // Ajouter aux totaux
        totalAgents += agenceAgents;
        totalActiveAgents += agenceActiveAgents;
        totalAdminsAgence += agenceAdmins;

        // Ajouter les détails de l'agence
        agencesDetails.add({
          'id': agenceDoc.id,
          'nom': agenceData['nom'],
          'code': agenceData['code'],
          'totalAgents': agenceAgents,
          'activeAgents': agenceActiveAgents,
          'inactiveAgents': agenceAgents - agenceActiveAgents,
          'totalAdmins': agenceAdmins,
          'adresse': agenceData['adresse'],
          'telephone': agenceData['telephone'],
          'email': agenceData['email'],
        });

        debugPrint('[ADMIN_COMPAGNIE_STATS] 🏢 Agence ${agenceData['nom']}: $agenceAgents agents, $agenceAdmins admins');
      }

      final stats = {
        'totalAgences': totalAgences,
        'totalAgents': totalAgents,
        'activeAgents': totalActiveAgents,
        'inactiveAgents': totalAgents - totalActiveAgents,
        'totalAdminsAgence': totalAdminsAgence,
        'agencesDetails': agencesDetails,
        'lastUpdate': DateTime.now().toIso8601String(),
      };

      debugPrint('[ADMIN_COMPAGNIE_STATS] ✅ Stats globales: $totalAgences agences, $totalAgents agents');
      return stats;

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_STATS] ❌ Erreur récupération stats: $e');
      return {
        'totalAgences': 0,
        'totalAgents': 0,
        'activeAgents': 0,
        'inactiveAgents': 0,
        'totalAdminsAgence': 0,
        'agencesDetails': [],
        'lastUpdate': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  /// 📊 Récupérer les statistiques d'une agence spécifique
  static Future<Map<String, dynamic>> getAgenceDetailedStats(String agenceId) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_STATS] 📊 Stats détaillées pour agence: $agenceId');

      // Récupérer les informations de l'agence
      final agenceDoc = await _firestore.collection('agences').doc(agenceId).get();
      if (!agenceDoc.exists) {
        throw Exception('Agence non trouvée');
      }

      final agenceData = agenceDoc.data()!;

      // Récupérer tous les agents
      final agentsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('agenceId', isEqualTo: agenceId)
          .get();

      List<Map<String, dynamic>> agents = [];
      int activeAgents = 0;

      for (var doc in agentsQuery.docs) {
        final agentData = doc.data();
        agentData['uid'] = doc.id;
        agents.add(agentData);

        if (agentData['isActive'] == true) {
          activeAgents++;
        }
      }

      // Récupérer les admins de l'agence
      final adminsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_agence')
          .where('agenceId', isEqualTo: agenceId)
          .get();

      List<Map<String, dynamic>> admins = [];
      for (var doc in adminsQuery.docs) {
        final adminData = doc.data();
        adminData['uid'] = doc.id;
        admins.add(adminData);
      }

      return {
        'agenceInfo': agenceData,
        'totalAgents': agents.length,
        'activeAgents': activeAgents,
        'inactiveAgents': agents.length - activeAgents,
        'agents': agents,
        'totalAdmins': admins.length,
        'admins': admins,
        'lastUpdate': DateTime.now().toIso8601String(),
      };

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_STATS] ❌ Erreur stats agence $agenceId: $e');
      return {
        'error': e.toString(),
        'totalAgents': 0,
        'activeAgents': 0,
        'inactiveAgents': 0,
        'agents': [],
        'totalAdmins': 0,
        'admins': [],
        'lastUpdate': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 🔄 Stream pour synchronisation en temps réel des agences
  static Stream<List<Map<String, dynamic>>> getAgencesStream(String compagnieId) {
    return _firestore
        .collection('agences')
        .where('compagnieId', isEqualTo: compagnieId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// 👥 Stream pour synchronisation en temps réel des agents d'une agence
  static Stream<List<Map<String, dynamic>>> getAgenceAgentsStream(String agenceId) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'agent')
        .where('agenceId', isEqualTo: agenceId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// 🔔 Créer une notification de changement
  static Future<void> notifyStatsChange(String compagnieId, String type, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('notifications_stats').add({
        'compagnieId': compagnieId,
        'type': type, // 'agent_created', 'agent_updated', 'agence_created', etc.
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
      
      debugPrint('[ADMIN_COMPAGNIE_STATS] 🔔 Notification créée: $type');
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_STATS] ❌ Erreur notification: $e');
    }
  }

  /// 📈 Calculer les tendances (évolution sur 30 jours)
  static Future<Map<String, dynamic>> getCompagnieTrends(String compagnieId) async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // Récupérer les agents créés dans les 30 derniers jours
      final recentAgentsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('compagnieId', isEqualTo: compagnieId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      // Récupérer les agences créées dans les 30 derniers jours
      final recentAgencesQuery = await _firestore
          .collection('agences')
          .where('compagnieId', isEqualTo: compagnieId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      return {
        'newAgentsLast30Days': recentAgentsQuery.docs.length,
        'newAgencesLast30Days': recentAgencesQuery.docs.length,
        'growthRate': _calculateGrowthRate(recentAgentsQuery.docs.length),
        'lastUpdate': DateTime.now().toIso8601String(),
      };

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_STATS] ❌ Erreur tendances: $e');
      return {
        'newAgentsLast30Days': 0,
        'newAgencesLast30Days': 0,
        'growthRate': 0.0,
        'lastUpdate': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 📊 Calculer le taux de croissance
  static double _calculateGrowthRate(int newItems) {
    // Calcul simple du taux de croissance basé sur les nouveaux éléments
    if (newItems == 0) return 0.0;
    return (newItems / 30) * 100; // Pourcentage par jour
  }
}
