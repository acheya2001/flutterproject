import 'package:flutter/material.dart';
import 'package:constat_tunisie/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Bienvenue sur Constat Tunisie',
      description: 'L\'application qui simplifie vos démarches après un accident de la route.',
      image: 'assets/images/car_icon.png',
      backgroundColor: AppTheme.primaryColor,
    ),
    OnboardingPage(
      title: 'Remplissez votre constat',
      description: 'Complétez facilement votre constat amiable directement depuis votre smartphone.',
      image: 'assets/images/document_icon.png',
      backgroundColor: AppTheme.secondaryColor,
    ),
    OnboardingPage(
      title: 'Suivez votre dossier',
      description: 'Restez informé de l\'avancement de votre dossier en temps réel.',
      image: 'assets/images/insurance_icon.png',
      backgroundColor: AppTheme.accentColor,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Marquer l'onboarding comme terminé
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    
    if (!mounted) return;
    
    // Naviguer vers l'écran d'authentification
    Navigator.of(context).pushReplacementNamed('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Pages d'onboarding
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
            },
          ),
          
          // Indicateurs de page
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => _buildDot(index),
              ),
            ),
          ),
          
          // Boutons de navigation
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Bouton Passer
                TextButton(
                  onPressed: _completeOnboarding, // Utiliser la fonction pour terminer l'onboarding
                  child: const Text(
                    'Passer',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
                
                // Bouton Suivant ou Commencer
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _completeOnboarding(); // Utiliser la fonction pour terminer l'onboarding
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _currentPage < _pages.length - 1 ? 'Suivant' : 'Commencer',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Container(
      color: page.backgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image
          Image.asset(
            page.image,
            height: 200,
            width: 200,
          ),
          const SizedBox(height: 40),
          
          // Titre
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              page.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String image;
  final Color backgroundColor;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
    required this.backgroundColor,
  });
}
