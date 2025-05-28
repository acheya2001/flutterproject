import 'package:flutter/material.dart';

class SessionUtils {
  static const Map<String, Color> positionColors = {
    'A': Color(0xFF10B981), // Vert
    'B': Color(0xFFEF4444), // Rouge
    'C': Color(0xFF6366F1), // Bleu
    'D': Color(0xFFF59E0B), // Orange
    'E': Color(0xFF8B5CF6), // Violet
    'F': Color(0xFF06B6D4), // Cyan
  };

  static Color getPositionColor(String position) {
    return positionColors[position] ?? const Color(0xFF6366F1);
  }

  static String getPositionName(String position) {
    return 'Conducteur $position';
  }

  static String formatSessionCode(String code) {
    return code.toUpperCase();
  }

  static bool isValidSessionCode(String code) {
    return code.isNotEmpty && code.startsWith('SESS_');
  }
}
