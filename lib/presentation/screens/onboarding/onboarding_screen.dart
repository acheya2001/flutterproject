import 'package:flutter/material.dart';
import 'package:constat_tunisie/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:constat_tunisie/core/services/firebase_service.dart';
import 'package:logger/logger.dart';
import 'package:constat_tunisie/presentation/screens/auth/auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final Logger _logger = Logger();
  int _currentPage = 0;
  bool _isFirebaseInitialized = false;
  bool _isFirebaseInitializing = true;
  String? _firebaseError;
  bool _isNavigating = false;
  
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
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeFirebase() async {
    try {
      _logger.i("Initialisation de Firebase depuis OnboardingScreen...");
      final result = await FirebaseService.initialize();
      
      if (mounted) {
        setState(() {
          _isFirebaseInitialized = result;
          _isFirebaseInitializing = false;
          if (!result) {
            _firebaseError = "Impossible d'initialiser Firebase";
          }
        });
      }
      
      _logger.i("Firebase initialisé avec succès: $result");
    } catch (e) {
      _logger.e("Erreur lors de l'initialisation de Firebase: $e");
      if (mounted) {
        setState(() {
          _isFirebaseInitialized = false;
          _isFirebaseInitializing = false;
          _firebaseError = e.toString();
        });
      }
    }
  }

  // Marquer l'onboarding comme terminé - MÉTHODE CORRIGÉE
  Future<void> _completeOnboarding() async {
    if (_isNavigating) return; // Éviter les navigations multiples
    _isNavigating = true;
    
    try {
      _logger.i("Tentative de navigation vers l'écran d'authentification");
      
      // Essayer d'enregistrer la préférence, mais ne pas attendre si ça échoue
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboarding_complete', true);
        _logger.i("Préférence onboarding_complete enregistrée");
      } catch (e) {
        _logger.e("Erreur lors de l'enregistrement des préférences: $e");
        // Continuer même en cas d'erreur
      }
      
      if (!mounted) {
        _logger.w("Widget non monté, navigation annulée");
        return;
      }
      
      // Utiliser pushReplacement avec MaterialPageRoute au lieu de pushReplacementNamed
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AuthScreen(),
        ),
      );
    } catch (e) {
      _isNavigating = false; // Réinitialiser le flag en cas d'erreur
      _logger.e("Erreur lors de la navigation: $e");
      
      // Afficher un message d'erreur à l'utilisateur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: _completeOnboarding,
            ),
          ),
        );
      }
    }
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
                  onPressed: _isFirebaseInitializing || _isNavigating ? null : _completeOnboarding,
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
                  onPressed: _isFirebaseInitializing || _isNavigating
                    ? null 
                    : () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _completeOnboarding();
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
                  child: _isFirebaseInitializing || _isNavigating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
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
          
          // Message d'erreur Firebase si nécessaire
          if (_firebaseError != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Attention: $_firebaseError\nCertaines fonctionnalités peuvent être limitées.',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          
          // Bouton de secours pour la navigation
          if (_firebaseError != null || _currentPage == _pages.length - 1)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: TextButton.icon(
                  onPressed: _isNavigating ? null : () {
                    _logger.i("Navigation de secours vers l'écran d'authentification");
                    setState(() {
                      _isNavigating = true;
                    });
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const AuthScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text(
                    "Aller directement à l'authentification",
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: Colors.white,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
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