import 'package:flutter/material.dart';

/// 🎨 Thème moderne et élégant pour l'application
class ModernTheme {
  // Couleurs principales modernes
  static const Color primaryColor = Color(0xFF6366F1); // Indigo moderne
  static const Color secondaryColor = Color(0xFF8B5CF6); // Violet élégant
  static const Color accentColor = Color(0xFF06B6D4); // Cyan moderne
  
  // Couleurs de fond
  static const Color backgroundColor = Color(0xFFF8FAFC); // Gris très clair
  static const Color surfaceColor = Color(0xFFFFFFFF); // Blanc pur
  static const Color cardColor = Color(0xFFFFFFFF); // Blanc pour les cards
  
  // Couleurs de texte
  static const Color textPrimary = Color(0xFF1E293B); // Gris foncé moderne
  static const Color textSecondary = Color(0xFF64748B); // Gris moyen
  static const Color textLight = Color(0xFF94A3B8); // Gris clair
  static const Color textDark = Color(0xFF1F2937); // Gris très foncé

  // Couleurs de bordure et séparateurs
  static const Color borderColor = Color(0xFFE5E7EB); // Gris clair pour bordures
  static const Color dividerColor = Color(0xFFF3F4F6); // Gris très clair pour dividers
  
  // Couleurs d'état modernes
  static const Color successColor = Color(0xFF10B981); // Vert émeraude
  static const Color warningColor = Color(0xFFF59E0B); // Orange moderne
  static const Color errorColor = Color(0xFFEF4444); // Rouge moderne
  static const Color infoColor = Color(0xFF3B82F6); // Bleu moderne
  
  // Couleurs de gradient
  static const List<Color> primaryGradient = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
  ];
  
  static const List<Color> successGradient = [
    Color(0xFF10B981),
    Color(0xFF059669),
  ];
  
  static const List<Color> warningGradient = [
    Color(0xFFF59E0B),
    Color(0xFFD97706),
  ];
  
  static const List<Color> errorGradient = [
    Color(0xFFEF4444),
    Color(0xFFDC2626),
  ];
  
  // Ombres modernes
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 1,
      offset: Offset(0, 1),
    ),
  ];
  
  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 25,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 6,
      offset: Offset(0, 4),
    ),
  ];
  
  // Rayons de bordure
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  
  // Espacements
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  // Styles de texte modernes
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.25,
  );
  
  static const TextStyle headingSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.4,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textLight,
    height: 1.3,
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );
  
  // Méthodes utilitaires
  static BoxDecoration cardDecoration({
    Color? color,
    List<BoxShadow>? boxShadow,
    double? borderRadius,
  }) {
    return BoxDecoration(
      color: color ?? cardColor,
      borderRadius: BorderRadius.circular(borderRadius ?? radiusMedium),
      boxShadow: boxShadow ?? cardShadow,
    );
  }
  
  static BoxDecoration gradientDecoration({
    required List<Color> colors,
    double? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
      borderRadius: BorderRadius.circular(borderRadius ?? radiusMedium),
      boxShadow: boxShadow ?? cardShadow,
    );
  }
  
  static Widget iconContainer({
    required IconData icon,
    required Color color,
    double? size,
    double? iconSize,
  }) {
    return Container(
      width: size ?? 48,
      height: size ?? 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      child: Icon(
        icon,
        color: color,
        size: iconSize ?? 24,
      ),
    );
  }
}
