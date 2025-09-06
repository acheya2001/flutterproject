/// 🚨 Système d'exceptions personnalisées pour l'application
/// Permet une gestion d'erreurs plus précise et des messages utilisateur appropriés

/// 🔥 Exception de base pour l'application
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';

  /// 📱 Message utilisateur friendly
  String get userMessage => message;

  /// 🔧 Message technique pour les développeurs
  String get technicalMessage => toString();
}

/// 🌐 Exceptions réseau
class NetworkException extends AppException {
  const NetworkException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(message, code: code, originalError: originalError, stackTrace: stackTrace);

  @override
  String get userMessage => 'Problème de connexion internet. Veuillez vérifier votre connexion.';
}

/// 🔐 Exceptions d'authentification
class AuthException extends AppException {
  const AuthException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(message, code: code, originalError: originalError, stackTrace: stackTrace);

  @override
  String get userMessage {
    switch (code) {
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cet email.';
      case 'weak-password':
        return 'Le mot de passe est trop faible.';
      case 'invalid-email':
        return 'Format d\'email invalide.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'too-many-requests':
        return 'Trop de tentatives. Veuillez réessayer plus tard.';
      default:
        return 'Erreur d\'authentification. Veuillez réessayer.';
    }
  }
}

/// 🔥 Exceptions Firestore
class FirestoreException extends AppException {
  const FirestoreException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(message, code: code, originalError: originalError, stackTrace: stackTrace);

  @override
  String get userMessage {
    switch (code) {
      case 'permission-denied':
        return 'Vous n\'avez pas les autorisations nécessaires.';
      case 'not-found':
        return 'Document non trouvé.';
      case 'already-exists':
        return 'Ce document existe déjà.';
      case 'resource-exhausted':
        return 'Limite de quota atteinte. Veuillez réessayer plus tard.';
      case 'unavailable':
        return 'Service temporairement indisponible.';
      default:
        return 'Erreur de base de données. Veuillez réessayer.';
    }
  }
}

/// 📤 Exceptions de stockage (upload/download)
class StorageException extends AppException {
  const StorageException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(message, code: code, originalError: originalError, stackTrace: stackTrace);

  @override
  String get userMessage {
    switch (code) {
      case 'file-too-large':
        return 'Le fichier est trop volumineux.';
      case 'invalid-format':
        return 'Format de fichier non supporté.';
      case 'upload-failed':
        return 'Échec du téléchargement. Vérifiez votre connexion.';
      case 'storage-quota-exceeded':
        return 'Espace de stockage insuffisant.';
      default:
        return 'Erreur de stockage. Veuillez réessayer.';
    }
  }
}

/// ✅ Exceptions de validation
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException(
    String message, {
    this.fieldErrors,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(message, code: code, originalError: originalError, stackTrace: stackTrace);

  @override
  String get userMessage => 'Veuillez corriger les erreurs dans le formulaire.';

  /// 📝 Obtenir l'erreur pour un champ spécifique
  String? getFieldError(String fieldName) => fieldErrors?[fieldName];

  /// 📋 Vérifier si un champ a une erreur
  bool hasFieldError(String fieldName) => fieldErrors?.containsKey(fieldName) ?? false;
}

/// 💼 Exceptions métier spécifiques
class BusinessException extends AppException {
  const BusinessException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(message, code: code, originalError: originalError, stackTrace: stackTrace);

  @override
  String get userMessage {
    switch (code) {
      case 'contract-already-exists':
        return 'Un contrat existe déjà pour ce véhicule.';
      case 'vehicle-not-found':
        return 'Véhicule non trouvé.';
      case 'agent-not-assigned':
        return 'Aucun agent n\'est assigné à ce dossier.';
      case 'invalid-contract-status':
        return 'Statut de contrat invalide pour cette opération.';
      case 'document-missing':
        return 'Document requis manquant.';
      default:
        return message;
    }
  }
}

/// 📧 Exceptions de service email
class EmailException extends AppException {
  const EmailException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(message, code: code, originalError: originalError, stackTrace: stackTrace);

  @override
  String get userMessage {
    switch (code) {
      case 'invalid-email':
        return 'Adresse email invalide.';
      case 'send-failed':
        return 'Échec de l\'envoi de l\'email. Veuillez réessayer.';
      case 'service-unavailable':
        return 'Service email temporairement indisponible.';
      default:
        return 'Erreur lors de l\'envoi de l\'email.';
    }
  }
}

/// 🔄 Exceptions de synchronisation
class SyncException extends AppException {
  const SyncException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(message, code: code, originalError: originalError, stackTrace: stackTrace);

  @override
  String get userMessage {
    switch (code) {
      case 'sync-conflict':
        return 'Conflit de synchronisation détecté.';
      case 'offline-mode':
        return 'Fonctionnalité non disponible hors ligne.';
      case 'sync-timeout':
        return 'Délai de synchronisation dépassé.';
      default:
        return 'Erreur de synchronisation.';
    }
  }
}

/// 🔧 Exception générique (classe concrète)
class GenericException extends AppException {
  const GenericException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(message, code: code, originalError: originalError, stackTrace: stackTrace);

  @override
  String get userMessage => 'Une erreur inattendue s\'est produite. Veuillez réessayer.';
}

/// 🛠️ Utilitaires pour la gestion d'exceptions
class ExceptionHandler {
  /// 🔍 Convertir une exception générique en AppException
  static AppException handleException(dynamic error, [StackTrace? stackTrace]) {
    if (error is AppException) {
      return error;
    }

    // Gestion des erreurs Firebase Auth
    if (error.toString().contains('firebase_auth')) {
      return AuthException(
        error.toString(),
        code: _extractFirebaseErrorCode(error.toString()),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Gestion des erreurs Firestore
    if (error.toString().contains('firestore') || error.toString().contains('cloud_firestore')) {
      return FirestoreException(
        error.toString(),
        code: _extractFirebaseErrorCode(error.toString()),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Gestion des erreurs réseau
    if (error.toString().contains('network') || 
        error.toString().contains('connection') ||
        error.toString().contains('timeout')) {
      return NetworkException(
        error.toString(),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Exception générique - utiliser une classe concrète
    return GenericException(
      error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// 🔧 Extraire le code d'erreur Firebase
  static String? _extractFirebaseErrorCode(String errorMessage) {
    final regex = RegExp(r'\[([^\]]+)\]');
    final match = regex.firstMatch(errorMessage);
    return match?.group(1);
  }

  /// 📱 Obtenir un message utilisateur approprié
  static String getUserMessage(dynamic error) {
    if (error is AppException) {
      return error.userMessage;
    }
    return 'Une erreur inattendue s\'est produite.';
  }

  /// 🔧 Obtenir un message technique pour les logs
  static String getTechnicalMessage(dynamic error) {
    if (error is AppException) {
      return error.technicalMessage;
    }
    return error.toString();
  }
}
