import 'package:flutter/material.dart';

class AppTheme {
  // Couleurs principales
  static const Color primaryColor = Color(0xFF0A6CFF);
  static const Color secondaryColor = Color(0xFF00A3FF);
  static const Color accentColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFE53935);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color successColor = Color(0xFF4CAF50);
  
  // Couleurs pour les rôles
  static const Color driverColor = Color(0xFF0A6CFF);
  static const Color insuranceColor = Color(0xFF4CAF50);
  static const Color expertColor = Color(0xFF9C27B0);
  
  // Couleurs de fond
  static const Color scaffoldBackgroundColor = Color(0xFFF5F5F5);
  static const Color cardColor = Colors.white;
  
  // Couleurs de texte
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color textLightColor = Color(0xFFBDBDBD);
  
  // Couleurs ajoutées pour résoudre les erreurs
  static const Color greyColor = Color(0xFF9E9E9E);
  static const Color darkColor = Color(0xFF424242);
  static const Color lightGreyColor = Color(0xFFE0E0E0);
  
  // Thème clair
  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
    ),
    scaffoldBackgroundColor: scaffoldBackgroundColor,
    cardTheme: const CardTheme(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.grey.withAlpha(77), // Remplacé withOpacity par withAlpha
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: primaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: errorColor,
          width: 2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: errorColor,
          width: 2,
        ),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: textPrimaryColor,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        color: textPrimaryColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: TextStyle(
        color: textPrimaryColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: textPrimaryColor,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: TextStyle(
        color: textPrimaryColor,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        color: textPrimaryColor,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(
        color: textPrimaryColor,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: textSecondaryColor,
        fontSize: 14,
      ),
      bodySmall: TextStyle(
        color: textLightColor,
        fontSize: 12,
      ),
    ),
  );
}
