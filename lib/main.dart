import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/insurance_company_service.dart';
import 'core/theme/app_theme.dart';
import 'core/services/navigation_service.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/user_type_selection_screen_elegant.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/conducteur/presentation/screens/conducteur_dashboard_screen.dart';
import 'features/conducteur/screens/modern_conducteur_dashboard.dart';
import 'features/conducteur/presentation/screens/conducteur_registration_screen.dart';
import 'features/expert/presentation/screens/expert_dashboard_screen.dart';
import 'features/admin_compagnie/presentation/screens/admin_compagnie_dashboard.dart';
import 'features/admin_agence/screens/admin_agence_dashboard.dart';
import 'features/admin/screens/super_admin_dashboard.dart';
import 'debug/check_admin_account.dart';

// Imports pour les écrans de constat
import 'features/constat/screens/declaration_entry_point_screen.dart';
import 'features/conducteur/screens/professional_session_screen.dart';
import 'features/constat/screens/join_session_screen.dart';
import 'features/conducteur/screens/invitations_screen.dart';
import 'features/constat/screens/declaration_wizard_screen.dart';
import 'features/constat/screens/constat_officiel_screen.dart';
import 'features/constat/screens/constat_selection_screen.dart';
import 'features/agent/screens/pending_vehicles_screen.dart';
import 'features/agent/screens/agent_dashboard_screen.dart';
import 'features/notifications/widgets/notification_badge.dart';

// Imports pour les écrans conducteur supplémentaires
import 'features/conducteur/screens/add_vehicle_screen.dart';
import 'features/conducteur/screens/add_vehicle_modern_screen.dart';
import 'features/constat/screens/ai_demo_screen.dart';
import 'features/conducteur/screens/conducteur_vehicules_screen.dart';
import 'features/conducteur/screens/conducteur_accidents_screen.dart';
import 'features/agent/screens/pending_contracts_screen.dart';
import 'features/agent/screens/pending_vehicles_management_screen.dart';
import 'features/admin_agence/screens/agent_password_reset_screen.dart';

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

    // 🔧 Désactiver reCAPTCHA en développement pour éviter les erreurs SSL
    if (kDebugMode) {
      try {
        await FirebaseAuth.instance.setSettings(
          appVerificationDisabledForTesting: true,
        );
        debugPrint('[CONSTAT_APP] ✅ reCAPTCHA désactivé pour le développement');
      } catch (e) {
        debugPrint('[CONSTAT_APP] ⚠️ Impossible de désactiver reCAPTCHA: $e');
      }
    }

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
        '/conducteur-dashboard': (context) => const ModernConducteurDashboard(),
        '/conducteur-registration': (context) => const ConducteurRegistrationScreen(),
        '/login': (context) => const LoginScreen(userType: 'driver'),
        '/agent-dashboard': (context) => const AgentDashboardScreen(),
        '/expert-dashboard': (context) => const ExpertDashboardScreen(),
        '/admin-agence-dashboard': (context) => const AdminAgenceDashboard(),
        '/admin-compagnie-dashboard': (context) => const AdminCompagnieDashboard(),
        '/super-admin-dashboard': (context) => const SuperAdminDashboard(),

        // Routes pour les fonctionnalités de constat
        '/declaration/entry': (context) => const DeclarationEntryPointScreen(),
        '/professional/session': (context) => const ProfessionalSessionScreen(),
        '/join/session': (context) => const JoinSessionScreen(),
        '/conducteur/invitations': (context) => const InvitationsScreen(),
        '/constat/ai-demo': (context) => const AiDemoScreen(),
        '/constat/declaration': (context) => const DeclarationWizardScreen(),
        '/constat/officiel': (context) => const ConstatOfficielScreen(),
        '/constat/selection': (context) => const ConstatSelectionScreen(),
        '/agent/pending-vehicles': (context) => const PendingVehiclesScreen(),
        '/agent/dashboard': (context) => const AgentDashboardScreen(),

        // Routes conducteur
        '/conducteur/register': (context) => const ConducteurRegistrationScreen(),
        '/conducteur/dashboard': (context) => const ConducteurDashboardScreen(),
        '/conducteur/add-vehicle': (context) => const AddVehicleModernScreen(),
        '/conducteur/add-vehicle-full': (context) => const AddVehicleScreen(),
        '/conducteur/vehicules': (context) => const ConducteurVehiculesScreen(),
        '/conducteur/accidents': (context) => const ConducteurAccidentsScreen(),

        // Routes agent
        '/agent/pending-contracts': (context) => const PendingContractsScreen(),
        '/agent/pending-vehicles': (context) => const PendingVehiclesManagementScreen(),

        // Routes admin agence
        '/admin-agence/agent-password-reset': (context) => const AgentPasswordResetScreen(),
      },

    );
  }
}