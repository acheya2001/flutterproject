import 'package:cloud_firestore/cloud_firestore.dart';

/// 🏢 Modèle pour une compagnie d'assurance
class CompagnieAssuranceModel {
  final String id;
  final String nom;
  final String siret;
  final String adresseSiege;
  final String telephone;
  final String email;
  final String? logoUrl;
  final List<String> agences;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CompagnieAssuranceModel({
    required this.id,
    required this.nom,
    required this.siret,
    required this.adresseSiege,
    required this.telephone,
    required this.email,
    this.logoUrl,
    required this.agences,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Créer depuis Firestore
  factory CompagnieAssuranceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CompagnieAssuranceModel(
      id: doc.id,
      nom: data['nom'] ?? '',
      siret: data['siret'] ?? '',
      adresseSiege: data['adresse_siege'] ?? '',
      telephone: data['telephone'] ?? '',
      email: data['email'] ?? '',
      logoUrl: data['logo_url'],
      agences: List<String>.from(data['agences'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'siret': siret,
      'adresse_siege': adresseSiege,
      'telephone': telephone,
      'email': email,
      'logo_url': logoUrl,
      'agences': agences,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copier avec modifications
  CompagnieAssuranceModel copyWith({
    String? id,
    String? nom,
    String? siret,
    String? adresseSiege,
    String? telephone,
    String? email,
    String? logoUrl,
    List<String>? agences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompagnieAssuranceModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      siret: siret ?? this.siret,
      adresseSiege: adresseSiege ?? this.adresseSiege,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      logoUrl: logoUrl ?? this.logoUrl,
      agences: agences ?? this.agences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CompagnieAssuranceModel(id: $id, nom: $nom, siret: $siret)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CompagnieAssuranceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
