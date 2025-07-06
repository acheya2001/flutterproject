import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/animated_logo.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/splash_provider.dart';

/// 🚀 Écran de démarrage avec animation
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _progressValue;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }

  /// 🎬 Initialisation des animations
  void _initializeAnimations() {
    // Animation du logo
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoScale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    // Animation du texte
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    // Animation de la barre de progression
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _progressValue = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
  }

  /// 🎭 Séquence d'animation du splash
  void _startSplashSequence() async {
    // Démarrer l'animation du logo
    await _logoController.forward();
    
    // Attendre un peu puis démarrer le texte
    await Future.delayed(const Duration(milliseconds: 300));
    _textController.forward();
    
    // Démarrer la barre de progression
    await Future.delayed(const Duration(milliseconds: 500));
    _progressController.forward();

    // Initialiser l'application en arrière-plan
    _initializeApp();
  }

  /// 🔧 Initialisation de l'application
  void _initializeApp() async {
    try {
      // Simuler le chargement des données
      await ref.read(splashProvider.notifier).initializeApp();
      
      // Attendre que les animations se terminent
      await _progressController.forward();
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Naviguer vers l'écran suivant
      _navigateToNextScreen();
    } catch (e) {
      debugPrint('[SPLASH] Erreur d\'initialisation: $e');
      // En cas d'erreur, naviguer quand même
      await Future.delayed(const Duration(seconds: 1));
      _navigateToNextScreen();
    }
  }

  /// 🧭 Navigation vers l'écran suivant
  void _navigateToNextScreen() {
    final splashState = ref.read(splashProvider);
    final authState = ref.read(authProvider);

    if (mounted) {
      if (authState.isAuthenticated && authState.currentUser != null) {
        // Utilisateur connecté - aller au dashboard
        final route = AppRouter.getDashboardRoute(authState.currentUser!.role);
        Navigator.pushReplacementNamed(context, route);
      } else if (splashState.isFirstLaunch) {
        // Premier lancement - aller à l'onboarding
        Navigator.pushReplacementNamed(context, AppRouter.onboarding);
      } else {
        // Utilisateur existant - aller à la sélection du type
        Navigator.pushReplacementNamed(context, AppRouter.userTypeSelection);
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final splashState = ref.watch(splashProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const Spacer(flex: 2),
              
              // 🎯 Logo animé
              _buildAnimatedLogo(),
              
              const SizedBox(height: 32),
              
              // 📝 Texte animé
              _buildAnimatedText(),
              
              const Spacer(flex: 2),
              
              // 📊 Barre de progression
              _buildProgressBar(),
              
              const SizedBox(height: 16),
              
              // 💬 Message de chargement
              _buildLoadingMessage(splashState),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎯 Logo animé
  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScale.value,
          child: Opacity(
            opacity: _logoOpacity.value,
            child: AnimatedLogo(
              size: 120,
              backgroundColor: Colors.white,
              iconColor: AppTheme.primaryColor,
              autoStart: false,
              onAnimationComplete: () {
                // Animation du logo terminée
              },
            ),
          ),
        );
      },
    );
  }

  /// 📝 Texte animé
  Widget _buildAnimatedText() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return SlideTransition(
          position: _textSlide,
          child: Opacity(
            opacity: _textOpacity.value,
            child: Column(
              children: [
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Déclaration d\'accidents simplifiée',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 📊 Barre de progression
  Widget _buildProgressBar() {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        return Column(
          children: [
            Container(
              width: double.infinity,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressValue.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 💬 Message de chargement
  Widget _buildLoadingMessage(SplashState splashState) {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return Opacity(
          opacity: _textOpacity.value,
          child: Text(
            splashState.loadingMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}
