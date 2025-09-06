import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 📊 Service BI pour les statistiques de compagnie (toutes agences)
class CompagnieBIService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📊 Récupérer toutes les statistiques d'une compagnie
  static Future<Map<String, dynamic>> getCompagnieStatistics(String compagnieId) async {
    try {
      debugPrint('[COMPAGNIE_BI] 📊 Récupération statistiques compagnie: $compagnieId');

      final results = await Future.wait([
        _getGlobalStats(compagnieId),
        _getAgencesStats(compagnieId),
        _getFinancialStats(compagnieId),
        _getPerformanceStats(compagnieId),
        _getComparativeStats(compagnieId),
      ]);

      final statistics = {
        'global': results[0],
        'agences': results[1],
        'financial': results[2],
        'performance': results[3],
        'comparative': results[4],
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      debugPrint('[COMPAGNIE_BI] ✅ Statistiques compagnie récupérées avec succès');
      return statistics;

    } catch (e) {
      debugPrint('[COMPAGNIE_BI] ❌ Erreur récupération statistiques: $e');
      return _getEmptyStatistics();
    }
  }

  /// 🌍 Statistiques globales de la compagnie
  static Future<Map<String, dynamic>> _getGlobalStats(String compagnieId) async {
    try {
      // Récupérer toutes les agences de la compagnie
      final agencesSnapshot = await _firestore
          .collection('agences')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      // Récupérer tous les contrats de toutes les agences
      final contractsSnapshot = await _firestore
          .collection('contrats')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      // Récupérer tous les agents de toutes les agences
      final agentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      // Calculer les statistiques globales
      int totalAgences = agencesSnapshot.docs.length;
      int totalContrats = contractsSnapshot.docs.length;
      int totalAgents = agentsSnapshot.docs.length;
      int contratsActifs = 0;
      int contratsExpires = 0;
      int contratsSuspendus = 0;
      double totalPrimes = 0;

      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 1);

      for (var doc in contractsSnapshot.docs) {
        final data = doc.data();
        final statut = data['statut']?.toString().toLowerCase() ?? '';
        final prime = (data['primeAnnuelle'] ?? data['primeAssurance'] ?? 0).toDouble();
        
        totalPrimes += prime;

        switch (statut) {
          case 'actif':
            contratsActifs++;
            break;
          case 'expiré':
          case 'expire':
            contratsExpires++;
            break;
          case 'suspendu':
            contratsSuspendus++;
            break;
        }
      }

      // Calculer la croissance mensuelle
      final contractsThisMonth = contractsSnapshot.docs.where((doc) {
        final createdAt = (doc.data()['createdAt'] as Timestamp?)?.toDate();
        return createdAt != null && createdAt.isAfter(thisMonth);
      }).length;

      return {
        'totalAgences': totalAgences,
        'totalContrats': totalContrats,
        'totalAgents': totalAgents,
        'contratsActifs': contratsActifs,
        'contratsExpires': contratsExpires,
        'contratsSuspendus': contratsSuspendus,
        'totalPrimes': totalPrimes,
        'contractsThisMonth': contractsThisMonth,
        'averageContractsPerAgence': totalAgences > 0 ? (totalContrats / totalAgences) : 0,
        'averageAgentsPerAgence': totalAgences > 0 ? (totalAgents / totalAgences) : 0,
      };

    } catch (e) {
      debugPrint('[COMPAGNIE_BI] ❌ Erreur statistiques globales: $e');
      return {};
    }
  }

  /// 🏢 Statistiques par agence
  static Future<List<Map<String, dynamic>>> _getAgencesStats(String compagnieId) async {
    try {
      final agencesSnapshot = await _firestore
          .collection('agences')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      List<Map<String, dynamic>> agencesStats = [];

      for (var agenceDoc in agencesSnapshot.docs) {
        final agenceData = agenceDoc.data();
        final agenceId = agenceDoc.id;

        // Récupérer les contrats de cette agence
        final contractsSnapshot = await _firestore
            .collection('contrats')
            .where('agenceId', isEqualTo: agenceId)
            .get();

        // Récupérer les agents de cette agence
        final agentsSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'agent')
            .where('agenceId', isEqualTo: agenceId)
            .get();

        // Calculer les statistiques de l'agence
        int totalContrats = contractsSnapshot.docs.length;
        int contratsActifs = 0;
        double totalPrimes = 0;
        int agentsActifs = 0;

        for (var doc in contractsSnapshot.docs) {
          final data = doc.data();
          final statut = data['statut']?.toString().toLowerCase() ?? '';
          final prime = (data['primeAnnuelle'] ?? data['primeAssurance'] ?? 0).toDouble();
          
          totalPrimes += prime;
          if (statut == 'actif') contratsActifs++;
        }

        for (var doc in agentsSnapshot.docs) {
          final data = doc.data();
          if (data['isActive'] == true) agentsActifs++;
        }

        agencesStats.add({
          'id': agenceId,
          'nom': agenceData['nom'] ?? 'Agence inconnue',
          'ville': agenceData['ville'] ?? 'Ville inconnue',
          'adresse': agenceData['adresse'] ?? '',
          'totalContrats': totalContrats,
          'contratsActifs': contratsActifs,
          'totalPrimes': totalPrimes,
          'totalAgents': agentsSnapshot.docs.length,
          'agentsActifs': agentsActifs,
          'performanceScore': _calculatePerformanceScore(totalContrats, contratsActifs, agentsActifs),
          'averagePrimePerContract': totalContrats > 0 ? (totalPrimes / totalContrats) : 0,
        });
      }

      // Trier par performance
      agencesStats.sort((a, b) => (b['performanceScore'] as double).compareTo(a['performanceScore'] as double));

      return agencesStats;

    } catch (e) {
      debugPrint('[COMPAGNIE_BI] ❌ Erreur statistiques agences: $e');
      return [];
    }
  }

  /// 💰 Statistiques financières globales
  static Future<Map<String, dynamic>> _getFinancialStats(String compagnieId) async {
    try {
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 1);
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      final thisYear = DateTime(now.year, 1, 1);

      final contractsSnapshot = await _firestore
          .collection('contrats')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      double totalPrimes = 0;
      double primesThisMonth = 0;
      double primesLastMonth = 0;
      double primesThisYear = 0;
      Map<String, double> primesByMonth = {};

      for (var doc in contractsSnapshot.docs) {
        final data = doc.data();
        final prime = (data['primeAnnuelle'] ?? data['primeAssurance'] ?? 0).toDouble();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

        totalPrimes += prime;

        if (createdAt != null) {
          if (createdAt.isAfter(thisYear)) {
            primesThisYear += prime;
          }

          if (createdAt.isAfter(thisMonth)) {
            primesThisMonth += prime;
          } else if (createdAt.isAfter(lastMonth) && createdAt.isBefore(thisMonth)) {
            primesLastMonth += prime;
          }

          // Grouper par mois pour les graphiques
          final monthKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';
          primesByMonth[monthKey] = (primesByMonth[monthKey] ?? 0) + prime;
        }
      }

      double growthRate = 0;
      if (primesLastMonth > 0) {
        growthRate = ((primesThisMonth - primesLastMonth) / primesLastMonth) * 100;
      }

      return {
        'totalPrimes': totalPrimes,
        'primesThisMonth': primesThisMonth,
        'primesLastMonth': primesLastMonth,
        'primesThisYear': primesThisYear,
        'growthRate': growthRate,
        'primesByMonth': primesByMonth,
        'averagePrimePerContract': contractsSnapshot.docs.isNotEmpty ? totalPrimes / contractsSnapshot.docs.length : 0,
      };

    } catch (e) {
      debugPrint('[COMPAGNIE_BI] ❌ Erreur statistiques financières: $e');
      return {};
    }
  }

  /// 📈 Statistiques de performance
  static Future<Map<String, dynamic>> _getPerformanceStats(String compagnieId) async {
    try {
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 1);

      // Top agences par nombre de contrats
      final agencesStats = await _getAgencesStats(compagnieId);
      final topAgences = agencesStats.take(5).toList();

      // Top agents par performance
      final agentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      List<Map<String, dynamic>> agentsPerformance = [];

      for (var agentDoc in agentsSnapshot.docs) {
        final agentData = agentDoc.data();
        final agentId = agentDoc.id;

        final agentContracts = await _firestore
            .collection('contrats')
            .where('agentId', isEqualTo: agentId)
            .get();

        final contractsThisMonth = agentContracts.docs.where((doc) {
          final createdAt = (doc.data()['createdAt'] as Timestamp?)?.toDate();
          return createdAt != null && createdAt.isAfter(thisMonth);
        }).length;

        agentsPerformance.add({
          'agentId': agentId,
          'nom': '${agentData['prenom']} ${agentData['nom']}',
          'agenceNom': agentData['agenceNom'] ?? 'Agence inconnue',
          'totalContrats': agentContracts.docs.length,
          'contractsThisMonth': contractsThisMonth,
          'isActive': agentData['isActive'] ?? false,
        });
      }

      // Trier par performance
      agentsPerformance.sort((a, b) => (b['totalContrats'] as int).compareTo(a['totalContrats'] as int));

      return {
        'topAgences': topAgences,
        'topAgents': agentsPerformance.take(10).toList(),
        'totalActiveAgents': agentsPerformance.where((agent) => agent['isActive']).length,
      };

    } catch (e) {
      debugPrint('[COMPAGNIE_BI] ❌ Erreur statistiques performance: $e');
      return {};
    }
  }

  /// 📊 Statistiques comparatives
  static Future<Map<String, dynamic>> _getComparativeStats(String compagnieId) async {
    try {
      final agencesStats = await _getAgencesStats(compagnieId);
      
      if (agencesStats.isEmpty) {
        return {
          'bestPerformingAgence': null,
          'worstPerformingAgence': null,
          'averageContractsPerAgence': 0,
          'averagePrimesPerAgence': 0,
        };
      }

      final bestAgence = agencesStats.first;
      final worstAgence = agencesStats.last;
      
      final totalContrats = agencesStats.fold<int>(0, (sum, agence) => sum + (agence['totalContrats'] as int));
      final totalPrimes = agencesStats.fold<double>(0, (sum, agence) => sum + (agence['totalPrimes'] as double));

      return {
        'bestPerformingAgence': bestAgence,
        'worstPerformingAgence': worstAgence,
        'averageContractsPerAgence': totalContrats / agencesStats.length,
        'averagePrimesPerAgence': totalPrimes / agencesStats.length,
        'agencesAboveAverage': agencesStats.where((agence) => 
          (agence['totalContrats'] as int) > (totalContrats / agencesStats.length)
        ).length,
      };

    } catch (e) {
      debugPrint('[COMPAGNIE_BI] ❌ Erreur statistiques comparatives: $e');
      return {};
    }
  }

  /// 📊 Calculer le score de performance d'une agence
  static double _calculatePerformanceScore(int totalContrats, int contratsActifs, int agentsActifs) {
    if (totalContrats == 0 || agentsActifs == 0) return 0;
    
    // Score basé sur le ratio contrats actifs / total et contrats par agent
    final activeRatio = contratsActifs / totalContrats;
    final contractsPerAgent = totalContrats / agentsActifs;
    
    return (activeRatio * 50) + (contractsPerAgent * 5);
  }

  /// 📊 Récupérer les alertes de toutes les agences
  static Future<Map<String, dynamic>> getCompagnieAlerts(String compagnieId) async {
    try {
      final agencesSnapshot = await _firestore
          .collection('agences')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      List<Map<String, dynamic>> allAlerts = [];
      Map<String, int> alertsByAgence = {};

      for (var agenceDoc in agencesSnapshot.docs) {
        final agenceId = agenceDoc.id;
        final agenceNom = agenceDoc.data()['nom'] ?? 'Agence inconnue';

        // Récupérer les contrats expirants de cette agence
        final now = DateTime.now();
        final in30Days = now.add(const Duration(days: 30));

        final contractsSnapshot = await _firestore
            .collection('contrats')
            .where('agenceId', isEqualTo: agenceId)
            .where('statut', isEqualTo: 'actif')
            .get();

        int agenceAlertsCount = 0;

        for (var contractDoc in contractsSnapshot.docs) {
          final data = contractDoc.data();
          final dateFin = (data['dateFin'] as Timestamp?)?.toDate();

          if (dateFin != null && dateFin.isAfter(now) && dateFin.isBefore(in30Days)) {
            final daysUntilExpiry = dateFin.difference(now).inDays;
            
            String severity = 'low';
            if (daysUntilExpiry <= 7) {
              severity = 'high';
            } else if (daysUntilExpiry <= 15) {
              severity = 'medium';
            }

            allAlerts.add({
              'id': contractDoc.id,
              'type': 'contract_expiring',
              'severity': severity,
              'agenceId': agenceId,
              'agenceNom': agenceNom,
              'contractNumber': data['numeroContrat'],
              'daysUntilExpiry': daysUntilExpiry,
              'conducteurName': data['conducteurNom'] ?? 'Conducteur inconnu',
            });

            agenceAlertsCount++;
          }
        }

        if (agenceAlertsCount > 0) {
          alertsByAgence[agenceNom] = agenceAlertsCount;
        }
      }

      // Trier les alertes par urgence
      allAlerts.sort((a, b) => (a['daysUntilExpiry'] as int).compareTo(b['daysUntilExpiry'] as int));

      return {
        'allAlerts': allAlerts,
        'alertsByAgence': alertsByAgence,
        'totalAlerts': allAlerts.length,
        'urgentAlerts': allAlerts.where((alert) => alert['severity'] == 'high').length,
      };

    } catch (e) {
      debugPrint('[COMPAGNIE_BI] ❌ Erreur alertes compagnie: $e');
      return {
        'allAlerts': [],
        'alertsByAgence': {},
        'totalAlerts': 0,
        'urgentAlerts': 0,
      };
    }
  }

  /// 📊 Statistiques vides par défaut
  static Map<String, dynamic> _getEmptyStatistics() {
    return {
      'global': {},
      'agences': [],
      'financial': {},
      'performance': {},
      'comparative': {},
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }
}
