import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/vehicule_complet_model.dart';

/// 🔍 Service de vérification de véhicule par assurance et contrat
class VehiculeVerificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔍 Vérifier un véhicule par compagnie d'assurance et numéro de contrat
  static Future<VehiculeVerificationResult> verifierVehicule({
    required String compagnieAssurance,
    required String numeroContrat,
    required String conducteurEmail,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      debugPrint('🔍 Vérification véhicule: $compagnieAssurance - $numeroContrat');

      // 1. Rechercher le véhicule par compagnie et numéro de contrat
      final vehiculeQuery = await _firestore
          .collection('vehicules_complets')
          .where('contrat.compagnie_id', isEqualTo: compagnieAssurance.toUpperCase())
          .where('contrat.numero_contrat', isEqualTo: numeroContrat)
          .limit(1)
          .get();

      if (vehiculeQuery.docs.isEmpty) {
        stopwatch.stop();
        debugPrint('❌ Véhicule non trouvé');
        
        return VehiculeVerificationResult(
          success: false,
          message: 'Véhicule non trouvé dans la base de données de $compagnieAssurance',
          errorType: VerificationErrorType.vehiculeNonTrouve,
          tempsVerification: stopwatch.elapsedMilliseconds,
        );
      }

      final vehicule = VehiculeCompletModel.fromFirestore(vehiculeQuery.docs.first);

      // 2. Vérifier que le contrat est actif
      if (!vehicule.contrat.isActif) {
        stopwatch.stop();
        debugPrint('❌ Contrat inactif');
        
        return VehiculeVerificationResult(
          success: false,
          vehicule: vehicule,
          message: 'Le contrat d\'assurance est inactif ou expiré',
          errorType: VerificationErrorType.contratInactif,
          tempsVerification: stopwatch.elapsedMilliseconds,
        );
      }

      // 3. Vérifier que le conducteur est autorisé
      if (!vehicule.isConducteurAutorise(conducteurEmail)) {
        stopwatch.stop();
        debugPrint('❌ Conducteur non autorisé');
        
        return VehiculeVerificationResult(
          success: false,
          vehicule: vehicule,
          message: 'Vous n\'êtes pas autorisé à conduire ce véhicule',
          errorType: VerificationErrorType.conducteurNonAutorise,
          tempsVerification: stopwatch.elapsedMilliseconds,
        );
      }

      // 4. Vérifier les droits du conducteur
      final droits = vehicule.getDroitsConducteur(conducteurEmail);
      if (!droits.contains('declarer_sinistre')) {
        stopwatch.stop();
        debugPrint('❌ Droits insuffisants');
        
        return VehiculeVerificationResult(
          success: false,
          vehicule: vehicule,
          message: 'Vous n\'avez pas le droit de déclarer un sinistre pour ce véhicule',
          errorType: VerificationErrorType.droitsInsuffisants,
          tempsVerification: stopwatch.elapsedMilliseconds,
        );
      }

      stopwatch.stop();
      debugPrint('✅ Véhicule vérifié avec succès: ${vehicule.descriptionVehicule}');

      // Enregistrer la vérification réussie
      await _enregistrerVerification(
        vehicule: vehicule,
        conducteurEmail: conducteurEmail,
        success: true,
        tempsVerification: stopwatch.elapsedMilliseconds,
      );

      return VehiculeVerificationResult(
        success: true,
        vehicule: vehicule,
        message: 'Véhicule vérifié avec succès',
        droitsConducteur: droits,
        tempsVerification: stopwatch.elapsedMilliseconds,
      );

    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ Erreur vérification véhicule: $e');
      
      return VehiculeVerificationResult(
        success: false,
        message: 'Erreur lors de la vérification: $e',
        errorType: VerificationErrorType.erreurTechnique,
        tempsVerification: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// 📝 Enregistrer une vérification dans l'historique
  static Future<void> _enregistrerVerification({
    required VehiculeCompletModel? vehicule,
    required String conducteurEmail,
    required bool success,
    required int tempsVerification,
    String? errorType,
  }) async {
    try {
      final now = DateTime.now();
      final verificationId = _firestore.collection('vehicules_verifications').doc().id;

      final verificationData = {
        'id': verificationId,
        'vehicule_id': vehicule?.id,
        'numero_contrat': vehicule?.contrat.numeroContrat,
        'compagnie_id': vehicule?.contrat.compagnieId,
        'conducteur_email': conducteurEmail,
        'success': success,
        'error_type': errorType,
        'temps_verification': tempsVerification,
        'date_verification': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
      };

      await _firestore
          .collection('vehicules_verifications')
          .doc(verificationId)
          .set(verificationData);

      debugPrint('📝 Vérification enregistrée: $verificationId');
    } catch (e) {
      debugPrint('❌ Erreur enregistrement vérification: $e');
      // Ne pas faire échouer la vérification principale
    }
  }

  /// 📋 Obtenir l'historique des vérifications d'un conducteur
  static Future<List<VerificationHistoryModel>> getHistoriqueVerifications(String conducteurEmail) async {
    try {
      final snapshot = await _firestore
          .collection('vehicules_verifications')
          .where('conducteur_email', isEqualTo: conducteurEmail.toLowerCase())
          .orderBy('date_verification', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => VerificationHistoryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération historique vérifications: $e');
      return [];
    }
  }

  /// 🏢 Obtenir la liste des compagnies d'assurance disponibles
  static Future<List<String>> getCompagniesAssurance() async {
    try {
      final snapshot = await _firestore
          .collection('compagnies_assurance')
          .orderBy('nom')
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['code'] as String)
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération compagnies: $e');
      return ['STAR', 'MAGHREBIA', 'LLOYD', 'GAT', 'AST']; // Fallback
    }
  }

  /// 📊 Obtenir les statistiques de vérification
  static Future<Map<String, dynamic>> getStatistiquesVerification({
    String? conducteurEmail,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    try {
      Query query = _firestore.collection('vehicules_verifications');

      if (conducteurEmail != null) {
        query = query.where('conducteur_email', isEqualTo: conducteurEmail.toLowerCase());
      }

      if (dateDebut != null) {
        query = query.where('date_verification', isGreaterThanOrEqualTo: Timestamp.fromDate(dateDebut));
      }

      if (dateFin != null) {
        query = query.where('date_verification', isLessThanOrEqualTo: Timestamp.fromDate(dateFin));
      }

      final snapshot = await query.get();
      
      int totalVerifications = snapshot.docs.length;
      int verificationsReussies = 0;
      int verificationsEchouees = 0;
      int tempsTotal = 0;
      Map<String, int> erreursParType = {};
      Map<String, int> verificationsParCompagnie = {};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        if (data['success'] == true) {
          verificationsReussies++;
        } else {
          verificationsEchouees++;
          final errorType = data['error_type'] as String?;
          if (errorType != null) {
            erreursParType[errorType] = (erreursParType[errorType] ?? 0) + 1;
          }
        }

        tempsTotal += (data['temps_verification'] as int? ?? 0);

        final compagnie = data['compagnie_id'] as String?;
        if (compagnie != null) {
          verificationsParCompagnie[compagnie] = (verificationsParCompagnie[compagnie] ?? 0) + 1;
        }
      }

      double tempsVerificationMoyen = totalVerifications > 0 ? tempsTotal / totalVerifications : 0;

      return {
        'total_verifications': totalVerifications,
        'verifications_reussies': verificationsReussies,
        'verifications_echouees': verificationsEchouees,
        'taux_succes': totalVerifications > 0 ? (verificationsReussies / totalVerifications) * 100 : 0,
        'temps_verification_moyen': tempsVerificationMoyen,
        'erreurs_par_type': erreursParType,
        'verifications_par_compagnie': verificationsParCompagnie,
      };

    } catch (e) {
      debugPrint('❌ Erreur statistiques vérification: $e');
      return {};
    }
  }
}

/// 📊 Résultat de vérification de véhicule
class VehiculeVerificationResult {
  final bool success;
  final VehiculeCompletModel? vehicule;
  final String message;
  final VerificationErrorType? errorType;
  final List<String>? droitsConducteur;
  final int tempsVerification;

  const VehiculeVerificationResult({
    required this.success,
    this.vehicule,
    required this.message,
    this.errorType,
    this.droitsConducteur,
    required this.tempsVerification,
  });
}

/// 🚫 Types d'erreur de vérification
enum VerificationErrorType {
  vehiculeNonTrouve,
  contratInactif,
  conducteurNonAutorise,
  droitsInsuffisants,
  erreurTechnique,
}

/// 📋 Modèle d'historique de vérification
class VerificationHistoryModel {
  final String id;
  final String? vehiculeId;
  final String? numeroContrat;
  final String? compagnieId;
  final String conducteurEmail;
  final bool success;
  final String? errorType;
  final int tempsVerification;
  final DateTime dateVerification;

  const VerificationHistoryModel({
    required this.id,
    this.vehiculeId,
    this.numeroContrat,
    this.compagnieId,
    required this.conducteurEmail,
    required this.success,
    this.errorType,
    required this.tempsVerification,
    required this.dateVerification,
  });

  factory VerificationHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VerificationHistoryModel(
      id: doc.id,
      vehiculeId: data['vehicule_id'],
      numeroContrat: data['numero_contrat'],
      compagnieId: data['compagnie_id'],
      conducteurEmail: data['conducteur_email'] ?? '',
      success: data['success'] ?? false,
      errorType: data['error_type'],
      tempsVerification: data['temps_verification'] ?? 0,
      dateVerification: (data['date_verification'] as Timestamp).toDate(),
    );
  }
}
