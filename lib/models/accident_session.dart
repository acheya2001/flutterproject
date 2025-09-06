import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

/// 🚗 Informations d'identité du véhicule (Case 9)
class IdentiteVehicule {
  final String marque;
  final String type;
  final String numeroImmatriculation;
  final String senssuivi;
  final String venantDe;
  final String allantA;

  IdentiteVehicule({
    required this.marque,
    required this.type,
    required this.numeroImmatriculation,
    required this.senssuivi,
    required this.venantDe,
    required this.allantA,
  });

  Map<String, dynamic> toMap() {
    return {
      'marque': marque,
      'type': type,
      'numeroImmatriculation': numeroImmatriculation,
      'senssuivi': senssuivi,
      'venantDe': venantDe,
      'allantA': allantA,
    };
  }

  factory IdentiteVehicule.fromMap(Map<String, dynamic> map) {
    return IdentiteVehicule(
      marque: map['marque'] ?? '',
      type: map['type'] ?? '',
      numeroImmatriculation: map['numeroImmatriculation'] ?? '',
      senssuivi: map['senssuivi'] ?? '',
      venantDe: map['venantDe'] ?? '',
      allantA: map['allantA'] ?? '',
    );
  }
}

/// 🎯 Point de choc initial (Case 10)
class PointChocInitial {
  final double x; // Position X sur le schéma du véhicule (0-1)
  final double y; // Position Y sur le schéma du véhicule (0-1)
  final String description;

  PointChocInitial({
    required this.x,
    required this.y,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'description': description,
    };
  }

  factory PointChocInitial.fromMap(Map<String, dynamic> map) {
    return PointChocInitial(
      x: map['x']?.toDouble() ?? 0.0,
      y: map['y']?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
    );
  }
}

/// 🔧 Dégâts apparents (Case 11)
class DegatsApparents {
  final String description;
  final List<String> zones; // Zones endommagées
  final String? croquisData; // Données du croquis libre

  DegatsApparents({
    required this.description,
    required this.zones,
    this.croquisData,
  });

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'zones': zones,
      'croquisData': croquisData,
    };
  }

  factory DegatsApparents.fromMap(Map<String, dynamic> map) {
    return DegatsApparents(
      description: map['description'] ?? '',
      zones: List<String>.from(map['zones'] ?? []),
      croquisData: map['croquisData'],
    );
  }
}

/// 📋 Circonstances de l'accident (Case 12)
class CirconstancesAccident {
  final List<int> casesSelectionnees; // Numéros des cases cochées (1-17)
  final int nombreCasesMarquees; // Case 17: nombre total

  CirconstancesAccident({
    required this.casesSelectionnees,
    required this.nombreCasesMarquees,
  });

  Map<String, dynamic> toMap() {
    return {
      'casesSelectionnees': casesSelectionnees,
      'nombreCasesMarquees': nombreCasesMarquees,
    };
  }

  factory CirconstancesAccident.fromMap(Map<String, dynamic> map) {
    return CirconstancesAccident(
      casesSelectionnees: List<int>.from(map['casesSelectionnees'] ?? []),
      nombreCasesMarquees: map['nombreCasesMarquees'] ?? 0,
    );
  }

  // Liste des 17 circonstances officielles
  static const List<String> circonstancesOfficielle = [
    'stationnait', // 1
    'quittait un stationnement', // 2
    'prenait un stationnement', // 3
    'sortait d\'un parking, d\'un lieu privé, d\'un chemin de terre', // 4
    's\'engageait dans un parking, un lieu privé, un chemin de terre', // 5
    'arrêt de circulation', // 6
    'roulement sans changement de file', // 7
    'roulait à l\'arrière en roulant dans la même sens et sur une même file', // 8
    'roulait dans le même sens et changeait de file', // 9
    'doublait', // 10
    'virait à droite', // 11
    'virait à gauche', // 12
    'reculait', // 13
    'empiétait sur la partie de chaussée réservée à la circulation en sens inverse', // 14
    'venait de droite (dans un carrefour)', // 15
    'n\'avait pas observé le signal de priorité', // 16
    'Indiquer le nombre de cases marquées d\'une croix', // 17
  ];
}

/// ✍️ Signature du conducteur (Case 15)
class SignatureConducteur {
  final String? signatureData; // Données de la signature (base64 ou path)
  final DateTime? dateSignature;
  final bool accepteResponsabilite;

  SignatureConducteur({
    this.signatureData,
    this.dateSignature,
    required this.accepteResponsabilite,
  });

  Map<String, dynamic> toMap() {
    return {
      'signatureData': signatureData,
      'dateSignature': dateSignature?.toIso8601String(),
      'accepteResponsabilite': accepteResponsabilite,
    };
  }

  factory SignatureConducteur.fromMap(Map<String, dynamic> map) {
    return SignatureConducteur(
      signatureData: map['signatureData'],
      dateSignature: map['dateSignature'] != null
          ? DateTime.parse(map['dateSignature'])
          : null,
      accepteResponsabilite: map['accepteResponsabilite'] ?? false,
    );
  }
}

/// 🚨 Modèle pour une session d'accident collaborative (nouveau système)
class AccidentSession {
  final String id;
  final String codePublic; // Code unique pour partage (ex: ACC-2024-001)
  final String createurUserId;
  final String createurVehiculeId; // Véhicule sélectionné par le créateur
  final String statut; // État de la state machine
  final DateTime dateOuverture;

  // Section commune (cases 1-5 du constat papier)
  final DateTime? dateAccident; // Case 1
  final TimeOfDay? heureAccident; // Case 1
  final Map<String, dynamic> localisation; // Case 2: {adresse, lat, lng, ville, codePostal}
  final bool blesses; // Case 3
  final bool degatsAutres; // Case 4
  final List<Temoin> temoins; // Case 5

  // Nouvelles sections conformes au constat officiel
  final Map<String, IdentiteVehicule> identitesVehicules; // Case 9: A et B
  final Map<String, PointChocInitial?> pointsChocInitial; // Case 10: A et B
  final Map<String, DegatsApparents> degatsApparents; // Case 11: A et B
  final Map<String, CirconstancesAccident> circonstances; // Case 12: A et B
  final Map<String, String> observationsVehicules; // Case 14: A et B
  final Map<String, SignatureConducteur> signatures; // Case 15: A et B

  // Section 13 - Croquis collaboratif
  final String? croquisFileId;
  final Map<String, dynamic>? croquisData;

  // Section 14 - Observations communes
  final String observations;

  // Photos/vidéos communes avec métadonnées
  final List<PhotoMetadata> photos;

  // Gestion collaborative
  final int nombreParticipants; // Nombre total de véhicules impliqués
  final List<String> rolesDisponibles; // ['A', 'B', 'C', 'D'...]
  final DateTime deadlineDeclaration; // Délai légal (5 jours ouvrés)
  final bool declarationUnilaterale; // Si une partie refuse de signer

  // Métadonnées
  final DateTime dateCreation;
  final DateTime dateModification;

  AccidentSession({
    required this.id,
    required this.codePublic,
    required this.createurUserId,
    required this.createurVehiculeId,
    required this.statut,
    required this.dateOuverture,
    this.dateAccident,
    this.heureAccident,
    required this.localisation,
    required this.blesses,
    required this.degatsAutres,
    required this.temoins,
    required this.identitesVehicules,
    required this.pointsChocInitial,
    required this.degatsApparents,
    required this.circonstances,
    required this.observationsVehicules,
    required this.signatures,
    this.croquisFileId,
    this.croquisData,
    required this.observations,
    required this.photos,
    required this.nombreParticipants,
    required this.rolesDisponibles,
    required this.deadlineDeclaration,
    required this.declarationUnilaterale,
    required this.dateCreation,
    required this.dateModification,
  });

  /// 🔄 États de la state machine (11 états selon spécifications)
  static const String STATUT_BROUILLON = 'brouillon';
  static const String STATUT_EN_ATTENTE_INVITES = 'en_attente_invites';
  static const String STATUT_PARTIES_EN_SAISIE = 'parties_en_saisie';
  static const String STATUT_PRET_A_SIGNER = 'pret_a_signer';
  static const String STATUT_SIGNATURE_EN_COURS = 'signature_en_cours';
  static const String STATUT_SIGNE_VALIDE = 'signe_valide';
  static const String STATUT_TRANSMIS_AUX_ASSUREURS = 'transmis_aux_assureurs';
  static const String STATUT_RETOUR_POUR_COMPLEMENT = 'retour_pour_complement';
  static const String STATUT_SOUS_EXPERTISE = 'sous_expertise';
  static const String STATUT_INDEMNISE = 'indemnise';
  static const String STATUT_CLOTURE = 'cloture';
  static const String STATUT_REFUS_DE_SIGNER = 'refus_de_signer';

  factory AccidentSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AccidentSession(
      id: doc.id,
      codePublic: data['codePublic'] ?? '',
      createurUserId: data['createurUserId'] ?? '',
      createurVehiculeId: data['createurVehiculeId'] ?? '',
      statut: data['statut'] ?? STATUT_BROUILLON,
      dateOuverture: (data['dateOuverture'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateAccident: data['dateAccident'] != null
          ? (data['dateAccident'] as Timestamp).toDate()
          : null,
      heureAccident: data['heureAccident'] != null
          ? TimeOfDay(
              hour: data['heureAccident']['hour'] ?? 0,
              minute: data['heureAccident']['minute'] ?? 0,
            )
          : null,
      localisation: Map<String, dynamic>.from(data['localisation'] ?? {}),
      blesses: data['blesses'] ?? false,
      degatsAutres: data['degatsAutres'] ?? false,
      temoins: (data['temoins'] as List<dynamic>?)
          ?.map((t) => Temoin.fromMap(t as Map<String, dynamic>))
          .toList() ?? [],
      identitesVehicules: (data['identitesVehicules'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, IdentiteVehicule.fromMap(value as Map<String, dynamic>))) ?? {},
      pointsChocInitial: (data['pointsChocInitial'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value != null ? PointChocInitial.fromMap(value as Map<String, dynamic>) : null)) ?? {},
      degatsApparents: (data['degatsApparents'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, DegatsApparents.fromMap(value as Map<String, dynamic>))) ?? {},
      circonstances: (data['circonstances'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, CirconstancesAccident.fromMap(value as Map<String, dynamic>))) ?? {},
      observationsVehicules: Map<String, String>.from(data['observationsVehicules'] ?? {}),
      signatures: (data['signatures'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, SignatureConducteur.fromMap(value as Map<String, dynamic>))) ?? {},
      croquisFileId: data['croquisFileId'],
      croquisData: data['croquisData'] != null
          ? Map<String, dynamic>.from(data['croquisData'])
          : null,
      observations: data['observations'] ?? '',
      photos: (data['photos'] as List<dynamic>?)
          ?.map((p) => PhotoMetadata.fromMap(p as Map<String, dynamic>))
          .toList() ?? [],
      nombreParticipants: data['nombreParticipants'] ?? 2,
      rolesDisponibles: List<String>.from(data['rolesDisponibles'] ?? ['A', 'B']),
      deadlineDeclaration: (data['deadlineDeclaration'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 5)),
      declarationUnilaterale: data['declarationUnilaterale'] ?? false,
      dateCreation: (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateModification: (data['dateModification'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'codePublic': codePublic,
      'createurUserId': createurUserId,
      'createurVehiculeId': createurVehiculeId,
      'statut': statut,
      'dateOuverture': Timestamp.fromDate(dateOuverture),
      'dateAccident': dateAccident != null
          ? Timestamp.fromDate(dateAccident!)
          : null,
      'heureAccident': heureAccident != null
          ? {
              'hour': heureAccident!.hour,
              'minute': heureAccident!.minute,
            }
          : null,
      'localisation': localisation,
      'blesses': blesses,
      'degatsAutres': degatsAutres,
      'temoins': temoins.map((t) => t.toMap()).toList(),
      'identitesVehicules': identitesVehicules.map((key, value) => MapEntry(key, value.toMap())),
      'pointsChocInitial': pointsChocInitial.map((key, value) => MapEntry(key, value?.toMap())),
      'degatsApparents': degatsApparents.map((key, value) => MapEntry(key, value.toMap())),
      'circonstances': circonstances.map((key, value) => MapEntry(key, value.toMap())),
      'observationsVehicules': observationsVehicules,
      'signatures': signatures.map((key, value) => MapEntry(key, value.toMap())),
      'croquisFileId': croquisFileId,
      'croquisData': croquisData,
      'observations': observations,
      'photos': photos.map((p) => p.toMap()).toList(),
      'nombreParticipants': nombreParticipants,
      'rolesDisponibles': rolesDisponibles,
      'deadlineDeclaration': Timestamp.fromDate(deadlineDeclaration),
      'declarationUnilaterale': declarationUnilaterale,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'dateModification': Timestamp.fromDate(dateModification),
    };
  }

  AccidentSession copyWith({
    String? id,
    String? codePublic,
    String? createurUserId,
    String? createurVehiculeId,
    String? statut,
    DateTime? dateOuverture,
    DateTime? dateAccident,
    TimeOfDay? heureAccident,
    Map<String, dynamic>? localisation,
    bool? blesses,
    bool? degatsAutres,
    List<Temoin>? temoins,
    Map<String, IdentiteVehicule>? identitesVehicules,
    Map<String, PointChocInitial?>? pointsChocInitial,
    Map<String, DegatsApparents>? degatsApparents,
    Map<String, CirconstancesAccident>? circonstances,
    Map<String, String>? observationsVehicules,
    Map<String, SignatureConducteur>? signatures,
    String? croquisFileId,
    Map<String, dynamic>? croquisData,
    String? observations,
    List<PhotoMetadata>? photos,
    int? nombreParticipants,
    List<String>? rolesDisponibles,
    DateTime? deadlineDeclaration,
    bool? declarationUnilaterale,
    DateTime? dateCreation,
    DateTime? dateModification,
  }) {
    return AccidentSession(
      id: id ?? this.id,
      codePublic: codePublic ?? this.codePublic,
      createurUserId: createurUserId ?? this.createurUserId,
      createurVehiculeId: createurVehiculeId ?? this.createurVehiculeId,
      statut: statut ?? this.statut,
      dateOuverture: dateOuverture ?? this.dateOuverture,
      dateAccident: dateAccident ?? this.dateAccident,
      heureAccident: heureAccident ?? this.heureAccident,
      localisation: localisation ?? this.localisation,
      blesses: blesses ?? this.blesses,
      degatsAutres: degatsAutres ?? this.degatsAutres,
      temoins: temoins ?? this.temoins,
      identitesVehicules: identitesVehicules ?? this.identitesVehicules,
      pointsChocInitial: pointsChocInitial ?? this.pointsChocInitial,
      degatsApparents: degatsApparents ?? this.degatsApparents,
      circonstances: circonstances ?? this.circonstances,
      observationsVehicules: observationsVehicules ?? this.observationsVehicules,
      signatures: signatures ?? this.signatures,
      croquisFileId: croquisFileId ?? this.croquisFileId,
      croquisData: croquisData ?? this.croquisData,
      observations: observations ?? this.observations,
      photos: photos ?? this.photos,
      nombreParticipants: nombreParticipants ?? this.nombreParticipants,
      rolesDisponibles: rolesDisponibles ?? this.rolesDisponibles,
      deadlineDeclaration: deadlineDeclaration ?? this.deadlineDeclaration,
      declarationUnilaterale: declarationUnilaterale ?? this.declarationUnilaterale,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
    );
  }

  /// Génère un code public unique pour la session
  static String generateCodePublic() {
    final now = DateTime.now();
    final year = now.year;
    final timestamp = now.millisecondsSinceEpoch.toString().substring(8);
    return 'ACC-$year-$timestamp';
  }

  /// Vérifie si la session est dans les délais légaux
  bool get isInLegalDeadline => DateTime.now().isBefore(deadlineDeclaration);

  /// Vérifie si la session peut être modifiée
  bool get canBeModified => [
    STATUT_BROUILLON,
    STATUT_EN_ATTENTE_INVITES,
    STATUT_PARTIES_EN_SAISIE,
    STATUT_RETOUR_POUR_COMPLEMENT,
  ].contains(statut);

  /// Vérifie si la session est signée par toutes les parties
  bool get isFullySigned => statut == STATUT_SIGNE_VALIDE;
}

/// 👤 Modèle pour un témoin (case 5)
class Temoin {
  final String nom;
  final String prenom;
  final String adresse;
  final String telephone;

  Temoin({
    required this.nom,
    required this.prenom,
    required this.adresse,
    required this.telephone,
  });

  factory Temoin.fromMap(Map<String, dynamic> map) {
    return Temoin(
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      adresse: map['adresse'] ?? '',
      telephone: map['telephone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'prenom': prenom,
      'adresse': adresse,
      'telephone': telephone,
    };
  }
}

/// 📸 Métadonnées pour les photos avec EXIF et watermark
class PhotoMetadata {
  final String fileId;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String? deviceInfo;
  final String watermark;
  final String type; // 'avant', 'arriere', 'cote_gauche', 'cote_droit', 'plaque', 'degats', 'general'

  PhotoMetadata({
    required this.fileId,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.deviceInfo,
    required this.watermark,
    required this.type,
  });

  factory PhotoMetadata.fromMap(Map<String, dynamic> map) {
    return PhotoMetadata(
      fileId: map['fileId'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      deviceInfo: map['deviceInfo'],
      watermark: map['watermark'] ?? '',
      type: map['type'] ?? 'general',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fileId': fileId,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'deviceInfo': deviceInfo,
      'watermark': watermark,
      'type': type,
    };
  }
}
