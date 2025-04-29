import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:constat_tunisie/core/providers/auth_provider.dart';
import 'package:constat_tunisie/core/theme/app_theme.dart';
import 'package:constat_tunisie/presentation/screens/splash_screen.dart';
import 'package:constat_tunisie/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:constat_tunisie/presentation/screens/auth/auth_screen.dart';
import 'package:constat_tunisie/presentation/screens/auth/register_screen.dart';
import 'package:constat_tunisie/presentation/screens/auth/login_screen.dart';
import 'package:constat_tunisie/presentation/screens/auth/forgot_password_screen.dart';
import 'package:constat_tunisie/presentation/screens/driver/driver_home_screen.dart';
import 'package:constat_tunisie/presentation/screens/insurance/insurance_home_screen.dart';
import 'package:constat_tunisie/presentation/screens/expert/expert_home_screen.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final logger = Logger();
  
  // Définir l'orientation de l'application
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Constat Tunisie',
        debugShowCheckedModeBanner: false, // Supprimer la bannière DEBUG
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/auth': (context) => const AuthScreen(),
          '/register': (context) => const RegisterScreen(),
          '/login': (context) => const LoginScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/driver-home': (context) => DriverHomeScreen(),
          '/insurance-home': (context) => const InsuranceHomeScreen(),
          '/expert-home': (context) => const ExpertHomeScreen(),
          // Ajouter d'autres routes ici
        },
        // Gestionnaire d'erreurs de navigation
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: const Text('Page non trouvée'),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Oups! La page demandée n\'existe pas.',
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/');
                      },
                      child: const Text('Retour à l\'accueil'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
