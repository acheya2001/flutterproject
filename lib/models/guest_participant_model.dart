import 'package:cloud_firestore/cloud_firestore.dart';

/// 👤 Modèle pour conducteur invité non-inscrit
class GuestParticipant {
  final String sessionId;
  final String participantId;
  final String roleVehicule;
  final PersonalInfo infosPersonnelles;
  final VehicleInfo infosVehicule;
  final InsuranceInfo infosAssurance;
  final List<String> circonstances;
  final String? observationsPersonnelles;
  final List<String> photosUrls;
  final DateTime dateCreation;
  final DateTime? dateModification;
  final bool formulaireComplete;

  GuestParticipant({
    required this.sessionId,
    required this.participantId,
    required this.roleVehicule,
    required this.infosPersonnelles,
    required this.infosVehicule,
    required this.infosAssurance,
    required this.circonstances,
    this.observationsPersonnelles,
    required this.photosUrls,
    required this.dateCreation,
    this.dateModification,
    required this.formulaireComplete,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'participantId': participantId,
      'roleVehicule': roleVehicule,
      'infosPersonnelles': infosPersonnelles.toMap(),
      'infosVehicule': infosVehicule.toMap(),
      'infosAssurance': infosAssurance.toMap(),
      'circonstances': circonstances,
      'observationsPersonnelles': observationsPersonnelles,
      'photosUrls': photosUrls,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'dateModification': dateModification != null ? Timestamp.fromDate(dateModification!) : null,
      'formulaireComplete': formulaireComplete,
    };
  }

  factory GuestParticipant.fromMap(Map<String, dynamic> map) {
    return GuestParticipant(
      sessionId: map['sessionId'] ?? '',
      participantId: map['participantId'] ?? '',
      roleVehicule: map['roleVehicule'] ?? '',
      infosPersonnelles: PersonalInfo.fromMap(map['infosPersonnelles'] ?? {}),
      infosVehicule: VehicleInfo.fromMap(map['infosVehicule'] ?? {}),
      infosAssurance: InsuranceInfo.fromMap(map['infosAssurance'] ?? {}),
      circonstances: List<String>.from(map['circonstances'] ?? []),
      observationsPersonnelles: map['observationsPersonnelles'],
      photosUrls: List<String>.from(map['photosUrls'] ?? []),
      dateCreation: (map['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateModification: (map['dateModification'] as Timestamp?)?.toDate(),
      formulaireComplete: map['formulaireComplete'] ?? false,
    );
  }
}

/// 👤 Informations personnelles du conducteur invité
class PersonalInfo {
  final String nom;
  final String prenom;
  final String cin;
  final String telephone;
  final String email;
  final String adresse;
  final String ville;
  final String codePostal;
  final DateTime? dateNaissance;
  final String? profession;
  final String? numeroPermis;
  final String? categoriePermis;
  final DateTime? dateDelivrancePermis;
  final String? photoPermisRectoUrl;
  final String? photoPermisVersoUrl;

  PersonalInfo({
    required this.nom,
    required this.prenom,
    required this.cin,
    required this.telephone,
    required this.email,
    required this.adresse,
    required this.ville,
    required this.codePostal,
    this.dateNaissance,
    this.profession,
    this.numeroPermis,
    this.categoriePermis,
    this.dateDelivrancePermis,
    this.photoPermisRectoUrl,
    this.photoPermisVersoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'prenom': prenom,
      'cin': cin,
      'telephone': telephone,
      'email': email,
      'adresse': adresse,
      'ville': ville,
      'codePostal': codePostal,
      'dateNaissance': dateNaissance != null ? Timestamp.fromDate(dateNaissance!) : null,
      'profession': profession,
      'numeroPermis': numeroPermis,
      'categoriePermis': categoriePermis,
      'dateDelivrancePermis': dateDelivrancePermis != null ? Timestamp.fromDate(dateDelivrancePermis!) : null,
      'photoPermisRectoUrl': photoPermisRectoUrl,
      'photoPermisVersoUrl': photoPermisVersoUrl,
    };
  }

  factory PersonalInfo.fromMap(Map<String, dynamic> map) {
    return PersonalInfo(
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      cin: map['cin'] ?? '',
      telephone: map['telephone'] ?? '',
      email: map['email'] ?? '',
      adresse: map['adresse'] ?? '',
      ville: map['ville'] ?? '',
      codePostal: map['codePostal'] ?? '',
      dateNaissance: (map['dateNaissance'] as Timestamp?)?.toDate(),
      profession: map['profession'],
      numeroPermis: map['numeroPermis'],
      categoriePermis: map['categoriePermis'],
      dateDelivrancePermis: (map['dateDelivrancePermis'] as Timestamp?)?.toDate(),
      photoPermisRectoUrl: map['photoPermisRectoUrl'],
      photoPermisVersoUrl: map['photoPermisVersoUrl'],
    );
  }
}

/// 🚗 Informations véhicule du conducteur invité
class VehicleInfo {
  final String immatriculation;
  final String marque;
  final String modele;
  final String couleur;
  final int? anneeConstruction;
  final String? numeroSerie;
  final String? typeCarburant;
  final int? puissanceFiscale;
  final int? nombrePlaces;
  final String? usage; // Personnel, Professionnel, etc.
  final List<String> pointsChoc;
  final List<String> degatsApparents;
  final String? descriptionDegats;

  VehicleInfo({
    required this.immatriculation,
    required this.marque,
    required this.modele,
    required this.couleur,
    this.anneeConstruction,
    this.numeroSerie,
    this.typeCarburant,
    this.puissanceFiscale,
    this.nombrePlaces,
    this.usage,
    required this.pointsChoc,
    required this.degatsApparents,
    this.descriptionDegats,
  });

  Map<String, dynamic> toMap() {
    return {
      'immatriculation': immatriculation,
      'marque': marque,
      'modele': modele,
      'couleur': couleur,
      'anneeConstruction': anneeConstruction,
      'numeroSerie': numeroSerie,
      'typeCarburant': typeCarburant,
      'puissanceFiscale': puissanceFiscale,
      'nombrePlaces': nombrePlaces,
      'usage': usage,
      'pointsChoc': pointsChoc,
      'degatsApparents': degatsApparents,
      'descriptionDegats': descriptionDegats,
    };
  }

  factory VehicleInfo.fromMap(Map<String, dynamic> map) {
    return VehicleInfo(
      immatriculation: map['immatriculation'] ?? '',
      marque: map['marque'] ?? '',
      modele: map['modele'] ?? '',
      couleur: map['couleur'] ?? '',
      anneeConstruction: map['anneeConstruction'],
      numeroSerie: map['numeroSerie'],
      typeCarburant: map['typeCarburant'],
      puissanceFiscale: map['puissanceFiscale'],
      nombrePlaces: map['nombrePlaces'],
      usage: map['usage'],
      pointsChoc: List<String>.from(map['pointsChoc'] ?? []),
      degatsApparents: List<String>.from(map['degatsApparents'] ?? []),
      descriptionDegats: map['descriptionDegats'],
    );
  }
}

/// 🏢 Informations assurance du conducteur invité
class InsuranceInfo {
  final String compagnieId;
  final String compagnieNom;
  final String agenceId;
  final String agenceNom;
  final String numeroContrat;
  final DateTime? dateDebutContrat;
  final DateTime? dateFinContrat;
  final String? typeContrat; // Tous risques, Tiers, etc.
  final String? numeroAttestation;
  final bool? assuranceValide;
  final String? remarquesAssurance;

  InsuranceInfo({
    required this.compagnieId,
    required this.compagnieNom,
    required this.agenceId,
    required this.agenceNom,
    required this.numeroContrat,
    this.dateDebutContrat,
    this.dateFinContrat,
    this.typeContrat,
    this.numeroAttestation,
    this.assuranceValide,
    this.remarquesAssurance,
  });

  Map<String, dynamic> toMap() {
    return {
      'compagnieId': compagnieId,
      'compagnieNom': compagnieNom,
      'agenceId': agenceId,
      'agenceNom': agenceNom,
      'numeroContrat': numeroContrat,
      'dateDebutContrat': dateDebutContrat != null ? Timestamp.fromDate(dateDebutContrat!) : null,
      'dateFinContrat': dateFinContrat != null ? Timestamp.fromDate(dateFinContrat!) : null,
      'typeContrat': typeContrat,
      'numeroAttestation': numeroAttestation,
      'assuranceValide': assuranceValide,
      'remarquesAssurance': remarquesAssurance,
    };
  }

  factory InsuranceInfo.fromMap(Map<String, dynamic> map) {
    return InsuranceInfo(
      compagnieId: map['compagnieId'] ?? '',
      compagnieNom: map['compagnieNom'] ?? '',
      agenceId: map['agenceId'] ?? '',
      agenceNom: map['agenceNom'] ?? '',
      numeroContrat: map['numeroContrat'] ?? '',
      dateDebutContrat: (map['dateDebutContrat'] as Timestamp?)?.toDate(),
      dateFinContrat: (map['dateFinContrat'] as Timestamp?)?.toDate(),
      typeContrat: map['typeContrat'],
      numeroAttestation: map['numeroAttestation'],
      assuranceValide: map['assuranceValide'],
      remarquesAssurance: map['remarquesAssurance'],
    );
  }
}
