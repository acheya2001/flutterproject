class AppRoutes {
  // Auth routes
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  
  // Dashboard routes
  static const String conducteurDashboard = '/conducteur-dashboard';
  static const String adminDashboard = '/admin-dashboard';
  static const String expertDashboard = '/expert-dashboard';
  static const String assureurDashboard = '/assureur-dashboard';
  
  // Conducteur routes
  static const String conducteurVehicules = '/conducteur/vehicules';
  static const String conducteurAccidents = '/conducteur/accidents';
  static const String conducteurInvitations = '/conducteur/invitations';
  static const String professionalSession = '/conducteur/professional-session';
  
  // Constat routes
  static const String declarationEntryPoint = '/constat/declaration';
  static const String joinSession = '/constat/join-session';
  static const String aiDemo = '/constat/ai-demo';
  
  // Admin routes
  static const String superAdminDashboard = '/super-admin-dashboard';
  static const String compagnieDashboard = '/compagnie-dashboard';
  static const String agenceDashboard = '/agence-dashboard';
  
  // Expert routes
  static const String expertiseList = '/expert/expertises';
  static const String expertiseDetails = '/expert/expertise-details';
  
  // Settings routes
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String about = '/about';
}
