import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../auth/models/user_model.dart';
import '../../../utils/user_type.dart';

/// 👑 Service de configuration des comptes administrateurs
class AdminSetupService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔧 Créer le compte admin par défaut
  static Future<bool> createDefaultAdminAccount() async {
    try {
      const adminEmail = 'constat.tunisie.app@gmail.com';
      const adminPassword = 'Acheya123';

      // Vérifier si l'admin existe déjà
      final existingAdmins = await _firestore
          .collection('users')
          .where('email', isEqualTo: adminEmail)
          .where('userType', isEqualTo: 'admin')
          .get();

      if (existingAdmins.docs.isNotEmpty) {
        debugPrint('✅ Compte admin par défaut existe déjà');
        return true;
      }

      // Créer le compte Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      if (userCredential.user != null) {
        // Créer le document utilisateur
        final adminUser = UserModel(
          uid: userCredential.user!.uid,
          email: adminEmail,
          nom: 'Constat Tunisie',
          prenom: 'Admin',
          telephone: '00000000',
          adresse: 'Tunisie',
          userType: UserType.admin,
          accountStatus: AccountStatus.active,
          dateCreation: DateTime.now(),
          dateModification: DateTime.now(),
          permissions: [
            'manage_users',
            'manage_permissions',
            'view_all_data',
            'system_config',
            'validate_agents',
            'manage_notifications',
            'view_contracts',
            'create_contracts',
            'edit_contracts',
            'delete_contracts',
            'view_claims',
            'process_claims',
            'view_expertises',
            'create_expertises',
            'edit_expertises',
            'validate_claims',
          ],
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(adminUser.toFirestore());

        // Créer aussi dans la collection admins pour compatibilité
        await _firestore
            .collection('admins')
            .doc(userCredential.user!.uid)
            .set({
          'uid': userCredential.user!.uid,
          'email': adminEmail,
          'nom': 'Constat Tunisie',
          'prenom': 'Admin',
          'telephone': '00000000',
          'adresse': 'Tunisie',
          'niveauAcces': 'super_admin',
          'permissions': adminUser.permissions,
          'dateCreation': DateTime.now(),
          'dateModification': DateTime.now(),
          'nombreValidations': 0,
          'zoneResponsabilite': ['Tunisie'],
        });

        debugPrint('✅ Compte admin par défaut créé avec succès');
        debugPrint('📧 Email: $adminEmail');
        debugPrint('🔑 Mot de passe: $adminPassword');
        debugPrint('👑 Nom: Constat Tunisie Admin');
        
        return true;
      }
    } catch (e) {
      debugPrint('❌ Erreur création compte admin: $e');
      return false;
    }

    return false;
  }

  /// 🔧 Créer un compte admin personnalisé
  static Future<bool> createCustomAdminAccount({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String telephone,
    String? adresse,
    List<String>? permissions,
  }) async {
    try {
      // Créer le compte Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Permissions par défaut pour un admin
        final defaultPermissions = permissions ?? [
          'manage_users',
          'manage_permissions',
          'view_all_data',
          'validate_agents',
          'manage_notifications',
        ];

        // Créer le document utilisateur
        final adminUser = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          nom: nom,
          prenom: prenom,
          telephone: telephone,
          adresse: adresse ?? 'Non spécifiée',
          userType: UserType.admin,
          accountStatus: AccountStatus.active,
          dateCreation: DateTime.now(),
          dateModification: DateTime.now(),
          permissions: defaultPermissions,
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(adminUser.toFirestore());

        // Créer aussi dans la collection admins
        await _firestore
            .collection('admins')
            .doc(userCredential.user!.uid)
            .set({
          'uid': userCredential.user!.uid,
          'email': email,
          'nom': nom,
          'prenom': prenom,
          'telephone': telephone,
          'adresse': adresse ?? 'Non spécifiée',
          'niveauAcces': 'admin',
          'permissions': defaultPermissions,
          'dateCreation': DateTime.now(),
          'dateModification': DateTime.now(),
          'nombreValidations': 0,
          'zoneResponsabilite': ['Tunisie'],
        });

        debugPrint('✅ Compte admin personnalisé créé: $email');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Erreur création compte admin personnalisé: $e');
      return false;
    }

    return false;
  }

  /// 🔍 Vérifier si un utilisateur est admin
  static Future<bool> isUserAdmin(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        return userData['userType'] == 'admin';
      }
    } catch (e) {
      debugPrint('❌ Erreur vérification admin: $e');
    }
    return false;
  }

  /// 📊 Obtenir les statistiques admin
  static Future<Map<String, int>> getAdminStats() async {
    try {
      final stats = <String, int>{};

      // Compter les utilisateurs par type
      final users = await _firestore.collection('users').get();
      stats['total_users'] = users.docs.length;
      stats['conducteurs'] = users.docs.where((doc) => doc.data()['userType'] == 'conducteur').length;
      stats['assureurs'] = users.docs.where((doc) => doc.data()['userType'] == 'assureur').length;
      stats['experts'] = users.docs.where((doc) => doc.data()['userType'] == 'expert').length;
      stats['admins'] = users.docs.where((doc) => doc.data()['userType'] == 'admin').length;

      // Compter les demandes en attente
      final requests = await _firestore
          .collection('professional_account_requests')
          .where('status', isEqualTo: 'pending')
          .get();
      stats['pending_requests'] = requests.docs.length;

      // Compter les notifications non lues
      final notifications = await _firestore
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();
      stats['unread_notifications'] = notifications.docs.length;

      return stats;
    } catch (e) {
      debugPrint('❌ Erreur récupération statistiques: $e');
      return {};
    }
  }

  /// 🔧 Initialiser le système admin
  static Future<void> initializeAdminSystem() async {
    debugPrint('🚀 Initialisation du système admin...');
    
    // Créer le compte admin par défaut
    await createDefaultAdminAccount();
    
    // Autres initialisations si nécessaire
    debugPrint('✅ Système admin initialisé');
  }
}
