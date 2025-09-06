import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 🔐 Service de configuration sécurisé pour l'application
/// Gère les variables d'environnement et les configurations sensibles
class AppConfig {
  static bool _isInitialized = false;

  /// 🚀 Initialiser la configuration
  static Future<void> initialize() async {
    try {
      if (!_isInitialized) {
        await dotenv.load(fileName: ".env");
        _isInitialized = true;
        debugPrint('✅ Configuration initialisée avec succès');
      }
    } catch (e) {
      debugPrint('⚠️ Erreur chargement .env: $e');
      debugPrint('📝 Utilisation des valeurs par défaut');
      _isInitialized = true;
    }
  }

  /// 🔧 Vérifier si la configuration est initialisée
  static bool get isInitialized => _isInitialized;

  // 🌐 Configuration Cloudinary
  static String get cloudinaryCloudName {
    return _getEnvVar('CLOUDINARY_CLOUD_NAME', 'dgw530dou');
  }

  static String get cloudinaryApiKey {
    return _getEnvVar('CLOUDINARY_API_KEY', '238965196817439');
  }

  static String get cloudinaryApiSecret {
    return _getEnvVar('CLOUDINARY_API_SECRET', 'UEjPyY-6993xQnAhz8RCvgMYYLM');
  }

  static String get cloudinaryUploadUrl {
    return 'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload';
  }

  static String get cloudinaryDestroyUrl {
    return 'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/destroy';
  }

  // 📧 Configuration Email
  static String get emailJsServiceId {
    return _getEnvVar('EMAILJS_SERVICE_ID', '');
  }

  static String get emailJsTemplateId {
    return _getEnvVar('EMAILJS_TEMPLATE_ID', '');
  }

  static String get emailJsUserId {
    return _getEnvVar('EMAILJS_USER_ID', '');
  }

  // 🗺️ Configuration Maps
  static String get googleMapsApiKey {
    return _getEnvVar('GOOGLE_MAPS_API_KEY', '');
  }

  // 🔥 Configuration Firebase
  static String get firebaseWebApiKey {
    return _getEnvVar('FIREBASE_WEB_API_KEY', '');
  }

  // 🏢 Configuration Application
  static String get appName {
    return _getEnvVar('APP_NAME', 'Constat Tunisie');
  }

  static String get appVersion {
    return _getEnvVar('APP_VERSION', '1.0.0');
  }

  static String get environment {
    return _getEnvVar('ENVIRONMENT', 'development');
  }

  // 🔧 Configuration Debug
  static bool get debugMode {
    return _getEnvVar('DEBUG_MODE', 'true').toLowerCase() == 'true';
  }

  static String get logLevel {
    return _getEnvVar('LOG_LEVEL', 'info');
  }

  // 🛡️ Méthodes utilitaires privées
  static String _getEnvVar(String key, String defaultValue) {
    if (!_isInitialized) {
      debugPrint('⚠️ Configuration non initialisée, utilisation de la valeur par défaut pour $key');
      return defaultValue;
    }

    try {
      return dotenv.env[key] ?? defaultValue;
    } catch (e) {
      debugPrint('⚠️ Erreur lecture variable $key: $e');
      return defaultValue;
    }
  }

  /// 🔍 Vérifier la validité de la configuration
  static Map<String, bool> validateConfig() {
    return {
      'cloudinary_configured': cloudinaryCloudName.isNotEmpty && 
                              cloudinaryApiKey.isNotEmpty && 
                              cloudinaryApiSecret.isNotEmpty,
      'email_configured': emailJsServiceId.isNotEmpty && 
                         emailJsTemplateId.isNotEmpty && 
                         emailJsUserId.isNotEmpty,
      'maps_configured': googleMapsApiKey.isNotEmpty,
      'firebase_configured': firebaseWebApiKey.isNotEmpty,
    };
  }

  /// 📊 Obtenir un résumé de la configuration (sans exposer les secrets)
  static Map<String, dynamic> getConfigSummary() {
    final validation = validateConfig();
    return {
      'app_name': appName,
      'app_version': appVersion,
      'environment': environment,
      'debug_mode': debugMode,
      'log_level': logLevel,
      'services_configured': validation,
      'initialization_status': _isInitialized,
    };
  }

  /// 🚨 Mode développement uniquement - Afficher la configuration (masquée en production)
  static void debugPrintConfig() {
    if (kDebugMode && debugMode) {
      debugPrint('🔧 Configuration Debug:');
      debugPrint('  App: $appName v$appVersion ($environment)');
      debugPrint('  Cloudinary: ${cloudinaryCloudName.isNotEmpty ? "✅" : "❌"}');
      debugPrint('  Email: ${emailJsServiceId.isNotEmpty ? "✅" : "❌"}');
      debugPrint('  Maps: ${googleMapsApiKey.isNotEmpty ? "✅" : "❌"}');
      debugPrint('  Firebase: ${firebaseWebApiKey.isNotEmpty ? "✅" : "❌"}');
    }
  }
}
