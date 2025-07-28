import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 🔧 Utilitaire temporaire pour configurer un admin compagnie de test
class TempAdminCompagnieSetup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔄 Transformer temporairement le super admin en admin compagnie
  static Future<Map<String, dynamic>> makeSuperAdminCompagnieAdmin() async {
    try {
      debugPrint('[TEMP_SETUP] 🔄 Configuration temporaire super admin → admin compagnie');

      const superAdminEmail = 'constat.tunisie.app@gmail.com';

      // 1. Trouver le super admin
      final superAdminQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: superAdminEmail)
          .get();

      if (superAdminQuery.docs.isEmpty) {
        return {
          'success': false,
          'error': 'Super admin non trouvé',
        };
      }

      final superAdminDoc = superAdminQuery.docs.first;
      final superAdminData = superAdminDoc.data();

      // 2. Trouver une compagnie existante
      final compagniesQuery = await _firestore
          .collection('compagnies')
          .limit(1)
          .get();

      if (compagniesQuery.docs.isEmpty) {
        return {
          'success': false,
          'error': 'Aucune compagnie trouvée',
        };
      }

      final compagnie = compagniesQuery.docs.first;
      final compagnieId = compagnie.id;
      final compagnieNom = compagnie.data()['nom'] ?? 'Compagnie Test';

      // 3. Sauvegarder l'état original
      await _firestore.collection('temp_backup').doc('super_admin_backup').set({
        'originalData': superAdminData,
        'backupDate': FieldValue.serverTimestamp(),
      });

      // 4. Modifier temporairement le rôle
      await _firestore.collection('users').doc(superAdminDoc.id).update({
        'role': 'admin_compagnie',
        'compagnieId': compagnieId,
        'compagnieNom': compagnieNom,
        'originalRole': 'super_admin', // Pour restaurer plus tard
        'tempModification': true,
        'tempModificationDate': FieldValue.serverTimestamp(),
        'permissions': [
          'manage_company_data',
          'view_company_stats',
          'manage_company_agents',
          'view_company_reports',
        ],
      });

      debugPrint('[TEMP_SETUP] ✅ Super admin temporairement configuré comme admin compagnie');

      return {
        'success': true,
        'message': 'Super admin temporairement configuré comme admin compagnie',
        'email': superAdminEmail,
        'password': 'Acheya123', // Mot de passe existant
        'compagnieNom': compagnieNom,
        'instructions': 'Connectez-vous avec constat.tunisie.app@gmail.com / Acheya123',
      };

    } catch (e) {
      debugPrint('[TEMP_SETUP] ❌ Erreur configuration temporaire: $e');
      return {
        'success': false,
        'error': 'Erreur lors de la configuration: $e',
      };
    }
  }

  /// 🔙 Restaurer le super admin à son état original
  static Future<Map<String, dynamic>> restoreSuperAdmin() async {
    try {
      debugPrint('[TEMP_SETUP] 🔙 Restauration super admin...');

      const superAdminEmail = 'constat.tunisie.app@gmail.com';

      // 1. Récupérer la sauvegarde
      final backupDoc = await _firestore
          .collection('temp_backup')
          .doc('super_admin_backup')
          .get();

      if (!backupDoc.exists) {
        return {
          'success': false,
          'error': 'Sauvegarde non trouvée',
        };
      }

      final originalData = backupDoc.data()!['originalData'] as Map<String, dynamic>;

      // 2. Trouver l'utilisateur actuel
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: superAdminEmail)
          .get();

      if (userQuery.docs.isEmpty) {
        return {
          'success': false,
          'error': 'Utilisateur non trouvé',
        };
      }

      // 3. Restaurer les données originales
      await _firestore.collection('users').doc(userQuery.docs.first.id).update({
        'role': originalData['role'],
        'permissions': originalData['permissions'],
        'compagnieId': FieldValue.delete(),
        'compagnieNom': FieldValue.delete(),
        'originalRole': FieldValue.delete(),
        'tempModification': FieldValue.delete(),
        'tempModificationDate': FieldValue.delete(),
        'restoredAt': FieldValue.serverTimestamp(),
      });

      // 4. Supprimer la sauvegarde
      await _firestore.collection('temp_backup').doc('super_admin_backup').delete();

      debugPrint('[TEMP_SETUP] ✅ Super admin restauré');

      return {
        'success': true,
        'message': 'Super admin restauré avec succès',
      };

    } catch (e) {
      debugPrint('[TEMP_SETUP] ❌ Erreur restauration: $e');
      return {
        'success': false,
        'error': 'Erreur lors de la restauration: $e',
      };
    }
  }

  /// 📋 Vérifier l'état actuel
  static Future<Map<String, dynamic>> checkCurrentState() async {
    try {
      const superAdminEmail = 'constat.tunisie.app@gmail.com';

      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: superAdminEmail)
          .get();

      if (userQuery.docs.isEmpty) {
        return {
          'success': false,
          'error': 'Utilisateur non trouvé',
        };
      }

      final userData = userQuery.docs.first.data();
      final currentRole = userData['role'];
      final isTemp = userData['tempModification'] ?? false;

      return {
        'success': true,
        'currentRole': currentRole,
        'isTemporaryModification': isTemp,
        'compagnieNom': userData['compagnieNom'],
        'email': superAdminEmail,
      };

    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur vérification: $e',
      };
    }
  }
}
