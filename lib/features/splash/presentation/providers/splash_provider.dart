import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/firebase_service.dart';

/// 🚀 État du splash screen
class SplashState {
  final bool isLoading;
  final bool isFirstLaunch;
  final String loadingMessage;
  final double progress;
  final String? error;

  const SplashState({
    this.isLoading = true,
    this.isFirstLaunch = true,
    this.loadingMessage = 'Initialisation...',
    this.progress = 0.0,
    this.error,
  });

  SplashState copyWith({
    bool? isLoading,
    bool? isFirstLaunch,
    String? loadingMessage,
    double? progress,
    String? error,
  }) {
    return SplashState(
      isLoading: isLoading ?? this.isLoading,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      progress: progress ?? this.progress,
      error: error,
    );
  }
}

/// 🚀 Notifier pour le splash screen
class SplashNotifier extends StateNotifier<SplashState> {
  SplashNotifier() : super(const SplashState());

  /// 🔧 Initialisation de l'application
  Future<void> initializeApp() async {
    try {
      // Étape 1: Vérifier si c'est le premier lancement
      state = state.copyWith(
        loadingMessage: 'Vérification des préférences...',
        progress: 0.1,
      );
      
      final isFirstLaunch = await _checkFirstLaunch();
      
      // Étape 2: Initialiser Firebase
      state = state.copyWith(
        loadingMessage: 'Connexion aux services...',
        progress: 0.3,
        isFirstLaunch: isFirstLaunch,
      );
      
      await _initializeFirebase();
      
      // Étape 3: Charger les données de base
      state = state.copyWith(
        loadingMessage: 'Chargement des données...',
        progress: 0.6,
      );
      
      await _loadBasicData();
      
      // Étape 4: Finalisation
      state = state.copyWith(
        loadingMessage: 'Finalisation...',
        progress: 0.9,
      );
      
      await Future.delayed(const Duration(milliseconds: 200)); // Réduit de 500ms à 200ms
      
      // Terminé
      state = state.copyWith(
        isLoading: false,
        loadingMessage: 'Prêt !',
        progress: 1.0,
      );
      
    } catch (e) {
      debugPrint('[SPLASH] Erreur d\'initialisation: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur d\'initialisation: $e',
        loadingMessage: 'Erreur de chargement',
      );
    }
  }

  /// 🔍 Vérifier si c'est le premier lancement
  Future<bool> _checkFirstLaunch() async {
    try {
      // Toujours afficher l'onboarding
      return true;

      // Code original commenté pour référence :
      /*
      final prefs = await SharedPreferences.getInstance();
      final hasLaunchedBefore = prefs.getBool('has_launched_before') ?? false;

      if (!hasLaunchedBefore) {
        // Marquer comme lancé
        await prefs.setBool('has_launched_before', true);
        return true;
      }

      return false;
      */
    } catch (e) {
      debugPrint('[SPLASH] Erreur lors de la vérification du premier lancement: $e');
      return true; // En cas d'erreur, afficher l'onboarding
    }
  }

  /// 🔥 Initialiser Firebase
  Future<void> _initializeFirebase() async {
    try {
      // Firebase est déjà initialisé dans main.dart
      // Ici on peut faire des vérifications supplémentaires
      await Future.delayed(const Duration(milliseconds: 100)); // Réduit de 500ms à 100ms
      debugPrint('[SPLASH] Firebase vérifié');
    } catch (e) {
      debugPrint('[SPLASH] Erreur Firebase: $e');
      throw Exception('Erreur de connexion aux services');
    }
  }

  /// 📊 Charger les données de base
  Future<void> _loadBasicData() async {
    try {
      // Simuler le chargement des données essentielles
      await Future.delayed(const Duration(milliseconds: 100)); // Réduit drastiquement
      
      // Ici on pourrait charger :
      // - Les configurations de l'app
      // - Les données de cache
      // - Les préférences utilisateur
      // - etc.
      
      debugPrint('[SPLASH] Données de base chargées');
    } catch (e) {
      debugPrint('[SPLASH] Erreur lors du chargement des données: $e');
      throw Exception('Erreur de chargement des données');
    }
  }

  /// 🔄 Réinitialiser l'état
  void reset() {
    state = const SplashState();
  }

  /// ⚠️ Marquer une erreur
  void setError(String error) {
    state = state.copyWith(
      isLoading: false,
      error: error,
      loadingMessage: 'Erreur',
    );
  }

  /// 📝 Mettre à jour le message de chargement
  void updateLoadingMessage(String message) {
    state = state.copyWith(loadingMessage: message);
  }

  /// 📊 Mettre à jour le progrès
  void updateProgress(double progress) {
    state = state.copyWith(progress: progress);
  }
}

/// 🚀 Provider principal pour le splash
final splashProvider = StateNotifierProvider<SplashNotifier, SplashState>((ref) {
  return SplashNotifier();
});

/// 🔍 Provider pour vérifier si c'est le premier lancement
final isFirstLaunchProvider = FutureProvider<bool>((ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('has_launched_before') ?? false);
  } catch (e) {
    debugPrint('[SPLASH] Erreur lors de la vérification du premier lancement: $e');
    return true; // Par défaut, considérer comme premier lancement
  }
});

/// ⏳ Provider pour l'état de chargement
final isLoadingProvider = Provider<bool>((ref) {
  final splashState = ref.watch(splashProvider);
  return splashState.isLoading;
});

/// 📊 Provider pour le progrès
final progressProvider = Provider<double>((ref) {
  final splashState = ref.watch(splashProvider);
  return splashState.progress;
});

/// 💬 Provider pour le message de chargement
final loadingMessageProvider = Provider<String>((ref) {
  final splashState = ref.watch(splashProvider);
  return splashState.loadingMessage;
});

/// ❌ Provider pour les erreurs
final splashErrorProvider = Provider<String?>((ref) {
  final splashState = ref.watch(splashProvider);
  return splashState.error;
});
