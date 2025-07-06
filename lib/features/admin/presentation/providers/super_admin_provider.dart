import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/simple_super_admin.dart';

/// 🔐 État du Super Admin (simplifié)
class SuperAdminState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;
  final Map<String, dynamic>? adminData;

  const SuperAdminState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
    this.adminData,
  });

  SuperAdminState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
    Map<String, dynamic>? adminData,
  }) {
    return SuperAdminState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
      adminData: adminData ?? this.adminData,
    );
  }
}

/// 🔐 Provider Super Admin Simplifié
class SuperAdminNotifier extends StateNotifier<SuperAdminState> {
  SuperAdminNotifier() : super(const SuperAdminState());



  /// 🚪 Déconnexion
  Future<void> signOut() async {
    try {
      SuperAdminMode.deactivate();
      await FirebaseAuth.instance.signOut();
      state = const SuperAdminState();
      debugPrint('[SUPER_ADMIN_PROVIDER] 🚪 Déconnexion réussie');
    } catch (e) {
      debugPrint('[SUPER_ADMIN_PROVIDER] ❌ Erreur déconnexion: $e');
    }
  }

  /// 🔄 Vérifier l'état de connexion
  Future<void> checkAuthState() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && user.email == 'constat.tunisie.app@gmail.com') {
        // Si l'utilisateur connecté a l'email du Super Admin, c'est bon
        state = state.copyWith(
          isAuthenticated: true,
          adminData: {
            'id': user.uid,
            'email': user.email,
            'firstName': 'Super',
            'lastName': 'Admin',
            'role': 'super_admin',
            'status': 'active',
          },
        );
      } else {
        await signOut();
      }
    } catch (e) {
      debugPrint('[SUPER_ADMIN_PROVIDER] ❌ Erreur vérification: $e');
      await signOut();
    }
  }

  /// 🧹 Effacer l'erreur
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 🚀 Connexion forcée (bypass Firebase Auth)
  void forceLogin() {
    debugPrint('[SUPER_ADMIN_PROVIDER] 🚀 Connexion forcée activée');

    SuperAdminMode.activate();

    final adminData = {
      'id': 'super_admin_forced',
      'email': 'constat.tunisie.app@gmail.com',
      'firstName': 'Super',
      'lastName': 'Admin',
      'role': 'super_admin',
      'status': 'active',
    };

    state = state.copyWith(
      isLoading: false,
      isAuthenticated: true,
      adminData: adminData,
    );

    debugPrint('[SUPER_ADMIN_PROVIDER] ✅ Connexion forcée réussie');
  }

  /// 📊 Obtenir les statistiques
  Future<Map<String, int>> getStatistics() async {
    try {
      // Ici on peut ajouter des statistiques réelles
      return {
        'total_users': 0,
        'total_companies': 0,
        'total_agencies': 0,
        'total_agents': 0,
        'total_experts': 0,
        'total_drivers': 0,
      };
    } catch (e) {
      debugPrint('[SUPER_ADMIN_PROVIDER] ❌ Erreur statistiques: $e');
      return {};
    }
  }


}

/// 🔐 Provider Super Admin
final superAdminProvider = StateNotifierProvider<SuperAdminNotifier, SuperAdminState>(
  (ref) => SuperAdminNotifier(),
);

/// 🔐 Provider pour vérifier si l'utilisateur est connecté en tant que Super Admin
final isSuperAdminProvider = Provider<bool>((ref) {
  final superAdminState = ref.watch(superAdminProvider);
  return superAdminState.isAuthenticated;
});

/// 📊 Provider pour les données du Super Admin
final superAdminDataProvider = Provider<Map<String, dynamic>?>((ref) {
  final superAdminState = ref.watch(superAdminProvider);
  return superAdminState.adminData;
});

/// 📈 Provider pour les statistiques
final superAdminStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final notifier = ref.read(superAdminProvider.notifier);
  return await notifier.getStatistics();
});
