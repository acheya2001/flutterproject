import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/vehicule_assure_model.dart';

/// 🚗 Service de gestion des véhicules assurés
class VehiculeAssureService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📋 Obtenir tous les véhicules
  Future<List<VehiculeAssureModel>> getAllVehicles() async {
    try {
      debugPrint('📋 Récupération de tous les véhicules...');

      final snapshot = await _firestore
          .collection('vehicules_assures')
          .orderBy('createdAt', descending: true)
          .get();

      final vehicules = snapshot.docs
          .map((doc) => VehiculeAssureModel.fromFirestore(doc))
          .toList();

      debugPrint('✅ ${vehicules.length} véhicules récupérés');
      return vehicules;
    } catch (e) {
      debugPrint('❌ Erreur récupération véhicules: $e');
      rethrow;
    }
  }

  /// 🔍 Obtenir un véhicule par ID
  Future<VehiculeAssureModel?> getVehicleById(String vehiculeId) async {
    try {
      debugPrint('🔍 Récupération véhicule: $vehiculeId');

      final doc = await _firestore
          .collection('vehicules_assures')
          .doc(vehiculeId)
          .get();

      if (!doc.exists) {
        debugPrint('ℹ️ Véhicule non trouvé: $vehiculeId');
        return null;
      }

      final vehicule = VehiculeAssureModel.fromFirestore(doc);
      debugPrint('✅ Véhicule trouvé: ${vehicule.descriptionVehicule}');
      return vehicule;
    } catch (e) {
      debugPrint('❌ Erreur récupération véhicule: $e');
      rethrow;
    }
  }

  /// 🏢 Obtenir les véhicules d'un assureur
  Future<List<VehiculeAssureModel>> getVehiclesByAssureur(String assureurId) async {
    try {
      debugPrint('🏢 Récupération véhicules assureur: $assureurId');

      final snapshot = await _firestore
          .collection('vehicules_assures')
          .where('assureur_id', isEqualTo: assureurId)
          .orderBy('createdAt', descending: true)
          .get();

      final vehicules = snapshot.docs
          .map((doc) => VehiculeAssureModel.fromFirestore(doc))
          .toList();

      debugPrint('✅ ${vehicules.length} véhicules trouvés pour $assureurId');
      return vehicules;
    } catch (e) {
      debugPrint('❌ Erreur récupération véhicules assureur: $e');
      rethrow;
    }
  }

  /// 🔍 Rechercher par immatriculation
  Future<VehiculeAssureModel?> getVehicleByImmatriculation(String immatriculation) async {
    try {
      debugPrint('🔍 Recherche par immatriculation: $immatriculation');

      final snapshot = await _firestore
          .collection('vehicules_assures')
          .where('vehicule.immatriculation', isEqualTo: immatriculation.toUpperCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('ℹ️ Aucun véhicule trouvé pour cette immatriculation');
        return null;
      }

      final vehicule = VehiculeAssureModel.fromFirestore(snapshot.docs.first);
      debugPrint('✅ Véhicule trouvé: ${vehicule.descriptionVehicule}');
      return vehicule;
    } catch (e) {
      debugPrint('❌ Erreur recherche par immatriculation: $e');
      rethrow;
    }
  }

  /// 📄 Rechercher par numéro de contrat
  Future<VehiculeAssureModel?> getVehicleByContrat(String numeroContrat) async {
    try {
      debugPrint('📄 Recherche par contrat: $numeroContrat');

      final snapshot = await _firestore
          .collection('vehicules_assures')
          .where('numero_contrat', isEqualTo: numeroContrat)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('ℹ️ Aucun véhicule trouvé pour ce contrat');
        return null;
      }

      final vehicule = VehiculeAssureModel.fromFirestore(snapshot.docs.first);
      debugPrint('✅ Véhicule trouvé: ${vehicule.descriptionVehicule}');
      return vehicule;
    } catch (e) {
      debugPrint('❌ Erreur recherche par contrat: $e');
      rethrow;
    }
  }

  /// ➕ Créer un nouveau véhicule assuré
  Future<VehiculeAssureModel> createVehicle(VehiculeAssureModel vehicule) async {
    try {
      debugPrint('➕ Création véhicule: ${vehicule.descriptionVehicule}');

      final docRef = _firestore.collection('vehicules_assures').doc();
      final vehiculeWithId = vehicule.copyWith(id: docRef.id);

      await docRef.set(vehiculeWithId.toFirestore());

      debugPrint('✅ Véhicule créé avec ID: ${docRef.id}');
      return vehiculeWithId;
    } catch (e) {
      debugPrint('❌ Erreur création véhicule: $e');
      rethrow;
    }
  }

  /// ✏️ Mettre à jour un véhicule
  Future<VehiculeAssureModel> updateVehicle(VehiculeAssureModel vehicule) async {
    try {
      debugPrint('✏️ Mise à jour véhicule: ${vehicule.id}');

      final vehiculeUpdated = vehicule.copyWith(updatedAt: DateTime.now());

      await _firestore
          .collection('vehicules_assures')
          .doc(vehicule.id)
          .update(vehiculeUpdated.toFirestore());

      debugPrint('✅ Véhicule mis à jour: ${vehicule.id}');
      return vehiculeUpdated;
    } catch (e) {
      debugPrint('❌ Erreur mise à jour véhicule: $e');
      rethrow;
    }
  }

  /// 🗑️ Supprimer un véhicule
  Future<void> deleteVehicle(String vehiculeId) async {
    try {
      debugPrint('🗑️ Suppression véhicule: $vehiculeId');

      await _firestore
          .collection('vehicules_assures')
          .doc(vehiculeId)
          .delete();

      debugPrint('✅ Véhicule supprimé: $vehiculeId');
    } catch (e) {
      debugPrint('❌ Erreur suppression véhicule: $e');
      rethrow;
    }
  }

  /// 📊 Obtenir les statistiques des véhicules
  Future<Map<String, dynamic>> getVehicleStatistics({String? assureurId}) async {
    try {
      Query query = _firestore.collection('vehicules_assures');
      
      if (assureurId != null) {
        query = query.where('assureur_id', isEqualTo: assureurId);
      }

      final snapshot = await query.get();
      
      int totalVehicules = snapshot.docs.length;
      int vehiculesAssures = 0;
      int vehiculesExpires = 0;
      int vehiculesExpirentBientot = 0;
      Map<String, int> vehiculesParAssureur = {};
      Map<String, int> vehiculesParMarque = {};

      for (final doc in snapshot.docs) {
        final vehicule = VehiculeAssureModel.fromFirestore(doc);
        
        if (vehicule.contrat.isActif) {
          vehiculesAssures++;
          if (vehicule.contrat.expireBientot) {
            vehiculesExpirentBientot++;
          }
        } else {
          vehiculesExpires++;
        }

        // Statistiques par assureur
        vehiculesParAssureur[vehicule.assureurId] = 
            (vehiculesParAssureur[vehicule.assureurId] ?? 0) + 1;

        // Statistiques par marque
        vehiculesParMarque[vehicule.vehicule.marque] = 
            (vehiculesParMarque[vehicule.vehicule.marque] ?? 0) + 1;
      }

      return {
        'total_vehicules': totalVehicules,
        'vehicules_assures': vehiculesAssures,
        'vehicules_expires': vehiculesExpires,
        'vehicules_expirent_bientot': vehiculesExpirentBientot,
        'taux_assurance': totalVehicules > 0 ? (vehiculesAssures / totalVehicules) * 100 : 0,
        'vehicules_par_assureur': vehiculesParAssureur,
        'vehicules_par_marque': vehiculesParMarque,
      };
    } catch (e) {
      debugPrint('❌ Erreur statistiques véhicules: $e');
      rethrow;
    }
  }

  /// 🔍 Recherche avancée de véhicules
  Future<List<VehiculeAssureModel>> searchVehicles({
    String? marque,
    String? modele,
    String? assureurId,
    String? proprietaireNom,
    String? proprietaireCin,
    int? anneeMin,
    int? anneeMax,
  }) async {
    try {
      debugPrint('🔍 Recherche avancée véhicules...');

      Query query = _firestore.collection('vehicules_assures');

      // Appliquer les filtres Firestore
      if (assureurId != null) {
        query = query.where('assureur_id', isEqualTo: assureurId);
      }

      final snapshot = await query.get();
      
      List<VehiculeAssureModel> resultats = snapshot.docs
          .map((doc) => VehiculeAssureModel.fromFirestore(doc))
          .toList();

      // Filtres en mémoire
      if (marque != null) {
        resultats = resultats.where((v) => 
          v.vehicule.marque.toLowerCase().contains(marque.toLowerCase())
        ).toList();
      }

      if (modele != null) {
        resultats = resultats.where((v) => 
          v.vehicule.modele.toLowerCase().contains(modele.toLowerCase())
        ).toList();
      }

      if (proprietaireNom != null) {
        resultats = resultats.where((v) => 
          v.proprietaire.nom.toLowerCase().contains(proprietaireNom.toLowerCase()) ||
          v.proprietaire.prenom.toLowerCase().contains(proprietaireNom.toLowerCase())
        ).toList();
      }

      if (proprietaireCin != null) {
        resultats = resultats.where((v) => 
          v.proprietaire.cin == proprietaireCin
        ).toList();
      }

      if (anneeMin != null) {
        resultats = resultats.where((v) => v.vehicule.annee >= anneeMin).toList();
      }

      if (anneeMax != null) {
        resultats = resultats.where((v) => v.vehicule.annee <= anneeMax).toList();
      }

      debugPrint('✅ ${resultats.length} véhicules trouvés');
      return resultats;
    } catch (e) {
      debugPrint('❌ Erreur recherche avancée: $e');
      rethrow;
    }
  }
}
