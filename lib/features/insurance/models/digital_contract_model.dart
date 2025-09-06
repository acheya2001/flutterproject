import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// 📄 Modèle complet pour les contrats numériques
class DigitalContract {
  final String id;
  final String numeroContrat;
  
  // Références
  final String vehiculeId;
  final String conducteurId;
  final String agentId;
  final String agenceId;
  final String compagnieId;
  
  // Informations contrat
  final ContractType typeContrat;
  final ContractStatus statut;
  final DateTime dateDebut;
  final DateTime dateFin;
  final double primeAnnuelle;
  final double franchise;
  
  // Garanties
  final List<Garantie> garanties;
  
  // Paiement
  final PaymentInfo paiement;
  
  // Documents
  final List<ContractDocument> documents;
  
  // Signature numérique
  final DigitalSignature? signature;
  
  // Métadonnées
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final bool isActive;

  const DigitalContract({
    required this.id,
    required this.numeroContrat,
    required this.vehiculeId,
    required this.conducteurId,
    required this.agentId,
    required this.agenceId,
    required this.compagnieId,
    required this.typeContrat,
    required this.statut,
    required this.dateDebut,
    required this.dateFin,
    required this.primeAnnuelle,
    required this.franchise,
    required this.garanties,
    required this.paiement,
    required this.documents,
    this.signature,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.isActive = true,
  });

  factory DigitalContract.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return DigitalContract(
      id: doc.id,
      numeroContrat: data['numeroContrat'] ?? '',
      vehiculeId: data['vehiculeId'] ?? '',
      conducteurId: data['conducteurId'] ?? '',
      agentId: data['agentId'] ?? '',
      agenceId: data['agenceId'] ?? '',
      compagnieId: data['compagnieId'] ?? '',
      typeContrat: parseContractType(data['typeContrat'] ?? 'responsabilite_civile'),
      statut: parseContractStatus(data['statut'] ?? 'brouillon'),
      dateDebut: (data['dateDebut'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateFin: (data['dateFin'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 365)),
      primeAnnuelle: (data['primeAnnuelle'] ?? 0).toDouble(),
      franchise: (data['franchise'] ?? 0).toDouble(),
      garanties: (data['garanties'] as List?)
          ?.map((g) => Garantie.fromMap(g))
          .toList() ?? [],
      paiement: PaymentInfo.fromMap(data['paiement'] ?? {}),
      documents: (data['documents'] as List?)
          ?.map((d) => ContractDocument.fromMap(d))
          .toList() ?? [],
      signature: data['signature'] != null 
          ? DigitalSignature.fromMap(data['signature']) 
          : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'numeroContrat': numeroContrat,
      'vehiculeId': vehiculeId,
      'conducteurId': conducteurId,
      'agentId': agentId,
      'agenceId': agenceId,
      'compagnieId': compagnieId,
      'typeContrat': typeContrat.value,
      'statut': statut.value,
      'dateDebut': Timestamp.fromDate(dateDebut),
      'dateFin': Timestamp.fromDate(dateFin),
      'primeAnnuelle': primeAnnuelle,
      'franchise': franchise,
      'garanties': garanties.map((g) => g.toMap()).toList(),
      'paiement': paiement.toMap(),
      'documents': documents.map((d) => d.toMap()).toList(),
      'signature': signature?.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'isActive': isActive,
    };
  }

  // Getters utiles
  bool get isExpired => DateTime.now().isAfter(dateFin);
  bool get isNearExpiry => DateTime.now().isAfter(dateFin.subtract(const Duration(days: 30)));
  bool get isSigned => signature != null;
  bool get isPaid => paiement.isPaid;
  bool get isValid => isActive && !isExpired && isSigned && isPaid;
  
  Duration get remainingDays => dateFin.difference(DateTime.now());
  double get totalPaid => paiement.totalPaid;
  double get remainingAmount => primeAnnuelle - totalPaid;
}

/// 📋 Types de contrats disponibles
enum ContractType {
  responsabiliteCivile,
  tiersPlusVol,
  tousRisques,
  temporaire,
}

extension ContractTypeExtension on ContractType {
  String get value {
    switch (this) {
      case ContractType.responsabiliteCivile:
        return 'responsabilite_civile';
      case ContractType.tiersPlusVol:
        return 'tiers_plus_vol';
      case ContractType.tousRisques:
        return 'tous_risques';
      case ContractType.temporaire:
        return 'temporaire';
    }
  }

  String get displayName {
    switch (this) {
      case ContractType.responsabiliteCivile:
        return 'Responsabilité Civile';
      case ContractType.tiersPlusVol:
        return 'Tiers + Vol/Incendie';
      case ContractType.tousRisques:
        return 'Tous Risques';
      case ContractType.temporaire:
        return 'Temporaire';
    }
  }

  double get basePrime {
    switch (this) {
      case ContractType.responsabiliteCivile:
        return 300.0;
      case ContractType.tiersPlusVol:
        return 600.0;
      case ContractType.tousRisques:
        return 1200.0;
      case ContractType.temporaire:
        return 150.0;
    }
  }


}

/// 📊 Statuts de contrat
enum ContractStatus {
  brouillon,        // En cours de création par l'agent
  propose,          // Proposé au conducteur
  enAttenteSignature, // En attente signature conducteur
  enAttentePaiement,  // Signé, en attente paiement
  actif,            // Actif et payé
  aRenouveler,      // Proche expiration
  expire,           // Expiré
  suspendu,         // Suspendu (impayé)
  annule,           // Annulé
}

extension ContractStatusExtension on ContractStatus {
  String get value {
    switch (this) {
      case ContractStatus.brouillon:
        return 'brouillon';
      case ContractStatus.propose:
        return 'propose';
      case ContractStatus.enAttenteSignature:
        return 'en_attente_signature';
      case ContractStatus.enAttentePaiement:
        return 'en_attente_paiement';
      case ContractStatus.actif:
        return 'actif';
      case ContractStatus.aRenouveler:
        return 'a_renouveler';
      case ContractStatus.expire:
        return 'expire';
      case ContractStatus.suspendu:
        return 'suspendu';
      case ContractStatus.annule:
        return 'annule';
    }
  }

  String get displayName {
    switch (this) {
      case ContractStatus.brouillon:
        return 'Brouillon';
      case ContractStatus.propose:
        return 'Proposé';
      case ContractStatus.enAttenteSignature:
        return 'En attente signature';
      case ContractStatus.enAttentePaiement:
        return 'En attente paiement';
      case ContractStatus.actif:
        return 'Actif';
      case ContractStatus.aRenouveler:
        return 'À renouveler';
      case ContractStatus.expire:
        return 'Expiré';
      case ContractStatus.suspendu:
        return 'Suspendu';
      case ContractStatus.annule:
        return 'Annulé';
    }
  }

  Color get color {
    switch (this) {
      case ContractStatus.brouillon:
        return Colors.grey;
      case ContractStatus.propose:
        return Colors.blue;
      case ContractStatus.enAttenteSignature:
        return Colors.orange;
      case ContractStatus.enAttentePaiement:
        return Colors.amber;
      case ContractStatus.actif:
        return Colors.green;
      case ContractStatus.aRenouveler:
        return Colors.deepOrange;
      case ContractStatus.expire:
        return Colors.red;
      case ContractStatus.suspendu:
        return Colors.purple;
      case ContractStatus.annule:
        return Colors.blueGrey;
    }
  }


}

/// 🛡️ Garantie d'assurance
class Garantie {
  final String nom;
  final String description;
  final bool incluse;
  final double montant;
  final double franchise;

  const Garantie({
    required this.nom,
    required this.description,
    required this.incluse,
    required this.montant,
    this.franchise = 0.0,
  });

  factory Garantie.fromMap(Map<String, dynamic> map) {
    return Garantie(
      nom: map['nom'] ?? '',
      description: map['description'] ?? '',
      incluse: map['incluse'] ?? false,
      montant: (map['montant'] ?? 0).toDouble(),
      franchise: (map['franchise'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'description': description,
      'incluse': incluse,
      'montant': montant,
      'franchise': franchise,
    };
  }
}

/// 💳 Informations de paiement
class PaymentInfo {
  final PaymentMethod methode;
  final PaymentFrequency frequence;
  final double montantTotal;
  final double montantPaye;
  final List<PaymentInstallment> echeances;
  final DateTime? datePremierPaiement;
  final DateTime? dateProchainPaiement;
  final PaymentStatus statut;

  const PaymentInfo({
    required this.methode,
    required this.frequence,
    required this.montantTotal,
    this.montantPaye = 0.0,
    required this.echeances,
    this.datePremierPaiement,
    this.dateProchainPaiement,
    required this.statut,
  });

  factory PaymentInfo.fromMap(Map<String, dynamic> map) {
    return PaymentInfo(
      methode: parsePaymentMethod(map['methode'] ?? 'carte_bancaire'),
      frequence: parsePaymentFrequency(map['frequence'] ?? 'annuel'),
      montantTotal: (map['montantTotal'] ?? 0).toDouble(),
      montantPaye: (map['montantPaye'] ?? 0).toDouble(),
      echeances: (map['echeances'] as List?)
          ?.map((e) => PaymentInstallment.fromMap(e))
          .toList() ?? [],
      datePremierPaiement: (map['datePremierPaiement'] as Timestamp?)?.toDate(),
      dateProchainPaiement: (map['dateProchainPaiement'] as Timestamp?)?.toDate(),
      statut: parsePaymentStatus(map['statut'] ?? 'en_attente'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'methode': methode.value,
      'frequence': frequence.value,
      'montantTotal': montantTotal,
      'montantPaye': montantPaye,
      'echeances': echeances.map((e) => e.toMap()).toList(),
      'datePremierPaiement': datePremierPaiement != null
          ? Timestamp.fromDate(datePremierPaiement!) : null,
      'dateProchainPaiement': dateProchainPaiement != null
          ? Timestamp.fromDate(dateProchainPaiement!) : null,
      'statut': statut.value,
    };
  }

  bool get isPaid => montantPaye >= montantTotal;
  bool get isPartiallyPaid => montantPaye > 0 && montantPaye < montantTotal;
  double get totalPaid => montantPaye;
  double get remainingAmount => montantTotal - montantPaye;
  int get paidInstallments => echeances.where((e) => e.isPaid).length;
  int get totalInstallments => echeances.length;
}

/// 💰 Méthodes de paiement
enum PaymentMethod {
  carteBancaire,
  virement,
  d17,
  especes,
  cheque,
}

extension PaymentMethodExtension on PaymentMethod {
  String get value {
    switch (this) {
      case PaymentMethod.carteBancaire:
        return 'carte_bancaire';
      case PaymentMethod.virement:
        return 'virement';
      case PaymentMethod.d17:
        return 'd17';
      case PaymentMethod.especes:
        return 'especes';
      case PaymentMethod.cheque:
        return 'cheque';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentMethod.carteBancaire:
        return 'Carte Bancaire';
      case PaymentMethod.virement:
        return 'Virement';
      case PaymentMethod.d17:
        return 'D17 (Tunisie)';
      case PaymentMethod.especes:
        return 'Espèces';
      case PaymentMethod.cheque:
        return 'Chèque';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.carteBancaire:
        return Icons.credit_card;
      case PaymentMethod.virement:
        return Icons.account_balance;
      case PaymentMethod.d17:
        return Icons.phone_android;
      case PaymentMethod.especes:
        return Icons.money;
      case PaymentMethod.cheque:
        return Icons.receipt;
    }
  }


}

/// 📅 Fréquence de paiement
enum PaymentFrequency {
  annuel,
  semestriel,
  trimestriel,
  mensuel,
}

extension PaymentFrequencyExtension on PaymentFrequency {
  String get value {
    switch (this) {
      case PaymentFrequency.annuel:
        return 'annuel';
      case PaymentFrequency.semestriel:
        return 'semestriel';
      case PaymentFrequency.trimestriel:
        return 'trimestriel';
      case PaymentFrequency.mensuel:
        return 'mensuel';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentFrequency.annuel:
        return 'Annuel';
      case PaymentFrequency.semestriel:
        return 'Semestriel';
      case PaymentFrequency.trimestriel:
        return 'Trimestriel';
      case PaymentFrequency.mensuel:
        return 'Mensuel';
    }
  }

  int get installmentCount {
    switch (this) {
      case PaymentFrequency.annuel:
        return 1;
      case PaymentFrequency.semestriel:
        return 2;
      case PaymentFrequency.trimestriel:
        return 4;
      case PaymentFrequency.mensuel:
        return 12;
    }
  }


}

/// 📊 Statut de paiement
enum PaymentStatus {
  enAttente,
  partiel,
  complet,
  enRetard,
  annule,
}

extension PaymentStatusExtension on PaymentStatus {
  String get value {
    switch (this) {
      case PaymentStatus.enAttente:
        return 'en_attente';
      case PaymentStatus.partiel:
        return 'partiel';
      case PaymentStatus.complet:
        return 'complet';
      case PaymentStatus.enRetard:
        return 'en_retard';
      case PaymentStatus.annule:
        return 'annule';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentStatus.enAttente:
        return 'En attente';
      case PaymentStatus.partiel:
        return 'Partiellement payé';
      case PaymentStatus.complet:
        return 'Payé intégralement';
      case PaymentStatus.enRetard:
        return 'En retard';
      case PaymentStatus.annule:
        return 'Annulé';
    }
  }

  Color get color {
    switch (this) {
      case PaymentStatus.enAttente:
        return Colors.orange;
      case PaymentStatus.partiel:
        return Colors.amber;
      case PaymentStatus.complet:
        return Colors.green;
      case PaymentStatus.enRetard:
        return Colors.red;
      case PaymentStatus.annule:
        return Colors.grey;
    }
  }


}

/// 💸 Échéance de paiement
class PaymentInstallment {
  final int numero;
  final double montant;
  final DateTime dateEcheance;
  final DateTime? datePaiement;
  final PaymentMethod? methodePaiement;
  final String? referencePaiement;
  final bool isPaid;

  const PaymentInstallment({
    required this.numero,
    required this.montant,
    required this.dateEcheance,
    this.datePaiement,
    this.methodePaiement,
    this.referencePaiement,
    this.isPaid = false,
  });

  factory PaymentInstallment.fromMap(Map<String, dynamic> map) {
    return PaymentInstallment(
      numero: map['numero'] ?? 1,
      montant: (map['montant'] ?? 0).toDouble(),
      dateEcheance: (map['dateEcheance'] as Timestamp?)?.toDate() ?? DateTime.now(),
      datePaiement: (map['datePaiement'] as Timestamp?)?.toDate(),
      methodePaiement: map['methodePaiement'] != null
          ? parsePaymentMethod(map['methodePaiement'])
          : null,
      referencePaiement: map['referencePaiement'],
      isPaid: map['isPaid'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'numero': numero,
      'montant': montant,
      'dateEcheance': Timestamp.fromDate(dateEcheance),
      'datePaiement': datePaiement != null
          ? Timestamp.fromDate(datePaiement!) : null,
      'methodePaiement': methodePaiement?.value,
      'referencePaiement': referencePaiement,
      'isPaid': isPaid,
    };
  }

  bool get isOverdue => !isPaid && DateTime.now().isAfter(dateEcheance);
  bool get isDueSoon => !isPaid && DateTime.now().isAfter(
      dateEcheance.subtract(const Duration(days: 7)));
}

/// 📄 Document de contrat
class ContractDocument {
  final String nom;
  final DocumentType type;
  final String url;
  final DateTime dateGeneration;
  final String? qrCode;
  final bool isDigitallySigned;

  const ContractDocument({
    required this.nom,
    required this.type,
    required this.url,
    required this.dateGeneration,
    this.qrCode,
    this.isDigitallySigned = false,
  });

  factory ContractDocument.fromMap(Map<String, dynamic> map) {
    return ContractDocument(
      nom: map['nom'] ?? '',
      type: parseDocumentType(map['type'] ?? 'contrat'),
      url: map['url'] ?? '',
      dateGeneration: (map['dateGeneration'] as Timestamp?)?.toDate() ?? DateTime.now(),
      qrCode: map['qrCode'],
      isDigitallySigned: map['isDigitallySigned'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'type': type.value,
      'url': url,
      'dateGeneration': Timestamp.fromDate(dateGeneration),
      'qrCode': qrCode,
      'isDigitallySigned': isDigitallySigned,
    };
  }
}

/// 📋 Types de documents
enum DocumentType {
  contrat,
  carteVerte,
  quittance,
  certificat,
  vignette,
}

extension DocumentTypeExtension on DocumentType {
  String get value {
    switch (this) {
      case DocumentType.contrat:
        return 'contrat';
      case DocumentType.carteVerte:
        return 'carte_verte';
      case DocumentType.quittance:
        return 'quittance';
      case DocumentType.certificat:
        return 'certificat';
      case DocumentType.vignette:
        return 'vignette';
    }
  }

  String get displayName {
    switch (this) {
      case DocumentType.contrat:
        return 'Contrat d\'assurance';
      case DocumentType.carteVerte:
        return 'Carte verte';
      case DocumentType.quittance:
        return 'Quittance de paiement';
      case DocumentType.certificat:
        return 'Certificat numérique';
      case DocumentType.vignette:
        return 'Vignette assurance';
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentType.contrat:
        return Icons.description;
      case DocumentType.carteVerte:
        return Icons.credit_card;
      case DocumentType.quittance:
        return Icons.receipt;
      case DocumentType.certificat:
        return Icons.verified;
      case DocumentType.vignette:
        return Icons.local_offer;
    }
  }


}

/// ✍️ Signature numérique
class DigitalSignature {
  final String conducteurId;
  final DateTime dateSignature;
  final String signatureHash;
  final String ipAddress;
  final String deviceInfo;
  final String? qrCodeValidation;

  const DigitalSignature({
    required this.conducteurId,
    required this.dateSignature,
    required this.signatureHash,
    required this.ipAddress,
    required this.deviceInfo,
    this.qrCodeValidation,
  });

  factory DigitalSignature.fromMap(Map<String, dynamic> map) {
    return DigitalSignature(
      conducteurId: map['conducteurId'] ?? '',
      dateSignature: (map['dateSignature'] as Timestamp?)?.toDate() ?? DateTime.now(),
      signatureHash: map['signatureHash'] ?? '',
      ipAddress: map['ipAddress'] ?? '',
      deviceInfo: map['deviceInfo'] ?? '',
      qrCodeValidation: map['qrCodeValidation'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conducteurId': conducteurId,
      'dateSignature': Timestamp.fromDate(dateSignature),
      'signatureHash': signatureHash,
      'ipAddress': ipAddress,
      'deviceInfo': deviceInfo,
      'qrCodeValidation': qrCodeValidation,
    };
  }

  bool get isValid => signatureHash.isNotEmpty && conducteurId.isNotEmpty;
}

// ========================================
// 🔧 FONCTIONS UTILITAIRES PRIVÉES
// ========================================

ContractType parseContractType(String value) {
  for (ContractType type in ContractType.values) {
    if (type.value == value) return type;
  }
  return ContractType.responsabiliteCivile;
}

ContractStatus parseContractStatus(String value) {
  for (ContractStatus status in ContractStatus.values) {
    if (status.value == value) return status;
  }
  return ContractStatus.brouillon;
}

PaymentMethod parsePaymentMethod(String value) {
  for (PaymentMethod method in PaymentMethod.values) {
    if (method.value == value) return method;
  }
  return PaymentMethod.carteBancaire;
}

PaymentFrequency parsePaymentFrequency(String value) {
  for (PaymentFrequency freq in PaymentFrequency.values) {
    if (freq.value == value) return freq;
  }
  return PaymentFrequency.annuel;
}

PaymentStatus parsePaymentStatus(String value) {
  for (PaymentStatus status in PaymentStatus.values) {
    if (status.value == value) return status;
  }
  return PaymentStatus.enAttente;
}

DocumentType parseDocumentType(String value) {
  for (DocumentType type in DocumentType.values) {
    if (type.value == value) return type;
  }
  return DocumentType.contrat;
}
