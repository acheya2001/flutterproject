import 'package:cloud_firestore/cloud_firestore.dart';

/// 🚗 Modèle simple pour un véhicule
class VehiculeModel {
  final String id;
  final String conducteurId;
  final String marque;
  final String modele;
  final String numeroImmatriculation;
  final String? numeroSerie;
  final int? annee;
  final String? couleur;
  final String? typeCarburant;
  final String? numeroMoteur;
  final String? numeroChassiss;
  
  // Informations d'assurance
  final String? compagnieAssurance;
  final String? numeroPolice;
  final String? agenceId;
  final String? agenceNom;
  final String? compagnieId;
  final DateTime? dateDebutAssurance;
  final DateTime? dateFinAssurance;
  final DateTime? dateDebutContrat;
  final DateTime? dateFinContrat;
  
  // État du contrat
  bool contratActif = false; // Sera calculé dynamiquement
  
  final DateTime createdAt;
  final DateTime updatedAt;

  VehiculeModel({
    required this.id,
    required this.conducteurId,
    required this.marque,
    required this.modele,
    required this.numeroImmatriculation,
    this.numeroSerie,
    this.annee,
    this.couleur,
    this.typeCarburant,
    this.numeroMoteur,
    this.numeroChassiss,
    this.compagnieAssurance,
    this.numeroPolice,
    this.agenceId,
    this.agenceNom,
    this.compagnieId,
    this.dateDebutAssurance,
    this.dateFinAssurance,
    this.dateDebutContrat,
    this.dateFinContrat,
    this.contratActif = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VehiculeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return VehiculeModel(
      id: doc.id,
      conducteurId: data['conducteurId'] ?? '',
      marque: data['marque'] ?? '',
      modele: data['modele'] ?? '',
      numeroImmatriculation: data['numeroImmatriculation'] ?? '',
      numeroSerie: data['numeroSerie'],
      annee: data['annee']?.toInt(),
      couleur: data['couleur'],
      typeCarburant: data['typeCarburant'],
      numeroMoteur: data['numeroMoteur'],
      numeroChassiss: data['numeroChassiss'],
      compagnieAssurance: data['compagnieAssurance'],
      numeroPolice: data['numeroPolice'],
      agenceId: data['agenceId'],
      dateDebutAssurance: data['dateDebutAssurance'] != null 
          ? (data['dateDebutAssurance'] as Timestamp).toDate() 
          : null,
      dateFinAssurance: data['dateFinAssurance'] != null 
          ? (data['dateFinAssurance'] as Timestamp).toDate() 
          : null,
      contratActif: data['contratActif'] ?? false,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'conducteurId': conducteurId,
      'marque': marque,
      'modele': modele,
      'numeroImmatriculation': numeroImmatriculation,
      'numeroSerie': numeroSerie,
      'annee': annee,
      'couleur': couleur,
      'typeCarburant': typeCarburant,
      'numeroMoteur': numeroMoteur,
      'numeroChassiss': numeroChassiss,
      'compagnieAssurance': compagnieAssurance,
      'numeroPolice': numeroPolice,
      'agenceId': agenceId,
      'dateDebutAssurance': dateDebutAssurance != null 
          ? Timestamp.fromDate(dateDebutAssurance!) 
          : null,
      'dateFinAssurance': dateFinAssurance != null 
          ? Timestamp.fromDate(dateFinAssurance!) 
          : null,
      'contratActif': contratActif,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Nom complet du véhicule
  String get nomComplet => '$marque $modele';

  /// Vérifie si l'assurance est valide
  bool get assuranceValide {
    if (dateFinAssurance == null) return false;
    return DateTime.now().isBefore(dateFinAssurance!);
  }

  VehiculeModel copyWith({
    String? id,
    String? conducteurId,
    String? marque,
    String? modele,
    String? numeroImmatriculation,
    String? numeroSerie,
    int? annee,
    String? couleur,
    String? typeCarburant,
    String? numeroMoteur,
    String? numeroChassiss,
    String? compagnieAssurance,
    String? numeroPolice,
    String? agenceId,
    DateTime? dateDebutAssurance,
    DateTime? dateFinAssurance,
    bool? contratActif,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehiculeModel(
      id: id ?? this.id,
      conducteurId: conducteurId ?? this.conducteurId,
      marque: marque ?? this.marque,
      modele: modele ?? this.modele,
      numeroImmatriculation: numeroImmatriculation ?? this.numeroImmatriculation,
      numeroSerie: numeroSerie ?? this.numeroSerie,
      annee: annee ?? this.annee,
      couleur: couleur ?? this.couleur,
      typeCarburant: typeCarburant ?? this.typeCarburant,
      numeroMoteur: numeroMoteur ?? this.numeroMoteur,
      numeroChassiss: numeroChassiss ?? this.numeroChassiss,
      compagnieAssurance: compagnieAssurance ?? this.compagnieAssurance,
      numeroPolice: numeroPolice ?? this.numeroPolice,
      agenceId: agenceId ?? this.agenceId,
      dateDebutAssurance: dateDebutAssurance ?? this.dateDebutAssurance,
      dateFinAssurance: dateFinAssurance ?? this.dateFinAssurance,
      contratActif: contratActif ?? this.contratActif,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
