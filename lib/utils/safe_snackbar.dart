import 'package:flutter/material.dart';

/// Utilitaire pour afficher des SnackBar de manière sécurisée
/// Évite l'erreur "showSnackBar() method cannot be called during build"
class SafeSnackBar {
  
  /// Affiche un SnackBar de manière sécurisée avec un délai automatique
  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    Widget? content,
  }) {
    // Utiliser un délai pour éviter les problèmes de build
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        // Vérifier que le context est encore valide
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: content ?? Text(message),
              backgroundColor: backgroundColor,
              duration: duration,
              action: action,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        // Ignorer silencieusement les erreurs de SnackBar
        print('SafeSnackBar: Erreur ignorée - $e');
      }
    });
  }

  /// Affiche un SnackBar de succès
  static void showSuccess(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: Colors.green,
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche un SnackBar d'erreur
  static void showError(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: Colors.red,
      content: Row(
        children: [
          const Icon(Icons.error, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche un SnackBar d'avertissement
  static void showWarning(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: Colors.orange,
      content: Row(
        children: [
          const Icon(Icons.warning, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche un SnackBar d'information
  static void showInfo(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: Colors.blue,
      content: Row(
        children: [
          const Icon(Icons.info, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
