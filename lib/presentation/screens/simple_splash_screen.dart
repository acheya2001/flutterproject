import 'package:flutter/material.dart';
import 'package:constat_tunisie/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:logger/logger.dart';

class SimpleSplashScreen extends StatefulWidget {
  const SimpleSplashScreen({Key? key}) : super(key: key);

  @override
  State<SimpleSplashScreen> createState() => _SimpleSplashScreenState();
}

class _SimpleSplashScreenState extends State<SimpleSplashScreen> {
  final Logger _logger = Logger();
  
  @override
  void initState() {
    super.initState();
    _logger.i("SimpleSplashScreen initialisé");
    
    // Navigation simple après un délai
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _logger.i("Navigation vers OnboardingScreen");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/images/logo.png',
              width: 150,
              height: 150,
            ),
            
            const SizedBox(height: 30),
            
            // Titre de l'application
            const Text(
              'Constat Tunisie',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A6CFF),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Slogan
            const Text(
              'Simplifiez vos démarches après accident',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 50),
            
            // Indicateur de chargement
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A6CFF)),
            ),
          ],
        ),
      ),
    );
  }
}