import 'package:flutter/material.dart';
import '../../../../core/theme/modern_theme.dart';

/// 🎯 Widget moderne pour les actions rapides du dashboard
class DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const DashboardCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ModernTheme.cardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(ModernTheme.spacingM),
            child: Row(
              children: [
                // Icône avec container moderne
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.2),
                        color.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),

                const SizedBox(width: ModernTheme.spacingM),

                // Titre
                Expanded(
                  child: Text(
                    title,
                    style: ModernTheme.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Badge et flèche
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (badge != null && badge!.isNotEmpty && badge != '0')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ModernTheme.spacingS,
                          vertical: ModernTheme.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: ModernTheme.errorGradient,
                          ),
                          borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
                          boxShadow: [
                            BoxShadow(
                              color: ModernTheme.errorColor.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          badge!,
                          style: ModernTheme.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const SizedBox(width: ModernTheme.spacingS),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: ModernTheme.textLight,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
