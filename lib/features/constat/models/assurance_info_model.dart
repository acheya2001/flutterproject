import 'package:cloud_firestore/cloud_firestore.dart';

class AssuranceInfoModel {
  final String? id;
  final String societeAssurance;
  final String numeroContrat;
  final String agence;
  final String? agenceId; // Lien avec la collection agences
  final DateTime? dateDebutValidite;
  final DateTime? dateFinValidite;
  final bool? assuranceValide;
  final String? photoAttestationUrl;
  final String conducteurId; // Lien avec ConducteurInfoModel
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  AssuranceInfoModel({
    this.id,
    required this.societeAssurance,
    required this.numeroContrat,
    required this.agence,
    this.agenceId,
    this.dateDebutValidite,
    this.dateFinValidite,
    this.assuranceValide,
    this.photoAttestationUrl,
    required this.conducteurId,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'societeAssurance': societeAssurance,
      'numeroContrat': numeroContrat,
      'agence': agence,
      'agenceId': agenceId,
      'dateDebutValidite': dateDebutValidite,
      'dateFinValidite': dateFinValidite,
      'assuranceValide': assuranceValide,
      'photoAttestationUrl': photoAttestationUrl,
      'conducteurId': conducteurId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static AssuranceInfoModel fromMap(Map<String, dynamic> map) {
    return AssuranceInfoModel(
      id: map['id'],
      societeAssurance: map['societeAssurance'] ?? '',
      numeroContrat: map['numeroContrat'] ?? '',
      agence: map['agence'] ?? '',
      agenceId: map['agenceId'],
      dateDebutValidite: map['dateDebutValidite'] != null 
          ? (map['dateDebutValidite'] as Timestamp).toDate() : null,
      dateFinValidite: map['dateFinValidite'] != null 
          ? (map['dateFinValidite'] as Timestamp).toDate() : null,
      assuranceValide: map['assuranceValide'],
      photoAttestationUrl: map['photoAttestationUrl'],
      conducteurId: map['conducteurId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }
}
