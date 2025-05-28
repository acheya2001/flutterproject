// lib/core/services/storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;
  static bool _initialized = false;

  // Initialiser le service
  static Future<void> init() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  // Vérifier si le service est initialisé
  static bool get isInitialized => _initialized;

  // Enregistrer une valeur String
  static Future<bool> setString(String key, String value) async {
    if (!_initialized) await init();
    return await _prefs!.setString(key, value);
  }

  // Récupérer une valeur String
  static String? getString(String key) {
    if (!_initialized) {
      // Si non initialisé, retourner null au lieu de lancer une exception
      return null;
    }
    return _prefs!.getString(key);
  }

  // Enregistrer une valeur bool
  static Future<bool> setBool(String key, bool value) async {
    if (!_initialized) await init();
    return await _prefs!.setBool(key, value);
  }

  // Récupérer une valeur bool
  static bool? getBool(String key) {
    if (!_initialized) {
      return null;
    }
    return _prefs!.getBool(key);
  }

  // Enregistrer une valeur int
  static Future<bool> setInt(String key, int value) async {
    if (!_initialized) await init();
    return await _prefs!.setInt(key, value);
  }

  // Récupérer une valeur int
  static int? getInt(String key) {
    if (!_initialized) {
      return null;
    }
    return _prefs!.getInt(key);
  }

  // Supprimer une valeur
  static Future<bool> remove(String key) async {
    if (!_initialized) await init();
    return await _prefs!.remove(key);
  }

  // Vider toutes les préférences
  static Future<bool> clear() async {
    if (!_initialized) await init();
    return await _prefs!.clear();
  }
}