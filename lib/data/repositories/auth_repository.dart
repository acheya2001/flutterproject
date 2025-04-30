import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:constat_tunisie/data/enums/user_role.dart';
import 'package:constat_tunisie/data/models/user_model.dart';
import 'package:constat_tunisie/data/services/auth_service.dart';
import 'package:logger/logger.dart';

class AuthRepository {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
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
      // Créer les données de profil en fonction du rôle
      final Map<String, dynamic> profileData = _createProfileData(role);
      
      // Appeler le service d'authentification
      final userCredential = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
        role: role.name, // Utiliser le nom de l'énumération
        phoneNumber: phoneNumber ?? '', // Fournir une valeur par défaut
        profileData: profileData,
      );
      
      // Convertir UserCredential en UserModel
      return await _getUserModelFromCredential(userCredential);
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
      // Appeler le service d'authentification
      final userCredential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Convertir UserCredential en UserModel
      return await _getUserModelFromCredential(userCredential);
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
    if (_auth.currentUser != null) {
      await _auth.currentUser!.sendEmailVerification();
    }
  }

  // Obtenir les données utilisateur depuis Firestore
  Future<UserModel?> getUserData() async {
    try {
      if (_auth.currentUser == null) {
        return null;
      }
      
      final uid = _auth.currentUser!.uid;
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      
      if (!userData.exists || userData.data() == null) {
        return null;
      }
      
      return UserModel.fromFirestore(userData);
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
      if (user == null) {
        throw Exception('Aucun utilisateur connecté');
      }
      
      // Mettre à jour le profil Firebase Auth
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
      
      // Mettre à jour les données Firestore
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      
      Map<String, dynamic> updateData = {};
      if (displayName != null) updateData['displayName'] = displayName;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (photoURL != null) updateData['photoURL'] = photoURL;
      
      if (updateData.isNotEmpty) {
        updateData['updatedAt'] = FieldValue.serverTimestamp();
        await userRef.update(updateData);
      }
    } catch (e) {
      _logger.e('Erreur lors de la mise à jour du profil: $e');
      rethrow;
    }
  }

  // Vérifier si un utilisateur existe
  Future<bool> userExists(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      _logger.e('Erreur lors de la vérification de l\'existence de l\'utilisateur: $e');
      return false;
    }
  }

  // Vérifier la connectivité
  Future<bool> checkConnectivity() async {
    // Vous pouvez implémenter cette méthode avec le package connectivity_plus
    // Pour l'instant, nous retournons simplement true
    return true;
  }

  // Méthode utilitaire pour créer les données de profil
  Map<String, dynamic> _createProfileData(UserRole role) {
    final Map<String, dynamic> profileData = {
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };
    
    switch (role) {
      case UserRole.driver:
        profileData['vehicleInfo'] = {};
        profileData['licenseInfo'] = {};
        break;
      case UserRole.insurance:
        profileData['companyName'] = '';
        profileData['registrationNumber'] = '';
        break;
      case UserRole.expert:
        profileData['specialization'] = '';
        profileData['certifications'] = [];
        break;
      case UserRole.admin:
        profileData['adminLevel'] = 'standard';
        break;
    }
    
    return profileData;
  }

  // Méthode utilitaire pour convertir UserCredential en UserModel
  Future<UserModel> _getUserModelFromCredential(UserCredential credential) async {
    final user = credential.user;
    if (user == null) {
      throw Exception('Échec de l\'authentification: aucun utilisateur retourné');
    }
    
    // Récupérer les données utilisateur depuis Firestore
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    
    if (userData.exists && userData.data() != null) {
      return UserModel.fromFirestore(userData);
    }
    
    // Si les données n'existent pas encore, créer un modèle par défaut
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      role: UserRole.driver, // Rôle par défaut
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      emailVerified: user.emailVerified,
      profileData: {},
    );
  }
}