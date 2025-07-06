import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import '../../models/onboarding_page_model.dart';

/// 🎯 État de l'onboarding
class OnboardingState {
  final int currentIndex;
  final bool isCompleted;
  final bool isLoading;

  const OnboardingState({
    this.currentIndex = 0,
    this.isCompleted = false,
    this.isLoading = false,
  });

  OnboardingState copyWith({
    int? currentIndex,
    bool? isCompleted,
    bool? isLoading,
  }) {
    return OnboardingState(
      currentIndex: currentIndex ?? this.currentIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// 🎯 Notifier pour l'onboarding
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(const OnboardingState());

  /// 📄 Changer l'index de la page courante
  void setCurrentIndex(int index) {
    if (index >= 0 && index < OnboardingPageModel.totalPages) {
      state = state.copyWith(currentIndex: index);
    }
  }

  /// ➡️ Aller à la page suivante
  void nextPage() {
    final nextIndex = state.currentIndex + 1;
    if (nextIndex < OnboardingPageModel.totalPages) {
      setCurrentIndex(nextIndex);
    }
  }

  /// ⬅️ Aller à la page précédente
  void previousPage() {
    final previousIndex = state.currentIndex - 1;
    if (previousIndex >= 0) {
      setCurrentIndex(previousIndex);
    }
  }

  /// ⏭️ Aller à une page spécifique
  void goToPage(int index) {
    setCurrentIndex(index);
  }

  /// ✅ Terminer l'onboarding
  Future<void> completeOnboarding() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      
      state = state.copyWith(
        isCompleted: true,
        isLoading: false,
      );
      
      debugPrint('[ONBOARDING] Onboarding terminé avec succès');
    } catch (e) {
      debugPrint('[ONBOARDING] Erreur lors de la sauvegarde: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// 🔄 Réinitialiser l'onboarding
  Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', false);
      
      state = const OnboardingState();
      
      debugPrint('[ONBOARDING] Onboarding réinitialisé');
    } catch (e) {
      debugPrint('[ONBOARDING] Erreur lors de la réinitialisation: $e');
    }
  }

  /// 🔍 Vérifier si l'onboarding est terminé
  Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('onboarding_completed') ?? false;
    } catch (e) {
      debugPrint('[ONBOARDING] Erreur lors de la vérification: $e');
      return false;
    }
  }

  /// 📊 Obtenir le progrès en pourcentage
  double get progress {
    return (state.currentIndex + 1) / OnboardingPageModel.totalPages;
  }

  /// 🔍 Vérifier si c'est la dernière page
  bool get isLastPage {
    return OnboardingPageModel.isLastPage(state.currentIndex);
  }

  /// 🔍 Vérifier si c'est la première page
  bool get isFirstPage {
    return OnboardingPageModel.isFirstPage(state.currentIndex);
  }

  /// 📄 Obtenir la page courante
  OnboardingPageModel get currentPage {
    return OnboardingPageModel.getPage(state.currentIndex);
  }
}

/// 🎯 Provider principal pour l'onboarding
final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});

/// 📊 Provider pour le progrès
final onboardingProgressProvider = Provider<double>((ref) {
  final notifier = ref.read(onboardingProvider.notifier);
  return notifier.progress;
});

/// 🔍 Provider pour vérifier si c'est la dernière page
final isLastPageProvider = Provider<bool>((ref) {
  final notifier = ref.read(onboardingProvider.notifier);
  return notifier.isLastPage;
});

/// 🔍 Provider pour vérifier si c'est la première page
final isFirstPageProvider = Provider<bool>((ref) {
  final notifier = ref.read(onboardingProvider.notifier);
  return notifier.isFirstPage;
});

/// 📄 Provider pour la page courante
final currentPageProvider = Provider<OnboardingPageModel>((ref) {
  final notifier = ref.read(onboardingProvider.notifier);
  return notifier.currentPage;
});

/// ✅ Provider pour vérifier si l'onboarding est terminé
final isOnboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final notifier = ref.read(onboardingProvider.notifier);
  return await notifier.isOnboardingCompleted();
});

/// 📱 Provider pour l'index de la page courante
final currentIndexProvider = Provider<int>((ref) {
  final onboardingState = ref.watch(onboardingProvider);
  return onboardingState.currentIndex;
});

/// ⏳ Provider pour l'état de chargement
final onboardingLoadingProvider = Provider<bool>((ref) {
  final onboardingState = ref.watch(onboardingProvider);
  return onboardingState.isLoading;
});
