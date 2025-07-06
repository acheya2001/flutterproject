import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/insurance_contract.dart';
import 'notification_service.dart';

/// 📋 Service de gestion des contrats d'assurance
class ContractService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ➕ Créer un nouveau contrat et l'affecter au conducteur
  static Future<Map<String, dynamic>> createAndAssignContract({
    required InsuranceContract contract,
    required String conducteurEmail,
  }) async {
    try {
      print('📋 [CONTRACT] Création contrat: ${contract.numeroContrat}');

      // 1. Vérifier si le conducteur existe
      final conducteurQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: conducteurEmail)
          .limit(1)
          .get();

      if (conducteurQuery.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Conducteur non trouvé avec l\'email: $conducteurEmail'
        };
      }

      final conducteurData = conducteurQuery.docs.first;
      final conducteurId = conducteurData.id;

      // Vérifier le type d'utilisateur
      final userTypeDoc = await _firestore
          .collection('user_types')
          .doc(conducteurId)
          .get();

      final userType = userTypeDoc.data()?['type'] as String? ?? 'conducteur';
      if (userType != 'conducteur') {
        return {
          'success': false,
          'message': 'L\'utilisateur n\'est pas un conducteur: $userType'
        };
      }

      // 2. Vérifier si le contrat existe déjà
      final existingContract = await _firestore
          .collection('contracts')
          .where('numeroContrat', isEqualTo: contract.numeroContrat)
          .limit(1)
          .get();

      if (existingContract.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'Un contrat avec ce numéro existe déjà: ${contract.numeroContrat}'
        };
      }

      // 3. Créer le contrat dans Firestore
      final contractRef = await _firestore.collection('contracts').add({
        ...contract.toMap(),
        'conducteurId': conducteurId,
        'conducteurEmail': conducteurEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'createdBy': _auth.currentUser?.uid,
      });

      // 4. Créer/Mettre à jour le véhicule dans la collection vehicules
      await _createOrUpdateVehicle(contract, conducteurId);

      // 5. Envoyer les notifications
      await InsuranceNotificationService.sendContractNotification(
        conducteurEmail: conducteurEmail,
        numeroContrat: contract.numeroContrat,
        vehiculeImmatriculation: contract.vehicule.immatriculation,
        compagnieNom: contract.compagnieAssurance,
        agentNom: 'Agent ${contract.agentId}',
      );

      // 6. Envoyer email de confirmation
      await InsuranceNotificationService.sendEmailNotification(
        recipientEmail: conducteurEmail,
        numeroContrat: contract.numeroContrat,
        vehiculeImmatriculation: contract.vehicule.immatriculation,
        compagnieNom: contract.compagnieAssurance,
      );

      print('✅ [CONTRACT] Contrat créé et affecté avec succès');
      return {
        'success': true,
        'message': 'Contrat créé et affecté avec succès',
        'contractId': contractRef.id,
      };
    } catch (e) {
      print('❌ [CONTRACT] Erreur création contrat: $e');
      return {
        'success': false,
        'message': 'Erreur lors de la création du contrat: $e'
      };
    }
  }

  /// 🚗 Créer ou mettre à jour le véhicule
  static Future<void> _createOrUpdateVehicle(
    InsuranceContract contract,
    String conducteurId,
  ) async {
    try {
      // Vérifier si le véhicule existe déjà
      final existingVehicle = await _firestore
          .collection('vehicules')
          .where('immatriculation', isEqualTo: contract.vehicule.immatriculation)
          .limit(1)
          .get();

      final vehiculeData = {
        'immatriculation': contract.vehicule.immatriculation,
        'marque': contract.vehicule.marque,
        'modele': contract.vehicule.modele,
        'annee': contract.vehicule.annee,
        'couleur': contract.vehicule.couleur,
        'numeroSerie': contract.vehicule.numeroSerie,
        'puissance': contract.vehicule.puissance,
        'energie': contract.vehicule.energie,
        'usage': contract.vehicule.usage,
        'conducteurId': conducteurId,
        'assurance': {
          'compagnie': contract.compagnieAssurance,
          'numeroContrat': contract.numeroContrat,
          'agence': contract.agence,
          'agent': 'Agent ${contract.agentId}',
          'dateDebut': contract.dateDebut,
          'dateFin': contract.dateFin,
          'status': 'active',
        },
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (existingVehicle.docs.isNotEmpty) {
        // Mettre à jour le véhicule existant
        await _firestore
            .collection('vehicules')
            .doc(existingVehicle.docs.first.id)
            .update(vehiculeData);
        print('🔄 [VEHICLE] Véhicule mis à jour: ${contract.vehicule.immatriculation}');
      } else {
        // Créer un nouveau véhicule
        vehiculeData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('vehicules').add(vehiculeData);
        print('➕ [VEHICLE] Nouveau véhicule créé: ${contract.vehicule.immatriculation}');
      }
    } catch (e) {
      print('❌ [VEHICLE] Erreur gestion véhicule: $e');
      rethrow;
    }
  }

  /// 📋 Récupérer les contrats d'un agent
  static Stream<List<InsuranceContract>> getAgentContracts(String agentId) {
    return _firestore
        .collection('contracts')
        .where('createdBy', isEqualTo: agentId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InsuranceContract.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  /// 🚗 Récupérer les véhicules d'un conducteur
  static Stream<List<Map<String, dynamic>>> getConducteurVehicles(String conducteurId) {
    return _firestore
        .collection('vehicules')
        .where('conducteurId', isEqualTo: conducteurId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// 🔍 Rechercher un conducteur par email
  static Future<Map<String, dynamic>?> searchConducteurByEmail(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;

        // Vérifier le type d'utilisateur
        final userTypeDoc = await _firestore
            .collection('user_types')
            .doc(doc.id)
            .get();

        final userType = userTypeDoc.data()?['type'] as String? ?? 'conducteur';
        if (userType != 'conducteur') {
          return null; // Seuls les conducteurs peuvent avoir des contrats
        }

        return {'id': doc.id, 'type': userType, ...doc.data()};
      }
      return null;
    } catch (e) {
      print('❌ [SEARCH] Erreur recherche conducteur: $e');
      return null;
    }
  }

  /// 📊 Statistiques des contrats pour un agent
  static Future<Map<String, int>> getAgentStats(String agentId) async {
    try {
      final contracts = await _firestore
          .collection('contracts')
          .where('createdBy', isEqualTo: agentId)
          .get();

      final activeContracts = contracts.docs
          .where((doc) => doc.data()['status'] == 'active')
          .length;

      final thisMonth = DateTime.now();
      final startOfMonth = DateTime(thisMonth.year, thisMonth.month, 1);
      
      final monthlyContracts = contracts.docs.where((doc) {
        final createdAt = (doc.data()['createdAt'] as Timestamp?)?.toDate();
        return createdAt != null && createdAt.isAfter(startOfMonth);
      }).length;

      return {
        'total': contracts.docs.length,
        'active': activeContracts,
        'thisMonth': monthlyContracts,
      };
    } catch (e) {
      print('❌ [STATS] Erreur statistiques: $e');
      return {'total': 0, 'active': 0, 'thisMonth': 0};
    }
  }

  /// 🔄 Renouveler un contrat
  static Future<bool> renewContract(String contractId, DateTime newEndDate) async {
    try {
      await _firestore.collection('contracts').doc(contractId).update({
        'dateFin': Timestamp.fromDate(newEndDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour aussi dans le véhicule
      final contract = await _firestore.collection('contracts').doc(contractId).get();
      if (contract.exists) {
        final contractData = contract.data()!;
        final immatriculation = contractData['vehicule']['immatriculation'];
        
        final vehicleQuery = await _firestore
            .collection('vehicules')
            .where('immatriculation', isEqualTo: immatriculation)
            .limit(1)
            .get();

        if (vehicleQuery.docs.isNotEmpty) {
          await _firestore
              .collection('vehicules')
              .doc(vehicleQuery.docs.first.id)
              .update({
            'assurance.dateFin': Timestamp.fromDate(newEndDate),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return true;
    } catch (e) {
      print('❌ [RENEW] Erreur renouvellement: $e');
      return false;
    }
  }

  /// ❌ Annuler un contrat
  static Future<bool> cancelContract(String contractId, String reason) async {
    try {
      await _firestore.collection('contracts').doc(contractId).update({
        'status': 'cancelled',
        'cancelReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour le statut dans le véhicule
      final contract = await _firestore.collection('contracts').doc(contractId).get();
      if (contract.exists) {
        final contractData = contract.data()!;
        final immatriculation = contractData['vehicule']['immatriculation'];
        
        final vehicleQuery = await _firestore
            .collection('vehicules')
            .where('immatriculation', isEqualTo: immatriculation)
            .limit(1)
            .get();

        if (vehicleQuery.docs.isNotEmpty) {
          await _firestore
              .collection('vehicules')
              .doc(vehicleQuery.docs.first.id)
              .update({
            'assurance.status': 'cancelled',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return true;
    } catch (e) {
      print('❌ [CANCEL] Erreur annulation: $e');
      return false;
    }
  }
}
