import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/firebase_service.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/user_model.dart';

/// 🔐 Service d'authentification moderne
class AuthService {
  final FirebaseAuth _auth = FirebaseService.auth;
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  /// 🔑 Connexion avec email et mot de passe
  Future<AuthResult> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // Connexion Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure('Erreur de connexion');
      }

      // Récupération des données utilisateur
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(credential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        return AuthResult.failure('Compte utilisateur non trouvé');
      }

      final userData = userDoc.data()!;
      final userRole = UserRole.fromString(userData['role']);
      final accountStatus = AccountStatus.fromString(userData['status']);

      // Vérification du statut du compte
      if (accountStatus != AccountStatus.active) {
        await _auth.signOut();
        return AuthResult.failure(_getStatusMessage(accountStatus));
      }

      // Mise à jour de la dernière connexion
      await _updateLastLogin(credential.user!.uid);

      // Récupération des données spécialisées selon le rôle
      final specializedData = await _getSpecializedUserData(
        credential.user!.uid,
        userRole,
      );

      final userModel = UserModel.fromFirestore(userDoc);

      return AuthResult.success(
        user: userModel,
        specializedData: specializedData,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_handleAuthException(e));
    } catch (e) {
      return AuthResult.failure('Erreur de connexion: $e');
    }
  }

  /// 📝 Inscription d'un nouveau conducteur
  Future<AuthResult> registerDriver({
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
    try {
      // Vérification de l'unicité de l'email
      final existingUser = await _checkEmailExists(email);
      if (existingUser) {
        return AuthResult.failure('Un compte existe déjà avec cet email');
      }

      // Vérification de l'unicité du CIN
      final existingCin = await _checkCinExists(cin);
      if (existingCin) {
        return AuthResult.failure('Un compte existe déjà avec ce CIN');
      }

      // Création du compte Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure('Erreur lors de la création du compte');
      }

      final userId = credential.user!.uid;
      final now = DateTime.now();

      // Création du modèle utilisateur de base
      final userModel = UserModel(
        id: userId,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        role: UserRole.driver,
        status: AccountStatus.active,
        createdAt: now,
        updatedAt: now,
        createdBy: userId,
        address: address,
        cin: cin,
      );

      // Pour l'instant, on ne crée que le modèle utilisateur de base
      // TODO: Implémenter les modèles spécialisés plus tard

      // Sauvegarde en base de données
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .set(userModel.toFirestore());

      return AuthResult.success(
        user: userModel,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_handleAuthException(e));
    } catch (e) {
      return AuthResult.failure('Erreur lors de l\'inscription: $e');
    }
  }

  /// 👨‍💼 Demande d'inscription pour agent/expert
  Future<AuthResult> requestProfessionalAccount({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required UserRole role,
    required String companyId,
    String? agencyId,
    String? specialization,
    String? licenseNumber,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Vérification de l'unicité de l'email
      final existingUser = await _checkEmailExists(email);
      if (existingUser) {
        return AuthResult.failure('Un compte existe déjà avec cet email');
      }

      // Création du compte Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure('Erreur lors de la création du compte');
      }

      final userId = credential.user!.uid;
      final now = DateTime.now();

      // Création du modèle utilisateur avec statut en attente
      final userModel = UserModel(
        id: userId,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        role: role,
        status: AccountStatus.pending, // En attente de validation
        createdAt: now,
        updatedAt: now,
        createdBy: userId,
        metadata: {
          'companyId': companyId,
          if (agencyId != null) 'agencyId': agencyId,
          if (specialization != null) 'specialization': specialization,
          if (licenseNumber != null) 'licenseNumber': licenseNumber,
          ...?additionalData,
        },
      );

      // Sauvegarde en base de données
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .set(userModel.toFirestore());

      // Déconnexion automatique car le compte est en attente
      await _auth.signOut();

      return AuthResult.success(
        user: userModel,
        message: 'Votre demande a été soumise. Elle sera examinée par un administrateur.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_handleAuthException(e));
    } catch (e) {
      return AuthResult.failure('Erreur lors de la demande: $e');
    }
  }

  /// 🚪 Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// 🔄 Réinitialisation du mot de passe
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult.success(
        message: 'Un email de réinitialisation a été envoyé à $email',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_handleAuthException(e));
    } catch (e) {
      return AuthResult.failure('Erreur lors de la réinitialisation: $e');
    }
  }

  /// 👤 Récupération de l'utilisateur actuel
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return null;

      return UserModel.fromFirestore(userDoc);
    } catch (e) {
      return null;
    }
  }

  /// 🔍 Méthodes privées
  Future<bool> _checkEmailExists(String email) async {
    final query = await _firestore
        .collection(AppConstants.usersCollection)
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<bool> _checkCinExists(String cin) async {
    final query = await _firestore
        .collection(AppConstants.driversCollection)
        .where('cin', isEqualTo: cin)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<void> _updateLastLogin(String userId) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  Future<dynamic> _getSpecializedUserData(String userId, UserRole role) async {
    // Pour l'instant, on retourne null pour tous les rôles
    // TODO: Implémenter la récupération des données spécialisées plus tard
    return null;
  }

  String _getStatusMessage(AccountStatus status) {
    switch (status) {
      case AccountStatus.pending:
        return 'Votre compte est en attente de validation par un administrateur.';
      case AccountStatus.suspended:
        return 'Votre compte a été suspendu. Contactez l\'administrateur.';
      case AccountStatus.rejected:
        return 'Votre demande de compte a été rejetée.';
      case AccountStatus.expired:
        return 'Votre compte a expiré. Contactez l\'administrateur.';
      default:
        return 'Statut de compte non valide.';
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cet email.';
      case 'weak-password':
        return 'Le mot de passe est trop faible (minimum 8 caractères).';
      case 'invalid-email':
        return 'L\'adresse email n\'est pas valide.';
      case 'user-disabled':
        return 'Ce compte utilisateur a été désactivé.';
      case 'too-many-requests':
        return 'Trop de tentatives. Veuillez réessayer plus tard.';
      default:
        return 'Erreur d\'authentification: ${e.message}';
    }
  }
}

/// 📊 Résultat d'authentification
class AuthResult {
  final bool isSuccess;
  final String? message;
  final UserModel? user;
  final dynamic specializedData;

  AuthResult._({
    required this.isSuccess,
    this.message,
    this.user,
    this.specializedData,
  });

  factory AuthResult.success({
    UserModel? user,
    dynamic specializedData,
    String? message,
  }) {
    return AuthResult._(
      isSuccess: true,
      user: user,
      specializedData: specializedData,
      message: message,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(
      isSuccess: false,
      message: message,
    );
  }
}

// Provider défini dans auth_provider.dart
