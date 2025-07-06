import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/firebase_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/enums/app_enums.dart';
import '../../../shared/models/user_model.dart';

/// 🔐 Service pour créer et gérer le Super Admin
class SuperAdminSetup {
  static final FirebaseAuth _auth = FirebaseService.auth;
  static final FirebaseFirestore _firestore = FirebaseService.firestore;

  /// 🔐 Informations du Super Admin
  static const String SUPER_ADMIN_EMAIL = 'constat.tunisie.app@gmail.com';
  static const String SUPER_ADMIN_PASSWORD = 'Acheya123'; // Mot de passe sécurisé
  static const String SUPER_ADMIN_FIRST_NAME = 'Super';
  static const String SUPER_ADMIN_LAST_NAME = 'Admin';
  static const String SUPER_ADMIN_PHONE = '+216 70 000 000';

  /// 🚀 Créer le compte Super Admin (à exécuter une seule fois)
  static Future<void> createSuperAdmin() async {
    try {
      debugPrint('[SUPER_ADMIN_SETUP] 🔐 Création du Super Admin...');

      // Vérifier si le Super Admin existe déjà
      final existingUser = await _firestore
          .collection(AppConstants.usersCollection)
          .where('email', isEqualTo: SUPER_ADMIN_EMAIL)
          .where('role', isEqualTo: UserRole.superAdmin.name)
          .get();

      if (existingUser.docs.isNotEmpty) {
        debugPrint('[SUPER_ADMIN_SETUP] ✅ Super Admin existe déjà');
        return;
      }

      // Créer le compte dans Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: SUPER_ADMIN_EMAIL,
        password: SUPER_ADMIN_PASSWORD,
      );

      final userId = userCredential.user!.uid;

      // Créer le modèle utilisateur Super Admin
      final superAdminModel = UserModel(
        id: userId,
        email: SUPER_ADMIN_EMAIL,
        firstName: SUPER_ADMIN_FIRST_NAME,
        lastName: SUPER_ADMIN_LAST_NAME,
        phone: SUPER_ADMIN_PHONE,
        role: UserRole.superAdmin,
        status: AccountStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'SYSTEM', // Créé par le système
        cin: 'SUPER_ADMIN',
        address: 'Tunis, Tunisie',
        permissions: [], // Permissions vides pour éviter les erreurs
      );

      // Sauvegarder dans Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .set(superAdminModel.toFirestore());

      // Mettre à jour le profil Firebase Auth
      await userCredential.user!.updateDisplayName(
        '${SUPER_ADMIN_FIRST_NAME} ${SUPER_ADMIN_LAST_NAME}',
      );

      debugPrint('[SUPER_ADMIN_SETUP] ✅ Super Admin créé avec succès !');
      debugPrint('[SUPER_ADMIN_SETUP] 📧 Email: $SUPER_ADMIN_EMAIL');
      debugPrint('[SUPER_ADMIN_SETUP] 🔑 Mot de passe: $SUPER_ADMIN_PASSWORD');
      debugPrint('[SUPER_ADMIN_SETUP] 🆔 UID: $userId');

    } catch (e) {
      debugPrint('[SUPER_ADMIN_SETUP] ❌ Erreur lors de la création: $e');
      rethrow;
    }
  }

  /// 🔍 Vérifier si un utilisateur est Super Admin
  static Future<bool> isSuperAdmin(String userId) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;
      return userData['role'] == UserRole.superAdmin.name;
    } catch (e) {
      debugPrint('[SUPER_ADMIN_SETUP] Erreur lors de la vérification: $e');
      return false;
    }
  }

  /// 🔐 Connexion Super Admin
  static Future<UserCredential?> signInSuperAdmin({
    String? email,
    String? password,
  }) async {
    try {
      debugPrint('[SUPER_ADMIN_SETUP] 🔐 Tentative de connexion Super Admin...');

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email ?? SUPER_ADMIN_EMAIL,
        password: password ?? SUPER_ADMIN_PASSWORD,
      );

      // Vérifier que c'est bien un Super Admin
      final isSuperAdminUser = await isSuperAdmin(userCredential.user!.uid);
      
      if (!isSuperAdminUser) {
        await _auth.signOut();
        throw Exception('Accès refusé : Vous n\'êtes pas autorisé à accéder à cette interface');
      }

      debugPrint('[SUPER_ADMIN_SETUP] ✅ Connexion Super Admin réussie');
      return userCredential;

    } catch (e) {
      debugPrint('[SUPER_ADMIN_SETUP] ❌ Erreur de connexion: $e');
      rethrow;
    }
  }

  /// 🔄 Réinitialiser le mot de passe Super Admin
  static Future<void> resetSuperAdminPassword() async {
    try {
      await _auth.sendPasswordResetEmail(email: SUPER_ADMIN_EMAIL);
      debugPrint('[SUPER_ADMIN_SETUP] 📧 Email de réinitialisation envoyé');
    } catch (e) {
      debugPrint('[SUPER_ADMIN_SETUP] ❌ Erreur lors de la réinitialisation: $e');
      rethrow;
    }
  }

  /// 📊 Obtenir les informations du Super Admin
  static Future<UserModel?> getSuperAdminInfo() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: UserRole.superAdmin.name)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return UserModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('[SUPER_ADMIN_SETUP] Erreur lors de la récupération: $e');
      return null;
    }
  }

  /// 🧹 Supprimer le Super Admin (DANGER - à utiliser avec précaution)
  static Future<void> deleteSuperAdmin() async {
    try {
      debugPrint('[SUPER_ADMIN_SETUP] ⚠️ SUPPRESSION DU SUPER ADMIN...');

      // Récupérer le Super Admin
      final superAdmin = await getSuperAdminInfo();
      if (superAdmin == null) {
        debugPrint('[SUPER_ADMIN_SETUP] ❌ Super Admin introuvable');
        return;
      }

      // Supprimer de Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(superAdmin.id)
          .delete();

      // Supprimer de Firebase Auth (nécessite d'être connecté)
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == superAdmin.id) {
        await currentUser.delete();
      }

      debugPrint('[SUPER_ADMIN_SETUP] ✅ Super Admin supprimé');
    } catch (e) {
      debugPrint('[SUPER_ADMIN_SETUP] ❌ Erreur lors de la suppression: $e');
      rethrow;
    }
  }

  /// 🔧 Mettre à jour les informations du Super Admin
  static Future<void> updateSuperAdminInfo({
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
  }) async {
    try {
      final superAdmin = await getSuperAdminInfo();
      if (superAdmin == null) {
        throw Exception('Super Admin introuvable');
      }

      final updates = <String, dynamic>{};
      if (firstName != null) updates['firstName'] = firstName;
      if (lastName != null) updates['lastName'] = lastName;
      if (phone != null) updates['phone'] = phone;
      if (address != null) updates['address'] = address;
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(superAdmin.id)
          .update(updates);

      debugPrint('[SUPER_ADMIN_SETUP] ✅ Informations mises à jour');
    } catch (e) {
      debugPrint('[SUPER_ADMIN_SETUP] ❌ Erreur lors de la mise à jour: $e');
      rethrow;
    }
  }

  /// 📋 Lister tous les admins créés par le Super Admin
  static Future<List<UserModel>> getCreatedAdmins() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', whereIn: [
            UserRole.companyAdmin.name,
            UserRole.agencyAdmin.name,
          ])
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('[SUPER_ADMIN_SETUP] Erreur lors de la récupération des admins: $e');
      return [];
    }
  }

  /// 🔐 Changer le mot de passe du Super Admin
  static Future<void> changeSuperAdminPassword(String newPassword) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      // Vérifier que c'est le Super Admin
      final isSuperAdminUser = await isSuperAdmin(currentUser.uid);
      if (!isSuperAdminUser) {
        throw Exception('Seul le Super Admin peut changer son mot de passe');
      }

      await currentUser.updatePassword(newPassword);
      debugPrint('[SUPER_ADMIN_SETUP] ✅ Mot de passe mis à jour');
    } catch (e) {
      debugPrint('[SUPER_ADMIN_SETUP] ❌ Erreur lors du changement de mot de passe: $e');
      rethrow;
    }
  }
}
