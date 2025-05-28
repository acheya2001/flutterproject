import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/config/app_routes.dart';
import 'core/config/app_theme.dart';
import 'core/services/notification_reminder_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/vehicule/providers/vehicule_provider.dart';
import 'features/conducteur/providers/conducteur_provider.dart';
import 'features/splash/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Activer les logs détaillés en mode debug
  if (kDebugMode) {
    debugPrint('[CONSTAT_APP] Starting application in debug mode');
  }
  
  try {
    await Firebase.initializeApp();
    debugPrint('[CONSTAT_APP] Firebase initialized successfully');
    
    // Initialiser le service de notifications de rappel
    try {
      await NotificationReminderService().initialize();
      debugPrint('[CONSTAT_APP] Notification reminder service initialized successfully');
    } catch (e) {
      debugPrint('[CONSTAT_APP] Warning: Could not initialize notification service: $e');
      // Ne pas bloquer l'application si les notifications échouent
    }
  } catch (e) {
    debugPrint('[CONSTAT_APP] Error during initialization: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VehiculeProvider()),
        ChangeNotifierProvider(create: (_) => ConducteurProvider()),
      ],
      child: MaterialApp(
        title: 'Constat Tunisie',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        navigatorObservers: [
          _NavigationObserver(),
        ],
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.routes,
        home: const SplashScreen(),
      ),
    );
  }
}

// Observer pour déboguer la navigation
class _NavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('[CONSTAT_APP] Navigation: Pushed ${route.settings.name} (from ${previousRoute?.settings.name})');
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('[CONSTAT_APP] Navigation: Popped ${route.settings.name} (back to ${previousRoute?.settings.name})');
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    debugPrint('[CONSTAT_APP] Navigation: Replaced ${oldRoute?.settings.name} with ${newRoute?.settings.name}');
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('[CONSTAT_APP] Navigation: Removed ${route.settings.name}');
    super.didRemove(route, previousRoute);
  }
}
