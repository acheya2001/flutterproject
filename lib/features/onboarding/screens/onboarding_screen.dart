import 'package:flutter/material.dart';

import '../../../core/config/app_routes.dart';
import '../../../core/config/app_theme.dart';
import '../../../core/widgets/custom_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: 'Bienvenue sur Constat Tunisie',
      description: 'L\'application qui simplifie vos déclarations d\'accidents',
      icon: Icons.car_crash,
      color: AppTheme.primaryColor,
    ),
    OnboardingItem(
      title: 'Déclarez vos accidents',
      description: 'Remplissez votre constat rapidement et facilement',
      icon: Icons.description,
      color: AppTheme.secondaryColor,
    ),
    OnboardingItem(
      title: 'Suivez vos dossiers',
      description: 'Restez informé de l\'avancement de vos déclarations',
      icon: Icons.track_changes,
      color: AppTheme.accentColor,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.languageSelection);
    }
  }

  void _skip() {
    Navigator.pushReplacementNamed(context, AppRoutes.languageSelection);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _skip,
                child: const Text('Passer'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPage(_items[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _items.length,
                      (index) => _buildDot(index),
                    ),
                  ),
                  // Correction: Utilisation de SizedBox pour contrôler la largeur
                  SizedBox(
                    width: 120,
                    child: CustomButton(
                      text: _currentPage < _items.length - 1 ? 'Suivant' : 'Commencer',
                      onPressed: _nextPage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingItem item) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              // Correction: Remplacement de withOpacity par withValues
              color: item.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              size: 60,
              color: item.color,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            item.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index
            ? AppTheme.primaryColor
            : Colors.grey.shade300,
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
