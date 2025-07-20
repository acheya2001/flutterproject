import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;

/// 🔐 Service pour la gestion des Super Admins
class SuperAdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 👑 Créer un nouveau Super Admin
  static Future<Map<String, dynamic>> createSuperAdmin({
    required String email,
    required String nom,
    required String prenom,
    String? telephone,
    String? adresse,
    bool requirePasswordChange = true,
  }) async {
    try {
      debugPrint('[SUPER_ADMIN_SERVICE] 🔐 Création Super Admin: $email');

      // Vérifier que l'utilisateur actuel est bien un Super Admin
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!currentUserDoc.exists || 
          currentUserDoc.data()?['role'] != 'super_admin') {
        throw Exception('Seul un Super Admin peut créer d\'autres Super Admins');
      }

      // Vérifier que l'email n'existe pas déjà
      final existingUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (existingUser.docs.isNotEmpty) {
        throw Exception('Un utilisateur avec cet email existe déjà');
      }

      // Générer un mot de passe sécurisé
      final password = _generateSecurePassword();
      final userId = _generateUserId();

      // Créer le document utilisateur
      final userData = {
        'uid': userId,
        'email': email,
        'nom': nom,
        'prenom': prenom,
        'role': 'super_admin',
        'status': 'actif',
        'isActive': true,
        'isLegitimate': true,
        'isSuperAdmin': true,
        'permissions': [
          'create_super_admin',
          'create_admin_compagnie',
          'manage_all_companies',
          'manage_all_users',
          'system_administration',
          'security_management',
          'audit_access',
        ],
        'securityLevel': 'maximum',
        'requirePasswordChange': requirePasswordChange,
        'password': password, // Temporaire pour transmission
        'temporaryPassword': password,
        'telephone': telephone,
        'adresse': adresse,
        'createdBy': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'source': 'super_admin_creation',
        'accountType': 'super_admin_system',
        'lastLoginAt': null,
        'loginCount': 0,
        'twoFactorEnabled': false, // À activer après première connexion
        'securityQuestions': [], // À configurer après première connexion
      };

      // Sauvegarder dans Firestore
      await _firestore.collection('users').doc(userId).set(userData);

      // Log de sécurité
      await _logSecurityEvent(
        action: 'super_admin_created',
        targetUserId: userId,
        targetEmail: email,
        performedBy: currentUser.uid,
        details: {
          'nom': nom,
          'prenom': prenom,
          'email': email,
        },
      );

      debugPrint('[SUPER_ADMIN_SERVICE] ✅ Super Admin créé: $email');

      return {
        'success': true,
        'userId': userId,
        'email': email,
        'password': password,
        'message': 'Super Admin créé avec succès',
      };
    } catch (e) {
      debugPrint('[SUPER_ADMIN_SERVICE] ❌ Erreur création Super Admin: $e');
      
      // Log de sécurité pour tentative échouée
      await _logSecurityEvent(
        action: 'super_admin_creation_failed',
        targetEmail: email,
        performedBy: _auth.currentUser?.uid,
        details: {'error': e.toString()},
      );

      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 📊 Lister tous les Super Admins
  static Future<List<Map<String, dynamic>>> getAllSuperAdmins() async {
    try {
      final query = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'super_admin')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        // Ne pas exposer les mots de passe
        data.remove('password');
        data.remove('temporaryPassword');
        return data;
      }).toList();
    } catch (e) {
      debugPrint('[SUPER_ADMIN_SERVICE] ❌ Erreur liste Super Admins: $e');
      rethrow;
    }
  }

  /// 🔒 Désactiver un Super Admin
  static Future<void> deactivateSuperAdmin(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Vérifier qu'on ne se désactive pas soi-même
      if (currentUser.uid == userId) {
        throw Exception('Impossible de se désactiver soi-même');
      }

      // Vérifier qu'il reste au moins un Super Admin actif
      final activeSuperAdmins = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'super_admin')
          .where('status', isEqualTo: 'actif')
          .get();

      if (activeSuperAdmins.docs.length <= 1) {
        throw Exception('Impossible de désactiver le dernier Super Admin actif');
      }

      await _firestore.collection('users').doc(userId).update({
        'status': 'desactive',
        'isActive': false,
        'deactivatedBy': currentUser.uid,
        'deactivatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log de sécurité
      await _logSecurityEvent(
        action: 'super_admin_deactivated',
        targetUserId: userId,
        performedBy: currentUser.uid,
      );

      debugPrint('[SUPER_ADMIN_SERVICE] ✅ Super Admin désactivé: $userId');
    } catch (e) {
      debugPrint('[SUPER_ADMIN_SERVICE] ❌ Erreur désactivation: $e');
      rethrow;
    }
  }

  /// 🔓 Réactiver un Super Admin
  static Future<void> reactivateSuperAdmin(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      await _firestore.collection('users').doc(userId).update({
        'status': 'actif',
        'isActive': true,
        'reactivatedBy': currentUser.uid,
        'reactivatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log de sécurité
      await _logSecurityEvent(
        action: 'super_admin_reactivated',
        targetUserId: userId,
        performedBy: currentUser.uid,
      );

      debugPrint('[SUPER_ADMIN_SERVICE] ✅ Super Admin réactivé: $userId');
    } catch (e) {
      debugPrint('[SUPER_ADMIN_SERVICE] ❌ Erreur réactivation: $e');
      rethrow;
    }
  }

  /// 🔐 Générer un mot de passe sécurisé
  static String _generateSecurePassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    const specialChars = '!@#\$%^&*';
    const numbers = '0123456789';
    const upperCase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowerCase = 'abcdefghijklmnopqrstuvwxyz';
    
    final random = math.Random.secure();
    
    // Assurer au moins un caractère de chaque type
    String password = '';
    password += upperCase[random.nextInt(upperCase.length)];
    password += lowerCase[random.nextInt(lowerCase.length)];
    password += numbers[random.nextInt(numbers.length)];
    password += specialChars[random.nextInt(specialChars.length)];
    
    // Compléter avec des caractères aléatoires
    for (int i = 4; i < 16; i++) {
      password += chars[random.nextInt(chars.length)];
    }
    
    // Mélanger les caractères
    final passwordList = password.split('');
    passwordList.shuffle(random);
    
    return passwordList.join('');
  }

  /// 🆔 Générer un ID utilisateur unique
  static String _generateUserId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = math.Random().nextInt(999999);
    return 'super_admin_${timestamp}_$random';
  }

  /// 📝 Logger un événement de sécurité
  static Future<void> _logSecurityEvent({
    required String action,
    String? targetUserId,
    String? targetEmail,
    String? performedBy,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _firestore.collection('security_logs').add({
        'action': action,
        'targetUserId': targetUserId,
        'targetEmail': targetEmail,
        'performedBy': performedBy,
        'performedAt': FieldValue.serverTimestamp(),
        'details': details ?? {},
        'severity': 'high',
        'category': 'super_admin_management',
        'ipAddress': null, // À implémenter si nécessaire
        'userAgent': null, // À implémenter si nécessaire
      });
    } catch (e) {
      debugPrint('[SUPER_ADMIN_SERVICE] ⚠️ Erreur log sécurité: $e');
      // Ne pas faire échouer l'opération principale
    }
  }

  /// 📊 Obtenir les statistiques des Super Admins
  static Future<Map<String, dynamic>> getSuperAdminStats() async {
    try {
      final allSuperAdmins = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'super_admin')
          .get();

      final activeSuperAdmins = allSuperAdmins.docs
          .where((doc) => doc.data()['status'] == 'actif')
          .length;

      final inactiveSuperAdmins = allSuperAdmins.docs.length - activeSuperAdmins;

      return {
        'total': allSuperAdmins.docs.length,
        'actifs': activeSuperAdmins,
        'inactifs': inactiveSuperAdmins,
        'lastCreated': allSuperAdmins.docs.isNotEmpty
            ? allSuperAdmins.docs.first.data()['createdAt']
            : null,
      };
    } catch (e) {
      debugPrint('[SUPER_ADMIN_SERVICE] ❌ Erreur stats: $e');
      return {
        'total': 0,
        'actifs': 0,
        'inactifs': 0,
        'lastCreated': null,
      };
    }
  }
}
