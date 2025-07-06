import 'package:flutter/material.dart';
import 'insurance_colors.dart';

/// 📊 Styles du thème assurance
class InsuranceStyles {
  static const TextStyle titleLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: Colors.black87,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: Colors.black54,
  );

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withValues(alpha: 0.1),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration get primaryGradient => BoxDecoration(
    gradient: const LinearGradient(
      colors: [InsuranceColors.primary, InsuranceColors.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(12),
  );
}
