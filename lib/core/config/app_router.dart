import 'package:flutter/material.dart';

import '../enums/app_enums.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/user_type_selection_screen.dart';
import '../../features/driver/presentation/screens/driver_dashboard.dart';
import '../../features/auth/presentation/screens/professional_account_request_screen.dart';
import '../../features/admin/presentation/screens/super_admin_login_screen.dart';
import '../../features/admin/presentation/screens/super_admin_dashboard_screen.dart';
import '../../features/admin/utils/clean_firestore.dart';

/// 🛣️ Configuration des routes de l'application
class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String userTypeSelection = '/user-type-selection';
  static const String login = '/login';
  static const String professionalAccountRequest = '/professional-account-request';
  static const String superAdminLogin = '/super-admin-login';
  static const String superAdminDashboard = '/super-admin-dashboard';
  static const String cleanFirestore = '/clean-firestore';
  
  // Routes Driver
  static const String driverDashboard = '/driver';
  static const String driverProfile = '/driver/profile';
  static const String driverVehicles = '/driver/vehicles';
  static const String driverContracts = '/driver/contracts';
  static const String driverClaims = '/driver/claims';
  
  // Routes partagées
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String settings = '/settings';

  /// 🧭 Générateur de routes
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );

      case onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        );

      case userTypeSelection:
        return MaterialPageRoute(
          builder: (_) => const UserTypeSelectionScreen(),
        );
      
      case login:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => LoginScreen(
            userType: args?['userType'],
          ),
        );
      
      case driverDashboard:
        return MaterialPageRoute(
          builder: (_) => const DriverDashboard(),
        );

      case professionalAccountRequest:
        return MaterialPageRoute(
          builder: (_) => const ProfessionalAccountRequestScreen(),
        );

      case superAdminLogin:
        return MaterialPageRoute(
          builder: (_) => const SuperAdminLoginScreen(),
        );

      case superAdminDashboard:
        return MaterialPageRoute(
          builder: (_) => const SuperAdminDashboardScreen(),
        );

      case cleanFirestore:
        return MaterialPageRoute(
          builder: (_) => const CleanFirestoreWidget(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const NotFoundScreen(),
        );
    }
  }

  /// 🧭 Navigation vers le dashboard selon le rôle
  static String getDashboardRoute(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
      case UserRole.companyAdmin:
      case UserRole.agencyAdmin:
        return '/admin'; // TODO: Implémenter les dashboards admin
      case UserRole.agent:
        return '/agent'; // TODO: Implémenter le dashboard agent
      case UserRole.driver:
        return driverDashboard;
      case UserRole.expert:
        return '/expert'; // TODO: Implémenter le dashboard expert
    }
  }
}

/// 📄 Écran pour les pages non trouvées
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page non trouvée'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'Page non trouvée',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'La page que vous cherchez n\'existe pas.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
