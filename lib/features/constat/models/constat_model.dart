import 'package:cloud_firestore/cloud_firestore.dart';

enum ConstatStatus {
  brouillon,
  enCours,
  termine,
  valide,
  rejete
}

class ConstatModel {
  final String id;
  final DateTime dateAccident;
  final String lieuAccident;
  final Map<String, double>? coordonnees;
  final String adresseAccident;
  final List<String> vehiculeIds;
  final List<String> conducteurIds;
  final List<String> temoinsIds;
  final List<String> photosUrls;
  final Map<String, bool> validationStatus;
  final ConstatStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final Map<String, dynamic>? circonstances;
  final Map<String, dynamic>? dommages;
  final String? observations;
  final String? descriptionVocale;
  final String? transcriptionDescription;
  final String? videoReconstruction;
  final Map<String, dynamic>? croquis;

  ConstatModel({
    required this.id,
    required this.dateAccident,
    required this.lieuAccident,
    this.coordonnees,
    required this.adresseAccident,
    this.vehiculeIds = const [],
    this.conducteurIds = const [],
    this.temoinsIds = const [],
    this.photosUrls = const [],
    this.validationStatus = const {},
    this.status = ConstatStatus.brouillon,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.circonstances,
    this.dommages,
    this.observations,
    this.descriptionVocale,
    this.transcriptionDescription,
    this.videoReconstruction,
    this.croquis,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateAccident': dateAccident.toIso8601String(),
      'lieuAccident': lieuAccident,
      'coordonnees': coordonnees,
      'adresseAccident': adresseAccident,
      'vehiculeIds': vehiculeIds,
      'conducteurIds': conducteurIds,
      'temoinsIds': temoinsIds,
      'photosUrls': photosUrls,
      'validationStatus': validationStatus,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'circonstances': circonstances,
      'dommages': dommages,
      'observations': observations,
      'descriptionVocale': descriptionVocale,
      'transcriptionDescription': transcriptionDescription,
      'videoReconstruction': videoReconstruction,
      'croquis': croquis,
    };
  }

  factory ConstatModel.fromMap(Map<String, dynamic> map) {
    return ConstatModel(
      id: map['id'] ?? '',
      dateAccident: map['dateAccident'] != null
          ? DateTime.parse(map['dateAccident'])
          : DateTime.now(),
      lieuAccident: map['lieuAccident'] ?? '',
      coordonnees: map['coordonnees'] != null
          ? Map<String, double>.from(map['coordonnees'])
          : null,
      adresseAccident: map['adresseAccident'] ?? '',
      vehiculeIds: List<String>.from(map['vehiculeIds'] ?? []),
      conducteurIds: List<String>.from(map['conducteurIds'] ?? []),
      temoinsIds: List<String>.from(map['temoinsIds'] ?? []),
      photosUrls: List<String>.from(map['photosUrls'] ?? []),
      validationStatus: Map<String, bool>.from(map['validationStatus'] ?? {}),
      status: ConstatStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => ConstatStatus.brouillon,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
      createdBy: map['createdBy'] ?? '',
      circonstances: map['circonstances'],
      dommages: map['dommages'],
      observations: map['observations'],
      descriptionVocale: map['descriptionVocale'],
      transcriptionDescription: map['transcriptionDescription'],
      videoReconstruction: map['videoReconstruction'],
      croquis: map['croquis'],
    );
  }

  factory ConstatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConstatModel.fromMap({...data, 'id': doc.id});
  }

  ConstatModel copyWith({
    String? id,
    DateTime? dateAccident,
    String? lieuAccident,
    Map<String, double>? coordonnees,
    String? adresseAccident,
    List<String>? vehiculeIds,
    List<String>? conducteurIds,
    List<String>? temoinsIds,
    List<String>? photosUrls,
    Map<String, bool>? validationStatus,
    ConstatStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    Map<String, dynamic>? circonstances,
    Map<String, dynamic>? dommages,
    String? observations,
    String? descriptionVocale,
    String? transcriptionDescription,
    String? videoReconstruction,
    Map<String, dynamic>? croquis,
  }) {
    return ConstatModel(
      id: id ?? this.id,
      dateAccident: dateAccident ?? this.dateAccident,
      lieuAccident: lieuAccident ?? this.lieuAccident,
      coordonnees: coordonnees ?? this.coordonnees,
      adresseAccident: adresseAccident ?? this.adresseAccident,
      vehiculeIds: vehiculeIds ?? this.vehiculeIds,
      conducteurIds: conducteurIds ?? this.conducteurIds,
      temoinsIds: temoinsIds ?? this.temoinsIds,
      photosUrls: photosUrls ?? this.photosUrls,
      validationStatus: validationStatus ?? this.validationStatus,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      circonstances: circonstances ?? this.circonstances,
      dommages: dommages ?? this.dommages,
      observations: observations ?? this.observations,
      descriptionVocale: descriptionVocale ?? this.descriptionVocale,
      transcriptionDescription: transcriptionDescription ?? this.transcriptionDescription,
      videoReconstruction: videoReconstruction ?? this.videoReconstruction,
      croquis: croquis ?? this.croquis,
    );
  }
}