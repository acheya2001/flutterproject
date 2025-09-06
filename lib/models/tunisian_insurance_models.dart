import 'package:cloud_firestore/cloud_firestore.dart';

/// 🏢 Modèle pour les compagnies d'assurance tunisiennes
class CompagnieAssurance {
  final String id;
  final String nom;
  final String code; // COMAR, STAR, GAT, etc.
  final String adresseSiege;
  final String telephone;
  final String email;
  final String numeroAgrement;
  final bool isActive;
  final DateTime dateCreation;
  final List<String> typesAssurance; // auto, habitation, vie, etc.
  final Map<String, dynamic> tarifBase; // Tarifs de base par type

  CompagnieAssurance({
    required this.id,
    required this.nom,
    required this.code,
    required this.adresseSiege,
    required this.telephone,
    required this.email,
    required this.numeroAgrement,
    required this.isActive,
    required this.dateCreation,
    required this.typesAssurance,
    required this.tarifBase,
  });

  factory CompagnieAssurance.fromMap(Map<String, dynamic> map) {
    return CompagnieAssurance(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      code: map['code'] ?? '',
      adresseSiege: map['adresseSiege'] ?? '',
      telephone: map['telephone'] ?? '',
      email: map['email'] ?? '',
      numeroAgrement: map['numeroAgrement'] ?? '',
      isActive: map['isActive'] ?? true,
      dateCreation: (map['dateCreation'] as Timestamp).toDate(),
      typesAssurance: List<String>.from(map['typesAssurance'] ?? []),
      tarifBase: Map<String, dynamic>.from(map['tarifBase'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'code': code,
      'adresseSiege': adresseSiege,
      'telephone': telephone,
      'email': email,
      'numeroAgrement': numeroAgrement,
      'isActive': isActive,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'typesAssurance': typesAssurance,
      'tarifBase': tarifBase,
    };
  }
}

/// 🏪 Modèle pour les agences d'assurance
class AgenceAssurance {
  final String id;
  final String compagnieId;
  final String nom;
  final String code;
  final String adresse;
  final String ville;
  final String telephone;
  final String email;
  final String agentGeneralId;
  final String agentGeneralNom;
  final bool isActive;
  final DateTime dateCreation;
  final Map<String, dynamic> statistiques;

  AgenceAssurance({
    required this.id,
    required this.compagnieId,
    required this.nom,
    required this.code,
    required this.adresse,
    required this.ville,
    required this.telephone,
    required this.email,
    required this.agentGeneralId,
    required this.agentGeneralNom,
    required this.isActive,
    required this.dateCreation,
    required this.statistiques,
  });

  factory AgenceAssurance.fromMap(Map<String, dynamic> map) {
    return AgenceAssurance(
      id: map['id'] ?? '',
      compagnieId: map['compagnieId'] ?? '',
      nom: map['nom'] ?? '',
      code: map['code'] ?? '',
      adresse: map['adresse'] ?? '',
      ville: map['ville'] ?? '',
      telephone: map['telephone'] ?? '',
      email: map['email'] ?? '',
      agentGeneralId: map['agentGeneralId'] ?? '',
      agentGeneralNom: map['agentGeneralNom'] ?? '',
      isActive: map['isActive'] ?? true,
      dateCreation: (map['dateCreation'] as Timestamp).toDate(),
      statistiques: Map<String, dynamic>.from(map['statistiques'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'compagnieId': compagnieId,
      'nom': nom,
      'code': code,
      'adresse': adresse,
      'ville': ville,
      'telephone': telephone,
      'email': email,
      'agentGeneralId': agentGeneralId,
      'agentGeneralNom': agentGeneralNom,
      'isActive': isActive,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'statistiques': statistiques,
    };
  }
}

/// 👨‍💼 Modèle pour les agents d'assurance
class AgentAssurance {
  final String id;
  final String compagnieId;
  final String agenceId;
  final String nom;
  final String prenom;
  final String cin;
  final String telephone;
  final String email;
  final String adresse;
  final String numeroLicence;
  final DateTime dateEmbauche;
  final bool isActive;
  final Map<String, dynamic> permissions;
  final Map<String, dynamic> statistiques;

  AgentAssurance({
    required this.id,
    required this.compagnieId,
    required this.agenceId,
    required this.nom,
    required this.prenom,
    required this.cin,
    required this.telephone,
    required this.email,
    required this.adresse,
    required this.numeroLicence,
    required this.dateEmbauche,
    required this.isActive,
    required this.permissions,
    required this.statistiques,
  });

  factory AgentAssurance.fromMap(Map<String, dynamic> map) {
    return AgentAssurance(
      id: map['id'] ?? '',
      compagnieId: map['compagnieId'] ?? '',
      agenceId: map['agenceId'] ?? '',
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      cin: map['cin'] ?? '',
      telephone: map['telephone'] ?? '',
      email: map['email'] ?? '',
      adresse: map['adresse'] ?? '',
      numeroLicence: map['numeroLicence'] ?? '',
      dateEmbauche: (map['dateEmbauche'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
      permissions: Map<String, dynamic>.from(map['permissions'] ?? {}),
      statistiques: Map<String, dynamic>.from(map['statistiques'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'compagnieId': compagnieId,
      'agenceId': agenceId,
      'nom': nom,
      'prenom': prenom,
      'cin': cin,
      'telephone': telephone,
      'email': email,
      'adresse': adresse,
      'numeroLicence': numeroLicence,
      'dateEmbauche': Timestamp.fromDate(dateEmbauche),
      'isActive': isActive,
      'permissions': permissions,
      'statistiques': statistiques,
    };
  }
}

/// 🚗 Modèle pour les véhicules avec informations complètes
class VehiculeAssure {
  final String id;
  final String conducteurId;
  final String numeroImmatriculation;
  final String numeroCarteGrise;
  final String marque;
  final String modele;
  final int annee;
  final String couleur;
  final String typeVehicule; // voiture, camion, moto, etc.
  final int puissanceFiscale;
  final String carburant;
  final String numeroSerie;
  final DateTime datePremiereImmatriculation;
  final Map<String, dynamic> proprietaire;
  final bool isActive;
  final DateTime dateCreation;

  VehiculeAssure({
    required this.id,
    required this.conducteurId,
    required this.numeroImmatriculation,
    required this.numeroCarteGrise,
    required this.marque,
    required this.modele,
    required this.annee,
    required this.couleur,
    required this.typeVehicule,
    required this.puissanceFiscale,
    required this.carburant,
    required this.numeroSerie,
    required this.datePremiereImmatriculation,
    required this.proprietaire,
    required this.isActive,
    required this.dateCreation,
  });

  factory VehiculeAssure.fromMap(Map<String, dynamic> map) {
    return VehiculeAssure(
      id: map['id'] ?? '',
      conducteurId: map['conducteurId'] ?? '',
      numeroImmatriculation: map['numeroImmatriculation'] ?? '',
      numeroCarteGrise: map['numeroCarteGrise'] ?? '',
      marque: map['marque'] ?? '',
      modele: map['modele'] ?? '',
      annee: map['annee'] ?? 0,
      couleur: map['couleur'] ?? '',
      typeVehicule: map['typeVehicule'] ?? '',
      puissanceFiscale: map['puissanceFiscale'] ?? 0,
      carburant: map['carburant'] ?? '',
      numeroSerie: map['numeroSerie'] ?? '',
      datePremiereImmatriculation: (map['datePremiereImmatriculation'] as Timestamp).toDate(),
      proprietaire: Map<String, dynamic>.from(map['proprietaire'] ?? {}),
      isActive: map['isActive'] ?? true,
      dateCreation: (map['dateCreation'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conducteurId': conducteurId,
      'numeroImmatriculation': numeroImmatriculation,
      'numeroCarteGrise': numeroCarteGrise,
      'marque': marque,
      'modele': modele,
      'annee': annee,
      'couleur': couleur,
      'typeVehicule': typeVehicule,
      'puissanceFiscale': puissanceFiscale,
      'carburant': carburant,
      'numeroSerie': numeroSerie,
      'datePremiereImmatriculation': Timestamp.fromDate(datePremiereImmatriculation),
      'proprietaire': proprietaire,
      'isActive': isActive,
      'dateCreation': Timestamp.fromDate(dateCreation),
    };
  }
}

/// 📋 Modèle pour les contrats d'assurance tunisiens
class ContratAssuranceTunisien {
  final String id;
  final String numeroContrat;
  final String vehiculeId;
  final String conducteurId;
  final String agentId;
  final String agenceId;
  final String compagnieId;
  final String typeCouverture;
  final List<String> garanties;
  final double primeAnnuelle;
  final double franchise;
  final DateTime dateDebut;
  final DateTime dateFin;
  final DateTime dateEcheance;
  final String statut; // actif, expire, suspendu, resilie
  final Map<String, dynamic> paiement;
  final Map<String, dynamic> documents;
  final DateTime dateCreation;
  final DateTime? dateRenouvellement;

  ContratAssuranceTunisien({
    required this.id,
    required this.numeroContrat,
    required this.vehiculeId,
    required this.conducteurId,
    required this.agentId,
    required this.agenceId,
    required this.compagnieId,
    required this.typeCouverture,
    required this.garanties,
    required this.primeAnnuelle,
    required this.franchise,
    required this.dateDebut,
    required this.dateFin,
    required this.dateEcheance,
    required this.statut,
    required this.paiement,
    required this.documents,
    required this.dateCreation,
    this.dateRenouvellement,
  });

  factory ContratAssuranceTunisien.fromMap(Map<String, dynamic> map) {
    return ContratAssuranceTunisien(
      id: map['id'] ?? '',
      numeroContrat: map['numeroContrat'] ?? '',
      vehiculeId: map['vehiculeId'] ?? '',
      conducteurId: map['conducteurId'] ?? '',
      agentId: map['agentId'] ?? '',
      agenceId: map['agenceId'] ?? '',
      compagnieId: map['compagnieId'] ?? '',
      typeCouverture: map['typeCouverture'] ?? '',
      garanties: List<String>.from(map['garanties'] ?? []),
      primeAnnuelle: (map['primeAnnuelle'] ?? 0).toDouble(),
      franchise: (map['franchise'] ?? 0).toDouble(),
      dateDebut: (map['dateDebut'] as Timestamp).toDate(),
      dateFin: (map['dateFin'] as Timestamp).toDate(),
      dateEcheance: (map['dateEcheance'] as Timestamp).toDate(),
      statut: map['statut'] ?? '',
      paiement: Map<String, dynamic>.from(map['paiement'] ?? {}),
      documents: Map<String, dynamic>.from(map['documents'] ?? {}),
      dateCreation: (map['dateCreation'] as Timestamp).toDate(),
      dateRenouvellement: map['dateRenouvellement'] != null 
          ? (map['dateRenouvellement'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numeroContrat': numeroContrat,
      'vehiculeId': vehiculeId,
      'conducteurId': conducteurId,
      'agentId': agentId,
      'agenceId': agenceId,
      'compagnieId': compagnieId,
      'typeCouverture': typeCouverture,
      'garanties': garanties,
      'primeAnnuelle': primeAnnuelle,
      'franchise': franchise,
      'dateDebut': Timestamp.fromDate(dateDebut),
      'dateFin': Timestamp.fromDate(dateFin),
      'dateEcheance': Timestamp.fromDate(dateEcheance),
      'statut': statut,
      'paiement': paiement,
      'documents': documents,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'dateRenouvellement': dateRenouvellement != null 
          ? Timestamp.fromDate(dateRenouvellement!) 
          : null,
    };
  }
}
