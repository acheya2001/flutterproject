import 'package:cloud_firestore/cloud_firestore.dart';

/// 🚗 Référence véhicule du participant
class ParticipantVehicleRef {
  final String? vehicleId;
  final String? plate;
  final String? brand;
  final String? model;
  final int? year;
  final String? vin;
  final String? color;
  final Map<String, dynamic> vehicleDetails;

  const ParticipantVehicleRef({
    this.vehicleId,
    this.plate,
    this.brand,
    this.model,
    this.year,
    this.vin,
    this.color,
    required this.vehicleDetails,
  });

  factory ParticipantVehicleRef.fromMap(Map<String, dynamic> map) {
    return ParticipantVehicleRef(
      vehicleId: map['vehicleId'],
      plate: map['plate'],
      brand: map['brand'],
      model: map['model'],
      year: map['year'],
      vin: map['vin'],
      color: map['color'],
      vehicleDetails: Map<String, dynamic>.from(map['vehicleDetails'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'plate': plate,
      'brand': brand,
      'model': model,
      'year': year,
      'vin': vin,
      'color': color,
      'vehicleDetails': vehicleDetails,
    };
  }
}

/// 📊 Statuts de participant
enum ParticipantStatus {
  notStarted,
  inProgress,
  completed,
  signed,
}

extension ParticipantStatusExtension on ParticipantStatus {
  String get value {
    switch (this) {
      case ParticipantStatus.notStarted:
        return 'not_started';
      case ParticipantStatus.inProgress:
        return 'in_progress';
      case ParticipantStatus.completed:
        return 'completed';
      case ParticipantStatus.signed:
        return 'signed';
    }
  }

  String get displayName {
    switch (this) {
      case ParticipantStatus.notStarted:
        return 'Non commencé';
      case ParticipantStatus.inProgress:
        return 'En cours';
      case ParticipantStatus.completed:
        return 'Terminé';
      case ParticipantStatus.signed:
        return 'Signé';
    }
  }

  static ParticipantStatus fromString(String value) {
    switch (value) {
      case 'not_started':
        return ParticipantStatus.notStarted;
      case 'in_progress':
        return ParticipantStatus.inProgress;
      case 'completed':
        return ParticipantStatus.completed;
      case 'signed':
        return ParticipantStatus.signed;
      default:
        return ParticipantStatus.notStarted;
    }
  }
}

/// 🎭 Rôles dans l'accident
enum RoleInAccident {
  conducteur,
  autreConducteur,
  temoin,
}

extension RoleInAccidentExtension on RoleInAccident {
  String get value {
    switch (this) {
      case RoleInAccident.conducteur:
        return 'conducteur';
      case RoleInAccident.autreConducteur:
        return 'autreConducteur';
      case RoleInAccident.temoin:
        return 'temoin';
    }
  }

  String get displayName {
    switch (this) {
      case RoleInAccident.conducteur:
        return 'Conducteur principal';
      case RoleInAccident.autreConducteur:
        return 'Autre conducteur';
      case RoleInAccident.temoin:
        return 'Témoin';
    }
  }

  static RoleInAccident fromString(String value) {
    switch (value) {
      case 'conducteur':
        return RoleInAccident.conducteur;
      case 'autreConducteur':
        return RoleInAccident.autreConducteur;
      case 'temoin':
        return RoleInAccident.temoin;
      default:
        return RoleInAccident.autreConducteur;
    }
  }
}

/// 👤 Modèle de participant au sinistre
class ParticipantModel {
  final String participantId;
  final String? uid;
  final String name;
  final String email;
  final String phone;
  final String? cin;
  final RoleInAccident roleInAccident;
  final ParticipantVehicleRef? vehicleRef;
  final bool isOwner;
  final ParticipantStatus status;
  final DateTime? signedAt;
  final String? signature; // base64 ou storage link
  final Map<String, dynamic> filledFields;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final String? lastUpdatedBy;
  final bool isFakeData;

  const ParticipantModel({
    required this.participantId,
    this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.cin,
    required this.roleInAccident,
    this.vehicleRef,
    required this.isOwner,
    required this.status,
    this.signedAt,
    this.signature,
    required this.filledFields,
    required this.createdAt,
    required this.lastUpdatedAt,
    this.lastUpdatedBy,
    this.isFakeData = false,
  });

  factory ParticipantModel.fromMap(Map<String, dynamic> map) {
    return ParticipantModel(
      participantId: map['participantId'] ?? '',
      uid: map['uid'],
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      cin: map['cin'],
      roleInAccident: RoleInAccidentExtension.fromString(map['roleInAccident'] ?? 'autreConducteur'),
      vehicleRef: map['vehicleRef'] != null ? ParticipantVehicleRef.fromMap(map['vehicleRef']) : null,
      isOwner: map['isOwner'] ?? false,
      status: ParticipantStatusExtension.fromString(map['status'] ?? 'not_started'),
      signedAt: (map['signedAt'] as Timestamp?)?.toDate(),
      signature: map['signature'],
      filledFields: Map<String, dynamic>.from(map['filledFields'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdatedAt: (map['lastUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdatedBy: map['lastUpdatedBy'],
      isFakeData: map['isFakeData'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participantId': participantId,
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'cin': cin,
      'roleInAccident': roleInAccident.value,
      'vehicleRef': vehicleRef?.toMap(),
      'isOwner': isOwner,
      'status': status.value,
      'signedAt': signedAt != null ? Timestamp.fromDate(signedAt!) : null,
      'signature': signature,
      'filledFields': filledFields,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
      'lastUpdatedBy': lastUpdatedBy,
      'isFakeData': isFakeData,
    };
  }

  bool get isSigned => status == ParticipantStatus.signed && signature != null;
  bool get isCompleted => status == ParticipantStatus.completed || status == ParticipantStatus.signed;
  bool get isRegistered => uid != null;
}
