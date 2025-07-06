import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/contrat_assurance_model.dart';
import '../models/vehicule_assure_model.dart';

/// 📋 Service pour gérer les contrats d'assurance
class InsuranceContractService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📝 Créer un nouveau contrat d'assurance
  static Future<String> createContract({
    required String compagnieId,
    required String agenceId,
    required String agentId,
    required String conducteurId,
    required String vehiculeId,
    required ContratAssurance contrat,
  }) async {
    try {
      // Créer le contrat dans Firestore
      final contractRef = await _firestore
          .collection('compagnies_assurance')
          .doc(compagnieId)
          .collection('contrats')
          .add(contrat.toFirestore());

      // Associer le véhicule au contrat
      await _firestore
          .collection('vehicules_assures')
          .doc(vehiculeId)
          .update({
            'contractId': contractRef.id,
            'compagnieId': compagnieId,
            'agenceId': agenceId,
            'agentId': agentId,
            'dateModification': FieldValue.serverTimestamp(),
          });

      // Mettre à jour les statistiques de l'agence
      await _updateAgencyStats(compagnieId, agenceId, 'nouveaux_contrats', 1);

      // Mettre à jour les statistiques de l'agent
      await _updateAgentStats(agentId, 'contrats_crees', 1);

      return contractRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création du contrat: $e');
    }
  }

  /// 🔍 Rechercher un contrat par numéro
  static Future<ContratAssurance?> findContractByNumber({
    required String numeroContrat,
    String? compagnieId,
  }) async {
    try {
      Query query = _firestore.collectionGroup('contrats')
          .where('numeroContrat', isEqualTo: numeroContrat);

      if (compagnieId != null) {
        query = query.where('compagnieId', isEqualTo: compagnieId);
      }

      final querySnapshot = await query.limit(1).get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return ContratAssurance.fromFirestore(querySnapshot.docs.first);
      }
      
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la recherche du contrat: $e');
    }
  }

  /// 🚗 Obtenir les véhicules d'un conducteur avec leurs contrats
  static Future<List<Map<String, dynamic>>> getDriverVehiclesWithContracts(
      String conducteurId) async {
    try {
      // Récupérer les véhicules du conducteur
      final vehiculesSnapshot = await _firestore
          .collection('vehicules_assures')
          .where('conducteurId', isEqualTo: conducteurId)
          .where('isActive', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> vehiculesAvecContrats = [];

      for (final vehiculeDoc in vehiculesSnapshot.docs) {
        final vehicule = VehiculeAssure.fromFirestore(vehiculeDoc);
        
        // Récupérer le contrat associé
        ContratAssurance? contrat;
        if (vehicule.contractId.isNotEmpty) {
          final contratDoc = await _firestore
              .collectionGroup('contrats')
              .where(FieldPath.documentId, isEqualTo: vehicule.contractId)
              .limit(1)
              .get();
          
          if (contratDoc.docs.isNotEmpty) {
            contrat = ContratAssurance.fromFirestore(contratDoc.docs.first);
          }
        }

        vehiculesAvecContrats.add({
          'vehicule': vehicule,
          'contrat': contrat,
          'hasValidContract': contrat?.isValid ?? false,
        });
      }

      return vehiculesAvecContrats;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des véhicules: $e');
    }
  }

  /// ✅ Valider un contrat d'assurance
  static Future<bool> validateContract({
    required String numeroContrat,
    required String numeroQuittance,
    String? compagnieId,
  }) async {
    try {
      // Rechercher le contrat
      final contrat = await findContractByNumber(
        numeroContrat: numeroContrat,
        compagnieId: compagnieId,
      );

      if (contrat == null) return false;

      // Vérifier la quittance
      if (contrat.numeroQuittance != numeroQuittance) return false;

      // Vérifier la validité
      return contrat.isValid;
    } catch (e) {
      return false;
    }
  }

  /// 📊 Obtenir les statistiques des contrats d'une compagnie
  static Future<Map<String, dynamic>> getCompanyContractStats(
      String compagnieId) async {
    try {
      final contratsSnapshot = await _firestore
          .collection('compagnies_assurance')
          .doc(compagnieId)
          .collection('contrats')
          .get();

      int totalContrats = contratsSnapshot.docs.length;
      int contratsActifs = 0;
      int contratsExpires = 0;
      int contratsBientotExpires = 0;
      double chiffreAffaires = 0;

      for (final doc in contratsSnapshot.docs) {
        final contrat = ContratAssurance.fromFirestore(doc);
        chiffreAffaires += contrat.prime;

        switch (contrat.statut) {
          case 'Actif':
            contratsActifs++;
            break;
          case 'Expiré':
            contratsExpires++;
            break;
          case 'Bientôt expiré':
            contratsBientotExpires++;
            break;
        }
      }

      return {
        'totalContrats': totalContrats,
        'contratsActifs': contratsActifs,
        'contratsExpires': contratsExpires,
        'contratsBientotExpires': contratsBientotExpires,
        'chiffreAffaires': chiffreAffaires,
        'tauxRenouvellement': totalContrats > 0 
            ? (contratsActifs / totalContrats * 100).round() 
            : 0,
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }

  /// 📈 Mettre à jour les statistiques d'une agence
  static Future<void> _updateAgencyStats(
      String compagnieId, String agenceId, String field, int increment) async {
    try {
      await _firestore
          .collection('compagnies_assurance')
          .doc(compagnieId)
          .collection('agences')
          .doc(agenceId)
          .update({
            'statistiques.$field': FieldValue.increment(increment),
            'dateModification': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      // Ignorer les erreurs de statistiques
    }
  }

  /// 📈 Mettre à jour les statistiques d'un agent
  static Future<void> _updateAgentStats(
      String agentId, String field, int increment) async {
    try {
      await _firestore
          .collection('agents_assurance')
          .doc(agentId)
          .update({
            'statistiques.$field': FieldValue.increment(increment),
            'dateModification': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      // Ignorer les erreurs de statistiques
    }
  }

  /// 🔄 Renouveler un contrat
  static Future<String> renewContract({
    required String contractId,
    required String compagnieId,
    required DateTime nouvelleDateFin,
    required double nouvellePrime,
    required String nouveauNumeroQuittance,
  }) async {
    try {
      // Créer un nouveau contrat basé sur l'ancien
      final ancienContratDoc = await _firestore
          .collection('compagnies_assurance')
          .doc(compagnieId)
          .collection('contrats')
          .doc(contractId)
          .get();

      if (!ancienContratDoc.exists) {
        throw Exception('Contrat introuvable');
      }

      final ancienContrat = ContratAssurance.fromFirestore(ancienContratDoc);
      
      // Désactiver l'ancien contrat
      await ancienContratDoc.reference.update({
        'isActive': false,
        'dateModification': FieldValue.serverTimestamp(),
      });

      // Créer le nouveau contrat
      final nouveauContrat = ContratAssurance(
        id: '',
        numeroContrat: '${ancienContrat.numeroContrat}_R${DateTime.now().year}',
        compagnieId: ancienContrat.compagnieId,
        agenceId: ancienContrat.agenceId,
        agentId: ancienContrat.agentId,
        conducteurId: ancienContrat.conducteurId,
        vehiculeId: ancienContrat.vehiculeId,
        typeAssurance: ancienContrat.typeAssurance,
        dateDebut: DateTime.now(),
        dateFin: nouvelleDateFin,
        prime: nouvellePrime,
        franchise: ancienContrat.franchise,
        numeroQuittance: nouveauNumeroQuittance,
        dateQuittance: DateTime.now(),
        isActive: true,
        garanties: ancienContrat.garanties,
        conditions: ancienContrat.conditions,
        dateCreation: DateTime.now(),
      );

      final nouveauContratRef = await _firestore
          .collection('compagnies_assurance')
          .doc(compagnieId)
          .collection('contrats')
          .add(nouveauContrat.toFirestore());

      // Mettre à jour le véhicule avec le nouveau contrat
      await _firestore
          .collection('vehicules_assures')
          .doc(ancienContrat.vehiculeId)
          .update({
            'contractId': nouveauContratRef.id,
            'dateModification': FieldValue.serverTimestamp(),
          });

      return nouveauContratRef.id;
    } catch (e) {
      throw Exception('Erreur lors du renouvellement: $e');
    }
  }
}
