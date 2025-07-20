import 'package:flutter/material.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/language/screens/language_selection_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/user_type_selection_screen.dart';
import '../../features/auth/screens/agent_login_screen.dart';
import '../../features/auth/screens/agent_registration_screen.dart';
import '../../features/auth/screens/conducteur_register_screen.dart';
import '../../features/auth/screens/professional_info_screen.dart';
import '../../features/auth/screens/professional_registration_screen.dart';
import '../../features/auth/presentation/screens/professional_account_request_screen.dart';
import '../../features/auth/presentation/screens/request_success_screen.dart';
import '../../features/admin/presentation/screens/professional_requests_management_screen.dart';
import '../../features/auth/screens/notifications_screen.dart';
import '../../features/conducteur/screens/conducteur_home_screen.dart';
import '../../features/conducteur/screens/conducteur_profile_screen.dart';
import '../../features/conducteur/screens/conducteur_vehicules_screen.dart';
import '../../features/conducteur/screens/conducteur_accidents_screen.dart';
import '../../features/conducteur/screens/conducteur_declaration_screen.dart';
import '../../features/assureur/screens/assureur_home_screen.dart';
import '../../features/assureur/screens/assureur_vehicle_verification_screen.dart';
import '../../features/expert/screens/expert_home_screen.dart';
import '../../features/admin/screens/clean_admin_dashboard.dart';
import '../../features/admin/screens/compagnies_management_screen.dart';
import '../../features/admin/screens/agences_management_screen.dart';
import '../../features/admin/screens/agents_management_screen.dart';
import '../../features/admin/screens/admin_test_screen.dart';
import '../../features/admin/screens/admin_initialization_screen.dart';
import '../../features/admin/screens/account_validation_screen.dart';
import '../../features/admin/screens/permissions_management_screen.dart';
import '../../features/admin/screens/agent_requests_screen.dart';
import '../../features/insurance/screens/insurance_system_init_screen.dart';
import '../../features/constat/screens/declaration_entry_point_screen.dart';
import '../../features/constat/screens/session_creation_screen.dart';
import '../../features/vehicule/models/vehicule_model.dart';
import '../../features/vehicule/screens/vehicule_form_screen.dart';
import '../../features/vehicles/screens/my_vehicles_screen.dart';

/// 🛣️ Configuration des routes de l'application
class AppRoutes {
  // Routes principales
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String languageSelection = '/language-selection';
  static const String userTypeSelection = '/user-type-selection';
  static const String login = '/login';
  static const String agentLogin = '/agent-login';
  static const String agentRegistration = '/agent-registration';
  static const String register = '/register';
  static const String conducteurRegister = '/conducteur-register';
  static const String professionalInfo = '/professional-info';
  static const String professionalRegistration = '/professional-registration';
  static const String professionalRequest = '/professional-request';
  static const String requestSuccess = '/request-success';
  static const String notifications = '/notifications';
  static const String forgotPassword = '/forgot-password';

  // Routes conducteur
  static const String conducteurHome = '/conducteur/home';
  static const String conducteurProfile = '/conducteur/profile';
  static const String conducteurVehicules = '/conducteur/vehicules';
  static const String conducteurAccidents = '/conducteur/accidents';
  static const String conducteurDeclaration = '/conducteur/declaration';

  // Routes assureur
  static const String assureurHome = '/assureur/home';
  static const String assureurVehicleVerification = '/assureur/vehicle-verification';
  static const String contractManagement = '/assureur/contract-management';
  static const String addContract = '/assureur/add-contract';

  // Routes expert
  static const String expertHome = '/expert/home';

  // Routes admin
  static const String adminHome = '/admin/home';
  static const String adminCompagnies = '/admin/compagnies';
  static const String adminAgences = '/admin/agences';
  static const String adminAgents = '/admin/agents';
  static const String adminTest = '/admin/test';
  static const String adminInit = '/admin/init';
  static const String adminAccountValidation = '/admin/account-validation';
  static const String adminPermissions = '/admin/permissions';
  static const String adminAgentRequests = '/admin/agent-requests';
  static const String adminProfessionalRequests = '/admin/professional-requests';

  // Routes système
  static const String insuranceSystemInit = '/insurance/system-init';
  static const String agentDashboard = '/agent/dashboard';
  static const String createContract = '/agent/create-contract';
  static const String declarationEntryPoint = '/declaration-entry-point';
  static const String sessionCreation = '/session-creation';
  static const String addVehicule = '/vehicule/add';
  static const String vehiculeDetails = '/vehicule/details';
  static const String testInsurance = '/test/insurance';
  static const String myVehicles = '/insurance/my-vehicles';

  /// 📱 Configuration des routes
  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    onboarding: (context) => const OnboardingScreen(),
    languageSelection: (context) => const LanguageSelectionScreen(),
    userTypeSelection: (context) => const UserTypeSelectionScreen(),
    login: (context) => const LoginScreen(),
    agentLogin: (context) => const AgentLoginScreen(),
    agentRegistration: (context) => const AgentRegistrationScreen(),
    register: (context) => const RegisterScreen(),
    conducteurRegister: (context) => const ConducteurRegisterScreen(),
    professionalInfo: (context) => const ProfessionalInfoScreen(userType: 'agent'),
    professionalRegistration: (context) => const ProfessionalRegistrationScreen(),
    professionalRequest: (context) => const ProfessionalAccountRequestScreen(),
    requestSuccess: (context) => const RequestSuccessScreen(),
    notifications: (context) => const NotificationsScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    conducteurHome: (context) => const ConducteurHomeScreen(),
    conducteurProfile: (context) => const ConducteurProfileScreen(),
    conducteurVehicules: (context) => const ConducteurVehiculesScreen(),
    conducteurAccidents: (context) => const ConducteurAccidentsScreen(),
    assureurHome: (context) => const AssureurHomeScreen(),
    assureurVehicleVerification: (context) => const AssureurVehicleVerificationScreen(),
    expertHome: (context) => const ExpertHomeScreen(),
    adminHome: (context) => const CleanAdminDashboard(),
    adminCompagnies: (context) => const CompagniesManagementScreen(),
    adminAgences: (context) => const AgencesManagementScreen(),
    adminAgents: (context) => const AgentsManagementScreen(),
    adminTest: (context) => const AdminTestScreen(),
    adminInit: (context) => const AdminInitializationScreen(),
    adminAccountValidation: (context) => const AccountValidationScreen(),
    adminPermissions: (context) => const PermissionsManagementScreen(),
    adminAgentRequests: (context) => const AgentRequestsScreen(),
    adminProfessionalRequests: (context) => const ProfessionalRequestsManagementScreen(),
    insuranceSystemInit: (context) => const InsuranceSystemInitScreen(),
    declarationEntryPoint: (context) => const DeclarationEntryPointScreen(),
    myVehicles: (context) => const MyVehiclesScreen(),
  };

  /// 🔄 Générateur de routes dynamiques
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final String routeName = settings.name ?? '';
    final dynamic args = settings.arguments;

    // Routes avec paramètres
    if (routeName.startsWith('/conducteur/declaration/')) {
      final Map<String, dynamic> routeArgs = args as Map<String, dynamic>? ?? {};
      return MaterialPageRoute(
        builder: (context) => ConducteurDeclarationScreen(
          conducteurPosition: 'A',
        ),
        settings: settings,
      );
    }

    if (routeName.startsWith('/session-creation')) {
      final Map<String, dynamic> routeArgs = args as Map<String, dynamic>? ?? {};
      final String sessionId = routeArgs['sessionId'] ?? '';
      final String conducteurPosition = routeArgs['conducteurPosition'] ?? 'A';
      final String? invitationCode = routeArgs['invitationCode'];
      final bool isCollaborative = routeArgs['isCollaborative'] ?? false;

      return MaterialPageRoute(
        builder: (context) => SessionCreationScreen(
          sessionId: sessionId,
          conducteurPosition: conducteurPosition,
          invitationCode: invitationCode,
          isCollaborative: isCollaborative,
        ),
        settings: settings,
      );
    }

    if (routeName.startsWith('/vehicule/add')) {
      final Map<String, dynamic>? routeArgs = args as Map<String, dynamic>?;
      final String? compagnieId = routeArgs?['compagnieId'];
      return MaterialPageRoute(
        builder: (context) => VehiculeFormScreen(compagnieId: compagnieId),
        settings: settings,
      );
    }

    if (routeName.startsWith('/vehicule/details')) {
      final Map<String, dynamic>? routeArgs = args as Map<String, dynamic>?;
      final String? compagnieId = routeArgs?['compagnieId'];
      final String? agenceId = routeArgs?['agenceId'];
      return MaterialPageRoute(
        builder: (context) => VehiculeFormScreen(
          compagnieId: compagnieId,
          agenceId: agenceId,
        ),
        settings: settings,
      );
    }

    // Route par défaut pour les pages non trouvées
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Page non trouvée')),
        body: Center(
          child: Text('Route inconnue: ${settings.name}'),
        ),
      ),
    );
  }

  /// 🏠 Obtenir la route d'accueil selon le type d'utilisateur
  static String getHomeRoute(String userType) {
    switch (userType) {
      case 'conducteur':
        return conducteurHome;
      case 'assureur':
        return assureurHome;
      case 'expert':
        return expertHome;
      case 'admin':
        return adminHome;
      case 'conducteur':
        return conducteurHome;
      // Ajoutez d'autres types d'utilisateurs selon vos besoins
      // case 'assureur':
      //   return assureurHome;
      default:
        return userTypeSelection;
    }
  }
}