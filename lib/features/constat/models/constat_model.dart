import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/constants.dart';
import '../../vehicule/models/vehicule_model.dart';

enum ConstatStatus {
  draft,        // Brouillon
  pending,      // En attente de validation par les autres parties
  validated,    // Validé par toutes les parties
  submitted,    // Soumis à l'assurance
  processing,   // En cours de traitement
  completed,    // Traité
  rejected,     // Rejeté
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
  final List<String> photosUrls;
  final String? croquis;
  final String? videoReconstruction;
  final String? descriptionVocale;
  final String? transcriptionDescription;
  final Map<String, bool> validationStatus;
  final ConstatStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final Map<String, dynamic>? circonstances;
  final Map<String, dynamic>? dommages;
  final Map<String, dynamic>? observations;

  ConstatModel({
    required this.id,
    required this.dateAccident,
    required this.lieuAccident,
    this.coordonnees,
    this.adresseAccident,
    required this.vehiculeIds,
    required this.conducteurIds,
    this.temoinsIds = const [],
    this.photosUrls = const [],
    this.croquis,
    this.videoReconstruction,
    this.descriptionVocale,
    this.transcriptionDescription,
    required this.validationStatus,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.circonstances,
    this.dommages,
    this.observations,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateAccident': dateAccident,
      'lieuAccident': lieuAccident,
      'coordonnees': coordonnees,
      'adresseAccident': adresseAccident,
      'vehiculeIds': vehiculeIds,
      'conducteurIds': conducteurIds,
      'temoinsIds': temoinsIds,
      'photosUrls': photosUrls,
      'croquis': croquis,
      'videoReconstruction': videoReconstruction,
      'descriptionVocale': descriptionVocale,
      'transcriptionDescription': transcriptionDescription,
      'validationStatus': validationStatus,
      'status': status.toString().split('.').last,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'circonstances': circonstances,
      'dommages': dommages,
      'observations': observations,
    };
  }

  static ConstatModel fromMap(Map<String, dynamic> map) {
    try {
      return ConstatModel(
        id: map['id'] as String? ?? '',
        dateAccident: (map['dateAccident'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lieuAccident: map['lieuAccident'] as String? ?? '',
        coordonnees: map['coordonnees'] as GeoPoint?,
        adresseAccident: map['adresseAccident'] as String?,
        vehiculeIds: List<String>.from(map['vehiculeIds'] ?? []),
        conducteurIds: List<String>.from(map['conducteurIds'] ?? []),
        temoinsIds: List<String>.from(map['temoinsIds'] ?? []),
        photosUrls: List<String>.from(map['photosUrls'] ?? []),
        croquis: map['croquis'] as String?,
        videoReconstruction: map['videoReconstruction'] as String?,
        descriptionVocale: map['descriptionVocale'] as String?,
        transcriptionDescription: map['transcriptionDescription'] as String?,
        validationStatus: Map<String, bool>.from(map['validationStatus'] ?? {}),
        status: ConstatStatus.values.firstWhere(
          (e) => e.toString().split('.').last == (map['status'] as String? ?? 'draft'),
          orElse: () => ConstatStatus.draft,
        ),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        createdBy: map['createdBy'] as String? ?? '',
        circonstances: map['circonstances'] as Map<String, dynamic>?,
        dommages: map['dommages'] as Map<String, dynamic>?,
        observations: map['observations'] as Map<String, dynamic>?,
      );
    } catch (e) {
      debugPrint('Erreur lors de la conversion de ConstatModel: $e');
      return ConstatModel(
        id: '',
        dateAccident: DateTime.now(),
        lieuAccident: '',
        vehiculeIds: [],
        conducteurIds: [],
        validationStatus: {},
        status: ConstatStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: '',
      );
    }
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
    String? croquis,
    String? videoReconstruction,
    String? descriptionVocale,
    String? transcriptionDescription,
    Map<String, bool>? validationStatus,
    ConstatStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    Map<String, dynamic>? circonstances,
    Map<String, dynamic>? dommages,
    Map<String, dynamic>? observations,
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
      croquis: croquis ?? this.croquis,
      videoReconstruction: videoReconstruction ?? this.videoReconstruction,
      descriptionVocale: descriptionVocale ?? this.descriptionVocale,
      transcriptionDescription: transcriptionDescription ?? this.transcriptionDescription,
      validationStatus: validationStatus ?? this.validationStatus,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      circonstances: circonstances ?? this.circonstances,
      dommages: dommages ?? this.dommages,
      observations: observations ?? this.observations,
    );
  }

  @override
  String toString() {
    return 'ConstatModel{id: $id, dateAccident: $dateAccident, lieuAccident: $lieuAccident, status: $status}';
  }
}
