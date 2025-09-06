import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// 🏢 Compagnie d'assurance
class InsuranceCompany {
  final String companyId;
  final String name;
  final String code; // Code unique (ex: "STAR", "GAT", "COMAR")
  final String? logo;
  final String? description;
  final String? website;
  final String? phone;
  final String? email;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;

  const InsuranceCompany({
    required this.companyId,
    required this.name,
    required this.code,
    this.logo,
    this.description,
    this.website,
    this.phone,
    this.email,
    this.isActive = true,
    required this.createdAt,
    required this.lastUpdatedAt,
  });

  factory InsuranceCompany.fromMap(Map<String, dynamic> map) {
    return InsuranceCompany(
      companyId: map['companyId'] ?? '',
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      logo: map['logo'],
      description: map['description'],
      website: map['website'],
      phone: map['phone'],
      email: map['email'],
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdatedAt: (map['lastUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'name': name,
      'code': code,
      'logo': logo,
      'description': description,
      'website': website,
      'phone': phone,
      'email': email,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
    };
  }
}

/// 🏪 Agence d'assurance
class InsuranceAgency {
  final String agencyId;
  final String companyId; // Référence à la compagnie
  final String name;
  final String code; // Code unique dans la compagnie
  final String? address;
  final String? city;
  final String? governorate;
  final String? postalCode;
  final String? phone;
  final String? email;
  final String? managerName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;

  const InsuranceAgency({
    required this.agencyId,
    required this.companyId,
    required this.name,
    required this.code,
    this.address,
    this.city,
    this.governorate,
    this.postalCode,
    this.phone,
    this.email,
    this.managerName,
    this.isActive = true,
    required this.createdAt,
    required this.lastUpdatedAt,
  });

  factory InsuranceAgency.fromMap(Map<String, dynamic> map) {
    return InsuranceAgency(
      agencyId: map['agencyId'] ?? '',
      companyId: map['companyId'] ?? '',
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      address: map['address'],
      city: map['city'],
      governorate: map['governorate'],
      postalCode: map['postalCode'],
      phone: map['phone'],
      email: map['email'],
      managerName: map['managerName'],
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdatedAt: (map['lastUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'agencyId': agencyId,
      'companyId': companyId,
      'name': name,
      'code': code,
      'address': address,
      'city': city,
      'governorate': governorate,
      'postalCode': postalCode,
      'phone': phone,
      'email': email,
      'managerName': managerName,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
    };
  }

  String get fullAddress {
    final parts = [address, city, governorate, postalCode]
        .where((part) => part != null && part.isNotEmpty)
        .toList();
    return parts.join(', ');
  }
}

/// 👨‍💼 Agent d'agence
class InsuranceAgent {
  final String agentId;
  final String agencyId; // Référence à l'agence
  final String companyId; // Référence à la compagnie
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? employeeId; // Numéro d'employé
  final String role; // 'manager', 'agent', 'assistant'
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;

  const InsuranceAgent({
    required this.agentId,
    required this.agencyId,
    required this.companyId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.employeeId,
    this.role = 'agent',
    this.isActive = true,
    required this.createdAt,
    required this.lastUpdatedAt,
  });

  factory InsuranceAgent.fromMap(Map<String, dynamic> map) {
    return InsuranceAgent(
      agentId: map['agentId'] ?? '',
      agencyId: map['agencyId'] ?? '',
      companyId: map['companyId'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      employeeId: map['employeeId'],
      role: map['role'] ?? 'agent',
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdatedAt: (map['lastUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'agentId': agentId,
      'agencyId': agencyId,
      'companyId': companyId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'employeeId': employeeId,
      'role': role,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
    };
  }

  String get fullName => '$firstName $lastName';
}

/// 📊 Statuts de véhicule dans le workflow complet
enum VehicleStatus {
  enAttenteValidation,  // 1. Soumis par conducteur, en attente validation admin agence
  valide,              // 2. Validé par admin agence, assigné à un agent
  contratEnCours,      // 3. Agent en train de créer le contrat
  contratPropose,      // 4. Contrat créé, en attente signature/paiement conducteur
  assure,              // 5. Contrat signé et payé, véhicule assuré
  aRenouveler,         // 6. Contrat proche expiration (30 jours)
  expire,              // 7. Contrat expiré
  suspendu,            // 8. Contrat suspendu (impayé)
  refuse,              // 9. Refusé par admin agence
  annule,              // 10. Annulé par le conducteur
}

extension VehicleStatusExtension on VehicleStatus {
  String get value {
    switch (this) {
      case VehicleStatus.enAttenteValidation:
        return 'en_attente_validation';
      case VehicleStatus.valide:
        return 'valide';
      case VehicleStatus.contratEnCours:
        return 'contrat_en_cours';
      case VehicleStatus.contratPropose:
        return 'contrat_propose';
      case VehicleStatus.assure:
        return 'assure';
      case VehicleStatus.aRenouveler:
        return 'a_renouveler';
      case VehicleStatus.expire:
        return 'expire';
      case VehicleStatus.suspendu:
        return 'suspendu';
      case VehicleStatus.refuse:
        return 'refuse';
      case VehicleStatus.annule:
        return 'annule';
    }
  }

  String get displayName {
    switch (this) {
      case VehicleStatus.enAttenteValidation:
        return 'En attente de validation';
      case VehicleStatus.valide:
        return 'Validé - Assigné à agent';
      case VehicleStatus.contratEnCours:
        return 'Contrat en cours de création';
      case VehicleStatus.contratPropose:
        return 'Contrat proposé';
      case VehicleStatus.assure:
        return 'Assuré';
      case VehicleStatus.aRenouveler:
        return 'À renouveler';
      case VehicleStatus.expire:
        return 'Expiré';
      case VehicleStatus.suspendu:
        return 'Suspendu';
      case VehicleStatus.refuse:
        return 'Refusé';
      case VehicleStatus.annule:
        return 'Annulé';
    }
  }

  MaterialColor get color {
    switch (this) {
      case VehicleStatus.enAttenteValidation:
        return Colors.orange;
      case VehicleStatus.valide:
        return Colors.blue;
      case VehicleStatus.contratEnCours:
        return Colors.indigo;
      case VehicleStatus.contratPropose:
        return Colors.purple;
      case VehicleStatus.assure:
        return Colors.green;
      case VehicleStatus.aRenouveler:
        return Colors.amber;
      case VehicleStatus.expire:
        return Colors.brown;
      case VehicleStatus.suspendu:
        return Colors.grey;
      case VehicleStatus.refuse:
        return Colors.red;
      case VehicleStatus.annule:
        return Colors.blueGrey;
    }
  }

  IconData get icon {
    switch (this) {
      case VehicleStatus.enAttenteValidation:
        return Icons.pending;
      case VehicleStatus.valide:
        return Icons.check_circle_outline;
      case VehicleStatus.contratEnCours:
        return Icons.edit_document;
      case VehicleStatus.contratPropose:
        return Icons.description;
      case VehicleStatus.assure:
        return Icons.verified;
      case VehicleStatus.aRenouveler:
        return Icons.refresh;
      case VehicleStatus.expire:
        return Icons.schedule;
      case VehicleStatus.suspendu:
        return Icons.pause_circle;
      case VehicleStatus.refuse:
        return Icons.cancel;
      case VehicleStatus.annule:
        return Icons.block;
    }
  }
}

/// 📋 Véhicule en attente de validation
class PendingVehicle {
  final String vehicleId;
  final String conducteurId;
  final String conducteurNom;
  final String conducteurPrenom;
  final String conducteurTelephone;
  // Informations conducteur enrichies
  final String conducteurAddress;
  final String conducteurEmail;
  final String permisNumber;
  final DateTime? permisDeliveryDate;
  // Informations compagnie/agence
  final String companyId;
  final String companyName;
  final String agencyId;
  final String agencyName;
  // Informations véhicule enrichies
  final String brand;
  final String model;
  final String plate;
  final int year;
  final String? vin;
  final String color;
  final String carteGriseNumber;
  final String fuelType;
  final DateTime? firstRegistrationDate;
  // Documents et validation
  final List<String> documents; // URLs des documents
  final VehicleStatus status;
  final DateTime submittedAt;
  final String? validatedBy; // Agent ID
  final DateTime? validatedAt;
  final String? rejectionReason;
  final String? contractId; // ID du contrat une fois créé

  const PendingVehicle({
    required this.vehicleId,
    required this.conducteurId,
    required this.conducteurNom,
    required this.conducteurPrenom,
    required this.conducteurTelephone,
    // Informations conducteur enrichies
    required this.conducteurAddress,
    required this.conducteurEmail,
    required this.permisNumber,
    this.permisDeliveryDate,
    // Informations compagnie/agence
    required this.companyId,
    required this.companyName,
    required this.agencyId,
    required this.agencyName,
    // Informations véhicule enrichies
    required this.brand,
    required this.model,
    required this.plate,
    required this.year,
    this.vin,
    required this.color,
    required this.carteGriseNumber,
    required this.fuelType,
    this.firstRegistrationDate,
    // Documents et validation
    required this.documents,
    this.status = VehicleStatus.enAttenteValidation,
    required this.submittedAt,
    this.validatedBy,
    this.validatedAt,
    this.rejectionReason,
    this.contractId,
  });

  factory PendingVehicle.fromMap(Map<String, dynamic> map) {
    // Convertir le statut string en enum
    VehicleStatus statusEnum = VehicleStatus.enAttenteValidation;
    final statusString = map['status'] ?? 'en_attente_validation';
    for (VehicleStatus status in VehicleStatus.values) {
      if (status.value == statusString) {
        statusEnum = status;
        break;
      }
    }

    return PendingVehicle(
      vehicleId: map['vehicleId'] ?? '',
      conducteurId: map['conducteurId'] ?? '',
      conducteurNom: map['conducteurNom'] ?? '',
      conducteurPrenom: map['conducteurPrenom'] ?? '',
      conducteurTelephone: map['conducteurTelephone'] ?? '',
      // Informations conducteur enrichies
      conducteurAddress: map['conducteurAddress'] ?? '',
      conducteurEmail: map['conducteurEmail'] ?? '',
      permisNumber: map['permisNumber'] ?? '',
      permisDeliveryDate: map['permisDeliveryDate'] != null
          ? (map['permisDeliveryDate'] as Timestamp).toDate()
          : null,
      // Informations compagnie/agence
      companyId: map['companyId'] ?? '',
      companyName: map['companyName'] ?? '',
      agencyId: map['agencyId'] ?? '',
      agencyName: map['agencyName'] ?? '',
      // Informations véhicule enrichies
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      plate: map['plate'] ?? '',
      year: map['year'] ?? 0,
      vin: map['vin'],
      color: map['color'] ?? '',
      carteGriseNumber: map['carteGriseNumber'] ?? '',
      fuelType: map['fuelType'] ?? 'essence',
      firstRegistrationDate: map['firstRegistrationDate'] != null
          ? (map['firstRegistrationDate'] as Timestamp).toDate()
          : null,
      // Documents et validation
      documents: List<String>.from(map['documents'] ?? []),
      status: statusEnum,
      submittedAt: (map['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      validatedBy: map['validatedBy'],
      validatedAt: map['validatedAt'] != null
          ? (map['validatedAt'] as Timestamp).toDate()
          : null,
      rejectionReason: map['rejectionReason'],
      contractId: map['contractId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'conducteurId': conducteurId,
      'conducteurNom': conducteurNom,
      'conducteurPrenom': conducteurPrenom,
      'conducteurTelephone': conducteurTelephone,
      // Informations conducteur enrichies
      'conducteurAddress': conducteurAddress,
      'conducteurEmail': conducteurEmail,
      'permisNumber': permisNumber,
      'permisDeliveryDate': permisDeliveryDate != null ? Timestamp.fromDate(permisDeliveryDate!) : null,
      // Informations compagnie/agence
      'companyId': companyId,
      'companyName': companyName,
      'agencyId': agencyId,
      'agencyName': agencyName,
      // Informations véhicule enrichies
      'brand': brand,
      'model': model,
      'plate': plate,
      'year': year,
      'vin': vin,
      'color': color,
      'carteGriseNumber': carteGriseNumber,
      'fuelType': fuelType,
      'firstRegistrationDate': firstRegistrationDate != null ? Timestamp.fromDate(firstRegistrationDate!) : null,
      // Documents et validation
      'documents': documents,
      'status': status.value,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'validatedBy': validatedBy,
      'validatedAt': validatedAt != null ? Timestamp.fromDate(validatedAt!) : null,
      'rejectionReason': rejectionReason,
      'contractId': contractId,
    };
  }

  String get fullName => '$brand $model ($year)';
  String get conducteurFullName => '$conducteurPrenom $conducteurNom';

  bool get isPending => status == VehicleStatus.enAttenteValidation;
  bool get isValidated => status == VehicleStatus.valide;
  bool get isRejected => status == VehicleStatus.refuse;
  bool get isInsured => status == VehicleStatus.assure;
}
