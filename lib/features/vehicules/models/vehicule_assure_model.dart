import 'package:cloud_firestore/cloud_firestore.dart';

/// 🚗 Modèle pour un véhicule assuré
class VehiculeAssureModel {
  final String id;
  final String assureurId;
  final String numeroContrat;
  final ProprietaireInfo proprietaire;
  final VehiculeInfo vehicule;
  final ContratInfo contrat;
  final String statut; // actif, suspendu, expire
  final List<SinistreInfo> historiqueSinistres;
  final DateTime createdAt;
  final DateTime updatedAt;

  VehiculeAssureModel({
    required this.id,
    required this.assureurId,
    required this.numeroContrat,
    required this.proprietaire,
    required this.vehicule,
    required this.contrat,
    required this.statut,
    this.historiqueSinistres = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Vérifie si le contrat est actif
  bool get isContratActif {
    final now = DateTime.now();
    return statut == 'actif' && 
           now.isAfter(contrat.dateDebut) && 
           now.isBefore(contrat.dateFin);
  }

  /// Vérifie si le véhicule appartient à un utilisateur
  bool belongsToUser(String userId) {
    return proprietaire.userId == userId;
  }

  Map<String, dynamic> toMap() {
    return {
      'assureur_id': assureurId,
      'numero_contrat': numeroContrat,
      'proprietaire': proprietaire.toMap(),
      'vehicule': vehicule.toMap(),
      'contrat': contrat.toMap(),
      'statut': statut,
      'historique_sinistres': historiqueSinistres.map((s) => s.toMap()).toList(),
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  factory VehiculeAssureModel.fromMap(Map<String, dynamic> map, String docId) {
    return VehiculeAssureModel(
      id: docId,
      assureurId: map['assureur_id'] ?? '',
      numeroContrat: map['numero_contrat'] ?? '',
      proprietaire: ProprietaireInfo.fromMap(map['proprietaire'] ?? {}),
      vehicule: VehiculeInfo.fromMap(map['vehicule'] ?? {}),
      contrat: ContratInfo.fromMap(map['contrat'] ?? {}),
      statut: map['statut'] ?? 'actif',
      historiqueSinistres: (map['historique_sinistres'] as List<dynamic>?)
          ?.map((s) => SinistreInfo.fromMap(s))
          .toList() ?? [],
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  VehiculeAssureModel copyWith({
    String? assureurId,
    String? numeroContrat,
    ProprietaireInfo? proprietaire,
    VehiculeInfo? vehicule,
    ContratInfo? contrat,
    String? statut,
    List<SinistreInfo>? historiqueSinistres,
    DateTime? updatedAt,
  }) {
    return VehiculeAssureModel(
      id: id,
      assureurId: assureurId ?? this.assureurId,
      numeroContrat: numeroContrat ?? this.numeroContrat,
      proprietaire: proprietaire ?? this.proprietaire,
      vehicule: vehicule ?? this.vehicule,
      contrat: contrat ?? this.contrat,
      statut: statut ?? this.statut,
      historiqueSinistres: historiqueSinistres ?? this.historiqueSinistres,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// 👤 Informations du propriétaire
class ProprietaireInfo {
  final String userId;
  final String nom;
  final String prenom;
  final String cin;
  final String telephone;

  ProprietaireInfo({
    required this.userId,
    required this.nom,
    required this.prenom,
    required this.cin,
    required this.telephone,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'nom': nom,
      'prenom': prenom,
      'cin': cin,
      'telephone': telephone,
    };
  }

  factory ProprietaireInfo.fromMap(Map<String, dynamic> map) {
    return ProprietaireInfo(
      userId: map['user_id'] ?? '',
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      cin: map['cin'] ?? '',
      telephone: map['telephone'] ?? '',
    );
  }
}

/// 🚗 Informations du véhicule
class VehiculeInfo {
  final String marque;
  final String modele;
  final int annee;
  final String couleur;
  final String immatriculation;
  final String numeroChassis;
  final int puissanceFiscale;

  VehiculeInfo({
    required this.marque,
    required this.modele,
    required this.annee,
    required this.couleur,
    required this.immatriculation,
    required this.numeroChassis,
    required this.puissanceFiscale,
  });

  Map<String, dynamic> toMap() {
    return {
      'marque': marque,
      'modele': modele,
      'annee': annee,
      'couleur': couleur,
      'immatriculation': immatriculation,
      'numero_chassis': numeroChassis,
      'puissance_fiscale': puissanceFiscale,
    };
  }

  factory VehiculeInfo.fromMap(Map<String, dynamic> map) {
    return VehiculeInfo(
      marque: map['marque'] ?? '',
      modele: map['modele'] ?? '',
      annee: map['annee'] ?? 0,
      couleur: map['couleur'] ?? '',
      immatriculation: map['immatriculation'] ?? '',
      numeroChassis: map['numero_chassis'] ?? '',
      puissanceFiscale: map['puissance_fiscale'] ?? 0,
    );
  }
}

/// 📄 Informations du contrat
class ContratInfo {
  final DateTime dateDebut;
  final DateTime dateFin;
  final String typeCouverture;
  final double franchise;
  final double primeAnnuelle;

  ContratInfo({
    required this.dateDebut,
    required this.dateFin,
    required this.typeCouverture,
    required this.franchise,
    required this.primeAnnuelle,
  });

  Map<String, dynamic> toMap() {
    return {
      'date_debut': Timestamp.fromDate(dateDebut),
      'date_fin': Timestamp.fromDate(dateFin),
      'type_couverture': typeCouverture,
      'franchise': franchise,
      'prime_annuelle': primeAnnuelle,
    };
  }

  factory ContratInfo.fromMap(Map<String, dynamic> map) {
    return ContratInfo(
      dateDebut: (map['date_debut'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateFin: (map['date_fin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      typeCouverture: map['type_couverture'] ?? '',
      franchise: (map['franchise'] ?? 0).toDouble(),
      primeAnnuelle: (map['prime_annuelle'] ?? 0).toDouble(),
    );
  }
}

/// 💥 Informations d'un sinistre
class SinistreInfo {
  final DateTime date;
  final String numeroSinistre;
  final double montant;
  final String statut;

  SinistreInfo({
    required this.date,
    required this.numeroSinistre,
    required this.montant,
    required this.statut,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'numero_sinistre': numeroSinistre,
      'montant': montant,
      'statut': statut,
    };
  }

  factory SinistreInfo.fromMap(Map<String, dynamic> map) {
    return SinistreInfo(
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      numeroSinistre: map['numero_sinistre'] ?? '',
      montant: (map['montant'] ?? 0).toDouble(),
      statut: map['statut'] ?? '',
    );
  }
}
