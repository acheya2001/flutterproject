import 'package:flutter/material.dart';
import 'package:constat_tunisie/core/providers/auth_provider.dart';
import 'package:constat_tunisie/core/enums/user_role.dart'; // Ajout de l'import manquant
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key}); // Utilisation de super.key

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Attendre 2.5 secondes pour l'animation du splash screen
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Vérifier si l'utilisateur est déjà connecté
    if (authProvider.isLoggedIn) {
      // Rediriger vers l'écran approprié en fonction du rôle
      switch (authProvider.currentUser?.role) {
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
          Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    } else {
      // Rediriger vers l'écran d'onboarding ou d'authentification
      Navigator.of(context).pushReplacementNamed('/onboarding');
    }
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
