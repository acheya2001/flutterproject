import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/insurance_contract.dart';

/// 🏢 Service de gestion des contrats d'assurance
class InsuranceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _contractsCollection = 'insurance_contracts';
  static const String _vehiclesCollection = 'vehicles';

  /// 📋 Créer un nouveau contrat d'assurance
  Future<String> createContract(InsuranceContract contract) async {
    try {
      debugPrint('🔍 [InsuranceService] Création contrat: ${contract.numeroContrat}');
      
      // Vérifier l'unicité du numéro de contrat
      final existingContract = await _firestore
          .collection(_contractsCollection)
          .where('numeroContrat', isEqualTo: contract.numeroContrat)
          .where('compagnieAssurance', isEqualTo: contract.compagnieAssurance)
          .limit(1)
          .get();
      
      if (existingContract.docs.isNotEmpty) {
        throw Exception('Un contrat avec ce numéro existe déjà pour cette compagnie');
      }

      // Créer d'abord le véhicule
      final vehicleRef = await _firestore.collection(_vehiclesCollection).add(
        contract.vehicule.toFirestore(),
      );
      
      // Créer le contrat avec l'ID du véhicule
      final updatedVehicle = contract.vehicule.copyWith(id: vehicleRef.id);
      final updatedContract = contract.copyWith(vehicule: updatedVehicle);
      
      final contractRef = await _firestore.collection(_contractsCollection).add(
        updatedContract.toFirestore(),
      );
      
      debugPrint('✅ [InsuranceService] Contrat créé: ${contractRef.id}');
      return contractRef.id;
    } catch (e) {
      debugPrint('❌ [InsuranceService] Erreur création contrat: $e');
      rethrow;
    }
  }

  /// 📥 Récupérer les contrats d'un agent
  Future<List<InsuranceContract>> getContractsByAgent(String agentId) async {
    try {
      debugPrint('🔍 [InsuranceService] Récupération contrats agent: $agentId');
      
      final querySnapshot = await _firestore
          .collection(_contractsCollection)
          .where('agentId', isEqualTo: agentId)
          .orderBy('createdAt', descending: true)
          .get();
      
      final contracts = querySnapshot.docs
          .map((doc) => InsuranceContract.fromFirestore(doc))
          .toList();
      
      debugPrint('✅ [InsuranceService] ${contracts.length} contrats trouvés');
      return contracts;
    } catch (e) {
      debugPrint('❌ [InsuranceService] Erreur récupération contrats: $e');
      rethrow;
    }
  }

  /// 🔍 Rechercher un contrat par numéro
  Future<InsuranceContract?> getContractByNumber(String numeroContrat, String compagnie) async {
    try {
      debugPrint('🔍 [InsuranceService] Recherche contrat: $numeroContrat ($compagnie)');
      
      final querySnapshot = await _firestore
          .collection(_contractsCollection)
          .where('numeroContrat', isEqualTo: numeroContrat)
          .where('compagnieAssurance', isEqualTo: compagnie)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        debugPrint('❌ [InsuranceService] Contrat non trouvé');
        return null;
      }
      
      final contract = InsuranceContract.fromFirestore(querySnapshot.docs.first);
      debugPrint('✅ [InsuranceService] Contrat trouvé: ${contract.id}');
      return contract;
    } catch (e) {
      debugPrint('❌ [InsuranceService] Erreur recherche contrat: $e');
      rethrow;
    }
  }

  /// 🔍 Rechercher un véhicule par immatriculation
  Future<List<InsuranceContract>> getContractsByVehicle(String immatriculation) async {
    try {
      debugPrint('🔍 [InsuranceService] Recherche véhicule: $immatriculation');

      final querySnapshot = await _firestore
          .collection(_contractsCollection)
          .where('vehicule.numeroImmatriculation', isEqualTo: immatriculation)
          .get();

      final contracts = querySnapshot.docs
          .map((doc) => InsuranceContract.fromFirestore(doc))
          .toList();

      debugPrint('✅ [InsuranceService] ${contracts.length} contrats trouvés pour le véhicule');
      return contracts;
    } catch (e) {
      debugPrint('❌ [InsuranceService] Erreur recherche véhicule: $e');
      rethrow;
    }
  }

  /// ✏️ Mettre à jour un contrat
  Future<void> updateContract(String contractId, Map<String, dynamic> updates) async {
    try {
      debugPrint('🔍 [InsuranceService] Mise à jour contrat: $contractId');
      
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
      
      await _firestore
          .collection(_contractsCollection)
          .doc(contractId)
          .update(updates);
      
      debugPrint('✅ [InsuranceService] Contrat mis à jour');
    } catch (e) {
      debugPrint('❌ [InsuranceService] Erreur mise à jour contrat: $e');
      rethrow;
    }
  }

  /// 🔄 Changer le statut d'un contrat
  Future<void> updateContractStatus(String contractId, bool isActive) async {
    try {
      debugPrint('🔍 [InsuranceService] Changement statut contrat: $contractId -> $isActive');
      
      await updateContract(contractId, {
        'isActive': isActive,
      });
      
      debugPrint('✅ [InsuranceService] Statut contrat mis à jour');
    } catch (e) {
      debugPrint('❌ [InsuranceService] Erreur changement statut: $e');
      rethrow;
    }
  }

  /// 🗑️ Supprimer un contrat
  Future<void> deleteContract(String contractId) async {
    try {
      debugPrint('🔍 [InsuranceService] Suppression contrat: $contractId');
      
      // Récupérer le contrat pour obtenir l'ID du véhicule
      final contractDoc = await _firestore
          .collection(_contractsCollection)
          .doc(contractId)
          .get();
      
      if (contractDoc.exists) {
        final contract = InsuranceContract.fromFirestore(contractDoc);
        
        // Supprimer le véhicule associé
        if (contract.vehicule.id.isNotEmpty) {
          await _firestore
              .collection(_vehiclesCollection)
              .doc(contract.vehicule.id)
              .delete();
        }
        
        // Supprimer le contrat
        await _firestore
            .collection(_contractsCollection)
            .doc(contractId)
            .delete();
        
        debugPrint('✅ [InsuranceService] Contrat et véhicule supprimés');
      }
    } catch (e) {
      debugPrint('❌ [InsuranceService] Erreur suppression contrat: $e');
      rethrow;
    }
  }

  /// 📊 Statistiques des contrats d'un agent
  Future<Map<String, int>> getAgentStats(String agentId) async {
    try {
      debugPrint('🔍 [InsuranceService] Statistiques agent: $agentId');
      
      final querySnapshot = await _firestore
          .collection(_contractsCollection)
          .where('agentId', isEqualTo: agentId)
          .get();
      
      final contracts = querySnapshot.docs
          .map((doc) => InsuranceContract.fromFirestore(doc))
          .toList();
      
      final stats = {
        'total': contracts.length,
        'actifs': contracts.where((c) => c.isActive).length,
        'inactifs': contracts.where((c) => !c.isActive).length,
        'expires': contracts.where((c) => c.isExpired).length,
        'expirentBientot': contracts.where((c) => c.daysRemaining <= 30 && c.daysRemaining > 0).length,
      };
      
      debugPrint('✅ [InsuranceService] Statistiques calculées: $stats');
      return stats;
    } catch (e) {
      debugPrint('❌ [InsuranceService] Erreur calcul statistiques: $e');
      rethrow;
    }
  }

  /// 🔍 Recherche avancée de contrats
  Future<List<InsuranceContract>> searchContracts({
    String? numeroContrat,
    String? compagnie,
    String? nomAssure,
    String? immatriculation,
    bool? isActive,
    String? agentId,
  }) async {
    try {
      debugPrint('🔍 [InsuranceService] Recherche avancée contrats');
      
      Query query = _firestore.collection(_contractsCollection);
      
      if (numeroContrat != null && numeroContrat.isNotEmpty) {
        query = query.where('numeroContrat', isEqualTo: numeroContrat);
      }
      
      if (compagnie != null && compagnie.isNotEmpty) {
        query = query.where('compagnieAssurance', isEqualTo: compagnie);
      }
      
      if (isActive != null) {
        query = query.where('isActive', isEqualTo: isActive);
      }
      
      if (agentId != null && agentId.isNotEmpty) {
        query = query.where('agentId', isEqualTo: agentId);
      }
      
      final querySnapshot = await query.get();
      
      List<InsuranceContract> contracts = querySnapshot.docs
          .map((doc) => InsuranceContract.fromFirestore(doc))
          .toList();
      
      // Filtres côté client pour les champs non indexés
      if (nomAssure != null && nomAssure.isNotEmpty) {
        contracts = contracts.where((c) => 
          c.nomAssure.toLowerCase().contains(nomAssure.toLowerCase()) ||
          c.prenomAssure.toLowerCase().contains(nomAssure.toLowerCase())
        ).toList();
      }
      
      if (immatriculation != null && immatriculation.isNotEmpty) {
        contracts = contracts.where((c) => 
          c.vehicule.numeroImmatriculation.toLowerCase().contains(immatriculation.toLowerCase())
        ).toList();
      }
      
      debugPrint('✅ [InsuranceService] ${contracts.length} contrats trouvés');
      return contracts;
    } catch (e) {
      debugPrint('❌ [InsuranceService] Erreur recherche avancée: $e');
      rethrow;
    }
  }
}
