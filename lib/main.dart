import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/insurance_company_service.dart';

import 'services/echeance_notification_service.dart';
import 'services/expiration_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/services/navigation_service.dart';
import 'core/config/app_config.dart';
import 'core/services/logging_service.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/user_type_selection_screen_elegant.dart';
import 'test_nouvelles_sections.dart';
import 'demo_formulaire_moderne.dart';
import 'widgets/demo_pdf_generator_widget.dart';
import 'test_firebase_pdf.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/conducteur_login_screen.dart';

import 'features/conducteur/screens/demande_contrat_screen.dart';
import 'features/conducteur/screens/conducteur_dashboard_complete.dart';
// import 'features/conducteur/screens/new_insurance_request_screen.dart'; // Remplacé par demande_contrat_screen
import 'features/agent/screens/create_conducteur_account_screen.dart';
import 'features/auth/screens/conducteur_register_simple_screen.dart';
import 'features/expert/presentation/screens/expert_dashboard_screen.dart';
import 'features/expert/screens/missions_expert_screen.dart';
import 'features/expert/screens/mission_details_screen.dart';
import 'features/admin_compagnie/presentation/screens/admin_compagnie_dashboard.dart';
import 'features/admin_agence/screens/admin_agence_dashboard.dart';
import 'features/admin/screens/super_admin_dashboard.dart';


// Imports pour les écrans de constat
import 'features/constat/screens/declaration_entry_point_screen.dart';

import 'features/constat/screens/join_session_screen.dart';

import 'features/conducteur/screens/conducteur_invitations_screen.dart';
import 'features/constat/screens/declaration_wizard_screen.dart';
import 'features/constat/screens/constat_officiel_screen.dart';
import 'features/constat/screens/constat_selection_screen.dart';

import 'features/agent/screens/agent_dashboard_screen.dart';


// Imports pour les écrans conducteur supplémentaires
import 'features/conducteur/screens/add_vehicle_screen.dart';
import 'features/conducteur/screens/add_vehicle_modern_screen.dart';
import 'features/constat/screens/ai_demo_screen.dart';
import 'demo/constat_demo_screen.dart';
import 'features/conducteur/screens/mes_vehicules_screen.dart';
import 'features/conducteur/screens/conducteur_accidents_screen.dart';
import 'features/agent/screens/pending_contracts_screen.dart';
import 'features/agent/screens/pending_vehicles_management_screen.dart';
import 'features/admin_agence/screens/agent_password_reset_screen.dart';

// Import pour le test PDF
import 'screens/test_pdf_screen.dart';

// Imports pour les écrans d'assurance
import 'features/conducteur/screens/add_vehicle_for_insurance_screen.dart';
import 'features/conducteur/screens/mes_demandes_assurance_screen.dart';
import 'features/conducteur/screens/complete_insurance_request_screen.dart';
import 'features/agent/screens/nouvelles_demandes_screen.dart';
import 'test_readonly_mode.dart';

/// 🚀 Point d'entrée principal de l'application Constat Tunisie
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🌍 Initialiser les données de localisation française
  await initializeDateFormatting('fr_FR', null);

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
    // 🔐 Initialiser la configuration sécurisée en premier
    await AppConfig.initialize();
    LoggingService.initialize();
    LoggingService.info('MAIN', 'Application Constat Tunisie démarrée');
    LoggingService.info('MAIN', 'Configuration: ${AppConfig.getConfigSummary()}');

    // 🔥 Initialiser Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    LoggingService.info('MAIN', 'Firebase initialisé avec succès');

    // 🔧 Désactiver reCAPTCHA en développement pour éviter les erreurs SSL
    if (kDebugMode) {
      try {
        await FirebaseAuth.instance.setSettings(
          appVerificationDisabledForTesting: true,
        );
        LoggingService.info('MAIN', 'reCAPTCHA désactivé pour le développement');
      } catch (e) {
        LoggingService.warning('MAIN', 'Impossible de désactiver reCAPTCHA', e);
      }
    }

    // 🔐 Initialiser le super admin par défaut
    try {
      await AuthService.initializeSuperAdmin();
      LoggingService.info('MAIN', 'Super admin initialisé');
    } catch (e) {
      LoggingService.error('MAIN', 'Erreur initialisation super admin', e);
    }

    // 🏢 Initialiser les compagnies d'assurance tunisiennes
    try {
      await InsuranceCompanyService.initializeDefaultCompanies();
      LoggingService.info('MAIN', 'Compagnies d\'assurance initialisées');
    } catch (e) {
      LoggingService.error('MAIN', 'Erreur initialisation compagnies', e);
    }

    // � Initialiser le service de notifications d'échéances
    try {
      await EcheanceNotificationService.initialiser();
      LoggingService.info('MAIN', 'Service d\'échéances initialisé');
    } catch (e) {
      LoggingService.error('MAIN', 'Erreur initialisation service échéances', e);
    }

    // Initialiser le service de notifications d'expiration
    try {
      await ExpirationNotificationService.verifierEtNotifierExpirations();
      LoggingService.info('MAIN', 'Service d\'expiration initialisé');
    } catch (e) {
      LoggingService.error('MAIN', 'Erreur initialisation service expiration', e);
    }

    // �🔧 Afficher la configuration en mode debug
    if (kDebugMode) {
      AppConfig.debugPrintConfig();
    }

  } catch (e, stackTrace) {
    LoggingService.error('MAIN', 'Erreur critique lors de l\'initialisation', e, stackTrace);
    debugPrint('[CONSTAT_APP] ❌ Critical initialization error: $e');
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
      // 🌍 Configuration des locales
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routes: {
        '/user-type-selection': (context) => const UserTypeSelectionScreenElegant(),
        '/conducteur-dashboard': (context) => const ConducteurDashboardComplete(),
        // '/conducteur-dashboard-modern': (context) => const ModernConducteurDashboard(), // Temporairement désactivé
        '/conducteur-registration': (context) => const ConducteurRegisterSimpleScreen(),
        '/login': (context) => const LoginScreen(userType: 'driver'),
        '/agent-dashboard': (context) => const AgentDashboardScreen(),
        '/expert-dashboard': (context) => const ExpertDashboardScreen(),
        '/expert-missions': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return MissionsExpertScreen(
            expertId: args['expertId'],
            expertData: args['expertData'],
          );
        },
        '/expert-mission-details': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return MissionDetailsScreen(
            mission: args['mission'],
            expertData: args['expertData'],
          );
        },
        '/admin-agence-dashboard': (context) => const AdminAgenceDashboard(),
        '/admin-compagnie-dashboard': (context) => const AdminCompagnieDashboard(),
        '/super-admin-dashboard': (context) => const SuperAdminDashboard(),

        // Routes pour les fonctionnalités de constat
        '/declaration/entry': (context) => const DeclarationEntryPointScreen(),

        '/conducteur/invitations': (context) => const ConducteurInvitationsScreen(),
        '/constat/ai-demo': (context) => const AiDemoScreen(),
        '/constat/declaration': (context) => const DeclarationWizardScreen(),
        '/constat/officiel': (context) => const ConstatOfficielScreen(),
        '/constat/selection': (context) => const ConstatSelectionScreen(),
        '/constat/demo': (context) => const ConstatDemoScreen(),

        '/agent/dashboard': (context) => const AgentDashboardScreen(),
        '/agent/create-conducteur': (context) => const CreateConducteurAccountScreen(),

        // Routes conducteur
        '/conducteur/register': (context) => const ConducteurRegisterSimpleScreen(),
        '/conducteur/login': (context) => const ConducteurLoginScreen(),
        '/conducteur/dashboard': (context) => const ConducteurDashboardComplete(),
        '/conducteur/nouvelle-demande': (context) => const DemandeContratScreen(),
        // '/conducteur/new-insurance-request': (context) => const NewInsuranceRequestScreen(), // Temporairement désactivé
        '/conducteur/add-vehicle': (context) => const AddVehicleModernScreen(),
        '/conducteur/add-vehicle-full': (context) => AddVehicleScreen(),
        '/conducteur/vehicules': (context) => const MesVehiculesScreen(),
        '/conducteur/accidents': (context) => const ConducteurAccidentsScreen(),

        // Routes agent
        '/agent/pending-contracts': (context) => const PendingContractsScreen(),
        '/agent/pending-vehicles': (context) => const PendingVehiclesManagementScreen(),
        '/agent/nouvelles-demandes': (context) => const NouvellesDemandesScreen(agenceId: ''),

        // Routes admin agence
        '/admin-agence/agent-password-reset': (context) => const AgentPasswordResetScreen(),

        // Routes assurance conducteur
        '/add-vehicle-insurance': (context) => const AddVehicleForInsuranceScreen(),
        '/mes-demandes-assurance': (context) => const MesDemandesAssuranceScreen(),
        '/complete-insurance-request': (context) => const CompleteInsuranceRequestScreen(),

        // Routes de test et démonstration
        '/test-nouvelles-sections': (context) => const TestNouvellesSections(),
        '/demo-formulaire-moderne': (context) => const DemoFormulaireModerne(),
        '/test-pdf': (context) => const TestPdfScreen(),
        '/demo-pdf': (context) => DemoPdfGeneratorWidget(),
        '/test-firebase-pdf': (context) => const TestFirebasePdfPage(),
      },

    );
  }
}