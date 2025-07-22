import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 🏢 Service professionnel pour la gestion de la structure des compagnies
/// 
/// Structure de données:
/// - compagnies_assurance (collection principale)
///   - adminCompagnieId (ID unique de l'admin)
///   - adminCompagnieNom (nom complet de l'admin)
///   - adminCompagnieEmail (email de l'admin)
///   - agences (sous-collection)
///     - adminAgenceId
///     - agents (sous-collection)
class CompanyStructureService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📊 Obtenir les statistiques des compagnies avec leurs admins
  static Future<Map<String, dynamic>> getCompanyStatistics() async {
    try {
      final companiesSnapshot = await _firestore
          .collection('compagnies')
          .get();

      int totalCompanies = companiesSnapshot.docs.length;
      int companiesWithAdmin = 0;
      int companiesWithoutAdmin = 0;

      for (var doc in companiesSnapshot.docs) {
        final data = doc.data();
        if (data['adminCompagnieId'] != null && data['adminCompagnieId'].toString().isNotEmpty) {
          companiesWithAdmin++;
        } else {
          companiesWithoutAdmin++;
        }
      }

      return {
        'totalCompanies': totalCompanies,
        'companiesWithAdmin': companiesWithAdmin,
        'companiesWithoutAdmin': companiesWithoutAdmin,
        'adminCoverage': totalCompanies > 0 ? (companiesWithAdmin / totalCompanies * 100).round() : 0,
      };
    } catch (e) {
      debugPrint('[COMPANY_STRUCTURE] ❌ Erreur statistiques: $e');
      return {
        'totalCompanies': 0,
        'companiesWithAdmin': 0,
        'companiesWithoutAdmin': 0,
        'adminCoverage': 0,
      };
    }
  }

  /// 🏢 Obtenir toutes les compagnies avec leurs informations d'admin
  static Future<List<Map<String, dynamic>>> getCompaniesWithAdminInfo() async {
    try {
      final snapshot = await _firestore
          .collection('compagnies')
          .orderBy('nom')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'nom': data['nom'] ?? 'Nom non défini',
          'code': data['code'],
          'type': data['type'] ?? 'Classique',
          'adminCompagnieId': data['adminCompagnieId'],
          'adminCompagnieNom': data['adminCompagnieNom'],
          'adminCompagnieEmail': data['adminCompagnieEmail'],
          'hasAdmin': data['adminCompagnieId'] != null && data['adminCompagnieId'].toString().isNotEmpty,
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
        };
      }).toList();
    } catch (e) {
      debugPrint('[COMPANY_STRUCTURE] ❌ Erreur récupération compagnies: $e');
      return [];
    }
  }

  /// 🔍 Vérifier si une compagnie a déjà un admin
  static Future<bool> hasExistingAdmin(String compagnieId) async {
    try {
      final doc = await _firestore
          .collection('compagnies')
          .doc(compagnieId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final adminId = data['adminCompagnieId'];
        return adminId != null && adminId.toString().isNotEmpty;
      }
      return false;
    } catch (e) {
      debugPrint('[COMPANY_STRUCTURE] ❌ Erreur vérification admin: $e');
      return false;
    }
  }

  /// 🏢 Obtenir les compagnies sans admin (pour la sélection)
  static Future<List<Map<String, dynamic>>> getCompaniesWithoutAdmin() async {
    try {
      final snapshot = await _firestore
          .collection('compagnies')
          .get();

      final companiesWithoutAdmin = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final adminId = data['adminCompagnieId'];
        
        if (adminId == null || adminId.toString().isEmpty) {
          companiesWithoutAdmin.add({
            'id': doc.id,
            'nom': data['nom'] ?? 'Nom non défini',
            'code': data['code'],
            'type': data['type'] ?? 'Classique',
          });
        }
      }

      // Trier par nom
      companiesWithoutAdmin.sort((a, b) => a['nom'].compareTo(b['nom']));
      
      return companiesWithoutAdmin;
    } catch (e) {
      debugPrint('[COMPANY_STRUCTURE] ❌ Erreur compagnies sans admin: $e');
      return [];
    }
  }

  /// 🔄 Mettre à jour l'admin d'une compagnie
  static Future<bool> updateCompanyAdmin({
    required String compagnieId,
    required String adminId,
    required String adminNom,
    required String adminEmail,
  }) async {
    try {
      debugPrint('[COMPANY_STRUCTURE] 🔄 Début mise à jour admin compagnie');
      debugPrint('[COMPANY_STRUCTURE] 📋 Compagnie ID: $compagnieId');
      debugPrint('[COMPANY_STRUCTURE] 👤 Admin ID: $adminId');
      debugPrint('[COMPANY_STRUCTURE] 📧 Admin Email: $adminEmail');
      debugPrint('[COMPANY_STRUCTURE] 👤 Admin Nom: $adminNom');

      // Vérifier d'abord que la compagnie existe
      final companyDoc = await _firestore
          .collection('compagnies')
          .doc(compagnieId)
          .get();

      if (!companyDoc.exists) {
        debugPrint('[COMPANY_STRUCTURE] ❌ Compagnie non trouvée: $compagnieId');
        return false;
      }

      debugPrint('[COMPANY_STRUCTURE] ✅ Compagnie trouvée, mise à jour...');

      // Mettre à jour avec les informations de l'admin
      await _firestore
          .collection('compagnies')
          .doc(compagnieId)
          .update({
        'adminCompagnieId': adminId,
        'adminCompagnieNom': adminNom,
        'adminCompagnieEmail': adminEmail,
        'adminAssignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': adminId,
      });

      debugPrint('[COMPANY_STRUCTURE] ✅ Admin assigné à la compagnie $compagnieId');

      // Vérifier que la mise à jour a bien eu lieu
      final updatedDoc = await _firestore
          .collection('compagnies')
          .doc(compagnieId)
          .get();

      if (updatedDoc.exists) {
        final data = updatedDoc.data()!;
        debugPrint('[COMPANY_STRUCTURE] 🔍 Vérification - Admin ID: ${data['adminCompagnieId']}');
        debugPrint('[COMPANY_STRUCTURE] 🔍 Vérification - Admin Email: ${data['adminCompagnieEmail']}');
        debugPrint('[COMPANY_STRUCTURE] 🔍 Vérification - Admin Nom: ${data['adminCompagnieNom']}');
      }

      return true;
    } catch (e) {
      debugPrint('[COMPANY_STRUCTURE] ❌ Erreur assignation admin: $e');
      debugPrint('[COMPANY_STRUCTURE] ❌ Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// 🗑️ Supprimer l'admin d'une compagnie
  static Future<bool> removeCompanyAdmin(String compagnieId) async {
    try {
      await _firestore
          .collection('compagnies_assurance')
          .doc(compagnieId)
          .update({
        'adminCompagnieId': FieldValue.delete(),
        'adminCompagnieNom': FieldValue.delete(),
        'adminCompagnieEmail': FieldValue.delete(),
        'adminAssignedAt': FieldValue.delete(),
        'adminRemovedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[COMPANY_STRUCTURE] ✅ Admin supprimé de la compagnie $compagnieId');
      return true;
    } catch (e) {
      debugPrint('[COMPANY_STRUCTURE] ❌ Erreur suppression admin: $e');
      return false;
    }
  }

  /// 🔧 Corriger les liaisons admin-compagnie manquantes
  static Future<Map<String, dynamic>> fixMissingAdminLinks() async {
    try {
      debugPrint('[COMPANY_STRUCTURE] 🔧 Début correction liaisons admin-compagnie');

      int companiesFixed = 0;
      int companiesChecked = 0;
      List<String> errors = [];

      // Récupérer tous les admins compagnie
      final adminsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_compagnie')
          .where('status', isEqualTo: 'actif')
          .get();

      debugPrint('[COMPANY_STRUCTURE] 📊 ${adminsSnapshot.docs.length} admins compagnie trouvés');

      for (final adminDoc in adminsSnapshot.docs) {
        final adminData = adminDoc.data();
        final adminId = adminDoc.id;
        final compagnieId = adminData['compagnieId'] as String?;
        final adminEmail = adminData['email'] as String?;
        final adminNom = adminData['displayName'] as String?;
        final compagnieNom = adminData['compagnieNom'] as String?;

        debugPrint('[COMPANY_STRUCTURE] 🔍 Admin trouvé: $adminId');
        debugPrint('[COMPANY_STRUCTURE] 🔍 - Email: $adminEmail');
        debugPrint('[COMPANY_STRUCTURE] 🔍 - Nom: $adminNom');
        debugPrint('[COMPANY_STRUCTURE] 🔍 - CompagnieId: $compagnieId');
        debugPrint('[COMPANY_STRUCTURE] 🔍 - CompagnieNom: $compagnieNom');

        if (compagnieId == null || adminEmail == null || adminNom == null) {
          errors.add('Admin $adminId: données incomplètes (compagnieId: $compagnieId, email: $adminEmail, nom: $adminNom)');
          continue;
        }

        companiesChecked++;

        // Vérifier si la compagnie a les champs admin mis à jour
        debugPrint('[COMPANY_STRUCTURE] 🔍 Recherche compagnie: $compagnieId');
        final companyDoc = await _firestore
            .collection('compagnies')
            .doc(compagnieId)
            .get();

        if (!companyDoc.exists) {
          debugPrint('[COMPANY_STRUCTURE] ❌ Compagnie $compagnieId non trouvée pour admin $adminId');

          // Essayer de trouver la compagnie par nom
          if (compagnieNom != null) {
            debugPrint('[COMPANY_STRUCTURE] 🔍 Recherche par nom: $compagnieNom');
            final companiesByName = await _firestore
                .collection('compagnies')
                .where('nom', isEqualTo: compagnieNom)
                .get();

            if (companiesByName.docs.isNotEmpty) {
              final foundCompany = companiesByName.docs.first;
              final foundCompanyId = foundCompany.id;
              debugPrint('[COMPANY_STRUCTURE] ✅ Compagnie trouvée par nom: $foundCompanyId');

              // Mettre à jour l'admin avec le bon ID de compagnie
              await _firestore.collection('users').doc(adminId).update({
                'compagnieId': foundCompanyId,
                'updatedAt': FieldValue.serverTimestamp(),
              });

              // Continuer avec le bon ID
              final success = await updateCompanyAdmin(
                compagnieId: foundCompanyId,
                adminId: adminId,
                adminNom: adminNom,
                adminEmail: adminEmail,
              );

              if (success) {
                companiesFixed++;
                debugPrint('[COMPANY_STRUCTURE] ✅ Compagnie $foundCompanyId corrigée (trouvée par nom)');
              } else {
                errors.add('Échec correction compagnie $foundCompanyId (trouvée par nom)');
              }
              continue;
            }
          }

          errors.add('Compagnie $compagnieId non trouvée pour admin $adminId (nom: $compagnieNom)');
          continue;
        }

        final companyData = companyDoc.data()!;
        final currentAdminId = companyData['adminCompagnieId'] as String?;
        final currentAdminEmail = companyData['adminCompagnieEmail'] as String?;
        final currentAdminNom = companyData['adminCompagnieNom'] as String?;

        debugPrint('[COMPANY_STRUCTURE] 🔍 Compagnie trouvée: ${companyData['nom']}');
        debugPrint('[COMPANY_STRUCTURE] 🔍 - Admin actuel ID: $currentAdminId');
        debugPrint('[COMPANY_STRUCTURE] 🔍 - Admin actuel Email: $currentAdminEmail');
        debugPrint('[COMPANY_STRUCTURE] 🔍 - Admin actuel Nom: $currentAdminNom');

        // Si la compagnie n'a pas d'admin assigné ou si c'est différent
        if (currentAdminId == null || currentAdminId != adminId) {
          debugPrint('[COMPANY_STRUCTURE] 🔧 Correction nécessaire pour compagnie $compagnieId');
          debugPrint('[COMPANY_STRUCTURE] 🔧 - Admin attendu: $adminId');
          debugPrint('[COMPANY_STRUCTURE] 🔧 - Admin actuel: $currentAdminId');

          final success = await updateCompanyAdmin(
            compagnieId: compagnieId,
            adminId: adminId,
            adminNom: adminNom,
            adminEmail: adminEmail,
          );

          if (success) {
            companiesFixed++;
            debugPrint('[COMPANY_STRUCTURE] ✅ Compagnie $compagnieId corrigée');
          } else {
            errors.add('Échec correction compagnie $compagnieId');
          }
        } else {
          debugPrint('[COMPANY_STRUCTURE] ✅ Compagnie $compagnieId déjà correcte');
        }
      }

      debugPrint('[COMPANY_STRUCTURE] 🎯 Correction terminée: $companiesFixed/$companiesChecked compagnies corrigées');

      return {
        'success': true,
        'companiesChecked': companiesChecked,
        'companiesFixed': companiesFixed,
        'errors': errors,
        'message': '$companiesFixed compagnies corrigées sur $companiesChecked vérifiées',
      };
    } catch (e) {
      debugPrint('[COMPANY_STRUCTURE] ❌ Erreur correction liaisons: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 📋 Obtenir les informations complètes d'une compagnie
  static Future<Map<String, dynamic>?> getCompanyDetails(String compagnieId) async {
    try {
      final doc = await _firestore
          .collection('compagnies_assurance')
          .doc(compagnieId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return {
          'id': doc.id,
          'nom': data['nom'],
          'code': data['code'],
          'type': data['type'],
          'adminCompagnieId': data['adminCompagnieId'],
          'adminCompagnieNom': data['adminCompagnieNom'],
          'adminCompagnieEmail': data['adminCompagnieEmail'],
          'adminAssignedAt': data['adminAssignedAt'],
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
        };
      }
      return null;
    } catch (e) {
      debugPrint('[COMPANY_STRUCTURE] ❌ Erreur détails compagnie: $e');
      return null;
    }
  }

  /// 🔍 Rechercher une compagnie par nom ou code
  static Future<String?> findCompanyIdByName(String companyName) async {
    try {
      final snapshot = await _firestore
          .collection('compagnies_assurance')
          .where('nom', isEqualTo: companyName)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      debugPrint('[COMPANY_STRUCTURE] ❌ Erreur recherche compagnie: $e');
      return null;
    }
  }

  /// 📊 Obtenir le rapport complet des compagnies
  static Future<Map<String, dynamic>> getCompanyReport() async {
    try {
      final companies = await getCompaniesWithAdminInfo();
      final stats = await getCompanyStatistics();

      return {
        'statistics': stats,
        'companies': companies,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('[COMPANY_STRUCTURE] ❌ Erreur rapport: $e');
      return {
        'statistics': {
          'totalCompanies': 0,
          'companiesWithAdmin': 0,
          'companiesWithoutAdmin': 0,
          'adminCoverage': 0,
        },
        'companies': [],
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 🔍 Diagnostiquer les compagnies sans admin
  static Future<Map<String, dynamic>> diagnoseCompaniesWithoutAdmin() async {
    try {
      debugPrint('[COMPANY_STRUCTURE] 🔍 Diagnostic des compagnies sans admin');

      List<Map<String, dynamic>> companiesWithoutAdmin = [];
      List<Map<String, dynamic>> companiesWithAdmin = [];

      // Récupérer toutes les compagnies
      final companiesSnapshot = await _firestore
          .collection('compagnies_assurance')
          .get();

      debugPrint('[COMPANY_STRUCTURE] 📊 ${companiesSnapshot.docs.length} compagnies trouvées');

      for (final companyDoc in companiesSnapshot.docs) {
        final companyData = companyDoc.data();
        final companyId = companyDoc.id;
        final companyName = companyData['nom'] as String?;
        final adminId = companyData['adminCompagnieId'] as String?;
        final adminEmail = companyData['adminCompagnieEmail'] as String?;
        final adminNom = companyData['adminCompagnieNom'] as String?;

        final companyInfo = {
          'id': companyId,
          'nom': companyName,
          'adminCompagnieId': adminId,
          'adminCompagnieEmail': adminEmail,
          'adminCompagnieNom': adminNom,
          'status': companyData['status'],
          'type': companyData['type'],
        };

        if (adminId == null || adminId.isEmpty) {
          companiesWithoutAdmin.add(companyInfo);
          debugPrint('[COMPANY_STRUCTURE] ❌ Compagnie sans admin: $companyName (ID: $companyId)');
        } else {
          companiesWithAdmin.add(companyInfo);
          debugPrint('[COMPANY_STRUCTURE] ✅ Compagnie avec admin: $companyName (Admin: $adminNom)');
        }
      }

      debugPrint('[COMPANY_STRUCTURE] 📊 Résumé:');
      debugPrint('[COMPANY_STRUCTURE] 📊 - Compagnies avec admin: ${companiesWithAdmin.length}');
      debugPrint('[COMPANY_STRUCTURE] 📊 - Compagnies sans admin: ${companiesWithoutAdmin.length}');

      return {
        'success': true,
        'totalCompanies': companiesSnapshot.docs.length,
        'companiesWithAdmin': companiesWithAdmin,
        'companiesWithoutAdmin': companiesWithoutAdmin,
        'summary': {
          'withAdmin': companiesWithAdmin.length,
          'withoutAdmin': companiesWithoutAdmin.length,
        },
      };
    } catch (e) {
      debugPrint('[COMPANY_STRUCTURE] ❌ Erreur diagnostic: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🔍 Détecter les compagnies en double
  static Future<Map<String, dynamic>> detectDuplicateCompanies() async {
    try {
      debugPrint('[COMPANY_STRUCTURE] 🔍 Détection des compagnies en double');

      Map<String, List<Map<String, dynamic>>> companiesByName = {};
      List<Map<String, dynamic>> duplicates = [];

      // Récupérer toutes les compagnies
      final companiesSnapshot = await _firestore
          .collection('compagnies_assurance')
          .get();

      debugPrint('[COMPANY_STRUCTURE] 📊 ${companiesSnapshot.docs.length} compagnies trouvées');

      // Grouper par nom
      for (final companyDoc in companiesSnapshot.docs) {
        final companyData = companyDoc.data();
        final companyId = companyDoc.id;
        final companyName = companyData['nom'] as String?;

        if (companyName != null) {
          if (!companiesByName.containsKey(companyName)) {
            companiesByName[companyName] = [];
          }

          companiesByName[companyName]!.add({
            'id': companyId,
            'nom': companyName,
            'adminCompagnieId': companyData['adminCompagnieId'],
            'adminCompagnieEmail': companyData['adminCompagnieEmail'],
            'adminCompagnieNom': companyData['adminCompagnieNom'],
            'status': companyData['status'],
            'type': companyData['type'],
            'createdAt': companyData['createdAt'],
            'email': companyData['email'],
            'telephone': companyData['telephone'],
          });
        }
      }

      // Identifier les doublons
      for (final entry in companiesByName.entries) {
        final companyName = entry.key;
        final companies = entry.value;

        if (companies.length > 1) {
          debugPrint('[COMPANY_STRUCTURE] 🚨 Doublon détecté: $companyName (${companies.length} instances)');

          for (final company in companies) {
            debugPrint('[COMPANY_STRUCTURE] 📋 - ID: ${company['id']}, Admin: ${company['adminCompagnieNom'] ?? 'AUCUN'}');
          }

          duplicates.add({
            'nom': companyName,
            'count': companies.length,
            'companies': companies,
          });
        }
      }

      debugPrint('[COMPANY_STRUCTURE] 📊 ${duplicates.length} groupes de doublons trouvés');

      return {
        'success': true,
        'duplicatesCount': duplicates.length,
        'duplicates': duplicates,
        'totalCompanies': companiesSnapshot.docs.length,
        'uniqueNames': companiesByName.length,
      };
    } catch (e) {
      debugPrint('[COMPANY_STRUCTURE] ❌ Erreur détection doublons: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🔧 Corriger les doublons en fusionnant ou supprimant
  static Future<Map<String, dynamic>> fixDuplicateCompanies({
    required String keepCompanyId,
    required List<String> removeCompanyIds,
  }) async {
    try {
      debugPrint('[COMPANY_STRUCTURE] 🔧 Correction doublons');
      debugPrint('[COMPANY_STRUCTURE] 📋 Garder: $keepCompanyId');
      debugPrint('[COMPANY_STRUCTURE] 🗑️ Supprimer: $removeCompanyIds');

      int companiesRemoved = 0;
      List<String> errors = [];

      // Récupérer la compagnie à garder
      final keepCompanyDoc = await _firestore
          .collection('compagnies_assurance')
          .doc(keepCompanyId)
          .get();

      if (!keepCompanyDoc.exists) {
        throw Exception('Compagnie à garder non trouvée: $keepCompanyId');
      }

      final keepCompanyData = keepCompanyDoc.data()!;
      final keepCompanyName = keepCompanyData['nom'] as String;

      // Pour chaque compagnie à supprimer
      for (final removeId in removeCompanyIds) {
        try {
          // Vérifier s'il y a des admins qui pointent vers cette compagnie
          final adminsSnapshot = await _firestore
              .collection('users')
              .where('role', isEqualTo: 'admin_compagnie')
              .where('compagnieId', isEqualTo: removeId)
              .get();

          // Mettre à jour les admins pour qu'ils pointent vers la bonne compagnie
          for (final adminDoc in adminsSnapshot.docs) {
            await _firestore.collection('users').doc(adminDoc.id).update({
              'compagnieId': keepCompanyId,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            debugPrint('[COMPANY_STRUCTURE] ✅ Admin ${adminDoc.id} redirigé vers $keepCompanyId');
          }

          // Supprimer la compagnie en double
          await _firestore
              .collection('compagnies_assurance')
              .doc(removeId)
              .delete();

          companiesRemoved++;
          debugPrint('[COMPANY_STRUCTURE] ✅ Compagnie supprimée: $removeId');

        } catch (e) {
          errors.add('Erreur suppression $removeId: $e');
          debugPrint('[COMPANY_STRUCTURE] ❌ Erreur suppression $removeId: $e');
        }
      }

      return {
        'success': true,
        'companiesRemoved': companiesRemoved,
        'errors': errors,
        'keptCompany': keepCompanyId,
        'message': '$companiesRemoved compagnies supprimées, $keepCompanyId conservée',
      };
    } catch (e) {
      debugPrint('[COMPANY_STRUCTURE] ❌ Erreur correction doublons: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🔍 Chercher les compagnies dans toutes les collections possibles
  static Future<Map<String, dynamic>> findCompaniesInAllCollections() async {
    try {
      debugPrint('[COMPANY_STRUCTURE] 🔍 Recherche compagnies dans toutes les collections');

      Map<String, List<Map<String, dynamic>>> companiesByCollection = {};
      List<String> collectionsToCheck = [
        'compagnies_assurance',
        'compagnies',
        'companies',
        'insurance_companies',
        'assurance_companies',
      ];

      for (final collectionName in collectionsToCheck) {
        try {
          debugPrint('[COMPANY_STRUCTURE] 🔍 Vérification collection: $collectionName');

          final snapshot = await _firestore.collection(collectionName).get();

          if (snapshot.docs.isNotEmpty) {
            debugPrint('[COMPANY_STRUCTURE] ✅ Collection $collectionName: ${snapshot.docs.length} documents');

            List<Map<String, dynamic>> companies = [];
            for (final doc in snapshot.docs) {
              final data = doc.data();
              companies.add({
                'id': doc.id,
                'data': data,
                'nom': data['nom'] ?? data['name'] ?? 'Nom non défini',
                'adminCompagnieId': data['adminCompagnieId'],
                'adminCompagnieNom': data['adminCompagnieNom'],
                'adminCompagnieEmail': data['adminCompagnieEmail'],
              });
            }
            companiesByCollection[collectionName] = companies;
          } else {
            debugPrint('[COMPANY_STRUCTURE] ❌ Collection $collectionName: vide');
          }
        } catch (e) {
          debugPrint('[COMPANY_STRUCTURE] ❌ Erreur collection $collectionName: $e');
        }
      }

      // Chercher spécifiquement "Assurances BIAT"
      Map<String, dynamic> biatCompanies = {};
      for (final entry in companiesByCollection.entries) {
        final collectionName = entry.key;
        final companies = entry.value;

        final biatMatches = companies.where((company) =>
          company['nom'].toString().toLowerCase().contains('biat')).toList();

        if (biatMatches.isNotEmpty) {
          biatCompanies[collectionName] = biatMatches;
          debugPrint('[COMPANY_STRUCTURE] 🎯 BIAT trouvée dans $collectionName: ${biatMatches.length} matches');
        }
      }

      return {
        'success': true,
        'companiesByCollection': companiesByCollection,
        'biatCompanies': biatCompanies,
        'totalCollections': collectionsToCheck.length,
        'collectionsWithData': companiesByCollection.length,
      };
    } catch (e) {
      debugPrint('[COMPANY_STRUCTURE] ❌ Erreur recherche collections: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🔧 Mettre à jour la collection utilisée
  static String _currentCollection = 'compagnies';

  static void setCompanyCollection(String collectionName) {
    _currentCollection = collectionName;
    debugPrint('[COMPANY_STRUCTURE] 📋 Collection mise à jour: $collectionName');
  }

  static String getCurrentCollection() {
    return _currentCollection;
  }

  /// 🔄 Version mise à jour de updateCompanyAdmin avec collection dynamique
  static Future<bool> updateCompanyAdminDynamic({
    required String compagnieId,
    required String adminId,
    required String adminNom,
    required String adminEmail,
    String? collectionName,
  }) async {
    final collection = collectionName ?? _currentCollection;

    try {
      debugPrint('[COMPANY_STRUCTURE] 🔄 Mise à jour admin (collection: $collection)');
      debugPrint('[COMPANY_STRUCTURE] 📋 Compagnie ID: $compagnieId');
      debugPrint('[COMPANY_STRUCTURE] 👤 Admin ID: $adminId');

      // Vérifier que la compagnie existe
      final companyDoc = await _firestore
          .collection(collection)
          .doc(compagnieId)
          .get();

      if (!companyDoc.exists) {
        debugPrint('[COMPANY_STRUCTURE] ❌ Compagnie non trouvée dans $collection: $compagnieId');
        return false;
      }

      // Mettre à jour
      await _firestore
          .collection(collection)
          .doc(compagnieId)
          .update({
        'adminCompagnieId': adminId,
        'adminCompagnieNom': adminNom,
        'adminCompagnieEmail': adminEmail,
        'adminAssignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': adminId,
      });

      debugPrint('[COMPANY_STRUCTURE] ✅ Admin assigné dans $collection');
      return true;
    } catch (e) {
      debugPrint('[COMPANY_STRUCTURE] ❌ Erreur mise à jour $collection: $e');
      return false;
    }
  }

  /// 🏗️ Recréer la collection compagnies_assurance
  static Future<Map<String, dynamic>> recreateCompaniesCollection() async {
    try {
      debugPrint('[COMPANY_STRUCTURE] 🏗️ Recréation de la collection compagnies_assurance');

      // Données de base pour les compagnies d'assurance tunisiennes
      final List<Map<String, dynamic>> defaultCompanies = [
        {
          'nom': 'Assurances BIAT',
          'code': 'BIAT',
          'type': 'Classique',
          'email': 'contact@biat.com.tn',
          'telephone': '+216 71 340 000',
          'adresse': 'Avenue Habib Bourguiba, Tunis',
          'siteWeb': 'https://www.biat.com.tn',
          'status': 'actif',
          'adminCompagnieId': null,
          'adminCompagnieNom': null,
          'adminCompagnieEmail': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdBy': 'system_init',
        },
        {
          'nom': 'Assurances Salim',
          'code': 'SALIM',
          'type': 'Classique',
          'email': 'contact@salim.com.tn',
          'telephone': '+216 71 123 456',
          'adresse': 'Avenue de la Liberté, Tunis',
          'siteWeb': 'https://www.salim.com.tn',
          'status': 'actif',
          'adminCompagnieId': null,
          'adminCompagnieNom': null,
          'adminCompagnieEmail': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdBy': 'system_init',
        },
        {
          'nom': 'STAR Assurances',
          'code': 'STAR',
          'type': 'Classique',
          'email': 'contact@star.com.tn',
          'telephone': '+216 71 789 012',
          'adresse': 'Rue de la République, Tunis',
          'siteWeb': 'https://www.star.com.tn',
          'status': 'actif',
          'adminCompagnieId': null,
          'adminCompagnieNom': null,
          'adminCompagnieEmail': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdBy': 'system_init',
        },
        {
          'nom': 'AMI Assurances',
          'code': 'AMI',
          'type': 'Classique',
          'email': 'contact@ami.com.tn',
          'telephone': '+216 71 456 789',
          'adresse': 'Avenue Bourguiba, Tunis',
          'siteWeb': 'https://www.ami.com.tn',
          'status': 'actif',
          'adminCompagnieId': null,
          'adminCompagnieNom': null,
          'adminCompagnieEmail': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdBy': 'system_init',
        },
        {
          'nom': 'Zitouna Takaful',
          'code': 'ZITOUNA',
          'type': 'Takaful',
          'email': 'contact@zitouna-takaful.com.tn',
          'telephone': '+216 71 654 321',
          'adresse': 'Avenue Mohamed V, Tunis',
          'siteWeb': 'https://www.zitouna-takaful.com.tn',
          'status': 'actif',
          'adminCompagnieId': null,
          'adminCompagnieNom': null,
          'adminCompagnieEmail': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdBy': 'system_init',
        },
      ];

      List<String> createdCompanies = [];
      List<String> errors = [];

      // Créer chaque compagnie
      for (final companyData in defaultCompanies) {
        try {
          final docRef = await _firestore
              .collection('compagnies_assurance')
              .add(companyData);

          createdCompanies.add('${companyData['nom']} (ID: ${docRef.id})');
          debugPrint('[COMPANY_STRUCTURE] ✅ Compagnie créée: ${companyData['nom']} (${docRef.id})');
        } catch (e) {
          errors.add('Erreur création ${companyData['nom']}: $e');
          debugPrint('[COMPANY_STRUCTURE] ❌ Erreur création ${companyData['nom']}: $e');
        }
      }

      debugPrint('[COMPANY_STRUCTURE] 🎯 Collection recréée: ${createdCompanies.length}/${defaultCompanies.length} compagnies');

      return {
        'success': true,
        'companiesCreated': createdCompanies.length,
        'totalCompanies': defaultCompanies.length,
        'createdCompanies': createdCompanies,
        'errors': errors,
        'message': '${createdCompanies.length} compagnies créées avec succès',
      };
    } catch (e) {
      debugPrint('[COMPANY_STRUCTURE] ❌ Erreur recréation collection: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🔄 Migrer les admins existants vers les nouvelles compagnies
  static Future<Map<String, dynamic>> migrateExistingAdmins() async {
    try {
      debugPrint('[COMPANY_STRUCTURE] 🔄 Migration des admins existants');

      // Récupérer tous les admins compagnie
      final adminsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_compagnie')
          .get();

      if (adminsSnapshot.docs.isEmpty) {
        return {
          'success': true,
          'message': 'Aucun admin à migrer',
          'adminsMigrated': 0,
        };
      }

      List<String> migratedAdmins = [];
      List<String> errors = [];

      for (final adminDoc in adminsSnapshot.docs) {
        final adminData = adminDoc.data();
        final adminId = adminDoc.id;
        final compagnieNom = adminData['compagnieNom'] as String?;
        final adminEmail = adminData['email'] as String?;
        final adminDisplayName = adminData['displayName'] as String?;

        if (compagnieNom == null || adminEmail == null || adminDisplayName == null) {
          errors.add('Admin $adminId: données incomplètes');
          continue;
        }

        try {
          // Chercher la compagnie par nom
          final companiesSnapshot = await _firestore
              .collection('compagnies_assurance')
              .where('nom', isEqualTo: compagnieNom)
              .limit(1)
              .get();

          if (companiesSnapshot.docs.isNotEmpty) {
            final companyDoc = companiesSnapshot.docs.first;
            final companyId = companyDoc.id;

            // Mettre à jour l'admin avec le bon ID de compagnie
            await _firestore.collection('users').doc(adminId).update({
              'compagnieId': companyId,
              'updatedAt': FieldValue.serverTimestamp(),
            });

            // Mettre à jour la compagnie avec l'admin
            await _firestore.collection('compagnies_assurance').doc(companyId).update({
              'adminCompagnieId': adminId,
              'adminCompagnieNom': adminDisplayName,
              'adminCompagnieEmail': adminEmail,
              'adminAssignedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

            migratedAdmins.add('$adminDisplayName → $compagnieNom');
            debugPrint('[COMPANY_STRUCTURE] ✅ Admin migré: $adminDisplayName → $compagnieNom');
          } else {
            errors.add('Compagnie non trouvée pour admin $adminDisplayName: $compagnieNom');
          }
        } catch (e) {
          errors.add('Erreur migration admin $adminId: $e');
        }
      }

      return {
        'success': true,
        'adminsMigrated': migratedAdmins.length,
        'totalAdmins': adminsSnapshot.docs.length,
        'migratedAdmins': migratedAdmins,
        'errors': errors,
        'message': '${migratedAdmins.length} admins migrés avec succès',
      };
    } catch (e) {
      debugPrint('[COMPANY_STRUCTURE] ❌ Erreur migration admins: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
