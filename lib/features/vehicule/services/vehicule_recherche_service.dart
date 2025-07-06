import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/vehicule_recherche_model.dart';
import '../models/vehicule_assure_model.dart';

/// 🔍 Service de recherche véhicule tiers
class VehiculeRechercheService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔍 Rechercher un véhicule par critères
  static Future<List<VehiculeAssureModel>> rechercherVehicule({
    required String conducteurRechercheur,
    required CriteresRecherche criteres,
    ContexteRecherche contexte = ContexteRecherche.declarationAccident,
    String? sessionId,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      debugPrint('🔍 Recherche véhicule avec critères: ${criteres.description}');

      // Construire la requête Firestore
      Query query = _firestore.collection('vehicules_assures');

      // Appliquer les filtres selon les critères
      if (criteres.assurance?.isNotEmpty == true) {
        query = query.where('assureur_id', isEqualTo: criteres.assurance!.toUpperCase());
      }

      if (criteres.numeroContrat?.isNotEmpty == true) {
        query = query.where('numero_contrat', isEqualTo: criteres.numeroContrat!);
      }

      if (criteres.immatriculation?.isNotEmpty == true) {
        query = query.where('vehicule.immatriculation', isEqualTo: criteres.immatriculation!.toUpperCase());
      }

      // Exécuter la requête
      final snapshot = await query.get();
      
      List<VehiculeAssureModel> resultats = snapshot.docs
          .map((doc) => VehiculeAssureModel.fromFirestore(doc))
          .toList();

      // Filtres additionnels en mémoire (pour les champs non indexés)
      if (criteres.marque?.isNotEmpty == true) {
        resultats = resultats.where((v) => 
          v.vehicule.marque.toLowerCase().contains(criteres.marque!.toLowerCase())
        ).toList();
      }

      if (criteres.modele?.isNotEmpty == true) {
        resultats = resultats.where((v) => 
          v.vehicule.modele.toLowerCase().contains(criteres.modele!.toLowerCase())
        ).toList();
      }

      if (criteres.proprietaireNom?.isNotEmpty == true) {
        resultats = resultats.where((v) => 
          v.proprietaire.nom.toLowerCase().contains(criteres.proprietaireNom!.toLowerCase())
        ).toList();
      }

      if (criteres.proprietairePrenom?.isNotEmpty == true) {
        resultats = resultats.where((v) => 
          v.proprietaire.prenom.toLowerCase().contains(criteres.proprietairePrenom!.toLowerCase())
        ).toList();
      }

      if (criteres.proprietaireCin?.isNotEmpty == true) {
        resultats = resultats.where((v) => 
          v.proprietaire.cin == criteres.proprietaireCin!
        ).toList();
      }

      stopwatch.stop();

      // Enregistrer la recherche
      await _enregistrerRecherche(
        conducteurRechercheur: conducteurRechercheur,
        criteres: criteres,
        resultats: resultats,
        tempsRecherche: stopwatch.elapsedMilliseconds,
        contexte: contexte,
        sessionId: sessionId,
      );

      debugPrint('✅ Recherche terminée: ${resultats.length} résultats en ${stopwatch.elapsedMilliseconds}ms');
      return resultats;

    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ Erreur recherche véhicule: $e');
      
      // Enregistrer la recherche échouée
      await _enregistrerRecherche(
        conducteurRechercheur: conducteurRechercheur,
        criteres: criteres,
        resultats: [],
        tempsRecherche: stopwatch.elapsedMilliseconds,
        contexte: contexte,
        sessionId: sessionId,
        erreur: e.toString(),
      );
      
      rethrow;
    }
  }

  /// 📝 Enregistrer une recherche dans l'historique
  static Future<void> _enregistrerRecherche({
    required String conducteurRechercheur,
    required CriteresRecherche criteres,
    required List<VehiculeAssureModel> resultats,
    required int tempsRecherche,
    required ContexteRecherche contexte,
    String? sessionId,
    String? erreur,
  }) async {
    try {
      final now = DateTime.now();
      final rechercheId = _firestore.collection('vehicules_recherches').doc().id;

      final recherche = VehiculeRechercheModel(
        id: rechercheId,
        conducteurRechercheur: conducteurRechercheur,
        criteres: criteres,
        resultatTrouve: resultats.isNotEmpty,
        vehiculeTrouve: resultats.length == 1 ? resultats.first.id : null,
        vehiculesPossibles: resultats.map((v) => v.id).toList(),
        dateRecherche: now,
        contexte: contexte,
        sessionId: sessionId,
        commentaire: erreur,
        tempsRecherche: tempsRecherche,
        createdAt: now,
      );

      await _firestore
          .collection('vehicules_recherches')
          .doc(rechercheId)
          .set(recherche.toFirestore());

      debugPrint('📝 Recherche enregistrée: $rechercheId');
    } catch (e) {
      debugPrint('❌ Erreur enregistrement recherche: $e');
      // Ne pas faire échouer la recherche principale
    }
  }

  /// 🔍 Recherche rapide par immatriculation
  static Future<VehiculeAssureModel?> rechercherParImmatriculation(String immatriculation) async {
    try {
      debugPrint('🔍 Recherche rapide par immatriculation: $immatriculation');

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
      debugPrint('✅ Véhicule trouvé: ${vehicule.vehicule.marque} ${vehicule.vehicule.modele}');
      return vehicule;

    } catch (e) {
      debugPrint('❌ Erreur recherche par immatriculation: $e');
      rethrow;
    }
  }

  /// 🔍 Recherche rapide par numéro de contrat
  static Future<VehiculeAssureModel?> rechercherParContrat(String numeroContrat) async {
    try {
      debugPrint('🔍 Recherche rapide par contrat: $numeroContrat');

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
      debugPrint('✅ Véhicule trouvé: ${vehicule.vehicule.marque} ${vehicule.vehicule.modele}');
      return vehicule;

    } catch (e) {
      debugPrint('❌ Erreur recherche par contrat: $e');
      rethrow;
    }
  }

  /// 📋 Obtenir l'historique des recherches d'un conducteur
  static Future<List<VehiculeRechercheModel>> getHistoriqueRecherches(String conducteurId) async {
    try {
      final snapshot = await _firestore
          .collection('vehicules_recherches')
          .where('conducteur_rechercheur', isEqualTo: conducteurId)
          .orderBy('date_recherche', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => VehiculeRechercheModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération historique recherches: $e');
      rethrow;
    }
  }

  /// 📊 Obtenir les statistiques de recherche
  static Future<StatistiquesRecherche> getStatistiquesRecherche({
    String? conducteurId,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    try {
      Query query = _firestore.collection('vehicules_recherches');

      if (conducteurId != null) {
        query = query.where('conducteur_rechercheur', isEqualTo: conducteurId);
      }

      if (dateDebut != null) {
        query = query.where('date_recherche', isGreaterThanOrEqualTo: Timestamp.fromDate(dateDebut));
      }

      if (dateFin != null) {
        query = query.where('date_recherche', isLessThanOrEqualTo: Timestamp.fromDate(dateFin));
      }

      final snapshot = await query.get();
      
      int totalRecherches = snapshot.docs.length;
      int recherchesReussies = 0;
      int recherchesEchouees = 0;
      int tempsTotal = 0;
      Map<String, int> recherchesParAssurance = {};
      Map<String, int> recherchesParContexte = {};

      for (final doc in snapshot.docs) {
        final recherche = VehiculeRechercheModel.fromFirestore(doc);
        
        if (recherche.resultatTrouve) {
          recherchesReussies++;
        } else {
          recherchesEchouees++;
        }

        tempsTotal += recherche.tempsRecherche;

        // Statistiques par assurance
        final assurance = recherche.criteres.assurance ?? 'Non spécifiée';
        recherchesParAssurance[assurance] = (recherchesParAssurance[assurance] ?? 0) + 1;

        // Statistiques par contexte
        final contexte = recherche.contexte.name;
        recherchesParContexte[contexte] = (recherchesParContexte[contexte] ?? 0) + 1;
      }

      double tempsRecherchesMoyen = totalRecherches > 0 ? tempsTotal / totalRecherches : 0;

      return StatistiquesRecherche(
        totalRecherches: totalRecherches,
        recherchesReussies: recherchesReussies,
        recherchesEchouees: recherchesEchouees,
        tempsRecherchesMoyen: tempsRecherchesMoyen,
        recherchesParAssurance: recherchesParAssurance,
        recherchesParContexte: recherchesParContexte,
      );

    } catch (e) {
      debugPrint('❌ Erreur statistiques recherche: $e');
      rethrow;
    }
  }

  /// 🔍 Suggestions de recherche basées sur l'historique
  static Future<List<CriteresRecherche>> getSuggestionsRecherche(String conducteurId) async {
    try {
      final snapshot = await _firestore
          .collection('vehicules_recherches')
          .where('conducteur_rechercheur', isEqualTo: conducteurId)
          .where('resultat_trouve', isEqualTo: true)
          .orderBy('date_recherche', descending: true)
          .limit(10)
          .get();

      final suggestions = <CriteresRecherche>[];
      final criteresVus = <String>{};

      for (final doc in snapshot.docs) {
        final recherche = VehiculeRechercheModel.fromFirestore(doc);
        final critereKey = '${recherche.criteres.assurance}_${recherche.criteres.immatriculation}';
        
        if (!criteresVus.contains(critereKey)) {
          suggestions.add(recherche.criteres);
          criteresVus.add(critereKey);
        }
      }

      return suggestions;
    } catch (e) {
      debugPrint('❌ Erreur suggestions recherche: $e');
      return [];
    }
  }

  /// 🧹 Nettoyer les anciennes recherches
  static Future<void> nettoyerAnciennesRecherches({int joursConservation = 90}) async {
    try {
      final dateLimit = DateTime.now().subtract(Duration(days: joursConservation));
      
      final snapshot = await _firestore
          .collection('vehicules_recherches')
          .where('date_recherche', isLessThan: Timestamp.fromDate(dateLimit))
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('ℹ️ Aucune ancienne recherche à nettoyer');
        return;
      }

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('🧹 ${snapshot.docs.length} anciennes recherches supprimées');

    } catch (e) {
      debugPrint('❌ Erreur nettoyage anciennes recherches: $e');
      rethrow;
    }
  }
}
