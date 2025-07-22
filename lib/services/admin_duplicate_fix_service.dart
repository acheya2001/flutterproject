import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 🔧 Service pour corriger les doublons d'admins compagnie
class AdminDuplicateFixService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔍 Diagnostiquer les compagnies avec plusieurs admins
  static Future<Map<String, dynamic>> diagnoseMultipleAdmins() async {
    try {
      debugPrint('[ADMIN_DUPLICATE_FIX] 🔍 Début diagnostic doublons admins');

      // Récupérer tous les admins compagnie actifs
      final adminsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_compagnie')
          .where('isActive', isEqualTo: true)
          .get();

      debugPrint('[ADMIN_DUPLICATE_FIX] 📊 ${adminsSnapshot.docs.length} admins actifs trouvés');

      // Grouper par compagnieId
      final Map<String, List<Map<String, dynamic>>> adminsByCompany = {};
      
      for (final doc in adminsSnapshot.docs) {
        final data = doc.data();
        final compagnieId = data['compagnieId'] as String?;
        
        if (compagnieId != null && compagnieId.isNotEmpty) {
          adminsByCompany[compagnieId] = adminsByCompany[compagnieId] ?? [];
          adminsByCompany[compagnieId]!.add({
            'id': doc.id,
            'displayName': data['displayName'],
            'email': data['email'],
            'compagnieId': compagnieId,
            'compagnieNom': data['compagnieNom'],
            'createdAt': data['createdAt'],
            'isActive': data['isActive'],
          });
        }
      }

      // Identifier les compagnies avec plusieurs admins
      final List<Map<String, dynamic>> duplicateCompanies = [];
      int totalDuplicates = 0;

      for (final entry in adminsByCompany.entries) {
        final compagnieId = entry.key;
        final admins = entry.value;
        
        if (admins.length > 1) {
          debugPrint('[ADMIN_DUPLICATE_FIX] ⚠️ Compagnie $compagnieId a ${admins.length} admins actifs');
          
          duplicateCompanies.add({
            'compagnieId': compagnieId,
            'compagnieNom': admins.first['compagnieNom'],
            'adminsCount': admins.length,
            'admins': admins,
          });
          
          totalDuplicates += admins.length - 1; // -1 car on garde un admin
        }
      }

      debugPrint('[ADMIN_DUPLICATE_FIX] 📊 ${duplicateCompanies.length} compagnies avec doublons');

      return {
        'success': true,
        'totalActiveAdmins': adminsSnapshot.docs.length,
        'companiesWithDuplicates': duplicateCompanies.length,
        'totalDuplicatesToFix': totalDuplicates,
        'duplicateCompanies': duplicateCompanies,
        'adminsByCompany': adminsByCompany,
      };
    } catch (e) {
      debugPrint('[ADMIN_DUPLICATE_FIX] ❌ Erreur diagnostic: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🔧 Corriger les doublons d'admins (garder le plus récent)
  static Future<Map<String, dynamic>> fixDuplicateAdmins({
    bool dryRun = true,
  }) async {
    try {
      debugPrint('[ADMIN_DUPLICATE_FIX] 🔧 Début correction doublons (dryRun: $dryRun)');

      final diagnosis = await diagnoseMultipleAdmins();
      if (!diagnosis['success']) {
        return diagnosis;
      }

      final duplicateCompanies = diagnosis['duplicateCompanies'] as List<Map<String, dynamic>>;
      
      if (duplicateCompanies.isEmpty) {
        return {
          'success': true,
          'message': 'Aucun doublon trouvé',
          'fixedCompanies': 0,
          'deactivatedAdmins': 0,
        };
      }

      int fixedCompanies = 0;
      int deactivatedAdmins = 0;
      final List<Map<String, dynamic>> fixedDetails = [];

      for (final company in duplicateCompanies) {
        final compagnieId = company['compagnieId'] as String;
        final compagnieNom = company['compagnieNom'] as String;
        final admins = company['admins'] as List<Map<String, dynamic>>;

        debugPrint('[ADMIN_DUPLICATE_FIX] 🔧 Correction compagnie: $compagnieNom ($compagnieId)');

        // Trier les admins par date de création (plus récent en premier)
        admins.sort((a, b) {
          final aCreated = a['createdAt'] as Timestamp?;
          final bCreated = b['createdAt'] as Timestamp?;
          
          if (aCreated == null && bCreated == null) return 0;
          if (aCreated == null) return 1;
          if (bCreated == null) return -1;
          
          return bCreated.compareTo(aCreated); // Plus récent en premier
        });

        // Garder le premier (plus récent), désactiver les autres
        final adminToKeep = admins.first;
        final adminsToDeactivate = admins.skip(1).toList();

        debugPrint('[ADMIN_DUPLICATE_FIX] ✅ Garder: ${adminToKeep['displayName']} (${adminToKeep['email']})');

        final List<Map<String, dynamic>> deactivatedList = [];

        for (final admin in adminsToDeactivate) {
          debugPrint('[ADMIN_DUPLICATE_FIX] ⚠️ Désactiver: ${admin['displayName']} (${admin['email']})');
          
          if (!dryRun) {
            // Désactiver l'admin
            await _firestore.collection('users').doc(admin['id']).update({
              'isActive': false,
              'status': 'inactif',
              'deactivationReason': 'Désactivé automatiquement - doublon admin compagnie',
              'deactivatedAt': FieldValue.serverTimestamp(),
              'deactivatedBy': 'system_duplicate_fix',
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }

          deactivatedList.add({
            'id': admin['id'],
            'displayName': admin['displayName'],
            'email': admin['email'],
          });
          
          deactivatedAdmins++;
        }

        if (!dryRun) {
          // Mettre à jour la compagnie pour pointer vers le bon admin
          await _firestore.collection('compagnies').doc(compagnieId).update({
            'adminCompagnieId': adminToKeep['id'],
            'adminCompagnieNom': adminToKeep['displayName'],
            'adminCompagnieEmail': adminToKeep['email'],
            'hasAdmin': true,
            'adminStatus': 'active',
            'duplicateFixedAt': FieldValue.serverTimestamp(),
            'duplicateFixedBy': 'system_duplicate_fix',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        fixedDetails.add({
          'compagnieId': compagnieId,
          'compagnieNom': compagnieNom,
          'adminKept': {
            'id': adminToKeep['id'],
            'displayName': adminToKeep['displayName'],
            'email': adminToKeep['email'],
          },
          'adminsDeactivated': deactivatedList,
        });

        fixedCompanies++;
      }

      debugPrint('[ADMIN_DUPLICATE_FIX] ✅ Correction terminée: $fixedCompanies compagnies, $deactivatedAdmins admins désactivés');

      return {
        'success': true,
        'dryRun': dryRun,
        'fixedCompanies': fixedCompanies,
        'deactivatedAdmins': deactivatedAdmins,
        'fixedDetails': fixedDetails,
        'message': dryRun 
            ? 'Simulation: $fixedCompanies compagnies à corriger, $deactivatedAdmins admins à désactiver'
            : 'Correction appliquée: $fixedCompanies compagnies corrigées, $deactivatedAdmins admins désactivés',
      };
    } catch (e) {
      debugPrint('[ADMIN_DUPLICATE_FIX] ❌ Erreur correction: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🔧 Corriger un doublon spécifique pour une compagnie
  static Future<Map<String, dynamic>> fixSpecificCompanyDuplicate({
    required String compagnieId,
    required String adminToKeepId,
    bool dryRun = true,
  }) async {
    try {
      debugPrint('[ADMIN_DUPLICATE_FIX] 🔧 Correction spécifique compagnie: $compagnieId');

      // Récupérer tous les admins de cette compagnie
      final adminsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_compagnie')
          .where('compagnieId', isEqualTo: compagnieId)
          .where('isActive', isEqualTo: true)
          .get();

      if (adminsSnapshot.docs.length <= 1) {
        return {
          'success': true,
          'message': 'Aucun doublon trouvé pour cette compagnie',
        };
      }

      final List<Map<String, dynamic>> deactivatedAdmins = [];
      Map<String, dynamic>? keptAdmin;

      for (final doc in adminsSnapshot.docs) {
        final data = doc.data();
        
        if (doc.id == adminToKeepId) {
          keptAdmin = {
            'id': doc.id,
            'displayName': data['displayName'],
            'email': data['email'],
          };
        } else {
          // Désactiver cet admin
          if (!dryRun) {
            await _firestore.collection('users').doc(doc.id).update({
              'isActive': false,
              'status': 'inactif',
              'deactivationReason': 'Désactivé manuellement - doublon admin compagnie',
              'deactivatedAt': FieldValue.serverTimestamp(),
              'deactivatedBy': 'admin_manual_fix',
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }

          deactivatedAdmins.add({
            'id': doc.id,
            'displayName': data['displayName'],
            'email': data['email'],
          });
        }
      }

      if (!dryRun && keptAdmin != null) {
        // Mettre à jour la compagnie
        await _firestore.collection('compagnies').doc(compagnieId).update({
          'adminCompagnieId': keptAdmin['id'],
          'adminCompagnieNom': keptAdmin['displayName'],
          'adminCompagnieEmail': keptAdmin['email'],
          'hasAdmin': true,
          'adminStatus': 'active',
          'manualFixedAt': FieldValue.serverTimestamp(),
          'manualFixedBy': 'admin_manual_fix',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return {
        'success': true,
        'dryRun': dryRun,
        'compagnieId': compagnieId,
        'adminKept': keptAdmin,
        'adminsDeactivated': deactivatedAdmins,
        'message': dryRun 
            ? 'Simulation: ${deactivatedAdmins.length} admins à désactiver'
            : 'Correction appliquée: ${deactivatedAdmins.length} admins désactivés',
      };
    } catch (e) {
      debugPrint('[ADMIN_DUPLICATE_FIX] ❌ Erreur correction spécifique: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 📊 Obtenir les statistiques après correction
  static Future<Map<String, dynamic>> getPostFixStatistics() async {
    try {
      final diagnosis = await diagnoseMultipleAdmins();
      
      if (!diagnosis['success']) {
        return diagnosis;
      }

      final duplicateCompanies = diagnosis['duplicateCompanies'] as List<Map<String, dynamic>>;
      
      return {
        'success': true,
        'remainingDuplicates': duplicateCompanies.length,
        'totalActiveAdmins': diagnosis['totalActiveAdmins'],
        'isClean': duplicateCompanies.isEmpty,
        'message': duplicateCompanies.isEmpty 
            ? 'Toutes les compagnies ont un seul admin actif'
            : '${duplicateCompanies.length} compagnies ont encore des doublons',
      };
    } catch (e) {
      debugPrint('[ADMIN_DUPLICATE_FIX] ❌ Erreur statistiques: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
