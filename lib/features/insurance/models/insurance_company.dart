import 'package:cloud_firestore/cloud_firestore.dart';

/// 🏢 Modèle pour une compagnie d'assurance
class InsuranceCompany {
  final String id;
  final String nom;
  final String logo;
  final String adresse;
  final String telephone;
  final String email;
  final String siteWeb;
  final String numeroAgrement;
  final DateTime dateCreation;
  final bool isActive;
  final Map<String, dynamic> statistiques;
  final List<String> gouvernoratsCouverts;

  const InsuranceCompany({
    required this.id,
    required this.nom,
    required this.logo,
    required this.adresse,
    required this.telephone,
    required this.email,
    required this.siteWeb,
    required this.numeroAgrement,
    required this.dateCreation,
    required this.isActive,
    required this.statistiques,
    required this.gouvernoratsCouverts,
  });

  /// Créer depuis Firestore
  factory InsuranceCompany.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InsuranceCompany(
      id: doc.id,
      nom: data['nom'] ?? '',
      logo: data['logo'] ?? '',
      adresse: data['adresse'] ?? '',
      telephone: data['telephone'] ?? '',
      email: data['email'] ?? '',
      siteWeb: data['siteWeb'] ?? '',
      numeroAgrement: data['numeroAgrement'] ?? '',
      dateCreation: (data['dateCreation'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      statistiques: Map<String, dynamic>.from(data['statistiques'] ?? {}),
      gouvernoratsCouverts: List<String>.from(data['gouvernoratsCouverts'] ?? []),
    );
  }

  /// Convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'logo': logo,
      'adresse': adresse,
      'telephone': telephone,
      'email': email,
      'siteWeb': siteWeb,
      'numeroAgrement': numeroAgrement,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'isActive': isActive,
      'statistiques': statistiques,
      'gouvernoratsCouverts': gouvernoratsCouverts,
    };
  }

  /// Copier avec modifications
  InsuranceCompany copyWith({
    String? id,
    String? nom,
    String? logo,
    String? adresse,
    String? telephone,
    String? email,
    String? siteWeb,
    String? numeroAgrement,
    DateTime? dateCreation,
    bool? isActive,
    Map<String, dynamic>? statistiques,
    List<String>? gouvernoratsCouverts,
  }) {
    return InsuranceCompany(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      logo: logo ?? this.logo,
      adresse: adresse ?? this.adresse,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      siteWeb: siteWeb ?? this.siteWeb,
      numeroAgrement: numeroAgrement ?? this.numeroAgrement,
      dateCreation: dateCreation ?? this.dateCreation,
      isActive: isActive ?? this.isActive,
      statistiques: statistiques ?? this.statistiques,
      gouvernoratsCouverts: gouvernoratsCouverts ?? this.gouvernoratsCouverts,
    );
  }
}

/// 🏪 Modèle pour une agence d'assurance
class InsuranceAgency {
  final String id;
  final String compagnieId;
  final String nom;
  final String adresse;
  final String gouvernorat;
  final String ville;
  final String telephone;
  final String email;
  final String responsable;
  final DateTime dateOuverture;
  final bool isActive;
  final Map<String, dynamic> statistiques;

  const InsuranceAgency({
    required this.id,
    required this.compagnieId,
    required this.nom,
    required this.adresse,
    required this.gouvernorat,
    required this.ville,
    required this.telephone,
    required this.email,
    required this.responsable,
    required this.dateOuverture,
    required this.isActive,
    required this.statistiques,
  });

  /// Créer depuis Firestore
  factory InsuranceAgency.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InsuranceAgency(
      id: doc.id,
      compagnieId: data['compagnieId'] ?? '',
      nom: data['nom'] ?? '',
      adresse: data['adresse'] ?? '',
      gouvernorat: data['gouvernorat'] ?? '',
      ville: data['ville'] ?? '',
      telephone: data['telephone'] ?? '',
      email: data['email'] ?? '',
      responsable: data['responsable'] ?? '',
      dateOuverture: (data['dateOuverture'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      statistiques: Map<String, dynamic>.from(data['statistiques'] ?? {}),
    );
  }

  /// Convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'compagnieId': compagnieId,
      'nom': nom,
      'adresse': adresse,
      'gouvernorat': gouvernorat,
      'ville': ville,
      'telephone': telephone,
      'email': email,
      'responsable': responsable,
      'dateOuverture': Timestamp.fromDate(dateOuverture),
      'isActive': isActive,
      'statistiques': statistiques,
    };
  }
}
