import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// 📊 Service pour récupérer les données réelles du dashboard
class DashboardDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📈 Obtenir les statistiques générales
  static Future<Map<String, int>> getGeneralStats() async {
    try {
      debugPrint('[DASHBOARD_DATA] 📊 Récupération des statistiques...');

      // Compter les utilisateurs par collection
      final results = await Future.wait([
        _countDocuments('users'),
        _countDocuments('agents_assurance'),
        _countDocuments('experts'),
        _countDocuments('conducteurs'),
        _countDocuments('compagnies_assurance'),
        _countDocuments('agences'),
        _countDocuments('constats'),
        _countDocuments('professional_account_requests'),
      ]);

      final stats = {
        'total_users': results[0],
        'total_agents': results[1],
        'total_experts': results[2],
        'total_conducteurs': results[3],
        'total_companies': results[4],
        'total_agencies': results[5],
        'total_claims': results[6],
        'pending_requests': results[7],
      };

      debugPrint('[DASHBOARD_DATA] ✅ Statistiques récupérées: $stats');

      return stats;

    } catch (e) {
      debugPrint('[DASHBOARD_DATA] ❌ Erreur récupération stats: $e');
      return {
        'total_users': 0,
        'total_agents': 0,
        'total_experts': 0,
        'total_conducteurs': 0,
        'total_companies': 0,
        'total_agencies': 0,
        'total_claims': 0,
        'pending_requests': 0,
      };
    }
  }

  /// 🔢 Compter les documents dans une collection
  static Future<int> _countDocuments(String collection) async {
    try {
      final snapshot = await _firestore.collection(collection).get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('[DASHBOARD_DATA] ❌ Erreur comptage $collection: $e');
      return 0;
    }
  }

  /// 🔢 Compter les documents avec fallback
  static Future<int> _countDocumentsWithFallback(String collection) async {
    try {
      final snapshot = await _firestore.collection(collection).get();
      final count = snapshot.docs.length;
      debugPrint('[DASHBOARD_DATA] 📊 Collection $collection: $count documents');
      return count;
    } catch (e) {
      debugPrint('[DASHBOARD_DATA] ❌ Erreur comptage $collection: $e');
      return 0;
    }
  }

  /// 🎯 Données de démonstration
  static Map<String, int> _getDemoStats() {
    return {
      'total_users': 15,
      'total_agents': 8,
      'total_experts': 5,
      'total_conducteurs': 25,
      'total_companies': 6,
      'total_agencies': 12,
      'total_claims': 18,
      'pending_requests': 7,
    };
  }

  /// 🕒 Obtenir l'activité récente
  static Future<List<Map<String, dynamic>>> getRecentActivity() async {
    try {
      debugPrint('[DASHBOARD_DATA] 🕒 Récupération activité récente...');

      final activities = <Map<String, dynamic>>[];

      // Récupérer les dernières demandes de comptes professionnels
      final requestsSnapshot = await _firestore
          .collection('professional_account_requests')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      for (final doc in requestsSnapshot.docs) {
        final data = doc.data();
        activities.add({
          'type': 'request',
          'icon': Icons.person_add,
          'color': Colors.blue,
          'title': 'Nouvelle demande ${data['role'] ?? 'professionnel'}',
          'subtitle': '${data['firstName']} ${data['lastName']} - ${data['companyName'] ?? 'N/A'}',
          'time': _formatTime(data['createdAt']),
          'timestamp': data['createdAt'],
        });
      }

      // Récupérer les derniers sinistres
      final claimsSnapshot = await _firestore
          .collection('constats')
          .orderBy('dateCreation', descending: true)
          .limit(2)
          .get();

      for (final doc in claimsSnapshot.docs) {
        final data = doc.data();
        activities.add({
          'type': 'claim',
          'icon': Icons.car_crash,
          'color': Colors.orange,
          'title': 'Nouveau sinistre déclaré',
          'subtitle': 'Réf: ${doc.id.substring(0, 8)} - ${data['lieu'] ?? 'Lieu non spécifié'}',
          'time': _formatTime(data['dateCreation']),
          'timestamp': data['dateCreation'],
        });
      }

      // Récupérer les dernières agences créées
      final agenciesSnapshot = await _firestore
          .collection('agences')
          .orderBy('createdAt', descending: true)
          .limit(2)
          .get();

      for (final doc in agenciesSnapshot.docs) {
        final data = doc.data();
        activities.add({
          'type': 'agency',
          'icon': Icons.business,
          'color': Colors.green,
          'title': 'Nouvelle agence créée',
          'subtitle': '${data['nom']} - ${data['ville'] ?? 'N/A'}',
          'time': _formatTime(data['createdAt']),
          'timestamp': data['createdAt'],
        });
      }

      // Trier par timestamp et prendre les 5 plus récents
      activities.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      final recentActivities = activities.take(5).toList();
      debugPrint('[DASHBOARD_DATA] ✅ ${recentActivities.length} activités récupérées');
      
      return recentActivities;

    } catch (e) {
      debugPrint('[DASHBOARD_DATA] ❌ Erreur récupération activité: $e');
      return [];
    }
  }

  /// 📅 Formater le temps relatif
  static String _formatTime(dynamic timestamp) {
    try {
      if (timestamp == null) return 'Date inconnue';
      
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        return 'Date invalide';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'À l\'instant';
      } else if (difference.inMinutes < 60) {
        return 'Il y a ${difference.inMinutes} min';
      } else if (difference.inHours < 24) {
        return 'Il y a ${difference.inHours}h';
      } else if (difference.inDays < 7) {
        return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
      } else {
        return 'Il y a ${(difference.inDays / 7).floor()} semaine${(difference.inDays / 7).floor() > 1 ? 's' : ''}';
      }
    } catch (e) {
      debugPrint('[DASHBOARD_DATA] ❌ Erreur formatage temps: $e');
      return 'Date inconnue';
    }
  }

  /// 📊 Obtenir les statistiques détaillées par période
  static Future<Map<String, dynamic>> getDetailedStats() async {
    try {
      debugPrint('[DASHBOARD_DATA] 📊 Récupération statistiques détaillées...');

      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));
      final lastMonth = now.subtract(const Duration(days: 30));

      // Statistiques de la semaine
      final weeklyRequests = await _firestore
          .collection('professional_account_requests')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(lastWeek))
          .get();

      final weeklyClaims = await _firestore
          .collection('constats')
          .where('dateCreation', isGreaterThan: Timestamp.fromDate(lastWeek))
          .get();

      // Statistiques du mois
      final monthlyRequests = await _firestore
          .collection('professional_account_requests')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(lastMonth))
          .get();

      final monthlyClaims = await _firestore
          .collection('constats')
          .where('dateCreation', isGreaterThan: Timestamp.fromDate(lastMonth))
          .get();

      final detailedStats = {
        'weekly': {
          'requests': weeklyRequests.docs.length,
          'claims': weeklyClaims.docs.length,
        },
        'monthly': {
          'requests': monthlyRequests.docs.length,
          'claims': monthlyClaims.docs.length,
        },
      };

      debugPrint('[DASHBOARD_DATA] ✅ Statistiques détaillées: $detailedStats');
      return detailedStats;

    } catch (e) {
      debugPrint('[DASHBOARD_DATA] ❌ Erreur stats détaillées: $e');
      return {
        'weekly': {'requests': 0, 'claims': 0},
        'monthly': {'requests': 0, 'claims': 0},
      };
    }
  }

  /// 🔄 Stream des statistiques en temps réel
  static Stream<Map<String, int>> getStatsStream() {
    return Stream.periodic(const Duration(minutes: 5), (_) async {
      return await getGeneralStats();
    }).asyncMap((future) => future);
  }

  /// 🔄 Stream de l'activité récente en temps réel
  static Stream<List<Map<String, dynamic>>> getActivityStream() {
    return Stream.periodic(const Duration(minutes: 2), (_) async {
      return await getRecentActivity();
    }).asyncMap((future) => future);
  }
}
