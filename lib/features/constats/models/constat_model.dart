import 'package:cloud_firestore/cloud_firestore.dart';

/// 📋 Modèle pour un constat d'accident
class ConstatModel {
  final String id;
  final String numeroConstat;
  final String type; // individuel, collaboratif
  final String statut; // brouillon, en_cours, termine, valide, expertise
  final AccidentInfo accident;
  final List<VehiculeConstatInfo> vehicules;
  final AnalyseIAInfo? analyseIA;
  final WorkflowInfo workflow;
  final AssignationInfo? assignation;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConstatModel({
    required this.id,
    required this.numeroConstat,
    required this.type,
    required this.statut,
    required this.accident,
    required this.vehicules,
    this.analyseIA,
    required this.workflow,
    this.assignation,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Liste des participants (conducteurs)
  List<String> get participants {
    return vehicules.map((v) => v.conducteurId).toList();
  }

  /// Vérifie si un utilisateur peut accéder au constat
  bool canUserAccess(String userId, String userRole) {
    if (userRole == 'assureur' || userRole == 'expert') return true;
    return participants.contains(userId);
  }

  Map<String, dynamic> toMap() {
    return {
      'numero_constat': numeroConstat,
      'type': type,
      'statut': statut,
      'accident': accident.toMap(),
      'vehicules': vehicules.map((v) => v.toMap()).toList(),
      'analyse_ia': analyseIA?.toMap(),
      'workflow': workflow.toMap(),
      'assignation': assignation?.toMap(),
      'participants': participants,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  factory ConstatModel.fromMap(Map<String, dynamic> map, String docId) {
    return ConstatModel(
      id: docId,
      numeroConstat: map['numero_constat'] ?? '',
      type: map['type'] ?? 'individuel',
      statut: map['statut'] ?? 'brouillon',
      accident: AccidentInfo.fromMap(map['accident'] ?? {}),
      vehicules: (map['vehicules'] as List<dynamic>?)
          ?.map((v) => VehiculeConstatInfo.fromMap(v))
          .toList() ?? [],
      analyseIA: map['analyse_ia'] != null 
          ? AnalyseIAInfo.fromMap(map['analyse_ia']) 
          : null,
      workflow: WorkflowInfo.fromMap(map['workflow'] ?? {}),
      assignation: map['assignation'] != null 
          ? AssignationInfo.fromMap(map['assignation']) 
          : null,
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// 💥 Informations de l'accident
class AccidentInfo {
  final DateTime date;
  final String heure;
  final LieuInfo lieu;
  final ConditionsInfo conditions;

  AccidentInfo({
    required this.date,
    required this.heure,
    required this.lieu,
    required this.conditions,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'heure': heure,
      'lieu': lieu.toMap(),
      'conditions': conditions.toMap(),
    };
  }

  factory AccidentInfo.fromMap(Map<String, dynamic> map) {
    return AccidentInfo(
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      heure: map['heure'] ?? '',
      lieu: LieuInfo.fromMap(map['lieu'] ?? {}),
      conditions: ConditionsInfo.fromMap(map['conditions'] ?? {}),
    );
  }
}

/// 📍 Informations du lieu
class LieuInfo {
  final String adresse;
  final double latitude;
  final double longitude;

  LieuInfo({
    required this.adresse,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'adresse': adresse,
      'coordonnees': {
        'latitude': latitude,
        'longitude': longitude,
      },
    };
  }

  factory LieuInfo.fromMap(Map<String, dynamic> map) {
    final coordonnees = map['coordonnees'] ?? {};
    return LieuInfo(
      adresse: map['adresse'] ?? '',
      latitude: (coordonnees['latitude'] ?? 0.0).toDouble(),
      longitude: (coordonnees['longitude'] ?? 0.0).toDouble(),
    );
  }
}

/// 🌤️ Conditions de l'accident
class ConditionsInfo {
  final String meteo;
  final String visibilite;
  final String etatRoute;

  ConditionsInfo({
    required this.meteo,
    required this.visibilite,
    required this.etatRoute,
  });

  Map<String, dynamic> toMap() {
    return {
      'meteo': meteo,
      'visibilite': visibilite,
      'etat_route': etatRoute,
    };
  }

  factory ConditionsInfo.fromMap(Map<String, dynamic> map) {
    return ConditionsInfo(
      meteo: map['meteo'] ?? '',
      visibilite: map['visibilite'] ?? '',
      etatRoute: map['etat_route'] ?? '',
    );
  }
}

/// 🚗 Informations véhicule dans le constat
class VehiculeConstatInfo {
  final String vehiculeId;
  final String conducteurId;
  final String assureurId;
  final String numeroContrat;
  final DegatsInfo degats;
  final int responsabilite; // Pourcentage 0-100

  VehiculeConstatInfo({
    required this.vehiculeId,
    required this.conducteurId,
    required this.assureurId,
    required this.numeroContrat,
    required this.degats,
    required this.responsabilite,
  });

  Map<String, dynamic> toMap() {
    return {
      'vehicule_id': vehiculeId,
      'conducteur_id': conducteurId,
      'assureur_id': assureurId,
      'numero_contrat': numeroContrat,
      'degats': degats.toMap(),
      'responsabilite': responsabilite,
    };
  }

  factory VehiculeConstatInfo.fromMap(Map<String, dynamic> map) {
    return VehiculeConstatInfo(
      vehiculeId: map['vehicule_id'] ?? '',
      conducteurId: map['conducteur_id'] ?? '',
      assureurId: map['assureur_id'] ?? '',
      numeroContrat: map['numero_contrat'] ?? '',
      degats: DegatsInfo.fromMap(map['degats'] ?? {}),
      responsabilite: map['responsabilite'] ?? 0,
    );
  }
}

/// 🔧 Informations des dégâts
class DegatsInfo {
  final String description;
  final String gravite; // leger, moyen, grave
  final List<String> photos;
  final double estimationCout;

  DegatsInfo({
    required this.description,
    required this.gravite,
    required this.photos,
    required this.estimationCout,
  });

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'gravite': gravite,
      'photos': photos,
      'estimation_cout': estimationCout,
    };
  }

  factory DegatsInfo.fromMap(Map<String, dynamic> map) {
    return DegatsInfo(
      description: map['description'] ?? '',
      gravite: map['gravite'] ?? 'moyen',
      photos: List<String>.from(map['photos'] ?? []),
      estimationCout: (map['estimation_cout'] ?? 0).toDouble(),
    );
  }
}

/// 🧠 Informations analyse IA
class AnalyseIAInfo {
  final List<String> photosAnalysees;
  final int vehiculesDetectes;
  final Map<String, String> degatsEstimes;
  final String scenarioProbable;
  final double confidenceScore;

  AnalyseIAInfo({
    required this.photosAnalysees,
    required this.vehiculesDetectes,
    required this.degatsEstimes,
    required this.scenarioProbable,
    required this.confidenceScore,
  });

  Map<String, dynamic> toMap() {
    return {
      'photos_analysees': photosAnalysees,
      'vehicules_detectes': vehiculesDetectes,
      'degats_estimes': degatsEstimes,
      'scenario_probable': scenarioProbable,
      'confidence_score': confidenceScore,
    };
  }

  factory AnalyseIAInfo.fromMap(Map<String, dynamic> map) {
    return AnalyseIAInfo(
      photosAnalysees: List<String>.from(map['photos_analysees'] ?? []),
      vehiculesDetectes: map['vehicules_detectes'] ?? 0,
      degatsEstimes: Map<String, String>.from(map['degats_estimes'] ?? {}),
      scenarioProbable: map['scenario_probable'] ?? '',
      confidenceScore: (map['confidence_score'] ?? 0.0).toDouble(),
    );
  }
}

/// 🔄 Informations workflow
class WorkflowInfo {
  final String etapeActuelle;
  final List<EtapeHistorique> historique;

  WorkflowInfo({
    required this.etapeActuelle,
    required this.historique,
  });

  Map<String, dynamic> toMap() {
    return {
      'etape_actuelle': etapeActuelle,
      'historique': historique.map((e) => e.toMap()).toList(),
    };
  }

  factory WorkflowInfo.fromMap(Map<String, dynamic> map) {
    return WorkflowInfo(
      etapeActuelle: map['etape_actuelle'] ?? 'remplissage',
      historique: (map['historique'] as List<dynamic>?)
          ?.map((e) => EtapeHistorique.fromMap(e))
          .toList() ?? [],
    );
  }
}

/// 📝 Étape historique du workflow
class EtapeHistorique {
  final String etape;
  final DateTime date;
  final String userId;
  final String action;

  EtapeHistorique({
    required this.etape,
    required this.date,
    required this.userId,
    required this.action,
  });

  Map<String, dynamic> toMap() {
    return {
      'etape': etape,
      'date': Timestamp.fromDate(date),
      'user_id': userId,
      'action': action,
    };
  }

  factory EtapeHistorique.fromMap(Map<String, dynamic> map) {
    return EtapeHistorique(
      etape: map['etape'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: map['user_id'] ?? '',
      action: map['action'] ?? '',
    );
  }
}

/// 👨‍🔧 Informations assignation expert
class AssignationInfo {
  final String expertId;
  final DateTime dateAssignation;
  final String priorite; // urgente, normale, faible

  AssignationInfo({
    required this.expertId,
    required this.dateAssignation,
    required this.priorite,
  });

  Map<String, dynamic> toMap() {
    return {
      'expert_id': expertId,
      'date_assignation': Timestamp.fromDate(dateAssignation),
      'priorite': priorite,
    };
  }

  factory AssignationInfo.fromMap(Map<String, dynamic> map) {
    return AssignationInfo(
      expertId: map['expert_id'] ?? '',
      dateAssignation: (map['date_assignation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      priorite: map['priorite'] ?? 'normale',
    );
  }
}
