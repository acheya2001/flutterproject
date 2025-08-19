import 'package:cloud_firestore/cloud_firestore.dart';

/// 📋 Modèle pour le constat amiable officiel
class ConstatOfficielModel {
  final String id;
  final DateTime dateAccident;
  final String? heureAccident;
  final String? lieuAccident;
  final bool? blesses;
  final bool? degatsMateriels;
  final bool? temoins;
  final List<ConstatPartieModel> parties;
  final ConstatCroquisModel? croquis;
  final List<String> observations;
  final Map<String, dynamic> circumstances;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final String createdBy;
  final bool isCompleted;
  final bool isSigned;

  const ConstatOfficielModel({
    required this.id,
    required this.dateAccident,
    this.heureAccident,
    this.lieuAccident,
    this.blesses,
    this.degatsMateriels,
    this.temoins,
    required this.parties,
    this.croquis,
    required this.observations,
    required this.circumstances,
    required this.createdAt,
    required this.lastUpdatedAt,
    required this.createdBy,
    this.isCompleted = false,
    this.isSigned = false,
  });

  factory ConstatOfficielModel.fromMap(Map<String, dynamic> map) {
    return ConstatOfficielModel(
      id: map['id'] ?? '',
      dateAccident: (map['dateAccident'] as Timestamp).toDate(),
      heureAccident: map['heureAccident'],
      lieuAccident: map['lieuAccident'],
      blesses: map['blesses'],
      degatsMateriels: map['degatsMateriels'],
      temoins: map['temoins'],
      parties: (map['parties'] as List<dynamic>?)
          ?.map((p) => ConstatPartieModel.fromMap(p))
          .toList() ?? [],
      croquis: map['croquis'] != null ? ConstatCroquisModel.fromMap(map['croquis']) : null,
      observations: List<String>.from(map['observations'] ?? []),
      circumstances: Map<String, dynamic>.from(map['circumstances'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastUpdatedAt: (map['lastUpdatedAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      isSigned: map['isSigned'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateAccident': Timestamp.fromDate(dateAccident),
      'heureAccident': heureAccident,
      'lieuAccident': lieuAccident,
      'blesses': blesses,
      'degatsMateriels': degatsMateriels,
      'temoins': temoins,
      'parties': parties.map((p) => p.toMap()).toList(),
      'croquis': croquis?.toMap(),
      'observations': observations,
      'circumstances': circumstances,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
      'createdBy': createdBy,
      'isCompleted': isCompleted,
      'isSigned': isSigned,
    };
  }

  ConstatOfficielModel copyWith({
    String? id,
    DateTime? dateAccident,
    String? heureAccident,
    String? lieuAccident,
    bool? blesses,
    bool? degatsMateriels,
    bool? temoins,
    List<ConstatPartieModel>? parties,
    ConstatCroquisModel? croquis,
    List<String>? observations,
    Map<String, dynamic>? circumstances,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    String? createdBy,
    bool? isCompleted,
    bool? isSigned,
  }) {
    return ConstatOfficielModel(
      id: id ?? this.id,
      dateAccident: dateAccident ?? this.dateAccident,
      heureAccident: heureAccident ?? this.heureAccident,
      lieuAccident: lieuAccident ?? this.lieuAccident,
      blesses: blesses ?? this.blesses,
      degatsMateriels: degatsMateriels ?? this.degatsMateriels,
      temoins: temoins ?? this.temoins,
      parties: parties ?? this.parties,
      croquis: croquis ?? this.croquis,
      observations: observations ?? this.observations,
      circumstances: circumstances ?? this.circumstances,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      createdBy: createdBy ?? this.createdBy,
      isCompleted: isCompleted ?? this.isCompleted,
      isSigned: isSigned ?? this.isSigned,
    );
  }
}

/// 🚗 Partie du constat (Véhicule A, B, C...)
class ConstatPartieModel {
  final String partieId; // A, B, C...
  final String? conducteurUid;
  final bool isEditable; // Si le conducteur connecté peut modifier
  
  // Société d'Assurance
  final String? societeAssurance;
  final String? numeroContrat;
  final String? agence;
  final String? attestationValable;
  
  // Identité du Conducteur
  final String? nomConducteur;
  final String? prenomConducteur;
  final String? adresseConducteur;
  final String? telephoneConducteur;
  final String? permisNumero;
  final String? permisDelivreLe;
  final String? permisValableJusquau;
  final String? categoriePermis;
  
  // Identité du Véhicule
  final String? marqueVehicule;
  final String? typeVehicule;
  final String? numeroImmatriculation;
  final String? paysImmatriculation;
  final String? venantDe;
  final String? allantA;
  
  // Dégâts apparents
  final List<String> degatsApparents;
  
  // Observations
  final String? observations;
  
  // Signature
  final String? signature;
  final DateTime? signedAt;
  final bool isSigned;

  const ConstatPartieModel({
    required this.partieId,
    this.conducteurUid,
    this.isEditable = false,
    this.societeAssurance,
    this.numeroContrat,
    this.agence,
    this.attestationValable,
    this.nomConducteur,
    this.prenomConducteur,
    this.adresseConducteur,
    this.telephoneConducteur,
    this.permisNumero,
    this.permisDelivreLe,
    this.permisValableJusquau,
    this.categoriePermis,
    this.marqueVehicule,
    this.typeVehicule,
    this.numeroImmatriculation,
    this.paysImmatriculation,
    this.venantDe,
    this.allantA,
    required this.degatsApparents,
    this.observations,
    this.signature,
    this.signedAt,
    this.isSigned = false,
  });

  factory ConstatPartieModel.fromMap(Map<String, dynamic> map) {
    return ConstatPartieModel(
      partieId: map['partieId'] ?? '',
      conducteurUid: map['conducteurUid'],
      isEditable: map['isEditable'] ?? false,
      societeAssurance: map['societeAssurance'],
      numeroContrat: map['numeroContrat'],
      agence: map['agence'],
      attestationValable: map['attestationValable'],
      nomConducteur: map['nomConducteur'],
      prenomConducteur: map['prenomConducteur'],
      adresseConducteur: map['adresseConducteur'],
      telephoneConducteur: map['telephoneConducteur'],
      permisNumero: map['permisNumero'],
      permisDelivreLe: map['permisDelivreLe'],
      permisValableJusquau: map['permisValableJusquau'],
      categoriePermis: map['categoriePermis'],
      marqueVehicule: map['marqueVehicule'],
      typeVehicule: map['typeVehicule'],
      numeroImmatriculation: map['numeroImmatriculation'],
      paysImmatriculation: map['paysImmatriculation'],
      venantDe: map['venantDe'],
      allantA: map['allantA'],
      degatsApparents: List<String>.from(map['degatsApparents'] ?? []),
      observations: map['observations'],
      signature: map['signature'],
      signedAt: map['signedAt'] != null ? (map['signedAt'] as Timestamp).toDate() : null,
      isSigned: map['isSigned'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'partieId': partieId,
      'conducteurUid': conducteurUid,
      'isEditable': isEditable,
      'societeAssurance': societeAssurance,
      'numeroContrat': numeroContrat,
      'agence': agence,
      'attestationValable': attestationValable,
      'nomConducteur': nomConducteur,
      'prenomConducteur': prenomConducteur,
      'adresseConducteur': adresseConducteur,
      'telephoneConducteur': telephoneConducteur,
      'permisNumero': permisNumero,
      'permisDelivreLe': permisDelivreLe,
      'permisValableJusquau': permisValableJusquau,
      'categoriePermis': categoriePermis,
      'marqueVehicule': marqueVehicule,
      'typeVehicule': typeVehicule,
      'numeroImmatriculation': numeroImmatriculation,
      'paysImmatriculation': paysImmatriculation,
      'venantDe': venantDe,
      'allantA': allantA,
      'degatsApparents': degatsApparents,
      'observations': observations,
      'signature': signature,
      'signedAt': signedAt != null ? Timestamp.fromDate(signedAt!) : null,
      'isSigned': isSigned,
    };
  }

  ConstatPartieModel copyWith({
    String? partieId,
    String? conducteurUid,
    bool? isEditable,
    String? societeAssurance,
    String? numeroContrat,
    String? agence,
    String? attestationValable,
    String? nomConducteur,
    String? prenomConducteur,
    String? adresseConducteur,
    String? telephoneConducteur,
    String? permisNumero,
    String? permisDelivreLe,
    String? permisValableJusquau,
    String? categoriePermis,
    String? marqueVehicule,
    String? typeVehicule,
    String? numeroImmatriculation,
    String? paysImmatriculation,
    String? venantDe,
    String? allantA,
    List<String>? degatsApparents,
    String? observations,
    String? signature,
    DateTime? signedAt,
    bool? isSigned,
  }) {
    return ConstatPartieModel(
      partieId: partieId ?? this.partieId,
      conducteurUid: conducteurUid ?? this.conducteurUid,
      isEditable: isEditable ?? this.isEditable,
      societeAssurance: societeAssurance ?? this.societeAssurance,
      numeroContrat: numeroContrat ?? this.numeroContrat,
      agence: agence ?? this.agence,
      attestationValable: attestationValable ?? this.attestationValable,
      nomConducteur: nomConducteur ?? this.nomConducteur,
      prenomConducteur: prenomConducteur ?? this.prenomConducteur,
      adresseConducteur: adresseConducteur ?? this.adresseConducteur,
      telephoneConducteur: telephoneConducteur ?? this.telephoneConducteur,
      permisNumero: permisNumero ?? this.permisNumero,
      permisDelivreLe: permisDelivreLe ?? this.permisDelivreLe,
      permisValableJusquau: permisValableJusquau ?? this.permisValableJusquau,
      categoriePermis: categoriePermis ?? this.categoriePermis,
      marqueVehicule: marqueVehicule ?? this.marqueVehicule,
      typeVehicule: typeVehicule ?? this.typeVehicule,
      numeroImmatriculation: numeroImmatriculation ?? this.numeroImmatriculation,
      paysImmatriculation: paysImmatriculation ?? this.paysImmatriculation,
      venantDe: venantDe ?? this.venantDe,
      allantA: allantA ?? this.allantA,
      degatsApparents: degatsApparents ?? this.degatsApparents,
      observations: observations ?? this.observations,
      signature: signature ?? this.signature,
      signedAt: signedAt ?? this.signedAt,
      isSigned: isSigned ?? this.isSigned,
    );
  }
}

/// 🎨 Modèle pour le croquis de l'accident
class ConstatCroquisModel {
  final String? croquisData; // SVG ou base64
  final List<ConstatVehiculePosition> vehiculePositions;
  final String? description;

  const ConstatCroquisModel({
    this.croquisData,
    required this.vehiculePositions,
    this.description,
  });

  factory ConstatCroquisModel.fromMap(Map<String, dynamic> map) {
    return ConstatCroquisModel(
      croquisData: map['croquisData'],
      vehiculePositions: (map['vehiculePositions'] as List<dynamic>?)
          ?.map((v) => ConstatVehiculePosition.fromMap(v))
          .toList() ?? [],
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'croquisData': croquisData,
      'vehiculePositions': vehiculePositions.map((v) => v.toMap()).toList(),
      'description': description,
    };
  }
}

/// 🚗 Position d'un véhicule dans le croquis
class ConstatVehiculePosition {
  final String partieId; // A, B, C...
  final double x;
  final double y;
  final double rotation;
  final String color;

  const ConstatVehiculePosition({
    required this.partieId,
    required this.x,
    required this.y,
    required this.rotation,
    required this.color,
  });

  factory ConstatVehiculePosition.fromMap(Map<String, dynamic> map) {
    return ConstatVehiculePosition(
      partieId: map['partieId'] ?? '',
      x: (map['x'] ?? 0.0).toDouble(),
      y: (map['y'] ?? 0.0).toDouble(),
      rotation: (map['rotation'] ?? 0.0).toDouble(),
      color: map['color'] ?? '#FF0000',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'partieId': partieId,
      'x': x,
      'y': y,
      'rotation': rotation,
      'color': color,
    };
  }
}
