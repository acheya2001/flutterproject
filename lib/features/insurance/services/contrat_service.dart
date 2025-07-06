import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/contrat_model.dart';
import '../models/vehicule_assure_model.dart';
import '../../vehicule/models/vehicule_model.dart';
import '../models/compagnie_model.dart';

/// 📄 Service de gestion des contrats d'assurance
class ContratService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections Firestore
  static const String _contratsCollection = 'contrats_assurance';
  static const String _vehiculesAssuresCollection = 'vehicules_assures';
  static const String _vehiculesCollection = 'vehicules';
  static const String _compagniesCollection = 'compagnies_assurance';
  static const String _agencesCollection = 'agences_assurance';

  /// 📄 Créer un nouveau contrat d'assurance
  static Future<String?> creerContrat({
    required String compagnieId,
    required String agenceId,
    required String agentId,
    required String conducteurId,
    required String vehiculeId,
    required TypeFormule formule,
    required double prime,
    required double franchise,
    required DateTime dateDebut,
    required DateTime dateFin,
    String? numeroQuittance,
  }) async {
    try {
      debugPrint('[ContratService] 📄 Création d\'un nouveau contrat...');

      // Générer un numéro de contrat unique
      final numeroContrat = await _genererNumeroContrat(compagnieId);

      final contrat = ContratModel(
        id: '', // Sera généré par Firestore
        numeroContrat: numeroContrat,
        compagnieId: compagnieId,
        agenceId: agenceId,
        agentId: agentId,
        conducteurId: conducteurId,
        vehiculeId: vehiculeId,
        dateDebut: dateDebut,
        dateFin: dateFin,
        dateCreation: DateTime.now(),
        formule: formule,
        prime: prime,
        franchise: franchise,
        garanties: formule.garantiesIncluses,
        numeroQuittance: numeroQuittance,
        dateQuittance: numeroQuittance != null ? DateTime.now() : null,
      );

      // Créer le contrat dans Firestore
      final docRef = await _firestore
          .collection(_contratsCollection)
          .add(contrat.toFirestore());

      debugPrint('[ContratService] ✅ Contrat créé: ${docRef.id}');

      // Créer l'entrée véhicule assuré
      await _creerVehiculeAssure(
        contratId: docRef.id,
        vehiculeId: vehiculeId,
        compagnieId: compagnieId,
        agenceId: agenceId,
        conducteurId: conducteurId,
        numeroContrat: numeroContrat,
        numeroQuittance: numeroQuittance ?? '',
        dateDebut: dateDebut,
        dateFin: dateFin,
        formule: formule,
        prime: prime,
        franchise: franchise,
      );

      return docRef.id;
    } catch (e) {
      debugPrint('[ContratService] ❌ Erreur création contrat: $e');
      return null;
    }
  }

  /// 🚗 Créer l'entrée véhicule assuré
  static Future<void> _creerVehiculeAssure({
    required String contratId,
    required String vehiculeId,
    required String compagnieId,
    required String agenceId,
    required String conducteurId,
    required String numeroContrat,
    required String numeroQuittance,
    required DateTime dateDebut,
    required DateTime dateFin,
    required TypeFormule formule,
    required double prime,
    required double franchise,
  }) async {
    final vehiculeAssure = VehiculeAssureModel(
      id: '', // Sera généré par Firestore
      vehiculeId: vehiculeId,
      contratId: contratId,
      compagnieId: compagnieId,
      agenceId: agenceId,
      conducteurId: conducteurId,
      dateCreation: DateTime.now(),
      numeroContrat: numeroContrat,
      numeroQuittance: numeroQuittance,
      dateDebutCouverture: dateDebut,
      dateFinCouverture: dateFin,
      valeurAssuree: prime * 10, // Estimation basique
      formule: formule.displayName,
      garanties: formule.garantiesIncluses,
      franchise: franchise,
    );

    await _firestore
        .collection(_vehiculesAssuresCollection)
        .add(vehiculeAssure.toFirestore());

    debugPrint('[ContratService] ✅ Véhicule assuré créé pour contrat: $contratId');
  }

  /// 🔢 Générer un numéro de contrat unique
  static Future<String> _genererNumeroContrat(String compagnieId) async {
    try {
      // Récupérer la compagnie pour obtenir son code
      final compagnieDoc = await _firestore
          .collection(_compagniesCollection)
          .doc(compagnieId)
          .get();

      String codeCompagnie = 'ASS';
      if (compagnieDoc.exists) {
        final nom = compagnieDoc.data()!['nom'] as String;
        if (nom.contains('STAR')) codeCompagnie = 'STAR';
        else if (nom.contains('Maghrebia')) codeCompagnie = 'MAGH';
        else if (nom.contains('Salim')) codeCompagnie = 'SALIM';
        else if (nom.contains('GAT')) codeCompagnie = 'GAT';
      }

      // Compter les contrats existants pour cette compagnie
      final contratsSnapshot = await _firestore
          .collection(_contratsCollection)
          .where('compagnie_id', isEqualTo: compagnieId)
          .get();

      final numeroSequentiel = (contratsSnapshot.docs.length + 1).toString().padLeft(6, '0');
      final annee = DateTime.now().year.toString();

      return '$codeCompagnie-$annee-$numeroSequentiel';
    } catch (e) {
      debugPrint('[ContratService] ❌ Erreur génération numéro: $e');
      return 'ASS-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    }
  }

  /// 🚗 Obtenir les véhicules assurés d'un conducteur
  static Future<List<VehiculeAvecAssuranceModel>> getVehiculesAvecAssurance(String conducteurId) async {
    try {
      debugPrint('[ContratService] 🚗 Récupération véhicules pour: $conducteurId');

      // Récupérer tous les véhicules du conducteur
      final vehiculesSnapshot = await _firestore
          .collection(_vehiculesCollection)
          .where('proprietaireId', isEqualTo: conducteurId)
          .get();

      final List<VehiculeAvecAssuranceModel> vehiculesAvecAssurance = [];

      for (final vehiculeDoc in vehiculesSnapshot.docs) {
        final vehicule = VehiculeModel.fromFirestore(vehiculeDoc);

        // Chercher l'assurance active pour ce véhicule
        final assuranceSnapshot = await _firestore
            .collection(_vehiculesAssuresCollection)
            .where('vehicule_id', isEqualTo: vehiculeDoc.id)
            .where('conducteur_id', isEqualTo: conducteurId)
            .where('actif', isEqualTo: true)
            .limit(1)
            .get();

        VehiculeAssureModel? assurance;
        String? compagnieNom;
        String? agenceNom;

        if (assuranceSnapshot.docs.isNotEmpty) {
          assurance = VehiculeAssureModel.fromFirestore(assuranceSnapshot.docs.first);

          // Récupérer le nom de la compagnie
          final compagnieDoc = await _firestore
              .collection(_compagniesCollection)
              .doc(assurance.compagnieId)
              .get();
          if (compagnieDoc.exists) {
            compagnieNom = compagnieDoc.data()!['nom'] as String;
          }

          // Récupérer le nom de l'agence
          final agenceDoc = await _firestore
              .collection(_agencesCollection)
              .doc(assurance.agenceId)
              .get();
          if (agenceDoc.exists) {
            agenceNom = agenceDoc.data()!['nom'] as String;
          }
        }

        vehiculesAvecAssurance.add(VehiculeAvecAssuranceModel(
          vehicule: vehicule,
          assurance: assurance,
          compagnieNom: compagnieNom,
          agenceNom: agenceNom,
        ));
      }

      debugPrint('[ContratService] ✅ ${vehiculesAvecAssurance.length} véhicules récupérés');
      return vehiculesAvecAssurance;
    } catch (e) {
      debugPrint('[ContratService] ❌ Erreur récupération véhicules: $e');
      return [];
    }
  }

  /// 📄 Obtenir les contrats d'un conducteur
  static Future<List<ContratModel>> getContratsByConducteur(String conducteurId) async {
    try {
      final snapshot = await _firestore
          .collection(_contratsCollection)
          .where('conducteur_id', isEqualTo: conducteurId)
          .orderBy('date_creation', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ContratModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('[ContratService] ❌ Erreur récupération contrats: $e');
      return [];
    }
  }

  /// 📄 Obtenir les contrats d'une agence
  static Future<List<ContratModel>> getContratsByAgence(String agenceId) async {
    try {
      final snapshot = await _firestore
          .collection(_contratsCollection)
          .where('agence_id', isEqualTo: agenceId)
          .orderBy('date_creation', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ContratModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('[ContratService] ❌ Erreur récupération contrats agence: $e');
      return [];
    }
  }

  /// 🔄 Renouveler un contrat
  static Future<String?> renouvellerContrat(String contratId, DateTime nouvelleDateFin) async {
    try {
      await _firestore
          .collection(_contratsCollection)
          .doc(contratId)
          .update({
        'date_fin': Timestamp.fromDate(nouvelleDateFin),
        'date_modification': Timestamp.now(),
        'status': ContratStatus.actif.name,
      });

      // Mettre à jour le véhicule assuré correspondant
      final vehiculeAssureSnapshot = await _firestore
          .collection(_vehiculesAssuresCollection)
          .where('contrat_id', isEqualTo: contratId)
          .get();

      for (final doc in vehiculeAssureSnapshot.docs) {
        await doc.reference.update({
          'date_fin_couverture': Timestamp.fromDate(nouvelleDateFin),
          'date_modification': Timestamp.now(),
          'actif': true,
        });
      }

      debugPrint('[ContratService] ✅ Contrat renouvelé: $contratId');
      return contratId;
    } catch (e) {
      debugPrint('[ContratService] ❌ Erreur renouvellement: $e');
      return null;
    }
  }

  /// ❌ Résilier un contrat
  static Future<bool> resilierContrat(String contratId, String motif) async {
    try {
      await _firestore
          .collection(_contratsCollection)
          .doc(contratId)
          .update({
        'status': ContratStatus.resilie.name,
        'date_modification': Timestamp.now(),
        'conditions.motif_resiliation': motif,
      });

      // Désactiver le véhicule assuré correspondant
      final vehiculeAssureSnapshot = await _firestore
          .collection(_vehiculesAssuresCollection)
          .where('contrat_id', isEqualTo: contratId)
          .get();

      for (final doc in vehiculeAssureSnapshot.docs) {
        await doc.reference.update({
          'actif': false,
          'date_modification': Timestamp.now(),
        });
      }

      debugPrint('[ContratService] ✅ Contrat résilié: $contratId');
      return true;
    } catch (e) {
      debugPrint('[ContratService] ❌ Erreur résiliation: $e');
      return false;
    }
  }
}
