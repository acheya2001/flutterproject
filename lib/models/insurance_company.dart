import 'package:cloud_firestore/cloud_firestore.dart';

/// 🏢 Modèle de données pour les compagnies d'assurance
class InsuranceCompany {
  final String id;
  final String nom;
  final String? code; // Code unique de la compagnie (ex: STA, COM, MAG)
  final String adresse;
  final String telephone;
  final String email;
  final String? siteWeb;
  final String? logoUrl;
  final String status; // 'active' ou 'inactive'
  final String type; // 'Classique' ou 'Takaful'
  final DateTime createdAt;
  final String? adminCompagnieId;
  final String? adminCompagnieEmail;
  final String? adminCompagnieNom;
  final bool? hasAdmin; // Indique si la compagnie a déjà un admin

  InsuranceCompany({
    required this.id,
    required this.nom,
    this.code,
    required this.adresse,
    required this.telephone,
    required this.email,
    this.siteWeb,
    this.logoUrl,
    this.status = 'active',
    this.type = 'Classique',
    required this.createdAt,
    this.adminCompagnieId,
    this.adminCompagnieEmail,
    this.adminCompagnieNom,
    this.hasAdmin,
  });

  /// Constructeur simplifié pour la sélection d'admin
  InsuranceCompany.forSelection({
    required this.id,
    required this.nom,
    this.code,
    required this.type,
    this.hasAdmin,
  }) : adresse = '',
       telephone = '',
       email = '',
       siteWeb = null,
       logoUrl = null,
       status = 'active',
       createdAt = DateTime.now(),
       adminCompagnieId = null,
       adminCompagnieEmail = null,
       adminCompagnieNom = null;

  /// Créer depuis Firestore
  factory InsuranceCompany.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InsuranceCompany(
      id: doc.id,
      nom: data['nom'] ?? '',
      code: data['code'],
      adresse: data['adresse'] ?? '',
      telephone: data['telephone'] ?? '',
      email: data['email'] ?? '',
      siteWeb: data['siteWeb'],
      logoUrl: data['logoUrl'],
      status: data['status'] ?? 'active',
      type: data['type'] ?? 'Classique',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminCompagnieId: data['adminCompagnieId'],
      adminCompagnieEmail: data['adminCompagnieEmail'],
      adminCompagnieNom: data['adminCompagnieNom'],
    );
  }

  /// Convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'code': code,
      'adresse': adresse,
      'telephone': telephone,
      'email': email,
      'siteWeb': siteWeb,
      'logoUrl': logoUrl,
      'status': status,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
      'adminCompagnieId': adminCompagnieId,
      'adminCompagnieEmail': adminCompagnieEmail,
      'adminCompagnieNom': adminCompagnieNom,
    };
  }

  /// Copier avec modifications
  InsuranceCompany copyWith({
    String? nom,
    String? adresse,
    String? telephone,
    String? email,
    String? siteWeb,
    String? logoUrl,
    String? status,
    String? type,
    String? adminCompagnieId,
    String? adminCompagnieEmail,
    String? adminCompagnieNom,
  }) {
    return InsuranceCompany(
      id: id,
      nom: nom ?? this.nom,
      adresse: adresse ?? this.adresse,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      siteWeb: siteWeb ?? this.siteWeb,
      logoUrl: logoUrl ?? this.logoUrl,
      status: status ?? this.status,
      type: type ?? this.type,
      createdAt: createdAt,
      adminCompagnieId: adminCompagnieId ?? this.adminCompagnieId,
      adminCompagnieEmail: adminCompagnieEmail ?? this.adminCompagnieEmail,
      adminCompagnieNom: adminCompagnieNom ?? this.adminCompagnieNom,
    );
  }
}

/// 📊 Statistiques du système
class SystemStats {
  final int totalCompagnies;
  final int compagniesActives;
  final int totalUtilisateurs;
  final int adminCompagnies;
  final int adminAgences;
  final int agents;
  final int experts;
  final int conducteurs;
  final int totalSinistres;
  final int sinistresEnCours;
  final int sinistresTraites;

  SystemStats({
    this.totalCompagnies = 0,
    this.compagniesActives = 0,
    this.totalUtilisateurs = 0,
    this.adminCompagnies = 0,
    this.adminAgences = 0,
    this.agents = 0,
    this.experts = 0,
    this.conducteurs = 0,
    this.totalSinistres = 0,
    this.sinistresEnCours = 0,
    this.sinistresTraites = 0,
  });
}

/// 🏢 Compagnies d'assurance tunisiennes prédéfinies
class TunisianInsuranceCompanies {
  static List<Map<String, dynamic>> getDefaultCompanies() {
    return [
      {
        'nom': 'STAR Assurances',
        'adresse': 'Square Avenue de Paris, Tunis',
        'telephone': '+216 70 255 000',
        'email': 'contact@star.com.tn',
        'siteWeb': 'https://www.star.com.tn',
        'type': 'Classique',
      },
      {
        'nom': 'COMAR Assurances',
        'adresse': 'Immeuble COMAR, avenue Habib Bourguiba, Tunis',
        'telephone': '+216 71 340 899',
        'email': 'info@comar.tn',
        'siteWeb': 'https://www.comar.tn',
        'type': 'Classique',
      },
      {
        'nom': 'MAGHREBIA',
        'adresse': '64 rue de Palestine, Tunis',
        'telephone': '+216 71 788 800',
        'email': 'contact@assurancesmaghrebia.com',
        'siteWeb': 'https://www.assurancesmaghrebia.com',
        'type': 'Classique',
      },
      {
        'nom': 'GAT Assurances',
        'adresse': '92-94 avenue Hédi Chaker, Tunis Belvédère',
        'telephone': '+216 31 350 000',
        'email': 'contact@gat.com.tn',
        'siteWeb': 'https://www.gat.com.tn',
        'type': 'Classique',
      },
      {
        'nom': 'ASTREE',
        'adresse': 'Avenue de la Liberté, Tunis',
        'telephone': '+216 71 832 222',
        'email': 'astree@planet.tn',
        'siteWeb': 'https://www.astree.com.tn',
        'type': 'Classique',
      },
      {
        'nom': 'Lloyd Tunisien',
        'adresse': 'Immeuble LLOYD, avenue principale, Tunis',
        'telephone': '+216 71 962 777',
        'email': 'lloyd@planet.tn',
        'siteWeb': 'http://www.lloydtunisien.com',
        'type': 'Classique',
      },
      {
        'nom': 'BH Assurance',
        'adresse': 'Centre Urbain Nord, RN8, Tunis',
        'telephone': '+216 71 184 200',
        'email': 'contact@bhassurance.com.tn',
        'siteWeb': 'https://www.bhassurance.com.tn',
        'type': 'Classique',
      },
      {
        'nom': 'BNA Assurances',
        'adresse': 'Avenue Mohamed V, Tunis',
        'telephone': '+216 71 347 000',
        'email': 'info@bna-assurances.com.tn',
        'siteWeb': 'https://www.bna-assurances.com.tn',
        'type': 'Classique',
      },
      {
        'nom': 'CARTE Assurances',
        'adresse': 'Lot BC4, Centre Urbain Nord, Tunis',
        'telephone': '+216 71 184 000',
        'email': 'carte@carte.com.tn',
        'siteWeb': 'https://www.carte.com.tn',
        'type': 'Classique',
      },
      {
        'nom': 'Zitouna Takaful',
        'adresse': 'Avenue de la Bourse, Jardins du Lac, Tunis',
        'telephone': '+216 71 19 80 80',
        'email': 'contact@zitounatakaful.com',
        'siteWeb': 'https://www.zitounatakaful.com',
        'type': 'Takaful',
      },
      {
        'nom': 'El Amana Takaful',
        'adresse': 'Avenue Habib Bourguiba, Tunis',
        'telephone': '+216 71 148 000',
        'email': 'contact@elamana.com.tn',
        'siteWeb': 'https://www.elamana.com.tn',
        'type': 'Takaful',
      },
      {
        'nom': 'Assurances BIAT',
        'adresse': 'Avenue Habib Bourguiba, Tunis',
        'telephone': '+216 71 340 000',
        'email': 'contact@biat.com.tn',
        'siteWeb': 'https://www.biat.com.tn',
        'type': 'Classique',
      },
    ];
  }
}
