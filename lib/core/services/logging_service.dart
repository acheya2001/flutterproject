import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../config/app_config.dart';
import '../exceptions/app_exceptions.dart';

/// 📝 Service de logging centralisé et sécurisé
/// Gère tous les logs de l'application avec différents niveaux
class LoggingService {
  static Logger? _logger;
  static bool _isInitialized = false;

  /// 🚀 Initialiser le service de logging
  static void initialize() {
    if (!_isInitialized) {
      _logger = Logger(
        filter: _CustomLogFilter(),
        printer: _CustomLogPrinter(),
        output: _CustomLogOutput(),
      );
      _isInitialized = true;
      info('LoggingService', 'Service de logging initialisé');
    }
  }

  /// 📊 Log d'information
  static void info(String tag, String message, [dynamic data]) {
    _ensureInitialized();
    _logger?.i('[$tag] $message', data);
  }

  /// ⚠️ Log d'avertissement
  static void warning(String tag, String message, [dynamic data]) {
    _ensureInitialized();
    _logger?.w('[$tag] $message', data);
  }

  /// 🚨 Log d'erreur
  static void error(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger?.e('[$tag] $message', error, stackTrace);
  }

  /// 🔧 Log de debug (uniquement en mode développement)
  static void debug(String tag, String message, [dynamic data]) {
    _ensureInitialized();
    if (kDebugMode) {
      _logger?.d('[$tag] $message', data);
    }
  }

  /// 📈 Log de performance
  static void performance(String tag, String operation, Duration duration, [Map<String, dynamic>? metadata]) {
    _ensureInitialized();
    final message = '$operation completed in ${duration.inMilliseconds}ms';
    _logger?.i('[$tag] [PERFORMANCE] $message', metadata);
  }

  /// 🔐 Log d'authentification (sans données sensibles)
  static void auth(String tag, String action, {String? userId, bool success = true}) {
    _ensureInitialized();
    final status = success ? 'SUCCESS' : 'FAILED';
    final userInfo = userId != null ? 'User: ${_maskUserId(userId)}' : 'Anonymous';
    _logger?.i('[$tag] [AUTH] $action - $status - $userInfo');
  }

  /// 🔥 Log Firestore (sans données sensibles)
  static void firestore(String tag, String operation, String collection, {String? documentId, bool success = true}) {
    _ensureInitialized();
    final status = success ? 'SUCCESS' : 'FAILED';
    final docInfo = documentId != null ? 'Doc: ${_maskDocumentId(documentId)}' : '';
    _logger?.i('[$tag] [FIRESTORE] $operation on $collection - $status $docInfo');
  }

  /// 📤 Log d'upload/stockage
  static void storage(String tag, String operation, {String? fileName, int? fileSize, bool success = true}) {
    _ensureInitialized();
    final status = success ? 'SUCCESS' : 'FAILED';
    final fileInfo = fileName != null ? 'File: ${_maskFileName(fileName)}' : '';
    final sizeInfo = fileSize != null ? 'Size: ${_formatFileSize(fileSize)}' : '';
    _logger?.i('[$tag] [STORAGE] $operation - $status $fileInfo $sizeInfo');
  }

  /// 🌐 Log d'API/réseau
  static void network(String tag, String method, String url, int statusCode, [Duration? duration]) {
    _ensureInitialized();
    final durationInfo = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
    final maskedUrl = _maskUrl(url);
    _logger?.i('[$tag] [NETWORK] $method $maskedUrl -> $statusCode$durationInfo');
  }

  /// 💼 Log d'événements métier
  static void business(String tag, String event, Map<String, dynamic>? context) {
    _ensureInitialized();
    final sanitizedContext = _sanitizeBusinessContext(context);
    _logger?.i('[$tag] [BUSINESS] $event', sanitizedContext);
  }

  /// 🚨 Log d'exception avec gestion appropriée
  static void exception(String tag, AppException exception, [StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger?.e(
      '[$tag] [EXCEPTION] ${exception.runtimeType}: ${exception.message}',
      {
        'code': exception.code,
        'userMessage': exception.userMessage,
        'technicalMessage': exception.technicalMessage,
      },
      stackTrace ?? exception.stackTrace,
    );
  }

  /// 🔄 Log de synchronisation
  static void sync(String tag, String operation, {int? itemCount, bool success = true}) {
    _ensureInitialized();
    final status = success ? 'SUCCESS' : 'FAILED';
    final countInfo = itemCount != null ? 'Items: $itemCount' : '';
    _logger?.i('[$tag] [SYNC] $operation - $status $countInfo');
  }

  /// 🛠️ Méthodes utilitaires privées

  static void _ensureInitialized() {
    if (!_isInitialized) {
      initialize();
    }
  }

  /// 🔒 Masquer l'ID utilisateur (garder seulement les premiers et derniers caractères)
  static String _maskUserId(String userId) {
    if (userId.length <= 6) return '***';
    return '${userId.substring(0, 3)}***${userId.substring(userId.length - 3)}';
  }

  /// 🔒 Masquer l'ID de document
  static String _maskDocumentId(String docId) {
    if (docId.length <= 6) return '***';
    return '${docId.substring(0, 4)}***${docId.substring(docId.length - 4)}';
  }

  /// 🔒 Masquer le nom de fichier (garder l'extension)
  static String _maskFileName(String fileName) {
    final parts = fileName.split('.');
    if (parts.length < 2) return '***';
    final name = parts.first;
    final extension = parts.last;
    if (name.length <= 4) return '***.$extension';
    return '${name.substring(0, 2)}***${name.substring(name.length - 2)}.$extension';
  }

  /// 🔒 Masquer l'URL (garder le domaine)
  static String _maskUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return '${uri.scheme}://${uri.host}${uri.path.length > 20 ? '${uri.path.substring(0, 20)}...' : uri.path}';
    } catch (e) {
      return 'invalid-url';
    }
  }

  /// 📊 Formater la taille de fichier
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// 🧹 Nettoyer le contexte métier (supprimer les données sensibles)
  static Map<String, dynamic>? _sanitizeBusinessContext(Map<String, dynamic>? context) {
    if (context == null) return null;

    final sanitized = <String, dynamic>{};
    final sensitiveKeys = ['password', 'token', 'secret', 'key', 'pin', 'cin', 'phone', 'email'];

    for (final entry in context.entries) {
      final key = entry.key.toLowerCase();
      if (sensitiveKeys.any((sensitive) => key.contains(sensitive))) {
        sanitized[entry.key] = '***';
      } else {
        sanitized[entry.key] = entry.value;
      }
    }

    return sanitized;
  }
}

/// 🎯 Filtre de log personnalisé
class _CustomLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (!AppConfig.isInitialized) return kDebugMode;
    
    final configuredLevel = AppConfig.logLevel.toLowerCase();
    
    switch (configuredLevel) {
      case 'debug':
        return true;
      case 'info':
        return event.level.index >= Level.info.index;
      case 'warning':
        return event.level.index >= Level.warning.index;
      case 'error':
        return event.level.index >= Level.error.index;
      default:
        return kDebugMode;
    }
  }
}

/// 🎨 Formateur de log personnalisé
class _CustomLogPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final timestamp = DateTime.now().toIso8601String();
    final level = event.level.name.toUpperCase().padRight(7);
    final message = event.message;
    
    final logLine = '[$timestamp] [$level] $message';
    
    final lines = <String>[logLine];
    
    if (event.error != null) {
      lines.add('Error: ${event.error}');
    }
    
    if (event.stackTrace != null && kDebugMode) {
      lines.addAll(event.stackTrace.toString().split('\n'));
    }
    
    return lines;
  }
}

/// 📤 Sortie de log personnalisée
class _CustomLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      if (kDebugMode) {
        developer.log(line, name: 'ConstatTunisie');
      }
      // En production, on pourrait envoyer vers un service de logging externe
    }
  }
}
