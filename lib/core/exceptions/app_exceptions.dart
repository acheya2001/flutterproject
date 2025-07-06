import 'package:cloud_firestore/cloud_firestore.dart';

/// 🚨 Exceptions personnalisées pour l'application Constat Tunisie
///
/// Ce fichier contient toutes les exceptions métier de l'application
/// pour une gestion d'erreurs robuste et professionnelle.

/// Exception de base pour l'application
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException: $message';
}

/// Exceptions liées aux sessions collaboratives
class SessionException extends AppException {
  const SessionException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

class SessionNotFoundException extends SessionException {
  const SessionNotFoundException([String? sessionCode])
      : super(
          sessionCode != null 
            ? 'Session non trouvée pour le code: $sessionCode'
            : 'Session non trouvée',
          code: 'SESSION_NOT_FOUND'
        );
}

class SessionFullException extends SessionException {
  const SessionFullException()
      : super(
          'Cette session est complète. Aucune position disponible.',
          code: 'SESSION_FULL'
        );
}

class SessionExpiredException extends SessionException {
  const SessionExpiredException()
      : super(
          'Cette session a expiré. Veuillez créer une nouvelle session.',
          code: 'SESSION_EXPIRED'
        );
}

class InvalidSessionCodeException extends SessionException {
  const InvalidSessionCodeException(String code)
      : super(
          'Code de session invalide: $code',
          code: 'INVALID_SESSION_CODE'
        );
}

/// Exceptions liées à l'authentification
class AuthException extends AppException {
  const AuthException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

class UserNotAuthenticatedException extends AuthException {
  const UserNotAuthenticatedException()
      : super(
          'Utilisateur non authentifié. Veuillez vous connecter.',
          code: 'USER_NOT_AUTHENTICATED'
        );
}

/// Exceptions liées à Firestore
class FirestoreException extends AppException {
  const FirestoreException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

class FirestoreTimeoutException extends FirestoreException {
  const FirestoreTimeoutException()
      : super(
          'Timeout lors de la connexion à la base de données. Vérifiez votre connexion internet.',
          code: 'FIRESTORE_TIMEOUT'
        );
}

class FirestorePermissionException extends FirestoreException {
  const FirestorePermissionException()
      : super(
          'Permissions insuffisantes pour accéder aux données.',
          code: 'FIRESTORE_PERMISSION_DENIED'
        );
}

/// Exceptions liées aux emails
class EmailException extends AppException {
  const EmailException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

class EmailSendFailedException extends EmailException {
  const EmailSendFailedException(String email)
      : super(
          'Échec de l\'envoi de l\'email à: $email',
          code: 'EMAIL_SEND_FAILED'
        );
}

class InvalidEmailException extends EmailException {
  const InvalidEmailException(String email)
      : super(
          'Format d\'email invalide: $email',
          code: 'INVALID_EMAIL'
        );
}

/// Exceptions liées aux données
class DataException extends AppException {
  const DataException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

class DataValidationException extends DataException {
  const DataValidationException(String field)
      : super(
          'Données invalides pour le champ: $field',
          code: 'DATA_VALIDATION_ERROR'
        );
}

class DataNotFoundException extends DataException {
  const DataNotFoundException(String dataType)
      : super(
          'Données non trouvées: $dataType',
          code: 'DATA_NOT_FOUND'
        );
}

/// Exceptions liées au réseau
class NetworkException extends AppException {
  const NetworkException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

class NoInternetException extends NetworkException {
  const NoInternetException()
      : super(
          'Aucune connexion internet. Vérifiez votre connexion.',
          code: 'NO_INTERNET'
        );
}

class ServerException extends NetworkException {
  const ServerException()
      : super(
          'Erreur serveur. Veuillez réessayer plus tard.',
          code: 'SERVER_ERROR'
        );
}

/// Utilitaire pour convertir les erreurs Firebase en exceptions métier
class ExceptionHandler {
  static AppException handleFirebaseError(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return const FirestorePermissionException();
        case 'unavailable':
          return const FirestoreTimeoutException();
        case 'not-found':
          return const DataNotFoundException('Document');
        default:
          return FirestoreException(
            'Erreur Firestore: ${error.message}',
            code: error.code,
            originalError: error,
          );
      }
    }

    if (error.toString().contains('timeout')) {
      return const FirestoreTimeoutException();
    }

    return DataException(
      'Erreur inattendue: ${error.toString()}',
      originalError: error,
    );
  }
  
  static String getLocalizedMessage(AppException exception) {
    switch (exception.code) {
      case 'SESSION_NOT_FOUND':
        return 'Session non trouvée. Vérifiez le code saisi.';
      case 'SESSION_FULL':
        return 'Cette session est complète.';
      case 'SESSION_EXPIRED':
        return 'Session expirée. Créez une nouvelle session.';
      case 'INVALID_SESSION_CODE':
        return 'Code de session invalide.';
      case 'USER_NOT_AUTHENTICATED':
        return 'Veuillez vous connecter.';
      case 'FIRESTORE_TIMEOUT':
        return 'Connexion lente. Vérifiez votre internet.';
      case 'FIRESTORE_PERMISSION_DENIED':
        return 'Accès refusé. Contactez le support.';
      case 'EMAIL_SEND_FAILED':
        return 'Échec de l\'envoi de l\'email.';
      case 'INVALID_EMAIL':
        return 'Format d\'email invalide.';
      case 'NO_INTERNET':
        return 'Aucune connexion internet.';
      case 'SERVER_ERROR':
        return 'Erreur serveur. Réessayez plus tard.';
      default:
        return exception.message;
    }
  }
}
