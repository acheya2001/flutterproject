import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/firebase_service.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../shared/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../../admin/services/simple_super_admin.dart';

/// 🔐 État d'authentification simple
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserModel? currentUser;
  final String? error;
  final String? message;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.currentUser,
    this.error,
    this.message,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserModel? currentUser,
    String? error,
    String? message,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      currentUser: currentUser ?? this.currentUser,
      error: error,
      message: message,
    );
  }
}

/// 🔐 Notifier d'authentification simple
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    // Écouter les changements d'état d'authentification
    FirebaseService.auth.authStateChanges().listen(_onAuthStateChanged);
  }

  /// 🔑 Connexion
  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.signInWithEmailAndPassword(email, password);

      if (result.isSuccess) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          currentUser: result.user,
          message: result.message,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          error: result.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: 'Erreur de connexion: $e',
      );
    }
  }

  /// 📝 Inscription conducteur
  Future<void> registerDriver({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String cin,
    required String drivingLicenseNumber,
    required DateTime drivingLicenseIssueDate,
    required DateTime drivingLicenseExpiryDate,
    String? address,
    DateTime? dateOfBirth,
    String? profession,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.registerDriver(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        cin: cin,
        drivingLicenseNumber: drivingLicenseNumber,
        drivingLicenseIssueDate: drivingLicenseIssueDate,
        drivingLicenseExpiryDate: drivingLicenseExpiryDate,
        address: address,
        dateOfBirth: dateOfBirth,
        profession: profession,
      );

      if (result.isSuccess) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          currentUser: result.user,
          message: 'Inscription réussie ! Bienvenue !',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de l\'inscription: $e',
      );
    }
  }

  /// � Connexion Super Admin
  Future<void> signInSuperAdmin({
    String? email,
    String? password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userCredential = await SimpleSuperAdmin.signInSuperAdmin(
        email: email,
        password: password,
      );

      if (userCredential != null) {
        // Connexion réussie - pas besoin de UserModel complexe
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          currentUser: null, // On évite UserModel pour l'instant
        );
        debugPrint('[AUTH_PROVIDER] Connexion Super Admin réussie');
      }
    } catch (e) {
      debugPrint('[AUTH_PROVIDER] Erreur connexion Super Admin: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// �🚪 Déconnexion
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.signOut();
      state = const AuthState(); // Reset complet
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la déconnexion: $e',
      );
    }
  }

  /// 🔄 Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.resetPassword(email);

      if (result.isSuccess) {
        state = state.copyWith(
          isLoading: false,
          message: result.message,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la réinitialisation: $e',
      );
    }
  }

  /// 🔄 Actualisation des données utilisateur
  Future<void> refreshUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        state = state.copyWith(
          currentUser: user,
          isAuthenticated: true,
        );
      }
    } catch (e) {
      // Erreur silencieuse
    }
  }

  /// 🧹 Effacement des messages
  void clearMessages() {
    state = state.copyWith(error: null, message: null);
  }

  /// 👂 Écoute des changements d'état Firebase Auth
  void _onAuthStateChanged(User? user) async {
    // VÉRIFIER LE MODE SUPER ADMIN EN PREMIER
    if (SuperAdminMode.isActive) {
      debugPrint('[AUTH_PROVIDER] Mode Super Admin actif - IGNORÉ COMPLÈTEMENT');
      return;
    }

    if (user == null) {
      // Utilisateur déconnecté
      state = const AuthState();
    } else {
      // Vérifier si c'est le Super Admin - si oui, ignorer
      if (user.email == 'constat.tunisie.app@gmail.com') {
        debugPrint('[AUTH_PROVIDER] Super Admin détecté - ignoré par AuthProvider');
        return;
      }

      // Utilisateur connecté - récupérer les données
      try {
        debugPrint('[AUTH_PROVIDER] Récupération données utilisateur normal...');
        final userModel = await _authService.getCurrentUser();
        if (userModel != null) {
          state = state.copyWith(
            isAuthenticated: true,
            currentUser: userModel,
            isLoading: false,
          );
        }
      } catch (e) {
        debugPrint('[AUTH_PROVIDER] Erreur récupération utilisateur: $e');
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          error: 'Erreur lors de la récupération des données utilisateur',
        );
      }
    }
  }
}

/// 🔐 Provider principal d'authentification
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.read(authServiceProvider);
  return AuthNotifier(authService);
});

/// 👤 Provider pour l'utilisateur actuel
final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.currentUser;
});

/// 🎭 Provider pour le rôle de l'utilisateur actuel
final currentUserRoleProvider = Provider<UserRole?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.role;
});

/// ✅ Provider pour vérifier si l'utilisateur est connecté
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.isAuthenticated;
});

/// ⏳ Provider pour vérifier si une opération est en cours
final isLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.isLoading;
});

/// ❌ Provider pour les erreurs d'authentification
final authErrorProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.error;
});

/// 💬 Provider pour les messages d'authentification
final authMessageProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.message;
});

/// 🔐 Provider pour vérifier si l'utilisateur a un rôle spécifique
final hasRoleProvider = Provider.family<bool, UserRole>((ref, role) {
  final currentRole = ref.watch(currentUserRoleProvider);
  return currentRole == role;
});

/// 👨‍💼 Provider pour vérifier si l'utilisateur est admin
final isAdminProvider = Provider<bool>((ref) {
  final currentRole = ref.watch(currentUserRoleProvider);
  return currentRole?.isAdmin ?? false;
});

/// 🎯 Provider pour vérifier si l'utilisateur peut gérer d'autres utilisateurs
final canManageUsersProvider = Provider<bool>((ref) {
  final currentRole = ref.watch(currentUserRoleProvider);
  return currentRole?.canManageUsers ?? false;
});

/// 📋 Provider pour vérifier si l'utilisateur peut créer des contrats
final canCreateContractsProvider = Provider<bool>((ref) {
  final currentRole = ref.watch(currentUserRoleProvider);
  return currentRole?.canCreateContracts ?? false;
});

/// 🔄 Provider pour l'état de connexion Firebase
final firebaseAuthStateProvider = StreamProvider<User?>((ref) {
  return FirebaseService.auth.authStateChanges();
});
