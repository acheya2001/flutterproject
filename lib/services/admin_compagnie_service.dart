import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'company_structure_service.dart';
import 'company_management_service.dart';

/// 🏢 Service pour la gestion des Admin Compagnie
class AdminCompagnieService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔐 Générer un mot de passe sécurisé
  static String generateSecurePassword() {
    const String chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    const String symbols = '@#!&*';
    final random = math.Random.secure();

    // Structure: @Assur + 4 chiffres + # + 2 lettres + !
    final year = DateTime.now().year;
    final numbers = List.generate(4, (_) => random.nextInt(10)).join();
    final letters = List.generate(2, (_) => chars[random.nextInt(chars.length)]).join();

    return '@Assur$year#$numbers$letters!';
  }

  /// 👤 Créer un nouveau Admin Compagnie
  static Future<Map<String, dynamic>> createAdminCompagnie({
    required String prenom,
    required String nom,
    required String telephone,
    required String compagnieId,
    required String compagnieNom,
  }) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🏢 Création Admin Compagnie: $prenom $nom');

      // Vérifier que l'utilisateur actuel est bien un Super Admin
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔍 Utilisateur actuel: ${currentUser.uid}');
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔍 Email actuel: ${currentUser.email}');

      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔍 Document existe: ${currentUserDoc.exists}');

      if (currentUserDoc.exists) {
        final userData = currentUserDoc.data();
        debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔍 Role utilisateur: ${userData?['role']}');
        debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔍 Données utilisateur: $userData');
      }

      // Vérification alternative pour le super admin
      bool isSuperAdmin = false;

      if (currentUserDoc.exists) {
        final userData = currentUserDoc.data();
        isSuperAdmin = userData?['role'] == 'super_admin';
      }

      // Vérification alternative par email (pour le compte principal)
      if (!isSuperAdmin && currentUser.email == 'constat.tunisie.app@gmail.com') {
        debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔍 Utilisateur reconnu comme super admin par email');
        isSuperAdmin = true;
      }

      if (!isSuperAdmin) {
        String currentRole = 'document inexistant';
        if (currentUserDoc.exists) {
          final userData = currentUserDoc.data();
          currentRole = userData?['role']?.toString() ?? 'role non défini';
        }
        throw Exception('Seul un Super Admin peut créer des Admin Compagnie. Role actuel: $currentRole');
      }

      // Recherche intelligente de la compagnie avec le nouveau service
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔍 Recherche compagnie ID: $compagnieId');
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔍 Nom compagnie: $compagnieNom');

      var company = await CompanyManagementService.smartFindCompany(compagnieId);

      if (company == null) {
        // Essayer par nom si l'ID ne fonctionne pas
        debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔍 Recherche par nom: $compagnieNom');
        company = await CompanyManagementService.findCompanyByName(compagnieNom);
      }

      if (company == null) {
        throw Exception('Compagnie non trouvée (ID: $compagnieId, Nom: $compagnieNom)');
      }

      // Utiliser l'ID correct de la compagnie trouvée
      compagnieId = company.id;
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ✅ Compagnie trouvée: ${company.nom} (ID: $compagnieId)');

      // Vérifier si la compagnie a déjà un admin
      final hasAdmin = company.adminCompagnieId != null && company.adminCompagnieId!.isNotEmpty;
      if (hasAdmin) {
        throw Exception('Cette compagnie a déjà un administrateur assigné: ${company.adminCompagnieNom}');
      }

      // Vérifier qu'il n'y a pas déjà un admin pour cette compagnie
      final existingAdmin = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_compagnie')
          .where('compagnieId', isEqualTo: compagnieId)
          .where('status', isEqualTo: 'actif')
          .get();

      if (existingAdmin.docs.isNotEmpty) {
        throw Exception('Cette compagnie a déjà un Admin Compagnie actif');
      }

      // Générer l'email automatiquement
      final email = await _generateEmail(prenom, nom, compagnieNom);
      
      // Vérifier que l'email n'existe pas déjà
      final existingUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (existingUser.docs.isNotEmpty) {
        throw Exception('Un utilisateur avec cet email existe déjà');
      }

      // Générer un mot de passe sécurisé
      final password = generateSecurePassword();
      final userId = _generateUserId();

      // Créer le document utilisateur
      final userData = {
        'uid': userId,
        'email': email,
        'prenom': prenom,
        'nom': nom,
        'displayName': '$prenom $nom',
        'telephone': telephone,
        'role': 'admin_compagnie',
        'status': 'actif',
        'isActive': true,
        'isLegitimate': true,
        'compagnieId': compagnieId,
        'compagnieNom': compagnieNom,
        'permissions': [
          'manage_company_data',
          'view_company_stats',
          'manage_company_agents',
          'view_company_reports',
        ],
        'requirePasswordChange': true,
        'password': password, // Temporaire pour transmission
        'temporaryPassword': password,
        'createdBy': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'source': 'super_admin_creation',
        'accountType': 'admin_compagnie',
        'lastLoginAt': null,
        'loginCount': 0,
        'twoFactorEnabled': false,
      };

      // Sauvegarder dans Firestore
      await _firestore.collection('users').doc(userId).set(userData);

      // Mettre à jour la compagnie avec l'admin assigné dans la collection unifiée
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔄 Mise à jour compagnie ID: $compagnieId');
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔄 Admin ID: $userId');
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔄 Admin Email: $email');

      // Mettre à jour directement dans la collection compagnies
      await _firestore.collection('compagnies').doc(compagnieId).update({
        'adminCompagnieId': userId,
        'adminCompagnieNom': '$prenom $nom',
        'adminCompagnieEmail': email,
        'adminAssignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final updateSuccess = await CompanyStructureService.updateCompanyAdmin(
        compagnieId: compagnieId,
        adminId: userId,
        adminNom: '$prenom $nom',
        adminEmail: email,
      );

      if (!updateSuccess) {
        debugPrint('[ADMIN_COMPAGNIE_SERVICE] ⚠️ Échec mise à jour compagnie, mais compte créé');
      }

      // Log de sécurité
      await _logSecurityEvent(
        action: 'admin_compagnie_created',
        targetUserId: userId,
        targetEmail: email,
        performedBy: currentUser.uid,
        details: {
          'prenom': prenom,
          'nom': nom,
          'telephone': telephone,
          'compagnieId': compagnieId,
          'compagnieNom': compagnieNom,
        },
      );

      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ✅ Admin Compagnie créé: $email');

      return {
        'success': true,
        'userId': userId,
        'email': email,
        'password': password,
        'compagnieNom': compagnieNom,
        'displayName': '$prenom $nom',
        'message': 'Admin Compagnie créé avec succès',
      };
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ❌ Erreur création Admin Compagnie: $e');
      
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 📧 Générer l'email automatiquement
  static Future<String> _generateEmail(String prenom, String nom, String compagnieNom) async {
    // Nettoyer les noms (enlever accents, espaces, caractères spéciaux)
    final cleanPrenom = _cleanString(prenom);
    final cleanNom = _cleanString(nom);
    final cleanCompagnie = _cleanString(compagnieNom);

    String baseEmail = '$cleanPrenom.$cleanNom@$cleanCompagnie.com';
    
    // Vérifier si l'email existe déjà
    final existingUser = await _firestore
        .collection('users')
        .where('email', isEqualTo: baseEmail)
        .get();

    if (existingUser.docs.isEmpty) {
      return baseEmail;
    }

    // Si l'email existe, ajouter un chiffre
    int counter = 2;
    String emailWithNumber;
    
    do {
      emailWithNumber = '$cleanPrenom.$cleanNom$counter@$cleanCompagnie.com';
      final existingUserWithNumber = await _firestore
          .collection('users')
          .where('email', isEqualTo: emailWithNumber)
          .get();
      
      if (existingUserWithNumber.docs.isEmpty) {
        return emailWithNumber;
      }
      
      counter++;
    } while (counter <= 99); // Limite de sécurité

    throw Exception('Impossible de générer un email unique');
  }

  /// 🧹 Nettoyer une chaîne pour l'email
  static String _cleanString(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ýÿ]'), 'y')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
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
    
    // Compléter avec des caractères aléatoires (total 10 caractères)
    for (int i = 4; i < 10; i++) {
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
    return 'admin_comp_${timestamp}_$random';
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
        'severity': 'medium',
        'category': 'admin_compagnie_management',
        'ipAddress': null,
        'userAgent': null,
      });
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ⚠️ Erreur log sécurité: $e');
    }
  }

  /// 📊 Lister tous les Admin Compagnie
  static Future<List<Map<String, dynamic>>> getAllAdminCompagnie() async {
    try {
      final query = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_compagnie')
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
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ❌ Erreur liste Admin Compagnie: $e');
      rethrow;
    }
  }

  /// 🔒 Désactiver un Admin Compagnie
  static Future<void> deactivateAdminCompagnie(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer les infos de l'admin à désactiver
      final adminDoc = await _firestore.collection('users').doc(userId).get();
      if (!adminDoc.exists) {
        throw Exception('Admin Compagnie non trouvé');
      }

      final adminData = adminDoc.data()!;
      final compagnieId = adminData['compagnieId'];

      // Désactiver l'admin
      await _firestore.collection('users').doc(userId).update({
        'status': 'desactive',
        'isActive': false,
        'deactivatedBy': currentUser.uid,
        'deactivatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour la compagnie
      if (compagnieId != null) {
        await _firestore.collection('compagnies_assurance').doc(compagnieId).update({
          'adminCompagnieId': null,
          'adminCompagnieNom': null,
          'adminCompagnieEmail': null,
          'adminRemovedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Log de sécurité
      await _logSecurityEvent(
        action: 'admin_compagnie_deactivated',
        targetUserId: userId,
        performedBy: currentUser.uid,
      );

      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ✅ Admin Compagnie désactivé: $userId');
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ❌ Erreur désactivation: $e');
      rethrow;
    }
  }
}
