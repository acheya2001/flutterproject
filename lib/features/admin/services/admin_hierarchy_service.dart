import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/models/admin_hierarchy_model.dart';

/// 🔧 Service pour gérer la hiérarchie d'administration
class AdminHierarchyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🏗️ Initialiser la hiérarchie d'admins (à exécuter une seule fois)
  static Future<void> initialiserHierarchieAdmins() async {
    try {
      debugPrint('[AdminHierarchy] 🏗️ Initialisation de la hiérarchie d\'admins...');

      // 1. Super Admin (constat.tunisie.app@gmail.com)
      await _creerSuperAdmin();

      // 2. Admins de compagnies
      await _creerAdminsCompagnies();

      // 3. Admins d'agences
      await _creerAdminsAgences();

      // 4. Admins régionaux
      await _creerAdminsRegionaux();

      debugPrint('[AdminHierarchy] ✅ Hiérarchie d\'admins initialisée avec succès');
    } catch (e) {
      debugPrint('[AdminHierarchy] ❌ Erreur initialisation: $e');
    }
  }

  /// 👑 Créer le Super Admin
  static Future<void> _creerSuperAdmin() async {
    final superAdmin = AdminHierarchyModel(
      id: 'super_admin_001',
      email: 'constat.tunisie.app@gmail.com',
      nom: 'Admin',
      prenom: 'Super',
      telephone: '+216 70 000 000',
      typeAdmin: TypeAdmin.superAdmin,
      gouvernoratsGeres: [], // Gère tout
      permissions: AdminHierarchyModel.getPermissionsParType(TypeAdmin.superAdmin),
      actif: true,
      dateCreation: DateTime.now(),
      statistiques: {
        'demandesTraitees': 0,
        'demandesApprouvees': 0,
        'demandesRefusees': 0,
      },
    );

    await _firestore
        .collection('admins_hierarchy')
        .doc(superAdmin.id)
        .set(superAdmin.toMap());
  }

  /// 🏢 Créer les Admins de Compagnies
  static Future<void> _creerAdminsCompagnies() async {
    final adminsCompagnies = [
      {
        'id': 'admin_star_001',
        'email': 'admin@star.tn',
        'nom': 'Ben Ahmed',
        'prenom': 'Mohamed',
        'telephone': '+216 71 123 456',
        'compagnieId': 'STAR',
        'compagnieNom': 'STAR Assurances',
      },
      {
        'id': 'admin_gat_001',
        'email': 'admin@gat.tn',
        'nom': 'Trabelsi',
        'prenom': 'Fatma',
        'telephone': '+216 71 234 567',
        'compagnieId': 'GAT',
        'compagnieNom': 'GAT Assurances',
      },
      {
        'id': 'admin_bh_001',
        'email': 'admin@bh.tn',
        'nom': 'Khelifi',
        'prenom': 'Ahmed',
        'telephone': '+216 71 345 678',
        'compagnieId': 'BH',
        'compagnieNom': 'BH Assurance',
      },
      {
        'id': 'admin_maghrebia_001',
        'email': 'admin@maghrebia.tn',
        'nom': 'Sassi',
        'prenom': 'Leila',
        'telephone': '+216 71 456 789',
        'compagnieId': 'MAGHREBIA',
        'compagnieNom': 'Maghrebia Assurances',
      },
    ];

    for (final adminData in adminsCompagnies) {
      final admin = AdminHierarchyModel(
        id: adminData['id'] as String,
        email: adminData['email'] as String,
        nom: adminData['nom'] as String,
        prenom: adminData['prenom'] as String,
        telephone: adminData['telephone'] as String,
        typeAdmin: TypeAdmin.adminCompagnie,
        compagnieId: adminData['compagnieId'] as String,
        gouvernoratsGeres: [], // Gère toute la compagnie
        permissions: AdminHierarchyModel.getPermissionsParType(TypeAdmin.adminCompagnie),
        actif: true,
        dateCreation: DateTime.now(),
        statistiques: {
          'demandesTraitees': 0,
          'demandesApprouvees': 0,
          'demandesRefusees': 0,
        },
      );

      await _firestore
          .collection('admins_hierarchy')
          .doc(admin.id)
          .set(admin.toMap());
    }
  }

  /// 🏪 Créer les Admins d'Agences
  static Future<void> _creerAdminsAgences() async {
    final adminsAgences = [
      {
        'id': 'admin_star_tunis_001',
        'email': 'admin.tunis@star.tn',
        'nom': 'Bouaziz',
        'prenom': 'Sami',
        'telephone': '+216 71 111 111',
        'compagnieId': 'STAR',
        'agenceId': 'STAR_TUNIS_CENTRE',
        'agenceNom': 'STAR Tunis Centre',
      },
      {
        'id': 'admin_gat_sousse_001',
        'email': 'admin.sousse@gat.tn',
        'nom': 'Mejri',
        'prenom': 'Nadia',
        'telephone': '+216 73 222 222',
        'compagnieId': 'GAT',
        'agenceId': 'GAT_SOUSSE',
        'agenceNom': 'GAT Sousse',
      },
    ];

    for (final adminData in adminsAgences) {
      final admin = AdminHierarchyModel(
        id: adminData['id'] as String,
        email: adminData['email'] as String,
        nom: adminData['nom'] as String,
        prenom: adminData['prenom'] as String,
        telephone: adminData['telephone'] as String,
        typeAdmin: TypeAdmin.adminAgence,
        compagnieId: adminData['compagnieId'] as String,
        agenceId: adminData['agenceId'] as String,
        gouvernoratsGeres: [],
        permissions: AdminHierarchyModel.getPermissionsParType(TypeAdmin.adminAgence),
        actif: true,
        dateCreation: DateTime.now(),
        statistiques: {
          'demandesTraitees': 0,
          'demandesApprouvees': 0,
          'demandesRefusees': 0,
        },
      );

      await _firestore
          .collection('admins_hierarchy')
          .doc(admin.id)
          .set(admin.toMap());
    }
  }

  /// 🗺️ Créer les Admins Régionaux
  static Future<void> _creerAdminsRegionaux() async {
    final adminsRegionaux = [
      {
        'id': 'admin_region_nord_001',
        'email': 'admin.nord@constat.tn',
        'nom': 'Hamdi',
        'prenom': 'Karim',
        'telephone': '+216 70 111 111',
        'gouvernorats': ['Tunis', 'Ariana', 'Ben Arous', 'Manouba', 'Bizerte'],
        'region': 'Nord',
      },
      {
        'id': 'admin_region_centre_001',
        'email': 'admin.centre@constat.tn',
        'nom': 'Gharbi',
        'prenom': 'Amina',
        'telephone': '+216 70 222 222',
        'gouvernorats': ['Sousse', 'Monastir', 'Mahdia', 'Sfax', 'Kairouan'],
        'region': 'Centre',
      },
      {
        'id': 'admin_region_sud_001',
        'email': 'admin.sud@constat.tn',
        'nom': 'Jebali',
        'prenom': 'Omar',
        'telephone': '+216 70 333 333',
        'gouvernorats': ['Gabès', 'Médenine', 'Tataouine', 'Gafsa', 'Tozeur', 'Kébili'],
        'region': 'Sud',
      },
    ];

    for (final adminData in adminsRegionaux) {
      final admin = AdminHierarchyModel(
        id: adminData['id'] as String,
        email: adminData['email'] as String,
        nom: adminData['nom'] as String,
        prenom: adminData['prenom'] as String,
        telephone: adminData['telephone'] as String,
        typeAdmin: TypeAdmin.adminRegional,
        gouvernoratsGeres: List<String>.from(adminData['gouvernorats'] as List),
        permissions: AdminHierarchyModel.getPermissionsParType(TypeAdmin.adminRegional),
        actif: true,
        dateCreation: DateTime.now(),
        statistiques: {
          'demandesTraitees': 0,
          'demandesApprouvees': 0,
          'demandesRefusees': 0,
        },
      );

      await _firestore
          .collection('admins_hierarchy')
          .doc(admin.id)
          .set(admin.toMap());
    }
  }

  /// 🔍 Obtenir un admin par email
  static Future<AdminHierarchyModel?> getAdminParEmail(String email) async {
    try {
      final query = await _firestore
          .collection('admins_hierarchy')
          .where('email', isEqualTo: email)
          .where('actif', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return AdminHierarchyModel.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('[AdminHierarchy] ❌ Erreur récupération admin: $e');
      return null;
    }
  }

  /// 📊 Obtenir les statistiques d'un admin
  static Future<Map<String, dynamic>> getStatistiquesAdmin(String adminId) async {
    try {
      final doc = await _firestore
          .collection('admins_hierarchy')
          .doc(adminId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['statistiques'] ?? {};
      }
      return {};
    } catch (e) {
      debugPrint('[AdminHierarchy] ❌ Erreur statistiques: $e');
      return {};
    }
  }

  /// 🔄 Mettre à jour les statistiques d'un admin
  static Future<void> mettreAJourStatistiques(String adminId, String action) async {
    try {
      await _firestore.collection('admins_hierarchy').doc(adminId).update({
        'statistiques.demandesTraitees': FieldValue.increment(1),
        'statistiques.demandes${action == 'approuvee' ? 'Approuvees' : 'Refusees'}': FieldValue.increment(1),
        'derniereConnexion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[AdminHierarchy] ❌ Erreur mise à jour statistiques: $e');
    }
  }

  /// 📋 Obtenir toutes les demandes pour un admin
  static Future<List<DemandeInscriptionModel>> getDemandesPourAdmin(
    AdminHierarchyModel admin, {
    String? filtreStatut,
  }) async {
    try {
      Query query = _firestore.collection('demandes_inscription');

      // Filtrer selon le type d'admin
      switch (admin.typeAdmin) {
        case TypeAdmin.superAdmin:
          // Super admin voit tout
          break;
        case TypeAdmin.adminCompagnie:
          query = query.where('compagnie', isEqualTo: admin.compagnieId);
          break;
        case TypeAdmin.adminAgence:
          query = query
              .where('compagnie', isEqualTo: admin.compagnieId)
              .where('agence', isEqualTo: admin.agenceId);
          break;
        case TypeAdmin.adminRegional:
          query = query.where('gouvernorat', whereIn: admin.gouvernoratsGeres);
          break;
      }

      // Filtrer par statut si spécifié
      if (filtreStatut != null && filtreStatut != 'toutes') {
        query = query.where('statut', isEqualTo: filtreStatut);
      }

      final snapshot = await query.orderBy('dateCreation', descending: true).get();

      return snapshot.docs
          .map((doc) => DemandeInscriptionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('[AdminHierarchy] ❌ Erreur récupération demandes: $e');
      return [];
    }
  }

  /// 🧹 Nettoyer les données de test (utilitaire)
  static Future<void> nettoyerDonneesTest() async {
    try {
      // Supprimer tous les admins de test
      final adminsSnapshot = await _firestore.collection('admins_hierarchy').get();
      for (final doc in adminsSnapshot.docs) {
        await doc.reference.delete();
      }

      debugPrint('[AdminHierarchy] 🧹 Données de test nettoyées');
    } catch (e) {
      debugPrint('[AdminHierarchy] ❌ Erreur nettoyage: $e');
    }
  }

  /// 🔐 Vérifier si un email est un admin
  static Future<bool> estAdmin(String email) async {
    final admin = await getAdminParEmail(email);
    return admin != null;
  }

  /// 📈 Obtenir le tableau de bord d'un admin
  static Future<Map<String, dynamic>> getTableauDeBord(AdminHierarchyModel admin) async {
    try {
      final demandes = await getDemandesPourAdmin(admin);
      
      final enAttente = demandes.where((d) => d.statut == 'en_attente').length;
      final enCours = demandes.where((d) => d.statut == 'en_cours_traitement').length;
      final approuvees = demandes.where((d) => d.statut == 'approuvee').length;
      final refusees = demandes.where((d) => d.statut == 'refusee').length;

      return {
        'totalDemandes': demandes.length,
        'enAttente': enAttente,
        'enCours': enCours,
        'approuvees': approuvees,
        'refusees': refusees,
        'tauxApprobation': demandes.isNotEmpty 
            ? (approuvees / (approuvees + refusees) * 100).round()
            : 0,
      };
    } catch (e) {
      debugPrint('[AdminHierarchy] ❌ Erreur tableau de bord: $e');
      return {};
    }
  }
}
