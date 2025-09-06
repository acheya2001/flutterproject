import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 🚨 Service d'alertes et notifications pour Admin Agence
class AdminAgenceAlertsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🚨 Récupérer toutes les alertes pour une agence
  static Future<Map<String, dynamic>> getAgenceAlerts(String agenceId) async {
    try {
      debugPrint('[ADMIN_AGENCE_ALERTS] 🚨 Récupération alertes agence: $agenceId');

      final results = await Future.wait([
        _getExpiringContracts(agenceId),
        _getPerformanceAlerts(agenceId),
        _getFinancialAlerts(agenceId),
        _getSystemAlerts(agenceId),
      ]);

      final alerts = {
        'expiringContracts': results[0],
        'performance': results[1],
        'financial': results[2],
        'system': results[3],
        'summary': _generateAlertsSummary(results),
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      debugPrint('[ADMIN_AGENCE_ALERTS] ✅ ${_getTotalAlertsCount(alerts)} alertes trouvées');
      return alerts;

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_ALERTS] ❌ Erreur récupération alertes: $e');
      return _getEmptyAlerts();
    }
  }

  /// ⏰ Contrats expirant bientôt
  static Future<List<Map<String, dynamic>>> _getExpiringContracts(String agenceId) async {
    try {
      final now = DateTime.now();
      final in30Days = now.add(const Duration(days: 30));

      final contractsSnapshot = await _firestore
          .collection('contrats')
          .where('agenceId', isEqualTo: agenceId)
          .where('statut', isEqualTo: 'actif')
          .get();

      List<Map<String, dynamic>> alerts = [];

      for (var doc in contractsSnapshot.docs) {
        final data = doc.data();
        final dateFin = (data['dateFin'] as Timestamp?)?.toDate();

        if (dateFin != null && dateFin.isAfter(now) && dateFin.isBefore(in30Days)) {
          final daysUntilExpiry = dateFin.difference(now).inDays;
          
          String severity = 'low';
          String message = 'Expire dans $daysUntilExpiry jours';
          
          if (daysUntilExpiry <= 7) {
            severity = 'high';
            message = 'Expire dans $daysUntilExpiry jours - Action urgente requise';
          } else if (daysUntilExpiry <= 15) {
            severity = 'medium';
            message = 'Expire dans $daysUntilExpiry jours - Prévoir le renouvellement';
          }

          alerts.add({
            'id': doc.id,
            'type': 'contract_expiring',
            'severity': severity,
            'title': 'Contrat ${data['numeroContrat']} expire bientôt',
            'message': message,
            'contractNumber': data['numeroContrat'],
            'expiryDate': dateFin.toIso8601String(),
            'daysUntilExpiry': daysUntilExpiry,
            'conducteurName': data['conducteurNom'] ?? 'Conducteur inconnu',
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      }

      // Trier par urgence (moins de jours restants en premier)
      alerts.sort((a, b) => (a['daysUntilExpiry'] as int).compareTo(b['daysUntilExpiry'] as int));

      return alerts;

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_ALERTS] ❌ Erreur contrats expirants: $e');
      return [];
    }
  }

  /// 📊 Alertes de performance
  static Future<List<Map<String, dynamic>>> _getPerformanceAlerts(String agenceId) async {
    try {
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 1);
      final lastMonth = DateTime(now.year, now.month - 1, 1);

      // Récupérer les agents de l'agence
      final agentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('agenceId', isEqualTo: agenceId)
          .where('isActive', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> alerts = [];

      for (var agentDoc in agentsSnapshot.docs) {
        final agentData = agentDoc.data();
        final agentId = agentDoc.id;

        // Compter les contrats ce mois et le mois dernier
        final contractsThisMonth = await _firestore
            .collection('contrats')
            .where('agentId', isEqualTo: agentId)
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(thisMonth))
            .get();

        final contractsLastMonth = await _firestore
            .collection('contrats')
            .where('agentId', isEqualTo: agentId)
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(lastMonth))
            .where('createdAt', isLessThan: Timestamp.fromDate(thisMonth))
            .get();

        final thisMonthCount = contractsThisMonth.docs.length;
        final lastMonthCount = contractsLastMonth.docs.length;

        // Alerte si baisse significative de performance
        if (lastMonthCount > 0 && thisMonthCount < lastMonthCount * 0.5) {
          alerts.add({
            'id': 'performance_$agentId',
            'type': 'performance_drop',
            'severity': 'medium',
            'title': 'Baisse de performance détectée',
            'message': '${agentData['prenom']} ${agentData['nom']} : $thisMonthCount contrats ce mois vs $lastMonthCount le mois dernier',
            'agentId': agentId,
            'agentName': '${agentData['prenom']} ${agentData['nom']}',
            'thisMonthCount': thisMonthCount,
            'lastMonthCount': lastMonthCount,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }

        // Alerte si aucun contrat ce mois
        if (thisMonthCount == 0 && now.day > 15) {
          alerts.add({
            'id': 'no_contracts_$agentId',
            'type': 'no_activity',
            'severity': 'high',
            'title': 'Aucune activité ce mois',
            'message': '${agentData['prenom']} ${agentData['nom']} n\'a créé aucun contrat ce mois',
            'agentId': agentId,
            'agentName': '${agentData['prenom']} ${agentData['nom']}',
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      }

      return alerts;

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_ALERTS] ❌ Erreur alertes performance: $e');
      return [];
    }
  }

  /// 💰 Alertes financières
  static Future<List<Map<String, dynamic>>> _getFinancialAlerts(String agenceId) async {
    try {
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 1);
      final lastMonth = DateTime(now.year, now.month - 1, 1);

      // Récupérer les contrats de ce mois et du mois dernier
      final contractsThisMonth = await _firestore
          .collection('contrats')
          .where('agenceId', isEqualTo: agenceId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(thisMonth))
          .get();

      final contractsLastMonth = await _firestore
          .collection('contrats')
          .where('agenceId', isEqualTo: agenceId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(lastMonth))
          .where('createdAt', isLessThan: Timestamp.fromDate(thisMonth))
          .get();

      double primesThisMonth = 0;
      double primesLastMonth = 0;

      for (var doc in contractsThisMonth.docs) {
        final data = doc.data();
        primesThisMonth += (data['primeAnnuelle'] ?? data['primeAssurance'] ?? 0).toDouble();
      }

      for (var doc in contractsLastMonth.docs) {
        final data = doc.data();
        primesLastMonth += (data['primeAnnuelle'] ?? data['primeAssurance'] ?? 0).toDouble();
      }

      List<Map<String, dynamic>> alerts = [];

      // Alerte si baisse significative du chiffre d'affaires
      if (primesLastMonth > 0 && primesThisMonth < primesLastMonth * 0.7) {
        final dropPercentage = ((primesLastMonth - primesThisMonth) / primesLastMonth * 100).round();
        alerts.add({
          'id': 'revenue_drop',
          'type': 'financial_drop',
          'severity': 'high',
          'title': 'Baisse du chiffre d\'affaires',
          'message': 'Baisse de $dropPercentage% par rapport au mois dernier (${primesThisMonth.toStringAsFixed(0)} DT vs ${primesLastMonth.toStringAsFixed(0)} DT)',
          'thisMonthRevenue': primesThisMonth,
          'lastMonthRevenue': primesLastMonth,
          'dropPercentage': dropPercentage,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      // Objectif mensuel (exemple : 50 000 DT)
      const monthlyTarget = 50000.0;
      if (now.day > 20 && primesThisMonth < monthlyTarget * 0.8) {
        alerts.add({
          'id': 'target_risk',
          'type': 'target_at_risk',
          'severity': 'medium',
          'title': 'Objectif mensuel en danger',
          'message': 'Seulement ${(primesThisMonth / monthlyTarget * 100).toStringAsFixed(1)}% de l\'objectif atteint (${primesThisMonth.toStringAsFixed(0)} DT / ${monthlyTarget.toStringAsFixed(0)} DT)',
          'currentRevenue': primesThisMonth,
          'target': monthlyTarget,
          'completionPercentage': primesThisMonth / monthlyTarget * 100,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      return alerts;

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_ALERTS] ❌ Erreur alertes financières: $e');
      return [];
    }
  }

  /// ⚙️ Alertes système
  static Future<List<Map<String, dynamic>>> _getSystemAlerts(String agenceId) async {
    try {
      List<Map<String, dynamic>> alerts = [];

      // Vérifier les véhicules en attente depuis longtemps
      final pendingVehicles = await _firestore
          .collection('vehicules')
          .where('agenceId', isEqualTo: agenceId)
          .where('etatCompte', isEqualTo: 'En attente')
          .get();

      final now = DateTime.now();
      int oldPendingCount = 0;

      for (var doc in pendingVehicles.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        
        if (createdAt != null) {
          final daysPending = now.difference(createdAt).inDays;
          if (daysPending > 7) {
            oldPendingCount++;
          }
        }
      }

      if (oldPendingCount > 0) {
        alerts.add({
          'id': 'old_pending_vehicles',
          'type': 'system_backlog',
          'severity': 'medium',
          'title': 'Véhicules en attente depuis longtemps',
          'message': '$oldPendingCount véhicules en attente depuis plus de 7 jours',
          'count': oldPendingCount,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      return alerts;

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_ALERTS] ❌ Erreur alertes système: $e');
      return [];
    }
  }

  /// 📋 Générer un résumé des alertes
  static Map<String, dynamic> _generateAlertsSummary(List<List<Map<String, dynamic>>> results) {
    int totalAlerts = 0;
    int highSeverity = 0;
    int mediumSeverity = 0;
    int lowSeverity = 0;

    for (var alertList in results) {
      for (var alert in alertList) {
        totalAlerts++;
        switch (alert['severity']) {
          case 'high':
            highSeverity++;
            break;
          case 'medium':
            mediumSeverity++;
            break;
          case 'low':
            lowSeverity++;
            break;
        }
      }
    }

    return {
      'total': totalAlerts,
      'high': highSeverity,
      'medium': mediumSeverity,
      'low': lowSeverity,
      'hasUrgentAlerts': highSeverity > 0,
      'needsAttention': highSeverity > 0 || mediumSeverity > 3,
    };
  }

  /// 📊 Compter le total des alertes
  static int _getTotalAlertsCount(Map<String, dynamic> alerts) {
    int total = 0;
    total += (alerts['expiringContracts'] as List).length;
    total += (alerts['performance'] as List).length;
    total += (alerts['financial'] as List).length;
    total += (alerts['system'] as List).length;
    return total;
  }

  /// 📊 Alertes vides par défaut
  static Map<String, dynamic> _getEmptyAlerts() {
    return {
      'expiringContracts': <Map<String, dynamic>>[],
      'performance': <Map<String, dynamic>>[],
      'financial': <Map<String, dynamic>>[],
      'system': <Map<String, dynamic>>[],
      'summary': {
        'total': 0,
        'high': 0,
        'medium': 0,
        'low': 0,
        'hasUrgentAlerts': false,
        'needsAttention': false,
      },
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }
}
