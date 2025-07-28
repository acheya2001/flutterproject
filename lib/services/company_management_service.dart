import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'company_admin_sync_service.dart';
import 'direct_admin_sync_service.dart';
import '../models/insurance_company.dart';

/// 🏢 Service centralisé pour la gestion des compagnies d'assurance
/// Évite les doublons et assure la cohérence des données
class CompanyManagementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'compagnies';

  /// 🔍 Vérifier et nettoyer les doublons
  static Future<Map<String, dynamic>> cleanDuplicates() async {
    try {
      debugPrint('[COMPANY_MANAGEMENT] 🧹 Début du nettoyage des doublons...');
      
      final snapshot = await _firestore.collection(_collection).get();
      final companies = <String, List<DocumentSnapshot>>{};
      
      // Grouper par nom
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final nom = data['nom'] as String?;
        if (nom != null) {
          companies[nom] = companies[nom] ?? [];
          companies[nom]!.add(doc);
        }
      }
      
      int duplicatesFound = 0;
      int duplicatesRemoved = 0;
      final List<String> cleanedCompanies = [];
      
      // Traiter les doublons
      for (var entry in companies.entries) {
        final companyName = entry.key;
        final docs = entry.value;
        
        if (docs.length > 1) {
          duplicatesFound += docs.length - 1;
          debugPrint('[COMPANY_MANAGEMENT] 🔍 Doublon trouvé: $companyName (${docs.length} copies)');
          
          // Garder le plus récent ou celui avec le plus de données
          var bestDoc = docs.first;
          var bestScore = _calculateDocumentScore(bestDoc.data() as Map<String, dynamic>);
          
          for (var doc in docs.skip(1)) {
            final score = _calculateDocumentScore(doc.data() as Map<String, dynamic>);
            if (score > bestScore) {
              bestDoc = doc;
              bestScore = score;
            }
          }
          
          // Supprimer les autres
          for (var doc in docs) {
            if (doc.id != bestDoc.id) {
              await doc.reference.delete();
              duplicatesRemoved++;
              debugPrint('[COMPANY_MANAGEMENT] 🗑️ Supprimé: ${doc.id}');
            }
          }
          
          cleanedCompanies.add(companyName);
        }
      }
      
      debugPrint('[COMPANY_MANAGEMENT] ✅ Nettoyage terminé: $duplicatesRemoved doublons supprimés');
      
      return {
        'success': true,
        'duplicatesFound': duplicatesFound,
        'duplicatesRemoved': duplicatesRemoved,
        'cleanedCompanies': cleanedCompanies,
        'totalCompanies': companies.length,
      };
    } catch (e) {
      debugPrint('[COMPANY_MANAGEMENT] ❌ Erreur nettoyage: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 📊 Calculer le score d'un document (pour choisir le meilleur en cas de doublon)
  static int _calculateDocumentScore(Map<String, dynamic> data) {
    int score = 0;
    
    // Points pour les champs remplis
    if (data['code'] != null && data['code'].toString().isNotEmpty) score += 10;
    if (data['adresse'] != null && data['adresse'].toString().isNotEmpty) score += 5;
    if (data['telephone'] != null && data['telephone'].toString().isNotEmpty) score += 5;
    if (data['email'] != null && data['email'].toString().isNotEmpty) score += 5;
    if (data['adminCompagnieId'] != null) score += 20; // Admin assigné = priorité
    if (data['createdAt'] != null) score += 3;
    if (data['updatedAt'] != null) score += 2;
    
    return score;
  }

  /// 🏢 Obtenir toutes les compagnies (version nettoyée)
  static Future<List<InsuranceCompany>> getAllCompanies() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('nom')
          .get();

      return snapshot.docs.map((doc) {
        try {
          return InsuranceCompany.fromFirestore(doc);
        } catch (e) {
          debugPrint('[COMPANY_MANAGEMENT] ⚠️ Erreur parsing compagnie ${doc.id}: $e');
          // Retourner une compagnie avec données minimales
          return InsuranceCompany.forSelection(
            id: doc.id,
            nom: doc.data()['nom'] ?? 'Nom non défini',
            code: doc.data()['code'],
            type: doc.data()['type'] ?? 'Classique',
          );
        }
      }).toList();
    } catch (e) {
      debugPrint('[COMPANY_MANAGEMENT] ❌ Erreur récupération compagnies: $e');
      return [];
    }
  }

  /// 🔍 Rechercher une compagnie par nom exact
  static Future<InsuranceCompany?> findCompanyByName(String name) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('nom', isEqualTo: name)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return InsuranceCompany.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('[COMPANY_MANAGEMENT] ❌ Erreur recherche par nom: $e');
      return null;
    }
  }

  /// 🔍 Rechercher une compagnie par ID
  static Future<InsuranceCompany?> findCompanyById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return InsuranceCompany.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('[COMPANY_MANAGEMENT] ❌ Erreur recherche par ID: $e');
      return null;
    }
  }

  /// 🏢 Obtenir les compagnies pour la sélection d'admin (avec statut admin)
  static Future<List<Map<String, dynamic>>> getCompaniesForAdminSelection() async {
    try {
      final companies = await getAllCompanies();
      final result = <Map<String, dynamic>>[];

      for (var company in companies) {
        // 🎯 VÉRIFICATION AMÉLIORÉE : Admin actif uniquement
        bool hasActiveAdmin = false;

        if (company.adminCompagnieId != null && company.adminCompagnieId!.isNotEmpty) {
          try {
            // Vérifier si l'admin existe et est actif
            final adminDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(company.adminCompagnieId)
                .get();
                ;
              



            if (adminDoc.exists) {
              final adminData = adminDoc.data()!;
              final isActive = adminData['isActive'] ?? false;
              final status = adminData['status'] ?? '';

              // Admin considéré comme actif seulement s'il est vraiment actif
              hasActiveAdmin = isActive && status == 'actif';

              debugPrint('[COMPANY_MANAGEMENT] 🏢 ${company.nom}: Admin ${hasActiveAdmin ? "ACTIF" : "INACTIF"}');
            } else {
              // L'admin n'existe plus, libérer la compagnie
              debugPrint('[COMPANY_MANAGEMENT] ⚠️ Admin ${company.adminCompagnieId} n\'existe plus pour ${company.nom}');

              // Nettoyer la référence dans la compagnie
              await FirebaseFirestore.instance
                  .collection('compagnies')
                  .doc(company.id)
                  .update({
                'adminCompagnieId': FieldValue.delete(),
                'adminCompagnieNom': FieldValue.delete(),
                'adminCompagnieEmail': FieldValue.delete(),
                'isAvailable': true,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          } catch (e) {
            debugPrint('[COMPANY_MANAGEMENT] ❌ Erreur vérification admin pour ${company.nom}: $e');
          }
        }

        result.add({
          'id': company.id,
          'nom': company.nom,
          'code': company.code,
          'type': company.type,
          'hasAdmin': hasActiveAdmin, // 🎯 Seulement les admins ACTIFS
          'adminCompagnieId': hasActiveAdmin ? company.adminCompagnieId : null,
          'adminCompagnieNom': hasActiveAdmin ? company.adminCompagnieNom : null,
          'adminCompagnieEmail': hasActiveAdmin ? company.adminCompagnieEmail : null,
          'isAvailable': !hasActiveAdmin, // Disponible si pas d'admin actif
        });
      }

      debugPrint('[COMPANY_MANAGEMENT] ✅ ${result.length} compagnies chargées pour sélection admin');
      final availableCount = result.where((c) => !c['hasAdmin']).length;
      debugPrint('[COMPANY_MANAGEMENT] 📊 $availableCount compagnies disponibles');

      return result;
    } catch (e) {
      debugPrint('[COMPANY_MANAGEMENT] ❌ Erreur sélection admin: $e');
      return [];
    }
  }

  /// 🆓 Obtenir seulement les compagnies disponibles (sans admin actif)
  static Future<List<Map<String, dynamic>>> getAvailableCompanies() async {
    try {
      final allCompanies = await getCompaniesForAdminSelection();

      // Filtrer seulement les compagnies disponibles
      final availableCompanies = allCompanies
          .where((company) => !company['hasAdmin'])
          .toList();

      debugPrint('[COMPANY_MANAGEMENT] 🆓 ${availableCompanies.length} compagnies disponibles trouvées');

      return availableCompanies;
    } catch (e) {
      debugPrint('[COMPANY_MANAGEMENT] ❌ Erreur compagnies disponibles: $e');
      return [];
    }
  }

  /// 📊 Obtenir les statistiques des compagnies
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final companies = await getCompaniesForAdminSelection();
      
      final totalCompanies = companies.length;
      final companiesWithAdmin = companies.where((c) => c['hasAdmin'] == true).length;
      final companiesWithoutAdmin = totalCompanies - companiesWithAdmin;
      final adminCoverage = totalCompanies > 0 ? (companiesWithAdmin / totalCompanies * 100).round() : 0;

      return {
        'totalCompanies': totalCompanies,
        'companiesWithAdmin': companiesWithAdmin,
        'companiesWithoutAdmin': companiesWithoutAdmin,
        'adminCoverage': adminCoverage,
      };
    } catch (e) {
      debugPrint('[COMPANY_MANAGEMENT] ❌ Erreur statistiques: $e');
      return {
        'totalCompanies': 0,
        'companiesWithAdmin': 0,
        'companiesWithoutAdmin': 0,
        'adminCoverage': 0,
      };
    }
  }

  /// 🔄 Mettre à jour l'admin d'une compagnie
  static Future<bool> updateCompanyAdmin({
    required String companyId,
    required String adminId,
    required String adminNom,
    required String adminEmail,
  }) async {
    try {
      await _firestore.collection(_collection).doc(companyId).update({
        'adminCompagnieId': adminId,
        'adminCompagnieNom': adminNom,
        'adminCompagnieEmail': adminEmail,
        'adminAssignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[COMPANY_MANAGEMENT] ✅ Admin assigné à la compagnie $companyId');
      return true;
    } catch (e) {
      debugPrint('[COMPANY_MANAGEMENT] ❌ Erreur assignation admin: $e');
      return false;
    }
  }

  /// 🗑️ Supprimer l'admin d'une compagnie
  static Future<bool> removeCompanyAdmin(String companyId) async {
    try {
      await _firestore.collection(_collection).doc(companyId).update({
        'adminCompagnieId': FieldValue.delete(),
        'adminCompagnieNom': FieldValue.delete(),
        'adminCompagnieEmail': FieldValue.delete(),
        'adminAssignedAt': FieldValue.delete(),
        'adminRemovedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[COMPANY_MANAGEMENT] ✅ Admin supprimé de la compagnie $companyId');
      return true;
    } catch (e) {
      debugPrint('[COMPANY_MANAGEMENT] ❌ Erreur suppression admin: $e');
      return false;
    }
  }

  /// 🔧 Initialiser les compagnies par défaut (si nécessaire)
  static Future<bool> initializeDefaultCompanies() async {
    try {
      final existingCompanies = await getAllCompanies();
      if (existingCompanies.isNotEmpty) {
        debugPrint('[COMPANY_MANAGEMENT] ℹ️ Compagnies déjà initialisées');
        return true;
      }

      debugPrint('[COMPANY_MANAGEMENT] 🚀 Initialisation des compagnies par défaut...');
      
      final defaultCompanies = TunisianInsuranceCompanies.getDefaultCompanies();
      final batch = _firestore.batch();

      for (var companyData in defaultCompanies) {
        final docRef = _firestore.collection(_collection).doc();
        batch.set(docRef, {
          ...companyData,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'status': 'active',
        });
      }

      await batch.commit();
      debugPrint('[COMPANY_MANAGEMENT] ✅ ${defaultCompanies.length} compagnies initialisées');
      return true;
    } catch (e) {
      debugPrint('[COMPANY_MANAGEMENT] ❌ Erreur initialisation: $e');
      return false;
    }
  }

  /// 🔍 Recherche intelligente de compagnie (par nom ou ID)
  static Future<InsuranceCompany?> smartFindCompany(String identifier) async {
    try {
      // Essayer d'abord par ID
      var company = await findCompanyById(identifier);
      if (company != null) return company;

      // Ensuite par nom exact
      company = await findCompanyByName(identifier);
      if (company != null) return company;

      // Recherche partielle par nom
      final snapshot = await _firestore
          .collection(_collection)
          .where('nom', isGreaterThanOrEqualTo: identifier)
          .where('nom', isLessThan: identifier + '\uf8ff')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return InsuranceCompany.fromFirestore(snapshot.docs.first);
      }

      return null;
    } catch (e) {
      debugPrint('[COMPANY_MANAGEMENT] ❌ Erreur recherche intelligente: $e');
      return null;
    }
  }

  /// 🔍 Diagnostic simple de la collection
  static Future<Map<String, dynamic>> diagnoseCollection() async {
    try {
      debugPrint('[COMPANY_MANAGEMENT] 🔍 Diagnostic de la collection $_collection');

      final snapshot = await _firestore.collection(_collection).get();

      debugPrint('[COMPANY_MANAGEMENT] 📊 ${snapshot.docs.length} documents trouvés');

      List<Map<String, dynamic>> companies = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        companies.add({
          'id': doc.id,
          'nom': data['nom'],
          'code': data['code'],
          'type': data['type'],
          'status': data['status'],
          'adminCompagnieId': data['adminCompagnieId'],
          'adminCompagnieNom': data['adminCompagnieNom'],
        });

        debugPrint('[COMPANY_MANAGEMENT] 📋 ${data['nom']} (${doc.id}) - Admin: ${data['adminCompagnieNom'] ?? 'AUCUN'}');
      }

      return {
        'success': true,
        'collection': _collection,
        'count': snapshot.docs.length,
        'companies': companies,
      };
    } catch (e) {
      debugPrint('[COMPANY_MANAGEMENT] ❌ Erreur diagnostic: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🏗️ Créer des compagnies par défaut si la collection est vide
  static Future<Map<String, dynamic>> createDefaultCompanies() async {
    try {
      debugPrint('[COMPANY_MANAGEMENT] 🏗️ Création des compagnies par défaut');

      // Vérifier si la collection est vide
      final snapshot = await _firestore.collection(_collection).get();
      if (snapshot.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'La collection contient déjà ${snapshot.docs.length} compagnies',
        };
      }

      // Compagnies par défaut
      final defaultCompanies = [
        {
          'nom': 'Assurances BIAT',
          'code': 'BIAT',
          'type': 'Classique',
          'email': 'contact@biat.com.tn',
          'telephone': '+216 71 340 000',
          'adresse': 'Avenue Habib Bourguiba, Tunis',
          'siteWeb': 'https://www.biat.com.tn',
          'status': 'actif',
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
        },
      ];

      List<String> createdCompanies = [];

      for (final companyData in defaultCompanies) {
        final docRef = await _firestore.collection(_collection).add({
          ...companyData,
          'adminCompagnieId': null,
          'adminCompagnieNom': null,
          'adminCompagnieEmail': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdBy': 'system_init',
        });

        createdCompanies.add('${companyData['nom']} (${docRef.id})');
        debugPrint('[COMPANY_MANAGEMENT] ✅ Créée: ${companyData['nom']}');
      }

      return {
        'success': true,
        'companiesCreated': createdCompanies.length,
        'createdCompanies': createdCompanies,
        'message': '${createdCompanies.length} compagnies créées avec succès',
      };
    } catch (e) {
      debugPrint('[COMPANY_MANAGEMENT] ❌ Erreur création: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🗑️ Vider toutes les compagnies de la collection
  static Future<Map<String, dynamic>> clearAllCompanies() async {
    try {
      debugPrint('[COMPANY_MANAGEMENT] 🗑️ Suppression de toutes les compagnies');

      // Récupérer toutes les compagnies
      final snapshot = await _firestore.collection(_collection).get();

      if (snapshot.docs.isEmpty) {
        return {
          'success': true,
          'message': 'La collection était déjà vide',
          'companiesDeleted': 0,
        };
      }

      debugPrint('[COMPANY_MANAGEMENT] 📊 ${snapshot.docs.length} compagnies à supprimer');

      // Supprimer toutes les compagnies
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        debugPrint('[COMPANY_MANAGEMENT] 🗑️ Suppression: ${doc.data()['nom']} (${doc.id})');
      }

      await batch.commit();

      debugPrint('[COMPANY_MANAGEMENT] ✅ ${snapshot.docs.length} compagnies supprimées');

      return {
        'success': true,
        'companiesDeleted': snapshot.docs.length,
        'message': '${snapshot.docs.length} compagnies supprimées avec succès',
      };
    } catch (e) {
      debugPrint('[COMPANY_MANAGEMENT] ❌ Erreur suppression: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🔄 Activer/Désactiver une compagnie avec synchronisation admin DIRECTE
  static Future<Map<String, dynamic>> toggleCompanyStatusWithSync({
    required String compagnieId,
    required bool newStatus,
  }) async {
    debugPrint('[COMPANY_MANAGEMENT] 🚀 Utilisation synchronisation DIRECTE');
    return await DirectAdminSyncService.syncCompanyToAdmin(
      compagnieId: compagnieId,
      newStatus: newStatus,
    );
  }

  /// 👤 Désactiver un admin pour permettre la réassignation
  static Future<Map<String, dynamic>> deactivateAdminForReassignment({
    required String adminId,
    required String compagnieId,
  }) async {
    return await CompanyAdminSyncService.deactivateAdminForReassignment(
      adminId: adminId,
      compagnieId: compagnieId,
    );
  }

  /// 🔄 Réassigner un admin à une compagnie
  static Future<Map<String, dynamic>> reassignAdminToCompany({
    required String newAdminId,
    required String compagnieId,
  }) async {
    return await CompanyAdminSyncService.reassignAdminToCompany(
      newAdminId: newAdminId,
      compagnieId: compagnieId,
    );
  }

  /// 📋 Obtenir les admins disponibles pour réassignation
  static Future<List<Map<String, dynamic>>> getAvailableAdminsForReassignment() async {
    return await CompanyAdminSyncService.getAvailableAdminsForReassignment();
  }
}
