import 'package:cloud_firestore/cloud_firestore.dart';

/// 🎯 Modèle complet de session d'accident multi-conducteurs
class AccidentSessionComplete {
  final String id;
  final String codeSession;
  final String typeAccident;
  final int nombreVehicules;
  final String statut; // 'creation', 'attente_conducteurs', 'en_cours', 'complete', 'signe'
  final String conducteurCreateur;
  final List<ConducteurSession> conducteurs;
  final InfosGeneralesAccident infosGenerales;
  final List<VehiculeAccident> vehicules;
  final CirconstancesAccident circonstances;
  final CroquisAccident croquis;
  final List<String> photos;
  final Map<String, String> signatures;
  final DateTime dateCreation;
  final DateTime? dateModification;
  final DateTime? dateFinalisation;

  AccidentSessionComplete({
    required this.id,
    required this.codeSession,
    required this.typeAccident,
    required this.nombreVehicules,
    required this.statut,
    required this.conducteurCreateur,
    required this.conducteurs,
    required this.infosGenerales,
    required this.vehicules,
    required this.circonstances,
    required this.croquis,
    required this.photos,
    required this.signatures,
    required this.dateCreation,
    this.dateModification,
    this.dateFinalisation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codeSession': codeSession,
      'typeAccident': typeAccident,
      'nombreVehicules': nombreVehicules,
      'statut': statut,
      'conducteurCreateur': conducteurCreateur,
      'conducteurs': conducteurs.map((c) => c.toMap()).toList(),
      'infosGenerales': infosGenerales.toMap(),
      'vehicules': vehicules.map((v) => v.toMap()).toList(),
      'circonstances': circonstances.toMap(),
      'croquis': croquis.toMap(),
      'photos': photos,
      'signatures': signatures,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'dateModification': dateModification != null ? Timestamp.fromDate(dateModification!) : null,
      'dateFinalisation': dateFinalisation != null ? Timestamp.fromDate(dateFinalisation!) : null,
    };
  }

  factory AccidentSessionComplete.fromMap(Map<String, dynamic> map, String id) {
    try {
      return AccidentSessionComplete(
        id: id,
        codeSession: _safeGetString(map, 'codeSession'),
        typeAccident: _safeGetString(map, 'typeAccident'),
        nombreVehicules: _safeGetInt(map, 'nombreVehicules', 2),
        statut: _safeGetString(map, 'statut', 'creation'),
        conducteurCreateur: _safeGetString(map, 'conducteurCreateur'),
        conducteurs: _safeGetConducteursList(map['conducteurs']),
        infosGenerales: InfosGeneralesAccident.fromMap(_safeGetMap(map, 'infosGenerales')),
        vehicules: _safeGetVehiculesList(map['vehicules']),
        circonstances: CirconstancesAccident.fromMap(_safeGetMap(map, 'circonstances')),
        croquis: CroquisAccident.fromMap(_safeGetMap(map, 'croquis')),
        photos: _safeGetStringList(map['photos']),
        signatures: _safeGetStringMap(map['signatures']),
        dateCreation: _safeGetDateTime(map, 'dateCreation') ?? DateTime.now(),
        dateModification: _safeGetDateTime(map, 'dateModification'),
        dateFinalisation: _safeGetDateTime(map, 'dateFinalisation'),
      );
    } catch (e) {
      print('❌ Erreur conversion AccidentSessionComplete: $e');
      print('📋 Données reçues: $map');
      rethrow;
    }
  }

  // 🛡️ Méthodes utilitaires pour conversion sécurisée
  static String _safeGetString(Map<String, dynamic> map, String key, [String defaultValue = '']) {
    final value = map[key];
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }

  static int _safeGetInt(Map<String, dynamic> map, String key, [int defaultValue = 0]) {
    final value = map[key];
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static Map<String, dynamic> _safeGetMap(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return {};
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  static List<String> _safeGetStringList(dynamic value) {
    if (value == null) return [];
    if (value is List<String>) return value;
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  static Map<String, String> _safeGetStringMap(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, String>) return value;
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v.toString()));
    return {};
  }

  static List<ConducteurSession> _safeGetConducteursList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) {
        if (item is Map<String, dynamic>) {
          return ConducteurSession.fromMap(item);
        } else if (item is Map) {
          return ConducteurSession.fromMap(Map<String, dynamic>.from(item));
        }
        return null;
      }).where((item) => item != null).cast<ConducteurSession>().toList();
    }
    return [];
  }

  static List<VehiculeAccident> _safeGetVehiculesList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) {
        if (item is Map<String, dynamic>) {
          return VehiculeAccident.fromMap(item);
        } else if (item is Map) {
          return VehiculeAccident.fromMap(Map<String, dynamic>.from(item));
        }
        return null;
      }).where((item) => item != null).cast<VehiculeAccident>().toList();
    }
    return [];
  }

  static DateTime? _safeGetDateTime(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// 👤 Conducteur dans une session
class ConducteurSession {
  final String userId;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final String roleVehicule; // 'A', 'B', 'C', etc.
  final bool estCreateur;
  final bool aRejoint;
  final bool estInscrit; // true si conducteur inscrit, false si invité
  final DateTime? dateRejoint;

  ConducteurSession({
    required this.userId,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.roleVehicule,
    required this.estCreateur,
    required this.aRejoint,
    this.estInscrit = true,
    this.dateRejoint,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'roleVehicule': roleVehicule,
      'estCreateur': estCreateur,
      'aRejoint': aRejoint,
      'estInscrit': estInscrit,
      'dateRejoint': dateRejoint != null ? Timestamp.fromDate(dateRejoint!) : null,
    };
  }

  factory ConducteurSession.fromMap(Map<String, dynamic> map) {
    try {
      return ConducteurSession(
        userId: map['userId']?.toString() ?? '',
        nom: map['nom']?.toString() ?? '',
        prenom: map['prenom']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
        telephone: map['telephone']?.toString() ?? '',
        roleVehicule: map['roleVehicule']?.toString() ?? '',
        estCreateur: _safeBool(map['estCreateur']),
        aRejoint: _safeBool(map['aRejoint']),
        estInscrit: _safeBool(map['estInscrit'], true),
        dateRejoint: _safeDateTimeFromMap(map['dateRejoint']),
      );
    } catch (e) {
      print('❌ Erreur conversion ConducteurSession: $e');
      print('📋 Données: $map');
      rethrow;
    }
  }

  static bool _safeBool(dynamic value, [bool defaultValue = false]) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value != 0;
    return defaultValue;
  }

  static DateTime? _safeDateTimeFromMap(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// 📋 Informations générales de l'accident (selon constat papier)
class InfosGeneralesAccident {
  final DateTime dateAccident;
  final String heureAccident;
  final String lieuAccident;
  final String lieuGps;
  final bool blesses;
  final String detailsBlesses;
  final bool degatsMaterielsAutres;
  final String detailsDegatsAutres;
  final List<Temoin> temoins;

  InfosGeneralesAccident({
    required this.dateAccident,
    required this.heureAccident,
    required this.lieuAccident,
    required this.lieuGps,
    required this.blesses,
    required this.detailsBlesses,
    required this.degatsMaterielsAutres,
    required this.detailsDegatsAutres,
    required this.temoins,
  });

  Map<String, dynamic> toMap() {
    return {
      'dateAccident': Timestamp.fromDate(dateAccident),
      'heureAccident': heureAccident,
      'lieuAccident': lieuAccident,
      'lieuGps': lieuGps,
      'blesses': blesses,
      'detailsBlesses': detailsBlesses,
      'degatsMaterielsAutres': degatsMaterielsAutres,
      'detailsDegatsAutres': detailsDegatsAutres,
      'temoins': temoins.map((t) => t.toMap()).toList(),
    };
  }

  factory InfosGeneralesAccident.fromMap(Map<String, dynamic> map) {
    return InfosGeneralesAccident(
      dateAccident: map['dateAccident'] != null 
          ? (map['dateAccident'] as Timestamp).toDate()
          : DateTime.now(),
      heureAccident: map['heureAccident'] ?? '',
      lieuAccident: map['lieuAccident'] ?? '',
      lieuGps: map['lieuGps'] ?? '',
      blesses: map['blesses'] ?? false,
      detailsBlesses: map['detailsBlesses'] ?? '',
      degatsMaterielsAutres: map['degatsMaterielsAutres'] ?? false,
      detailsDegatsAutres: map['detailsDegatsAutres'] ?? '',
      temoins: (map['temoins'] as List<dynamic>?)
          ?.map((t) => Temoin.fromMap(t))
          .toList() ?? [],
    );
  }
}

/// 👁️ Témoin
class Temoin {
  final String nom;
  final String adresse;
  final String telephone;

  Temoin({
    required this.nom,
    required this.adresse,
    required this.telephone,
  });

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'adresse': adresse,
      'telephone': telephone,
    };
  }

  factory Temoin.fromMap(Map<String, dynamic> map) {
    return Temoin(
      nom: map['nom'] ?? '',
      adresse: map['adresse'] ?? '',
      telephone: map['telephone'] ?? '',
    );
  }
}

/// 🚗 Véhicule dans l'accident (selon constat papier)
class VehiculeAccident {
  final String roleVehicule; // 'A', 'B', 'C', etc.
  final String conducteurId;
  
  // Infos véhicule
  final String marque;
  final String modele;
  final String immatriculation;
  final String sensCirculation;
  final String pointChocInitial;
  final List<String> degatsApparents;
  
  // Infos assurance
  final String societeAssurance;
  final String numeroContrat;
  final String agence;
  final DateTime validiteAssuranceDebut;
  final DateTime validiteAssuranceFin;
  
  // Infos conducteur
  final String nomConducteur;
  final String prenomConducteur;
  final String adresseConducteur;
  final String numeroPermis;
  final DateTime dateDelivrancePermis;
  final String categoriePermis;
  
  // Infos assuré (si différent)
  final bool assureDifferent;
  final String nomAssure;
  final String prenomAssure;
  final String adresseAssure;

  VehiculeAccident({
    required this.roleVehicule,
    required this.conducteurId,
    required this.marque,
    required this.modele,
    required this.immatriculation,
    required this.sensCirculation,
    required this.pointChocInitial,
    required this.degatsApparents,
    required this.societeAssurance,
    required this.numeroContrat,
    required this.agence,
    required this.validiteAssuranceDebut,
    required this.validiteAssuranceFin,
    required this.nomConducteur,
    required this.prenomConducteur,
    required this.adresseConducteur,
    required this.numeroPermis,
    required this.dateDelivrancePermis,
    required this.categoriePermis,
    required this.assureDifferent,
    required this.nomAssure,
    required this.prenomAssure,
    required this.adresseAssure,
  });

  Map<String, dynamic> toMap() {
    return {
      'roleVehicule': roleVehicule,
      'conducteurId': conducteurId,
      'marque': marque,
      'modele': modele,
      'immatriculation': immatriculation,
      'sensCirculation': sensCirculation,
      'pointChocInitial': pointChocInitial,
      'degatsApparents': degatsApparents,
      'societeAssurance': societeAssurance,
      'numeroContrat': numeroContrat,
      'agence': agence,
      'validiteAssuranceDebut': Timestamp.fromDate(validiteAssuranceDebut),
      'validiteAssuranceFin': Timestamp.fromDate(validiteAssuranceFin),
      'nomConducteur': nomConducteur,
      'prenomConducteur': prenomConducteur,
      'adresseConducteur': adresseConducteur,
      'numeroPermis': numeroPermis,
      'dateDelivrancePermis': Timestamp.fromDate(dateDelivrancePermis),
      'categoriePermis': categoriePermis,
      'assureDifferent': assureDifferent,
      'nomAssure': nomAssure,
      'prenomAssure': prenomAssure,
      'adresseAssure': adresseAssure,
    };
  }

  factory VehiculeAccident.fromMap(Map<String, dynamic> map) {
    return VehiculeAccident(
      roleVehicule: map['roleVehicule'] ?? '',
      conducteurId: map['conducteurId'] ?? '',
      marque: map['marque'] ?? '',
      modele: map['modele'] ?? '',
      immatriculation: map['immatriculation'] ?? '',
      sensCirculation: map['sensCirculation'] ?? '',
      pointChocInitial: map['pointChocInitial'] ?? '',
      degatsApparents: List<String>.from(map['degatsApparents'] ?? []),
      societeAssurance: map['societeAssurance'] ?? '',
      numeroContrat: map['numeroContrat'] ?? '',
      agence: map['agence'] ?? '',
      validiteAssuranceDebut: map['validiteAssuranceDebut'] != null 
          ? (map['validiteAssuranceDebut'] as Timestamp).toDate()
          : DateTime.now(),
      validiteAssuranceFin: map['validiteAssuranceFin'] != null 
          ? (map['validiteAssuranceFin'] as Timestamp).toDate()
          : DateTime.now(),
      nomConducteur: map['nomConducteur'] ?? '',
      prenomConducteur: map['prenomConducteur'] ?? '',
      adresseConducteur: map['adresseConducteur'] ?? '',
      numeroPermis: map['numeroPermis'] ?? '',
      dateDelivrancePermis: map['dateDelivrancePermis'] != null 
          ? (map['dateDelivrancePermis'] as Timestamp).toDate()
          : DateTime.now(),
      categoriePermis: map['categoriePermis'] ?? '',
      assureDifferent: map['assureDifferent'] ?? false,
      nomAssure: map['nomAssure'] ?? '',
      prenomAssure: map['prenomAssure'] ?? '',
      adresseAssure: map['adresseAssure'] ?? '',
    );
  }
}

/// 📝 Circonstances de l'accident (selon constat papier)
class CirconstancesAccident {
  final Map<String, List<String>> circonstancesParVehicule; // roleVehicule -> liste des circonstances

  CirconstancesAccident({
    required this.circonstancesParVehicule,
  });

  Map<String, dynamic> toMap() {
    return {
      'circonstancesParVehicule': circonstancesParVehicule,
    };
  }

  factory CirconstancesAccident.fromMap(Map<String, dynamic> map) {
    return CirconstancesAccident(
      circonstancesParVehicule: Map<String, List<String>>.from(
        map['circonstancesParVehicule']?.map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ) ?? {},
      ),
    );
  }
}

/// 🎨 Croquis de l'accident
class CroquisAccident {
  final String croquisData; // JSON ou base64 du croquis
  final List<String> annotations;

  CroquisAccident({
    required this.croquisData,
    required this.annotations,
  });

  Map<String, dynamic> toMap() {
    return {
      'croquisData': croquisData,
      'annotations': annotations,
    };
  }

  factory CroquisAccident.fromMap(Map<String, dynamic> map) {
    return CroquisAccident(
      croquisData: map['croquisData'] ?? '',
      annotations: List<String>.from(map['annotations'] ?? []),
    );
  }
}
