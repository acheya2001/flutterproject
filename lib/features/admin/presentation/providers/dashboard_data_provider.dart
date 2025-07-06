import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/modern_theme.dart';
import '../../services/dashboard_data_service.dart';

/// 📊 Provider pour les statistiques générales
final dashboardStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  return await DashboardDataService.getGeneralStats();
});

/// 🕒 Provider pour l'activité récente
final recentActivityProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await DashboardDataService.getRecentActivity();
});

/// 📈 Provider pour les statistiques détaillées
final detailedStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await DashboardDataService.getDetailedStats();
});

/// 🔄 Provider pour les statistiques en temps réel (stream)
final statsStreamProvider = StreamProvider<Map<String, int>>((ref) {
  return DashboardDataService.getStatsStream();
});

/// 🔄 Provider pour l'activité en temps réel (stream)
final activityStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return DashboardDataService.getActivityStream();
});

/// 📊 Provider pour calculer les tendances
final statsTrendsProvider = Provider<Map<String, String>>((ref) {
  final detailedStats = ref.watch(detailedStatsProvider);
  
  return detailedStats.when(
    data: (stats) {
      final weekly = stats['weekly'] as Map<String, dynamic>? ?? {};
      final monthly = stats['monthly'] as Map<String, dynamic>? ?? {};
      
      // Calculer les tendances (simulation basée sur les données)
      final weeklyRequests = weekly['requests'] as int? ?? 0;
      final monthlyRequests = monthly['requests'] as int? ?? 0;
      final weeklyClaims = weekly['claims'] as int? ?? 0;
      final monthlyClaims = monthly['claims'] as int? ?? 0;
      
      return {
        'users': weeklyRequests > 5 ? '+${weeklyRequests}%' : '+${weeklyRequests}',
        'agencies': monthlyRequests > 10 ? '+3%' : '+1',
        'claims': weeklyClaims > 0 ? '-${weeklyClaims}%' : '0',
        'pending': weeklyRequests > 0 ? '+${weeklyRequests}' : '0',
      };
    },
    loading: () => {
      'users': '...',
      'agencies': '...',
      'claims': '...',
      'pending': '...',
    },
    error: (_, __) => {
      'users': 'N/A',
      'agencies': 'N/A',
      'claims': 'N/A',
      'pending': 'N/A',
    },
  );
});

/// 🎯 Provider pour les actions rapides avec compteurs réels
final quickActionsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final stats = ref.watch(dashboardStatsProvider);
  
  return stats.when(
    data: (data) => [
      {
        'title': 'Nouvelle Agence',
        'icon': Icons.add_business_rounded,
        'color': ModernTheme.primaryColor,
        'count': null,
      },
      {
        'title': 'Valider Demandes',
        'icon': Icons.check_circle_rounded,
        'color': ModernTheme.successColor,
        'count': data['pending_requests'] ?? 0,
      },
      {
        'title': 'Voir Rapports',
        'icon': Icons.assessment_rounded,
        'color': ModernTheme.secondaryColor,
        'count': data['total_claims'] ?? 0,
      },
      {
        'title': 'Paramètres',
        'icon': Icons.settings_rounded,
        'color': ModernTheme.accentColor,
        'count': null,
      },
    ],
    loading: () => [
      {
        'title': 'Nouvelle Agence',
        'icon': Icons.add_business_rounded,
        'color': ModernTheme.primaryColor,
        'count': null,
      },
      {
        'title': 'Valider Demandes',
        'icon': Icons.check_circle_rounded,
        'color': ModernTheme.successColor,
        'count': '...',
      },
      {
        'title': 'Voir Rapports',
        'icon': Icons.assessment_rounded,
        'color': ModernTheme.secondaryColor,
        'count': '...',
      },
      {
        'title': 'Paramètres',
        'icon': Icons.settings_rounded,
        'color': ModernTheme.accentColor,
        'count': null,
      },
    ],
    error: (_, __) => [
      {
        'title': 'Nouvelle Agence',
        'icon': Icons.add_business,
        'color': Colors.blue,
        'count': null,
      },
      {
        'title': 'Valider Demandes',
        'icon': Icons.check_circle,
        'color': Colors.green,
        'count': 'Err',
      },
      {
        'title': 'Voir Rapports',
        'icon': Icons.assessment,
        'color': Colors.purple,
        'count': 'Err',
      },
      {
        'title': 'Paramètres',
        'icon': Icons.settings,
        'color': Colors.grey,
        'count': null,
      },
    ],
  );
});
