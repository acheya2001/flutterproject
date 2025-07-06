import 'package:flutter/material.dart';

// Imports des écrans
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
  static const String insuranceSystemInit = '/insurance/system-init';
  static const String agentDashboard = '/agent/dashboard';
  static const String createContract = '/agent/create-contract';

  // Nouvelles routes pour le flux de déclaration
  static const String declarationEntryPoint = '/declaration-entry-point';
  static const String sessionCreation = '/session-creation';
  
  // Routes véhicule
  static const String addVehicule = '/vehicule/add';
  static const String vehiculeDetails = '/vehicule/details';

  // Routes test
  static const String testInsurance = '/test/insurance';

  // Routes assurance (nettoyées)
  static const String myVehicles = '/insurance/my-vehicles';



  static final Map<String, WidgetBuilder> routes = {
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
    professionalRequest: (context) => const ProfessionalAccountRequestScreen(),
    requestSuccess: (context) => const RequestSuccessScreen(),

    forgotPassword: (context) => const ForgotPasswordScreen(),
    notifications: (context) => const NotificationsScreen(),
    conducteurHome: (context) => const ConducteurHomeScreen(),
    conducteurProfile: (context) => const ConducteurProfileScreen(),
    conducteurAccidents: (context) => const ConducteurAccidentsScreen(),
    assureurHome: (context) => const AssureurHomeScreen(),
    assureurVehicleVerification: (context) => const AssureurVehicleVerificationScreen(),
    expertHome: (context) => const ExpertHomeScreen(),
    adminHome: (context) => const CleanAdminDashboard(),
    adminCompagnies: (context) => const CompagniesManagementScreen(),
    adminTest: (context) => const AdminTestScreen(),
    adminInit: (context) => const AdminInitializationScreen(),
    adminAccountValidation: (context) => const AccountValidationScreen(),
    adminPermissions: (context) => const PermissionsManagementScreen(),
    adminAgentRequests: (context) => const AgentRequestsScreen(),
    adminProfessionalRequests: (context) => const ProfessionalRequestsManagementScreen(),
    insuranceSystemInit: (context) => const InsuranceSystemInitScreen(),
    // agentDashboard: (context) => const AgentDashboardScreen(agent: agent), // TODO: Implémenter avec paramètres
    // createContract: (context) => const ModernContractCreationScreen(), // TODO: Implémenter avec paramètres
    declarationEntryPoint: (context) => const DeclarationEntryPointScreen(),
    sessionCreation: (context) => const SessionCreationScreen(),
    addVehicule: (context) => const VehiculeFormScreen(vehicule: null),
    myVehicles: (context) => const MyVehiclesScreen(),
    // Note: conducteurVehicules et conducteurDeclaration sont gérés dans generateRoute
    // car ils prennent des arguments.
  };

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case conducteurVehicules:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ConducteurVehiculesScreen(
            conducteurPosition: 'A', // Paramètre requis
            isCollaborative: false, // Valeur par défaut
          ),
        );

      case conducteurDeclaration:
        final Map<String, dynamic> routeArgs = args as Map<String, dynamic>;
        final String sessionId = routeArgs['sessionId'] as String;
        final String conducteurPosition = routeArgs['conducteurPosition'] as String;
        final String? invitationCode = routeArgs['invitationCode'] as String?;
        final bool isCollaborative = routeArgs['isCollaborative'] as bool? ?? false;

        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ConducteurDeclarationScreen(
            sessionId: sessionId,
            conducteurPosition: conducteurPosition,
            invitationCode: invitationCode,
            isCollaborative: isCollaborative,
          ),
        );
        
      case vehiculeDetails:
        final VehiculeModel vehicule = args as VehiculeModel;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => VehiculeFormScreen(vehicule: vehicule),
        );

      case adminAgences:
        final Map<String, dynamic>? routeArgs = args as Map<String, dynamic>?;
        final String? compagnieId = routeArgs?['compagnieId'] as String?;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AgencesManagementScreen(compagnieId: compagnieId),
        );

      case adminAgents:
        final Map<String, dynamic>? routeArgs = args as Map<String, dynamic>?;
        final String? compagnieId = routeArgs?['compagnieId'] as String?;
        final String? agenceId = routeArgs?['agenceId'] as String?;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AgentsManagementScreen(
            compagnieId: compagnieId,
            agenceId: agenceId,
          ),
        );

      case professionalRegistration:
        final String userType = args as String? ?? 'assureur';
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ProfessionalRegistrationScreen(userType: userType),
        );



      default:
        // Gère les routes définies dans la map `routes`
        if (routes.containsKey(settings.name)) {
          return MaterialPageRoute(
            settings: settings,
            builder: routes[settings.name]!,
          );
        }
        // Fallback pour les routes inconnues
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Page non trouvée')),
            body: Center(
              child: Text('Route inconnue: ${settings.name}'),
            ),
          ),
        );
    }
  }

  static String getHomeRouteByUserType(String userType) {
    switch (userType.toLowerCase()) {
      case 'conducteur':
        return conducteurHome;
      case 'assureur':
        return assureurHome;
      case 'expert':
        return expertHome;
      case 'admin':
        return adminHome;
      default:
        return login;
    }
  }

  static String getProfileRouteByUserType(String userType) {
    switch (userType.toLowerCase()) {
      case 'conducteur':
        return conducteurProfile;
      // Ajoutez d'autres types d'utilisateurs si nécessaire
      // case 'assureur': return assureurProfile;
      default:
        return login;
    }
  }
}
