import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 👨‍💼 Gestionnaire des comptes administrateurs
class AdminAccountsManager {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📧 Liste complète des comptes admin avec emails et mots de passe
  static const Map<String, List<Map<String, String>>> adminAccounts = {
    'Super Admin': [
      {
        'email': 'super.admin@constat-tunisie.tn',
        'password': 'SuperAdmin2024!',
        'nom': 'Super',
        'prenom': 'Administrateur',
        'telephone': '+216 20 000 000',
        'type': 'super_admin',
      },
    ],
    'Admins Compagnies': [
      {
        'email': 'admin.star@constat-tunisie.tn',
        'password': 'AdminStar2024!',
        'nom': 'Ben Ali',
        'prenom': 'Ahmed',
        'telephone': '+216 20 111 111',
        'type': 'admin_compagnie',
        'compagnieId': 'star_assurance',
      },
      {
        'email': 'admin.maghrebia@constat-tunisie.tn',
        'password': 'AdminMaghrebia2024!',
        'nom': 'Trabelsi',
        'prenom': 'Fatma',
        'telephone': '+216 20 222 222',
        'type': 'admin_compagnie',
        'compagnieId': 'maghrebia_assurance',
      },
      {
        'email': 'admin.gat@constat-tunisie.tn',
        'password': 'AdminGat2024!',
        'nom': 'Sassi',
        'prenom': 'Mohamed',
        'telephone': '+216 20 333 333',
        'type': 'admin_compagnie',
        'compagnieId': 'gat_assurance',
      },
      {
        'email': 'admin.bh@constat-tunisie.tn',
        'password': 'AdminBH2024!',
        'nom': 'Khelifi',
        'prenom': 'Leila',
        'telephone': '+216 20 444 444',
        'type': 'admin_compagnie',
        'compagnieId': 'bh_assurance',
      },
    ],
    'Admins Agences': [
      {
        'email': 'admin.star.tunis@constat-tunisie.tn',
        'password': 'AdminStarTunis2024!',
        'nom': 'Bouazizi',
        'prenom': 'Karim',
        'telephone': '+216 20 555 555',
        'type': 'admin_agence',
        'compagnieId': 'star_assurance',
        'agenceId': 'star_tunis',
      },
      {
        'email': 'admin.star.manouba@constat-tunisie.tn',
        'password': 'AdminStarManouba2024!',
        'nom': 'Jemli',
        'prenom': 'Sonia',
        'telephone': '+216 20 666 666',
        'type': 'admin_agence',
        'compagnieId': 'star_assurance',
        'agenceId': 'star_manouba',
      },
      {
        'email': 'admin.maghrebia.sfax@constat-tunisie.tn',
        'password': 'AdminMaghrebiaSfax2024!',
        'nom': 'Hamdi',
        'prenom': 'Nizar',
        'telephone': '+216 20 777 777',
        'type': 'admin_agence',
        'compagnieId': 'maghrebia_assurance',
        'agenceId': 'maghrebia_sfax',
      },
    ],
  };

  /// 🔧 Créer tous les comptes admin
  static Future<Map<String, dynamic>> createAllAdminAccounts() async {
    final results = <String, dynamic>{
      'success': [],
      'errors': [],
      'existing': [],
    };

    try {
      debugPrint('[AdminAccounts] 🔧 Création de tous les comptes admin...');

      for (final category in adminAccounts.entries) {
        debugPrint('[AdminAccounts] 📂 Catégorie: ${category.key}');
        
        for (final admin in category.value) {
          try {
            final email = admin['email']!;
            final password = admin['password']!;

            // Vérifier si le compte existe déjà
            final existingUser = await _checkIfUserExists(email);
            if (existingUser) {
              results['existing'].add(email);
              debugPrint('[AdminAccounts] ✅ Compte existant: $email');
              continue;
            }

            // Créer le compte Firebase Auth
            final userCredential = await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );

            if (userCredential.user != null) {
              // Créer le document admin dans Firestore
              await _createAdminDocument(userCredential.user!.uid, admin);
              
              results['success'].add(email);
              debugPrint('[AdminAccounts] ✅ Compte créé: $email');
            }

          } catch (e) {
            results['errors'].add('${admin['email']}: $e');
            debugPrint('[AdminAccounts] ❌ Erreur pour ${admin['email']}: $e');
          }
        }
      }

      debugPrint('[AdminAccounts] 🎉 Création terminée');
      debugPrint('[AdminAccounts] ✅ Succès: ${results['success'].length}');
      debugPrint('[AdminAccounts] ⚠️ Existants: ${results['existing'].length}');
      debugPrint('[AdminAccounts] ❌ Erreurs: ${results['errors'].length}');

    } catch (e) {
      debugPrint('[AdminAccounts] ❌ Erreur générale: $e');
      results['errors'].add('Erreur générale: $e');
    }

    return results;
  }

  /// 🔍 Vérifier si un utilisateur existe
  static Future<bool> _checkIfUserExists(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 📄 Créer le document admin dans Firestore
  static Future<void> _createAdminDocument(String uid, Map<String, String> adminData) async {
    await _firestore.collection('admins_users').doc(uid).set({
      'id': uid,
      'email': adminData['email'],
      'type': adminData['type'],
      'nom': adminData['nom'],
      'prenom': adminData['prenom'],
      'telephone': adminData['telephone'],
      'compagnieId': adminData['compagnieId'],
      'agenceId': adminData['agenceId'],
      'dateCreation': DateTime.now().millisecondsSinceEpoch,
      'active': true,
      'permissions': _getPermissions(adminData['type']!),
    });
  }

  /// 🔑 Obtenir les permissions selon le type d'admin
  static List<String> _getPermissions(String type) {
    switch (type) {
      case 'super_admin':
        return [
          'manage_all',
          'create_admins',
          'delete_admins',
          'view_all_data',
          'system_config',
          'manage_companies',
          'manage_agencies',
          'validate_agents',
          'manage_contracts',
          'view_reports',
        ];
      case 'admin_compagnie':
        return [
          'manage_company_data',
          'manage_agencies',
          'validate_agents',
          'view_company_reports',
          'manage_contracts',
          'view_claims',
        ];
      case 'admin_agence':
        return [
          'manage_agency_data',
          'validate_local_agents',
          'view_agency_reports',
          'manage_local_contracts',
          'view_local_claims',
        ];
      default:
        return ['view_basic_data'];
    }
  }

  /// 📋 Obtenir la liste formatée des emails admin
  static Map<String, List<String>> getFormattedAdminEmails() {
    final formatted = <String, List<String>>{};
    
    for (final category in adminAccounts.entries) {
      formatted[category.key] = category.value.map((admin) {
        return '${admin['email']} (${admin['password']})';
      }).toList();
    }
    
    return formatted;
  }

  /// 🧪 Tester la connexion d'un admin
  static Future<Map<String, dynamic>> testAdminLogin(String email, String password) async {
    try {
      debugPrint('[AdminAccounts] 🧪 Test connexion: $email');

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Vérifier le document admin
        final adminDoc = await _firestore
            .collection('admins_users')
            .doc(userCredential.user!.uid)
            .get();

        if (adminDoc.exists) {
          final adminData = adminDoc.data()!;

          // Déconnexion après test
          await _auth.signOut();

          return {
            'success': true,
            'message': 'Connexion réussie',
            'adminType': adminData['type'],
            'nom': '${adminData['prenom']} ${adminData['nom']}',
          };
        } else {
          // Document manquant, essayer de le créer
          debugPrint('[AdminAccounts] 📄 Document admin manquant, création...');
          await _createMissingAdminDocument(userCredential.user!.uid, email);

          await _auth.signOut();
          return {
            'success': true,
            'message': 'Document admin créé et connexion réussie',
            'adminType': 'admin_created',
            'nom': 'Admin Synchronisé',
          };
        }
      }

      return {
        'success': false,
        'message': 'Échec de l\'authentification',
      };

    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e',
      };
    }
  }

  /// 🔧 Créer un document admin manquant
  static Future<void> _createMissingAdminDocument(String uid, String email) async {
    // Trouver les données admin correspondantes
    Map<String, String>? adminData;

    for (final category in adminAccounts.values) {
      for (final admin in category) {
        if (admin['email'] == email) {
          adminData = admin;
          break;
        }
      }
      if (adminData != null) break;
    }

    if (adminData != null) {
      await _createAdminDocument(uid, adminData);
      debugPrint('[AdminAccounts] ✅ Document admin créé pour: $email');
    }
  }

  /// 📊 Obtenir les statistiques des comptes admin
  static Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final snapshot = await _firestore.collection('admins_users').get();
      
      final stats = <String, int>{
        'total': snapshot.docs.length,
        'super_admin': 0,
        'admin_compagnie': 0,
        'admin_agence': 0,
        'active': 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type'] as String? ?? 'unknown';
        final active = data['active'] as bool? ?? false;

        stats[type] = (stats[type] ?? 0) + 1;
        if (active) stats['active'] = stats['active']! + 1;
      }

      return {
        'success': true,
        'stats': stats,
      };

    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
