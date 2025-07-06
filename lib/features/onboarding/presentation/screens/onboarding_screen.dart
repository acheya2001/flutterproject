import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/app_router.dart';
import '../../models/onboarding_page_model.dart';
import '../widgets/onboarding_page_widget.dart';
import '../widgets/onboarding_indicator.dart';
import '../providers/onboarding_provider.dart';

/// 🎯 Écran d'onboarding principal
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _buttonController;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _buttonScale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  /// 🧭 Navigation vers la page suivante
  void _nextPage() {
    final currentIndex = ref.read(onboardingProvider).currentIndex;
    
    if (OnboardingPageModel.isLastPage(currentIndex)) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// ⬅️ Navigation vers la page précédente
  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// ⏭️ Passer l'onboarding
  void _skipOnboarding() {
    _completeOnboarding();
  }

  /// ✅ Terminer l'onboarding
  void _completeOnboarding() async {
    await ref.read(onboardingProvider.notifier).completeOnboarding();
    
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRouter.userTypeSelection);
    }
  }

  /// 📄 Changement de page
  void _onPageChanged(int index) {
    ref.read(onboardingProvider.notifier).setCurrentIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);
    final currentPage = OnboardingPageModel.getPage(onboardingState.currentIndex);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: OnboardingPageModel.getGradientColors(onboardingState.currentIndex),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 🔝 Barre supérieure avec bouton Skip
              _buildTopBar(),
              
              // 📄 Pages d'onboarding
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: OnboardingPageModel.totalPages,
                  itemBuilder: (context, index) {
                    final page = OnboardingPageModel.getPage(index);
                    return OnboardingPageWidget(
                      page: page,
                      isActive: index == onboardingState.currentIndex,
                    );
                  },
                ),
              ),
              
              // 🔘 Indicateurs de page
              OnboardingIndicator(
                currentIndex: onboardingState.currentIndex,
                totalPages: OnboardingPageModel.totalPages,
              ),
              
              const SizedBox(height: 32),
              
              // 🎯 Boutons de navigation
              _buildNavigationButtons(onboardingState.currentIndex),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔝 Barre supérieure
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo ou titre
          Text(
            'Constat Tunisie',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // Bouton Skip
          TextButton(
            onPressed: _skipOnboarding,
            child: Text(
              'Passer',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Boutons de navigation
  Widget _buildNavigationButtons(int currentIndex) {
    final isLastPage = OnboardingPageModel.isLastPage(currentIndex);
    final isFirstPage = OnboardingPageModel.isFirstPage(currentIndex);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Row(
        children: [
          // Bouton Précédent
          if (!isFirstPage)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Précédent',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          
          if (!isFirstPage) const SizedBox(width: 16),
          
          // Bouton Suivant/Commencer
          Expanded(
            flex: isFirstPage ? 1 : 1,
            child: AnimatedBuilder(
              animation: _buttonScale,
              builder: (context, child) {
                return Transform.scale(
                  scale: _buttonScale.value,
                  child: ElevatedButton(
                    onPressed: () {
                      _buttonController.forward().then((_) {
                        _buttonController.reverse();
                        _nextPage();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: OnboardingPageModel.getPage(currentIndex).backgroundColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      isLastPage ? 'Commencer' : 'Suivant',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
