import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 🔧 Service de synchronisation DIRECTE et SIMPLE compagnie-admin
class DirectAdminSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔄 Synchronisation DIRECTE compagnie → admin
  static Future<Map<String, dynamic>> syncCompanyToAdmin({
    required String compagnieId,
    required bool newStatus,
  }) async {
    try {
      debugPrint('[DIRECT_SYNC] 🚀 DÉBUT SYNCHRONISATION DIRECTE');
      debugPrint('[DIRECT_SYNC] 🏢 CompagnieId: $compagnieId');
      debugPrint('[DIRECT_SYNC] 📊 Nouveau statut: ${newStatus ? "ACTIF" : "INACTIF"}');

      // 1. Mettre à jour la compagnie
      await _firestore.collection('compagnies').doc(compagnieId).update({
        'status': newStatus ? 'active' : 'inactive',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': 'direct_sync',
      });

      debugPrint('[DIRECT_SYNC] ✅ Compagnie mise à jour');

      // 2. Récupérer TOUS les admins compagnie
      final allAdminsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_compagnie')
          .get();

      debugPrint('[DIRECT_SYNC] 📊 ${allAdminsQuery.docs.length} admins compagnie trouvés au total');

      int adminsUpdated = 0;
      List<String> updatedAdmins = [];

      // 3. Parcourir TOUS les admins et trouver ceux de cette compagnie
      for (final adminDoc in allAdminsQuery.docs) {
        final adminData = adminDoc.data();
        final adminCompagnieId = adminData['compagnieId'] as String?;
        final adminCompagnieNom = adminData['compagnieNom'] as String?;
        final adminDisplayName = adminData['displayName'] ?? '${adminData['prenom']} ${adminData['nom']}';

        debugPrint('[DIRECT_SYNC] 👤 Admin: $adminDisplayName');
        debugPrint('[DIRECT_SYNC]    CompagnieId: $adminCompagnieId');
        debugPrint('[DIRECT_SYNC]    CompagnieNom: $adminCompagnieNom');

        // Vérifier si cet admin appartient à cette compagnie
        bool belongsToCompany = false;
        
        if (adminCompagnieId == compagnieId) {
          belongsToCompany = true;
          debugPrint('[DIRECT_SYNC]    ✅ Correspond par compagnieId');
        }

        // Si pas trouvé par ID, vérifier par nom de compagnie
        if (!belongsToCompany && adminCompagnieNom != null) {
          // Récupérer le nom de la compagnie
          final companyDoc = await _firestore.collection('compagnies').doc(compagnieId).get();
          if (companyDoc.exists) {
            final companyName = companyDoc.data()!['nom'] as String?;
            if (companyName != null && adminCompagnieNom == companyName) {
              belongsToCompany = true;
              debugPrint('[DIRECT_SYNC]    ✅ Correspond par nom de compagnie');
              
              // Corriger le compagnieId
              await _firestore.collection('users').doc(adminDoc.id).update({
                'compagnieId': compagnieId,
                'updatedAt': FieldValue.serverTimestamp(),
                'updatedBy': 'direct_sync_fix',
              });
              debugPrint('[DIRECT_SYNC]    🔧 CompagnieId corrigé');
            }
          }
        }

        // Si cet admin appartient à cette compagnie, le synchroniser
        if (belongsToCompany) {
          final currentStatus = adminData['isActive'] ?? false;

          debugPrint('[DIRECT_SYNC]    🔄 SYNCHRONISATION DÉTAILLÉE:');
          debugPrint('[DIRECT_SYNC]       Admin ID: ${adminDoc.id}');
          debugPrint('[DIRECT_SYNC]       Statut actuel: $currentStatus');
          debugPrint('[DIRECT_SYNC]       Nouveau statut: $newStatus');
          debugPrint('[DIRECT_SYNC]       Action: ${newStatus ? 'ACTIVATION' : 'DÉSACTIVATION'}');

          // Forcer la mise à jour avec tous les champs nécessaires
          final updateData = {
            'isActive': newStatus,
            'status': newStatus ? 'actif' : 'inactif',
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': 'direct_sync_v2',
            'syncReason': newStatus
                ? 'RÉACTIVATION automatique suite à réactivation compagnie'
                : 'DÉSACTIVATION automatique suite à désactivation compagnie',
            'lastDirectSync': FieldValue.serverTimestamp(),
            'compagnieId': compagnieId, // S'assurer que c'est correct
            'syncAction': newStatus ? 'ACTIVATE' : 'DEACTIVATE',
            'syncTimestamp': DateTime.now().millisecondsSinceEpoch,
          };

          debugPrint('[DIRECT_SYNC]       Données à mettre à jour: $updateData');

          await _firestore.collection('users').doc(adminDoc.id).update(updateData);

          debugPrint('[DIRECT_SYNC]    ✅ MISE À JOUR FIRESTORE TERMINÉE');

          // Vérification immédiate de la mise à jour
          await Future.delayed(const Duration(milliseconds: 100));
          final verificationDoc = await _firestore.collection('users').doc(adminDoc.id).get();
          if (verificationDoc.exists) {
            final verificationData = verificationDoc.data()!;
            final verifiedStatus = verificationData['isActive'] ?? false;
            debugPrint('[DIRECT_SYNC]    🔍 VÉRIFICATION: Statut après mise à jour = $verifiedStatus');

            if (verifiedStatus == newStatus) {
              debugPrint('[DIRECT_SYNC]    ✅ VÉRIFICATION RÉUSSIE: Statut correctement mis à jour');
            } else {
              debugPrint('[DIRECT_SYNC]    ❌ VÉRIFICATION ÉCHOUÉE: Statut non mis à jour !');
              debugPrint('[DIRECT_SYNC]    ❌ Attendu: $newStatus, Trouvé: $verifiedStatus');
            }
          }

          adminsUpdated++;
          updatedAdmins.add('$adminDisplayName (${adminDoc.id})');

          debugPrint('[DIRECT_SYNC]    ✅ ADMIN SYNCHRONISÉ: $adminDisplayName');
        } else {
          debugPrint('[DIRECT_SYNC]    ⏭️ Admin ignoré (autre compagnie)');
        }
      }

      debugPrint('[DIRECT_SYNC] 🎯 RÉSULTAT: $adminsUpdated admins synchronisés');
      for (final admin in updatedAdmins) {
        debugPrint('[DIRECT_SYNC]    - $admin');
      }

      return {
        'success': true,
        'compagnieId': compagnieId,
        'newStatus': newStatus,
        'adminsUpdated': adminsUpdated,
        'updatedAdmins': updatedAdmins,
        'message': 'Synchronisation directe réussie: $adminsUpdated admin(s) ${newStatus ? "activé(s)" : "désactivé(s)"}',
      };
    } catch (e) {
      debugPrint('[DIRECT_SYNC] ❌ ERREUR: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🔍 Diagnostiquer les liaisons compagnie-admin
  static Future<Map<String, dynamic>> diagnoseCompanyAdminLinks() async {
    try {
      debugPrint('[DIRECT_SYNC] 🔍 DIAGNOSTIC DES LIAISONS');

      // Récupérer toutes les compagnies
      final companiesQuery = await _firestore.collection('compagnies').get();
      debugPrint('[DIRECT_SYNC] 🏢 ${companiesQuery.docs.length} compagnies trouvées');

      // Récupérer tous les admins compagnie
      final adminsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_compagnie')
          .get();
      debugPrint('[DIRECT_SYNC] 👤 ${adminsQuery.docs.length} admins compagnie trouvés');

      final List<Map<String, dynamic>> diagnosticResults = [];

      for (final companyDoc in companiesQuery.docs) {
        final companyData = companyDoc.data();
        final companyId = companyDoc.id;
        final companyName = companyData['nom'] as String?;
        final companyStatus = companyData['status'] ?? 'unknown';

        debugPrint('[DIRECT_SYNC] 🏢 Analyse: $companyName ($companyId)');

        // Trouver les admins de cette compagnie
        final companyAdmins = <Map<String, dynamic>>[];

        for (final adminDoc in adminsQuery.docs) {
          final adminData = adminDoc.data();
          final adminCompagnieId = adminData['compagnieId'] as String?;
          final adminCompagnieNom = adminData['compagnieNom'] as String?;
          final adminDisplayName = adminData['displayName'] ?? '${adminData['prenom']} ${adminData['nom']}';
          final adminStatus = adminData['isActive'] ?? false;

          bool belongsToThisCompany = false;
          String linkType = '';

          if (adminCompagnieId == companyId) {
            belongsToThisCompany = true;
            linkType = 'compagnieId';
          } else if (adminCompagnieNom == companyName) {
            belongsToThisCompany = true;
            linkType = 'compagnieNom';
          }

          if (belongsToThisCompany) {
            companyAdmins.add({
              'id': adminDoc.id,
              'displayName': adminDisplayName,
              'isActive': adminStatus,
              'linkType': linkType,
              'compagnieId': adminCompagnieId,
              'compagnieNom': adminCompagnieNom,
            });
          }
        }

        diagnosticResults.add({
          'companyId': companyId,
          'companyName': companyName,
          'companyStatus': companyStatus,
          'adminsCount': companyAdmins.length,
          'admins': companyAdmins,
          'hasIssues': companyAdmins.length != 1 || 
                      (companyAdmins.isNotEmpty && 
                       ((companyStatus == 'active' && !companyAdmins.first['isActive']) ||
                        (companyStatus == 'inactive' && companyAdmins.first['isActive']))),
        });

        debugPrint('[DIRECT_SYNC]    👥 ${companyAdmins.length} admin(s) trouvé(s)');
        for (final admin in companyAdmins) {
          debugPrint('[DIRECT_SYNC]       - ${admin['displayName']} (${admin['isActive'] ? 'ACTIF' : 'INACTIF'}) via ${admin['linkType']}');
        }
      }

      final issuesCount = diagnosticResults.where((r) => r['hasIssues'] == true).length;
      debugPrint('[DIRECT_SYNC] 🎯 DIAGNOSTIC TERMINÉ: $issuesCount compagnies avec problèmes');

      return {
        'success': true,
        'totalCompanies': companiesQuery.docs.length,
        'totalAdmins': adminsQuery.docs.length,
        'companiesWithIssues': issuesCount,
        'diagnosticResults': diagnosticResults,
      };
    } catch (e) {
      debugPrint('[DIRECT_SYNC] ❌ ERREUR DIAGNOSTIC: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🔧 Corriger toutes les liaisons cassées
  static Future<Map<String, dynamic>> fixAllBrokenLinks() async {
    try {
      debugPrint('[DIRECT_SYNC] 🔧 CORRECTION DE TOUTES LES LIAISONS');

      final diagnosis = await diagnoseCompanyAdminLinks();
      if (!diagnosis['success']) {
        return diagnosis;
      }

      final diagnosticResults = diagnosis['diagnosticResults'] as List<Map<String, dynamic>>;
      int fixedCompanies = 0;
      int fixedAdmins = 0;

      for (final result in diagnosticResults) {
        if (result['hasIssues'] == true) {
          final companyId = result['companyId'] as String;
          final companyStatus = result['companyStatus'] as String;
          final admins = result['admins'] as List<Map<String, dynamic>>;

          debugPrint('[DIRECT_SYNC] 🔧 Correction: ${result['companyName']}');

          for (final admin in admins) {
            final adminId = admin['id'] as String;
            final shouldBeActive = companyStatus == 'active';
            final currentlyActive = admin['isActive'] as bool;

            if (shouldBeActive != currentlyActive) {
              await _firestore.collection('users').doc(adminId).update({
                'isActive': shouldBeActive,
                'status': shouldBeActive ? 'actif' : 'inactif',
                'updatedAt': FieldValue.serverTimestamp(),
                'updatedBy': 'direct_sync_fix_all',
                'syncReason': 'Correction automatique des liaisons cassées',
                'compagnieId': companyId,
              });

              fixedAdmins++;
              debugPrint('[DIRECT_SYNC]    ✅ Admin ${admin['displayName']} corrigé: $currentlyActive → $shouldBeActive');
            }
          }

          fixedCompanies++;
        }
      }

      debugPrint('[DIRECT_SYNC] 🎯 CORRECTION TERMINÉE: $fixedCompanies compagnies, $fixedAdmins admins corrigés');

      return {
        'success': true,
        'fixedCompanies': fixedCompanies,
        'fixedAdmins': fixedAdmins,
        'message': 'Correction terminée: $fixedCompanies compagnies et $fixedAdmins admins corrigés',
      };
    } catch (e) {
      debugPrint('[DIRECT_SYNC] ❌ ERREUR CORRECTION: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
