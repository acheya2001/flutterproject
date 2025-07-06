import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔗 Statuts de liaison véhicule-conducteur
enum LiaisonStatus {
  actif,
  suspendu,
  expire,
  annule,
}

extension LiaisonStatusExtension on LiaisonStatus {
  String get name {
    switch (this) {
      case LiaisonStatus.actif:
        return 'Actif';
      case LiaisonStatus.suspendu:
        return 'Suspendu';
      case LiaisonStatus.expire:
        return 'Expiré';
      case LiaisonStatus.annule:
        return 'Annulé';
    }
  }

  String get value {
    switch (this) {
      case LiaisonStatus.actif:
        return 'actif';
      case LiaisonStatus.suspendu:
        return 'suspendu';
      case LiaisonStatus.expire:
        return 'expire';
      case LiaisonStatus.annule:
        return 'annule';
    }
  }

  static LiaisonStatus fromString(String value) {
    switch (value) {
      case 'actif':
        return LiaisonStatus.actif;
      case 'suspendu':
        return LiaisonStatus.suspendu;
      case 'expire':
        return LiaisonStatus.expire;
      case 'annule':
        return LiaisonStatus.annule;
      default:
        return LiaisonStatus.actif;
    }
  }
}

/// 🚗 Modèle de liaison véhicule-conducteur
class VehiculeConducteurLiaisonModel {
  final String id;
  final String vehiculeId;
  final String conducteurEmail;
  final String? conducteurId; // Rempli quand le conducteur s'inscrit
  final String agentAffecteur;
  final String agenceId;
  final String compagnieId;
  final DateTime dateAffectation;
  final DateTime? dateExpiration;
  final LiaisonStatus statut;
  final List<String> droits; // ['conduire', 'declarer_sinistre', 'modifier_infos']
  final String? commentaire;
  final bool notificationEnvoyee;
  final DateTime? dateNotification;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VehiculeConducteurLiaisonModel({
    required this.id,
    required this.vehiculeId,
    required this.conducteurEmail,
    this.conducteurId,
    required this.agentAffecteur,
    required this.agenceId,
    required this.compagnieId,
    required this.dateAffectation,
    this.dateExpiration,
    required this.statut,
    required this.droits,
    this.commentaire,
    this.notificationEnvoyee = false,
    this.dateNotification,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Créer depuis Firestore
  factory VehiculeConducteurLiaisonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VehiculeConducteurLiaisonModel(
      id: doc.id,
      vehiculeId: data['vehicule_id'] ?? '',
      conducteurEmail: data['conducteur_email'] ?? '',
      conducteurId: data['conducteur_id'],
      agentAffecteur: data['agent_affecteur'] ?? '',
      agenceId: data['agence_id'] ?? '',
      compagnieId: data['compagnie_id'] ?? '',
      dateAffectation: (data['date_affectation'] as Timestamp).toDate(),
      dateExpiration: data['date_expiration'] != null 
          ? (data['date_expiration'] as Timestamp).toDate()
          : null,
      statut: LiaisonStatusExtension.fromString(data['statut'] ?? 'actif'),
      droits: List<String>.from(data['droits'] ?? []),
      commentaire: data['commentaire'],
      notificationEnvoyee: data['notification_envoyee'] ?? false,
      dateNotification: data['date_notification'] != null 
          ? (data['date_notification'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'vehicule_id': vehiculeId,
      'conducteur_email': conducteurEmail,
      'conducteur_id': conducteurId,
      'agent_affecteur': agentAffecteur,
      'agence_id': agenceId,
      'compagnie_id': compagnieId,
      'date_affectation': Timestamp.fromDate(dateAffectation),
      'date_expiration': dateExpiration != null 
          ? Timestamp.fromDate(dateExpiration!)
          : null,
      'statut': statut.value,
      'droits': droits,
      'commentaire': commentaire,
      'notification_envoyee': notificationEnvoyee,
      'date_notification': dateNotification != null 
          ? Timestamp.fromDate(dateNotification!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copier avec modifications
  VehiculeConducteurLiaisonModel copyWith({
    String? id,
    String? vehiculeId,
    String? conducteurEmail,
    String? conducteurId,
    String? agentAffecteur,
    String? agenceId,
    String? compagnieId,
    DateTime? dateAffectation,
    DateTime? dateExpiration,
    LiaisonStatus? statut,
    List<String>? droits,
    String? commentaire,
    bool? notificationEnvoyee,
    DateTime? dateNotification,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehiculeConducteurLiaisonModel(
      id: id ?? this.id,
      vehiculeId: vehiculeId ?? this.vehiculeId,
      conducteurEmail: conducteurEmail ?? this.conducteurEmail,
      conducteurId: conducteurId ?? this.conducteurId,
      agentAffecteur: agentAffecteur ?? this.agentAffecteur,
      agenceId: agenceId ?? this.agenceId,
      compagnieId: compagnieId ?? this.compagnieId,
      dateAffectation: dateAffectation ?? this.dateAffectation,
      dateExpiration: dateExpiration ?? this.dateExpiration,
      statut: statut ?? this.statut,
      droits: droits ?? this.droits,
      commentaire: commentaire ?? this.commentaire,
      notificationEnvoyee: notificationEnvoyee ?? this.notificationEnvoyee,
      dateNotification: dateNotification ?? this.dateNotification,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Vérifier si la liaison est active
  bool get isActif => statut == LiaisonStatus.actif;

  /// Vérifier si la liaison est expirée
  bool get isExpire {
    if (dateExpiration == null) return false;
    return DateTime.now().isAfter(dateExpiration!);
  }

  /// Vérifier si le conducteur a un droit spécifique
  bool hasDroit(String droit) {
    return droits.contains(droit);
  }

  /// Obtenir les jours restants avant expiration
  int? get joursRestants {
    if (dateExpiration == null) return null;
    final difference = dateExpiration!.difference(DateTime.now());
    return difference.inDays;
  }

  /// Vérifier si la liaison expire bientôt (moins de 30 jours)
  bool get expireBientot {
    final jours = joursRestants;
    return jours != null && jours <= 30 && jours > 0;
  }

  @override
  String toString() {
    return 'VehiculeConducteurLiaisonModel(id: $id, vehicule: $vehiculeId, conducteur: $conducteurEmail, statut: ${statut.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VehiculeConducteurLiaisonModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 🔑 Droits disponibles pour les conducteurs
class ConducteurDroits {
  static const String conduire = 'conduire';
  static const String declarerSinistre = 'declarer_sinistre';
  static const String modifierInfos = 'modifier_infos';
  static const String voirHistorique = 'voir_historique';
  static const String ajouterConducteur = 'ajouter_conducteur';

  /// Obtenir tous les droits disponibles
  static List<String> get allDroits => [
    conduire,
    declarerSinistre,
    modifierInfos,
    voirHistorique,
    ajouterConducteur,
  ];

  /// Obtenir les droits par défaut
  static List<String> get defaultDroits => [
    conduire,
    declarerSinistre,
    voirHistorique,
  ];

  /// Obtenir le nom français d'un droit
  static String getDroitName(String droit) {
    switch (droit) {
      case conduire:
        return 'Conduire le véhicule';
      case declarerSinistre:
        return 'Déclarer un sinistre';
      case modifierInfos:
        return 'Modifier les informations';
      case voirHistorique:
        return 'Voir l\'historique';
      case ajouterConducteur:
        return 'Ajouter un conducteur';
      default:
        return droit;
    }
  }

  /// Obtenir l'icône d'un droit
  static String getDroitIcon(String droit) {
    switch (droit) {
      case conduire:
        return '🚗';
      case declarerSinistre:
        return '🚨';
      case modifierInfos:
        return '✏️';
      case voirHistorique:
        return '📋';
      case ajouterConducteur:
        return '👥';
      default:
        return '🔑';
    }
  }
}
