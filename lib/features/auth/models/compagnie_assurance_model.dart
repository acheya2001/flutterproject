import 'package:cloud_firestore/cloud_firestore.dart';

/// 🏢 Modèle pour les compagnies d'assurance
class CompagnieAssuranceModel {
  final String id;
  final String nom;
  final String adresseSiege;
  final String telephone;
  final String email;
  final String? siteWeb;
  final String? logo;
  final List<String> agenceIds;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  CompagnieAssuranceModel({
    required this.id,
    required this.nom,
    required this.adresseSiege,
    required this.telephone,
    required this.email,
    this.siteWeb,
    this.logo,
    this.agenceIds = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Créer depuis Map Firestore
  factory CompagnieAssuranceModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return CompagnieAssuranceModel(
      id: id ?? map['id'] ?? '',
      nom: map['nom'] ?? '',
      adresseSiege: map['adresseSiege'] ?? '',
      telephone: map['telephone'] ?? '',
      email: map['email'] ?? '',
      siteWeb: map['siteWeb'],
      logo: map['logo'],
      agenceIds: List<String>.from(map['agenceIds'] ?? []),
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'adresseSiege': adresseSiege,
      'telephone': telephone,
      'email': email,
      'siteWeb': siteWeb,
      'logo': logo,
      'agenceIds': agenceIds,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copier avec modifications
  CompagnieAssuranceModel copyWith({
    String? id,
    String? nom,
    String? adresseSiege,
    String? telephone,
    String? email,
    String? siteWeb,
    String? logo,
    List<String>? agenceIds,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompagnieAssuranceModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      adresseSiege: adresseSiege ?? this.adresseSiege,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      siteWeb: siteWeb ?? this.siteWeb,
      logo: logo ?? this.logo,
      agenceIds: agenceIds ?? this.agenceIds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Validation des données
  List<String> validate() {
    final errors = <String>[];

    if (nom.isEmpty) {
      errors.add('Nom de la compagnie requis');
    }

    if (adresseSiege.isEmpty) {
      errors.add('Adresse du siège requise');
    }

    if (telephone.isEmpty) {
      errors.add('Téléphone requis');
    }

    if (email.isEmpty || !email.contains('@')) {
      errors.add('Email invalide');
    }

    return errors;
  }

  /// Vérifier si les données sont valides
  bool get isValid => validate().isEmpty;

  @override
  String toString() {
    return 'CompagnieAssuranceModel(id: $id, nom: $nom, agences: ${agenceIds.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CompagnieAssuranceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
