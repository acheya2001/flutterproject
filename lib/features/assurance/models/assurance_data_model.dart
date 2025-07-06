import 'package:cloud_firestore/cloud_firestore.dart';

/// 🏢 Modèle pour les compagnies d'assurance
class CompagnieAssurance {
  final String id;
  final String nom;
  final String code;
  final String couleur;
  final String logo;
  final String slogan;
  final String siegeSocial;
  final String telephone;
  final String email;
  final String siteWeb;
  final int capital;
  final String agrement;
  final DateTime dateCreation;
  final List<AgenceAssurance> agences;
  final StatistiquesCompagnie statistiques;
  final List<ProduitAssurance> produits;
  final TarifsAssurance tarifs;
  final DateTime createdAt;
  final DateTime updatedAt;

  CompagnieAssurance({
    required this.id,
    required this.nom,
    required this.code,
    required this.couleur,
    required this.logo,
    required this.slogan,
    required this.siegeSocial,
    required this.telephone,
    required this.email,
    required this.siteWeb,
    required this.capital,
    required this.agrement,
    required this.dateCreation,
    required this.agences,
    required this.statistiques,
    required this.produits,
    required this.tarifs,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CompagnieAssurance.fromMap(Map<String, dynamic> map, String id) {
    return CompagnieAssurance(
      id: id,
      nom: map['nom'] ?? '',
      code: map['code'] ?? '',
      couleur: map['couleur'] ?? '#000000',
      logo: map['logo'] ?? '',
      slogan: map['slogan'] ?? '',
      siegeSocial: map['siege_social'] ?? '',
      telephone: map['telephone'] ?? '',
      email: map['email'] ?? '',
      siteWeb: map['site_web'] ?? '',
      capital: map['capital'] ?? 0,
      agrement: map['agrement'] ?? '',
      dateCreation: (map['date_creation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      agences: (map['agences'] as List?)?.map((a) => AgenceAssurance.fromMap(a)).toList() ?? [],
      statistiques: StatistiquesCompagnie.fromMap(map['statistiques'] ?? {}),
      produits: (map['produits'] as List?)?.map((p) => ProduitAssurance.fromMap(p)).toList() ?? [],
      tarifs: TarifsAssurance.fromMap(map['tarifs'] ?? {}),
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'code': code,
      'couleur': couleur,
      'logo': logo,
      'slogan': slogan,
      'siege_social': siegeSocial,
      'telephone': telephone,
      'email': email,
      'site_web': siteWeb,
      'capital': capital,
      'agrement': agrement,
      'date_creation': Timestamp.fromDate(dateCreation),
      'agences': agences.map((a) => a.toMap()).toList(),
      'statistiques': statistiques.toMap(),
      'produits': produits.map((p) => p.toMap()).toList(),
      'tarifs': tarifs.toMap(),
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }
}

/// 🏪 Modèle pour les agences d'assurance
class AgenceAssurance {
  final String id;
  final String nom;
  final String adresse;
  final String gouvernorat;
  final String telephone;
  final String email;
  final String responsable;
  final Map<String, String> horaires;
  final List<String> services;
  final Coordonnees coordonnees;
  final DateTime createdAt;

  AgenceAssurance({
    required this.id,
    required this.nom,
    required this.adresse,
    required this.gouvernorat,
    required this.telephone,
    required this.email,
    required this.responsable,
    required this.horaires,
    required this.services,
    required this.coordonnees,
    required this.createdAt,
  });

  factory AgenceAssurance.fromMap(Map<String, dynamic> map) {
    return AgenceAssurance(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      adresse: map['adresse'] ?? '',
      gouvernorat: map['gouvernorat'] ?? '',
      telephone: map['telephone'] ?? '',
      email: map['email'] ?? '',
      responsable: map['responsable'] ?? '',
      horaires: Map<String, String>.from(map['horaires'] ?? {}),
      services: List<String>.from(map['services'] ?? []),
      coordonnees: Coordonnees.fromMap(map['coordonnees'] ?? {}),
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'adresse': adresse,
      'gouvernorat': gouvernorat,
      'telephone': telephone,
      'email': email,
      'responsable': responsable,
      'horaires': horaires,
      'services': services,
      'coordonnees': coordonnees.toMap(),
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}

/// 📍 Modèle pour les coordonnées GPS
class Coordonnees {
  final double latitude;
  final double longitude;

  Coordonnees({
    required this.latitude,
    required this.longitude,
  });

  factory Coordonnees.fromMap(Map<String, dynamic> map) {
    return Coordonnees(
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

/// 📊 Modèle pour les statistiques de compagnie
class StatistiquesCompagnie {
  final int totalContrats;
  final int contratsActifs;
  final int sinistresAnnee;
  final int chiffreAffaires;
  final String ratioSinistralite;

  StatistiquesCompagnie({
    required this.totalContrats,
    required this.contratsActifs,
    required this.sinistresAnnee,
    required this.chiffreAffaires,
    required this.ratioSinistralite,
  });

  factory StatistiquesCompagnie.fromMap(Map<String, dynamic> map) {
    return StatistiquesCompagnie(
      totalContrats: map['total_contrats'] ?? 0,
      contratsActifs: map['contrats_actifs'] ?? 0,
      sinistresAnnee: map['sinistres_annee'] ?? 0,
      chiffreAffaires: map['chiffre_affaires'] ?? 0,
      ratioSinistralite: map['ratio_sinistralite'] ?? '0.0',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_contrats': totalContrats,
      'contrats_actifs': contratsActifs,
      'sinistres_annee': sinistresAnnee,
      'chiffre_affaires': chiffreAffaires,
      'ratio_sinistralite': ratioSinistralite,
    };
  }
}

/// 🛡️ Modèle pour les produits d'assurance
class ProduitAssurance {
  final String nom;
  final int prixBase;
  final String description;

  ProduitAssurance({
    required this.nom,
    required this.prixBase,
    required this.description,
  });

  factory ProduitAssurance.fromMap(Map<String, dynamic> map) {
    return ProduitAssurance(
      nom: map['nom'] ?? '',
      prixBase: map['prix_base'] ?? 0,
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'prix_base': prixBase,
      'description': description,
    };
  }
}

/// 💰 Modèle pour les tarifs d'assurance
class TarifsAssurance {
  final double jeuneConducteur;
  final double conducteurExperimente;
  final double senior;
  final double malus;
  final double bonusMax;
  final int franchiseMini;
  final int franchiseMaxi;

  TarifsAssurance({
    required this.jeuneConducteur,
    required this.conducteurExperimente,
    required this.senior,
    required this.malus,
    required this.bonusMax,
    required this.franchiseMini,
    required this.franchiseMaxi,
  });

  factory TarifsAssurance.fromMap(Map<String, dynamic> map) {
    return TarifsAssurance(
      jeuneConducteur: (map['jeune_conducteur'] ?? 1.0).toDouble(),
      conducteurExperimente: (map['conducteur_experimente'] ?? 1.0).toDouble(),
      senior: (map['senior'] ?? 1.0).toDouble(),
      malus: (map['malus'] ?? 1.0).toDouble(),
      bonusMax: (map['bonus_max'] ?? 1.0).toDouble(),
      franchiseMini: map['franchise_mini'] ?? 100,
      franchiseMaxi: map['franchise_maxi'] ?? 500,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jeune_conducteur': jeuneConducteur,
      'conducteur_experimente': conducteurExperimente,
      'senior': senior,
      'malus': malus,
      'bonus_max': bonusMax,
      'franchise_mini': franchiseMini,
      'franchise_maxi': franchiseMaxi,
    };
  }
}

/// 👤 Modèle pour les clients d'assurance
class ClientAssurance {
  final String id;
  final String nom;
  final String prenom;
  final String cin;
  final String telephone;
  final String email;
  final String adresse;
  final DateTime dateNaissance;
  final DateTime createdAt;

  ClientAssurance({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.cin,
    required this.telephone,
    required this.email,
    required this.adresse,
    required this.dateNaissance,
    required this.createdAt,
  });

  factory ClientAssurance.fromMap(Map<String, dynamic> map, String id) {
    return ClientAssurance(
      id: id,
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      cin: map['cin'] ?? '',
      telephone: map['telephone'] ?? '',
      email: map['email'] ?? '',
      adresse: map['adresse'] ?? '',
      dateNaissance: (map['date_naissance'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'prenom': prenom,
      'cin': cin,
      'telephone': telephone,
      'email': email,
      'adresse': adresse,
      'date_naissance': Timestamp.fromDate(dateNaissance),
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  String get nomComplet => '$prenom $nom';
  int get age => DateTime.now().difference(dateNaissance).inDays ~/ 365;
}

/// 👨‍💼 Modèle pour les utilisateurs assureurs
class UtilisateurAssureur {
  final String id;
  final String email;
  final String nom;
  final String prenom;
  final String telephone;
  final String compagnie;
  final String poste;
  final String agenceId;
  final List<String> permissions;
  final String statut;
  final DateTime dateEmbauche;
  final DateTime createdAt;
  final DateTime updatedAt;

  UtilisateurAssureur({
    required this.id,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.compagnie,
    required this.poste,
    required this.agenceId,
    required this.permissions,
    required this.statut,
    required this.dateEmbauche,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UtilisateurAssureur.fromMap(Map<String, dynamic> map, String id) {
    return UtilisateurAssureur(
      id: id,
      email: map['email'] ?? '',
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      telephone: map['telephone'] ?? '',
      compagnie: map['compagnie'] ?? '',
      poste: map['poste'] ?? '',
      agenceId: map['agence_id'] ?? '',
      permissions: List<String>.from(map['permissions'] ?? []),
      statut: map['statut'] ?? 'actif',
      dateEmbauche: (map['date_embauche'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'compagnie': compagnie,
      'poste': poste,
      'agence_id': agenceId,
      'permissions': permissions,
      'statut': statut,
      'date_embauche': Timestamp.fromDate(dateEmbauche),
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  String get nomComplet => '$prenom $nom';
  bool get isActif => statut == 'actif';
  bool hasPermission(String permission) => permissions.contains(permission);
}
