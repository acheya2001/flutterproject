import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firebase_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/enums/app_enums.dart';
import '../../../shared/models/user_model.dart';

/// 🔧 Utilitaire pour corriger le Super Admin
class FixSuperAdmin {
  static final FirebaseAuth _auth = FirebaseService.auth;
  static final FirebaseFirestore _firestore = FirebaseService.firestore;

  /// 🧹 Supprimer et recréer le Super Admin
  static Future<void> fixSuperAdmin() async {
    try {
      debugPrint('[FIX_SUPER_ADMIN] 🔧 Correction du Super Admin...');

      // 1. Supprimer tous les Super Admins existants de Firestore
      await _deleteExistingSuperAdmins();

      // 2. Créer un nouveau Super Admin propre
      await _createCleanSuperAdmin();

      debugPrint('[FIX_SUPER_ADMIN] ✅ Super Admin corrigé avec succès !');
    } catch (e) {
      debugPrint('[FIX_SUPER_ADMIN] ❌ Erreur lors de la correction: $e');
      rethrow;
    }
  }

  /// 🗑️ Supprimer les Super Admins existants
  static Future<void> _deleteExistingSuperAdmins() async {
    try {
      debugPrint('[FIX_SUPER_ADMIN] 🗑️ Suppression des Super Admins existants...');

      // Chercher tous les Super Admins
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: UserRole.superAdmin.name)
          .get();

      // Supprimer chaque document
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
        debugPrint('[FIX_SUPER_ADMIN] 🗑️ Supprimé: ${doc.id}');
      }

      debugPrint('[FIX_SUPER_ADMIN] ✅ ${snapshot.docs.length} Super Admin(s) supprimé(s)');
    } catch (e) {
      debugPrint('[FIX_SUPER_ADMIN] ❌ Erreur lors de la suppression: $e');
    }
  }

  /// 🆕 Créer un Super Admin propre
  static Future<void> _createCleanSuperAdmin() async {
    try {
      debugPrint('[FIX_SUPER_ADMIN] 🆕 Création d\'un nouveau Super Admin...');

      const email = 'constat.tunisie.app@gmail.com';
      const password = 'Acheya123';

      // Créer le compte dans Firebase Auth
      UserCredential? userCredential;
      
      try {
        // Essayer de se connecter d'abord
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        debugPrint('[FIX_SUPER_ADMIN] 📧 Compte Auth existant trouvé');
      } catch (e) {
        // Si la connexion échoue, créer le compte
        try {
          userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          debugPrint('[FIX_SUPER_ADMIN] 📧 Nouveau compte Auth créé');
        } catch (createError) {
          debugPrint('[FIX_SUPER_ADMIN] ❌ Erreur création Auth: $createError');
          rethrow;
        }
      }

      if (userCredential?.user == null) {
        throw Exception('Impossible de créer ou récupérer le compte Auth');
      }

      final userId = userCredential!.user!.uid;

      // Créer le document Firestore avec des données propres
      final superAdminData = {
        'id': userId,
        'email': email,
        'firstName': 'Super',
        'lastName': 'Admin',
        'phone': '+216 70 000 000',
        'role': UserRole.superAdmin.name,
        'status': AccountStatus.active.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': 'SYSTEM',
        'cin': 'SUPER_ADMIN',
        'address': 'Tunis, Tunisie',
        'permissions': [], // Liste vide pour éviter les erreurs
        'metadata': <String, dynamic>{}, // Map vide
      };

      // Sauvegarder dans Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .set(superAdminData);

      // Mettre à jour le profil Firebase Auth
      await userCredential.user!.updateDisplayName('Super Admin');

      debugPrint('[FIX_SUPER_ADMIN] ✅ Super Admin créé avec l\'ID: $userId');
      debugPrint('[FIX_SUPER_ADMIN] 📧 Email: $email');
      debugPrint('[FIX_SUPER_ADMIN] 🔑 Mot de passe: $password');

      // Se déconnecter après la création
      await _auth.signOut();

    } catch (e) {
      debugPrint('[FIX_SUPER_ADMIN] ❌ Erreur lors de la création: $e');
      rethrow;
    }
  }

  /// 🔍 Vérifier le Super Admin
  static Future<void> checkSuperAdmin() async {
    try {
      debugPrint('[FIX_SUPER_ADMIN] 🔍 Vérification du Super Admin...');

      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: UserRole.superAdmin.name)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('[FIX_SUPER_ADMIN] ❌ Aucun Super Admin trouvé');
        return;
      }

      for (final doc in snapshot.docs) {
        final data = doc.data();
        debugPrint('[FIX_SUPER_ADMIN] ✅ Super Admin trouvé:');
        debugPrint('[FIX_SUPER_ADMIN] 🆔 ID: ${doc.id}');
        debugPrint('[FIX_SUPER_ADMIN] 📧 Email: ${data['email']}');
        debugPrint('[FIX_SUPER_ADMIN] 👤 Nom: ${data['firstName']} ${data['lastName']}');
        debugPrint('[FIX_SUPER_ADMIN] 🎭 Rôle: ${data['role']}');
        debugPrint('[FIX_SUPER_ADMIN] 📊 Statut: ${data['status']}');
      }
    } catch (e) {
      debugPrint('[FIX_SUPER_ADMIN] ❌ Erreur lors de la vérification: $e');
    }
  }

  /// 🧪 Tester la connexion
  static Future<void> testConnection() async {
    try {
      debugPrint('[FIX_SUPER_ADMIN] 🧪 Test de connexion...');

      const email = 'constat.tunisie.app@gmail.com';
      const password = 'Acheya123';

      // Tentative de connexion
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        debugPrint('[FIX_SUPER_ADMIN] ✅ Connexion Auth réussie');

        // Vérifier le document Firestore
        final doc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userCredential.user!.uid)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          debugPrint('[FIX_SUPER_ADMIN] ✅ Document Firestore trouvé');
          debugPrint('[FIX_SUPER_ADMIN] 🎭 Rôle: ${data['role']}');

          // Essayer de créer un UserModel
          try {
            final userModel = UserModel.fromFirestore(doc);
            debugPrint('[FIX_SUPER_ADMIN] ✅ UserModel créé avec succès');
            debugPrint('[FIX_SUPER_ADMIN] 👤 ${userModel.fullName}');
          } catch (e) {
            debugPrint('[FIX_SUPER_ADMIN] ❌ Erreur UserModel: $e');
          }
        } else {
          debugPrint('[FIX_SUPER_ADMIN] ❌ Document Firestore introuvable');
        }

        // Se déconnecter
        await _auth.signOut();
      }
    } catch (e) {
      debugPrint('[FIX_SUPER_ADMIN] ❌ Erreur de connexion: $e');
    }
  }
}
