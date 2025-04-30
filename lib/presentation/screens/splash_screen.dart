import 'package:flutter/material.dart';
import 'package:constat_tunisie/core/providers/auth_provider.dart';
import 'package:constat_tunisie/data/enums/user_role.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:constat_tunisie/firebase_options.dart';
import 'package:logger/logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final Logger _logger = Logger();
  bool _isFirebaseInitialized = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    
    // Mécanisme de secours: forcer la navigation après 8 secondes
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && !_isNavigating) {
        _logger.i("Forçage de la navigation après délai de sécurité");
        _navigateToOnboarding();
      }
    });
  }

  Future<void> _initializeApp() async {
    try {
      _logger.i("Initialisation de Firebase...");
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _logger.i("Firebase initialisé avec succès");
      
      if (mounted) {
        setState(() {
          _isFirebaseInitialized = true;
        });
      }
      
      // Attendre un peu pour l'animation
      await Future.delayed(const Duration(milliseconds: 2000));
      
      if (mounted) {
        _navigateBasedOnAuthState();
      }
    } catch (e) {
      _logger.e("Erreur d'initialisation Firebase: $e");
      
      // En cas d'erreur, attendre un peu puis naviguer vers l'onboarding
      await Future.delayed(const Duration(milliseconds: 2000));
      
      if (mounted) {
        _navigateToOnboarding();
      }
    }
  }

  Future<void> _navigateBasedOnAuthState() async {
    if (_isNavigating) return;
    _isNavigating = true;
    
    _logger.i("Vérification de l'état d'authentification...");
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Attendre que l'AuthProvider soit initialisé (avec timeout)
      bool initialized = false;
      for (int i = 0; i < 10; i++) {
        if (authProvider.isInitialized) {
          initialized = true;
          break;
        }
        _logger.d("Attente de l'initialisation de l'AuthProvider... tentative $i");
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      if (!initialized) {
        _logger.w("Timeout: AuthProvider non initialisé après 5 secondes");
        _navigateToOnboarding();
        return;
      }
      
      _logger.i("AuthProvider initialisé, isLoggedIn: ${authProvider.isLoggedIn}");
      
      if (!mounted) return;
      
      if (authProvider.isLoggedIn) {
        final role = authProvider.currentUser?.role;
        _logger.i("Utilisateur connecté avec le rôle: $role");
        
        switch (role) {
          case UserRole.driver:
            Navigator.of(context).pushReplacementNamed('/driver-home');
            break;
          case UserRole.insurance:
            Navigator.of(context).pushReplacementNamed('/insurance-home');
            break;
          case UserRole.expert:
            Navigator.of(context).pushReplacementNamed('/expert-home');
            break;
          default:
            _navigateToOnboarding();
        }
      } else {
        _navigateToOnboarding();
      }
    } catch (e) {
      _logger.e("Erreur lors de la navigation: $e");
      if (mounted) {
        _navigateToOnboarding();
      }
    }
  }

  void _navigateToOnboarding() {
    if (!mounted || _isNavigating) return;
    _isNavigating = true;
    _logger.i("Navigation vers l'écran d'onboarding");
    Navigator.of(context).pushReplacementNamed('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo animé
            Image.asset(
              'assets/images/logo.png',
              width: 150,
              height: 150,
            )
            .animate()
            .scale(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.0, 1.0),
            )
            .then()
            .fadeIn(duration: const Duration(milliseconds: 300)),
            
            const SizedBox(height: 30),
            
            // Titre de l'application
            const Text(
              'Constat Tunisie',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A6CFF),
              ),
            )
            .animate()
            .fadeIn(delay: const Duration(milliseconds: 300))
            .slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 10),
            
            // Slogan
            const Text(
              'Simplifiez vos démarches après accident',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            )
            .animate()
            .fadeIn(delay: const Duration(milliseconds: 500)),
            
            const SizedBox(height: 50),
            
            // Indicateur de chargement
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A6CFF)),
            )
            .animate()
            .fadeIn(delay: const Duration(milliseconds: 700)),
          ],
        ),
      ),
    );
  }
}