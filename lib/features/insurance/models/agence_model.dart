import 'package:cloud_firestore/cloud_firestore.dart';

/// 👨‍💼 Modèle pour le directeur d'agence
class DirecteurAgence {
  final String nom;
  final String prenom;
  final String telephone;

  const DirecteurAgence({
    required this.nom,
    required this.prenom,
    required this.telephone,
  });

  factory DirecteurAgence.fromMap(Map<String, dynamic> map) {
    return DirecteurAgence(
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      telephone: map['telephone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
    };
  }
}

/// 🏪 Modèle pour une agence d'assurance
class AgenceModel {
  final String id;
  final String compagnieId;
  final String nom;
  final String codeAgence;
  final String adresse;
  final String telephone;
  final String email;
  final DirecteurAgence directeur;
  final List<String> agents;
  final List<String> zoneGeographique;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AgenceModel({
    required this.id,
    required this.compagnieId,
    required this.nom,
    required this.codeAgence,
    required this.adresse,
    required this.telephone,
    required this.email,
    required this.directeur,
    required this.agents,
    required this.zoneGeographique,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Créer depuis Firestore
  factory AgenceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AgenceModel(
      id: doc.id,
      compagnieId: data['compagnie_id'] ?? '',
      nom: data['nom'] ?? '',
      codeAgence: data['code_agence'] ?? '',
      adresse: data['adresse'] ?? '',
      telephone: data['telephone'] ?? '',
      email: data['email'] ?? '',
      directeur: DirecteurAgence.fromMap(data['directeur'] ?? {}),
      agents: List<String>.from(data['agents'] ?? []),
      zoneGeographique: List<String>.from(data['zone_geographique'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'compagnie_id': compagnieId,
      'nom': nom,
      'code_agence': codeAgence,
      'adresse': adresse,
      'telephone': telephone,
      'email': email,
      'directeur': directeur.toMap(),
      'agents': agents,
      'zone_geographique': zoneGeographique,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copier avec modifications
  AgenceModel copyWith({
    String? id,
    String? compagnieId,
    String? nom,
    String? codeAgence,
    String? adresse,
    String? telephone,
    String? email,
    DirecteurAgence? directeur,
    List<String>? agents,
    List<String>? zoneGeographique,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AgenceModel(
      id: id ?? this.id,
      compagnieId: compagnieId ?? this.compagnieId,
      nom: nom ?? this.nom,
      codeAgence: codeAgence ?? this.codeAgence,
      adresse: adresse ?? this.adresse,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      directeur: directeur ?? this.directeur,
      agents: agents ?? this.agents,
      zoneGeographique: zoneGeographique ?? this.zoneGeographique,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AgenceModel(id: $id, nom: $nom, compagnie: $compagnieId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgenceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
