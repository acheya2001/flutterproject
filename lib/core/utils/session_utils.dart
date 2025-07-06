import 'package:flutter/material.dart';

class SessionUtils {
  static Color getPositionColor(String position) {
    switch (position) {
      case 'A':
        return const Color(0xFF0369A1); // Bleu
      case 'B':
        return const Color(0xFFEF4444); // Rouge
      case 'C':
        return const Color(0xFF047857); // Vert
      case 'D':
        return const Color(0xFFB45309); // Orange
      default:
        return const Color(0xFF6B7280); // Gris
    }
  }

  static String getPositionLabel(String position) {
    return 'Conducteur $position';
  }
}
