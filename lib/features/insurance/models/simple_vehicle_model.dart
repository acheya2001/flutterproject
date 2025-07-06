import 'package:cloud_firestore/cloud_firestore.dart';

/// 🚗 Modèle de véhicule simple pour les contrats d'assurance
class SimpleVehicleModel {
  final String id;
  final String marque;
  final String modele;
  final int annee;
  final String numeroImmatriculation;

  // Alias pour compatibilité
  String get immatriculation => numeroImmatriculation;
  final String numeroSerie;
  final String puissance;
  final String energie;
  final String couleur;
  final String usage;
  final String proprietaireId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SimpleVehicleModel({
    required this.id,
    required this.marque,
    required this.modele,
    required this.annee,
    required this.numeroImmatriculation,
    required this.numeroSerie,
    required this.puissance,
    required this.energie,
    required this.couleur,
    this.usage = 'Personnel',
    required this.proprietaireId,
    required this.createdAt,
    this.updatedAt,
  });

  /// Créer depuis Map
  factory SimpleVehicleModel.fromMap(Map<String, dynamic> data) {
    return SimpleVehicleModel(
      id: data['id'] ?? '',
      marque: data['marque'] ?? '',
      modele: data['modele'] ?? '',
      annee: data['annee'] ?? DateTime.now().year,
      numeroImmatriculation: data['numeroImmatriculation'] ?? '',
      numeroSerie: data['numeroSerie'] ?? '',
      puissance: data['puissance'] ?? '',
      energie: data['energie'] ?? '',
      couleur: data['couleur'] ?? '',
      usage: data['usage'] ?? 'Personnel',
      proprietaireId: data['proprietaireId'] ?? '',
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate()
          : (data['createdAt'] != null ? DateTime.parse(data['createdAt']) : DateTime.now()),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] is Timestamp 
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(data['updatedAt']))
          : null,
    );
  }

  /// Convertir vers Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'marque': marque,
      'modele': modele,
      'annee': annee,
      'numeroImmatriculation': numeroImmatriculation,
      'numeroSerie': numeroSerie,
      'puissance': puissance,
      'energie': energie,
      'couleur': couleur,
      'usage': usage,
      'proprietaireId': proprietaireId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Convertir vers Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'marque': marque,
      'modele': modele,
      'annee': annee,
      'numeroImmatriculation': numeroImmatriculation,
      'numeroSerie': numeroSerie,
      'puissance': puissance,
      'energie': energie,
      'couleur': couleur,
      'usage': usage,
      'proprietaireId': proprietaireId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Créer une copie avec des modifications
  SimpleVehicleModel copyWith({
    String? id,
    String? marque,
    String? modele,
    int? annee,
    String? numeroImmatriculation,
    String? numeroSerie,
    String? puissance,
    String? energie,
    String? couleur,
    String? usage,
    String? proprietaireId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SimpleVehicleModel(
      id: id ?? this.id,
      marque: marque ?? this.marque,
      modele: modele ?? this.modele,
      annee: annee ?? this.annee,
      numeroImmatriculation: numeroImmatriculation ?? this.numeroImmatriculation,
      numeroSerie: numeroSerie ?? this.numeroSerie,
      puissance: puissance ?? this.puissance,
      energie: energie ?? this.energie,
      couleur: couleur ?? this.couleur,
      usage: usage ?? this.usage,
      proprietaireId: proprietaireId ?? this.proprietaireId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Description complète du véhicule
  String get description => '$marque $modele ($annee)';

  /// Description avec immatriculation
  String get descriptionComplete => '$marque $modele - $numeroImmatriculation';

  @override
  String toString() {
    return 'SimpleVehicleModel(id: $id, marque: $marque, modele: $modele, immatriculation: $numeroImmatriculation)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SimpleVehicleModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
