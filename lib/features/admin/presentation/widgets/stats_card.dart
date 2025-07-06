import 'package:flutter/material.dart';
import '../../../../core/theme/modern_theme.dart';

/// 📊 Widget moderne pour afficher une statistique avec icône et tendance
class StatsCard extends StatelessWidget {
  final String title;
  final dynamic value;
  final IconData icon;
  final Color color;
  final String? trend;
  final bool isLoading;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ModernTheme.cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(6), // Padding ultra-minimal
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // En-tête avec icône et tendance
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ModernTheme.iconContainer(
                  icon: icon,
                  color: color,
                  size: 24, // Taille ultra-réduite
                  iconSize: 12, // Icône ultra-petite
                ),
                if (trend != null && !isLoading)
                  _buildTrendBadge(),
              ],
            ),

            const SizedBox(height: 1), // Espacement absolu minimal

            // Valeur principale
            isLoading
                ? _buildLoadingIndicator()
                : Text(
                    value.toString(),
                    style: ModernTheme.headingMedium.copyWith(
                      fontSize: 17, // Taille absolu minimale
                      fontWeight: FontWeight.w700,
                      height: 1.0, // Hauteur de ligne minimale
                    ),
                  ),

            // Pas d'espacement

            // Titre
            Text(
              title,
              style: ModernTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 10, // Taille absolu minimale
                height: 1.0, // Hauteur de ligne minimale
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendBadge() {
    final trendColor = _getTrendColor();
    final isPositive = trend!.startsWith('+');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6, // Padding réduit
        vertical: 2, // Padding réduit
      ),
      decoration: BoxDecoration(
        color: trendColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
        border: Border.all(
          color: trendColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: trendColor,
            size: 10, // Icône plus petite
          ),
          const SizedBox(width: 2),
          Text(
            trend!,
            style: ModernTheme.bodySmall.copyWith(
              color: trendColor,
              fontWeight: FontWeight.w600,
              fontSize: 10, // Texte plus petit
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      width: 60,
      height: 8,
      decoration: BoxDecoration(
        color: ModernTheme.textLight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
        child: LinearProgressIndicator(
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }

  Color _getTrendColor() {
    if (trend == null) return ModernTheme.textLight;
    if (trend!.startsWith('+')) return ModernTheme.successColor;
    if (trend!.startsWith('-')) return ModernTheme.errorColor;
    return ModernTheme.textLight;
  }
}
