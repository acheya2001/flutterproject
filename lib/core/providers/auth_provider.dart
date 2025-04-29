import 'package:flutter/material.dart';
import 'package:constat_tunisie/core/enums/user_role.dart';
import 'package:constat_tunisie/data/models/user_model.dart';
import 'package:constat_tunisie/data/services/mock_auth_service.dart';
import 'package:logger/logger.dart';

class AuthProvider extends ChangeNotifier {
  final MockAuthService _authService = MockAuthService();
  final Logger _logger = Logger();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isEmailVerified => _currentUser?.emailVerified ?? false;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Vérifier si l'utilisateur est déjà connecté
      final userData = await _authService.getUserData();
      if (userData != null) {
        _currentUser = userData;
      }
      
      // Écouter les changements d'état d'authentification
      _authService.authStateChanges.listen((user) async {
        _currentUser = user;
        _isInitialized = true;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _logger.e('Erreur lors de l\'initialisation: $e');
      _error = e.toString();
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Inscription avec email et mot de passe
  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userModel = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
        phoneNumber: phoneNumber,
      );
      
      _currentUser = userModel;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _logger.e('Erreur lors de l\'inscription: $e');
      _error = _handleAuthError(e);
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Connexion avec email et mot de passe
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userModel = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _currentUser = userModel;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _logger.e('Erreur lors de la connexion: $e');
      _error = _handleAuthError(e);
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _logger.e('Erreur lors de la déconnexion: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _logger.e('Erreur lors de la réinitialisation du mot de passe: $e');
      _error = _handleAuthError(e);
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Renvoyer l'email de vérification
  Future<void> sendEmailVerification() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendEmailVerification();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _logger.e('Erreur lors de l\'envoi de l\'email de vérification: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Rafraîchir les données utilisateur
  Future<void> refreshUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userData = await _authService.getUserData();
      _currentUser = userData;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _logger.e('Erreur lors du rafraîchissement des données utilisateur: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mettre à jour le profil utilisateur
  Future<void> updateUserProfile({
    String? displayName,
    String? phoneNumber,
    String? photoURL,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.updateUserProfile(
        displayName: displayName,
        phoneNumber: phoneNumber,
        photoURL: photoURL,
      );
      
      await refreshUserData();
    } catch (e) {
      _logger.e('Erreur lors de la mise à jour du profil: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Effacer les erreurs
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Gérer les erreurs d'authentification
  String _handleAuthError(dynamic e) {
    return e.toString();
  }
  
  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }
}
