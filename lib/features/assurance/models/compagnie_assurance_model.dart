import 'package:cloud_firestore/cloud_firestore.dart';

/// 🏢 Modèle pour une compagnie d'assurance
class CompagnieAssuranceModel {
  final String id;
  final String nom;
  final String logo;
  final String adresseSiege;
  final String telephone;
  final String email;
  final String siteWeb;
  final String numeroRegistre;
  final DateTime dateCreation;
  final bool isActive;
  final Map<String, dynamic> configuration;
  final List<String> gouvernoratsCouverts;

  const CompagnieAssuranceModel({
    required this.id,
    required this.nom,
    required this.logo,
    required this.adresseSiege,
    required this.telephone,
    required this.email,
    required this.siteWeb,
    required this.numeroRegistre,
    required this.dateCreation,
    this.isActive = true,
    this.configuration = const {},
    this.gouvernoratsCouverts = const [],
  });

  /// Créer depuis Firestore
  factory CompagnieAssuranceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return CompagnieAssuranceModel(
      id: doc.id,
      nom: data['nom'] ?? '',
      logo: data['logo'] ?? '',
      adresseSiege: data['adresseSiege'] ?? '',
      telephone: data['telephone'] ?? '',
      email: data['email'] ?? '',
      siteWeb: data['siteWeb'] ?? '',
      numeroRegistre: data['numeroRegistre'] ?? '',
      dateCreation: (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      configuration: Map<String, dynamic>.from(data['configuration'] ?? {}),
      gouvernoratsCouverts: List<String>.from(data['gouvernoratsCouverts'] ?? []),
    );
  }

  /// Convertir vers Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'logo': logo,
      'adresseSiege': adresseSiege,
      'telephone': telephone,
      'email': email,
      'siteWeb': siteWeb,
      'numeroRegistre': numeroRegistre,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'isActive': isActive,
      'configuration': configuration,
      'gouvernoratsCouverts': gouvernoratsCouverts,
    };
  }

  /// Copier avec modifications
  CompagnieAssuranceModel copyWith({
    String? id,
    String? nom,
    String? logo,
    String? adresseSiege,
    String? telephone,
    String? email,
    String? siteWeb,
    String? numeroRegistre,
    DateTime? dateCreation,
    bool? isActive,
    Map<String, dynamic>? configuration,
    List<String>? gouvernoratsCouverts,
  }) {
    return CompagnieAssuranceModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      logo: logo ?? this.logo,
      adresseSiege: adresseSiege ?? this.adresseSiege,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      siteWeb: siteWeb ?? this.siteWeb,
      numeroRegistre: numeroRegistre ?? this.numeroRegistre,
      dateCreation: dateCreation ?? this.dateCreation,
      isActive: isActive ?? this.isActive,
      configuration: configuration ?? this.configuration,
      gouvernoratsCouverts: gouvernoratsCouverts ?? this.gouvernoratsCouverts,
    );
  }

  @override
  String toString() {
    return 'CompagnieAssuranceModel(id: $id, nom: $nom, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CompagnieAssuranceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 🏢 Compagnies d'assurance prédéfinies en Tunisie
class CompagniesAssuranceTunisie {
  static const List<Map<String, dynamic>> compagnies = [
    {
      'nom': 'STAR Assurances',
      'logo': 'assets/logos/star.png',
      'couleur': '#FF6B35',
      'gouvernorats': ['Tunis', 'Ariana', 'Ben Arous', 'Manouba'],
    },
    {
      'nom': 'Maghrebia Assurances',
      'logo': 'assets/logos/maghrebia.png',
      'couleur': '#2E8B57',
      'gouvernorats': ['Sfax', 'Mahdia', 'Monastir', 'Sousse'],
    },
    {
      'nom': 'Assurances Salim',
      'logo': 'assets/logos/salim.png',
      'couleur': '#4169E1',
      'gouvernorats': ['Bizerte', 'Nabeul', 'Zaghouan'],
    },
    {
      'nom': 'GAT Assurances',
      'logo': 'assets/logos/gat.png',
      'couleur': '#DC143C',
      'gouvernorats': ['Kairouan', 'Kasserine', 'Sidi Bouzid'],
    },
    {
      'nom': 'Comar Assurances',
      'logo': 'assets/logos/comar.png',
      'couleur': '#FF8C00',
      'gouvernorats': ['Gafsa', 'Tozeur', 'Kebili'],
    },
    {
      'nom': 'Lloyd Tunisien',
      'logo': 'assets/logos/lloyd.png',
      'couleur': '#9932CC',
      'gouvernorats': ['Gabès', 'Medenine', 'Tataouine'],
    },
    {
      'nom': 'Zitouna Takaful',
      'logo': 'assets/logos/zitouna.png',
      'couleur': '#228B22',
      'gouvernorats': ['Jendouba', 'Kef', 'Siliana'],
    },
    {
      'nom': 'Attijari Assurance',
      'logo': 'assets/logos/attijari.png',
      'couleur': '#B22222',
      'gouvernorats': ['Beja', 'Tunis', 'Ariana'],
    },
  ];
}
