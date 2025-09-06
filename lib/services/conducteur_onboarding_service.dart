import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../core/models/contract_models.dart';
import '../core/services/logging_service.dart';
import '../core/exceptions/app_exceptions.dart';

/// 🚀 Service de gestion des parcours d'inscription conducteur
/// Gère les nouveaux conducteurs ET la migration des anciens
class ConducteurOnboardingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🆕 Créer un nouveau conducteur (parcours 100% digital)
  static Future<Map<String, dynamic>> createNewConducteur({
    required Map<String, dynamic> conducteurData,
    required Map<String, dynamic> vehicleData,
    required String selectedOfferId,
  }) async {
    try {
      LoggingService.info('ONBOARDING', 'Création nouveau conducteur: ${conducteurData['email']}');

      // 1. Créer le compte utilisateur Firebase
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: conducteurData['email'],
        password: conducteurData['password'],
      );

      final userId = userCredential.user!.uid;

      // 2. Créer le profil conducteur dans Firestore
      final conducteurProfile = {
        ...conducteurData,
        'uid': userId,
        'type': ConducteurType.newConducteur.value,
        'status': 'active',
        'registrationMethod': 'mobile_app',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(userId).set(conducteurProfile);
      LoggingService.info('ONBOARDING', 'Profil conducteur créé: $userId');

      // 3. Ajouter le véhicule
      final vehicleId = await _addVehicleForNewConducteur(userId, vehicleData);
      LoggingService.info('ONBOARDING', 'Véhicule ajouté: $vehicleId');

      // 4. Créer la demande de contrat
      final contractId = await _createContractRequest(userId, vehicleId, selectedOfferId);
      LoggingService.info('ONBOARDING', 'Demande de contrat créée: $contractId');

      // 5. Notifier les agents
      await _notifyAgentsNewRequest(contractId, userId);

      return {
        'success': true,
        'userId': userId,
        'vehicleId': vehicleId,
        'contractId': contractId,
        'message': 'Inscription réussie ! Votre demande est en cours de traitement.',
      };

    } catch (e, stackTrace) {
      LoggingService.error('ONBOARDING', 'Erreur création nouveau conducteur', e, stackTrace);
      
      if (e is FirebaseAuthException) {
        throw AuthException(
          'Erreur lors de la création du compte',
          code: e.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      }
      
      throw BusinessException(
        'Erreur lors de l\'inscription',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 👴 Migrer un conducteur existant (papier → digital)
  static Future<Map<String, dynamic>> migratePaperConducteur({
    required String agentId,
    required PaperContract paperContract,
    required String conducteurPhone,
    required String conducteurEmail,
  }) async {
    try {
      LoggingService.info('MIGRATION', 'Migration conducteur: ${paperContract.conducteurCin}');

      // 1. Vérifier que l'agent a les droits
      await _validateAgentPermissions(agentId);

      // 2. Créer le profil conducteur (sans compte Firebase pour l'instant)
      final conducteurId = _generateConducteurId();
      final conducteurProfile = {
        'conducteurId': conducteurId,
        'cin': paperContract.conducteurCin,
        'nom': _extractLastName(paperContract.conducteurName),
        'prenom': _extractFirstName(paperContract.conducteurName),
        'telephone': conducteurPhone,
        'email': conducteurEmail,
        'type': ConducteurType.existingConducteur.value,
        'status': 'migration_pending',
        'registrationMethod': 'agent_migration',
        'migratedBy': agentId,
        'migratedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('conducteurs_migration').doc(conducteurId).set(conducteurProfile);

      // 3. Migrer le véhicule
      final vehicleId = await _migrateVehicleFromPaper(conducteurId, paperContract);

      // 4. Migrer le contrat
      final contractId = await _migrateContractFromPaper(conducteurId, vehicleId, paperContract);

      // 5. Générer le code d'activation
      final activationCode = await _generateActivationCode(conducteurId, contractId, agentId);

      // 6. Envoyer l'invitation
      await _sendActivationInvitation(conducteurPhone, conducteurEmail, activationCode);

      LoggingService.info('MIGRATION', 'Migration terminée - Code: ${activationCode.code}');

      return {
        'success': true,
        'conducteurId': conducteurId,
        'vehicleId': vehicleId,
        'contractId': contractId,
        'activationCode': activationCode.code,
        'message': 'Migration réussie ! Le conducteur va recevoir son code d\'activation.',
      };

    } catch (e, stackTrace) {
      LoggingService.error('MIGRATION', 'Erreur migration conducteur', e, stackTrace);
      throw BusinessException(
        'Erreur lors de la migration',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 🔑 Activer le compte d'un conducteur migré
  static Future<Map<String, dynamic>> activateAccount({
    required String activationCode,
    required String password,
  }) async {
    try {
      LoggingService.info('ACTIVATION', 'Activation compte avec code: $activationCode');

      // 1. Vérifier le code d'activation
      final codeDoc = await _firestore
          .collection('activation_codes')
          .where('code', isEqualTo: activationCode)
          .where('isUsed', isEqualTo: false)
          .limit(1)
          .get();

      if (codeDoc.docs.isEmpty) {
        throw ValidationException('Code d\'activation invalide ou expiré');
      }

      final codeData = ActivationCode.fromMap(codeDoc.docs.first.data());

      // 2. Vérifier l'expiration
      if (codeData.expiryDate.isBefore(DateTime.now())) {
        throw ValidationException('Code d\'activation expiré');
      }

      // 3. Récupérer les données du conducteur
      final conducteurDoc = await _firestore
          .collection('conducteurs_migration')
          .doc(codeData.conducteurCin)
          .get();

      if (!conducteurDoc.exists) {
        throw BusinessException('Données de conducteur non trouvées');
      }

      final conducteurData = conducteurDoc.data()!;

      // 4. Créer le compte Firebase
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: conducteurData['email'],
        password: password,
      );

      final userId = userCredential.user!.uid;

      // 5. Migrer les données vers le profil principal
      await _completeMigration(userId, conducteurData, codeData.contractId);

      // 6. Marquer le code comme utilisé
      await codeDoc.docs.first.reference.update({
        'isUsed': true,
        'usedAt': FieldValue.serverTimestamp(),
        'activatedUserId': userId,
      });

      LoggingService.info('ACTIVATION', 'Compte activé avec succès: $userId');

      return {
        'success': true,
        'userId': userId,
        'message': 'Compte activé avec succès ! Bienvenue dans l\'application.',
      };

    } catch (e, stackTrace) {
      LoggingService.error('ACTIVATION', 'Erreur activation compte', e, stackTrace);
      
      if (e is AppException) {
        rethrow;
      }
      
      throw BusinessException(
        'Erreur lors de l\'activation du compte',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 📊 Obtenir les statistiques d'onboarding
  static Future<Map<String, dynamic>> getOnboardingStats(String agentId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Nouveaux conducteurs ce mois
      final newConducteursQuery = await _firestore
          .collection('users')
          .where('type', isEqualTo: ConducteurType.newConducteur.value)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      // Migrations ce mois
      final migrationsQuery = await _firestore
          .collection('conducteurs_migration')
          .where('migratedBy', isEqualTo: agentId)
          .where('migratedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      // Activations en attente
      final pendingActivationsQuery = await _firestore
          .collection('activation_codes')
          .where('agentId', isEqualTo: agentId)
          .where('isUsed', isEqualTo: false)
          .get();

      return {
        'newConducteursThisMonth': newConducteursQuery.docs.length,
        'migrationsThisMonth': migrationsQuery.docs.length,
        'pendingActivations': pendingActivationsQuery.docs.length,
        'totalProcessed': newConducteursQuery.docs.length + migrationsQuery.docs.length,
      };

    } catch (e) {
      LoggingService.error('ONBOARDING', 'Erreur récupération statistiques', e);
      return {
        'newConducteursThisMonth': 0,
        'migrationsThisMonth': 0,
        'pendingActivations': 0,
        'totalProcessed': 0,
      };
    }
  }

  // ========== MÉTHODES PRIVÉES ==========

  /// 🚗 Ajouter un véhicule pour un nouveau conducteur
  static Future<String> _addVehicleForNewConducteur(String userId, Map<String, dynamic> vehicleData) async {
    final vehicleId = _firestore.collection('vehicules').doc().id;
    
    final vehicleDoc = {
      ...vehicleData,
      'id': vehicleId,
      'conducteurId': userId,
      'etatCompte': 'En attente',
      'registrationMethod': 'mobile_app',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('vehicules').doc(vehicleId).set(vehicleDoc);
    return vehicleId;
  }

  /// 📋 Créer une demande de contrat
  static Future<String> _createContractRequest(String userId, String vehicleId, String offerId) async {
    final contractId = _firestore.collection('contract_requests').doc().id;
    
    final contractRequest = {
      'id': contractId,
      'conducteurId': userId,
      'vehicleId': vehicleId,
      'offerId': offerId,
      'status': ContractStatus.pendingValidation.value,
      'requestMethod': 'mobile_app',
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('contract_requests').doc(contractId).set(contractRequest);
    return contractId;
  }

  /// 🔔 Notifier les agents d'une nouvelle demande
  static Future<void> _notifyAgentsNewRequest(String contractId, String userId) async {
    // TODO: Implémenter le système de notifications push
    LoggingService.info('NOTIFICATION', 'Nouvelle demande de contrat: $contractId pour $userId');
  }

  /// 🛡️ Valider les permissions de l'agent
  static Future<void> _validateAgentPermissions(String agentId) async {
    final agentDoc = await _firestore.collection('users').doc(agentId).get();
    
    if (!agentDoc.exists) {
      throw AuthException('Agent non trouvé');
    }

    final agentData = agentDoc.data()!;
    if (agentData['role'] != 'agent' && agentData['role'] != 'admin_agence') {
      throw AuthException('Permissions insuffisantes pour la migration');
    }
  }

  /// 🚗 Migrer un véhicule depuis un contrat papier
  static Future<String> _migrateVehicleFromPaper(String conducteurId, PaperContract paperContract) async {
    final vehicleId = _firestore.collection('vehicules').doc().id;
    
    final vehicleDoc = {
      'id': vehicleId,
      'conducteurId': conducteurId,
      'numeroImmatriculation': paperContract.vehiclePlate,
      'marque': paperContract.vehicleBrand,
      'modele': paperContract.vehicleModel,
      'annee': paperContract.vehicleYear,
      'etatCompte': 'Migré depuis papier',
      'registrationMethod': 'paper_migration',
      'migratedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('vehicules').doc(vehicleId).set(vehicleDoc);
    return vehicleId;
  }

  /// 📄 Migrer un contrat depuis papier
  static Future<String> _migrateContractFromPaper(String conducteurId, String vehicleId, PaperContract paperContract) async {
    final contractId = _firestore.collection('contrats').doc().id;
    
    final contractDoc = {
      'id': contractId,
      'numeroContrat': paperContract.contractNumber,
      'conducteurId': conducteurId,
      'vehicleId': vehicleId,
      'primeAnnuelle': paperContract.annualPremium,
      'dateDebut': Timestamp.fromDate(paperContract.startDate),
      'dateFin': Timestamp.fromDate(paperContract.endDate),
      'compagnieNom': paperContract.companyName,
      'agenceNom': paperContract.agencyName,
      'agentId': paperContract.agentId,
      'status': ContractStatus.paperMigration.value,
      'registrationMethod': 'paper_migration',
      'scannedDocuments': paperContract.scannedDocuments,
      'migratedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('contrats').doc(contractId).set(contractDoc);
    return contractId;
  }

  /// 🔑 Générer un code d'activation
  static Future<ActivationCode> _generateActivationCode(String conducteurId, String contractId, String agentId) async {
    final code = _generateRandomCode();
    final expiryDate = DateTime.now().add(const Duration(days: 7)); // Expire dans 7 jours

    final activationCode = ActivationCode(
      code: code,
      conducteurCin: conducteurId,
      contractId: contractId,
      agentId: agentId,
      expiryDate: expiryDate,
    );

    await _firestore.collection('activation_codes').doc(code).set(activationCode.toMap());
    return activationCode;
  }

  /// 📱 Envoyer l'invitation d'activation
  static Future<void> _sendActivationInvitation(String phone, String email, ActivationCode activationCode) async {
    // TODO: Intégrer avec un service SMS/Email
    LoggingService.info('INVITATION', 'Code d\'activation envoyé: ${activationCode.code} à $phone / $email');
  }

  /// ✅ Compléter la migration après activation
  static Future<void> _completeMigration(String userId, Map<String, dynamic> conducteurData, String contractId) async {
    // 1. Créer le profil principal
    final mainProfile = {
      ...conducteurData,
      'uid': userId,
      'status': 'active',
      'activatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(userId).set(mainProfile);

    // 2. Mettre à jour le contrat
    await _firestore.collection('contrats').doc(contractId).update({
      'conducteurId': userId,
      'status': ContractStatus.synchronized.value,
      'synchronizedAt': FieldValue.serverTimestamp(),
    });

    // 3. Mettre à jour le véhicule
    final vehicleQuery = await _firestore
        .collection('vehicules')
        .where('conducteurId', isEqualTo: conducteurData['conducteurId'])
        .get();

    for (final doc in vehicleQuery.docs) {
      await doc.reference.update({
        'conducteurId': userId,
        'etatCompte': 'Assuré',
        'synchronizedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ========== UTILITAIRES ==========

  static String _generateConducteurId() {
    return 'COND_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _generateRandomCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString(); // Code à 6 chiffres
  }

  static String _extractFirstName(String fullName) {
    final parts = fullName.trim().split(' ');
    return parts.first;
  }

  static String _extractLastName(String fullName) {
    final parts = fullName.trim().split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }
}
