import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Added for ChangeNotifier if not implicitly imported
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Aliased to avoid conflict
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Added for Riverpod

// Assuming these paths are correct relative to this file's location
// (e.g., if auth_provider.dart is in lib/features/auth/providers/)
import '../models/user_model.dart';
import '../models/conducteur_model.dart';
import '../../admin/services/simple_super_admin.dart';
import '../models/assureur_model.dart';
import '../models/expert_model.dart';
import '../../admin/models/admin_model.dart';
import '../services/clean_auth_service.dart';
import '../../../utils/user_type.dart'; // Adjust path if necessary

class AuthProvider with ChangeNotifier {
  final CleanAuthService _authService = CleanAuthService();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    // initAuth() is called when the provider instance is created below.
  }

  Future<void> initAuth() async {
    try {
      debugPrint('[AuthProvider] Initializing authentication');
      _setLoading(true);
      _clearError();

      // VÉRIFIER LE MODE SUPER ADMIN EN PREMIER
      if (SuperAdminMode.isActive) {
        debugPrint('[AuthProvider] Mode Super Admin actif - IGNORÉ COMPLÈTEMENT');
        _currentUser = null;
        return;
      }

      // Vérifier si c'est le Super Admin - si oui, ignorer
      final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser?.email == 'constat.tunisie.app@gmail.com') {
        debugPrint('[AuthProvider] Super Admin détecté - ignoré par AuthProvider');
        _currentUser = null;
        return;
      }

      final user = await _authService.getCurrentUser();

      if (user != null) {
        debugPrint('[AuthProvider] Current user retrieved: ${user.toString()}');
        _currentUser = user;
      } else {
        debugPrint('[AuthProvider] No current user found');
        _currentUser = null; // Explicitly set to null if no user
      }
    } catch (e) {
      debugPrint('[AuthProvider] Error in initAuth: $e');
      _handleAuthError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<UserModel?> registerUser({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String telephone,
    required UserType userType,
    String? adresse,
    String? cin,
    String? compagnie,
    String? matricule,
    String? cabinet,
    String? agrement,
  }) async {
    try {
      debugPrint('[AuthProvider] Starting user registration');
      _setLoading(true);
      _clearError();

      final user = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        nom: nom,
        prenom: prenom,
        telephone: telephone,
        userType: userType,
        adresse: adresse,
        cin: cin,
        compagnie: compagnie,
        matricule: matricule,
        cabinet: cabinet,
        agrement: agrement,
      );

      if (user != null) {
        debugPrint('[AuthProvider] User registered successfully: ${user.toString()}');
        _currentUser = user;
      } else {
        debugPrint('[AuthProvider] Registration failed, user is null');
        _setError('L\'inscription a échoué. Veuillez réessayer.');
      }
      return user;
    } catch (registerError) {
      debugPrint('[AuthProvider] Error during registration: $registerError');
      if (registerError.toString().contains('PigeonUserDetails')) {
        debugPrint('[AuthProvider] Attempting to recover user after PigeonUserDetails error');
        await Future.delayed(const Duration(seconds: 2));
        if (_authService.isUserLoggedIn()) {
          debugPrint('[AuthProvider] User is logged in, creating necessary documents');
          final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
          if (firebaseUser != null) {
            try {
              final userTypeDoc = await FirebaseFirestore.instance.collection('user_types').doc(firebaseUser.uid).get();
              if (!userTypeDoc.exists) {
                debugPrint('[AuthProvider] Creating user_type document');
                await FirebaseFirestore.instance.collection('user_types').doc(firebaseUser.uid).set({
                  'type': userType.toString().split('.').last,
                  'createdAt': FieldValue.serverTimestamp(),
                });
              }
              
              final userDoc = await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).get();
              if (!userDoc.exists) {
                debugPrint('[AuthProvider] Creating user document');
                final now = DateTime.now();
                await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).set({
                  'id': firebaseUser.uid, 'email': email, 'nom': nom, 'prenom': prenom,
                  'telephone': telephone, 'adresse': adresse, 'type': userType.toString().split('.').last,
                  'createdAt': now, 'updatedAt': now,
                });
              }
              
              switch (userType) {
                case UserType.conducteur:
                  if (cin != null) {
                    final conducteurDoc = await FirebaseFirestore.instance.collection('conducteurs').doc(firebaseUser.uid).get();
                    if (!conducteurDoc.exists) {
                      debugPrint('[AuthProvider] Creating conducteur document');
                      final now = DateTime.now();
                      await FirebaseFirestore.instance.collection('conducteurs').doc(firebaseUser.uid).set({
                        'userId': firebaseUser.uid, 'cin': cin, 'vehiculeIds': <String>[],
                        'createdAt': now, 'updatedAt': now,
                      });
                    }
                  }
                  break;
                case UserType.assureur:
                  if (compagnie != null && matricule != null) {
                    final assureurDoc = await FirebaseFirestore.instance.collection('assureurs').doc(firebaseUser.uid).get();
                    if (!assureurDoc.exists) {
                      debugPrint('[AuthProvider] Creating assureur document');
                      final now = DateTime.now();
                      await FirebaseFirestore.instance.collection('assureurs').doc(firebaseUser.uid).set({
                        'userId': firebaseUser.uid, 'compagnie': compagnie, 'matricule': matricule,
                        'dossierIds': <String>[], 'createdAt': now, 'updatedAt': now,
                      });
                    }
                  }
                  break;
                case UserType.expert:
                  if (cabinet != null && agrement != null) {
                    final expertDoc = await FirebaseFirestore.instance.collection('experts').doc(firebaseUser.uid).get();
                    if (!expertDoc.exists) {
                      debugPrint('[AuthProvider] Creating expert document');
                      final now = DateTime.now();
                      await FirebaseFirestore.instance.collection('experts').doc(firebaseUser.uid).set({
                        'userId': firebaseUser.uid, 'cabinet': cabinet, 'agrement': agrement,
                        'expertiseIds': <String>[], 'createdAt': now, 'updatedAt': now,
                      });
                    }
                  }
                  break;
                case UserType.admin:
                  final adminDoc = await FirebaseFirestore.instance.collection('admins').doc(firebaseUser.uid).get();
                  if (!adminDoc.exists) {
                    debugPrint('[AuthProvider] Creating admin document');
                    final now = DateTime.now();
                    await FirebaseFirestore.instance.collection('admins').doc(firebaseUser.uid).set({
                      'userId': firebaseUser.uid,
                      'niveau_acces': 'admin',
                      'permissions': ['validate_agents', 'manage_system'],
                      'zone_responsabilite': ['Tunis', 'Sfax'],
                      'nombre_validations': 0,
                      'createdAt': now, 'updatedAt': now,
                    });
                  }
                  break;
              }
              
              UserModel? recoveredUser = await _authService.getCurrentUser();
              if (recoveredUser != null) {
                debugPrint('[AuthProvider] Successfully recovered user: ${recoveredUser.toString()}');
                _currentUser = recoveredUser;
                notifyListeners();
                return recoveredUser;
              } else {
                UserModel? manualUser;
                final now = DateTime.now();
                switch (userType) {
                  case UserType.conducteur:
                    if (cin != null) {
                      manualUser = ConducteurModel(id: firebaseUser.uid, email: email, nom: nom, prenom: prenom, telephone: telephone, cin: cin, adresse: adresse, createdAt: now, updatedAt: now);
                    }
                    break;
                  case UserType.assureur:
                    if (compagnie != null && matricule != null) {
                      manualUser = AssureurModel(
                        id: firebaseUser.uid,
                        email: email,
                        nom: nom,
                        prenom: prenom,
                        telephone: telephone,
                        compagnie: compagnie,
                        matricule: matricule,
                        agenceId: '', // Sera assigné plus tard par un admin
                        agenceNom: '', // Sera assigné plus tard par un admin
                        gouvernorat: '', // Sera assigné plus tard par un admin
                        poste: 'Agent Commercial', // Poste par défaut
                        adresse: adresse,
                        createdAt: now,
                        updatedAt: now
                      );
                    }
                    break;
                  case UserType.expert:
                    if (cabinet != null && agrement != null) {
                      manualUser = ExpertModel(id: firebaseUser.uid, email: email, nom: nom, prenom: prenom, telephone: telephone, cabinet: cabinet, agrement: agrement, adresse: adresse, createdAt: now, updatedAt: now);
                    }
                    break;
                  case UserType.admin:
                    manualUser = AdminModel(
                      uid: firebaseUser.uid,
                      email: email,
                      nom: nom,
                      prenom: prenom,
                      telephone: telephone,
                      adresse: adresse,
                      dateCreation: now,
                      dateModification: now,
                      niveauAcces: 'admin',
                      zoneResponsabilite: ['Tunis', 'Sfax'],
                      permissions: ['validate_agents', 'manage_system'],
                    );
                    break;
                }
                manualUser ??= UserModel(uid: firebaseUser.uid, email: email, nom: nom, prenom: prenom, telephone: telephone, userType: userType, adresse: adresse, dateCreation: now, dateModification: now);
                _currentUser = manualUser;
                notifyListeners();
                return manualUser;
              }
            } catch (e) {
              debugPrint('[AuthProvider] Error creating documents: $e');
            }
          }
        }
      }
      _handleAuthError(registerError);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[AuthProvider] Starting user sign in');
      _setLoading(true);
      _clearError();

      final user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (user != null) {
        debugPrint('[AuthProvider] User signed in successfully: ${user.toString()}');
        _currentUser = user;
      } else {
        debugPrint('[AuthProvider] Sign in failed, user is null');
        _setError('La connexion a échoué. Veuillez vérifier vos identifiants.');
      }
      return user;
    } catch (e) {
      debugPrint('[AuthProvider] Error in signIn: $e');
       if (e.toString().contains('PigeonUserDetails')) {
        debugPrint('[AuthProvider] PigeonUserDetails error detected, attempting to continue');
        if (_authService.isUserLoggedIn()) {
          debugPrint('[AuthProvider] User is logged in, trying to get user data');
          try {
            final recoveredUser = await _authService.getCurrentUser();
            if (recoveredUser != null) {
              _currentUser = recoveredUser;
              notifyListeners(); // Explicit notify for this recovery path
              return recoveredUser;
            }
          } catch (innerError) {
            debugPrint('[AuthProvider] Error during recovery: $innerError');
          }
        }
      }
      _handleAuthError(e);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      debugPrint('[AuthProvider] Starting user sign out');
      _setLoading(true);
      _clearError();

      await _authService.signOut();
      
      debugPrint('[AuthProvider] User signed out successfully');
      _currentUser = null;
    } catch (e) {
      debugPrint('[AuthProvider] Error in signOut: $e');
      _handleAuthError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      debugPrint('[AuthProvider] Starting password reset for email: $email');
      _setLoading(true);
      _clearError();
      await _authService.resetPassword(email);
      debugPrint('[AuthProvider] Password reset email sent successfully');
      return true;
    } catch (e) {
      debugPrint('[AuthProvider] Error in resetPassword: $e');
      _handleAuthError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  bool isUserLoggedIn() {
    final isLoggedIn = _authService.isUserLoggedIn();
    debugPrint('[AuthProvider] Is user logged in: $isLoggedIn');
    return isLoggedIn;
  }

  void _handleAuthError(dynamic error) {
    String errorMessage = 'Une erreur s\'est produite. Veuillez réessayer.';
    if (error is Exception) {
      debugPrint('[AuthProvider] Authentication error: $error');
      if (error.toString().contains('PigeonUserDetails') && _authService.isUserLoggedIn()) {
        debugPrint('[AuthProvider] Ignoring PigeonUserDetails error since user is logged in');
        _clearError();
        return;
      }
      final errorString = error.toString().toLowerCase();
      if (errorString.contains('user-not-found') || errorString.contains('no user record') || errorString.contains('invalid-credential')) {
        errorMessage = 'Email ou mot de passe incorrect.';
      } else if (errorString.contains('wrong-password')) {
        errorMessage = 'Mot de passe incorrect.';
      } else if (errorString.contains('email-already-in-use') || errorString.contains('already in use')) {
        errorMessage = 'Cet email est déjà utilisé par un autre compte.';
      } else if (errorString.contains('weak-password')) {
        errorMessage = 'Le mot de passe est trop faible (minimum 6 caractères).';
      } else if (errorString.contains('invalid-email')) {
        errorMessage = 'Format d\'email invalide.';
      } else if (errorString.contains('network-request-failed') || errorString.contains('network error')) {
        errorMessage = 'Erreur de connexion réseau. Vérifiez votre connexion internet.';
      } else if (errorString.contains('too-many-requests')) {
        errorMessage = 'Trop de tentatives. Veuillez réessayer plus tard.';
      }
    }
    _setError(errorMessage);
  }

  void _setLoading(bool loading) {
    if (_isLoading == loading) return;
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? errorMessage) {
    if (_error == errorMessage) return;
    _error = errorMessage;
    notifyListeners();
  }

  void _clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  /// 🧪 Méthode pour créer un utilisateur de test (développement uniquement)
  void setTestUser() {
    final now = DateTime.now();
    _currentUser = UserModel(
      uid: 'test_conducteur_1',
      email: 'test@example.com',
      nom: 'Test',
      prenom: 'Utilisateur',
      telephone: '+216 98 123 456',
      userType: UserType.conducteur,
      adresse: 'Adresse de test',
      dateCreation: now,
      dateModification: now,
    );
    notifyListeners();
    debugPrint('[AuthProvider] Test user set: ${_currentUser?.uid}');
  }
}

final authProvider = ChangeNotifierProvider((ref) {
  final provider = AuthProvider();
  provider.initAuth();
  return provider;
});
