import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_constants.dart';

/// 🎨 Thème moderne de l'application d'assurance
class AppTheme {
  // 🎨 Couleurs principales
  static const Color primaryColor = Color(0xFF1976D2); // Bleu professionnel
  static const Color secondaryColor = Color(0xFFFFC107); // Jaune/Orange
  static const Color accentColor = Color(0xFF4CAF50); // Vert succès
  static const Color errorColor = Color(0xFFF44336); // Rouge erreur
  static const Color warningColor = Color(0xFFFF9800); // Orange avertissement
  static const Color successColor = Color(0xFF4CAF50); // Vert succès
  static const Color infoColor = Color(0xFF2196F3); // Bleu info

  // 🌈 Palette de couleurs étendues
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color dividerColor = Color(0xFFE0E0E0);
  
  // 📝 Couleurs de texte
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  // 🎯 Couleurs spécifiques aux rôles
  static const Color adminColor = Color(0xFF9C27B0); // Violet
  static const Color agentColor = Color(0xFF2196F3); // Bleu
  static const Color driverColor = Color(0xFF4CAF50); // Vert
  static const Color expertColor = Color(0xFFFF5722); // Orange foncé
  
  /// 🌞 Thème clair
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // 🎨 Schéma de couleurs
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: errorColor,
        surface: surfaceColor,
        onPrimary: textOnPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onError: textOnPrimary,
      ),
      
      // 📱 AppBar
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: textOnPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: textOnPrimary),
      ),
      
      // 🔘 Boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textOnPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignConstants.radiusM),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignConstants.radiusM),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // 📝 Champs de saisie avec couleur de texte forcée
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFFFF), // Blanc absolu
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignConstants.radiusM),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignConstants.radiusM),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignConstants.radiusM),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignConstants.radiusM),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: textHint),
        labelStyle: const TextStyle(color: textSecondary),
      ),

      // 📝 Style de texte global pour les champs de saisie
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: Color(0xFF1976D2), // Bleu pour la sélection
        selectionHandleColor: primaryColor,
      ),
      
      // 🃏 Cartes
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignConstants.radiusL),
        ),
        color: cardColor,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // 📋 Listes
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: textSecondary,
        textColor: textPrimary,
      ),
      
      // 🎛️ Autres composants
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        labelStyle: const TextStyle(color: textPrimary),
        side: const BorderSide(color: dividerColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignConstants.radiusM),
        ),
      ),
      
      // 📱 Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // 🎨 Typographie
      textTheme: _buildTextTheme(),
      
      // 🔔 SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(color: textOnPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignConstants.radiusM),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // 🎭 Dialog
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignConstants.radiusL),
        ),
        elevation: 8,
      ),
      
      // 🎚️ Slider
      sliderTheme: const SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: dividerColor,
        thumbColor: primaryColor,
      ),
      
      // ✅ Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return null;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignConstants.radiusS),
        ),
      ),

      // 🔘 Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return null;
        }),
      ),

      // 🎯 Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withValues(alpha: 0.5);
          }
          return null;
        }),
      ),
    );
  }
  
  /// 🌙 Thème sombre (pour une future implémentation)
  static ThemeData get darkTheme {
    return lightTheme.copyWith(
      brightness: Brightness.dark,
      // TODO: Implémenter le thème sombre
    );
  }
  
  /// 📝 Construction de la typographie
  static TextTheme _buildTextTheme() {
    return const TextTheme(
      // Titres
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        height: 1.2,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        height: 1.2,
      ),
      
      // En-têtes
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: 1.3,
      ),
      
      // Titres
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: 1.4,
      ),
      
      // Corps de texte
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textPrimary,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textPrimary,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: textSecondary,
        height: 1.5,
      ),
      
      // Labels
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        height: 1.4,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        height: 1.4,
      ),
    );
  }
  
  /// 🎨 Couleurs spécifiques aux rôles
  static Color getRoleColor(String role) {
    switch (role) {
      case 'super_admin':
      case 'company_admin':
      case 'agency_admin':
        return adminColor;
      case 'agent':
        return agentColor;
      case 'driver':
        return driverColor;
      case 'expert':
        return expertColor;
      default:
        return primaryColor;
    }
  }
  
  /// 🎯 Couleurs de statut
  static Color getStatusColor(String status) {
    switch (status) {
      case 'active':
      case 'approved':
        return accentColor;
      case 'pending':
        return warningColor;
      case 'rejected':
      case 'suspended':
        return errorColor;
      default:
        return textSecondary;
    }
  }
}
