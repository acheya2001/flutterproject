import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/firebase_service.dart';
import '../../../core/constants/app_constants.dart';

/// 🔐 Mode Super Admin Global
class SuperAdminMode {
  static bool _isActive = false;

  static bool get isActive => _isActive;

  static void activate() {
    _isActive = true;
    debugPrint('[SUPER_ADMIN_MODE] 🔐 Mode Super Admin ACTIVÉ');
  }

  static void deactivate() {
    _isActive = false;
    debugPrint('[SUPER_ADMIN_MODE] 🔓 Mode Super Admin DÉSACTIVÉ');
  }
}

/// 🔐 Service Super Admin Simplifié (sans UserModel)
class SimpleSuperAdmin {
  static final FirebaseAuth _auth = FirebaseService.auth;
  static final FirebaseFirestore _firestore = FirebaseService.firestore;

  /// 📧 Informations du Super Admin
  static const String SUPER_ADMIN_EMAIL = 'constat.tunisie.app@gmail.com';
  static const String SUPER_ADMIN_PASSWORD = 'Acheya123';

  /// 🆕 Créer le Super Admin avec structure simple
  static Future<void> createSuperAdmin() async {
    try {
      debugPrint('[SIMPLE_SUPER_ADMIN] 🔐 Vérification du Super Admin...');

      // Essayer de se connecter pour vérifier si le compte existe
      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: SUPER_ADMIN_EMAIL,
          password: SUPER_ADMIN_PASSWORD,
        );

        debugPrint('[SIMPLE_SUPER_ADMIN] ✅ Super Admin existe déjà et fonctionne !');
        debugPrint('[SIMPLE_SUPER_ADMIN] 🆔 UID: ${userCredential.user!.uid}');
        debugPrint('[SIMPLE_SUPER_ADMIN] 📧 Email: $SUPER_ADMIN_EMAIL');

        await _auth.signOut(); // Se déconnecter immédiatement
        return;

      } catch (e) {
        debugPrint('[SIMPLE_SUPER_ADMIN] ⚠️ Compte n\'existe pas, création...');

        // Créer le compte seulement s'il n'existe pas
        try {
          final userCredential = await _auth.createUserWithEmailAndPassword(
            email: SUPER_ADMIN_EMAIL,
            password: SUPER_ADMIN_PASSWORD,
          );

          debugPrint('[SIMPLE_SUPER_ADMIN] ✅ Nouveau Super Admin créé !');
          debugPrint('[SIMPLE_SUPER_ADMIN] 🆔 UID: ${userCredential.user!.uid}');

          await _auth.signOut(); // Se déconnecter immédiatement

        } catch (createError) {
          debugPrint('[SIMPLE_SUPER_ADMIN] ❌ Erreur création: $createError');
          // Si l'erreur est "email-already-in-use", c'est OK
          if (createError.toString().contains('email-already-in-use')) {
            debugPrint('[SIMPLE_SUPER_ADMIN] ✅ Compte existe déjà (normal)');
            return;
          }
          rethrow;
        }
      }

    } catch (e) {
      debugPrint('[SIMPLE_SUPER_ADMIN] ❌ Erreur lors de la création: $e');
      rethrow;
    }
  }

  /// 🧹 Nettoyer l'état Firebase Auth
  static Future<void> cleanFirebaseAuthState() async {
    try {
      debugPrint('[SIMPLE_SUPER_ADMIN] 🧹 Nettoyage état Firebase Auth...');

      // Se déconnecter complètement
      await _auth.signOut();

      // Attendre que l'état soit nettoyé
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint('[SIMPLE_SUPER_ADMIN] ✅ État Firebase Auth nettoyé');
    } catch (e) {
      debugPrint('[SIMPLE_SUPER_ADMIN] ⚠️ Erreur nettoyage: $e');
    }
  }

  /// 🔐 Connexion Super Admin avec Nettoyage
  static Future<UserCredential?> signInSuperAdmin({
    String? email,
    String? password,
  }) async {
    try {
      debugPrint('[SIMPLE_SUPER_ADMIN] 🔐 === DÉBUT CONNEXION ===');
      debugPrint('[SIMPLE_SUPER_ADMIN] 📧 Email: ${email ?? SUPER_ADMIN_EMAIL}');
      debugPrint('[SIMPLE_SUPER_ADMIN] 🔑 Password: ${password != null ? '***' : 'DEFAULT'}');

      // NETTOYER L'ÉTAT FIREBASE AUTH D'ABORD
      await cleanFirebaseAuthState();

      // ACTIVER LE MODE SUPER ADMIN AVANT LA CONNEXION
      SuperAdminMode.activate();

      debugPrint('[SIMPLE_SUPER_ADMIN] 🔥 Appel Firebase Auth...');

      // Essayer avec un délai pour éviter les problèmes de timing
      await Future.delayed(const Duration(milliseconds: 100));

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email ?? SUPER_ADMIN_EMAIL,
        password: password ?? SUPER_ADMIN_PASSWORD,
      );

      debugPrint('[SIMPLE_SUPER_ADMIN] ✅ Firebase Auth réussi !');
      debugPrint('[SIMPLE_SUPER_ADMIN] 🆔 UID: ${userCredential.user!.uid}');
      debugPrint('[SIMPLE_SUPER_ADMIN] 📧 Email: ${userCredential.user!.email}');
      debugPrint('[SIMPLE_SUPER_ADMIN] 🕐 Créé: ${userCredential.user!.metadata.creationTime}');

      debugPrint('[SIMPLE_SUPER_ADMIN] 🎯 Retour UserCredential...');
      return userCredential;

    } catch (e, stackTrace) {
      debugPrint('[SIMPLE_SUPER_ADMIN] ❌ ERREUR DÉTAILLÉE: $e');
      debugPrint('[SIMPLE_SUPER_ADMIN] 📍 STACK TRACE: $stackTrace');
      SuperAdminMode.deactivate(); // Désactiver en cas d'erreur

      // Si c'est l'erreur PigeonUserDetails, essayer une approche alternative
      if (e.toString().contains('PigeonUserDetails')) {
        debugPrint('[SIMPLE_SUPER_ADMIN] 🔄 Tentative de récupération...');
        return await _attemptRecovery(email, password);
      }

      rethrow;
    }
  }

  /// 🔄 Tentative de récupération après erreur PigeonUserDetails
  static Future<UserCredential?> _attemptRecovery(String? email, String? password) async {
    try {
      debugPrint('[SIMPLE_SUPER_ADMIN] 🔄 === TENTATIVE DE RÉCUPÉRATION ===');

      // Attendre plus longtemps
      await Future.delayed(const Duration(seconds: 2));

      // Vérifier si l'utilisateur est déjà connecté
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.email == (email ?? SUPER_ADMIN_EMAIL)) {
        debugPrint('[SIMPLE_SUPER_ADMIN] ✅ Utilisateur déjà connecté après erreur');

        // Retourner null et gérer dans le provider
        debugPrint('[SIMPLE_SUPER_ADMIN] ⚠️ Impossible de créer UserCredential, mais utilisateur connecté');
        return null;
      }

      debugPrint('[SIMPLE_SUPER_ADMIN] ❌ Récupération échouée');
      return null;

    } catch (e) {
      debugPrint('[SIMPLE_SUPER_ADMIN] ❌ Erreur récupération: $e');
      return null;
    }
  }

  /// 📊 Obtenir les informations du Super Admin (format simple)
  static Future<Map<String, dynamic>?> getSuperAdminInfo() async {
    try {
      // Retourner des données statiques pour éviter les problèmes de sérialisation
      final user = _auth.currentUser;

      if (user != null && user.email == SUPER_ADMIN_EMAIL) {
        return {
          'id': user.uid,
          'email': SUPER_ADMIN_EMAIL,
          'firstName': 'Super',
          'lastName': 'Admin',
          'phone': '+216 70 000 000',
          'role': 'super_admin',
          'status': 'active',
          'createdBy': 'SYSTEM',
          'cin': 'SUPER_ADMIN',
          'address': 'Tunis, Tunisie',
        };
      }
      return null;
    } catch (e) {
      debugPrint('[SIMPLE_SUPER_ADMIN] Erreur lors de la récupération: $e');
      return null;
    }
  }

  /// 🔍 Vérifier si un utilisateur est Super Admin (simplifié)
  static Future<bool> isSuperAdmin(String userId) async {
    try {
      final user = _auth.currentUser;
      // Vérification simple basée sur l'email
      return user != null && user.email == SUPER_ADMIN_EMAIL && user.uid == userId;
    } catch (e) {
      debugPrint('[SIMPLE_SUPER_ADMIN] Erreur lors de la vérification: $e');
      return false;
    }
  }

  /// 🧹 Supprimer tous les Super Admins existants
  static Future<void> deleteAllSuperAdmins() async {
    try {
      debugPrint('[SIMPLE_SUPER_ADMIN] 🗑️ Suppression des Super Admins...');

      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: 'super_admin')
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
        debugPrint('[SIMPLE_SUPER_ADMIN] 🗑️ Supprimé: ${doc.id}');
      }

      debugPrint('[SIMPLE_SUPER_ADMIN] ✅ ${snapshot.docs.length} Super Admin(s) supprimé(s)');
    } catch (e) {
      debugPrint('[SIMPLE_SUPER_ADMIN] ❌ Erreur lors de la suppression: $e');
    }
  }

  /// 🧹 Nettoyer le compte existant
  static Future<void> cleanExistingAccount() async {
    try {
      debugPrint('[SIMPLE_SUPER_ADMIN] 🧹 Nettoyage du compte existant...');

      // Se connecter pour supprimer le compte
      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: SUPER_ADMIN_EMAIL,
          password: SUPER_ADMIN_PASSWORD,
        );

        // Supprimer le document Firestore
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userCredential.user!.uid)
            .delete();

        // Supprimer le compte Auth
        await userCredential.user!.delete();

        debugPrint('[SIMPLE_SUPER_ADMIN] ✅ Compte existant supprimé');
      } catch (e) {
        debugPrint('[SIMPLE_SUPER_ADMIN] ⚠️ Pas de compte existant à supprimer: $e');
      }

    } catch (e) {
      debugPrint('[SIMPLE_SUPER_ADMIN] ❌ Erreur lors du nettoyage: $e');
    }
  }

  /// 🔄 Reset complet : supprimer et recréer
  static Future<void> resetSuperAdmin() async {
    try {
      debugPrint('[SIMPLE_SUPER_ADMIN] 🔄 Reset complet du Super Admin...');

      // 1. Nettoyer le compte existant
      await cleanExistingAccount();

      // 2. Attendre un peu
      await Future.delayed(const Duration(seconds: 1));

      // 3. Créer un nouveau Super Admin
      await createSuperAdmin();

      debugPrint('[SIMPLE_SUPER_ADMIN] ✅ Reset terminé !');
    } catch (e) {
      debugPrint('[SIMPLE_SUPER_ADMIN] ❌ Erreur lors du reset: $e');
      rethrow;
    }
  }

  /// 🧪 Tester la connexion
  static Future<void> testConnection() async {
    try {
      debugPrint('[SIMPLE_SUPER_ADMIN] 🧪 Test de connexion...');

      final userCredential = await signInSuperAdmin();
      
      if (userCredential != null) {
        debugPrint('[SIMPLE_SUPER_ADMIN] ✅ Test réussi !');
        await _auth.signOut();
      }
    } catch (e) {
      debugPrint('[SIMPLE_SUPER_ADMIN] ❌ Test échoué: $e');
    }
  }

  /// 📋 Afficher les informations
  static Future<void> showInfo() async {
    try {
      final info = await getSuperAdminInfo();
      
      if (info != null) {
        debugPrint('[SIMPLE_SUPER_ADMIN] ✅ Super Admin trouvé:');
        debugPrint('[SIMPLE_SUPER_ADMIN] 📧 Email: ${info['email']}');
        debugPrint('[SIMPLE_SUPER_ADMIN] 👤 Nom: ${info['firstName']} ${info['lastName']}');
        debugPrint('[SIMPLE_SUPER_ADMIN] 🆔 ID: ${info['id']}');
        debugPrint('[SIMPLE_SUPER_ADMIN] 🎭 Rôle: ${info['role']}');
      } else {
        debugPrint('[SIMPLE_SUPER_ADMIN] ❌ Aucun Super Admin trouvé');
      }
    } catch (e) {
      debugPrint('[SIMPLE_SUPER_ADMIN] ❌ Erreur: $e');
    }
  }
}
