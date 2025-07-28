import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 🧪 Utilitaire pour créer un admin compagnie de test
class CreateTestAdminCompagnie {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🏢 Créer un admin compagnie de test (ou utiliser un existant)
  static Future<Map<String, dynamic>> createTestAdmin() async {
    try {
      debugPrint('[TEST_ADMIN] 🧪 Recherche/Création admin compagnie de test...');

      // 1. D'abord, chercher un admin compagnie existant
      final existingAdmins = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_compagnie')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (existingAdmins.docs.isNotEmpty) {
        final adminData = existingAdmins.docs.first.data();
        debugPrint('[TEST_ADMIN] ✅ Admin compagnie existant trouvé');

        // Mettre à jour avec un mot de passe simple pour les tests
        const testPassword = 'Test123!';
        await _firestore.collection('users').doc(existingAdmins.docs.first.id).update({
          'password': testPassword,
          'temporaryPassword': testPassword,
          'requirePasswordChange': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return {
          'success': true,
          'message': 'Admin compagnie existant configuré pour les tests',
          'email': adminData['email'],
          'password': testPassword,
          'uid': adminData['uid'],
          'compagnieId': adminData['compagnieId'],
          'compagnieNom': adminData['compagnieNom'],
          'displayName': adminData['displayName'],
        };
      }

      // 2. Si aucun admin existant, créer un nouveau
      debugPrint('[TEST_ADMIN] 🆕 Aucun admin existant, création d\'un nouveau...');

      // Données de test
      const email = 'admin.test@comarassurances.com';
      const password = 'Test123!';
      const prenom = 'Admin';
      const nom = 'Test';
      const telephone = '+216 12 345 678';

      // Vérifier si l'email existe déjà
      final existingUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (existingUser.docs.isNotEmpty) {
        debugPrint('[TEST_ADMIN] ⚠️ Utilisateur avec cet email existe déjà');
        final userData = existingUser.docs.first.data();
        return {
          'success': true,
          'message': 'Utilisateur de test existe déjà',
          'email': email,
          'password': password,
          'uid': userData['uid'],
          'compagnieId': userData['compagnieId'],
          'compagnieNom': userData['compagnieNom'],
        };
      }

      // 2. Trouver une compagnie existante
      final compagniesQuery = await _firestore
          .collection('compagnies')
          .limit(1)
          .get();

      if (compagniesQuery.docs.isEmpty) {
        return {
          'success': false,
          'error': 'Aucune compagnie trouvée pour assigner l\'admin',
        };
      }

      final compagnie = compagniesQuery.docs.first;
      final compagnieId = compagnie.id;
      final compagnieNom = compagnie.data()['nom'] ?? 'Compagnie Test';

      debugPrint('[TEST_ADMIN] 🏢 Compagnie sélectionnée: $compagnieNom ($compagnieId)');

      // 3. Créer l'utilisateur Firebase Auth
      UserCredential userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        debugPrint('[TEST_ADMIN] ❌ Erreur création Firebase Auth: $e');
        return {
          'success': false,
          'error': 'Erreur création compte Firebase: $e',
        };
      }

      final user = userCredential.user!;
      debugPrint('[TEST_ADMIN] ✅ Utilisateur Firebase créé: ${user.uid}');

      // 4. Créer le document Firestore
      final userData = {
        'uid': user.uid,
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
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'test_script',
        'password': password, // Pour référence (en production, ne pas stocker)
      };

      await _firestore.collection('users').doc(user.uid).set(userData);
      debugPrint('[TEST_ADMIN] ✅ Document Firestore créé');

      // 5. Mettre à jour la compagnie
      await _firestore.collection('compagnies').doc(compagnieId).update({
        'adminCompagnieId': user.uid,
        'adminCompagnieNom': '$prenom $nom',
        'adminCompagnieEmail': email,
        'adminAssignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[TEST_ADMIN] ✅ Compagnie mise à jour');

      return {
        'success': true,
        'message': 'Admin compagnie de test créé avec succès',
        'email': email,
        'password': password,
        'uid': user.uid,
        'compagnieId': compagnieId,
        'compagnieNom': compagnieNom,
      };

    } catch (e) {
      debugPrint('[TEST_ADMIN] ❌ Erreur générale: $e');
      return {
        'success': false,
        'error': 'Erreur lors de la création: $e',
      };
    }
  }

  /// 🗑️ Supprimer l'admin de test
  static Future<Map<String, dynamic>> deleteTestAdmin() async {
    try {
      const email = 'admin.test@comarassurances.com';

      // Trouver l'utilisateur
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userQuery.docs.isEmpty) {
        return {
          'success': false,
          'error': 'Utilisateur de test non trouvé',
        };
      }

      final userDoc = userQuery.docs.first;
      final userData = userDoc.data();
      final uid = userData['uid'];
      final compagnieId = userData['compagnieId'];

      // Supprimer de Firestore
      await _firestore.collection('users').doc(userDoc.id).delete();

      // Mettre à jour la compagnie
      if (compagnieId != null) {
        await _firestore.collection('compagnies').doc(compagnieId).update({
          'adminCompagnieId': FieldValue.delete(),
          'adminCompagnieNom': FieldValue.delete(),
          'adminCompagnieEmail': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Note: Suppression Firebase Auth nécessite des privilèges admin
      // Pour l'instant, on se contente de supprimer de Firestore
      debugPrint('[TEST_ADMIN] ℹ️ Suppression Firebase Auth non implémentée (nécessite privilèges admin)');

      return {
        'success': true,
        'message': 'Admin de test supprimé avec succès',
      };

    } catch (e) {
      debugPrint('[TEST_ADMIN] ❌ Erreur suppression: $e');
      return {
        'success': false,
        'error': 'Erreur lors de la suppression: $e',
      };
    }
  }

  /// 📋 Lister tous les admins compagnie existants
  static Future<Map<String, dynamic>> listExistingAdmins() async {
    try {
      debugPrint('[TEST_ADMIN] 📋 Recherche des admins compagnie existants...');

      final adminsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_compagnie')
          .get();

      final admins = <Map<String, dynamic>>[];

      for (final doc in adminsQuery.docs) {
        final data = doc.data();
        admins.add({
          'id': doc.id,
          'email': data['email'],
          'displayName': data['displayName'],
          'compagnieNom': data['compagnieNom'],
          'isActive': data['isActive'] ?? false,
          'status': data['status'] ?? 'inconnu',
        });
      }

      debugPrint('[TEST_ADMIN] ✅ ${admins.length} admins compagnie trouvés');

      return {
        'success': true,
        'admins': admins,
        'count': admins.length,
      };

    } catch (e) {
      debugPrint('[TEST_ADMIN] ❌ Erreur recherche admins: $e');
      return {
        'success': false,
        'error': 'Erreur lors de la recherche: $e',
      };
    }
  }

  /// 🔑 Configurer un admin existant pour les tests
  static Future<Map<String, dynamic>> configureExistingAdminForTest(String adminId) async {
    try {
      debugPrint('[TEST_ADMIN] 🔑 Configuration admin pour tests: $adminId');

      const testPassword = 'Test123!';

      // Mettre à jour l'admin avec un mot de passe simple
      await _firestore.collection('users').doc(adminId).update({
        'password': testPassword,
        'temporaryPassword': testPassword,
        'requirePasswordChange': false,
        'isActive': true,
        'status': 'actif',
        'updatedAt': FieldValue.serverTimestamp(),
        'configuredForTest': true,
      });

      // Récupérer les données mises à jour
      final adminDoc = await _firestore.collection('users').doc(adminId).get();
      final adminData = adminDoc.data()!;

      debugPrint('[TEST_ADMIN] ✅ Admin configuré pour les tests');

      return {
        'success': true,
        'message': 'Admin configuré pour les tests avec succès',
        'email': adminData['email'],
        'password': testPassword,
        'displayName': adminData['displayName'],
        'compagnieNom': adminData['compagnieNom'],
      };

    } catch (e) {
      debugPrint('[TEST_ADMIN] ❌ Erreur configuration: $e');
      return {
        'success': false,
        'error': 'Erreur lors de la configuration: $e',
      };
    }
  }
}
