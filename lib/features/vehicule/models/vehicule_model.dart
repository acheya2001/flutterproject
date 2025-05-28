import 'package:cloud_firestore/cloud_firestore.dart';

class VehiculeModel {
  final String? id;
  final String proprietaireId;
  final String immatriculation;
  final String marque;
  final String modele;
  final String compagnieAssurance;
  final String numeroContrat;
  final String agence;
  final DateTime? dateDebutValidite;
  final DateTime? dateFinValidite;
  final String? photoCarteGriseRecto;
  final String? photoCarteGriseVerso;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Getters pour la compatibilité avec l'ancien code
  String? get assureur => compagnieAssurance;
  DateTime? get dateDebutAssurance => dateDebutValidite;
  DateTime? get dateFinAssurance => dateFinValidite;
  
  // Propriétés supprimées mais gardées pour compatibilité (valeurs par défaut)
  int get kilometrage => 0;
  String? get numeroPolice => numeroContrat;
  String? get numeroCarteGrise => null;
  DateTime? get datePremiereCirculation => null;
  String? get type => 'Voiture';
  int? get annee => null;

  VehiculeModel({
    this.id,
    required this.proprietaireId,
    required this.immatriculation,
    required this.marque,
    required this.modele,
    required this.compagnieAssurance,
    required this.numeroContrat,
    required this.agence,
    this.dateDebutValidite,
    this.dateFinValidite,
    this.photoCarteGriseRecto,
    this.photoCarteGriseVerso,
    this.createdAt,
    this.updatedAt,
  });

  // Vérifier si l'assurance est valide
  bool get estAssuranceValide {
    if (dateFinValidite == null) return false;
    return dateFinValidite!.isAfter(DateTime.now());
  }

  // Calculer le nombre de jours restants avant expiration de l'assurance
  int get joursRestantsAssurance {
    if (dateFinValidite == null) return 0;
    final now = DateTime.now();
    if (dateFinValidite!.isBefore(now)) return 0;
    return dateFinValidite!.difference(now).inDays;
  }

  // Créer une copie du modèle avec des valeurs modifiées
  VehiculeModel copyWith({
    String? id,
    String? proprietaireId,
    String? immatriculation,
    String? marque,
    String? modele,
    String? compagnieAssurance,
    String? numeroContrat,
    String? agence,
    DateTime? dateDebutValidite,
    DateTime? dateFinValidite,
    String? photoCarteGriseRecto,
    String? photoCarteGriseVerso,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehiculeModel(
      id: id ?? this.id,
      proprietaireId: proprietaireId ?? this.proprietaireId,
      immatriculation: immatriculation ?? this.immatriculation,
      marque: marque ?? this.marque,
      modele: modele ?? this.modele,
      compagnieAssurance: compagnieAssurance ?? this.compagnieAssurance,
      numeroContrat: numeroContrat ?? this.numeroContrat,
      agence: agence ?? this.agence,
      dateDebutValidite: dateDebutValidite ?? this.dateDebutValidite,
      dateFinValidite: dateFinValidite ?? this.dateFinValidite,
      photoCarteGriseRecto: photoCarteGriseRecto ?? this.photoCarteGriseRecto,
      photoCarteGriseVerso: photoCarteGriseVerso ?? this.photoCarteGriseVerso,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convertir le modèle en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'proprietaireId': proprietaireId,
      'immatriculation': immatriculation,
      'marque': marque,
      'modele': modele,
      'compagnieAssurance': compagnieAssurance,
      'numeroContrat': numeroContrat,
      'agence': agence,
      'dateDebutValidite': dateDebutValidite,
      'dateFinValidite': dateFinValidite,
      'photoCarteGriseRecto': photoCarteGriseRecto,
      'photoCarteGriseVerso': photoCarteGriseVerso,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }

  // Créer un modèle à partir d'un document Firestore
  factory VehiculeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return VehiculeModel(
      id: doc.id,
      proprietaireId: data['proprietaireId'] ?? '',
      immatriculation: data['immatriculation'] ?? '',
      marque: data['marque'] ?? '',
      modele: data['modele'] ?? '',
      compagnieAssurance: data['compagnieAssurance'] ?? data['assureur'] ?? '',
      numeroContrat: data['numeroContrat'] ?? data['numeroPolice'] ?? '',
      agence: data['agence'] ?? '',
      dateDebutValidite: data['dateDebutValidite'] != null
          ? (data['dateDebutValidite'] is Timestamp
              ? (data['dateDebutValidite'] as Timestamp).toDate()
              : DateTime.parse(data['dateDebutValidite'].toString()))
          : data['dateDebutAssurance'] != null
              ? (data['dateDebutAssurance'] is Timestamp
                  ? (data['dateDebutAssurance'] as Timestamp).toDate()
                  : DateTime.parse(data['dateDebutAssurance'].toString()))
              : null,
      dateFinValidite: data['dateFinValidite'] != null
          ? (data['dateFinValidite'] is Timestamp
              ? (data['dateFinValidite'] as Timestamp).toDate()
              : DateTime.parse(data['dateFinValidite'].toString()))
          : data['dateFinAssurance'] != null
              ? (data['dateFinAssurance'] is Timestamp
                  ? (data['dateFinAssurance'] as Timestamp).toDate()
                  : DateTime.parse(data['dateFinAssurance'].toString()))
              : null,
      photoCarteGriseRecto: data['photoCarteGriseRecto'],
      photoCarteGriseVerso: data['photoCarteGriseVerso'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.parse(data['createdAt'].toString()))
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(data['updatedAt'].toString()))
          : null,
    );
  }

  // Créer un modèle à partir d'un Map
  factory VehiculeModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return VehiculeModel(
      id: id ?? data['id'],
      proprietaireId: data['proprietaireId'] ?? '',
      immatriculation: data['immatriculation'] ?? '',
      marque: data['marque'] ?? '',
      modele: data['modele'] ?? '',
      compagnieAssurance: data['compagnieAssurance'] ?? data['assureur'] ?? '',
      numeroContrat: data['numeroContrat'] ?? data['numeroPolice'] ?? '',
      agence: data['agence'] ?? '',
      dateDebutValidite: data['dateDebutValidite'] != null
          ? (data['dateDebutValidite'] is Timestamp
              ? (data['dateDebutValidite'] as Timestamp).toDate()
              : DateTime.parse(data['dateDebutValidite'].toString()))
          : data['dateDebutAssurance'] != null
              ? (data['dateDebutAssurance'] is Timestamp
                  ? (data['dateDebutAssurance'] as Timestamp).toDate()
                  : DateTime.parse(data['dateDebutAssurance'].toString()))
              : null,
      dateFinValidite: data['dateFinValidite'] != null
          ? (data['dateFinValidite'] is Timestamp
              ? (data['dateFinValidite'] as Timestamp).toDate()
              : DateTime.parse(data['dateFinValidite'].toString()))
          : data['dateFinAssurance'] != null
              ? (data['dateFinAssurance'] is Timestamp
                  ? (data['dateFinAssurance'] as Timestamp).toDate()
                  : DateTime.parse(data['dateFinAssurance'].toString()))
              : null,
      photoCarteGriseRecto: data['photoCarteGriseRecto'],
      photoCarteGriseVerso: data['photoCarteGriseVerso'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.parse(data['createdAt'].toString()))
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(data['updatedAt'].toString()))
          : null,
    );
  }

  @override
  String toString() {
    return 'VehiculeModel(id: $id, immatriculation: $immatriculation, marque: $marque, modele: $modele)';
  }
}
