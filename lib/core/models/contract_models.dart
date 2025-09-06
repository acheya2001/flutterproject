import 'package:cloud_firestore/cloud_firestore.dart';

/// 📋 États possibles d'un contrat
enum ContractStatus {
  // Nouveau conducteur
  pendingValidation('En attente de validation', 'pending_validation'),
  contractProposed('Contrat proposé', 'contract_proposed'),
  awaitingPayment('En attente de paiement', 'awaiting_payment'),
  active('Assuré actif', 'active'),
  
  // Migration papier
  paperMigration('Migration en cours', 'paper_migration'),
  activationPending('Activation en attente', 'activation_pending'),
  synchronized('Synchronisé', 'synchronized'),
  
  // États communs
  expired('Expiré', 'expired'),
  cancelled('Annulé', 'cancelled'),
  suspended('Suspendu', 'suspended');

  const ContractStatus(this.displayName, this.value);
  final String displayName;
  final String value;

  static ContractStatus fromString(String value) {
    return ContractStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ContractStatus.pendingValidation,
    );
  }
}

/// 💳 Types de paiement hors application
enum PaymentMethod {
  cash('Espèces à l\'agence', 'cash'),
  bankTransfer('Virement bancaire', 'bank_transfer'),
  d17('D17 Mobile', 'd17'),
  check('Chèque', 'check'),
  postOffice('Poste Tunisienne', 'post_office');

  const PaymentMethod(this.displayName, this.value);
  final String displayName;
  final String value;

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => PaymentMethod.cash,
    );
  }
}

/// 🆔 Types de conducteur
enum ConducteurType {
  newConducteur('Nouveau conducteur', 'new'),
  existingConducteur('Conducteur existant', 'existing');

  const ConducteurType(this.displayName, this.value);
  final String displayName;
  final String value;

  static ConducteurType fromString(String value) {
    return ConducteurType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ConducteurType.newConducteur,
    );
  }
}

/// 📄 Modèle de référence de paiement
class PaymentReference {
  final String contractId;
  final String referenceNumber;
  final double amount;
  final PaymentMethod method;
  final String qrCode;
  final String bankDetails;
  final String agencyAddress;
  final DateTime expiryDate;
  final Map<String, dynamic> additionalInfo;

  PaymentReference({
    required this.contractId,
    required this.referenceNumber,
    required this.amount,
    required this.method,
    required this.qrCode,
    required this.bankDetails,
    required this.agencyAddress,
    required this.expiryDate,
    this.additionalInfo = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'contractId': contractId,
      'referenceNumber': referenceNumber,
      'amount': amount,
      'method': method.value,
      'qrCode': qrCode,
      'bankDetails': bankDetails,
      'agencyAddress': agencyAddress,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'additionalInfo': additionalInfo,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory PaymentReference.fromMap(Map<String, dynamic> map) {
    return PaymentReference(
      contractId: map['contractId'] ?? '',
      referenceNumber: map['referenceNumber'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      method: PaymentMethod.fromString(map['method'] ?? 'cash'),
      qrCode: map['qrCode'] ?? '',
      bankDetails: map['bankDetails'] ?? '',
      agencyAddress: map['agencyAddress'] ?? '',
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      additionalInfo: Map<String, dynamic>.from(map['additionalInfo'] ?? {}),
    );
  }
}

/// 📋 Modèle de preuve de paiement
class PaymentProof {
  final String contractId;
  final PaymentMethod method;
  final double amount;
  final String referenceNumber;
  final String? receiptImageUrl;
  final String? bankTransferReference;
  final String? d17TransactionId;
  final DateTime paymentDate;
  final String agentId;
  final String notes;

  PaymentProof({
    required this.contractId,
    required this.method,
    required this.amount,
    required this.referenceNumber,
    this.receiptImageUrl,
    this.bankTransferReference,
    this.d17TransactionId,
    required this.paymentDate,
    required this.agentId,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'contractId': contractId,
      'method': method.value,
      'amount': amount,
      'referenceNumber': referenceNumber,
      'receiptImageUrl': receiptImageUrl,
      'bankTransferReference': bankTransferReference,
      'd17TransactionId': d17TransactionId,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'agentId': agentId,
      'notes': notes,
      'validatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory PaymentProof.fromMap(Map<String, dynamic> map) {
    return PaymentProof(
      contractId: map['contractId'] ?? '',
      method: PaymentMethod.fromString(map['method'] ?? 'cash'),
      amount: (map['amount'] ?? 0).toDouble(),
      referenceNumber: map['referenceNumber'] ?? '',
      receiptImageUrl: map['receiptImageUrl'],
      bankTransferReference: map['bankTransferReference'],
      d17TransactionId: map['d17TransactionId'],
      paymentDate: (map['paymentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      agentId: map['agentId'] ?? '',
      notes: map['notes'] ?? '',
    );
  }
}

/// 📄 Modèle de contrat papier (pour migration)
class PaperContract {
  final String contractNumber;
  final String conducteurCin;
  final String conducteurName;
  final String vehiclePlate;
  final String vehicleBrand;
  final String vehicleModel;
  final int vehicleYear;
  final double annualPremium;
  final DateTime startDate;
  final DateTime endDate;
  final String companyName;
  final String agencyName;
  final String agentId;
  final List<String> scannedDocuments;
  final Map<String, dynamic> additionalData;

  PaperContract({
    required this.contractNumber,
    required this.conducteurCin,
    required this.conducteurName,
    required this.vehiclePlate,
    required this.vehicleBrand,
    required this.vehicleModel,
    required this.vehicleYear,
    required this.annualPremium,
    required this.startDate,
    required this.endDate,
    required this.companyName,
    required this.agencyName,
    required this.agentId,
    this.scannedDocuments = const [],
    this.additionalData = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'contractNumber': contractNumber,
      'conducteurCin': conducteurCin,
      'conducteurName': conducteurName,
      'vehiclePlate': vehiclePlate,
      'vehicleBrand': vehicleBrand,
      'vehicleModel': vehicleModel,
      'vehicleYear': vehicleYear,
      'annualPremium': annualPremium,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'companyName': companyName,
      'agencyName': agencyName,
      'agentId': agentId,
      'scannedDocuments': scannedDocuments,
      'additionalData': additionalData,
      'migratedAt': FieldValue.serverTimestamp(),
      'status': ContractStatus.paperMigration.value,
    };
  }

  factory PaperContract.fromMap(Map<String, dynamic> map) {
    return PaperContract(
      contractNumber: map['contractNumber'] ?? '',
      conducteurCin: map['conducteurCin'] ?? '',
      conducteurName: map['conducteurName'] ?? '',
      vehiclePlate: map['vehiclePlate'] ?? '',
      vehicleBrand: map['vehicleBrand'] ?? '',
      vehicleModel: map['vehicleModel'] ?? '',
      vehicleYear: map['vehicleYear'] ?? DateTime.now().year,
      annualPremium: (map['annualPremium'] ?? 0).toDouble(),
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      companyName: map['companyName'] ?? '',
      agencyName: map['agencyName'] ?? '',
      agentId: map['agentId'] ?? '',
      scannedDocuments: List<String>.from(map['scannedDocuments'] ?? []),
      additionalData: Map<String, dynamic>.from(map['additionalData'] ?? {}),
    );
  }
}

/// 🔑 Modèle de code d'activation
class ActivationCode {
  final String code;
  final String conducteurCin;
  final String contractId;
  final String agentId;
  final DateTime expiryDate;
  final bool isUsed;
  final DateTime? usedAt;

  ActivationCode({
    required this.code,
    required this.conducteurCin,
    required this.contractId,
    required this.agentId,
    required this.expiryDate,
    this.isUsed = false,
    this.usedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'conducteurCin': conducteurCin,
      'contractId': contractId,
      'agentId': agentId,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'isUsed': isUsed,
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory ActivationCode.fromMap(Map<String, dynamic> map) {
    return ActivationCode(
      code: map['code'] ?? '',
      conducteurCin: map['conducteurCin'] ?? '',
      contractId: map['contractId'] ?? '',
      agentId: map['agentId'] ?? '',
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isUsed: map['isUsed'] ?? false,
      usedAt: (map['usedAt'] as Timestamp?)?.toDate(),
    );
  }
}
