import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 🧹 Service pour nettoyer et unifier les collections de compagnies
class DatabaseCleanupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🗑️ SUPPRESSION DÉFINITIVE - Vider toutes les collections de compagnies
  static Future<Map<String, dynamic>> clearAllCompanyCollections() async {
    try {
      debugPrint('[DATABASE_CLEANUP] 🗑️ SUPPRESSION DÉFINITIVE de toutes les compagnies');

      final collectionsToClean = [
        'compagnies',              // Gestion des Compagnies (12 compagnies)
        'compagnies_assurance',    // Gestion des Utilisateurs (7 compagnies)
        'companies',               // Anciennes collections
        'insurance_companies',     // Anciennes collections
        'company',                 // Autres variantes possibles
        'assurance_companies',     // Autres variantes possibles
      ];
      
      Map<String, int> deletedCounts = {};
      int totalDeleted = 0;
      
      for (final collectionName in collectionsToClean) {
        try {
          debugPrint('[DATABASE_CLEANUP] 🔍 Vérification collection: $collectionName');
          
          final snapshot = await _firestore.collection(collectionName).get();
          final count = snapshot.docs.length;
          
          if (count > 0) {
            debugPrint('[DATABASE_CLEANUP] 🗑️ Suppression de $count documents dans $collectionName');
            
            // Supprimer par batch pour éviter les timeouts
            final batch = _firestore.batch();
            for (final doc in snapshot.docs) {
              batch.delete(doc.reference);
            }
            await batch.commit();
            
            deletedCounts[collectionName] = count;
            totalDeleted += count;
            debugPrint('[DATABASE_CLEANUP] ✅ $count documents supprimés de $collectionName');
          } else {
            debugPrint('[DATABASE_CLEANUP] ℹ️ Collection $collectionName déjà vide');
            deletedCounts[collectionName] = 0;
          }
        } catch (e) {
          debugPrint('[DATABASE_CLEANUP] ⚠️ Erreur avec collection $collectionName: $e');
          deletedCounts[collectionName] = -1; // Marquer comme erreur
        }
      }
      
      debugPrint('[DATABASE_CLEANUP] 🎯 Nettoyage terminé: $totalDeleted documents supprimés');
      
      return {
        'success': true,
        'totalDeleted': totalDeleted,
        'deletedCounts': deletedCounts,
        'message': '$totalDeleted compagnies supprimées de toutes les collections',
      };
    } catch (e) {
      debugPrint('[DATABASE_CLEANUP] ❌ Erreur générale: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🗑️ Vider tous les admins compagnie
  static Future<Map<String, dynamic>> clearAllAdminCompagnie() async {
    try {
      debugPrint('[DATABASE_CLEANUP] 🧹 Suppression des admins compagnie');
      
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_compagnie')
          .get();
      
      if (snapshot.docs.isEmpty) {
        return {
          'success': true,
          'adminsDeleted': 0,
          'message': 'Aucun admin compagnie à supprimer',
        };
      }
      
      debugPrint('[DATABASE_CLEANUP] 🗑️ Suppression de ${snapshot.docs.length} admins compagnie');
      
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        debugPrint('[DATABASE_CLEANUP] 🗑️ Admin supprimé: ${doc.data()['displayName']} (${doc.id})');
      }
      await batch.commit();
      
      return {
        'success': true,
        'adminsDeleted': snapshot.docs.length,
        'message': '${snapshot.docs.length} admins compagnie supprimés',
      };
    } catch (e) {
      debugPrint('[DATABASE_CLEANUP] ❌ Erreur suppression admins: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🔄 Nettoyage complet (compagnies + admins)
  static Future<Map<String, dynamic>> fullCleanup() async {
    try {
      debugPrint('[DATABASE_CLEANUP] 🧹 NETTOYAGE COMPLET DÉMARRÉ');
      
      // Étape 1: Supprimer les admins compagnie
      final adminResult = await clearAllAdminCompagnie();
      
      // Étape 2: Supprimer toutes les compagnies
      final companyResult = await clearAllCompanyCollections();
      
      final totalDeleted = (adminResult['adminsDeleted'] ?? 0) + (companyResult['totalDeleted'] ?? 0);
      
      debugPrint('[DATABASE_CLEANUP] 🎯 NETTOYAGE COMPLET TERMINÉ');
      debugPrint('[DATABASE_CLEANUP] 📊 Total supprimé: $totalDeleted éléments');
      
      return {
        'success': true,
        'totalDeleted': totalDeleted,
        'adminsDeleted': adminResult['adminsDeleted'] ?? 0,
        'companiesDeleted': companyResult['totalDeleted'] ?? 0,
        'adminResult': adminResult,
        'companyResult': companyResult,
        'message': 'Nettoyage complet: $totalDeleted éléments supprimés',
      };
    } catch (e) {
      debugPrint('[DATABASE_CLEANUP] ❌ Erreur nettoyage complet: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 📊 Diagnostic des collections
  static Future<Map<String, dynamic>> diagnoseCollections() async {
    try {
      debugPrint('[DATABASE_CLEANUP] 🔍 Diagnostic des collections');
      
      final collectionsToCheck = [
        'compagnies',
        'compagnies_assurance',
        'companies',
        'insurance_companies',
        'users',
      ];
      
      Map<String, dynamic> diagnosis = {};
      
      for (final collectionName in collectionsToCheck) {
        try {
          final snapshot = await _firestore.collection(collectionName).get();
          final count = snapshot.docs.length;
          
          if (collectionName == 'users') {
            // Compter spécifiquement les admins compagnie
            final adminSnapshot = await _firestore
                .collection('users')
                .where('role', isEqualTo: 'admin_compagnie')
                .get();
            
            diagnosis[collectionName] = {
              'total': count,
              'adminCompagnie': adminSnapshot.docs.length,
            };
          } else {
            diagnosis[collectionName] = {
              'total': count,
              'documents': snapshot.docs.map((doc) => {
                'id': doc.id,
                'nom': doc.data()['nom'] ?? 'Sans nom',
              }).toList(),
            };
          }
          
          debugPrint('[DATABASE_CLEANUP] 📋 $collectionName: $count documents');
        } catch (e) {
          diagnosis[collectionName] = {
            'error': e.toString(),
          };
          debugPrint('[DATABASE_CLEANUP] ❌ Erreur $collectionName: $e');
        }
      }
      
      return {
        'success': true,
        'diagnosis': diagnosis,
      };
    } catch (e) {
      debugPrint('[DATABASE_CLEANUP] ❌ Erreur diagnostic: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🔧 Unifier vers une seule collection
  static Future<Map<String, dynamic>> unifyToSingleCollection({
    required String targetCollection,
  }) async {
    try {
      debugPrint('[DATABASE_CLEANUP] 🔄 Unification vers: $targetCollection');
      
      // D'abord nettoyer la collection cible
      final targetSnapshot = await _firestore.collection(targetCollection).get();
      if (targetSnapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in targetSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        debugPrint('[DATABASE_CLEANUP] 🗑️ Collection cible $targetCollection vidée');
      }
      
      return {
        'success': true,
        'message': 'Collection $targetCollection prête pour les nouvelles données',
        'targetCollection': targetCollection,
      };
    } catch (e) {
      debugPrint('[DATABASE_CLEANUP] ❌ Erreur unification: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🎯 SUPPRIMER UNIQUEMENT LES DONNÉES CRÉÉES PAR LE CODE
  static Future<Map<String, dynamic>> deleteCodeCreatedData() async {
    try {
      debugPrint('[DATABASE_CLEANUP] 🎯 SUPPRESSION DES DONNÉES CRÉÉES PAR LE CODE');

      int totalDeleted = 0;
      Map<String, int> deletedCounts = {};

      // 1. Supprimer les compagnies créées par le code (avec createdBy = 'system_init' ou 'super_admin')
      final collectionsToCheck = ['compagnies', 'compagnies_assurance'];

      for (final collectionName in collectionsToCheck) {
        try {
          debugPrint('[DATABASE_CLEANUP] 🔍 Vérification $collectionName pour données automatiques...');

          // Supprimer les compagnies créées automatiquement
          final autoSnapshot = await _firestore
              .collection(collectionName)
              .where('createdBy', whereIn: ['system_init', 'super_admin', 'auto_generated'])
              .get();

          if (autoSnapshot.docs.isNotEmpty) {
            final batch = _firestore.batch();
            for (final doc in autoSnapshot.docs) {
              batch.delete(doc.reference);
              final data = doc.data();
              debugPrint('[DATABASE_CLEANUP] 🗑️ Compagnie auto supprimée: ${data['nom']} (${doc.id})');
            }
            await batch.commit();
            deletedCounts['${collectionName}_auto'] = autoSnapshot.docs.length;
            totalDeleted += autoSnapshot.docs.length;
          }

          // Supprimer aussi les compagnies avec des noms génériques (créées par le code)
          final genericNames = [
            'Assurances BIAT',
            'Assurances Salim',
            'STAR Assurances',
            'AMI Assurances',
            'Zitouna Takaful',
            'BIAT Assurances',
            'Salim Assurances',
            'Test Company',
            'Compagnie Test',
          ];

          for (final name in genericNames) {
            final nameSnapshot = await _firestore
                .collection(collectionName)
                .where('nom', isEqualTo: name)
                .get();

            if (nameSnapshot.docs.isNotEmpty) {
              final batch = _firestore.batch();
              for (final doc in nameSnapshot.docs) {
                batch.delete(doc.reference);
                debugPrint('[DATABASE_CLEANUP] 🗑️ Compagnie générique supprimée: $name (${doc.id})');
              }
              await batch.commit();
              deletedCounts['${collectionName}_generic'] = nameSnapshot.docs.length;
              totalDeleted += nameSnapshot.docs.length;
            }
          }

        } catch (e) {
          debugPrint('[DATABASE_CLEANUP] ⚠️ Erreur avec $collectionName: $e');
        }
      }

      // 2. Supprimer les admins compagnie créés automatiquement
      final adminSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_compagnie')
          .where('source', isEqualTo: 'super_admin_creation')
          .get();

      if (adminSnapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in adminSnapshot.docs) {
          batch.delete(doc.reference);
          debugPrint('[DATABASE_CLEANUP] 🗑️ Admin auto supprimé: ${doc.data()['displayName']} (${doc.id})');
        }
        await batch.commit();
        deletedCounts['admins_auto'] = adminSnapshot.docs.length;
        totalDeleted += adminSnapshot.docs.length;
      }

      debugPrint('[DATABASE_CLEANUP] 🎯 SUPPRESSION CIBLÉE TERMINÉE');
      debugPrint('[DATABASE_CLEANUP] 📊 Total supprimé: $totalDeleted éléments automatiques');

      return {
        'success': true,
        'totalDeleted': totalDeleted,
        'deletedCounts': deletedCounts,
        'message': 'SUPPRESSION CIBLÉE: $totalDeleted éléments automatiques supprimés',
        'details': 'Seules les données créées par le code ont été supprimées',
      };
    } catch (e) {
      debugPrint('[DATABASE_CLEANUP] ❌ Erreur suppression ciblée: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🔥 SUPPRESSION AGRESSIVE - Supprimer TOUT sans exception
  static Future<Map<String, dynamic>> aggressiveCleanup() async {
    try {
      debugPrint('[DATABASE_CLEANUP] 🔥 SUPPRESSION AGRESSIVE DÉMARRÉE');

      int totalDeleted = 0;
      Map<String, int> deletedCounts = {};

      // 1. Supprimer TOUS les admins compagnie
      debugPrint('[DATABASE_CLEANUP] 🗑️ Suppression des admins compagnie...');
      final adminSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_compagnie')
          .get();

      if (adminSnapshot.docs.isNotEmpty) {
        final adminBatch = _firestore.batch();
        for (final doc in adminSnapshot.docs) {
          adminBatch.delete(doc.reference);
          debugPrint('[DATABASE_CLEANUP] 🗑️ Admin supprimé: ${doc.data()['displayName']} (${doc.id})');
        }
        await adminBatch.commit();
        deletedCounts['admins_compagnie'] = adminSnapshot.docs.length;
        totalDeleted += adminSnapshot.docs.length;
        debugPrint('[DATABASE_CLEANUP] ✅ ${adminSnapshot.docs.length} admins supprimés');
      }

      // 2. Supprimer TOUTES les collections de compagnies (même celles inconnues)
      final allCollections = [
        'compagnies',
        'compagnies_assurance',
        'companies',
        'insurance_companies',
        'company',
        'assurance_companies',
        'compagnie',
        'assurance',
        'insurances',
      ];

      for (final collectionName in allCollections) {
        try {
          debugPrint('[DATABASE_CLEANUP] 🔍 Vérification collection: $collectionName');
          final snapshot = await _firestore.collection(collectionName).get();

          if (snapshot.docs.isNotEmpty) {
            debugPrint('[DATABASE_CLEANUP] 🗑️ Suppression de ${snapshot.docs.length} documents dans $collectionName');

            // Supprimer par petits batches pour éviter les timeouts
            const batchSize = 500;
            for (int i = 0; i < snapshot.docs.length; i += batchSize) {
              final batch = _firestore.batch();
              final endIndex = (i + batchSize < snapshot.docs.length) ? i + batchSize : snapshot.docs.length;

              for (int j = i; j < endIndex; j++) {
                batch.delete(snapshot.docs[j].reference);
                final data = snapshot.docs[j].data() as Map<String, dynamic>?;
                debugPrint('[DATABASE_CLEANUP] 🗑️ Document supprimé: ${data?['nom'] ?? 'Sans nom'} (${snapshot.docs[j].id})');
              }

              await batch.commit();
              debugPrint('[DATABASE_CLEANUP] ✅ Batch ${(i ~/ batchSize) + 1} supprimé');
            }

            deletedCounts[collectionName] = snapshot.docs.length;
            totalDeleted += snapshot.docs.length;
            debugPrint('[DATABASE_CLEANUP] ✅ Collection $collectionName vidée: ${snapshot.docs.length} documents');
          } else {
            deletedCounts[collectionName] = 0;
            debugPrint('[DATABASE_CLEANUP] ℹ️ Collection $collectionName déjà vide');
          }
        } catch (e) {
          debugPrint('[DATABASE_CLEANUP] ⚠️ Erreur avec $collectionName: $e');
          deletedCounts[collectionName] = -1;
        }
      }

      debugPrint('[DATABASE_CLEANUP] 🎯 SUPPRESSION AGRESSIVE TERMINÉE');
      debugPrint('[DATABASE_CLEANUP] 📊 Total supprimé: $totalDeleted éléments');

      return {
        'success': true,
        'totalDeleted': totalDeleted,
        'deletedCounts': deletedCounts,
        'message': 'SUPPRESSION AGRESSIVE: $totalDeleted éléments supprimés définitivement',
        'details': 'Toutes les collections de compagnies et admins ont été vidées',
      };
    } catch (e) {
      debugPrint('[DATABASE_CLEANUP] ❌ Erreur suppression agressive: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
