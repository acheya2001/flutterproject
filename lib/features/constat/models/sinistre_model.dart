import 'package:cloud_firestore/cloud_firestore.dart';

/// 📍 Modèle de localisation
class SinistreLocation {
  final double lat;
  final double lng;
  final String address;

  const SinistreLocation({
    required this.lat,
    required this.lng,
    required this.address,
  });

  factory SinistreLocation.fromMap(Map<String, dynamic> map) {
    return SinistreLocation(
      lat: (map['lat'] ?? 0.0).toDouble(),
      lng: (map['lng'] ?? 0.0).toDouble(),
      address: map['address'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'address': address,
    };
  }
}

/// 🚗 Référence véhicule dans sinistre
class SinistreVehicleRef {
  final String vehicleId;
  final String? ownerUid;
  final bool isOwnerBoolean;
  final String? plate;
  final String? brand;
  final String? model;

  const SinistreVehicleRef({
    required this.vehicleId,
    this.ownerUid,
    required this.isOwnerBoolean,
    this.plate,
    this.brand,
    this.model,
  });

  factory SinistreVehicleRef.fromMap(Map<String, dynamic> map) {
    return SinistreVehicleRef(
      vehicleId: map['vehicleId'] ?? '',
      ownerUid: map['ownerUid'],
      isOwnerBoolean: map['isOwnerBoolean'] ?? false,
      plate: map['plate'],
      brand: map['brand'],
      model: map['model'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'ownerUid': ownerUid,
      'isOwnerBoolean': isOwnerBoolean,
      'plate': plate,
      'brand': brand,
      'model': model,
    };
  }
}

/// 📋 Référence contrat dans sinistre
class SinistreContractRef {
  final String contractId;
  final String agencyId;
  final String companyId;
  final bool contractMissing;

  const SinistreContractRef({
    required this.contractId,
    required this.agencyId,
    required this.companyId,
    this.contractMissing = false,
  });

  factory SinistreContractRef.fromMap(Map<String, dynamic> map) {
    return SinistreContractRef(
      contractId: map['contractId'] ?? '',
      agencyId: map['agencyId'] ?? '',
      companyId: map['companyId'] ?? '',
      contractMissing: map['contractMissing'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contractId': contractId,
      'agencyId': agencyId,
      'companyId': companyId,
      'contractMissing': contractMissing,
    };
  }
}

/// 👥 Témoin
class SinistreWitness {
  final String name;
  final String phone;
  final String statement;
  final List<String> attachmentRefs;

  const SinistreWitness({
    required this.name,
    required this.phone,
    required this.statement,
    required this.attachmentRefs,
  });

  factory SinistreWitness.fromMap(Map<String, dynamic> map) {
    return SinistreWitness(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      statement: map['statement'] ?? '',
      attachmentRefs: List<String>.from(map['attachmentRefs'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'statement': statement,
      'attachmentRefs': attachmentRefs,
    };
  }
}

/// 📎 Pièce jointe
class SinistreAttachment {
  final String id;
  final String storagePath;
  final String type; // image, video, document
  final String uploadedBy;
  final DateTime uploadedAt;
  final String? thumbUrl;
  final String filename;
  final int size;
  final String mimeType;

  const SinistreAttachment({
    required this.id,
    required this.storagePath,
    required this.type,
    required this.uploadedBy,
    required this.uploadedAt,
    this.thumbUrl,
    required this.filename,
    required this.size,
    required this.mimeType,
  });

  factory SinistreAttachment.fromMap(Map<String, dynamic> map) {
    return SinistreAttachment(
      id: map['id'] ?? '',
      storagePath: map['storagePath'] ?? '',
      type: map['type'] ?? '',
      uploadedBy: map['uploadedBy'] ?? '',
      uploadedAt: (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      thumbUrl: map['thumbUrl'],
      filename: map['filename'] ?? '',
      size: map['size'] ?? 0,
      mimeType: map['mimeType'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'storagePath': storagePath,
      'type': type,
      'uploadedBy': uploadedBy,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'thumbUrl': thumbUrl,
      'filename': filename,
      'size': size,
      'mimeType': mimeType,
    };
  }
}

/// 📧 Invitation
class SinistreInvite {
  final String inviteId;
  final String emailOrPhone;
  final String token;
  final DateTime expiresAt;
  final String status; // pending, accepted, declined, expired

  const SinistreInvite({
    required this.inviteId,
    required this.emailOrPhone,
    required this.token,
    required this.expiresAt,
    required this.status,
  });

  factory SinistreInvite.fromMap(Map<String, dynamic> map) {
    return SinistreInvite(
      inviteId: map['inviteId'] ?? '',
      emailOrPhone: map['emailOrPhone'] ?? '',
      token: map['token'] ?? '',
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'inviteId': inviteId,
      'emailOrPhone': emailOrPhone,
      'token': token,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'status': status,
    };
  }
}

/// 🤖 Analyse IA
class SinistreIAAnalysis {
  final String status;
  final String summaryText;
  final String? videoUrl;
  final Map<String, dynamic> metrics;

  const SinistreIAAnalysis({
    required this.status,
    required this.summaryText,
    this.videoUrl,
    required this.metrics,
  });

  factory SinistreIAAnalysis.fromMap(Map<String, dynamic> map) {
    return SinistreIAAnalysis(
      status: map['status'] ?? '',
      summaryText: map['summaryText'] ?? '',
      videoUrl: map['videoUrl'],
      metrics: Map<String, dynamic>.from(map['metrics'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'summaryText': summaryText,
      'videoUrl': videoUrl,
      'metrics': metrics,
    };
  }
}

/// 📊 Statuts de sinistre
enum SinistreStatus {
  draft,
  open,
  inProgress,
  underExpertise,
  closed,
  rejected,
}

extension SinistreStatusExtension on SinistreStatus {
  String get value {
    switch (this) {
      case SinistreStatus.draft:
        return 'draft';
      case SinistreStatus.open:
        return 'open';
      case SinistreStatus.inProgress:
        return 'in_progress';
      case SinistreStatus.underExpertise:
        return 'under_expertise';
      case SinistreStatus.closed:
        return 'closed';
      case SinistreStatus.rejected:
        return 'rejected';
    }
  }

  String get displayName {
    switch (this) {
      case SinistreStatus.draft:
        return 'Brouillon';
      case SinistreStatus.open:
        return 'Ouvert';
      case SinistreStatus.inProgress:
        return 'En cours';
      case SinistreStatus.underExpertise:
        return 'Sous expertise';
      case SinistreStatus.closed:
        return 'Fermé';
      case SinistreStatus.rejected:
        return 'Rejeté';
    }
  }

  static SinistreStatus fromString(String value) {
    switch (value) {
      case 'draft':
        return SinistreStatus.draft;
      case 'open':
        return SinistreStatus.open;
      case 'in_progress':
        return SinistreStatus.inProgress;
      case 'under_expertise':
        return SinistreStatus.underExpertise;
      case 'closed':
        return SinistreStatus.closed;
      case 'rejected':
        return SinistreStatus.rejected;
      default:
        return SinistreStatus.draft;
    }
  }
}

/// 🚨 Modèle principal de sinistre
class SinistreModel {
  final String id;
  final String createdBy;
  final DateTime createdAt;
  final SinistreStatus status;
  final SinistreLocation location;
  final DateTime dateAccident;
  final String mode; // collaboratif
  final String? ownerConducteurUid;
  final List<SinistreVehicleRef> vehicles;
  final List<SinistreContractRef> contracts;
  final String? agencyId;
  final String? companyId;
  final List<SinistreWitness> witnesses;
  final List<SinistreAttachment> attachments;
  final List<SinistreInvite> invites;
  final String? lastUpdatedBy;
  final DateTime lastUpdatedAt;
  final SinistreIAAnalysis? iaAnalysis;
  final String? description;
  final bool isFakeData;

  const SinistreModel({
    required this.id,
    required this.createdBy,
    required this.createdAt,
    required this.status,
    required this.location,
    required this.dateAccident,
    this.mode = 'collaboratif',
    this.ownerConducteurUid,
    required this.vehicles,
    required this.contracts,
    this.agencyId,
    this.companyId,
    required this.witnesses,
    required this.attachments,
    required this.invites,
    this.lastUpdatedBy,
    required this.lastUpdatedAt,
    this.iaAnalysis,
    this.description,
    this.isFakeData = false,
  });

  factory SinistreModel.fromMap(Map<String, dynamic> map) {
    return SinistreModel(
      id: map['id'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: SinistreStatusExtension.fromString(map['status'] ?? 'draft'),
      location: SinistreLocation.fromMap(map['location'] ?? {}),
      dateAccident: (map['dateAccident'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mode: map['mode'] ?? 'collaboratif',
      ownerConducteurUid: map['ownerConducteurUid'],
      vehicles: (map['vehicles'] as List?)?.map((v) => SinistreVehicleRef.fromMap(v)).toList() ?? [],
      contracts: (map['contracts'] as List?)?.map((c) => SinistreContractRef.fromMap(c)).toList() ?? [],
      agencyId: map['agencyId'],
      companyId: map['companyId'],
      witnesses: (map['witnesses'] as List?)?.map((w) => SinistreWitness.fromMap(w)).toList() ?? [],
      attachments: (map['attachments'] as List?)?.map((a) => SinistreAttachment.fromMap(a)).toList() ?? [],
      invites: (map['invites'] as List?)?.map((i) => SinistreInvite.fromMap(i)).toList() ?? [],
      lastUpdatedBy: map['lastUpdatedBy'],
      lastUpdatedAt: (map['lastUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      iaAnalysis: map['iaAnalysis'] != null ? SinistreIAAnalysis.fromMap(map['iaAnalysis']) : null,
      description: map['description'],
      isFakeData: map['isFakeData'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.value,
      'location': location.toMap(),
      'dateAccident': Timestamp.fromDate(dateAccident),
      'mode': mode,
      'ownerConducteurUid': ownerConducteurUid,
      'vehicles': vehicles.map((v) => v.toMap()).toList(),
      'contracts': contracts.map((c) => c.toMap()).toList(),
      'agencyId': agencyId,
      'companyId': companyId,
      'witnesses': witnesses.map((w) => w.toMap()).toList(),
      'attachments': attachments.map((a) => a.toMap()).toList(),
      'invites': invites.map((i) => i.toMap()).toList(),
      'lastUpdatedBy': lastUpdatedBy,
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
      'iaAnalysis': iaAnalysis?.toMap(),
      'description': description,
      'isFakeData': isFakeData,
    };
  }

  SinistreModel copyWith({
    String? id,
    String? createdBy,
    DateTime? createdAt,
    SinistreStatus? status,
    SinistreLocation? location,
    DateTime? dateAccident,
    String? mode,
    String? ownerConducteurUid,
    List<SinistreVehicleRef>? vehicles,
    List<SinistreContractRef>? contracts,
    String? agencyId,
    String? companyId,
    List<SinistreWitness>? witnesses,
    List<SinistreAttachment>? attachments,
    List<SinistreInvite>? invites,
    String? lastUpdatedBy,
    DateTime? lastUpdatedAt,
    SinistreIAAnalysis? iaAnalysis,
    String? description,
    bool? isFakeData,
  }) {
    return SinistreModel(
      id: id ?? this.id,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      location: location ?? this.location,
      dateAccident: dateAccident ?? this.dateAccident,
      mode: mode ?? this.mode,
      ownerConducteurUid: ownerConducteurUid ?? this.ownerConducteurUid,
      vehicles: vehicles ?? this.vehicles,
      contracts: contracts ?? this.contracts,
      agencyId: agencyId ?? this.agencyId,
      companyId: companyId ?? this.companyId,
      witnesses: witnesses ?? this.witnesses,
      attachments: attachments ?? this.attachments,
      invites: invites ?? this.invites,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      iaAnalysis: iaAnalysis ?? this.iaAnalysis,
      description: description ?? this.description,
      isFakeData: isFakeData ?? this.isFakeData,
    );
  }
}
