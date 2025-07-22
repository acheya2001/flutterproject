import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 🔄 Service de synchronisation entre compagnies et leurs admins
class CompanyAdminSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🏢 Désactiver/Activer une compagnie et synchroniser son admin
  static Future<Map<String, dynamic>> toggleCompanyStatus({
    required String compagnieId,
    required bool newStatus,
  }) async {
    try {
      debugPrint('[COMPANY_SYNC] 🔄 Début synchronisation compagnie: $compagnieId');
      debugPrint('[COMPANY_SYNC] 📊 Nouveau statut: ${newStatus ? "actif" : "inactif"}');

      // 1. Mettre à jour le statut de la compagnie
      await _firestore.collection('compagnies').doc(compagnieId).update({
        'status': newStatus ? 'active' : 'inactive',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': 'system_sync',
      });

      debugPrint('[COMPANY_SYNC] ✅ Compagnie mise à jour');

      // 2. Trouver TOUS les admins de cette compagnie (actifs ET inactifs)
      final adminQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_compagnie')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      debugPrint('[COMPANY_SYNC] 🔍 ${adminQuery.docs.length} admins trouvés pour cette compagnie');

      int adminsUpdated = 0;
      String adminInfo = 'Aucun admin trouvé';

      if (adminQuery.docs.isNotEmpty) {
        for (final adminDoc in adminQuery.docs) {
          final adminData = adminDoc.data();
          final currentStatus = adminData['isActive'] ?? false;

          debugPrint('[COMPANY_SYNC] 👤 Admin ${adminDoc.id}: statut actuel=$currentStatus, nouveau=$newStatus');

          // 3. Mettre à jour le statut de TOUS les admins de cette compagnie
          await _firestore.collection('users').doc(adminDoc.id).update({
            'isActive': newStatus,
            'status': newStatus ? 'actif' : 'inactif',
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': 'system_sync',
            'syncReason': newStatus
                ? 'Réactivation automatique suite à réactivation compagnie'
                : 'Désactivation automatique suite à désactivation compagnie',
            'lastSyncAt': FieldValue.serverTimestamp(),
          });

          adminsUpdated++;
          adminInfo = adminData['displayName'] ?? '${adminData['prenom']} ${adminData['nom']}';

          debugPrint('[COMPANY_SYNC] ✅ Admin synchronisé: ${adminDoc.id} - $adminInfo (${currentStatus} → $newStatus)');
        }
      }

      // 4. Mettre à jour les champs de liaison dans la compagnie
      if (adminsUpdated > 0) {
        await _firestore.collection('compagnies').doc(compagnieId).update({
          'adminStatus': newStatus ? 'active' : 'inactive',
          'lastAdminSync': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('[COMPANY_SYNC] ✅ Synchronisation terminée');

      return {
        'success': true,
        'compagnieId': compagnieId,
        'newStatus': newStatus,
        'adminsUpdated': adminsUpdated,
        'adminInfo': adminInfo,
        'message': newStatus 
            ? 'Compagnie et admin réactivés avec succès'
            : 'Compagnie et admin désactivés avec succès',
      };
    } catch (e) {
      debugPrint('[COMPANY_SYNC] ❌ Erreur synchronisation: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 👤 Désactiver un admin et permettre la réassignation
  static Future<Map<String, dynamic>> deactivateAdminForReassignment({
    required String adminId,
    required String compagnieId,
  }) async {
    try {
      debugPrint('[COMPANY_SYNC] 🔄 Désactivation admin pour réassignation: $adminId');

      // 1. Désactiver l'admin
      await _firestore.collection('users').doc(adminId).update({
        'isActive': false,
        'status': 'inactif',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': 'admin_reassignment',
        'deactivationReason': 'Désactivé pour permettre réassignation à la compagnie',
      });

      // 2. Mettre à jour la compagnie pour indiquer qu'elle n'a plus d'admin actif
      await _firestore.collection('compagnies').doc(compagnieId).update({
        'hasAdmin': false,
        'adminCompagnieId': null,
        'adminCompagnieEmail': null,
        'adminCompagnieNom': null,
        'adminStatus': 'none',
        'adminDeactivatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': 'admin_reassignment',
      });

      debugPrint('[COMPANY_SYNC] ✅ Admin désactivé et compagnie prête pour réassignation');

      return {
        'success': true,
        'adminId': adminId,
        'compagnieId': compagnieId,
        'message': 'Admin désactivé. La compagnie peut maintenant recevoir un nouvel admin.',
      };
    } catch (e) {
      debugPrint('[COMPANY_SYNC] ❌ Erreur désactivation admin: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🔄 Réassigner un admin à une compagnie
  static Future<Map<String, dynamic>> reassignAdminToCompany({
    required String newAdminId,
    required String compagnieId,
  }) async {
    try {
      debugPrint('[COMPANY_SYNC] 🔄 Réassignation admin: $newAdminId -> $compagnieId');

      // 1. Vérifier que la compagnie existe
      final companyDoc = await _firestore.collection('compagnies').doc(compagnieId).get();
      if (!companyDoc.exists) {
        return {
          'success': false,
          'error': 'Compagnie non trouvée',
        };
      }

      final companyData = companyDoc.data()!;

      // 2. IMPORTANT: Désactiver TOUS les admins actifs de cette compagnie
      final existingAdminsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_compagnie')
          .where('compagnieId', isEqualTo: compagnieId)
          .where('isActive', isEqualTo: true)
          .get();

      debugPrint('[COMPANY_SYNC] 🔍 ${existingAdminsQuery.docs.length} admins actifs trouvés pour cette compagnie');

      // Désactiver tous les admins existants
      for (final adminDoc in existingAdminsQuery.docs) {
        await _firestore.collection('users').doc(adminDoc.id).update({
          'isActive': false,
          'status': 'inactif',
          'deactivationReason': 'Désactivé automatiquement pour réassignation',
          'deactivatedAt': FieldValue.serverTimestamp(),
          'deactivatedBy': 'system_reassignment',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[COMPANY_SYNC] ⚠️ Admin ${adminDoc.id} désactivé pour réassignation');
      }

      // 3. Vérifier que le nouvel admin existe
      final adminDoc = await _firestore.collection('users').doc(newAdminId).get();
      if (!adminDoc.exists) {
        return {
          'success': false,
          'error': 'Admin non trouvé',
        };
      }

      final adminData = adminDoc.data()!;
      if (adminData['role'] != 'admin_compagnie') {
        return {
          'success': false,
          'error': 'Cet utilisateur n\'est pas un admin compagnie',
        };
      }

      // 4. Si l'admin est déjà assigné à une autre compagnie, le désassigner d'abord
      if (adminData['compagnieId'] != null && adminData['compagnieId'] != compagnieId) {
        debugPrint('[COMPANY_SYNC] ⚠️ Admin déjà assigné à ${adminData['compagnieId']}, désassignation...');

        // Mettre à jour l'ancienne compagnie
        await _firestore.collection('compagnies').doc(adminData['compagnieId']).update({
          'hasAdmin': false,
          'adminCompagnieId': null,
          'adminCompagnieEmail': null,
          'adminCompagnieNom': null,
          'adminStatus': 'none',
          'adminRemovedAt': FieldValue.serverTimestamp(),
          'adminRemovedReason': 'Admin réassigné à une autre compagnie',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 5. Assigner le nouvel admin à la compagnie
      await _firestore.collection('users').doc(newAdminId).update({
        'compagnieId': compagnieId,
        'compagnieNom': companyData['nom'],
        'isActive': true,
        'status': 'actif',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': 'admin_reassignment',
        'assignmentReason': 'Réassigné à la compagnie ${companyData['nom']}',
        'reassignedAt': FieldValue.serverTimestamp(),
      });

      // 6. Mettre à jour la compagnie
      await _firestore.collection('compagnies').doc(compagnieId).update({
        'hasAdmin': true,
        'adminCompagnieId': newAdminId,
        'adminCompagnieEmail': adminData['email'],
        'adminCompagnieNom': adminData['displayName'] ?? '${adminData['prenom']} ${adminData['nom']}',
        'adminStatus': 'active',
        'adminAssignedAt': FieldValue.serverTimestamp(),
        'previousAdminsDeactivated': existingAdminsQuery.docs.length,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': 'admin_reassignment',
      });

      debugPrint('[COMPANY_SYNC] ✅ Réassignation terminée');

      debugPrint('[COMPANY_SYNC] ✅ Réassignation terminée avec succès');

      return {
        'success': true,
        'adminId': newAdminId,
        'compagnieId': compagnieId,
        'adminName': adminData['displayName'] ?? '${adminData['prenom']} ${adminData['nom']}',
        'compagnieNom': companyData['nom'],
        'previousAdminsDeactivated': existingAdminsQuery.docs.length,
        'message': 'Admin réassigné avec succès. ${existingAdminsQuery.docs.length} ancien(s) admin(s) désactivé(s).',
      };
    } catch (e) {
      debugPrint('[COMPANY_SYNC] ❌ Erreur réassignation: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 📋 Obtenir les admins disponibles pour réassignation
  static Future<List<Map<String, dynamic>>> getAvailableAdminsForReassignment() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_compagnie')
          .where('isActive', isEqualTo: false)
          .get();

      final admins = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'displayName': data['displayName'],
          'email': data['email'],
          'compagnieId': data['compagnieId'],
          'compagnieNom': data['compagnieNom'],
          'status': data['status'],
          'deactivationReason': data['deactivationReason'],
        };
      }).toList();

      // Trier par nom
      admins.sort((a, b) => (a['displayName'] ?? '').compareTo(b['displayName'] ?? ''));
      
      return admins;
    } catch (e) {
      debugPrint('[COMPANY_SYNC] ❌ Erreur récupération admins disponibles: $e');
      return [];
    }
  }

  /// 📊 Obtenir les statistiques de synchronisation
  static Future<Map<String, dynamic>> getSyncStatistics() async {
    try {
      // Compagnies actives/inactives
      final companiesSnapshot = await _firestore.collection('compagnies').get();
      int activeCompanies = 0;
      int inactiveCompanies = 0;
      int companiesWithAdmin = 0;
      int companiesWithoutAdmin = 0;

      for (final doc in companiesSnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'active') {
          activeCompanies++;
        } else {
          inactiveCompanies++;
        }

        if (data['hasAdmin'] == true) {
          companiesWithAdmin++;
        } else {
          companiesWithoutAdmin++;
        }
      }

      // Admins actifs/inactifs
      final adminsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_compagnie')
          .get();

      int activeAdmins = 0;
      int inactiveAdmins = 0;
      int assignedAdmins = 0;
      int unassignedAdmins = 0;

      for (final doc in adminsSnapshot.docs) {
        final data = doc.data();
        if (data['isActive'] == true) {
          activeAdmins++;
        } else {
          inactiveAdmins++;
        }

        if (data['compagnieId'] != null) {
          assignedAdmins++;
        } else {
          unassignedAdmins++;
        }
      }

      return {
        'companies': {
          'total': companiesSnapshot.docs.length,
          'active': activeCompanies,
          'inactive': inactiveCompanies,
          'withAdmin': companiesWithAdmin,
          'withoutAdmin': companiesWithoutAdmin,
        },
        'admins': {
          'total': adminsSnapshot.docs.length,
          'active': activeAdmins,
          'inactive': inactiveAdmins,
          'assigned': assignedAdmins,
          'unassigned': unassignedAdmins,
        },
      };
    } catch (e) {
      debugPrint('[COMPANY_SYNC] ❌ Erreur statistiques: $e');
      return {};
    }
  }
}
