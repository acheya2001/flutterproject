import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 📄 Service de gestion des contrats pour Admin Agence
class AdminAgenceContractService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📄 Récupérer tous les contrats d'une agence avec pagination
  static Future<Map<String, dynamic>> getAgenceContracts({
    required String agenceId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
    String? searchQuery,
    String? statusFilter,
    String? typeFilter,
    String? agentFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('[ADMIN_AGENCE_CONTRACTS] 📄 Récupération contrats agence: $agenceId');

      Query query = _firestore
          .collection('contrats')
          .where('agenceId', isEqualTo: agenceId);

      // Filtres
      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.where('statut', isEqualTo: statusFilter);
      }

      if (typeFilter != null && typeFilter.isNotEmpty) {
        query = query.where('typeCouverture', isEqualTo: typeFilter);
      }

      if (agentFilter != null && agentFilter.isNotEmpty) {
        query = query.where('agentId', isEqualTo: agentFilter);
      }

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      // Pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      List<Map<String, dynamic>> contracts = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        // Recherche textuelle côté client
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final searchLower = searchQuery.toLowerCase();
          final numeroContrat = (data['numeroContrat'] ?? '').toString().toLowerCase();
          final conducteurNom = (data['conducteurNom'] ?? '').toString().toLowerCase();
          
          if (!numeroContrat.contains(searchLower) && !conducteurNom.contains(searchLower)) {
            continue;
          }
        }

        // Enrichir avec les données liées
        data['conducteurData'] = await _getConducteurData(data['conducteurId']);
        data['vehiculeData'] = await _getVehiculeData(data['vehiculeId']);
        data['agentData'] = await _getAgentData(data['agentId']);

        contracts.add(data);
      }

      final hasMore = snapshot.docs.length == limit;
      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      debugPrint('[ADMIN_AGENCE_CONTRACTS] ✅ ${contracts.length} contrats récupérés');

      return {
        'contracts': contracts,
        'hasMore': hasMore,
        'lastDocument': lastDoc,
        'total': contracts.length,
      };

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_CONTRACTS] ❌ Erreur récupération contrats: $e');
      return {
        'contracts': <Map<String, dynamic>>[],
        'hasMore': false,
        'lastDocument': null,
        'total': 0,
      };
    }
  }

  /// 📄 Récupérer les détails complets d'un contrat
  static Future<Map<String, dynamic>?> getContractDetails(String contractId) async {
    try {
      debugPrint('[ADMIN_AGENCE_CONTRACTS] 📄 Récupération détails contrat: $contractId');

      final contractDoc = await _firestore.collection('contrats').doc(contractId).get();
      
      if (!contractDoc.exists) {
        debugPrint('[ADMIN_AGENCE_CONTRACTS] ❌ Contrat non trouvé: $contractId');
        return null;
      }

      final contractData = contractDoc.data()!;
      contractData['id'] = contractDoc.id;

      // Enrichir avec toutes les données liées
      contractData['conducteurData'] = await _getConducteurData(contractData['conducteurId']);
      contractData['vehiculeData'] = await _getVehiculeData(contractData['vehiculeId']);
      contractData['agentData'] = await _getAgentData(contractData['agentId']);
      contractData['history'] = await _getContractHistory(contractId);

      debugPrint('[ADMIN_AGENCE_CONTRACTS] ✅ Détails contrat récupérés');
      return contractData;

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_CONTRACTS] ❌ Erreur récupération détails: $e');
      return null;
    }
  }

  /// 👤 Récupérer les données du conducteur
  static Future<Map<String, dynamic>?> _getConducteurData(String? conducteurId) async {
    if (conducteurId == null || conducteurId.isEmpty) return null;

    try {
      final doc = await _firestore.collection('users').doc(conducteurId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('[ADMIN_AGENCE_CONTRACTS] ❌ Erreur récupération conducteur: $e');
      return null;
    }
  }

  /// 🚗 Récupérer les données du véhicule
  static Future<Map<String, dynamic>?> _getVehiculeData(String? vehiculeId) async {
    if (vehiculeId == null || vehiculeId.isEmpty) return null;

    try {
      final doc = await _firestore.collection('vehicules').doc(vehiculeId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('[ADMIN_AGENCE_CONTRACTS] ❌ Erreur récupération véhicule: $e');
      return null;
    }
  }

  /// 👨‍💼 Récupérer les données de l'agent
  static Future<Map<String, dynamic>?> _getAgentData(String? agentId) async {
    if (agentId == null || agentId.isEmpty) return null;

    try {
      final doc = await _firestore.collection('users').doc(agentId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('[ADMIN_AGENCE_CONTRACTS] ❌ Erreur récupération agent: $e');
      return null;
    }
  }

  /// 📜 Récupérer l'historique d'un contrat
  static Future<List<Map<String, dynamic>>> _getContractHistory(String contractId) async {
    try {
      final historySnapshot = await _firestore
          .collection('contrats')
          .doc(contractId)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .get();

      return historySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_CONTRACTS] ❌ Erreur récupération historique: $e');
      return [];
    }
  }

  /// 📊 Récupérer les statistiques des contrats
  static Future<Map<String, dynamic>> getContractsStatistics(String agenceId) async {
    try {
      final contractsSnapshot = await _firestore
          .collection('contrats')
          .where('agenceId', isEqualTo: agenceId)
          .get();

      Map<String, int> statusCount = {};
      Map<String, int> typeCount = {};
      Map<String, int> monthlyCount = {};

      for (var doc in contractsSnapshot.docs) {
        final data = doc.data();
        
        // Compter par statut
        final status = data['statut'] ?? 'Non défini';
        statusCount[status] = (statusCount[status] ?? 0) + 1;

        // Compter par type
        final type = data['typeCouverture'] ?? 'Non défini';
        typeCount[type] = (typeCount[type] ?? 0) + 1;

        // Compter par mois
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        if (createdAt != null) {
          final monthKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';
          monthlyCount[monthKey] = (monthlyCount[monthKey] ?? 0) + 1;
        }
      }

      return {
        'total': contractsSnapshot.docs.length,
        'statusDistribution': statusCount,
        'typeDistribution': typeCount,
        'monthlyDistribution': monthlyCount,
      };

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_CONTRACTS] ❌ Erreur statistiques: $e');
      return {
        'total': 0,
        'statusDistribution': {},
        'typeDistribution': {},
        'monthlyDistribution': {},
      };
    }
  }

  /// 🔍 Rechercher des contrats
  static Future<List<Map<String, dynamic>>> searchContracts({
    required String agenceId,
    required String searchQuery,
    int limit = 10,
  }) async {
    try {
      final contractsSnapshot = await _firestore
          .collection('contrats')
          .where('agenceId', isEqualTo: agenceId)
          .get();

      List<Map<String, dynamic>> results = [];
      final searchLower = searchQuery.toLowerCase();

      for (var doc in contractsSnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;

        final numeroContrat = (data['numeroContrat'] ?? '').toString().toLowerCase();
        final conducteurNom = (data['conducteurNom'] ?? '').toString().toLowerCase();

        if (numeroContrat.contains(searchLower) || conducteurNom.contains(searchLower)) {
          results.add(data);
          if (results.length >= limit) break;
        }
      }

      return results;

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_CONTRACTS] ❌ Erreur recherche: $e');
      return [];
    }
  }

  /// 📅 Récupérer les contrats expirant bientôt
  static Future<List<Map<String, dynamic>>> getExpiringContracts({
    required String agenceId,
    int daysAhead = 30,
  }) async {
    try {
      final now = DateTime.now();
      final futureDate = now.add(Duration(days: daysAhead));

      final contractsSnapshot = await _firestore
          .collection('contrats')
          .where('agenceId', isEqualTo: agenceId)
          .where('statut', isEqualTo: 'actif')
          .get();

      List<Map<String, dynamic>> expiringContracts = [];

      for (var doc in contractsSnapshot.docs) {
        final data = doc.data();
        final dateFin = (data['dateFin'] as Timestamp?)?.toDate();

        if (dateFin != null && dateFin.isAfter(now) && dateFin.isBefore(futureDate)) {
          data['id'] = doc.id;
          data['daysUntilExpiry'] = dateFin.difference(now).inDays;
          expiringContracts.add(data);
        }
      }

      // Trier par date d'expiration
      expiringContracts.sort((a, b) => (a['daysUntilExpiry'] as int).compareTo(b['daysUntilExpiry'] as int));

      return expiringContracts;

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_CONTRACTS] ❌ Erreur contrats expirants: $e');
      return [];
    }
  }

  /// 📄 Exporter les contrats en CSV (données seulement)
  static Future<List<Map<String, dynamic>>> exportContractsData(String agenceId) async {
    try {
      final contractsSnapshot = await _firestore
          .collection('contrats')
          .where('agenceId', isEqualTo: agenceId)
          .get();

      List<Map<String, dynamic>> exportData = [];

      for (var doc in contractsSnapshot.docs) {
        final data = doc.data();
        
        exportData.add({
          'Numéro Contrat': data['numeroContrat'],
          'Conducteur': data['conducteurNom'],
          'Type Couverture': data['typeCouverture'],
          'Prime Annuelle': data['primeAnnuelle'],
          'Date Début': data['dateDebut']?.toDate()?.toString(),
          'Date Fin': data['dateFin']?.toDate()?.toString(),
          'Statut': data['statut'],
          'Date Création': data['createdAt']?.toDate()?.toString(),
        });
      }

      return exportData;

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_CONTRACTS] ❌ Erreur export: $e');
      return [];
    }
  }
}
