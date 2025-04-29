import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:constat_tunisie/core/enums/user_role.dart';
import 'package:constat_tunisie/data/models/user_model.dart';
import 'package:constat_tunisie/data/services/auth_service.dart';
import 'package:logger/logger.dart';

class AuthRepository {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  // Obtenir l'utilisateur actuel
  User? get currentUser => _auth.currentUser;
  
  // Stream pour suivre les changements d'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Vérifier si l'email est vérifié
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Inscription avec email et mot de passe
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? phoneNumber,
  }) async {
    try {
      return await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
        phoneNumber: phoneNumber,
      );
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
      return await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      _logger.e('Erreur lors de la connexion: $e');
      rethrow;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await _authService.signOut();
  }

  // Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }

  // Renvoyer l'email de vérification
  Future<void> sendEmailVerification() async {
    await _authService.sendEmailVerification();
  }

  // Obtenir les données utilisateur depuis Firestore
  Future<UserModel?> getUserData() async {
    return await _authService.getUserData();
  }

  // Mettre à jour le profil utilisateur
  Future<void> updateUserProfile({
    String? displayName,
    String? phoneNumber,
    String? photoURL,
  }) async {
    await _authService.updateUserProfile(
      displayName: displayName,
      phoneNumber: phoneNumber,
      photoURL: photoURL,
    );
  }

  // Vérifier si un utilisateur existe
  Future<bool> userExists(String email) async {
    return await _authService.userExists(email);
  }

  // Vérifier la connectivité
  Future<bool> checkConnectivity() async {
    return await _authService.checkConnectivity();
  }
}