import 'package:cloud_firestore/cloud_firestore.dart';

/// 🚗 Modèle de véhicule
class VehiculeModel {
  final String id;
  final String immatriculation;
  final String marque;
  final String modele;
  final int annee;
  final String couleur;
  final String numeroChassis;
  final int puissanceFiscale;
  final String typeCarburant;
  final int nombrePlaces;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VehiculeModel({
    required this.id,
    required this.immatriculation,
    required this.marque,
    required this.modele,
    required this.annee,
    required this.couleur,
    required this.numeroChassis,
    required this.puissanceFiscale,
    required this.typeCarburant,
    required this.nombrePlaces,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VehiculeModel.fromMap(Map<String, dynamic> map) {
    return VehiculeModel(
      id: map['id'] ?? '',
      immatriculation: map['immatriculation'] ?? '',
      marque: map['marque'] ?? '',
      modele: map['modele'] ?? '',
      annee: map['annee'] ?? 0,
      couleur: map['couleur'] ?? '',
      numeroChassis: map['numero_chassis'] ?? '',
      puissanceFiscale: map['puissance_fiscale'] ?? 0,
      typeCarburant: map['type_carburant'] ?? '',
      nombrePlaces: map['nombre_places'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'immatriculation': immatriculation,
      'marque': marque,
      'modele': modele,
      'annee': annee,
      'couleur': couleur,
      'numero_chassis': numeroChassis,
      'puissance_fiscale': puissanceFiscale,
      'type_carburant': typeCarburant,
      'nombre_places': nombrePlaces,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

/// 👤 Modèle de propriétaire
class ProprietaireModel {
  final String nom;
  final String prenom;
  final String cin;
  final String telephone;
  final String adresse;

  const ProprietaireModel({
    required this.nom,
    required this.prenom,
    required this.cin,
    required this.telephone,
    required this.adresse,
  });

  factory ProprietaireModel.fromMap(Map<String, dynamic> map) {
    return ProprietaireModel(
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      cin: map['cin'] ?? '',
      telephone: map['telephone'] ?? '',
      adresse: map['adresse'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'prenom': prenom,
      'cin': cin,
      'telephone': telephone,
      'adresse': adresse,
    };
  }

  String get nomComplet => '$prenom $nom';
}

/// 📄 Modèle de contrat d'assurance
class ContratAssuranceModel {
  final String typeCouverture;
  final DateTime dateDebut;
  final DateTime dateFin;
  final double primeAnnuelle;
  final double franchise;

  const ContratAssuranceModel({
    required this.typeCouverture,
    required this.dateDebut,
    required this.dateFin,
    required this.primeAnnuelle,
    required this.franchise,
  });

  factory ContratAssuranceModel.fromMap(Map<String, dynamic> map) {
    return ContratAssuranceModel(
      typeCouverture: map['type_couverture'] ?? '',
      dateDebut: (map['date_debut'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateFin: (map['date_fin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      primeAnnuelle: (map['prime_annuelle'] ?? 0).toDouble(),
      franchise: (map['franchise'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type_couverture': typeCouverture,
      'date_debut': Timestamp.fromDate(dateDebut),
      'date_fin': Timestamp.fromDate(dateFin),
      'prime_annuelle': primeAnnuelle,
      'franchise': franchise,
    };
  }

  int get joursRestants {
    final now = DateTime.now();
    if (dateFin.isBefore(now)) return 0;
    return dateFin.difference(now).inDays;
  }

  bool get estExpire => DateTime.now().isAfter(dateFin);
  bool get expireBientot => joursRestants <= 30 && joursRestants > 0;
}

/// 🚗📋 Modèle principal de véhicule assuré
class VehiculeAssureModel {
  final String id;
  final String numeroContrat;
  final String assureurId;
  final VehiculeModel vehicule;
  final ProprietaireModel proprietaire;
  final ContratAssuranceModel contrat;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VehiculeAssureModel({
    required this.id,
    required this.numeroContrat,
    required this.assureurId,
    required this.vehicule,
    required this.proprietaire,
    required this.contrat,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VehiculeAssureModel.fromMap(Map<String, dynamic> data) {
    return VehiculeAssureModel(
      id: data['id'] ?? '',
      numeroContrat: data['numero_contrat'] ?? '',
      assureurId: data['assureur_id'] ?? '',
      vehicule: VehiculeModel.fromMap(data['vehicule'] ?? {}),
      proprietaire: ProprietaireModel.fromMap(data['proprietaire'] ?? {}),
      contrat: ContratAssuranceModel.fromMap(data['contrat'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numero_contrat': numeroContrat,
      'assureur_id': assureurId,
      'vehicule': vehicule.toMap(),
      'proprietaire': proprietaire.toMap(),
      'contrat': contrat.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Obtenir le nom de l'assureur
  String get nomAssureur {
    switch (assureurId.toUpperCase()) {
      case 'STAR':
        return 'STAR Assurances';
      case 'MAGHREBIA':
        return 'Maghrebia Assurances';
      case 'LLOYD':
        return 'Lloyd Tunisien';
      case 'GAT':
        return 'GAT Assurances';
      case 'AST':
        return 'Assurances Salim';
      default:
        return assureurId;
    }
  }

  String get descriptionVehicule => '${vehicule.marque} ${vehicule.modele} (${vehicule.annee})';

  /// Obtenir le statut d'assurance
  String get statutAssurance {
    if (contrat.estExpire) {
      return 'Expiré';
    } else if (contrat.expireBientot) {
      return 'Expire bientôt';
    }
    return 'Assuré';
  }

  @override
  String toString() {
    return 'VehiculeAssureModel(id: $id, vehicule: $descriptionVehicule, contrat: $numeroContrat)';
  }
}