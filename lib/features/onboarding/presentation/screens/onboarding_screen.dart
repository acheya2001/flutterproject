import 'package:flutter/material.dart';
import '../../../auth/presentation/screens/user_type_selection_screen_elegant.dart';
import '../../../../core/theme/app_theme.dart';

/// 🎯 Écran d'onboarding moderne et élégant
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>with TickerProviderStateMixin  {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: '🚗 Constat Intelligent',
      description: 'Créez vos constats d\'accident rapidement avec notre assistant intelligent et notre reconnaissance vocale.',
      icon: Icons.smart_toy,
      color: const Color(0xFF6C63FF),
      gradient: const LinearGradient(
        colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    OnboardingPage(
      title: '📱 Suivi en Temps Réel',
      description: 'Suivez l\'évolution de vos dossiers, recevez des notifications et communiquez avec les experts.',
      icon: Icons.timeline,
      color: const Color(0xFF00D4AA),
      gradient: const LinearGradient(
        colors: [Color(0xFF00D4AA), Color(0xFF00E5FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    OnboardingPage(
      title: '🔧 Expertise Professionnelle',
      description: 'Bénéficiez d\'une expertise automobile certifiée avec photos, vidéos et rapports détaillés.',
      icon: Icons.engineering,
      color: const Color(0xFFFF6B6B),
      gradient: const LinearGradient(
        colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finishOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const UserTypeSelectionScreenElegant(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: _pages[_currentPage].gradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Barre du haut avec bouton passer
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Constat Tunisie',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: const Text(
                        'Passer',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Pages d'onboarding
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    if (mounted) setState(() {
                      _currentPage = index;
                    });
                    _animationController.reset();
                    _animationController.forward();
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildOnboardingPage(_pages[index]);
                  },
                ),
              ),

            // Indicateurs et boutons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Indicateurs de page
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppTheme.primaryColor
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Boutons de navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Bouton précédent
                      if (_currentPage > 0)
                        TextButton(
                          onPressed: _previousPage,
                          child: const Text(
                            'Précédent',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 80),

                      // Bouton suivant/commencer
                      ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1 ? 'Commencer' : 'Suivant',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildOnboardingPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône animée avec effet de pulsation
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1200),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Icon(
                        page.icon,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 60),

              // Titre avec animation de glissement
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: Text(
                        page.title,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Description avec animation
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1000),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 40 * (1 - value)),
                      child: Text(
                        page.description,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.6,
                          fontWeight: FontWeight.w300,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 📄 Modèle pour une page d'onboarding
class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final LinearGradient gradient;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.gradient,
  });
}
