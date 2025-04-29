// lib/core/providers/language_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = const Locale('fr'); // Français par défaut
  
  Locale get locale => _locale;

  // Langues supportées
  final List<Locale> supportedLocales = [
    const Locale('fr'), // Français
    const Locale('ar'), // Arabe
    const Locale('en'), // Anglais
  ];

  // Initialiser la langue à partir des préférences
  Future<void> initLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString('language_code');
    
    if (languageCode != null) {
      _locale = Locale(languageCode);
    }
    
    notifyListeners();
  }

  // Changer la langue
  Future<void> changeLanguage(Locale newLocale) async {
    if (!supportedLocales.contains(newLocale)) return;
    
    _locale = newLocale;
    
    // Sauvegarder la préférence
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', newLocale.languageCode);
    
    notifyListeners();
  }

  // Obtenir le nom de la langue actuelle
  String getCurrentLanguageName() {
    switch (_locale.languageCode) {
      case 'fr':
        return 'Français';
      case 'ar':
        return 'العربية';
      case 'en':
        return 'English';
      default:
        return 'Français';
    }
  }
}