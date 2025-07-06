import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/vehicule_complet_model.dart';

/// 📋 Service de gestion des contrats d'assurance
class ContratManagementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ Créer un nouveau contrat d'assurance
  static Future<String> createNewContract(VehiculeCompletModel vehicule) async {
    try {
      debugPrint('📋 Création nouveau contrat: ${vehicule.contrat.numeroContrat}');

      // 1. Vérifier que le numéro de contrat n'existe pas déjà
      final existingContract = await _firestore
          .collection('vehicules_complets')
          .where('contrat.numero_contrat', isEqualTo: vehicule.contrat.numeroContrat)
          .limit(1)
          .get();

      if (existingContract.docs.isNotEmpty) {
        throw Exception('Un contrat avec ce numéro existe déjà');
      }

      // 2. Vérifier que l'immatriculation n'existe pas déjà
      final existingVehicle = await _firestore
          .collection('vehicules_complets')
          .where('immatriculation', isEqualTo: vehicule.immatriculation)
          .limit(1)
          .get();

      if (existingVehicle.docs.isNotEmpty) {
        throw Exception('Un véhicule avec cette immatriculation existe déjà');
      }

      // 3. Créer le document véhicule complet
      final vehiculeRef = _firestore.collection('vehicules_complets').doc();
      final vehiculeWithId = VehiculeCompletModel(
        id: vehiculeRef.id,
        immatriculation: vehicule.immatriculation,
        marque: vehicule.marque,
        modele: vehicule.modele,
        annee: vehicule.annee,
        couleur: vehicule.couleur,
        numeroChassis: vehicule.numeroChassis,
        puissanceFiscale: vehicule.puissanceFiscale,
        typeCarburant: vehicule.typeCarburant,
        nombrePlaces: vehicule.nombrePlaces,
        proprietaire: vehicule.proprietaire,
        contrat: vehicule.contrat,
        conducteursAutorises: vehicule.conducteursAutorises,
        historiqueSinistres: vehicule.historiqueSinistres,
        derniereMiseAJour: vehicule.derniereMiseAJour,
        createdAt: vehicule.createdAt,
        updatedAt: vehicule.updatedAt,
      );

      await vehiculeRef.set(vehiculeWithId.toFirestore());

      // 4. Enregistrer l'activité de création
      await _logContractActivity(
        contractId: vehiculeRef.id,
        contractNumber: vehicule.contrat.numeroContrat,
        action: 'creation',
        agentId: vehicule.contrat.agentGestionnaire,
        details: {
          'vehicule': '${vehicule.marque} ${vehicule.modele}',
          'immatriculation': vehicule.immatriculation,
          'proprietaire': vehicule.proprietaire.nomComplet,
          'type_couverture': vehicule.contrat.typeCouverture,
          'prime_annuelle': vehicule.contrat.primeAnnuelle,
        },
      );

      // 5. Mettre à jour les statistiques de l'agence
      await _updateAgencyStats(vehicule.contrat.agenceId, true);

      debugPrint('✅ Contrat créé avec succès: ${vehiculeRef.id}');
      return vehiculeRef.id;

    } catch (e) {
      debugPrint('❌ Erreur création contrat: $e');
      rethrow;
    }
  }

  /// 📊 Obtenir les contrats d'un agent
  static Future<List<VehiculeCompletModel>> getAgentContracts(String agentId) async {
    try {
      final snapshot = await _firestore
          .collection('vehicules_complets')
          .where('contrat.agent_gestionnaire', isEqualTo: agentId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => VehiculeCompletModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération contrats agent: $e');
      return [];
    }
  }

  /// 📊 Obtenir les contrats d'une agence
  static Future<List<VehiculeCompletModel>> getAgencyContracts(String agenceId) async {
    try {
      final snapshot = await _firestore
          .collection('vehicules_complets')
          .where('contrat.agence_id', isEqualTo: agenceId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => VehiculeCompletModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération contrats agence: $e');
      return [];
    }
  }

  /// 📊 Obtenir les contrats d'une compagnie
  static Future<List<VehiculeCompletModel>> getCompanyContracts(String compagnieId) async {
    try {
      final snapshot = await _firestore
          .collection('vehicules_complets')
          .where('contrat.compagnie_id', isEqualTo: compagnieId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => VehiculeCompletModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération contrats compagnie: $e');
      return [];
    }
  }

  /// 🔍 Rechercher un contrat par numéro
  static Future<VehiculeCompletModel?> findContractByNumber(String numeroContrat) async {
    try {
      final snapshot = await _firestore
          .collection('vehicules_complets')
          .where('contrat.numero_contrat', isEqualTo: numeroContrat)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return VehiculeCompletModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur recherche contrat: $e');
      return null;
    }
  }

  /// 🔄 Renouveler un contrat
  static Future<void> renewContract(String vehiculeId, DateTime newEndDate) async {
    try {
      await _firestore.collection('vehicules_complets').doc(vehiculeId).update({
        'contrat.date_fin': Timestamp.fromDate(newEndDate),
        'contrat.statut': 'actif',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      debugPrint('✅ Contrat renouvelé: $vehiculeId');
    } catch (e) {
      debugPrint('❌ Erreur renouvellement contrat: $e');
      rethrow;
    }
  }

  /// ⏸️ Suspendre un contrat
  static Future<void> suspendContract(String vehiculeId, String reason) async {
    try {
      await _firestore.collection('vehicules_complets').doc(vehiculeId).update({
        'contrat.statut': 'suspendu',
        'contrat.raison_suspension': reason,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      debugPrint('✅ Contrat suspendu: $vehiculeId');
    } catch (e) {
      debugPrint('❌ Erreur suspension contrat: $e');
      rethrow;
    }
  }

  /// 📈 Obtenir les statistiques des contrats
  static Future<Map<String, dynamic>> getContractStats({
    String? agentId,
    String? agenceId,
    String? compagnieId,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    try {
      Query query = _firestore.collection('vehicules_complets');

      if (agentId != null) {
        query = query.where('contrat.agent_gestionnaire', isEqualTo: agentId);
      }
      if (agenceId != null) {
        query = query.where('contrat.agence_id', isEqualTo: agenceId);
      }
      if (compagnieId != null) {
        query = query.where('contrat.compagnie_id', isEqualTo: compagnieId);
      }
      if (dateDebut != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(dateDebut));
      }
      if (dateFin != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(dateFin));
      }

      final snapshot = await query.get();
      
      int totalContracts = snapshot.docs.length;
      int contratsActifs = 0;
      int contratsSuspendus = 0;
      int contratsExpires = 0;
      double primeTotal = 0;
      Map<String, int> contractsParType = {};
      Map<String, int> contractsParMarque = {};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final contratData = data['contrat'] as Map<String, dynamic>;
        
        final statut = contratData['statut'] as String;
        switch (statut) {
          case 'actif':
            contratsActifs++;
            break;
          case 'suspendu':
            contratsSuspendus++;
            break;
          case 'expire':
            contratsExpires++;
            break;
        }

        primeTotal += (contratData['prime_annuelle'] as num).toDouble();

        final typeCouverture = contratData['type_couverture'] as String;
        contractsParType[typeCouverture] = (contractsParType[typeCouverture] ?? 0) + 1;

        final marque = data['marque'] as String;
        contractsParMarque[marque] = (contractsParMarque[marque] ?? 0) + 1;
      }

      return {
        'total_contrats': totalContracts,
        'contrats_actifs': contratsActifs,
        'contrats_suspendus': contratsSuspendus,
        'contrats_expires': contratsExpires,
        'prime_totale': primeTotal,
        'prime_moyenne': totalContracts > 0 ? primeTotal / totalContracts : 0,
        'contrats_par_type': contractsParType,
        'contrats_par_marque': contractsParMarque,
        'taux_activite': totalContracts > 0 ? (contratsActifs / totalContracts) * 100 : 0,
      };

    } catch (e) {
      debugPrint('❌ Erreur statistiques contrats: $e');
      return {};
    }
  }

  /// 📝 Enregistrer une activité sur un contrat
  static Future<void> _logContractActivity({
    required String contractId,
    required String contractNumber,
    required String action,
    required String agentId,
    Map<String, dynamic>? details,
  }) async {
    try {
      final activityId = _firestore.collection('contrats_activites').doc().id;
      
      await _firestore.collection('contrats_activites').doc(activityId).set({
        'id': activityId,
        'contract_id': contractId,
        'contract_number': contractNumber,
        'action': action,
        'agent_id': agentId,
        'details': details ?? {},
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      debugPrint('📝 Activité contrat enregistrée: $action');
    } catch (e) {
      debugPrint('❌ Erreur enregistrement activité: $e');
      // Ne pas faire échouer l'opération principale
    }
  }

  /// 📊 Mettre à jour les statistiques d'agence
  static Future<void> _updateAgencyStats(String agenceId, bool increment) async {
    try {
      final agenceRef = _firestore.collection('agences').doc(agenceId);
      
      await _firestore.runTransaction((transaction) async {
        final agenceDoc = await transaction.get(agenceRef);
        
        if (agenceDoc.exists) {
          final currentStats = agenceDoc.data() as Map<String, dynamic>;
          final currentContracts = currentStats['contrats_actifs'] as int? ?? 0;
          final currentVehicules = currentStats['vehicules_geres'] as int? ?? 0;
          
          transaction.update(agenceRef, {
            'contrats_actifs': increment ? currentContracts + 1 : currentContracts - 1,
            'vehicules_geres': increment ? currentVehicules + 1 : currentVehicules - 1,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
        }
      });

      debugPrint('📊 Statistiques agence mises à jour: $agenceId');
    } catch (e) {
      debugPrint('❌ Erreur mise à jour stats agence: $e');
      // Ne pas faire échouer l'opération principale
    }
  }
}
