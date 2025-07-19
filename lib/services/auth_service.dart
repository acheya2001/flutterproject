import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 🔐 Service d'authentification Firebase
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🚀 Initialiser un super admin par défaut (pour les tests)
  static Future<void> initializeSuperAdmin() async {
    try {
      const superAdminEmail = 'constat.tunisie.app@gmail.com';
      const superAdminPassword = 'Acheya123';

      // Vérifier si le super admin existe déjà
      final existingUsers = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'super_admin')
          .get();

      if (existingUsers.docs.isEmpty) {
        debugPrint('[AUTH_SERVICE] 🔧 Création du super admin par défaut...');

        // Créer le compte Firebase Auth
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: superAdminEmail,
          password: superAdminPassword,
        );

        if (userCredential.user != null) {
          // Créer le profil dans Firestore
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'uid': userCredential.user!.uid,
            'email': superAdminEmail,
            'role': 'super_admin',
            'firstName': 'Super',
            'lastName': 'Admin',
            'status': 'active',
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': 'system',
            'permissions': [
              'create_companies',
              'manage_users',
              'view_all_data',
              'system_admin',
            ],
          });

          debugPrint('[AUTH_SERVICE] ✅ Super admin créé avec succès');
          debugPrint('[AUTH_SERVICE] 📧 Email: $superAdminEmail');
          debugPrint('[AUTH_SERVICE] 🔑 Mot de passe: $superAdminPassword');
        }
      } else {
        debugPrint('[AUTH_SERVICE] ℹ️ Super admin déjà existant');
      }
    } catch (e) {
      debugPrint('[AUTH_SERVICE] ❌ Erreur lors de l\'initialisation du super admin: $e');
    }
  }

  /// 🔐 Connexion utilisateur
  static Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AUTH_SERVICE] ❌ Erreur de connexion: ${e.code}');
      rethrow;
    }
  }

  /// 👤 Obtenir le profil utilisateur
  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('[AUTH_SERVICE] ❌ Erreur lors de la récupération du profil: $e');
      return null;
    }
  }

  /// 🚪 Déconnexion
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// 👥 Créer un utilisateur avec rôle
  static Future<String?> createUserWithRole({
    required String email,
    required String password,
    required String role,
    required String firstName,
    required String lastName,
    String? compagnieId,
    String? agenceId,
  }) async {
    try {
      // Créer le compte Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Créer le profil dans Firestore
        final userData = {
          'uid': userCredential.user!.uid,
          'email': email,
          'role': role,
          'firstName': firstName,
          'lastName': lastName,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': _auth.currentUser?.uid ?? 'system',
        };

        // Ajouter les IDs de compagnie/agence si fournis
        if (compagnieId != null) userData['compagnieId'] = compagnieId;
        if (agenceId != null) userData['agenceId'] = agenceId;

        await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);

        debugPrint('[AUTH_SERVICE] ✅ Utilisateur créé: $email ($role)');
        return userCredential.user!.uid;
      }
    } catch (e) {
      debugPrint('[AUTH_SERVICE] ❌ Erreur lors de la création de l\'utilisateur: $e');
      rethrow;
    }
    return null;
  }

  /// 🏢 Créer une compagnie d'assurance
  static Future<String?> createCompany({
    required String nom,
    required String adresse,
    required String telephone,
    required String email,
  }) async {
    try {
      // Générer un ID unique pour la compagnie
      final compagnieRef = _firestore.collection('compagnies').doc();
      
      await compagnieRef.set({
        'id': compagnieRef.id,
        'nom': nom,
        'adresse': adresse,
        'telephone': telephone,
        'email': email,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser?.uid ?? 'system',
      });

      debugPrint('[AUTH_SERVICE] ✅ Compagnie créée: $nom');
      return compagnieRef.id;
    } catch (e) {
      debugPrint('[AUTH_SERVICE] ❌ Erreur lors de la création de la compagnie: $e');
      rethrow;
    }
  }

  /// 📊 Obtenir les statistiques
  static Future<Map<String, int>> getSystemStats() async {
    try {
      final compagniesSnapshot = await _firestore.collection('compagnies').get();
      final usersSnapshot = await _firestore.collection('users').get();
      final agencesSnapshot = await _firestore.collection('agences').get();

      return {
        'compagnies': compagniesSnapshot.docs.length,
        'users': usersSnapshot.docs.length,
        'agences': agencesSnapshot.docs.length,
        'agents': usersSnapshot.docs.where((doc) => doc.data()['role'] == 'agent_agence').length,
        'experts': usersSnapshot.docs.where((doc) => doc.data()['role'] == 'expert_auto').length,
        'conducteurs': usersSnapshot.docs.where((doc) => doc.data()['role'] == 'conducteur').length,
        'admin_compagnie': usersSnapshot.docs.where((doc) => doc.data()['role'] == 'admin_compagnie').length,
        'admin_agence': usersSnapshot.docs.where((doc) => doc.data()['role'] == 'admin_agence').length,
      };
    } catch (e) {
      debugPrint('[AUTH_SERVICE] ❌ Erreur lors de la récupération des statistiques: $e');
      return {};
    }
  }

  /// 🔍 Vérifier les permissions utilisateur
  static Future<bool> hasPermission(String permission) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final role = userData['role'] as String?;
      final permissions = userData['permissions'] as List<dynamic>?;

      // Super admin a toutes les permissions
      if (role == 'super_admin') return true;

      // Vérifier les permissions spécifiques
      return permissions?.contains(permission) ?? false;
    } catch (e) {
      debugPrint('[AUTH_SERVICE] ❌ Erreur lors de la vérification des permissions: $e');
      return false;
    }
  }
}
