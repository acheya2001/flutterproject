import 'package:flutter/material.dart';

/// 🧭 Service de navigation centralisé
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Rediriger vers le dashboard approprié selon le type d'utilisateur
  static void redirectToDashboard(String userType) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    switch (userType) {
      case 'driver':
      case 'conducteur':
        Navigator.pushReplacementNamed(context, '/conducteur-dashboard');
        break;

      case 'agent':
      case 'agent_assurance':
        Navigator.pushReplacementNamed(context, '/agent-dashboard');
        break;

      case 'expert':
      case 'expert_auto':
        Navigator.pushReplacementNamed(context, '/expert-dashboard');
        break;

      case 'admin':
      case 'admin_agence':
        Navigator.pushReplacementNamed(context, '/admin-agence-dashboard');
        break;

      case 'admin_compagnie':
        Navigator.pushReplacementNamed(context, '/admin-compagnie-dashboard');
        break;

      case 'super_admin':
        Navigator.pushReplacementNamed(context, '/super-admin-dashboard');
        break;

      default:
        Navigator.pushReplacementNamed(context, '/user-type-selection');
        break;
    }
  }

  /// Afficher un message de succès de connexion
  static void showLoginSuccess(String userType) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    String message = _getWelcomeMessage(userType);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Obtenir le message de bienvenue selon le type d'utilisateur
  static String _getWelcomeMessage(String userType) {
    switch (userType) {
      case 'driver':
      case 'conducteur':
        return 'Bienvenue ! Accès à votre espace conducteur';

      case 'agent':
      case 'agent_assurance':
        return 'Bienvenue ! Accès à votre espace agent d\'assurance';

      case 'expert':
      case 'expert_auto':
        return 'Bienvenue ! Accès à votre espace expert automobile';

      case 'admin':
      case 'admin_agence':
        return 'Bienvenue ! Accès à votre espace administrateur d\'agence';

      case 'admin_compagnie':
        return 'Bienvenue ! Accès à votre espace administrateur de compagnie';

      case 'super_admin':
        return 'Bienvenue ! Accès à l\'espace super administrateur';

      default:
        return 'Connexion réussie !';
    }
  }
}