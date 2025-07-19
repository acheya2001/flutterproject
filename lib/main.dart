import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/insurance_company_service.dart';
import 'core/theme/app_theme.dart';
import 'core/services/navigation_service.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/user_type_selection_screen_elegant.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/conducteur/presentation/screens/conducteur_dashboard_screen.dart';
import 'features/agent/presentation/screens/agent_dashboard_screen.dart';
import 'features/expert/presentation/screens/expert_dashboard_screen.dart';
import 'features/admin/widgets/global_emergency_fab.dart';

/// 🚀 Point d'entrée principal de l'application Constat Tunisie
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuration de l'orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configuration de la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[CONSTAT_APP] ✅ Firebase initialized successfully');

    // Initialiser le super admin par défaut
    await AuthService.initializeSuperAdmin();

    // Initialiser les compagnies d'assurance tunisiennes
    await InsuranceCompanyService.initializeDefaultCompanies();
  } catch (e) {
    debugPrint('[CONSTAT_APP] ❌ Firebase initialization failed: $e');
  }

  runApp(const ProviderScope(child: ConstatTunisieApp()));
}

/// 🎯 Application principale Constat Tunisie
class ConstatTunisieApp extends StatelessWidget {
  const ConstatTunisieApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Constat Tunisie - Assurance Moderne',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      navigatorKey: NavigationService.navigatorKey,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/user-type-selection': (context) => const UserTypeSelectionScreenElegant(),
        '/conducteur-dashboard': (context) => const ConducteurDashboardScreen(),
        '/agent-dashboard': (context) => const AgentDashboardScreen(),
        '/expert-dashboard': (context) => const ExpertDashboardScreen(),
        '/admin-agence-dashboard': (context) => const Scaffold(
          body: Center(
            child: Text('Dashboard Admin Agence - En développement'),
          ),
        ),
        '/admin-compagnie-dashboard': (context) => const Scaffold(
          body: Center(
            child: Text('Dashboard Admin Compagnie - En développement'),
          ),
        ),
        '/super-admin-dashboard': (context) => const Scaffold(
          body: Center(
            child: Text('Dashboard Super Admin - En développement'),
          ),
        ),
      },
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            const Positioned(
              bottom: 20,
              right: 20,
              child: GlobalEmergencyFAB(),
            ),
          ],
        );
      },
    );
  }
}