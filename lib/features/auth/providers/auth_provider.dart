import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../models/conducteur_model.dart';
import '../models/assureur_model.dart';
import '../models/expert_model.dart';
import '../services/auth_service.dart';
import '../../../utils/user_type.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // Méthode pour initialiser l'authentification
  Future<void> initAuth() async {
    try {
      debugPrint('[AuthProvider] Initializing authentication');
      _setLoading(true);
      _clearError();

      final user = await _authService.getCurrentUser();
      
      if (user != null) {
        debugPrint('[AuthProvider] Current user retrieved: ${user.toString()}');
        _currentUser = user;
        notifyListeners();
      } else {
        debugPrint('[AuthProvider] No current user found');
      }
    } catch (e) {
      debugPrint('[AuthProvider] Error in initAuth: $e');
      _handleAuthError(e);
    } finally {
      _setLoading(false);
    }
  }

  // Méthode pour enregistrer un nouvel utilisateur
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
        notifyListeners();
      } else {
        debugPrint('[AuthProvider] Registration failed, user is null');
        _setError('L\'inscription a échoué. Veuillez réessayer.');
      }

      return user;
    } catch (registerError) {
      debugPrint('[AuthProvider] Error during registration: $registerError');
      
      // Si l'erreur est liée à PigeonUserDetails, essayons de récupérer l'utilisateur créé
      if (registerError.toString().contains('PigeonUserDetails')) {
        debugPrint('[AuthProvider] Attempting to recover user after PigeonUserDetails error');
        
        // Attendre un peu pour que Firebase termine la création de l'utilisateur
        await Future.delayed(const Duration(seconds: 2));
        
        // Vérifier si l'utilisateur est connecté
        if (_authService.isUserLoggedIn()) {
          debugPrint('[AuthProvider] User is logged in, creating necessary documents');
          
          // Récupérer l'utilisateur Firebase
          final firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser != null) {
            // Créer le document user_types s'il n'existe pas
            try {
              final userTypeDoc = await FirebaseFirestore.instance.collection('user_types').doc(firebaseUser.uid).get();
              if (!userTypeDoc.exists) {
                debugPrint('[AuthProvider] Creating user_type document');
                await FirebaseFirestore.instance.collection('user_types').doc(firebaseUser.uid).set({
                  'type': userType.toString().split('.').last,
                  'createdAt': FieldValue.serverTimestamp(),
                });
              }
              
              // Créer le document users s'il n'existe pas
              final userDoc = await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).get();
              if (!userDoc.exists) {
                debugPrint('[AuthProvider] Creating user document');
                final now = DateTime.now();
                await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).set({
                  'id': firebaseUser.uid,
                  'email': email,
                  'nom': nom,
                  'prenom': prenom,
                  'telephone': telephone,
                  'adresse': adresse,
                  'type': userType.toString().split('.').last,
                  'createdAt': now,
                  'updatedAt': now,
                });
              }
              
              // Créer le document spécifique au type d'utilisateur s'il n'existe pas
              switch (userType) {
                case UserType.conducteur:
                  if (cin != null) {
                    final conducteurDoc = await FirebaseFirestore.instance.collection('conducteurs').doc(firebaseUser.uid).get();
                    if (!conducteurDoc.exists) {
                      debugPrint('[AuthProvider] Creating conducteur document');
                      final now = DateTime.now();
                      await FirebaseFirestore.instance.collection('conducteurs').doc(firebaseUser.uid).set({
                        'userId': firebaseUser.uid,
                        'cin': cin,
                        'vehiculeIds': <String>[],
                        'createdAt': now,
                        'updatedAt': now,
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
                        'userId': firebaseUser.uid,
                        'compagnie': compagnie,
                        'matricule': matricule,
                        'dossierIds': <String>[],
                        'createdAt': now,
                        'updatedAt': now,
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
                        'userId': firebaseUser.uid,
                        'cabinet': cabinet,
                        'agrement': agrement,
                        'expertiseIds': <String>[],
                        'createdAt': now,
                        'updatedAt': now,
                      });
                    }
                  }
                  break;
              }
              
              // Essayer de récupérer l'utilisateur à nouveau
              UserModel? user = await _authService.getCurrentUser();
              
              if (user != null) {
                debugPrint('[AuthProvider] Successfully recovered user: ${user.toString()}');
                _currentUser = user;
                notifyListeners();
                return user;
              } else {
                // Si nous ne pouvons toujours pas récupérer l'utilisateur, créons-en un manuellement
                debugPrint('[AuthProvider] Creating user model manually');
                final now = DateTime.now();
                
                switch (userType) {
                  case UserType.conducteur:
                    if (cin != null) {
                      user = ConducteurModel(
                        id: firebaseUser.uid,
                        email: email,
                        nom: nom,
                        prenom: prenom,
                        telephone: telephone,
                        cin: cin,
                        adresse: adresse,
                        createdAt: now,
                        updatedAt: now,
                      );
                    }
                    break;
                  case UserType.assureur:
                    if (compagnie != null && matricule != null) {
                      user = AssureurModel(
                        id: firebaseUser.uid,
                        email: email,
                        nom: nom,
                        prenom: prenom,
                        telephone: telephone,
                        compagnie: compagnie,
                        matricule: matricule,
                        adresse: adresse,
                        createdAt: now,
                        updatedAt: now,
                      );
                    }
                    break;
                  case UserType.expert:
                    if (cabinet != null && agrement != null) {
                      user = ExpertModel(
                        id: firebaseUser.uid,
                        email: email,
                        nom: nom,
                        prenom: prenom,
                        telephone: telephone,
                        cabinet: cabinet,
                        agrement: agrement,
                        adresse: adresse,
                        createdAt: now,
                        updatedAt: now,
                      );
                    }
                    break;
                }
                
                if (user == null) {
                  user = UserModel(
                    id: firebaseUser.uid,
                    email: email,
                    nom: nom,
                    prenom: prenom,
                    telephone: telephone,
                    type: userType,
                    adresse: adresse,
                    createdAt: now,
                    updatedAt: now,
                  );
                }
                
                _currentUser = user;
                notifyListeners();
                return user;
              }
            } catch (e) {
              debugPrint('[AuthProvider] Error creating documents: $e');
            }
          } else {
            debugPrint('[AuthProvider] Firebase user is null');
          }
        } else {
          debugPrint('[AuthProvider] User is not logged in');
        }
        
        debugPrint('[AuthProvider] Failed to recover user');
      }
      
      _handleAuthError(registerError);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Méthode pour connecter un utilisateur
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
        notifyListeners();
      } else {
        debugPrint('[AuthProvider] Sign in failed, user is null');
        _setError('La connexion a échoué. Veuillez vérifier vos identifiants.');
      }

      return user;
    } catch (e) {
      debugPrint('[AuthProvider] Error in signIn: $e');
      
      // Si l'erreur est liée à PigeonUserDetails, essayons de récupérer l'utilisateur
      if (e.toString().contains('PigeonUserDetails')) {
        debugPrint('[AuthProvider] PigeonUserDetails error detected, attempting to continue');
        
        // Vérifier si l'utilisateur est connecté
        if (_authService.isUserLoggedIn()) {
          debugPrint('[AuthProvider] User is logged in, trying to get user data');
          
          try {
            // Récupérer l'utilisateur
            final user = await _authService.getCurrentUser();
            
            if (user != null) {
              debugPrint('[AuthProvider] Successfully recovered user: ${user.toString()}');
              _currentUser = user;
              notifyListeners();
              return user;
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

  // Méthode pour déconnecter l'utilisateur
  Future<void> signOut() async {
    try {
      debugPrint('[AuthProvider] Starting user sign out');
      _setLoading(true);
      _clearError();

      await _authService.signOut();
      
      debugPrint('[AuthProvider] User signed out successfully');
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('[AuthProvider] Error in signOut: $e');
      _handleAuthError(e);
    } finally {
      _setLoading(false);
    }
  }

  // Méthode pour réinitialiser le mot de passe
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

  // Méthode pour vérifier si un utilisateur est connecté
  bool isUserLoggedIn() {
    final isLoggedIn = _authService.isUserLoggedIn();
    debugPrint('[AuthProvider] Is user logged in: $isLoggedIn');
    return isLoggedIn;
  }

  // Méthode pour gérer les erreurs d'authentification
  void _handleAuthError(dynamic error) {
    String errorMessage = 'Une erreur s\'est produite. Veuillez réessayer.';
    
    if (error is Exception) {
      debugPrint('[AuthProvider] Authentication error: $error');
      
      // Ignorer les erreurs liées à PigeonUserDetails si l'utilisateur est connecté
      if (error.toString().contains('PigeonUserDetails') && _authService.isUserLoggedIn()) {
        debugPrint('[AuthProvider] Ignoring PigeonUserDetails error since user is logged in');
        return;
      }
      
      // Analyser le message d'erreur pour fournir un message plus convivial
      final errorString = error.toString().toLowerCase();
      
      if (errorString.contains('user-not-found') || 
          errorString.contains('no user record')) {
        errorMessage = 'Aucun utilisateur trouvé avec cet email.';
      } else if (errorString.contains('wrong-password') || 
                errorString.contains('invalid-credential')) {
        errorMessage = 'Mot de passe incorrect.';
      } else if (errorString.contains('email-already-in-use') || 
                errorString.contains('already in use')) {
        errorMessage = 'Cet email est déjà utilisé par un autre compte.';
      } else if (errorString.contains('weak-password')) {
        errorMessage = 'Le mot de passe est trop faible.';
      } else if (errorString.contains('invalid-email')) {
        errorMessage = 'Format d\'email invalide.';
      } else if (errorString.contains('network-request-failed') || 
                errorString.contains('network error')) {
        errorMessage = 'Erreur de connexion réseau. Vérifiez votre connexion internet.';
      } else if (errorString.contains('too-many-requests')) {
        errorMessage = 'Trop de tentatives. Veuillez réessayer plus tard.';
      }
    }
    
    _setError(errorMessage);
  }

  // Méthode pour définir l'état de chargement
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Méthode pour définir un message d'erreur
  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  // Méthode pour effacer le message d'erreur
  void _clearError() {
    _error = null;
    notifyListeners();
  }
}