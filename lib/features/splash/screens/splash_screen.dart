import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_routes.dart';
import '../../../core/config/app_theme.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/constants.dart';
import '../../../utils/user_type.dart';
import '../../auth/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Configuration des animations
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
      ),
    );
    
    _controller.forward();
    
    // Initialiser l'authentification
    _checkAuth();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    // Attendre un peu pour montrer l'animation
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initAuth();
    
    if (!mounted) return;
    
    if (authProvider.isAuthenticated) {
      final userType = authProvider.currentUser!.type;
      
      if (!mounted) return;
      
      switch (userType) {
        case UserType.conducteur:
          Navigator.pushReplacementNamed(context, AppRoutes.conducteurHome);
          break;
        case UserType.assureur:
          Navigator.pushReplacementNamed(context, AppRoutes.assureurHome);
          break;
        case UserType.expert:
          Navigator.pushReplacementNamed(context, AppRoutes.expertHome);
          break;
      }
    } else {
      if (!mounted) return;
      
      final hasSeenOnboarding = StorageService.getBool(Constants.prefOnboardingCompleted);
      
      if (!mounted) return;
      
      if (hasSeenOnboarding ?? false) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo avec animation
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withAlpha(60),
                            blurRadius: 20,
                            spreadRadius: 5,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.car_crash,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Titre de l'application
                    Text(
                      'Constat Tunisie',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Slogan
                    Text(
                      'Simplifiez vos déclarations d\'accidents',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Indicateur de chargement
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
