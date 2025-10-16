import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 🌳 Service pour la vue hiérarchique Super Admin
/// Compagnie → Agences → Admins Agences
class SuperAdminHierarchyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🏢 Obtenir la hiérarchie complète : Compagnies → Agences → Admins
  static Future<List<Map<String, dynamic>>> getCompleteHierarchy() async {
    try {
      debugPrint('[SUPER_ADMIN_HIERARCHY] 🌳 Chargement hiérarchie complète...');

      // 1. Charger toutes les compagnies depuis la collection 'compagnies'
      final compagniesSnapshot = await _firestore
          .collection('compagnies')
          .get();

      debugPrint('[SUPER_ADMIN_HIERARCHY] 📊 Collection compagnies: ${compagniesSnapshot.docs.length} documents');

      if (compagniesSnapshot.docs.isEmpty) {
        debugPrint('[SUPER_ADMIN_HIERARCHY] ⚠️ Aucune compagnie trouvée dans la collection compagnies');
        return [];
      }

      List<Map<String, dynamic>> hierarchyData = [];

      // Trier les compagnies par nom en mémoire
      final sortedCompagnieDocs = compagniesSnapshot.docs.toList()
        ..sort((a, b) => (a.data()['nom'] ?? '').toString().compareTo((b.data()['nom'] ?? '').toString()));

      for (var compagnieDoc in sortedCompagnieDocs) {
        final compagnieData = compagnieDoc.data();
        compagnieData['id'] = compagnieDoc.id;

        // 2. Charger les agences de cette compagnie
        final agencesSnapshot = await _firestore
            .collection('agences')
            .where('compagnieId', isEqualTo: compagnieDoc.id)
            .get();

        List<Map<String, dynamic>> agencesWithAdmins = [];

        // Trier les agences par nom en mémoire
        final sortedAgenceDocs = agencesSnapshot.docs.toList()
          ..sort((a, b) => (a.data()['nom'] ?? '').toString().compareTo((b.data()['nom'] ?? '').toString()));

        for (var agenceDoc in sortedAgenceDocs) {
          final agenceData = agenceDoc.data();
          agenceData['id'] = agenceDoc.id;

          // 3. Charger l'admin agence de cette agence (s'il existe)
          Map<String, dynamic>? adminAgence;
          if (agenceData['hasAdminAgence'] == true) {
            try {
              final adminSnapshot = await _firestore
                  .collection('users')
                  .where('role', isEqualTo: 'admin_agence')
                  .where('agenceId', isEqualTo: agenceDoc.id)
                  .where('isActive', isEqualTo: true)
                  .limit(1)
                  .get();

              if (adminSnapshot.docs.isNotEmpty) {
                adminAgence = adminSnapshot.docs.first.data();
                adminAgence!['id'] = adminSnapshot.docs.first.id;
              }
            } catch (e) {
              debugPrint('[SUPER_ADMIN_HIERARCHY] ⚠️ Erreur chargement admin agence ${agenceDoc.id}: $e');
            }
          }

          // 4. Compter les agents de cette agence
          int nombreAgents = 0;
          try {
            final agentsSnapshot = await _firestore
                .collection('users')
                .where('role', isEqualTo: 'agent')
                .where('agenceId', isEqualTo: agenceDoc.id)
                .get();
            nombreAgents = agentsSnapshot.docs.length;
          } catch (e) {
            debugPrint('[SUPER_ADMIN_HIERARCHY] ⚠️ Erreur comptage agents ${agenceDoc.id}: $e');
          }

          // 5. Ajouter les données enrichies de l'agence
          agenceData['adminAgence'] = adminAgence;
          agenceData['nombreAgents'] = nombreAgents;
          agenceData['hasValidAdmin'] = adminAgence != null;
          
          agencesWithAdmins.add(agenceData);
        }

        // 6. Calculer les statistiques de la compagnie
        final stats = _calculateCompagnieStats(agencesWithAdmins);
        
        // 7. Ajouter les données enrichies de la compagnie
        compagnieData['agences'] = agencesWithAdmins;
        compagnieData['stats'] = stats;
        
        hierarchyData.add(compagnieData);
      }

      debugPrint('[SUPER_ADMIN_HIERARCHY] ✅ Hiérarchie chargée: ${hierarchyData.length} compagnies');
      return hierarchyData;

    } catch (e) {
      debugPrint('[SUPER_ADMIN_HIERARCHY] ❌ Erreur chargement hiérarchie: $e');
      return [];
    }
  }

  /// 📊 Calculer les statistiques d'une compagnie
  static Map<String, dynamic> _calculateCompagnieStats(List<Map<String, dynamic>> agences) {
    int totalAgences = agences.length;
    int agencesAvecAdmin = agences.where((a) => a['hasValidAdmin'] == true).length;
    int agencesSansAdmin = totalAgences - agencesAvecAdmin;
    int totalAgents = agences.fold(0, (sum, agence) => sum + (agence['nombreAgents'] as int));
    
    return {
      'totalAgences': totalAgences,
      'agencesAvecAdmin': agencesAvecAdmin,
      'agencesSansAdmin': agencesSansAdmin,
      'totalAgents': totalAgents,
      'pourcentageAvecAdmin': totalAgences > 0 ? (agencesAvecAdmin / totalAgences * 100).round() : 0,
    };
  }

  /// 🔍 Obtenir les détails d'une compagnie spécifique
  static Future<Map<String, dynamic>?> getCompagnieDetails(String compagnieId) async {
    try {
      debugPrint('[SUPER_ADMIN_HIERARCHY] 🔍 Chargement détails compagnie: $compagnieId');

      final compagnieDoc = await _firestore
          .collection('compagnies_assurance')
          .doc(compagnieId)
          .get();

      if (!compagnieDoc.exists) {
        return null;
      }

      final compagnieData = compagnieDoc.data()!;
      compagnieData['id'] = compagnieDoc.id;

      // Charger l'admin compagnie
      try {
        final adminSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'admin_compagnie')
            .where('compagnieId', isEqualTo: compagnieId)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();

        if (adminSnapshot.docs.isNotEmpty) {
          compagnieData['adminCompagnie'] = adminSnapshot.docs.first.data();
          compagnieData['adminCompagnie']['id'] = adminSnapshot.docs.first.id;
        }
      } catch (e) {
        debugPrint('[SUPER_ADMIN_HIERARCHY] ⚠️ Erreur chargement admin compagnie: $e');
      }

      // Charger les agences avec leurs admins
      final agencesSnapshot = await _firestore
          .collection('agences')
          .where('compagnieId', isEqualTo: compagnieId)
          .orderBy('nom')
          .get();

      List<Map<String, dynamic>> agencesWithAdmins = [];

      for (var agenceDoc in agencesSnapshot.docs) {
        final agenceData = agenceDoc.data();
        agenceData['id'] = agenceDoc.id;

        // Charger l'admin agence
        if (agenceData['hasAdminAgence'] == true) {
          try {
            final adminSnapshot = await _firestore
                .collection('users')
                .where('role', isEqualTo: 'admin_agence')
                .where('agenceId', isEqualTo: agenceDoc.id)
                .limit(1)
                .get();

            if (adminSnapshot.docs.isNotEmpty) {
              agenceData['adminAgence'] = adminSnapshot.docs.first.data();
              agenceData['adminAgence']['id'] = adminSnapshot.docs.first.id;
            }
          } catch (e) {
            debugPrint('[SUPER_ADMIN_HIERARCHY] ⚠️ Erreur admin agence ${agenceDoc.id}: $e');
          }
        }

        agencesWithAdmins.add(agenceData);
      }

      compagnieData['agences'] = agencesWithAdmins;
      compagnieData['stats'] = _calculateCompagnieStats(agencesWithAdmins);

      return compagnieData;

    } catch (e) {
      debugPrint('[SUPER_ADMIN_HIERARCHY] ❌ Erreur détails compagnie: $e');
      return null;
    }
  }

  /// 📈 Obtenir les statistiques globales
  static Future<Map<String, dynamic>> getGlobalStats() async {
    try {
      debugPrint('[SUPER_ADMIN_HIERARCHY] 📈 Calcul statistiques globales...');

      // Récupérer toutes les collections nécessaires
      final compagniesSnapshot = await _firestore.collection('compagnies').get();
      final agencesSnapshot = await _firestore.collection('agences').get();
      final usersSnapshot = await _firestore.collection('users').get();
      final sinistresSnapshot = await _firestore.collection('sinistres').get();

      int totalCompagnies = compagniesSnapshot.docs.length;
      int totalAgences = agencesSnapshot.docs.length;

      int agencesAvecAdmin = agencesSnapshot.docs
          .where((doc) => doc.data()['hasAdminAgence'] == true).length;
      int agencesSansAdmin = totalAgences - agencesAvecAdmin;

      // Compter les utilisateurs par rôle
      int adminCompagnies = usersSnapshot.docs
          .where((doc) => doc.data()['role'] == 'admin_compagnie' && doc.data()['isActive'] == true).length;
      int adminAgences = usersSnapshot.docs
          .where((doc) => doc.data()['role'] == 'admin_agence' && doc.data()['isActive'] == true).length;
      int agents = usersSnapshot.docs
          .where((doc) => doc.data()['role'] == 'agent' && doc.data()['isActive'] == true).length;

      // Compter les experts (différents rôles possibles)
      int experts = usersSnapshot.docs
          .where((doc) => (doc.data()['role'] == 'expert' || doc.data()['role'] == 'expert_auto') && doc.data()['isActive'] == true).length;

      // Compter les conducteurs
      int conducteurs = usersSnapshot.docs
          .where((doc) => doc.data()['role'] == 'conducteur' && doc.data()['isActive'] == true).length;

      // Compter les sinistres par statut
      int totalSinistres = sinistresSnapshot.docs.length;
      int sinistresEnCours = sinistresSnapshot.docs
          .where((doc) => doc.data()['status'] == 'en_cours' || doc.data()['status'] == 'ouvert').length;
      int sinistresTraites = sinistresSnapshot.docs
          .where((doc) => doc.data()['status'] == 'traite' || doc.data()['status'] == 'clos').length;
      int sinistresEnAttente = sinistresSnapshot.docs
          .where((doc) => doc.data()['status'] == 'en_attente' || doc.data()['status'] == 'nouveau').length;

      debugPrint('[SUPER_ADMIN_HIERARCHY] 📊 Stats calculées: Experts=$experts, Sinistres=$totalSinistres, En cours=$sinistresEnCours');

      return {
        'totalCompagnies': totalCompagnies,
        'totalAgences': totalAgences,
        'agencesAvecAdmin': agencesAvecAdmin,
        'agencesSansAdmin': agencesSansAdmin,
        'adminCompagnies': adminCompagnies,
        'adminAgences': adminAgences,
        'agents': agents,
        'experts': experts,
        'conducteurs': conducteurs,
        'totalSinistres': totalSinistres,
        'sinistresEnCours': sinistresEnCours,
        'sinistresTraites': sinistresTraites,
        'sinistresEnAttente': sinistresEnAttente,
        'pourcentageAgencesAvecAdmin': totalAgences > 0 ? (agencesAvecAdmin / totalAgences * 100).round() : 0,
        'tauxTraitementSinistres': totalSinistres > 0 ? (sinistresTraites / totalSinistres * 100).round() : 0,
      };

    } catch (e) {
      debugPrint('[SUPER_ADMIN_HIERARCHY] ❌ Erreur stats globales: $e');
      return {};
    }
  }

  /// 🔄 Stream pour la hiérarchie en temps réel
  static Stream<List<Map<String, dynamic>>> getHierarchyStream() {
    return _firestore
        .collection('compagnies_assurance')
        .orderBy('nom')
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> hierarchyData = [];

      for (var compagnieDoc in snapshot.docs) {
        final compagnieData = compagnieDoc.data();
        compagnieData['id'] = compagnieDoc.id;

        // Charger les agences de cette compagnie
        final agencesSnapshot = await _firestore
            .collection('agences')
            .where('compagnieId', isEqualTo: compagnieDoc.id)
            .get();

        List<Map<String, dynamic>> agencesWithAdmins = [];

        for (var agenceDoc in agencesSnapshot.docs) {
          final agenceData = agenceDoc.data();
          agenceData['id'] = agenceDoc.id;

          // Charger l'admin agence si présent
          if (agenceData['hasAdminAgence'] == true) {
            try {
              final adminSnapshot = await _firestore
                  .collection('users')
                  .where('role', isEqualTo: 'admin_agence')
                  .where('agenceId', isEqualTo: agenceDoc.id)
                  .limit(1)
                  .get();

              if (adminSnapshot.docs.isNotEmpty) {
                agenceData['adminAgence'] = adminSnapshot.docs.first.data();
                agenceData['adminAgence']['id'] = adminSnapshot.docs.first.id;
              }
            } catch (e) {
              debugPrint('[SUPER_ADMIN_HIERARCHY] ⚠️ Erreur stream admin: $e');
            }
          }

          agencesWithAdmins.add(agenceData);
        }

        compagnieData['agences'] = agencesWithAdmins;
        compagnieData['stats'] = _calculateCompagnieStats(agencesWithAdmins);
        
        hierarchyData.add(compagnieData);
      }

      return hierarchyData;
    });
  }
}
