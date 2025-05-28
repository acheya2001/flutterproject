import 'package:flutter/material.dart';

class AppTheme {
  // Couleurs principales - Palette pastel moderne
  static const Color primaryColor = Color(0xFF5B8FF9); // Bleu pastel
  static const Color secondaryColor = Color(0xFF61DDAA); // Vert menthe
  static const Color accentColor = Color(0xFFFFA8B8); // Rose pastel
  
  // Couleurs supplémentaires
  static const Color yellowPastel = Color(0xFFFFD666); // Jaune pastel
  static const Color purplePastel = Color(0xFFB37FEB); // Violet pastel
  static const Color orangePastel = Color(0xFFFF9F7F); // Orange pastel
  
  // Couleurs neutres
  static const Color backgroundColor = Color(0xFFF7F9FC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color errorColor = Color(0xFFF5222D);
  static const Color successColor = Color(0xFF52C41A);
  static const Color warningColor = Color(0xFFFAAD14);
  static const Color infoColor = Color(0xFF1890FF);
  
  // Couleurs de texte
  static const Color textPrimaryColor = Color(0xFF2E384D);
  static const Color textSecondaryColor = Color(0xFF8798AD);
  static const Color textDisabledColor = Color(0xFFB8C4D0);
  static const Color textOnPrimaryColor = Color(0xFFFFFFFF);
  
  // Couleurs de bordure
  static const Color borderColor = Color(0xFFE9EDF2);
  static const Color dividerColor = Color(0xFFF0F3F8);
  
  // Thème clair
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      surface: surfaceColor,
      error: errorColor,
      onPrimary: textOnPrimaryColor,
      onSecondary: textPrimaryColor,
      onSurface: textPrimaryColor,
      onError: textOnPrimaryColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: textOnPrimaryColor,
      elevation: 0,
      centerTitle: true,
    ),
    // Utilisation de CardThemeData au lieu de CardTheme
    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      shadowColor: const Color(0x195B8FF9), // primaryColor.withAlpha(25)
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      labelStyle: const TextStyle(color: textSecondaryColor),
      hintStyle: const TextStyle(color: textDisabledColor),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      displayMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      displaySmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textSecondaryColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textPrimaryColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textPrimaryColor,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimaryColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: textSecondaryColor,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.normal,
        color: textSecondaryColor,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: dividerColor,
      thickness: 1,
      space: 1,
    ),
    checkboxTheme: CheckboxThemeData(
      // Utilisation de WidgetStateProperty au lieu de MaterialStateProperty
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return Colors.transparent;
      }),
      side: const BorderSide(color: borderColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    radioTheme: RadioThemeData(
      // Utilisation de WidgetStateProperty au lieu de MaterialStateProperty
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return textDisabledColor;
      }),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondaryColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
  
  // Thème sombre (désactivé - nous utilisons uniquement le thème clair)
  static final ThemeData darkTheme = lightTheme;
}