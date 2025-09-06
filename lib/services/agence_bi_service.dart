import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 📊 Service BI pour les statistiques d'agence
class AgenceBIService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📊 Récupérer toutes les statistiques d'une agence
  static Future<Map<String, dynamic>> getAgenceStatistics(String agenceId) async {
    try {
      debugPrint('[AGENCE_BI] 📊 Récupération statistiques agence: $agenceId');

      final results = await Future.wait([
        _getContractsStats(agenceId),
        _getFinancialStats(agenceId),
        _getAgentsStats(agenceId),
        _getVehiclesStats(agenceId),
        _getRecentActivity(agenceId),
      ]);

      final statistics = {
        'contracts': results[0],
        'financial': results[1],
        'agents': results[2],
        'vehicles': results[3],
        'recentActivity': results[4],
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      debugPrint('[AGENCE_BI] ✅ Statistiques récupérées avec succès');
      return statistics;

    } catch (e) {
      debugPrint('[AGENCE_BI] ❌ Erreur récupération statistiques: $e');
      return _getEmptyStatistics();
    }
  }

  /// 📄 Statistiques des contrats
  static Future<Map<String, dynamic>> _getContractsStats(String agenceId) async {
    try {
      final contractsSnapshot = await _firestore
          .collection('contrats')
          .where('agenceId', isEqualTo: agenceId)
          .get();

      int total = contractsSnapshot.docs.length;
      int active = 0;
      int expired = 0;
      int suspended = 0;
      int expiringThisMonth = 0;

      final now = DateTime.now();
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      for (var doc in contractsSnapshot.docs) {
        final data = doc.data();
        final statut = data['statut']?.toString().toLowerCase() ?? '';
        final dateFin = (data['dateFin'] as Timestamp?)?.toDate();

        switch (statut) {
          case 'actif':
            active++;
            // Vérifier si expire ce mois
            if (dateFin != null && dateFin.isBefore(endOfMonth) && dateFin.isAfter(now)) {
              expiringThisMonth++;
            }
            break;
          case 'expiré':
          case 'expire':
            expired++;
            break;
          case 'suspendu':
            suspended++;
            break;
        }
      }

      // Calculer la croissance (simulation - à adapter selon vos besoins)
      double growthRate = total > 0 ? (active / total * 100) - 85 : 0;

      return {
        'total': total,
        'active': active,
        'expired': expired,
        'suspended': suspended,
        'expiringThisMonth': expiringThisMonth,
        'growthRate': growthRate,
        'activePercentage': total > 0 ? (active / total * 100) : 0,
      };

    } catch (e) {
      debugPrint('[AGENCE_BI] ❌ Erreur statistiques contrats: $e');
      return {
        'total': 0,
        'active': 0,
        'expired': 0,
        'suspended': 0,
        'expiringThisMonth': 0,
        'growthRate': 0,
        'activePercentage': 0,
      };
    }
  }

  /// 💰 Statistiques financières
  static Future<Map<String, dynamic>> _getFinancialStats(String agenceId) async {
    try {
      final contractsSnapshot = await _firestore
          .collection('contrats')
          .where('agenceId', isEqualTo: agenceId)
          .get();

      double totalPrimes = 0;
      double primesThisMonth = 0;
      double primesLastMonth = 0;

      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 1);
      final lastMonth = DateTime(now.year, now.month - 1, 1);

      for (var doc in contractsSnapshot.docs) {
        final data = doc.data();
        final prime = (data['primeAnnuelle'] ?? data['primeAssurance'] ?? 0).toDouble();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

        totalPrimes += prime;

        if (createdAt != null) {
          if (createdAt.isAfter(thisMonth)) {
            primesThisMonth += prime;
          } else if (createdAt.isAfter(lastMonth) && createdAt.isBefore(thisMonth)) {
            primesLastMonth += prime;
          }
        }
      }

      double financialGrowthRate = 0;
      if (primesLastMonth > 0) {
        financialGrowthRate = ((primesThisMonth - primesLastMonth) / primesLastMonth) * 100;
      }

      return {
        'totalPrimes': totalPrimes,
        'primesThisMonth': primesThisMonth,
        'primesLastMonth': primesLastMonth,
        'financialGrowthRate': financialGrowthRate,
        'averagePrime': contractsSnapshot.docs.isNotEmpty ? totalPrimes / contractsSnapshot.docs.length : 0,
      };

    } catch (e) {
      debugPrint('[AGENCE_BI] ❌ Erreur statistiques financières: $e');
      return {
        'totalPrimes': 0,
        'primesThisMonth': 0,
        'primesLastMonth': 0,
        'financialGrowthRate': 0,
        'averagePrime': 0,
      };
    }
  }

  /// 👥 Statistiques des agents
  static Future<Map<String, dynamic>> _getAgentsStats(String agenceId) async {
    try {
      final agentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('agenceId', isEqualTo: agenceId)
          .get();

      int totalAgents = agentsSnapshot.docs.length;
      int activeAgents = 0;

      List<Map<String, dynamic>> agentPerformance = [];

      for (var agentDoc in agentsSnapshot.docs) {
        final agentData = agentDoc.data();
        final agentId = agentDoc.id;
        final isActive = agentData['isActive'] ?? false;

        if (isActive) activeAgents++;

        // Compter les contrats de cet agent
        final agentContracts = await _firestore
            .collection('contrats')
            .where('agentId', isEqualTo: agentId)
            .get();

        agentPerformance.add({
          'agentId': agentId,
          'nom': '${agentData['prenom']} ${agentData['nom']}',
          'contractsCount': agentContracts.docs.length,
          'isActive': isActive,
        });
      }

      // Trier par performance
      agentPerformance.sort((a, b) => (b['contractsCount'] as int).compareTo(a['contractsCount'] as int));

      return {
        'totalAgents': totalAgents,
        'activeAgents': activeAgents,
        'topPerformers': agentPerformance.take(5).toList(),
        'agentPerformance': agentPerformance,
      };

    } catch (e) {
      debugPrint('[AGENCE_BI] ❌ Erreur statistiques agents: $e');
      return {
        'totalAgents': 0,
        'activeAgents': 0,
        'topPerformers': [],
        'agentPerformance': [],
      };
    }
  }

  /// 🚗 Statistiques des véhicules
  static Future<Map<String, dynamic>> _getVehiclesStats(String agenceId) async {
    try {
      final vehiculesSnapshot = await _firestore
          .collection('vehicules')
          .where('agenceId', isEqualTo: agenceId)
          .get();

      Map<String, int> typeDistribution = {};
      Map<String, int> statusDistribution = {};
      int totalVehicules = vehiculesSnapshot.docs.length;

      for (var doc in vehiculesSnapshot.docs) {
        final data = doc.data();
        final type = data['typeVehicule'] ?? 'Non défini';
        final status = data['etatCompte'] ?? 'Non défini';

        typeDistribution[type] = (typeDistribution[type] ?? 0) + 1;
        statusDistribution[status] = (statusDistribution[status] ?? 0) + 1;
      }

      return {
        'totalVehicules': totalVehicules,
        'typeDistribution': typeDistribution,
        'statusDistribution': statusDistribution,
        'pendingVehicules': statusDistribution['En attente'] ?? 0,
        'activeVehicules': statusDistribution['Actif'] ?? 0,
      };

    } catch (e) {
      debugPrint('[AGENCE_BI] ❌ Erreur statistiques véhicules: $e');
      return {
        'totalVehicules': 0,
        'typeDistribution': {},
        'statusDistribution': {},
        'pendingVehicules': 0,
        'activeVehicules': 0,
      };
    }
  }

  /// 📱 Activité récente
  static Future<List<Map<String, dynamic>>> _getRecentActivity(String agenceId) async {
    try {
      // Récupérer tous les contrats de l'agence puis trier en mémoire
      final contractsSnapshot = await _firestore
          .collection('contrats')
          .where('agenceId', isEqualTo: agenceId)
          .get();

      // Trier par date de création et prendre les 10 plus récents
      final sortedContracts = contractsSnapshot.docs.toList()
        ..sort((a, b) {
          final aCreated = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          final bCreated = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          return bCreated.compareTo(aCreated);
        });

      final recentContracts = sortedContracts.take(10);

      List<Map<String, dynamic>> activities = [];

      for (var doc in recentContracts) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

        activities.add({
          'id': doc.id,
          'type': 'contract_created',
          'title': 'Nouveau contrat ${data['numeroContrat']}',
          'description': 'Contrat créé pour ${data['conducteurNom'] ?? 'Conducteur'}',
          'timestamp': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'agentId': data['agentId'],
          'contractNumber': data['numeroContrat'],
        });
      }

      return activities;

    } catch (e) {
      debugPrint('[AGENCE_BI] ❌ Erreur activité récente: $e');
      return [];
    }
  }

  /// 📊 Statistiques vides par défaut
  static Map<String, dynamic> _getEmptyStatistics() {
    return {
      'contracts': {
        'total': 0,
        'active': 0,
        'expired': 0,
        'suspended': 0,
        'expiringThisMonth': 0,
        'growthRate': 0,
        'activePercentage': 0,
      },
      'financial': {
        'totalPrimes': 0,
        'primesThisMonth': 0,
        'primesLastMonth': 0,
        'financialGrowthRate': 0,
        'averagePrime': 0,
      },
      'agents': {
        'totalAgents': 0,
        'activeAgents': 0,
        'topPerformers': [],
        'agentPerformance': [],
      },
      'vehicles': {
        'totalVehicules': 0,
        'typeDistribution': {},
        'statusDistribution': {},
        'pendingVehicules': 0,
        'activeVehicules': 0,
      },
      'recentActivity': [],
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }
}
