import 'package:cloud_firestore/cloud_firestore.dart';

/// 🏢 Modèle pour une compagnie d'assurance
class CompagnieModel {
  final String id;
  final String nom;
  final String logo; // URL du logo
  final String adresseSiege;
  final String telephone;
  final String email;
  final String siteWeb;
  final String numeroAgrement; // Numéro d'agrément officiel
  final List<String> typesAssurance; // Auto, Habitation, Santé, etc.
  final bool active;
  final DateTime dateCreation;
  final DateTime? dateModification;
  final Map<String, dynamic> statistiques; // Nombre d'agences, clients, etc.

  CompagnieModel({
    required this.id,
    required this.nom,
    required this.logo,
    required this.adresseSiege,
    required this.telephone,
    required this.email,
    required this.siteWeb,
    required this.numeroAgrement,
    required this.typesAssurance,
    this.active = true,
    required this.dateCreation,
    this.dateModification,
    this.statistiques = const {},
  });

  /// Créer depuis Firestore
  factory CompagnieModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CompagnieModel(
      id: doc.id,
      nom: data['nom'] ?? '',
      logo: data['logo'] ?? '',
      adresseSiege: data['adresse_siege'] ?? '',
      telephone: data['telephone'] ?? '',
      email: data['email'] ?? '',
      siteWeb: data['site_web'] ?? '',
      numeroAgrement: data['numero_agrement'] ?? '',
      typesAssurance: List<String>.from(data['types_assurance'] ?? []),
      active: data['active'] ?? true,
      dateCreation: (data['date_creation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateModification: (data['date_modification'] as Timestamp?)?.toDate(),
      statistiques: Map<String, dynamic>.from(data['statistiques'] ?? {}),
    );
  }

  /// Convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'logo': logo,
      'adresse_siege': adresseSiege,
      'telephone': telephone,
      'email': email,
      'site_web': siteWeb,
      'numero_agrement': numeroAgrement,
      'types_assurance': typesAssurance,
      'active': active,
      'date_creation': Timestamp.fromDate(dateCreation),
      'date_modification': dateModification != null ? Timestamp.fromDate(dateModification!) : null,
      'statistiques': statistiques,
    };
  }

  /// Copier avec modifications
  CompagnieModel copyWith({
    String? id,
    String? nom,
    String? logo,
    String? adresseSiege,
    String? telephone,
    String? email,
    String? siteWeb,
    String? numeroAgrement,
    List<String>? typesAssurance,
    bool? active,
    DateTime? dateCreation,
    DateTime? dateModification,
    Map<String, dynamic>? statistiques,
  }) {
    return CompagnieModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      logo: logo ?? this.logo,
      adresseSiege: adresseSiege ?? this.adresseSiege,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      siteWeb: siteWeb ?? this.siteWeb,
      numeroAgrement: numeroAgrement ?? this.numeroAgrement,
      typesAssurance: typesAssurance ?? this.typesAssurance,
      active: active ?? this.active,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
      statistiques: statistiques ?? this.statistiques,
    );
  }

  @override
  String toString() {
    return 'CompagnieModel(id: $id, nom: $nom, active: $active)';
  }
}

/// 🏪 Modèle pour une agence d'assurance
class AgenceModel {
  final String id;
  final String compagnieId;
  final String nom;
  final String adresse;
  final String ville;
  final String codePostal;
  final String gouvernorat;
  final String telephone;
  final String email;
  final String? responsable; // Nom du responsable
  final bool active;
  final DateTime dateCreation;
  final DateTime? dateModification;
  final Map<String, dynamic> statistiques; // Nombre d'agents, clients, etc.

  AgenceModel({
    required this.id,
    required this.compagnieId,
    required this.nom,
    required this.adresse,
    required this.ville,
    required this.codePostal,
    required this.gouvernorat,
    required this.telephone,
    required this.email,
    this.responsable,
    this.active = true,
    required this.dateCreation,
    this.dateModification,
    this.statistiques = const {},
  });

  /// Créer depuis Firestore
  factory AgenceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AgenceModel(
      id: doc.id,
      compagnieId: data['compagnie_id'] ?? '',
      nom: data['nom'] ?? '',
      adresse: data['adresse'] ?? '',
      ville: data['ville'] ?? '',
      codePostal: data['code_postal'] ?? '',
      gouvernorat: data['gouvernorat'] ?? '',
      telephone: data['telephone'] ?? '',
      email: data['email'] ?? '',
      responsable: data['responsable'],
      active: data['active'] ?? true,
      dateCreation: (data['date_creation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateModification: (data['date_modification'] as Timestamp?)?.toDate(),
      statistiques: Map<String, dynamic>.from(data['statistiques'] ?? {}),
    );
  }

  /// Convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'compagnie_id': compagnieId,
      'nom': nom,
      'adresse': adresse,
      'ville': ville,
      'code_postal': codePostal,
      'gouvernorat': gouvernorat,
      'telephone': telephone,
      'email': email,
      'responsable': responsable,
      'active': active,
      'date_creation': Timestamp.fromDate(dateCreation),
      'date_modification': dateModification != null ? Timestamp.fromDate(dateModification!) : null,
      'statistiques': statistiques,
    };
  }

  /// Copier avec modifications
  AgenceModel copyWith({
    String? id,
    String? compagnieId,
    String? nom,
    String? adresse,
    String? ville,
    String? codePostal,
    String? gouvernorat,
    String? telephone,
    String? email,
    String? responsable,
    bool? active,
    DateTime? dateCreation,
    DateTime? dateModification,
    Map<String, dynamic>? statistiques,
  }) {
    return AgenceModel(
      id: id ?? this.id,
      compagnieId: compagnieId ?? this.compagnieId,
      nom: nom ?? this.nom,
      adresse: adresse ?? this.adresse,
      ville: ville ?? this.ville,
      codePostal: codePostal ?? this.codePostal,
      gouvernorat: gouvernorat ?? this.gouvernorat,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      responsable: responsable ?? this.responsable,
      active: active ?? this.active,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
      statistiques: statistiques ?? this.statistiques,
    );
  }

  @override
  String toString() {
    return 'AgenceModel(id: $id, nom: $nom, ville: $ville)';
  }
}
