import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

/// 🏢 Service pour gérer la structure complète d'assurance
/// Hiérarchie: Compagnies → Agences → Agents → Clients → Contrats → Constats
class InsuranceStructureService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🏢 GESTION DES COMPAGNIES D'ASSURANCE

  /// Créer une nouvelle compagnie d'assurance
  static Future<Map<String, dynamic>> createCompagnie({
    required String nom,
    required String adresse,
    required String telephone,
    required String email,
    String? siteWeb,
    String? logo,
  }) async {
    try {
      final compagnieId = _generateCompagnieId();
      final codeCompagnie = _generateCompagnieCode(nom);

      final compagnieData = {
        'id': compagnieId,
        'code': codeCompagnie,
        'nom': nom,
        'adresse': adresse,
        'telephone': telephone,
        'email': email,
        'siteWeb': siteWeb,
        'logo': logo,
        'status': 'active',
        'dateCreation': FieldValue.serverTimestamp(),
        'derniereMiseAJour': FieldValue.serverTimestamp(),
        'statistiques': {
          'nombreAgences': 0,
          'nombreAgents': 0,
          'nombreClients': 0,
          'nombreContrats': 0,
          'chiffreAffaires': 0.0,
        },
      };

      await _firestore
          .collection('compagnies_assurance')
          .doc(compagnieId)
          .set(compagnieData);

      debugPrint('✅ Compagnie créée: $nom ($codeCompagnie)');
      return {
        'success': true,
        'compagnieId': compagnieId,
        'code': codeCompagnie,
        'message': 'Compagnie créée avec succès',
      };
    } catch (e) {
      debugPrint('❌ Erreur création compagnie: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de la création de la compagnie',
      };
    }
  }

  /// Créer une nouvelle agence
  static Future<Map<String, dynamic>> createAgence({
    required String compagnieId,
    required String nom,
    required String adresse,
    required String telephone,
    required String email,
    String? responsable,
  }) async {
    try {
      final agenceId = _generateAgenceId();
      final codeAgence = _generateAgenceCode(compagnieId, nom);

      final agenceData = {
        'id': agenceId,
        'code': codeAgence,
        'compagnieId': compagnieId,
        'nom': nom,
        'adresse': adresse,
        'telephone': telephone,
        'email': email,
        'responsable': responsable,
        'status': 'active',
        'dateCreation': FieldValue.serverTimestamp(),
        'derniereMiseAJour': FieldValue.serverTimestamp(),
        'statistiques': {
          'nombreAgents': 0,
          'nombreClients': 0,
          'nombreContrats': 0,
          'chiffreAffaires': 0.0,
        },
      };

      // Utiliser subcollection pour les agences
      await _firestore
          .collection('compagnies_assurance')
          .doc(compagnieId)
          .collection('agences')
          .doc(agenceId)
          .set(agenceData);

      // Mettre à jour les statistiques de la compagnie
      await _updateCompagnieStats(compagnieId);

      debugPrint('✅ Agence créée: $nom ($codeAgence)');
      return {
        'success': true,
        'agenceId': agenceId,
        'code': codeAgence,
        'message': 'Agence créée avec succès',
      };
    } catch (e) {
      debugPrint('❌ Erreur création agence: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de la création de l\'agence',
      };
    }
  }

  /// Créer un nouveau contrat d'assurance
  static Future<Map<String, dynamic>> createContrat({
    required String compagnieId,
    required String agenceId,
    required String agentId,
    required String conducteurId,
    required String vehiculeId,
    required String typeAssurance,
    required DateTime dateDebut,
    required DateTime dateFin,
    required double primeAnnuelle,
    required double franchise,
    required List<String> garanties,
    Map<String, dynamic>? conditions,
  }) async {
    try {
      final contratId = _generateContratId();
      final numeroContrat = _generateNumeroContrat(compagnieId);

      final contratData = {
        'id': contratId,
        'numeroContrat': numeroContrat,
        'compagnieId': compagnieId,
        'agenceId': agenceId,
        'agentId': agentId,
        'conducteurId': conducteurId,
        'vehiculeId': vehiculeId,
        'typeAssurance': typeAssurance,
        'dateDebut': Timestamp.fromDate(dateDebut),
        'dateFin': Timestamp.fromDate(dateFin),
        'primeAnnuelle': primeAnnuelle,
        'franchise': franchise,
        'garanties': garanties,
        'conditions': conditions ?? {},
        'status': 'actif',
        'dateCreation': FieldValue.serverTimestamp(),
        'derniereMiseAJour': FieldValue.serverTimestamp(),
      };

      // Sauvegarder le contrat
      await _firestore
          .collection('contrats_assurance')
          .doc(contratId)
          .set(contratData);

      // Mettre à jour le véhicule avec les infos du contrat
      await _updateVehiculeContrat(vehiculeId, contratData);

      // Mettre à jour les statistiques
      await _updateAgenceStats(compagnieId, agenceId);
      await _updateCompagnieStats(compagnieId);

      debugPrint('✅ Contrat créé: $numeroContrat');
      return {
        'success': true,
        'contratId': contratId,
        'numeroContrat': numeroContrat,
        'message': 'Contrat créé avec succès',
      };
    } catch (e) {
      debugPrint('❌ Erreur création contrat: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de la création du contrat',
      };
    }
  }

  // 🔧 MÉTHODES UTILITAIRES

  /// Générer un ID unique pour une compagnie
  static String _generateCompagnieId() {
    return 'COMP_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Générer un code compagnie (3 premières lettres + nombre)
  static String _generateCompagnieCode(String nom) {
    final prefix = nom.toUpperCase().replaceAll(' ', '').substring(0, 3.clamp(0, nom.length));
    final suffix = Random().nextInt(999).toString().padLeft(3, '0');
    return '$prefix$suffix';
  }

  /// Générer un ID unique pour une agence
  static String _generateAgenceId() {
    return 'AGE_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Générer un code agence
  static String _generateAgenceCode(String compagnieId, String nom) {
    final compPrefix = compagnieId.substring(5, 8); // Prendre 3 chars après COMP_
    final agePrefix = nom.toUpperCase().replaceAll(' ', '').substring(0, 2.clamp(0, nom.length));
    final suffix = Random().nextInt(99).toString().padLeft(2, '0');
    return '$compPrefix$agePrefix$suffix';
  }

  /// Générer un ID unique pour un contrat
  static String _generateContratId() {
    return 'CTR_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Générer un numéro de contrat
  static String _generateNumeroContrat(String compagnieId) {
    final year = DateTime.now().year.toString();
    final month = DateTime.now().month.toString().padLeft(2, '0');
    final random = Random().nextInt(999999).toString().padLeft(6, '0');
    final compPrefix = compagnieId.substring(5, 8);
    return '$compPrefix$year$month$random';
  }

  /// Mettre à jour les statistiques d'une compagnie
  static Future<void> _updateCompagnieStats(String compagnieId) async {
    try {
      // Compter les agences
      final agencesSnapshot = await _firestore
          .collection('compagnies_assurance')
          .doc(compagnieId)
          .collection('agences')
          .where('status', isEqualTo: 'active')
          .get();

      // Compter les contrats
      final contratsSnapshot = await _firestore
          .collection('contrats_assurance')
          .where('compagnieId', isEqualTo: compagnieId)
          .where('status', isEqualTo: 'actif')
          .get();

      double chiffreAffaires = 0;
      for (final doc in contratsSnapshot.docs) {
        final data = doc.data();
        if (data['primeAnnuelle'] != null) {
          chiffreAffaires += (data['primeAnnuelle'] as num).toDouble();
        }
      }

      await _firestore
          .collection('compagnies_assurance')
          .doc(compagnieId)
          .update({
        'statistiques.nombreAgences': agencesSnapshot.docs.length,
        'statistiques.nombreContrats': contratsSnapshot.docs.length,
        'statistiques.chiffreAffaires': chiffreAffaires,
        'derniereMiseAJour': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Erreur mise à jour stats compagnie: $e');
    }
  }

  /// Mettre à jour les statistiques d'une agence
  static Future<void> _updateAgenceStats(String compagnieId, String agenceId) async {
    try {
      final contratsSnapshot = await _firestore
          .collection('contrats_assurance')
          .where('compagnieId', isEqualTo: compagnieId)
          .where('agenceId', isEqualTo: agenceId)
          .where('status', isEqualTo: 'actif')
          .get();

      double chiffreAffaires = 0;
      for (final doc in contratsSnapshot.docs) {
        final data = doc.data();
        if (data['primeAnnuelle'] != null) {
          chiffreAffaires += (data['primeAnnuelle'] as num).toDouble();
        }
      }

      await _firestore
          .collection('compagnies_assurance')
          .doc(compagnieId)
          .collection('agences')
          .doc(agenceId)
          .update({
        'statistiques.nombreContrats': contratsSnapshot.docs.length,
        'statistiques.chiffreAffaires': chiffreAffaires,
        'derniereMiseAJour': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Erreur mise à jour stats agence: $e');
    }
  }

  /// Mettre à jour le véhicule avec les informations du contrat
  static Future<void> _updateVehiculeContrat(String vehiculeId, Map<String, dynamic> contratData) async {
    try {
      await _firestore
          .collection('vehicules')
          .doc(vehiculeId)
          .update({
        'contratActuel': {
          'contratId': contratData['id'],
          'numeroContrat': contratData['numeroContrat'],
          'compagnieId': contratData['compagnieId'],
          'agenceId': contratData['agenceId'],
          'typeAssurance': contratData['typeAssurance'],
          'dateDebut': contratData['dateDebut'],
          'dateFin': contratData['dateFin'],
          'status': contratData['status'],
        },
        'derniereMiseAJour': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Erreur mise à jour véhicule: $e');
    }
  }
}
