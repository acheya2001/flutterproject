import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:constat_tunisie/core/enums/user_role.dart';
import 'package:constat_tunisie/data/models/user_model.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();
  final Connectivity _connectivity = Connectivity();

  // Obtenir l'utilisateur actuel
  User? get currentUser => _auth.currentUser;
  
  // Stream pour suivre les changements d'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Vérifier si l'email est vérifié
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Vérifier la connectivité
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      _logger.e('Erreur lors de la vérification de la connectivité: $e');
      // En cas d'erreur, supposer que la connexion est disponible
      return true;
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
      // Vérifier la connectivité
      final isConnected = await checkConnectivity();
      if (!isConnected) {
        throw Exception('Pas de connexion Internet. Veuillez vérifier votre connexion et réessayer.');
      }
      
      // Créer l'utilisateur dans Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user!;
      
      // Envoyer un email de vérification
      await user.sendEmailVerification();
      
      // Mettre à jour le profil utilisateur
      await user.updateDisplayName(displayName);
      
      // Créer le document utilisateur dans Firestore
      final userModel = UserModel(
        uid: user.uid,
        email: email,
        displayName: displayName,
        phoneNumber: phoneNumber,
        role: role,
        createdAt: DateTime.now(),
        emailVerified: false,
      );
      
      await _firestore.collection('users').doc(user.uid).set(userModel.toFirestore());
      
      return userModel;
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
      // Vérifier la connectivité
      final isConnected = await checkConnectivity();
      if (!isConnected) {
        throw Exception('Pas de connexion Internet. Veuillez vérifier votre connexion et réessayer.');
      }
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user!;
      
      // Récupérer les données utilisateur depuis Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        // Si l'utilisateur n'existe pas dans Firestore, créer un document par défaut
        final defaultUserModel = UserModel(
          uid: user.uid,
          email: user.email!,
          displayName: user.displayName,
          role: UserRole.driver, // Rôle par défaut
          createdAt: DateTime.now(),
          emailVerified: user.emailVerified,
        );
        
        await _firestore.collection('users').doc(user.uid).set(defaultUserModel.toFirestore());
        
        return defaultUserModel;
      }
      
      // Convertir le document en UserModel
      final userModel = UserModel.fromFirestore(userDoc);
      
      // Mettre à jour le statut de vérification de l'email et la date de dernière connexion
      await _firestore.collection('users').doc(user.uid).update({
        'lastLoginAt': Timestamp.now(),
        'emailVerified': user.emailVerified,
      });
      
      return userModel.copyWith(
        lastLoginAt: DateTime.now(),
        emailVerified: user.emailVerified,
      );
    } catch (e) {
      _logger.e('Erreur lors de la connexion: $e');
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

  // Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    try {
      // Vérifier la connectivité
      final isConnected = await checkConnectivity();
      if (!isConnected) {
        throw Exception('Pas de connexion Internet. Veuillez vérifier votre connexion et réessayer.');
      }
      
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      _logger.e('Erreur lors de la réinitialisation du mot de passe: $e');
      rethrow;
    }
  }

  // Renvoyer l'email de vérification
  Future<void> sendEmailVerification() async {
    try {
      // Vérifier la connectivité
      final isConnected = await checkConnectivity();
      if (!isConnected) {
        throw Exception('Pas de connexion Internet. Veuillez vérifier votre connexion et réessayer.');
      }
      
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      _logger.e('Erreur lors de l\'envoi de l\'email de vérification: $e');
      rethrow;
    }
  }

  // Obtenir les données utilisateur depuis Firestore
  Future<UserModel?> getUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;
      
      return UserModel.fromFirestore(doc);
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
      final user = _auth.currentUser;
      if (user == null) return;
      
      // Mettre à jour dans Firebase Auth
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
      
      // Mettre à jour dans Firestore
      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (photoURL != null) updates['photoURL'] = photoURL;
      
      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update(updates);
      }
    } catch (e) {
      _logger.e('Erreur lors de la mise à jour du profil: $e');
      rethrow;
    }
  }

  // Mettre à jour les données utilisateur
  Future<void> updateUserData(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update(user.toFirestore());
    } catch (e) {
      _logger.e('Erreur lors de la mise à jour des données utilisateur: $e');
      rethrow;
    }
  }

  // Vérifier si un utilisateur existe
  Future<bool> userExists(String email) async {
    try {
      final result = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      return result.docs.isNotEmpty;
    } catch (e) {
      _logger.e('Erreur lors de la vérification de l\'existence de l\'utilisateur: $e');
      return false;
    }
  }
}
