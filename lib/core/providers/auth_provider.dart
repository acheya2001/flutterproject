import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:constat_tunisie/data/services/auth_service.dart';
import 'package:constat_tunisie/data/models/user_model.dart';
import 'package:constat_tunisie/data/enums/user_role.dart';




class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
  bool get isInitialized => _isInitialized;
  
  // Constructeur
  AuthProvider() {
    _initializeUser();
  }
  
  // Initialiser l'utilisateur actuel
  Future<void> _initializeUser() async {
    _setLoading(true);
    try {
      final user = _authService.getCurrentUser();
      if (user != null) {
        await _fetchUserData(user.uid);
      }
    } catch (e) {
      _setError(e.toString());
      _logger.e('Erreur lors de l\'initialisation de l\'utilisateur: $e');
    } finally {
      _setLoading(false);
      _isInitialized = true;
    }
  }
  
  // Récupérer les données utilisateur depuis Firestore
  Future<void> _fetchUserData(String uid) async {
    try {
      final userData = await _authService.getUserData(uid);
      if (userData != null) {
        _currentUser = UserModel.fromFirestore(
          await _firestore.collection('users').doc(uid).get(),
        );
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
      _logger.e('Erreur lors de la récupération des données utilisateur: $e');
    }
  }
  
  // Inscription avec email et mot de passe
  Future<bool> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required String phoneNumber,
    required UserRole role,
    required Map<String, dynamic> profileData,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
  final userCredential = await _authService.registerWithEmailAndPassword(
    email: email,
    password: password,
    displayName: displayName,
    phoneNumber: phoneNumber,
    role: role.toString().split('.').last, // Conversion simple de l'enum en string
    // OU si vous avez implémenté l'extension: role: role.value,
    profileData: profileData,
  );
      
      await _fetchUserData(userCredential.user!.uid);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Une erreur s\'est produite lors de l\'inscription.');
      _logger.e('Erreur d\'authentification: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      _setError(e.toString());
      _logger.e('Erreur inattendue lors de l\'inscription: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Connexion avec email et mot de passe
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final userCredential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await _fetchUserData(userCredential.user!.uid);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Une erreur s\'est produite lors de la connexion.');
      _logger.e('Erreur d\'authentification: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      _setError(e.toString());
      _logger.e('Erreur inattendue lors de la connexion: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Récupération du mot de passe
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.resetPassword(email);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Une erreur s\'est produite lors de la réinitialisation du mot de passe.');
      _logger.e('Erreur d\'authentification: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      _setError(e.toString());
      _logger.e('Erreur inattendue lors de la réinitialisation du mot de passe: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Déconnexion
  Future<bool> signOut() async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.signOut();
      _currentUser = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _logger.e('Erreur lors de la déconnexion: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Mettre à jour les données utilisateur
  Future<bool> updateUserData(Map<String, dynamic> data) async {
    _setLoading(true);
    _clearError();
    
    try {
      if (_currentUser == null) {
        throw Exception('Aucun utilisateur connecté');
      }
      
      await _authService.updateUserData(_currentUser!.uid, data);
      await _fetchUserData(_currentUser!.uid);
      return true;
    } catch (e) {
      _setError(e.toString());
      _logger.e('Erreur lors de la mise à jour des données utilisateur: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Mettre à jour le mot de passe
  Future<bool> updatePassword(String newPassword) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.updatePassword(newPassword);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Une erreur s\'est produite lors de la mise à jour du mot de passe.');
      _logger.e('Erreur d\'authentification: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      _setError(e.toString());
      _logger.e('Erreur inattendue lors de la mise à jour du mot de passe: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Helpers
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
    notifyListeners();
  }
}