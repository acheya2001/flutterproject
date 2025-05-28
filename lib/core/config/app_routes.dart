import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/splash/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/language/screens/language_selection_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/conducteur/screens/conducteur_home_screen.dart';
import '../../features/conducteur/screens/conducteur_profile_screen.dart';
import '../../features/conducteur/screens/conducteur_vehicules_screen.dart';
import '../../features/conducteur/screens/conducteur_accidents_screen.dart';
import '../../features/conducteur/screens/conducteur_declaration_screen.dart';
import '../../features/assureur/screens/assureur_home_screen.dart';
import '../../features/expert/screens/expert_home_screen.dart';

class AppRoutes {
  // Routes principales
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String languageSelection = '/language-selection';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  
  // Routes conducteur
  static const String conducteurHome = '/conducteur/home';
  static const String conducteurProfile = '/conducteur/profile';
  static const String conducteurVehicules = '/conducteur/vehicules';
  static const String conducteurAccidents = '/conducteur/accidents';
  static const String conducteurDeclaration = '/conducteur/declaration';
  
  // Routes assureur
  static const String assureurHome = '/assureur/home';
  static const String assureurProfile = '/assureur/profile';
  static const String assureurDossiers = '/assureur/dossiers';
  static const String assureurClients = '/assureur/clients';
  
  // Routes expert
  static const String expertHome = '/expert/home';
  static const String expertProfile = '/expert/profile';
  static const String expertExpertises = '/expert/expertises';
  static const String expertRapports = '/expert/rapports';
  
  // Routes communes
  static const String documents = '/documents';
  static const String createConstat = '/create-constat';
  static const String constatHistory = '/constat-history';
  static const String profile = '/profile';
  static const String vehicules = '/vehicules';
  
  // Méthode pour obtenir l'ID de l'utilisateur connecté
  static String _getCurrentUserId() {
    final auth = FirebaseAuth.instance;
    return auth.currentUser?.uid ?? '';
  }
  
  // Définition des routes
  static final Map<String, WidgetBuilder> routes = {
    // Routes principales
    splash: (context) => const SplashScreen(),
    onboarding: (context) => const OnboardingScreen(),
    languageSelection: (context) => const LanguageSelectionScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    
    // Routes conducteur
    conducteurHome: (context) => const ConducteurHomeScreen(),
    conducteurProfile: (context) => const ConducteurProfileScreen(),
    conducteurVehicules: (context) => ConducteurVehiculesScreen(
      conducteurId: _getCurrentUserId(),
    ),
    conducteurAccidents: (context) => const ConducteurAccidentsScreen(),
    // Correction: Ajout du paramètre requis conducteurPosition
    conducteurDeclaration: (context) => const ConducteurDeclarationScreen(
      conducteurPosition: 'A', // Position par défaut
    ),
    
    // Routes assureur
    assureurHome: (context) => const AssureurHomeScreen(),
    
    // Routes expert
    expertHome: (context) => const ExpertHomeScreen(),
  };
  
  // Méthode pour générer les routes dynamiquement
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;
    
    switch (settings.name) {
      case conducteurVehicules:
        final conducteurId = args is Map<String, dynamic> ? 
            args['conducteurId'] ?? _getCurrentUserId() : 
            _getCurrentUserId();
            
        return MaterialPageRoute(
          builder: (_) => ConducteurVehiculesScreen(
            conducteurId: conducteurId,
          ),
        );
      
      case conducteurDeclaration:
        final sessionId = args is Map<String, dynamic> ? args['sessionId'] : null;
        final conducteurPosition = args is Map<String, dynamic> ? 
            args['conducteurPosition'] ?? 'A' : 'A';
        final invitationCode = args is Map<String, dynamic> ? args['invitationCode'] : null;
            
        return MaterialPageRoute(
          builder: (_) => ConducteurDeclarationScreen(
            sessionId: sessionId,
            conducteurPosition: conducteurPosition,
            invitationCode: invitationCode,
          ),
        );
      
      default:
        if (routes.containsKey(settings.name)) {
          return MaterialPageRoute(
            builder: routes[settings.name]!,
          );
        }
        
        return MaterialPageRoute(
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
      default:
        return login;
    }
  }
  
  static String getProfileRouteByUserType(String userType) {
    switch (userType.toLowerCase()) {
      case 'conducteur':
        return conducteurProfile;
      case 'assureur':
        return assureurProfile;
      case 'expert':
        return expertProfile;
      default:
        return profile;
    }
  }
}
