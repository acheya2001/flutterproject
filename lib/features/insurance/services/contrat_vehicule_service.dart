import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/contrat_assurance_model.dart';

/// 🔧 Service pour gérer les contrats et véhicules assurés
class ContratVehiculeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📄 Créer un nouveau contrat d'assurance
  static Future<String?> creerContrat({
    required String compagnieId,
    required String agenceId,
    required String agentId,
    required String conducteurId,
    required String vehiculeId,
    required String typeContrat,
    required DateTime dateDebut,
    required DateTime dateFin,
    required Map<String, dynamic> prime,
    required List<String> couvertures,
    Map<String, dynamic>? franchises,
    String? notes,
  }) async {
    try {
      // Générer un numéro de contrat unique
      final numeroContrat = await _genererNumeroContrat(compagnieId);
      
      final contrat = ContratAssuranceModel(
        id: '', // Sera généré par Firestore
        numeroContrat: numeroContrat,
        compagnieId: compagnieId,
        agenceId: agenceId,
        agentId: agentId,
        conducteurId: conducteurId,
        vehiculeId: vehiculeId,
        typeContrat: typeContrat,
        dateDebut: dateDebut,
        dateFin: dateFin,
        dateCreation: DateTime.now(),
        statut: 'actif',
        prime: prime,
        couvertures: couvertures,
        franchises: franchises ?? {},
        documents: [],
        historiquePaiements: [],
        notes: notes,
      );

      // Sauvegarder le contrat
      final docRef = await _firestore
          .collection('contrats_assurance')
          .add(contrat.toMap());

      // Mettre à jour le véhicule avec l'ID du contrat
      await _firestore
          .collection('vehicules_assures')
          .doc(vehiculeId)
          .update({'contratId': docRef.id});

      debugPrint('[ContratVehiculeService] ✅ Contrat créé: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('[ContratVehiculeService] ❌ Erreur création contrat: $e');
      return null;
    }
  }

  /// 🚙 Créer un nouveau véhicule assuré
  static Future<String?> creerVehicule({
    required String conducteurId,
    required String immatriculation,
    required String marque,
    required String modele,
    required int annee,
    required String couleur,
    required String numeroSerie,
    String typeVehicule = 'voiture',
    String carburant = 'essence',
    int? puissance,
    int? nombrePlaces,
    double valeurVehicule = 0.0,
    DateTime? dateAchat,
    int? kilometrage,
  }) async {
    try {
      final vehicule = VehiculeAssureModel(
        id: '', // Sera généré par Firestore
        conducteurId: conducteurId,
        contratId: null, // Sera assigné lors de la création du contrat
        immatriculation: immatriculation,
        marque: marque,
        modele: modele,
        annee: annee,
        couleur: couleur,
        numeroSerie: numeroSerie,
        typeVehicule: typeVehicule,
        carburant: carburant,
        puissance: puissance,
        nombrePlaces: nombrePlaces,
        valeurVehicule: valeurVehicule,
        dateAchat: dateAchat,
        kilometrage: kilometrage,
        photos: [],
        documents: [],
        dateCreation: DateTime.now(),
        statut: 'actif',
      );

      // Sauvegarder le véhicule
      final docRef = await _firestore
          .collection('vehicules_assures')
          .add(vehicule.toMap());

      debugPrint('[ContratVehiculeService] ✅ Véhicule créé: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('[ContratVehiculeService] ❌ Erreur création véhicule: $e');
      return null;
    }
  }

  /// 📋 Obtenir les véhicules d'un conducteur
  static Future<List<VehiculeAssureModel>> getVehiculesConducteur(String conducteurId) async {
    try {
      final query = await _firestore
          .collection('vehicules_assures')
          .where('conducteurId', isEqualTo: conducteurId)
          .where('statut', isEqualTo: 'actif')
          .get();

      return query.docs
          .map((doc) => VehiculeAssureModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('[ContratVehiculeService] ❌ Erreur récupération véhicules: $e');
      return [];
    }
  }

  /// 📄 Obtenir les contrats d'un conducteur
  static Future<List<ContratAssuranceModel>> getContratsConducteur(String conducteurId) async {
    try {
      final query = await _firestore
          .collection('contrats_assurance')
          .where('conducteurId', isEqualTo: conducteurId)
          .orderBy('dateCreation', descending: true)
          .get();

      return query.docs
          .map((doc) => ContratAssuranceModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('[ContratVehiculeService] ❌ Erreur récupération contrats: $e');
      return [];
    }
  }

  /// 🔍 Obtenir un contrat par ID
  static Future<ContratAssuranceModel?> getContrat(String contratId) async {
    try {
      final doc = await _firestore
          .collection('contrats_assurance')
          .doc(contratId)
          .get();

      if (doc.exists) {
        return ContratAssuranceModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('[ContratVehiculeService] ❌ Erreur récupération contrat: $e');
      return null;
    }
  }

  /// 🚙 Obtenir un véhicule par ID
  static Future<VehiculeAssureModel?> getVehicule(String vehiculeId) async {
    try {
      final doc = await _firestore
          .collection('vehicules_assures')
          .doc(vehiculeId)
          .get();

      if (doc.exists) {
        return VehiculeAssureModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('[ContratVehiculeService] ❌ Erreur récupération véhicule: $e');
      return null;
    }
  }

  /// 🔍 Rechercher un véhicule par immatriculation
  static Future<VehiculeAssureModel?> getVehiculeParImmatriculation(String immatriculation) async {
    try {
      final query = await _firestore
          .collection('vehicules_assures')
          .where('immatriculation', isEqualTo: immatriculation)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return VehiculeAssureModel.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('[ContratVehiculeService] ❌ Erreur recherche véhicule: $e');
      return null;
    }
  }

  /// 📊 Obtenir les véhicules avec leurs contrats pour un conducteur
  static Future<List<Map<String, dynamic>>> getVehiculesAvecContrats(String conducteurId) async {
    try {
      final vehicules = await getVehiculesConducteur(conducteurId);
      final List<Map<String, dynamic>> result = [];

      for (final vehicule in vehicules) {
        ContratAssuranceModel? contrat;
        if (vehicule.contratId != null) {
          contrat = await getContrat(vehicule.contratId!);
        }

        result.add({
          'vehicule': vehicule,
          'contrat': contrat,
          'isAssure': contrat != null && contrat.isActif,
          'expireBientot': contrat?.expireBientot ?? false,
        });
      }

      return result;
    } catch (e) {
      debugPrint('[ContratVehiculeService] ❌ Erreur récupération véhicules avec contrats: $e');
      return [];
    }
  }

  /// 🔢 Générer un numéro de contrat unique
  static Future<String> _genererNumeroContrat(String compagnieId) async {
    try {
      // Obtenir le code de la compagnie
      final compagnieDoc = await _firestore
          .collection('compagnies_assurance')
          .doc(compagnieId)
          .get();
      
      String codeCompagnie = 'ASS';
      if (compagnieDoc.exists) {
        final data = compagnieDoc.data() as Map<String, dynamic>;
        codeCompagnie = data['code'] ?? 'ASS';
      }

      // Compter les contrats existants pour cette compagnie
      final query = await _firestore
          .collection('contrats_assurance')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      final numeroSequentiel = query.docs.length + 1;
      final annee = DateTime.now().year;
      
      return '$codeCompagnie-$annee-${numeroSequentiel.toString().padLeft(6, '0')}';
    } catch (e) {
      debugPrint('[ContratVehiculeService] ❌ Erreur génération numéro: $e');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'CONT-$timestamp';
    }
  }

  /// 📈 Obtenir les statistiques d'un agent
  static Future<Map<String, int>> getStatistiquesAgent(String agentId) async {
    try {
      final contratsQuery = await _firestore
          .collection('contrats_assurance')
          .where('agentId', isEqualTo: agentId)
          .get();

      final contratsActifs = contratsQuery.docs
          .where((doc) {
            final data = doc.data();
            return data['statut'] == 'actif';
          })
          .length;

      final clientsUniques = contratsQuery.docs
          .map((doc) => doc.data()['conducteurId'])
          .toSet()
          .length;

      return {
        'nombreContrats': contratsQuery.docs.length,
        'contratsActifs': contratsActifs,
        'nombreClients': clientsUniques,
      };
    } catch (e) {
      debugPrint('[ContratVehiculeService] ❌ Erreur statistiques agent: $e');
      return {
        'nombreContrats': 0,
        'contratsActifs': 0,
        'nombreClients': 0,
      };
    }
  }

  /// 🔄 Renouveler un contrat
  static Future<String?> renouvellerContrat(String contratId, DateTime nouvelleDateFin) async {
    try {
      await _firestore
          .collection('contrats_assurance')
          .doc(contratId)
          .update({
            'dateFin': Timestamp.fromDate(nouvelleDateFin),
            'statut': 'actif',
          });

      debugPrint('[ContratVehiculeService] ✅ Contrat renouvelé: $contratId');
      return contratId;
    } catch (e) {
      debugPrint('[ContratVehiculeService] ❌ Erreur renouvellement: $e');
      return null;
    }
  }

  /// ❌ Résilier un contrat
  static Future<bool> resilierContrat(String contratId, String motif) async {
    try {
      await _firestore
          .collection('contrats_assurance')
          .doc(contratId)
          .update({
            'statut': 'resilie',
            'motifResiliation': motif,
            'dateResiliation': Timestamp.now(),
          });

      debugPrint('[ContratVehiculeService] ✅ Contrat résilié: $contratId');
      return true;
    } catch (e) {
      debugPrint('[ContratVehiculeService] ❌ Erreur résiliation: $e');
      return false;
    }
  }
}
