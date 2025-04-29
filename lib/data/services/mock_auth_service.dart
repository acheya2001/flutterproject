import 'dart:async';
import 'dart:convert';
import 'package:constat_tunisie/core/enums/user_role.dart';
import 'package:constat_tunisie/data/models/user_model.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service d'authentification simulé qui fonctionne sans Firebase
/// Utilise SharedPreferences pour stocker les données utilisateur
class MockAuthService {
  final Logger _logger = Logger();
  
  // Utilisateur actuellement connecté
  UserModel? _currentUser;
  
  // Contrôleur de flux pour simuler authStateChanges
  final StreamController<UserModel?> _authStateController = StreamController<UserModel?>.broadcast();
  
  // Obtenir l'utilisateur actuel
  UserModel? get currentUser => _currentUser;
  
  // Stream pour suivre les changements d'état d'authentification
  Stream<UserModel?> get authStateChanges => _authStateController.stream;
  
  // Vérifier si l'email est vérifié (toujours vrai en mode simulé)
  bool get isEmailVerified => true;
  
  // Constructeur
  MockAuthService() {
    // Charger l'utilisateur depuis SharedPreferences au démarrage
    _loadCurrentUser();
  }
  
  // Charger l'utilisateur actuel depuis SharedPreferences
  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      
      if (userJson != null) {
        final userData = json.decode(userJson) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(userData);
        _authStateController.add(_currentUser);
      } else {
        _currentUser = null;
        _authStateController.add(null);
      }
    } catch (e) {
      _logger.e('Erreur lors du chargement de l\'utilisateur: $e');
      _currentUser = null;
      _authStateController.add(null);
    }
  }
  
  // Sauvegarder l'utilisateur actuel dans SharedPreferences
  Future<void> _saveCurrentUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', json.encode(user.toJson()));
    } catch (e) {
      _logger.e('Erreur lors de la sauvegarde de l\'utilisateur: $e');
    }
  }
  
  // Sauvegarder un utilisateur dans la "base de données" (SharedPreferences)
  Future<void> _saveUserToDatabase(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Récupérer la liste des utilisateurs existants
      final usersJson = prefs.getStringList('users') ?? [];
      
      // Vérifier si l'utilisateur existe déjà
      bool userExists = false;
      List<String> updatedUsersJson = [];
      
      for (final userJson in usersJson) {
        final userData = json.decode(userJson) as Map<String, dynamic>;
        if (userData['email'] == user.email) {
          // Mettre à jour l'utilisateur existant
          updatedUsersJson.add(json.encode(user.toJson()));
          userExists = true;
        } else {
          updatedUsersJson.add(userJson);
        }
      }
      
      // Ajouter le nouvel utilisateur s'il n'existe pas
      if (!userExists) {
        updatedUsersJson.add(json.encode(user.toJson()));
      }
      
      // Sauvegarder la liste mise à jour
      await prefs.setStringList('users', updatedUsersJson);
    } catch (e) {
      _logger.e('Erreur lors de la sauvegarde de l\'utilisateur dans la base de données: $e');
    }
  }
  
  // Récupérer un utilisateur depuis la "base de données" (SharedPreferences)
  Future<UserModel?> _getUserFromDatabase(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getStringList('users') ?? [];
      
      for (final userJson in usersJson) {
        final userData = json.decode(userJson) as Map<String, dynamic>;
        if (userData['email'] == email) {
          return UserModel.fromJson(userData);
        }
      }
      
      return null;
    } catch (e) {
      _logger.e('Erreur lors de la récupération de l\'utilisateur depuis la base de données: $e');
      return null;
    }
  }
  
  // Inscription avec email et mot de passe
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? phoneNumber,
  }) async {
    try {
      // Vérifier si l'utilisateur existe déjà
      final existingUser = await _getUserFromDatabase(email);
      if (existingUser != null) {
        throw Exception('Cet email est déjà utilisé par un autre compte.');
      }
      
      // Simuler un délai réseau
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Créer un nouvel utilisateur
      final user = UserModel(
        uid: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email,
        displayName: displayName,
        role: role,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
        emailVerified: true,
        additionalData: {'password': password}, // Stocker le mot de passe (en clair pour la simulation)
      );
      
      // Sauvegarder l'utilisateur dans la "base de données"
      await _saveUserToDatabase(user);
      
      // Définir l'utilisateur actuel
      _currentUser = user;
      _authStateController.add(_currentUser);
      
      // Sauvegarder l'utilisateur actuel
      await _saveCurrentUser(user);
      
      return user;
    } catch (e) {
      _logger.e('Erreur lors de l\'inscription: $e');
      rethrow;
    }
  }
  
  // Connexion avec email et mot de passe
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Récupérer l'utilisateur depuis la "base de données"
      final user = await _getUserFromDatabase(email);
      
      // Simuler un délai réseau
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (user == null) {
        throw Exception('Aucun utilisateur trouvé avec cet email.');
      }
      
      // Vérifier le mot de passe
      final storedPassword = user.additionalData?['password'] as String?;
      if (storedPassword != password) {
        throw Exception('Mot de passe incorrect.');
      }
      
      // Mettre à jour la date de dernière connexion
      final updatedUser = user.copyWith(
        lastLoginAt: DateTime.now(),
      );
      
      // Sauvegarder l'utilisateur mis à jour
      await _saveUserToDatabase(updatedUser);
      
      // Définir l'utilisateur actuel
      _currentUser = updatedUser;
      _authStateController.add(_currentUser);
      
      // Sauvegarder l'utilisateur actuel
      await _saveCurrentUser(updatedUser);
      
      return updatedUser;
    } catch (e) {
      _logger.e('Erreur lors de la connexion: $e');
      rethrow;
    }
  }
  
  // Déconnexion
  Future<void> signOut() async {
    try {
      // Simuler un délai réseau
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Supprimer l'utilisateur actuel
      _currentUser = null;
      _authStateController.add(null);
      
      // Supprimer l'utilisateur des préférences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
    } catch (e) {
      _logger.e('Erreur lors de la déconnexion: $e');
      rethrow;
    }
  }
  
  // Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    try {
      // Récupérer l'utilisateur depuis la "base de données"
      final user = await _getUserFromDatabase(email);
      
      // Simuler un délai réseau
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (user == null) {
        throw Exception('Aucun utilisateur trouvé avec cet email.');
      }
      
      // En mode simulé, nous ne faisons rien de plus
      _logger.i('Demande de réinitialisation de mot de passe pour: $email');
    } catch (e) {
      _logger.e('Erreur lors de la réinitialisation du mot de passe: $e');
      rethrow;
    }
  }
  
  // Renvoyer l'email de vérification
  Future<void> sendEmailVerification() async {
    try {
      // Simuler un délai réseau
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (_currentUser == null) {
        throw Exception('Aucun utilisateur connecté.');
      }
      
      // En mode simulé, nous ne faisons rien de plus
      _logger.i('Demande d\'envoi d\'email de vérification pour: ${_currentUser!.email}');
    } catch (e) {
      _logger.e('Erreur lors de l\'envoi de l\'email de vérification: $e');
      rethrow;
    }
  }
  
  // Obtenir les données utilisateur
  Future<UserModel?> getUserData() async {
    try {
      // Simuler un délai réseau
      await Future.delayed(const Duration(milliseconds: 300));
      
      return _currentUser;
    } catch (e) {
      _logger.e('Erreur lors de la récupération des données utilisateur: $e');
      return null;
    }
  }
  
  // Mettre à jour le profil utilisateur
  Future<void> updateUserProfile({
    String? displayName,
    String? phoneNumber,
    String? photoURL,
  }) async {
    try {
      // Simuler un délai réseau
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (_currentUser == null) {
        throw Exception('Aucun utilisateur connecté.');
      }
      
      // Mettre à jour l'utilisateur
      final updatedUser = _currentUser!.copyWith(
        displayName: displayName ?? _currentUser!.displayName,
        phoneNumber: phoneNumber ?? _currentUser!.phoneNumber,
        photoURL: photoURL ?? _currentUser!.photoURL,
      );
      
      // Sauvegarder l'utilisateur mis à jour
      await _saveUserToDatabase(updatedUser);
      
      // Mettre à jour l'utilisateur actuel
      _currentUser = updatedUser;
      _authStateController.add(_currentUser);
      
      // Sauvegarder l'utilisateur actuel
      await _saveCurrentUser(updatedUser);
    } catch (e) {
      _logger.e('Erreur lors de la mise à jour du profil: $e');
      rethrow;
    }
  }
  
  // Mettre à jour les données utilisateur
  Future<void> updateUserData(UserModel user) async {
    try {
      // Simuler un délai réseau
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Sauvegarder l'utilisateur mis à jour
      await _saveUserToDatabase(user);
      
      // Mettre à jour l'utilisateur actuel si c'est le même
      if (_currentUser != null && _currentUser!.uid == user.uid) {
        _currentUser = user;
        _authStateController.add(_currentUser);
        
        // Sauvegarder l'utilisateur actuel
        await _saveCurrentUser(user);
      }
    } catch (e) {
      _logger.e('Erreur lors de la mise à jour des données utilisateur: $e');
      rethrow;
    }
  }
  
  // Vérifier si un utilisateur existe
  Future<bool> userExists(String email) async {
    try {
      // Simuler un délai réseau
      await Future.delayed(const Duration(milliseconds: 500));
      
      final user = await _getUserFromDatabase(email);
      return user != null;
    } catch (e) {
      _logger.e('Erreur lors de la vérification de l\'existence de l\'utilisateur: $e');
      return false;
    }
  }
  
  // Fermer le service
  void dispose() {
    _authStateController.close();
  }
}
