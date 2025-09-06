import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/models/contract_models.dart';
import '../core/services/logging_service.dart';
import '../core/exceptions/app_exceptions.dart';
import 'hybrid_contract_service.dart';
import 'offline_payment_service.dart';

/// 🔄 Service de workflow complet pour l'assurance auto tunisienne
/// Gère tout le processus : inscription → contrat → paiement → documents
class CompleteInsuranceWorkflowService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 📝 Étape 1: Conducteur soumet sa demande d'assurance
  static Future<Map<String, dynamic>> submitInsuranceRequest({
    required Map<String, dynamic> conducteurData,
    required Map<String, dynamic> vehicleData,
    required String compagnieId,
    required String agenceId,
  }) async {
    try {
      LoggingService.info('COMPLETE_WORKFLOW', '🚀 Début soumission demande assurance');

      final user = _auth.currentUser;
      if (user == null) throw const AuthException('Utilisateur non connecté');

      // Générer un ID unique pour la demande
      final requestId = _firestore.collection('insurance_requests').doc().id;

      // Créer la demande d'assurance
      final requestData = {
        'id': requestId,
        'conducteurId': user.uid,
        'conducteurData': conducteurData,
        'vehicleData': vehicleData,
        'compagnieId': compagnieId,
        'agenceId': agenceId,
        'status': 'pending_agent_review', // En attente de révision par l'agent
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'workflow': {
          'step': 1,
          'stepName': 'Demande soumise',
          'nextStep': 'Agent doit créer le contrat',
        },
      };

      await _firestore.collection('insurance_requests').doc(requestId).set(requestData);

      // Notifier l'agence
      await _notifyAgency(agenceId, requestId, conducteurData, vehicleData);

      LoggingService.info('COMPLETE_WORKFLOW', '✅ Demande soumise avec succès: $requestId');

      return {
        'success': true,
        'requestId': requestId,
        'message': 'Demande soumise avec succès! L\'agence va traiter votre dossier.',
        'nextStep': 'L\'agent va créer votre contrat et vous contacter.',
      };
    } catch (e) {
      LoggingService.error('COMPLETE_WORKFLOW', '❌ Erreur soumission demande', e);
      throw BusinessException('Erreur lors de la soumission: ${e.toString()}');
    }
  }

  /// 👨‍💼 Étape 2: Agent crée le contrat et génère le montant
  static Future<Map<String, dynamic>> createContractByAgent({
    required String requestId,
    required String agentId,
    required Map<String, dynamic> contractDetails,
    required double primeAmount,
    required String paymentFrequency, // 'mensuel', 'trimestriel', 'annuel'
  }) async {
    try {
      LoggingService.info('COMPLETE_WORKFLOW', '👨‍💼 Agent crée contrat pour demande: $requestId');

      // Récupérer la demande
      final requestDoc = await _firestore.collection('insurance_requests').doc(requestId).get();
      if (!requestDoc.exists) throw const BusinessException('Demande introuvable');

      final requestData = requestDoc.data()!;

      // Créer le contrat via HybridContractService
      final contractId = await HybridContractService.createDigitalContract(
        vehicleData: requestData['vehicleData'],
        conducteurData: requestData['conducteurData'],
        agentId: agentId,
        typeContrat: 'Assurance Auto',
        primeAnnuelle: primeAmount,
        dateDebut: DateTime.now(),
        dateFin: DateTime.now().add(const Duration(days: 365)),
      );

      // Générer la référence de paiement
      final paymentRef = await OfflinePaymentService.generatePaymentReference(
        contractId: contractId,
        amount: primeAmount,
        method: PaymentMethod.bankTransfer, // Méthode par défaut
      );

      // Mettre à jour la demande
      await _firestore.collection('insurance_requests').doc(requestId).update({
        'status': 'contract_created_pending_payment',
        'contractId': contractId,
        'paymentReference': paymentRef.toMap(),
        'agentId': agentId,
        'updatedAt': FieldValue.serverTimestamp(),
        'workflow': {
          'step': 2,
          'stepName': 'Contrat créé',
          'nextStep': 'Conducteur doit payer',
        },
      });

      // Notifier le conducteur
      await _notifyConducteurContractReady(
        requestData['conducteurId'],
        contractId,
        paymentRef,
      );

      LoggingService.info('COMPLETE_WORKFLOW', '✅ Contrat créé par agent: $contractId');

      return {
        'success': true,
        'contractId': contractId,
        'paymentReference': paymentRef.toMap(),
        'message': 'Contrat créé! Le conducteur peut maintenant payer.',
      };
    } catch (e) {
      LoggingService.error('COMPLETE_WORKFLOW', '❌ Erreur création contrat par agent', e);
      throw BusinessException('Erreur création contrat: ${e.toString()}');
    }
  }

  /// 💰 Étape 3: Conducteur effectue le paiement (hors app)
  static Future<Map<String, dynamic>> recordPaymentReceived({
    required String contractId,
    required String agentId,
    required PaymentMethod paymentMethod,
    required Map<String, dynamic> paymentProof,
  }) async {
    try {
      LoggingService.info('COMPLETE_WORKFLOW', '💰 Enregistrement paiement pour contrat: $contractId');

      // Enregistrer le paiement via OfflinePaymentService
      final paymentResult = await OfflinePaymentService.validatePayment(
        contractId: contractId,
        paymentProof: PaymentProof(
          contractId: contractId,
          method: paymentMethod,
          amount: paymentProof['amount'] ?? 0.0,
          referenceNumber: paymentProof['referenceNumber'] ?? '',
          receiptImageUrl: paymentProof['receiptImageUrl'],
          bankTransferReference: paymentProof['bankTransferReference'],
          d17TransactionId: paymentProof['d17TransactionId'],
          paymentDate: DateTime.now(),
          agentId: agentId,
          notes: paymentProof['notes'] ?? '',
        ),
      );

      // Mettre à jour le statut du contrat
      await _firestore.collection('contracts').doc(contractId).update({
        'status': ContractStatus.active,
        'paymentStatus': 'paid',
        'paymentValidatedAt': FieldValue.serverTimestamp(),
        'paymentValidatedBy': agentId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Générer les documents numériques
      final documentsResult = await _generateDigitalDocuments(contractId);

      // Mettre à jour la demande originale
      final requestQuery = await _firestore
          .collection('insurance_requests')
          .where('contractId', isEqualTo: contractId)
          .limit(1)
          .get();

      if (requestQuery.docs.isNotEmpty) {
        await requestQuery.docs.first.reference.update({
          'status': 'completed_insured',
          'documentsGenerated': true,
          'updatedAt': FieldValue.serverTimestamp(),
          'workflow': {
            'step': 4,
            'stepName': 'Assuré - Documents générés',
            'nextStep': 'Processus terminé',
          },
        });
      }

      // Notifier le conducteur
      await _notifyConducteurInsured(contractId, documentsResult);

      LoggingService.info('COMPLETE_WORKFLOW', '✅ Paiement validé et documents générés: $contractId');

      return {
        'success': true,
        'contractId': contractId,
        'documents': documentsResult,
        'message': 'Paiement validé! Véhicule maintenant assuré.',
      };
    } catch (e) {
      LoggingService.error('COMPLETE_WORKFLOW', '❌ Erreur validation paiement', e);
      throw BusinessException('Erreur validation paiement: ${e.toString()}');
    }
  }

  /// 📄 Générer tous les documents numériques
  static Future<Map<String, dynamic>> _generateDigitalDocuments(String contractId) async {
    try {
      // Récupérer les données du contrat
      final contractDoc = await _firestore.collection('contracts').doc(contractId).get();
      if (!contractDoc.exists) throw const BusinessException('Contrat introuvable');

      final contractData = contractDoc.data()!;

      // Générer les documents via HybridContractService
      final documents = await HybridContractService.generateDigitalDocuments(contractId);

      // Générer le QR Code pour la carte verte
      final qrCodeData = await _generateInsuranceQRCode(contractId, contractData);

      // Sauvegarder les URLs des documents
      await _firestore.collection('contracts').doc(contractId).update({
        'documents': documents,
        'qrCodeData': qrCodeData,
        'documentsGeneratedAt': FieldValue.serverTimestamp(),
      });

      return {
        'contractPdf': documents['contractPdf'],
        'quittancePdf': documents['quittance'],
        'carteVertePdf': documents['carteVerte'],
        'qrCode': qrCodeData,
      };
    } catch (e) {
      LoggingService.error('COMPLETE_WORKFLOW', '❌ Erreur génération documents', e);
      throw BusinessException('Erreur génération documents: ${e.toString()}');
    }
  }

  /// 📱 Générer QR Code pour vérification police
  static Future<Map<String, dynamic>> _generateInsuranceQRCode(
    String contractId,
    Map<String, dynamic> contractData,
  ) async {
    final qrData = {
      'contractId': contractId,
      'vehicleId': contractData['vehicleId'],
      'immatriculation': contractData['vehicleData']['immatriculation'],
      'conducteurId': contractData['conducteurId'],
      'compagnie': contractData['compagnieId'],
      'validUntil': contractData['endDate'],
      'verificationUrl': 'https://constat-tunisie.tn/verify/$contractId',
      'generatedAt': DateTime.now().toIso8601String(),
    };

    return qrData;
  }

  /// 🔔 Notifier l'agence d'une nouvelle demande
  static Future<void> _notifyAgency(
    String agenceId,
    String requestId,
    Map<String, dynamic> conducteurData,
    Map<String, dynamic> vehicleData,
  ) async {
    await _firestore.collection('notifications').add({
      'type': 'new_insurance_request',
      'agenceId': agenceId,
      'requestId': requestId,
      'title': 'Nouvelle demande d\'assurance',
      'message': 'Nouveau conducteur: ${conducteurData['prenom']} ${conducteurData['nom']} - Véhicule: ${vehicleData['marque']} ${vehicleData['modele']}',
      'data': {
        'requestId': requestId,
        'conducteurName': '${conducteurData['prenom']} ${conducteurData['nom']}',
        'vehicleInfo': '${vehicleData['marque']} ${vehicleData['modele']}',
        'immatriculation': vehicleData['immatriculation'],
      },
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  /// 🔔 Notifier le conducteur que son contrat est prêt
  static Future<void> _notifyConducteurContractReady(
    String conducteurId,
    String contractId,
    PaymentReference paymentRef,
  ) async {
    await _firestore.collection('notifications').add({
      'type': 'contract_ready_for_payment',
      'userId': conducteurId,
      'contractId': contractId,
      'title': 'Contrat prêt - Paiement requis',
      'message': 'Votre contrat est prêt! Montant: ${paymentRef.amount} DT. Référence: ${paymentRef.referenceNumber}',
      'data': {
        'contractId': contractId,
        'amount': paymentRef.amount,
        'reference': paymentRef.referenceNumber,
        'paymentMethods': ['agence', 'virement', 'd17'],
      },
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  /// 🔔 Notifier le conducteur qu'il est maintenant assuré
  static Future<void> _notifyConducteurInsured(
    String contractId,
    Map<String, dynamic> documents,
  ) async {
    // Récupérer le conducteur ID depuis le contrat
    final contractDoc = await _firestore.collection('contracts').doc(contractId).get();
    final conducteurId = contractDoc.data()?['conducteurId'];

    if (conducteurId != null) {
      await _firestore.collection('notifications').add({
        'type': 'vehicle_insured_documents_ready',
        'userId': conducteurId,
        'contractId': contractId,
        'title': '🎉 Véhicule assuré!',
        'message': 'Félicitations! Votre véhicule est maintenant assuré. Documents disponibles dans l\'app.',
        'data': {
          'contractId': contractId,
          'documents': documents,
          'hasQrCode': true,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    }
  }

  /// 📊 Obtenir le statut complet d'une demande
  static Future<Map<String, dynamic>> getRequestStatus(String requestId) async {
    try {
      final requestDoc = await _firestore.collection('insurance_requests').doc(requestId).get();
      if (!requestDoc.exists) throw const BusinessException('Demande introuvable');

      final data = requestDoc.data()!;
      
      return {
        'requestId': requestId,
        'status': data['status'],
        'workflow': data['workflow'],
        'contractId': data['contractId'],
        'paymentReference': data['paymentReference'],
        'createdAt': data['createdAt'],
        'updatedAt': data['updatedAt'],
      };
    } catch (e) {
      LoggingService.error('COMPLETE_WORKFLOW', '❌ Erreur récupération statut', e);
      throw BusinessException('Erreur récupération statut: ${e.toString()}');
    }
  }

  /// 📋 Obtenir toutes les demandes pour une agence
  static Future<List<Map<String, dynamic>>> getAgencyRequests(String agenceId) async {
    try {
      final snapshot = await _firestore
          .collection('insurance_requests')
          .where('agenceId', isEqualTo: agenceId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      LoggingService.error('COMPLETE_WORKFLOW', '❌ Erreur récupération demandes agence', e);
      throw BusinessException('Erreur récupération demandes: ${e.toString()}');
    }
  }

  /// 📋 Obtenir les demandes d'un conducteur
  static Future<List<Map<String, dynamic>>> getConducteurRequests(String conducteurId) async {
    try {
      final snapshot = await _firestore
          .collection('insurance_requests')
          .where('conducteurId', isEqualTo: conducteurId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      LoggingService.error('COMPLETE_WORKFLOW', '❌ Erreur récupération demandes conducteur', e);
      throw BusinessException('Erreur récupération demandes: ${e.toString()}');
    }
  }
}
