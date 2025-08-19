import 'package:cloud_firestore/cloud_firestore.dart';

/// 👤 Propriétaire du véhicule
class VehicleOwner {
  final String name;
  final String cin;
  final String relationToConducteur; // 'proprietaire', 'parent', 'conjoint', 'ami', 'autre'
  final String? phone;

  const VehicleOwner({
    required this.name,
    required this.cin,
    required this.relationToConducteur,
    this.phone,
  });

  factory VehicleOwner.fromMap(Map<String, dynamic> map) {
    return VehicleOwner(
      name: map['name'] ?? '',
      cin: map['cin'] ?? '',
      relationToConducteur: map['relationToConducteur'] ?? 'proprietaire',
      phone: map['phone'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'cin': cin,
      'relationToConducteur': relationToConducteur,
      'phone': phone,
    };
  }
}

/// 📋 Contrat d'assurance véhicule
class VehicleContract {
  final String contractId;
  final String contractNumber;
  final String companyId;
  final String companyName;
  final String agencyId;
  final String agencyName;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String? policyType; // 'tous_risques', 'tiers', 'tiers_vol_incendie'
  final double? premium; // Prime annuelle
  final String? notes;

  /// Vérifie si le contrat est valide (actif et non expiré)
  bool get isValid => isActive && endDate.isAfter(DateTime.now());

  const VehicleContract({
    required this.contractId,
    required this.contractNumber,
    required this.companyId,
    required this.companyName,
    required this.agencyId,
    required this.agencyName,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.policyType,
    this.premium,
    this.notes,
  });

  factory VehicleContract.fromMap(Map<String, dynamic> map) {
    return VehicleContract(
      contractId: map['contractId'] ?? '',
      contractNumber: map['contractNumber'] ?? '',
      companyId: map['companyId'] ?? '',
      companyName: map['companyName'] ?? '',
      agencyId: map['agencyId'] ?? '',
      agencyName: map['agencyName'] ?? '',
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? false,
      policyType: map['policyType'],
      premium: map['premium']?.toDouble(),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contractId': contractId,
      'contractNumber': contractNumber,
      'companyId': companyId,
      'companyName': companyName,
      'agencyId': agencyId,
      'agencyName': agencyName,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      'policyType': policyType,
      'premium': premium,
      'notes': notes,
    };
  }

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isValidToday => isActive && !isExpired;
  
  int get daysUntilExpiry => endDate.difference(DateTime.now()).inDays;
}

/// 📄 Document véhicule
class VehicleDocument {
  final String id;
  final String type; // 'carte_grise', 'attestation_assurance'
  final String fileName;
  final String storagePath;
  final String downloadUrl;
  final DateTime uploadedAt;
  final bool isVerified;

  const VehicleDocument({
    required this.id,
    required this.type,
    required this.fileName,
    required this.storagePath,
    required this.downloadUrl,
    required this.uploadedAt,
    this.isVerified = false,
  });

  factory VehicleDocument.fromMap(Map<String, dynamic> map) {
    return VehicleDocument(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      fileName: map['fileName'] ?? '',
      storagePath: map['storagePath'] ?? '',
      downloadUrl: map['downloadUrl'] ?? '',
      uploadedAt: (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerified: map['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'fileName': fileName,
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'isVerified': isVerified,
    };
  }
}

/// 🚗 Modèle de véhicule conducteur
class ConducteurVehicleModel {
  final String vehicleId;
  final String conducteurUid;
  // Informations véhicule
  final String plate;
  final String brand;
  final String model;
  final int year;
  final String? vin;
  final String color;
  final String carteGriseNumber;
  final String fuelType; // essence, diesel, hybride, electrique, gpl
  final DateTime? firstRegistrationDate;
  // Informations conducteur
  final String conducteurNom;
  final String conducteurPrenom;
  final String conducteurAddress;
  final String conducteurPhone;
  final String conducteurEmail;
  final String permisNumber;
  final DateTime? permisDeliveryDate;
  // Propriétaire
  final bool isConducteurOwner;
  final VehicleOwner? owner; // Si conducteur n'est pas propriétaire
  // Documents et contrats
  final List<VehicleContract> contracts;
  final List<VehicleDocument> documents;
  // Métadonnées
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final bool isActive;
  final bool isFakeData;

  const ConducteurVehicleModel({
    required this.vehicleId,
    required this.conducteurUid,
    // Informations véhicule
    required this.plate,
    required this.brand,
    required this.model,
    required this.year,
    this.vin,
    required this.color,
    required this.carteGriseNumber,
    required this.fuelType,
    this.firstRegistrationDate,
    // Informations conducteur
    required this.conducteurNom,
    required this.conducteurPrenom,
    required this.conducteurAddress,
    required this.conducteurPhone,
    required this.conducteurEmail,
    required this.permisNumber,
    this.permisDeliveryDate,
    // Propriétaire
    required this.isConducteurOwner,
    this.owner,
    // Documents et contrats
    required this.contracts,
    required this.documents,
    // Métadonnées
    required this.createdAt,
    required this.lastUpdatedAt,
    this.isActive = true,
    this.isFakeData = false,
  });

  factory ConducteurVehicleModel.fromMap(Map<String, dynamic> map) {
    return ConducteurVehicleModel(
      vehicleId: map['vehicleId'] ?? '',
      conducteurUid: map['conducteurUid'] ?? '',
      // Informations véhicule
      plate: map['plate'] ?? '',
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      year: map['year'] ?? DateTime.now().year,
      vin: map['vin'],
      color: map['color'] ?? '',
      carteGriseNumber: map['carteGriseNumber'] ?? '',
      fuelType: map['fuelType'] ?? 'essence',
      firstRegistrationDate: (map['firstRegistrationDate'] as Timestamp?)?.toDate(),
      // Informations conducteur
      conducteurNom: map['conducteurNom'] ?? '',
      conducteurPrenom: map['conducteurPrenom'] ?? '',
      conducteurAddress: map['conducteurAddress'] ?? '',
      conducteurPhone: map['conducteurPhone'] ?? '',
      conducteurEmail: map['conducteurEmail'] ?? '',
      permisNumber: map['permisNumber'] ?? '',
      permisDeliveryDate: (map['permisDeliveryDate'] as Timestamp?)?.toDate(),
      // Propriétaire
      isConducteurOwner: map['isConducteurOwner'] ?? true,
      owner: map['owner'] != null ? VehicleOwner.fromMap(map['owner']) : null,
      // Documents et contrats
      contracts: (map['contracts'] as List?)
          ?.map((contract) => VehicleContract.fromMap(contract))
          .toList() ?? [],
      documents: (map['documents'] as List?)
          ?.map((doc) => VehicleDocument.fromMap(doc))
          .toList() ?? [],
      // Métadonnées
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdatedAt: (map['lastUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      isFakeData: map['isFakeData'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'conducteurUid': conducteurUid,
      // Informations véhicule
      'plate': plate,
      'brand': brand,
      'model': model,
      'year': year,
      'vin': vin,
      'color': color,
      'carteGriseNumber': carteGriseNumber,
      'fuelType': fuelType,
      'firstRegistrationDate': firstRegistrationDate != null ? Timestamp.fromDate(firstRegistrationDate!) : null,
      // Informations conducteur
      'conducteurNom': conducteurNom,
      'conducteurPrenom': conducteurPrenom,
      'conducteurAddress': conducteurAddress,
      'conducteurPhone': conducteurPhone,
      'conducteurEmail': conducteurEmail,
      'permisNumber': permisNumber,
      'permisDeliveryDate': permisDeliveryDate != null ? Timestamp.fromDate(permisDeliveryDate!) : null,
      // Propriétaire
      'isConducteurOwner': isConducteurOwner,
      'owner': owner?.toMap(),
      // Documents et contrats
      'contracts': contracts.map((contract) => contract.toMap()).toList(),
      'documents': documents.map((doc) => doc.toMap()).toList(),
      // Métadonnées
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
      'isActive': isActive,
      'isFakeData': isFakeData,
    };
  }

  String get fullName => '$brand $model ($year)';
  String get ownerName => isConducteurOwner ? 'Moi' : (owner?.name ?? 'Non renseigné');
  
  VehicleContract? get activeContract {
    try {
      return contracts.firstWhere((contract) => contract.isValidToday);
    } catch (e) {
      return null;
    }
  }

  List<VehicleContract> get activeContracts => 
      contracts.where((contract) => contract.isValidToday).toList();

  bool get hasValidInsurance => activeContract != null;
  
  VehicleDocument? getDocument(String type) {
    try {
      return documents.firstWhere((doc) => doc.type == type);
    } catch (e) {
      return null;
    }
  }

  bool get hasCarteGrise => getDocument('carte_grise') != null;
  bool get hasAttestationAssurance => getDocument('attestation_assurance') != null;

  ConducteurVehicleModel copyWith({
    String? vehicleId,
    String? conducteurUid,
    // Informations véhicule
    String? plate,
    String? brand,
    String? model,
    int? year,
    String? vin,
    String? color,
    String? carteGriseNumber,
    String? fuelType,
    DateTime? firstRegistrationDate,
    // Informations conducteur
    String? conducteurNom,
    String? conducteurPrenom,
    String? conducteurAddress,
    String? conducteurPhone,
    String? conducteurEmail,
    String? permisNumber,
    DateTime? permisDeliveryDate,
    // Propriétaire
    bool? isConducteurOwner,
    VehicleOwner? owner,
    // Documents et contrats
    List<VehicleContract>? contracts,
    List<VehicleDocument>? documents,
    // Métadonnées
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    bool? isActive,
    bool? isFakeData,
  }) {
    return ConducteurVehicleModel(
      vehicleId: vehicleId ?? this.vehicleId,
      conducteurUid: conducteurUid ?? this.conducteurUid,
      // Informations véhicule
      plate: plate ?? this.plate,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      vin: vin ?? this.vin,
      color: color ?? this.color,
      carteGriseNumber: carteGriseNumber ?? this.carteGriseNumber,
      fuelType: fuelType ?? this.fuelType,
      firstRegistrationDate: firstRegistrationDate ?? this.firstRegistrationDate,
      // Informations conducteur
      conducteurNom: conducteurNom ?? this.conducteurNom,
      conducteurPrenom: conducteurPrenom ?? this.conducteurPrenom,
      conducteurAddress: conducteurAddress ?? this.conducteurAddress,
      conducteurPhone: conducteurPhone ?? this.conducteurPhone,
      conducteurEmail: conducteurEmail ?? this.conducteurEmail,
      permisNumber: permisNumber ?? this.permisNumber,
      permisDeliveryDate: permisDeliveryDate ?? this.permisDeliveryDate,
      // Propriétaire
      isConducteurOwner: isConducteurOwner ?? this.isConducteurOwner,
      owner: owner ?? this.owner,
      // Documents et contrats
      contracts: contracts ?? this.contracts,
      documents: documents ?? this.documents,
      // Métadonnées
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      isActive: isActive ?? this.isActive,
      isFakeData: isFakeData ?? this.isFakeData,
    );
  }
}
