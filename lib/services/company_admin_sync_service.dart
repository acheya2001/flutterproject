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

      // 1. Récupérer les informations de la compagnie d'abord
      final companyDoc = await _firestore.collection('compagnies').doc(compagnieId).get();
      if (!companyDoc.exists) {
        return {
          'success': false,
          'error': 'Compagnie non trouvée',
        };
      }

      final companyData = companyDoc.data()!;
      final companyName = companyData['nom'] as String?;

      debugPrint('[COMPANY_SYNC] 🏢 Compagnie: $companyName');

      // 2. Mettre à jour le statut de la compagnie
      await _firestore.collection('compagnies').doc(compagnieId).update({
        'status': newStatus ? 'active' : 'inactive',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': 'system_sync',
      });

      debugPrint('[COMPANY_SYNC] ✅ Compagnie mise à jour');

      // 3. Rechercher les admins de cette compagnie avec plusieurs stratégies
      final adminsToUpdate = await _findCompanyAdmins(compagnieId, companyName);

      debugPrint('[COMPANY_SYNC] 📊 ${adminsToUpdate.length} admins trouvés pour synchronisation');

      int adminsUpdated = 0;
      String adminInfo = 'Aucun admin trouvé';

      debugPrint('[COMPANY_SYNC] 🔄 Début mise à jour des admins: ${adminsToUpdate.length} admins à traiter');

      // 4. Mettre à jour le statut de TOUS les admins trouvés
      for (final adminData in adminsToUpdate) {
        final adminId = adminData['id'] as String;
        final currentStatus = adminData['isActive'] ?? false;

        debugPrint('[COMPANY_SYNC] 👤 Admin $adminId: statut actuel=$currentStatus, nouveau=$newStatus');

        await _firestore.collection('users').doc(adminId).update({
          'isActive': newStatus,
          'status': newStatus ? 'actif' : 'inactif',
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': 'system_sync',
          'syncReason': newStatus
              ? 'Réactivation automatique suite à réactivation compagnie'
              : 'Désactivation automatique suite à désactivation compagnie',
          'lastSyncAt': FieldValue.serverTimestamp(),
          'compagnieId': compagnieId, // S'assurer que le compagnieId est correct
        });

        adminsUpdated++;
        adminInfo = adminData['displayName'] ?? '${adminData['prenom']} ${adminData['nom']}';

        debugPrint('[COMPANY_SYNC] ✅ Admin synchronisé: $adminId - $adminInfo ($currentStatus → $newStatus)');
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

  /// 🔍 Trouver les admins d'une compagnie avec plusieurs stratégies
  static Future<List<Map<String, dynamic>>> _findCompanyAdmins(String compagnieId, String? companyName) async {
    final List<Map<String, dynamic>> foundAdmins = [];
    final Set<String> processedAdminIds = {};

    debugPrint('[COMPANY_SYNC] 🔍 Recherche admins pour compagnieId: $compagnieId, nom: $companyName');

    try {
      // Stratégie 1: Recherche par compagnieId
      final adminsByIdQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_compagnie')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      debugPrint('[COMPANY_SYNC] 📊 Stratégie 1 (compagnieId): ${adminsByIdQuery.docs.length} admins trouvés');

      for (final doc in adminsByIdQuery.docs) {
        if (!processedAdminIds.contains(doc.id)) {
          final data = doc.data();
          data['id'] = doc.id;
          foundAdmins.add(data);
          processedAdminIds.add(doc.id);
          debugPrint('[COMPANY_SYNC] 👤 Admin trouvé (ID): ${data['displayName']} (${doc.id})');
        }
      }

      // Stratégie 2: Recherche par nom de compagnie si fourni
      if (companyName != null && companyName.isNotEmpty) {
        final adminsByNameQuery = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'admin_compagnie')
            .where('compagnieNom', isEqualTo: companyName)
            .get();

        debugPrint('[COMPANY_SYNC] 📊 Stratégie 2 (nom): ${adminsByNameQuery.docs.length} admins trouvés');

        for (final doc in adminsByNameQuery.docs) {
          if (!processedAdminIds.contains(doc.id)) {
            final data = doc.data();
            data['id'] = doc.id;
            foundAdmins.add(data);
            processedAdminIds.add(doc.id);
            debugPrint('[COMPANY_SYNC] 👤 Admin trouvé (nom): ${data['displayName']} (${doc.id})');

            // Mettre à jour le compagnieId si nécessaire
            if (data['compagnieId'] != compagnieId) {
              await _firestore.collection('users').doc(doc.id).update({
                'compagnieId': compagnieId,
                'updatedAt': FieldValue.serverTimestamp(),
                'updatedBy': 'system_sync_fix',
              });
              debugPrint('[COMPANY_SYNC] 🔧 CompagnieId mis à jour pour admin: ${doc.id}');
            }
          }
        }
      }

      // Stratégie 3: Recherche dans la compagnie elle-même (adminCompagnieId)
      final companyDoc = await _firestore.collection('compagnies').doc(compagnieId).get();
      if (companyDoc.exists) {
        final companyData = companyDoc.data()!;
        final adminCompagnieId = companyData['adminCompagnieId'] as String?;

        if (adminCompagnieId != null && !processedAdminIds.contains(adminCompagnieId)) {
          debugPrint('[COMPANY_SYNC] 🔍 Stratégie 3: Vérification admin référencé: $adminCompagnieId');

          final adminDoc = await _firestore.collection('users').doc(adminCompagnieId).get();
          if (adminDoc.exists) {
            final data = adminDoc.data()!;
            if (data['role'] == 'admin_compagnie') {
              data['id'] = adminDoc.id;
              foundAdmins.add(data);
              processedAdminIds.add(adminDoc.id);
              debugPrint('[COMPANY_SYNC] 👤 Admin trouvé (référence): ${data['displayName']} (${adminDoc.id})');

              // Mettre à jour le compagnieId si nécessaire
              if (data['compagnieId'] != compagnieId) {
                await _firestore.collection('users').doc(adminDoc.id).update({
                  'compagnieId': compagnieId,
                  'updatedAt': FieldValue.serverTimestamp(),
                  'updatedBy': 'system_sync_fix',
                });
                debugPrint('[COMPANY_SYNC] 🔧 CompagnieId mis à jour pour admin référencé: ${adminDoc.id}');
              }
            }
          }
        }
      }

      debugPrint('[COMPANY_SYNC] ✅ Total admins trouvés: ${foundAdmins.length}');
      return foundAdmins;
    } catch (e) {
      debugPrint('[COMPANY_SYNC] ❌ Erreur recherche admins: $e');
      return [];
    }
  }
}
