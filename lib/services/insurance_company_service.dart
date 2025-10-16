import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/insurance_company.dart';

/// 🏢 Service de gestion des compagnies d'assurance
class InsuranceCompanyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 📋 Obtenir toutes les compagnies (Stream)
  static Stream<List<InsuranceCompany>> getAllCompanies() {
    return _firestore
        .collection('compagnies')
        .orderBy('nom')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InsuranceCompany.fromFirestore(doc))
            .toList());
  }

  /// 📋 Obtenir toutes les compagnies (Future)
  static Future<List<InsuranceCompany>> getAllCompaniesFuture() async {
    try {
      final snapshot = await _firestore
          .collection('compagnies')
          .orderBy('nom')
          .get();

      return snapshot.docs
          .map((doc) => InsuranceCompany.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Erreur lors du chargement des compagnies: $e');
      return [];
    }
  }

  /// 🔍 Obtenir une compagnie par ID
  static Future<InsuranceCompany?> getCompanyById(String id) async {
    try {
      final doc = await _firestore.collection('compagnies').doc(id).get();
      if (doc.exists) {
        return InsuranceCompany.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('[COMPANY_SERVICE] ❌ Erreur lors de la récupération: $e');
      return null;
    }
  }

  /// ➕ Créer une nouvelle compagnie
  static Future<String?> createCompany(InsuranceCompany company) async {
    try {
      // Générer un code unique pour la compagnie
      final code = await _generateCompanyCode(company.nom);

      final docRef = await _firestore.collection('compagnies').add({
        ...company.toFirestore(),
        'code': code,
        'createdBy': _auth.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[COMPANY_SERVICE] ✅ Compagnie créée: ${company.nom} (Code: $code)');
      return docRef.id;
    } catch (e) {
      debugPrint('[COMPANY_SERVICE] ❌ Erreur lors de la création: $e');
      rethrow;
    }
  }

  /// ✏️ Mettre à jour une compagnie
  static Future<void> updateCompany(String id, InsuranceCompany company) async {
    try {
      await _firestore.collection('compagnies').doc(id).update({
        ...company.toFirestore(),
        'updatedBy': _auth.currentUser?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[COMPANY_SERVICE] ✅ Compagnie mise à jour: ${company.nom}');
    } catch (e) {
      debugPrint('[COMPANY_SERVICE] ❌ Erreur lors de la mise à jour: $e');
      rethrow;
    }
  }

  /// 🔄 Changer le statut d'une compagnie
  static Future<void> toggleCompanyStatus(String id, String newStatus) async {
    try {
      await _firestore.collection('compagnies').doc(id).update({
        'status': newStatus,
        'updatedBy': _auth.currentUser?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[COMPANY_SERVICE] ✅ Statut changé: $newStatus');
    } catch (e) {
      debugPrint('[COMPANY_SERVICE] ❌ Erreur lors du changement de statut: $e');
      rethrow;
    }
  }

  /// 🗑️ Supprimer une compagnie
  static Future<void> deleteCompany(String id) async {
    try {
      // Vérifier s'il y a des utilisateurs liés
      final usersQuery = await _firestore
          .collection('users')
          .where('compagnieId', isEqualTo: id)
          .get();

      if (usersQuery.docs.isNotEmpty) {
        throw Exception('Impossible de supprimer: ${usersQuery.docs.length} utilisateur(s) lié(s) à cette compagnie');
      }

      await _firestore.collection('compagnies').doc(id).delete();
      debugPrint('[COMPANY_SERVICE] ✅ Compagnie supprimée');
    } catch (e) {
      debugPrint('[COMPANY_SERVICE] ❌ Erreur lors de la suppression: $e');
      rethrow;
    }
  }

  /// 🔢 Générer un code unique pour la compagnie
  static Future<String> _generateCompanyCode(String nom) async {
    // Prendre les 3 premières lettres du nom en majuscules
    String baseCode = nom.replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
    if (baseCode.length >= 3) {
      baseCode = baseCode.substring(0, 3);
    } else {
      baseCode = baseCode.padRight(3, 'X');
    }

    // Vérifier l'unicité et ajouter un numéro si nécessaire
    int counter = 1;
    String code = baseCode;

    while (await _codeExists(code)) {
      code = '$baseCode${counter.toString().padLeft(2, '0')}';
      counter++;
    }

    return code;
  }

  /// 🔍 Vérifier si un code existe déjà
  static Future<bool> _codeExists(String code) async {
    final query = await _firestore
        .collection('compagnies')
        .where('code', isEqualTo: code)
        .get();
    return query.docs.isNotEmpty;
  }



  /// 👤 Associer un admin à une compagnie
  static Future<void> assignAdminToCompany(
    String companyId,
    String adminId,
    String adminEmail,
    String adminNom,
  ) async {
    try {
      // Mettre à jour la compagnie
      await _firestore.collection('compagnies').doc(companyId).update({
        'adminCompagnieId': adminId,
        'adminCompagnieEmail': adminEmail,
        'adminCompagnieNom': adminNom,
        'adminAssignedAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour l'utilisateur admin
      await _firestore.collection('users').doc(adminId).update({
        'compagnieId': companyId,
        'assignedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[COMPANY_SERVICE] ✅ Admin assigné à la compagnie');
    } catch (e) {
      debugPrint('[COMPANY_SERVICE] ❌ Erreur lors de l\'assignation: $e');
      rethrow;
    }
  }

  /// 🔄 Ajouter des codes aux compagnies existantes (migration)
  static Future<void> addCodesToExistingCompanies() async {
    try {
      debugPrint('[COMPANY_SERVICE] 🔄 Début de la migration des codes...');

      // Récupérer toutes les compagnies sans code
      final query = await _firestore
          .collection('compagnies')
          .where('code', isNull: true)
          .get();

      if (query.docs.isEmpty) {
        debugPrint('[COMPANY_SERVICE] ✅ Toutes les compagnies ont déjà un code');
        return;
      }

      int updated = 0;
      for (final doc in query.docs) {
        try {
          final data = doc.data();
          final nom = data['nom'] as String? ?? 'Compagnie';

          // Générer un code pour cette compagnie
          final code = await _generateCompanyCode(nom);

          // Mettre à jour le document
          await doc.reference.update({
            'code': code,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          updated++;
          debugPrint('[COMPANY_SERVICE] ✅ Code ajouté: $nom -> $code');
        } catch (e) {
          debugPrint('[COMPANY_SERVICE] ❌ Erreur pour ${doc.id}: $e');
        }
      }

      debugPrint('[COMPANY_SERVICE] ✅ Migration terminée: $updated compagnies mises à jour');
    } catch (e) {
      debugPrint('[COMPANY_SERVICE] ❌ Erreur lors de la migration: $e');
      rethrow;
    }
  }

  /// 📊 Obtenir les statistiques du système
  static Future<SystemStats> getSystemStats() async {
    try {
      // Compagnies
      final companiesSnapshot = await _firestore.collection('compagnies').get();
      final activeCompanies = companiesSnapshot.docs
          .where((doc) => doc.data()['status'] == 'active')
          .length;

      // Utilisateurs
      final usersSnapshot = await _firestore.collection('users').get();
      final users = usersSnapshot.docs.map((doc) => doc.data()).toList();

      // Sinistres (si collection existe)
      final sinistresSnapshot = await _firestore.collection('sinistres').get();
      final sinistres = sinistresSnapshot.docs.map((doc) => doc.data()).toList();

      // Compter les utilisateurs actifs par rôle
      final activeUsers = users.where((u) => u['isActive'] == true || u['status'] == 'actif').toList();

      debugPrint('[COMPANY_SERVICE] 📊 Utilisateurs actifs trouvés: ${activeUsers.length}');
      debugPrint('[COMPANY_SERVICE] 🔍 Rôles disponibles: ${users.map((u) => u['role']).toSet().toList()}');

      // Compter les experts (différents rôles possibles)
      final expertsCount = activeUsers.where((u) =>
        u['role'] == 'expert' ||
        u['role'] == 'expert_auto' ||
        u['role'] == 'expert_automobile'
      ).length;

      // Compter les agents
      final agentsCount = activeUsers.where((u) =>
        u['role'] == 'agent' ||
        u['role'] == 'agent_agence' ||
        u['role'] == 'agent_assurance'
      ).length;

      debugPrint('[COMPANY_SERVICE] 👥 Experts trouvés: $expertsCount');
      debugPrint('[COMPANY_SERVICE] 🏢 Agents trouvés: $agentsCount');
      debugPrint('[COMPANY_SERVICE] 📋 Sinistres trouvés: ${sinistres.length}');

      return SystemStats(
        totalCompagnies: companiesSnapshot.docs.length,
        compagniesActives: activeCompanies,
        totalUtilisateurs: users.length,
        adminCompagnies: activeUsers.where((u) => u['role'] == 'admin_compagnie').length,
        adminAgences: activeUsers.where((u) => u['role'] == 'admin_agence').length,
        agents: agentsCount,
        experts: expertsCount,
        conducteurs: activeUsers.where((u) => u['role'] == 'conducteur').length,
        totalSinistres: sinistres.length,
        sinistresEnCours: sinistres.where((s) => s['status'] == 'en_cours' || s['status'] == 'ouvert').length,
        sinistresTraites: sinistres.where((s) => s['status'] == 'traite' || s['status'] == 'clos').length,
      );
    } catch (e) {
      debugPrint('[COMPANY_SERVICE] ❌ Erreur lors du calcul des stats: $e');
      return SystemStats();
    }
  }

  /// 🚀 Initialiser les compagnies par défaut
  static Future<void> initializeDefaultCompanies() async {
    try {
      final existingCompanies = await _firestore.collection('compagnies').get();
      
      if (existingCompanies.docs.isEmpty) {
        debugPrint('[COMPANY_SERVICE] 🔧 Initialisation des compagnies par défaut...');
        
        final defaultCompanies = TunisianInsuranceCompanies.getDefaultCompanies();
        
        for (final companyData in defaultCompanies) {
          final company = InsuranceCompany(
            id: '', // Sera généré par Firestore
            nom: companyData['nom'],
            adresse: companyData['adresse'],
            telephone: companyData['telephone'],
            email: companyData['email'],
            siteWeb: companyData['siteWeb'],
            type: companyData['type'],
            createdAt: DateTime.now(),
          );
          
          await createCompany(company);
        }
        
        debugPrint('[COMPANY_SERVICE] ✅ Compagnies par défaut créées');
      }
    } catch (e) {
      debugPrint('[COMPANY_SERVICE] ❌ Erreur lors de l\'initialisation: $e');
    }
  }

  /// 🔒 Désactiver tous les utilisateurs d'une compagnie
  static Future<void> _deactivateCompanyUsers(String companyId) async {
    try {
      final usersSnapshot = await _firestore
          .collection('users')
          .where('compagnieId', isEqualTo: companyId)
          .get();

      final batch = _firestore.batch();
      for (final doc in usersSnapshot.docs) {
        batch.update(doc.reference, {
          'status': 'inactive',
          'deactivatedBy': 'company_deactivation',
          'deactivatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[COMPANY_SERVICE] ❌ Erreur désactivation utilisateurs: $e');
    }
  }

  /// 🔓 Réactiver tous les utilisateurs d'une compagnie
  static Future<void> _reactivateCompanyUsers(String companyId) async {
    try {
      final usersSnapshot = await _firestore
          .collection('users')
          .where('compagnieId', isEqualTo: companyId)
          .where('deactivatedBy', isEqualTo: 'company_deactivation')
          .get();

      final batch = _firestore.batch();
      for (final doc in usersSnapshot.docs) {
        batch.update(doc.reference, {
          'status': 'active',
          'reactivatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[COMPANY_SERVICE] ❌ Erreur réactivation utilisateurs: $e');
    }
  }
}
