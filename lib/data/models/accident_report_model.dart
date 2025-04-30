// lib/data/models/accident_report_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:constat_tunisie/data/models/user_model.dart';
import 'package:constat_tunisie/data/models/vehicle_model.dart';
import 'package:constat_tunisie/data/models/insurance_model.dart';

class AccidentReport {
  final String id;
  final DateTime date;
  final GeoPoint location;
  final String address;
  final bool hasInjuries;
  final bool hasOtherDamage;
  final List<Witness> witnesses;
  
  // Parties impliquées
  final PartyInformation partyA;
  final PartyInformation? partyB; // Peut être null si l'autre partie n'a pas encore rempli
  
  // Circonstances
  final List<CircumstanceItem> circumstancesA;
  final List<CircumstanceItem> circumstancesB;
  
  // Croquis de l'accident
  final String sketchImageUrl;
  final Map<String, dynamic> sketchData; // Pour stocker les données vectorielles du croquis
  
  // Observations
  final String observationsA;
  final String observationsB;
  
  // Signatures
  final String signatureAUrl;
  final String signatureBUrl;
  
  // Statut du constat
  final ReportStatus status;
  
  // Métadonnées
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy; // UID du créateur
  final String? invitationCode; // Code pour inviter l'autre partie
  
  // Constructeur
  AccidentReport({
    required this.id,
    required this.date,
    required this.location,
    required this.address,
    required this.hasInjuries,
    required this.hasOtherDamage,
    required this.witnesses,
    required this.partyA,
    this.partyB,
    required this.circumstancesA,
    required this.circumstancesB,
    required this.sketchImageUrl,
    required this.sketchData,
    required this.observationsA,
    required this.observationsB,
    required this.signatureAUrl,
    required this.signatureBUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.invitationCode,
  });
  
  // Conversion depuis/vers Firestore
  factory AccidentReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AccidentReport(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      location: data['location'] as GeoPoint,
      address: data['address'] as String,
      hasInjuries: data['hasInjuries'] as bool,
      hasOtherDamage: data['hasOtherDamage'] as bool,
      witnesses: (data['witnesses'] as List).map((w) => Witness.fromMap(w)).toList(),
      partyA: PartyInformation.fromMap(data['partyA']),
      partyB: data['partyB'] != null ? PartyInformation.fromMap(data['partyB']) : null,
      circumstancesA: (data['circumstancesA'] as List).map((c) => CircumstanceItem.fromMap(c)).toList(),
      circumstancesB: (data['circumstancesB'] as List).map((c) => CircumstanceItem.fromMap(c)).toList(),
      sketchImageUrl: data['sketchImageUrl'] as String,
      sketchData: data['sketchData'] as Map<String, dynamic>,
      observationsA: data['observationsA'] as String,
      observationsB: data['observationsB'] as String,
      signatureAUrl: data['signatureAUrl'] as String,
      signatureBUrl: data['signatureBUrl'] as String? ?? '',
      status: ReportStatus.values[data['status'] as int],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] as String,
      invitationCode: data['invitationCode'] as String?,
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'location': location,
      'address': address,
      'hasInjuries': hasInjuries,
      'hasOtherDamage': hasOtherDamage,
      'witnesses': witnesses.map((w) => w.toMap()).toList(),
      'partyA': partyA.toMap(),
      'partyB': partyB?.toMap(),
      'circumstancesA': circumstancesA.map((c) => c.toMap()).toList(),
      'circumstancesB': circumstancesB.map((c) => c.toMap()).toList(),
      'sketchImageUrl': sketchImageUrl,
      'sketchData': sketchData,
      'observationsA': observationsA,
      'observationsB': observationsB,
      'signatureAUrl': signatureAUrl,
      'signatureBUrl': signatureBUrl,
      'status': status.index,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'invitationCode': invitationCode,
    };
  }
}

class PartyInformation {
  final String userId;
  final String driverName;
  final String driverAddress;
  final String driverLicenseNumber;
  final DateTime driverLicenseDate;
  final String driverPhone;
  final String driverEmail;
  
  // Véhicule
  final String vehicleId;
  final String vehicleMake;
  final String vehicleModel;
  final String vehiclePlateNumber;
  final String vehicleRegistrationNumber;
  
  // Assurance
  final String insuranceCompanyId;
  final String insuranceAgencyId;
  final String insuranceContractNumber;
  final DateTime insuranceValidFrom;
  final DateTime insuranceValidTo;
  
  // Dommages visibles
  final List<String> visibleDamages;
  final List<String> damagePhotoUrls;
  
  // Point d'impact initial
  final ImpactPoint initialImpact;
  
  PartyInformation({
    required this.userId,
    required this.driverName,
    required this.driverAddress,
    required this.driverLicenseNumber,
    required this.driverLicenseDate,
    required this.driverPhone,
    required this.driverEmail,
    required this.vehicleId,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehiclePlateNumber,
    required this.vehicleRegistrationNumber,
    required this.insuranceCompanyId,
    required this.insuranceAgencyId,
    required this.insuranceContractNumber,
    required this.insuranceValidFrom,
    required this.insuranceValidTo,
    required this.visibleDamages,
    required this.damagePhotoUrls,
    required this.initialImpact,
  });
  
  factory PartyInformation.fromMap(Map<String, dynamic> map) {
    return PartyInformation(
      userId: map['userId'] as String,
      driverName: map['driverName'] as String,
      driverAddress: map['driverAddress'] as String,
      driverLicenseNumber: map['driverLicenseNumber'] as String,
      driverLicenseDate: (map['driverLicenseDate'] as Timestamp).toDate(),
      driverPhone: map['driverPhone'] as String,
      driverEmail: map['driverEmail'] as String,
      vehicleId: map['vehicleId'] as String,
      vehicleMake: map['vehicleMake'] as String,
      vehicleModel: map['vehicleModel'] as String,
      vehiclePlateNumber: map['vehiclePlateNumber'] as String,
      vehicleRegistrationNumber: map['vehicleRegistrationNumber'] as String,
      insuranceCompanyId: map['insuranceCompanyId'] as String,
      insuranceAgencyId: map['insuranceAgencyId'] as String,
      insuranceContractNumber: map['insuranceContractNumber'] as String,
      insuranceValidFrom: (map['insuranceValidFrom'] as Timestamp).toDate(),
      insuranceValidTo: (map['insuranceValidTo'] as Timestamp).toDate(),
      visibleDamages: List<String>.from(map['visibleDamages']),
      damagePhotoUrls: List<String>.from(map['damagePhotoUrls']),
      initialImpact: ImpactPoint.values[map['initialImpact'] as int],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'driverName': driverName,
      'driverAddress': driverAddress,
      'driverLicenseNumber': driverLicenseNumber,
      'driverLicenseDate': Timestamp.fromDate(driverLicenseDate),
      'driverPhone': driverPhone,
      'driverEmail': driverEmail,
      'vehicleId': vehicleId,
      'vehicleMake': vehicleMake,
      'vehicleModel': vehicleModel,
      'vehiclePlateNumber': vehiclePlateNumber,
      'vehicleRegistrationNumber': vehicleRegistrationNumber,
      'insuranceCompanyId': insuranceCompanyId,
      'insuranceAgencyId': insuranceAgencyId,
      'insuranceContractNumber': insuranceContractNumber,
      'insuranceValidFrom': Timestamp.fromDate(insuranceValidFrom),
      'insuranceValidTo': Timestamp.fromDate(insuranceValidTo),
      'visibleDamages': visibleDamages,
      'damagePhotoUrls': damagePhotoUrls,
      'initialImpact': initialImpact.index,
    };
  }
}

class Witness {
  final String name;
  final String address;
  final String phone;
  final bool isPassenger;
  final String? partyId; // 'A' ou 'B' si c'est un passager
  
  Witness({
    required this.name,
    required this.address,
    required this.phone,
    required this.isPassenger,
    this.partyId,
  });
  
  factory Witness.fromMap(Map<String, dynamic> map) {
    return Witness(
      name: map['name'] as String,
      address: map['address'] as String,
      phone: map['phone'] as String,
      isPassenger: map['isPassenger'] as bool,
      partyId: map['partyId'] as String?,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'isPassenger': isPassenger,
      'partyId': partyId,
    };
  }
}

class CircumstanceItem {
  final int id;
  final String description;
  final bool isChecked;
  
  CircumstanceItem({
    required this.id,
    required this.description,
    required this.isChecked,
  });
  
  factory CircumstanceItem.fromMap(Map<String, dynamic> map) {
    return CircumstanceItem(
      id: map['id'] as int,
      description: map['description'] as String,
      isChecked: map['isChecked'] as bool,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'isChecked': isChecked,
    };
  }
}

enum ReportStatus {
  draft,
  pendingPartyB,
  completed,
  submittedToInsurance,
  processingByInsurance,
  closed
}

enum ImpactPoint {
  front,
  frontRight,
  right,
  rearRight,
  rear,
  rearLeft,
  left,
  frontLeft
}