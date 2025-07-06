import 'package:cloud_firestore/cloud_firestore.dart';

/// 👤 Modèle de propriétaire de véhicule
class ProprietaireVehiculeModel {
  final String nom;
  final String prenom;
  final String cin;
  final String telephone;
  final String adresse;
  final DateTime dateNaissance;

  const ProprietaireVehiculeModel({
    required this.nom,
    required this.prenom,
    required this.cin,
    required this.telephone,
    required this.adresse,
    required this.dateNaissance,
  });

  factory ProprietaireVehiculeModel.fromMap(Map<String, dynamic> map) {
    return ProprietaireVehiculeModel(
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      cin: map['cin'] ?? '',
      telephone: map['telephone'] ?? '',
      adresse: map['adresse'] ?? '',
      dateNaissance: (map['date_naissance'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'prenom': prenom,
      'cin': cin,
      'telephone': telephone,
      'adresse': adresse,
      'date_naissance': Timestamp.fromDate(dateNaissance),
    };
  }

  String get nomComplet => '$prenom $nom';
}

/// 📄 Modèle de contrat d'assurance complet
class ContratAssuranceCompletModel {
  final String numeroContrat;
  final String compagnieId;
  final String agenceId;
  final String agentGestionnaire;
  final String typeCouverture; // Tiers, Tiers+, Tous risques
  final DateTime dateDebut;
  final DateTime dateFin;
  final double primeAnnuelle;
  final double franchise;
  final String statut; // actif, suspendu, expire, resilie

  const ContratAssuranceCompletModel({
    required this.numeroContrat,
    required this.compagnieId,
    required this.agenceId,
    required this.agentGestionnaire,
    required this.typeCouverture,
    required this.dateDebut,
    required this.dateFin,
    required this.primeAnnuelle,
    required this.franchise,
    required this.statut,
  });

  factory ContratAssuranceCompletModel.fromMap(Map<String, dynamic> map) {
    return ContratAssuranceCompletModel(
      numeroContrat: map['numero_contrat'] ?? '',
      compagnieId: map['compagnie_id'] ?? '',
      agenceId: map['agence_id'] ?? '',
      agentGestionnaire: map['agent_gestionnaire'] ?? '',
      typeCouverture: map['type_couverture'] ?? '',
      dateDebut: (map['date_debut'] as Timestamp).toDate(),
      dateFin: (map['date_fin'] as Timestamp).toDate(),
      primeAnnuelle: (map['prime_annuelle'] ?? 0).toDouble(),
      franchise: (map['franchise'] ?? 0).toDouble(),
      statut: map['statut'] ?? 'actif',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'numero_contrat': numeroContrat,
      'compagnie_id': compagnieId,
      'agence_id': agenceId,
      'agent_gestionnaire': agentGestionnaire,
      'type_couverture': typeCouverture,
      'date_debut': Timestamp.fromDate(dateDebut),
      'date_fin': Timestamp.fromDate(dateFin),
      'prime_annuelle': primeAnnuelle,
      'franchise': franchise,
      'statut': statut,
    };
  }

  /// Vérifier si le contrat est actif
  bool get isActif {
    final now = DateTime.now();
    return statut == 'actif' && now.isAfter(dateDebut) && now.isBefore(dateFin);
  }

  /// Obtenir les jours restants avant expiration
  int get joursRestants {
    final now = DateTime.now();
    if (now.isAfter(dateFin)) return 0;
    return dateFin.difference(now).inDays;
  }

  /// Vérifier si le contrat expire bientôt (moins de 30 jours)
  bool get expireBientot => joursRestants <= 30 && joursRestants > 0;
}

/// 🚗 Modèle de conducteur autorisé
class ConducteurAutoriseModel {
  final String conducteurEmail;
  final String? conducteurId; // Rempli quand il s'inscrit
  final String relation; // proprietaire, conjoint, enfant, autre
  final DateTime dateAutorisation;
  final String permisNumero;
  final DateTime permisDateObtention;
  final List<String> droits; // conduire, declarer_sinistre

  const ConducteurAutoriseModel({
    required this.conducteurEmail,
    this.conducteurId,
    required this.relation,
    required this.dateAutorisation,
    required this.permisNumero,
    required this.permisDateObtention,
    required this.droits,
  });

  factory ConducteurAutoriseModel.fromMap(Map<String, dynamic> map) {
    return ConducteurAutoriseModel(
      conducteurEmail: map['conducteur_email'] ?? '',
      conducteurId: map['conducteur_id'],
      relation: map['relation'] ?? '',
      dateAutorisation: (map['date_autorisation'] as Timestamp).toDate(),
      permisNumero: map['permis_numero'] ?? '',
      permisDateObtention: (map['permis_date_obtention'] as Timestamp).toDate(),
      droits: List<String>.from(map['droits'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conducteur_email': conducteurEmail,
      'conducteur_id': conducteurId,
      'relation': relation,
      'date_autorisation': Timestamp.fromDate(dateAutorisation),
      'permis_numero': permisNumero,
      'permis_date_obtention': Timestamp.fromDate(permisDateObtention),
      'droits': droits,
    };
  }

  bool get peutConduire => droits.contains('conduire');
  bool get peutDeclarerSinistre => droits.contains('declarer_sinistre');
}

/// 🚗 Modèle de véhicule complet avec toutes les informations
class VehiculeCompletModel {
  final String id;
  
  // Informations véhicule
  final String immatriculation;
  final String marque;
  final String modele;
  final int annee;
  final String couleur;
  final String numeroChassis;
  final int puissanceFiscale;
  final String typeCarburant;
  final int nombrePlaces;
  
  // Informations propriétaire
  final ProprietaireVehiculeModel proprietaire;
  
  // Informations contrat
  final ContratAssuranceCompletModel contrat;
  
  // Conducteurs autorisés
  final List<ConducteurAutoriseModel> conducteursAutorises;
  
  // Historique
  final List<String> historiqueSinistres;
  final DateTime derniereMiseAJour;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VehiculeCompletModel({
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
    required this.proprietaire,
    required this.contrat,
    required this.conducteursAutorises,
    required this.historiqueSinistres,
    required this.derniereMiseAJour,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Créer depuis Firestore
  factory VehiculeCompletModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VehiculeCompletModel(
      id: doc.id,
      immatriculation: data['immatriculation'] ?? '',
      marque: data['marque'] ?? '',
      modele: data['modele'] ?? '',
      annee: data['annee'] ?? 0,
      couleur: data['couleur'] ?? '',
      numeroChassis: data['numero_chassis'] ?? '',
      puissanceFiscale: data['puissance_fiscale'] ?? 0,
      typeCarburant: data['type_carburant'] ?? '',
      nombrePlaces: data['nombre_places'] ?? 5,
      proprietaire: ProprietaireVehiculeModel.fromMap(data['proprietaire'] ?? {}),
      contrat: ContratAssuranceCompletModel.fromMap(data['contrat'] ?? {}),
      conducteursAutorises: (data['conducteurs_autorises'] as List<dynamic>? ?? [])
          .map((item) => ConducteurAutoriseModel.fromMap(item as Map<String, dynamic>))
          .toList(),
      historiqueSinistres: List<String>.from(data['historique_sinistres'] ?? []),
      derniereMiseAJour: (data['derniere_mise_a_jour'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'immatriculation': immatriculation,
      'marque': marque,
      'modele': modele,
      'annee': annee,
      'couleur': couleur,
      'numero_chassis': numeroChassis,
      'puissance_fiscale': puissanceFiscale,
      'type_carburant': typeCarburant,
      'nombre_places': nombrePlaces,
      'proprietaire': proprietaire.toMap(),
      'contrat': contrat.toMap(),
      'conducteurs_autorises': conducteursAutorises.map((c) => c.toMap()).toList(),
      'historique_sinistres': historiqueSinistres,
      'derniere_mise_a_jour': Timestamp.fromDate(derniereMiseAJour),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Obtenir la description complète du véhicule
  String get descriptionVehicule => '$marque $modele ($annee)';

  /// Vérifier si le véhicule est assuré (contrat actif)
  bool get isAssure => contrat.isActif;

  /// Obtenir le nom de la compagnie d'assurance
  String get nomCompagnie {
    switch (contrat.compagnieId) {
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
        return contrat.compagnieId;
    }
  }

  /// Vérifier si un conducteur est autorisé
  bool isConducteurAutorise(String email) {
    return conducteursAutorises.any((c) => c.conducteurEmail.toLowerCase() == email.toLowerCase());
  }

  /// Obtenir les droits d'un conducteur
  List<String> getDroitsConducteur(String email) {
    final conducteur = conducteursAutorises.firstWhere(
      (c) => c.conducteurEmail.toLowerCase() == email.toLowerCase(),
      orElse: () => ConducteurAutoriseModel(
        conducteurEmail: '',
        relation: '',
        dateAutorisation: DateTime.now(),
        permisNumero: '',
        permisDateObtention: DateTime.now(),
        droits: const [],
      ),
    );
    return conducteur.droits;
  }

  @override
  String toString() {
    return 'VehiculeCompletModel(id: $id, vehicule: $descriptionVehicule, contrat: ${contrat.numeroContrat})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VehiculeCompletModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
