import 'package:flutter/material.dart';
import '../../../../core/theme/modern_theme.dart';
import '../../models/professional_request_model_final.dart';

/// 📊 Widget d'en-tête avec statistiques des demandes
class RequestStatsHeader extends StatelessWidget {
  final List<ProfessionalRequestModel> requests;

  const RequestStatsHeader({
    super.key,
    required this.requests,
  });

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();
    
    return Container(
      margin: const EdgeInsets.all(ModernTheme.spacingM),
      decoration: ModernTheme.cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(ModernTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Text(
              'Aperçu des demandes',
              style: ModernTheme.headingSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: ModernTheme.spacingM),
            
            // Statistiques principales
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Total',
                    value: stats['total'].toString(),
                    icon: Icons.inbox,
                    color: ModernTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: ModernTheme.spacingS),
                Expanded(
                  child: _buildStatCard(
                    title: 'En attente',
                    value: stats['en_attente'].toString(),
                    icon: Icons.pending_actions,
                    color: ModernTheme.warningColor,
                  ),
                ),
                const SizedBox(width: ModernTheme.spacingS),
                Expanded(
                  child: _buildStatCard(
                    title: 'Approuvées',
                    value: stats['approuvees'].toString(),
                    icon: Icons.check_circle,
                    color: ModernTheme.successColor,
                  ),
                ),
                const SizedBox(width: ModernTheme.spacingS),
                Expanded(
                  child: _buildStatCard(
                    title: 'Rejetées',
                    value: stats['rejetees'].toString(),
                    icon: Icons.cancel,
                    color: ModernTheme.errorColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: ModernTheme.spacingM),
            
            // Statistiques par type
            Row(
              children: [
                Expanded(
                  child: _buildTypeCard(
                    title: 'Agents',
                    value: stats['agents'].toString(),
                    icon: Icons.people,
                    color: ModernTheme.secondaryColor,
                  ),
                ),
                const SizedBox(width: ModernTheme.spacingM),
                Expanded(
                  child: _buildTypeCard(
                    title: 'Experts',
                    value: stats['experts'].toString(),
                    icon: Icons.engineering,
                    color: ModernTheme.accentColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 📊 Carte de statistique principale
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(ModernTheme.spacingS),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: ModernTheme.headingSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: ModernTheme.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 👥 Carte de type de compte
  Widget _buildTypeCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(ModernTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: ModernTheme.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: ModernTheme.headingSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  title,
                  style: ModernTheme.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Calculer les statistiques
  Map<String, int> _calculateStats() {
    final stats = {
      'total': requests.length,
      'en_attente': 0,
      'approuvees': 0,
      'rejetees': 0,
      'agents': 0,
      'experts': 0,
    };

    for (final request in requests) {
      // Compter par statut
      switch (request.statut) {
        case 'en_attente':
          stats['en_attente'] = stats['en_attente']! + 1;
          break;
        case 'approuvee':
          stats['approuvees'] = stats['approuvees']! + 1;
          break;
        case 'rejetee':
          stats['rejetees'] = stats['rejetees']! + 1;
          break;
      }

      // Compter par type
      switch (request.typeCompte) {
        case 'agent':
          stats['agents'] = stats['agents']! + 1;
          break;
        case 'expert':
          stats['experts'] = stats['experts']! + 1;
          break;
      }
    }

    return stats;
  }
}

/// 📊 Widget de statistique rapide
class QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const QuickStat({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
      child: Container(
        padding: const EdgeInsets.all(ModernTheme.spacingS),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: ModernTheme.spacingXS),
            Text(
              value,
              style: ModernTheme.headingSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: ModernTheme.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// 📈 Widget de tendance
class TrendIndicator extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final bool isPositive;

  const TrendIndicator({
    super.key,
    required this.label,
    required this.value,
    required this.trend,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final trendColor = isPositive ? ModernTheme.successColor : ModernTheme.errorColor;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ModernTheme.bodySmall.copyWith(
            color: ModernTheme.textLight,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(
              value,
              style: ModernTheme.headingSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: ModernTheme.spacingXS),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: trendColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: trendColor,
                    size: 12,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    trend,
                    style: TextStyle(
                      color: trendColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
