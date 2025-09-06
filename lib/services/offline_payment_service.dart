import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../core/models/contract_models.dart';
import '../core/services/logging_service.dart';
import '../core/exceptions/app_exceptions.dart';
import '../services/hybrid_contract_service.dart';

/// 💳 Service de gestion des paiements hors application
/// Gère D17, virements, paiements en agence, etc.
class OfflinePaymentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔢 Générer une référence de paiement
  static Future<PaymentReference> generatePaymentReference({
    required String contractId,
    required PaymentMethod method,
    required double amount,
    String? agencyAddress,
  }) async {
    try {
      LoggingService.info('PAYMENT', 'Génération référence paiement: $contractId ($method)');

      // 1. Récupérer les infos du contrat
      final contractDoc = await _firestore.collection('contrats').doc(contractId).get();
      if (!contractDoc.exists) {
        throw BusinessException('Contrat non trouvé');
      }

      final contractData = contractDoc.data()!;

      // 2. Générer la référence unique
      final referenceNumber = _generateReferenceNumber(method);

      // 3. Générer le QR Code pour D17
      final qrCode = await _generateQRCode(contractId, referenceNumber, amount, method);

      // 4. Récupérer les détails bancaires
      final bankDetails = await _getBankDetails(contractData['agenceId']);

      // 5. Récupérer l'adresse de l'agence
      final finalAgencyAddress = agencyAddress ?? await _getAgencyAddress(contractData['agenceId']);

      // 6. Créer la référence de paiement
      final paymentReference = PaymentReference(
        contractId: contractId,
        referenceNumber: referenceNumber,
        amount: amount,
        method: method,
        qrCode: qrCode,
        bankDetails: bankDetails,
        agencyAddress: finalAgencyAddress,
        expiryDate: DateTime.now().add(const Duration(days: 30)), // Expire dans 30 jours
        additionalInfo: _getMethodSpecificInfo(method, contractData),
      );

      // 7. Sauvegarder la référence
      await _firestore.collection('payment_references').doc(referenceNumber).set(paymentReference.toMap());

      // 8. Mettre à jour le contrat
      await _firestore.collection('contrats').doc(contractId).update({
        'status': ContractStatus.awaitingPayment.value,
        'paymentReference': referenceNumber,
        'paymentMethod': method.value,
        'paymentAmount': amount,
        'paymentExpiryDate': Timestamp.fromDate(paymentReference.expiryDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      LoggingService.info('PAYMENT', 'Référence générée: $referenceNumber');
      return paymentReference;

    } catch (e, stackTrace) {
      LoggingService.error('PAYMENT', 'Erreur génération référence paiement', e, stackTrace);
      throw BusinessException(
        'Erreur lors de la génération de la référence de paiement',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// ✅ Valider un paiement par l'agent
  static Future<void> validatePayment({
    required String contractId,
    required PaymentProof paymentProof,
  }) async {
    try {
      LoggingService.info('PAYMENT', 'Validation paiement: $contractId');

      // 1. Vérifier que l'agent a les droits
      await _validateAgentPermissions(paymentProof.agentId);

      // 2. Vérifier que le contrat existe et est en attente de paiement
      final contractDoc = await _firestore.collection('contrats').doc(contractId).get();
      if (!contractDoc.exists) {
        throw BusinessException('Contrat non trouvé');
      }

      final contractData = contractDoc.data()!;
      final currentStatus = ContractStatus.fromString(contractData['status']);

      if (currentStatus != ContractStatus.awaitingPayment) {
        throw BusinessException('Ce contrat n\'est pas en attente de paiement');
      }

      // 3. Vérifier le montant
      final expectedAmount = contractData['paymentAmount'] as double;
      if ((paymentProof.amount - expectedAmount).abs() > 0.01) {
        throw ValidationException('Le montant payé ne correspond pas au montant attendu');
      }

      // 4. Sauvegarder la preuve de paiement
      await _firestore.collection('payment_proofs').add(paymentProof.toMap());

      // 5. Activer le contrat
      await HybridContractService.activateContract(
        contractId: contractId,
        agentId: paymentProof.agentId,
        paymentInfo: {
          'method': paymentProof.method.value,
          'amount': paymentProof.amount,
          'referenceNumber': paymentProof.referenceNumber,
          'validatedAt': FieldValue.serverTimestamp(),
          'validatedBy': paymentProof.agentId,
        },
      );

      // 6. Marquer la référence de paiement comme utilisée
      if (contractData['paymentReference'] != null) {
        await _firestore.collection('payment_references').doc(contractData['paymentReference']).update({
          'status': 'paid',
          'paidAt': FieldValue.serverTimestamp(),
          'validatedBy': paymentProof.agentId,
        });
      }

      LoggingService.info('PAYMENT', 'Paiement validé et contrat activé: $contractId');

    } catch (e, stackTrace) {
      LoggingService.error('PAYMENT', 'Erreur validation paiement', e, stackTrace);
      
      if (e is AppException) {
        rethrow;
      }
      
      throw BusinessException(
        'Erreur lors de la validation du paiement',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 📊 Obtenir les statistiques de paiement
  static Future<Map<String, dynamic>> getPaymentStats({String? agentId}) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      Query query = _firestore.collection('payment_proofs');
      
      if (agentId != null) {
        query = query.where('agentId', isEqualTo: agentId);
      }

      // Paiements ce mois
      final thisMonthQuery = await query
          .where('paymentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      // Calculer le total des montants
      double totalAmount = 0;
      final methodCounts = <String, int>{};

      for (final doc in thisMonthQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalAmount += (data['amount'] as num).toDouble();
        
        final method = data['method'] as String;
        methodCounts[method] = (methodCounts[method] ?? 0) + 1;
      }

      // Paiements en attente
      final pendingQuery = await _firestore
          .collection('contrats')
          .where('status', isEqualTo: ContractStatus.awaitingPayment.value)
          .get();

      return {
        'paymentsThisMonth': thisMonthQuery.docs.length,
        'totalAmountThisMonth': totalAmount,
        'pendingPayments': pendingQuery.docs.length,
        'methodBreakdown': methodCounts,
        'averageAmount': thisMonthQuery.docs.isNotEmpty ? totalAmount / thisMonthQuery.docs.length : 0,
      };

    } catch (e) {
      LoggingService.error('PAYMENT', 'Erreur récupération statistiques paiement', e);
      return {
        'paymentsThisMonth': 0,
        'totalAmountThisMonth': 0.0,
        'pendingPayments': 0,
        'methodBreakdown': <String, int>{},
        'averageAmount': 0.0,
      };
    }
  }

  /// 📱 Obtenir les instructions de paiement pour le conducteur
  static Future<Map<String, dynamic>> getPaymentInstructions({
    required String contractId,
    required PaymentMethod method,
  }) async {
    try {
      // Récupérer la référence de paiement
      final contractDoc = await _firestore.collection('contrats').doc(contractId).get();
      if (!contractDoc.exists) {
        throw BusinessException('Contrat non trouvé');
      }

      final contractData = contractDoc.data()!;
      final referenceNumber = contractData['paymentReference'];

      if (referenceNumber == null) {
        throw BusinessException('Référence de paiement non trouvée');
      }

      final referenceDoc = await _firestore.collection('payment_references').doc(referenceNumber).get();
      if (!referenceDoc.exists) {
        throw BusinessException('Référence de paiement invalide');
      }

      final paymentRef = PaymentReference.fromMap(referenceDoc.data()!);

      // Générer les instructions spécifiques selon la méthode
      return _generateInstructions(paymentRef, method);

    } catch (e, stackTrace) {
      LoggingService.error('PAYMENT', 'Erreur récupération instructions paiement', e, stackTrace);
      throw BusinessException(
        'Erreur lors de la récupération des instructions de paiement',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// ⏰ Vérifier les paiements expirés
  static Future<List<String>> checkExpiredPayments() async {
    try {
      final now = DateTime.now();
      
      final expiredQuery = await _firestore
          .collection('contrats')
          .where('status', isEqualTo: ContractStatus.awaitingPayment.value)
          .where('paymentExpiryDate', isLessThan: Timestamp.fromDate(now))
          .get();

      final expiredContractIds = <String>[];

      for (final doc in expiredQuery.docs) {
        final contractId = doc.id;
        
        // Marquer comme expiré
        await doc.reference.update({
          'status': ContractStatus.expired.value,
          'expiredAt': FieldValue.serverTimestamp(),
        });

        expiredContractIds.add(contractId);
      }

      LoggingService.info('PAYMENT', '${expiredContractIds.length} paiements expirés traités');
      return expiredContractIds;

    } catch (e) {
      LoggingService.error('PAYMENT', 'Erreur vérification paiements expirés', e);
      return [];
    }
  }

  // ========== MÉTHODES PRIVÉES ==========

  /// 🔢 Générer un numéro de référence unique
  static String _generateReferenceNumber(PaymentMethod method) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    
    switch (method) {
      case PaymentMethod.d17:
        return 'D17-$timestamp-$random';
      case PaymentMethod.bankTransfer:
        return 'VIR-$timestamp-$random';
      case PaymentMethod.cash:
        return 'ESP-$timestamp-$random';
      case PaymentMethod.check:
        return 'CHQ-$timestamp-$random';
      case PaymentMethod.postOffice:
        return 'PTT-$timestamp-$random';
    }
  }

  /// 📱 Générer le QR Code pour D17
  static Future<String> _generateQRCode(String contractId, String referenceNumber, double amount, PaymentMethod method) async {
    if (method == PaymentMethod.d17) {
      // Format QR Code D17 (simulé)
      return 'D17:$referenceNumber:$amount:TND:Assurance Auto';
    }
    
    // QR Code générique avec les infos de paiement
    return 'PAY:$referenceNumber:$amount:$contractId';
  }

  /// 🏦 Récupérer les détails bancaires de l'agence
  static Future<String> _getBankDetails(String agenceId) async {
    try {
      final agenceDoc = await _firestore.collection('agences').doc(agenceId).get();
      
      if (agenceDoc.exists) {
        final agenceData = agenceDoc.data()!;
        return '''
Bénéficiaire: ${agenceData['nom']}
Banque: ${agenceData['banque'] ?? 'Banque de Tunisie'}
RIB: ${agenceData['rib'] ?? 'TN59 0000 0000 0000 0000 00'}
Code Swift: ${agenceData['swift'] ?? 'BTUBTNTX'}
''';
      }
    } catch (e) {
      LoggingService.warning('PAYMENT', 'Erreur récupération détails bancaires', e);
    }

    // Détails par défaut
    return '''
Bénéficiaire: Agence d'Assurance
Banque: Banque de Tunisie
RIB: TN59 0000 0000 0000 0000 00
Code Swift: BTUBTNTX
''';
  }

  /// 📍 Récupérer l'adresse de l'agence
  static Future<String> _getAgencyAddress(String agenceId) async {
    try {
      final agenceDoc = await _firestore.collection('agences').doc(agenceId).get();
      
      if (agenceDoc.exists) {
        final agenceData = agenceDoc.data()!;
        return agenceData['adresse'] ?? 'Adresse de l\'agence non disponible';
      }
    } catch (e) {
      LoggingService.warning('PAYMENT', 'Erreur récupération adresse agence', e);
    }

    return 'Adresse de l\'agence non disponible';
  }

  /// ℹ️ Obtenir les informations spécifiques à la méthode
  static Map<String, dynamic> _getMethodSpecificInfo(PaymentMethod method, Map<String, dynamic> contractData) {
    switch (method) {
      case PaymentMethod.d17:
        return {
          'instructions': 'Scannez le QR Code avec votre application D17',
          'steps': [
            'Ouvrez votre application D17',
            'Sélectionnez "Scanner QR Code"',
            'Scannez le code affiché',
            'Confirmez le paiement',
          ],
        };
        
      case PaymentMethod.bankTransfer:
        return {
          'instructions': 'Effectuez un virement bancaire avec la référence',
          'steps': [
            'Connectez-vous à votre banque en ligne',
            'Sélectionnez "Virement"',
            'Saisissez les coordonnées bancaires',
            'Indiquez la référence dans le motif',
            'Confirmez le virement',
          ],
        };
        
      case PaymentMethod.cash:
        return {
          'instructions': 'Rendez-vous à l\'agence avec la référence',
          'steps': [
            'Présentez-vous à l\'agence',
            'Donnez la référence de paiement',
            'Effectuez le paiement en espèces',
            'Conservez le reçu',
          ],
        };
        
      case PaymentMethod.check:
        return {
          'instructions': 'Remettez un chèque à l\'ordre de l\'agence',
          'steps': [
            'Établissez le chèque à l\'ordre de l\'agence',
            'Indiquez la référence au dos',
            'Remettez le chèque à l\'agence',
            'Conservez le reçu de dépôt',
          ],
        };
        
      case PaymentMethod.postOffice:
        return {
          'instructions': 'Effectuez le paiement à la Poste Tunisienne',
          'steps': [
            'Rendez-vous au bureau de poste',
            'Demandez un mandat de paiement',
            'Indiquez la référence',
            'Effectuez le paiement',
            'Conservez le reçu',
          ],
        };
    }
  }

  /// 🛡️ Valider les permissions de l'agent
  static Future<void> _validateAgentPermissions(String agentId) async {
    final agentDoc = await _firestore.collection('users').doc(agentId).get();
    
    if (!agentDoc.exists) {
      throw AuthException('Agent non trouvé');
    }

    final agentData = agentDoc.data()!;
    if (agentData['role'] != 'agent' && agentData['role'] != 'admin_agence') {
      throw AuthException('Permissions insuffisantes pour valider les paiements');
    }
  }

  /// 📋 Générer les instructions détaillées
  static Map<String, dynamic> _generateInstructions(PaymentReference paymentRef, PaymentMethod method) {
    final baseInfo = {
      'contractId': paymentRef.contractId,
      'referenceNumber': paymentRef.referenceNumber,
      'amount': paymentRef.amount,
      'expiryDate': paymentRef.expiryDate,
      'method': method.displayName,
    };

    switch (method) {
      case PaymentMethod.d17:
        return {
          ...baseInfo,
          'qrCode': paymentRef.qrCode,
          'title': 'Paiement par D17',
          'description': 'Scannez le QR Code avec votre application D17 Mobile',
          'steps': paymentRef.additionalInfo['steps'] ?? [],
        };
        
      case PaymentMethod.bankTransfer:
        return {
          ...baseInfo,
          'bankDetails': paymentRef.bankDetails,
          'title': 'Paiement par virement bancaire',
          'description': 'Effectuez un virement avec les coordonnées ci-dessous',
          'steps': paymentRef.additionalInfo['steps'] ?? [],
        };
        
      case PaymentMethod.cash:
        return {
          ...baseInfo,
          'agencyAddress': paymentRef.agencyAddress,
          'title': 'Paiement en espèces',
          'description': 'Rendez-vous à l\'agence pour effectuer le paiement',
          'steps': paymentRef.additionalInfo['steps'] ?? [],
        };
        
      default:
        return {
          ...baseInfo,
          'title': method.displayName,
          'description': 'Suivez les instructions pour effectuer le paiement',
          'steps': paymentRef.additionalInfo['steps'] ?? [],
        };
    }
  }
}
