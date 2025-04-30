import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  // Obtenir l'utilisateur actuel
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Obtenir les données utilisateur depuis Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      _logger.e('Erreur lors de la récupération des données utilisateur: $e');
      rethrow;
    }
  }

  // Vérifier la connectivité avant les opérations d'authentification
  Future<bool> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Inscription avec email et mot de passe
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required String phoneNumber,
    required String role,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      // Vérifier la connectivité
      if (!await _checkConnectivity()) {
        throw FirebaseAuthException(
          code: 'network-error',
          message: 'Pas de connexion Internet. Veuillez vérifier votre connexion et réessayer.',
        );
      }
      
      // Créer l'utilisateur dans Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Mettre à jour le profil de l'utilisateur
      await userCredential.user?.updateDisplayName(displayName);
      
      // Créer le document utilisateur dans Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'displayName': displayName,
        'phoneNumber': phoneNumber,
        'role': role,
        'profileData': profileData,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _logger.e('Erreur d\'authentification: ${e.code} - ${e.message}');
      
      // Traduire les messages d'erreur courants
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Cette adresse email est déjà utilisée par un autre compte.';
          break;
        case 'invalid-email':
          message = 'L\'adresse email n\'est pas valide.';
          break;
        case 'operation-not-allowed':
          message = 'L\'inscription par email et mot de passe n\'est pas activée.';
          break;
        case 'weak-password':
          message = 'Le mot de passe est trop faible. Utilisez au moins 6 caractères.';
          break;
        case 'network-error':
          message = e.message ?? 'Erreur de connexion réseau.';
          break;
        default:
          message = e.message ?? 'Une erreur inconnue s\'est produite.';
      }
      
      throw FirebaseAuthException(
        code: e.code,
        message: message,
      );
    } catch (e) {
      _logger.e('Erreur inattendue lors de l\'inscription: $e');
      throw Exception('Une erreur inattendue s\'est produite. Veuillez réessayer.');
    }
  }

  // Connexion avec email et mot de passe
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Vérifier la connectivité
      if (!await _checkConnectivity()) {
        throw FirebaseAuthException(
          code: 'network-error',
          message: 'Pas de connexion Internet. Veuillez vérifier votre connexion et réessayer.',
        );
      }
      
      // Connexion à Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Mettre à jour la date de dernière connexion
      await _firestore.collection('users').doc(userCredential.user!.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _logger.e('Erreur de connexion: ${e.code} - ${e.message}');
      
      // Traduire les messages d'erreur courants
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Aucun utilisateur trouvé avec cette adresse email.';
          break;
        case 'wrong-password':
          message = 'Mot de passe incorrect.';
          break;
        case 'invalid-email':
          message = 'L\'adresse email n\'est pas valide.';
          break;
        case 'user-disabled':
          message = 'Ce compte a été désactivé.';
          break;
        case 'network-error':
          message = e.message ?? 'Erreur de connexion réseau.';
          break;
        default:
          message = e.message ?? 'Une erreur inconnue s\'est produite.';
      }
      
      throw FirebaseAuthException(
        code: e.code,
        message: message,
      );
    } catch (e) {
      _logger.e('Erreur inattendue lors de la connexion: $e');
      throw Exception('Une erreur inattendue s\'est produite. Veuillez réessayer.');
    }
  }

  // Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      _logger.e('Erreur lors de la réinitialisation du mot de passe: $e');
      rethrow;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      _logger.e('Erreur lors de la déconnexion: $e');
      rethrow;
    }
  }

  // Mettre à jour les données utilisateur
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      _logger.e('Erreur lors de la mise à jour des données utilisateur: $e');
      rethrow;
    }
  }

  // Mettre à jour le mot de passe
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw Exception('Aucun utilisateur connecté');
      }
    } catch (e) {
      _logger.e('Erreur lors de la mise à jour du mot de passe: $e');
      rethrow;
    }
  }
}