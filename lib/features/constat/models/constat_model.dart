import 'package:cloud_firestore/cloud_firestore.dart';

enum ConstatStatus { 
  draft, 
  pending_validation, 
  en_cours_de_validation, 
  valide, 
  validated, // Added as per constat_service.dart
  submitted, // Added as per constat_service.dart
  refuse, 
  completed, 
  archived 
}

class ConstatModel {
  final String id;
  final DateTime dateAccident;
  final String lieuAccident;
  final GeoPoint? coordonnees;
  final String? adresseAccident;
  final List<String> vehiculeIds;
  final List<String> conducteurIds;
  final List<String> temoinsIds;
  List<String> photosUrls;
  final Map<String, bool> validationStatus;
  final ConstatStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final Map<String, dynamic>? circonstances;
  final Map<String, dynamic>? dommages;
  final Map<String, dynamic>? observations;
  final String? descriptionVocale;
  final String? transcriptionDescription;
  final String? videoReconstruction;
  final String? croquis;

  ConstatModel({
    required this.id,
    required this.dateAccident,
    required this.lieuAccident,
    this.coordonnees,
    this.adresseAccident,
    this.vehiculeIds = const [],
    this.conducteurIds = const [],
    this.temoinsIds = const [],
    this.photosUrls = const [],
    this.validationStatus = const {},
    required this.status,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateAccident': Timestamp.fromDate(dateAccident),
      'lieuAccident': lieuAccident,
      'coordonnees': coordonnees,
      'adresseAccident': adresseAccident,
      'vehiculeIds': vehiculeIds,
      'conducteurIds': conducteurIds,
      'temoinsIds': temoinsIds,
      'photosUrls': photosUrls,
      'validationStatus': validationStatus,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
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

  factory ConstatModel.fromJson(Map<String, dynamic> json) {
    return ConstatModel(
      id: json['id'] ?? '',
      dateAccident: (json['dateAccident'] as Timestamp).toDate(),
      lieuAccident: json['lieuAccident'] ?? '',
      coordonnees: json['coordonnees'] as GeoPoint?,
      adresseAccident: json['adresseAccident'] as String?,
      vehiculeIds: List<String>.from(json['vehiculeIds'] ?? []),
      conducteurIds: List<String>.from(json['conducteurIds'] ?? []),
      temoinsIds: List<String>.from(json['temoinsIds'] ?? []),
      photosUrls: List<String>.from(json['photosUrls'] ?? []),
      validationStatus: Map<String, bool>.from(json['validationStatus'] ?? {}),
      status: ConstatStatus.values.firstWhere(
            (e) => e.toString().split('.').last == json['status'],
        orElse: () => ConstatStatus.draft,
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      createdBy: json['createdBy'] ?? '',
      circonstances: json['circonstances'] as Map<String, dynamic>?,
      dommages: json['dommages'] as Map<String, dynamic>?,
      observations: json['observations'] as Map<String, dynamic>?,
      descriptionVocale: json['descriptionVocale'] as String?,
      transcriptionDescription: json['transcriptionDescription'] as String?,
      videoReconstruction: json['videoReconstruction'] as String?,
      croquis: json['croquis'] as String?,
    );
  }
  
  factory ConstatModel.fromMap(Map<String, dynamic> map) {
    return ConstatModel.fromJson(map); 
  }

  ConstatModel copyWith({
    String? id,
    DateTime? dateAccident,
    String? lieuAccident,
    GeoPoint? coordonnees,
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
    Map<String, dynamic>? observations,
    String? descriptionVocale,
    String? transcriptionDescription,
    String? videoReconstruction,
    String? croquis,
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
