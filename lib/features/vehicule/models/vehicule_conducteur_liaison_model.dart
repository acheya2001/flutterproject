import 'package:cloud_firestore/cloud_firestore.dart';

/// 📊 Statut de liaison véhicule-conducteur
enum LiaisonStatus {
  actif,
  suspendu,
  expire,
  annule,
}

extension LiaisonStatusExtension on LiaisonStatus {
  String get displayName {
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
    switch (value.toLowerCase()) {
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

/// 🔗 Modèle de liaison véhicule-conducteur
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
    required this.notificationEnvoyee,
    this.dateNotification,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VehiculeConducteurLiaisonModel.fromMap(Map<String, dynamic> data) {
    return VehiculeConducteurLiaisonModel(
      id: data['id'] ?? '',
      vehiculeId: data['vehicule_id'] ?? '',
      conducteurEmail: data['conducteur_email'] ?? '',
      conducteurId: data['conducteur_id'],
      agentAffecteur: data['agent_affecteur'] ?? '',
      agenceId: data['agence_id'] ?? '',
      compagnieId: data['compagnie_id'] ?? '',
      dateAffectation: (data['date_affectation'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicule_id': vehiculeId,
      'conducteur_email': conducteurEmail,
      'conducteur_id': conducteurId,
      'agent_affecteur': agentAffecteur,
      'agence_id': agenceId,
      'compagnie_id': compagnieId,
      'date_affectation': Timestamp.fromDate(dateAffectation),
      'date_expiration': dateExpiration != null ? Timestamp.fromDate(dateExpiration!) : null,
      'statut': statut.value,
      'droits': droits,
      'commentaire': commentaire,
      'notification_envoyee': notificationEnvoyee,
      'date_notification': dateNotification != null ? Timestamp.fromDate(dateNotification!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get estActif => statut == LiaisonStatus.actif;
  bool get estExpire => statut == LiaisonStatus.expire ||
      (dateExpiration != null && DateTime.now().isAfter(dateExpiration!));

  @override
  String toString() {
    return 'VehiculeConducteurLiaisonModel(id: $id, vehicule: $vehiculeId, conducteur: $conducteurEmail, statut: ${statut.name})';
  }
}

/// 🔑 Droits disponibles pour les conducteurs
class ConducteurDroits {
  static const String conduire = 'conduire';
  static const String declarerSinistre = 'declarer_sinistre';
  static const String modifierInfos = 'modifier_infos';
  static const String voirHistorique = 'voir_historique';
  static const String ajouterConducteur = 'ajouter_conducteur';

  /// Obtenir le nom français d'un droit
  static String getNomFrancais(String droit) {
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
  static String getIcone(String droit) {
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

  static List<String> get tousLesDroits => [
    conduire,
    declarerSinistre,
    modifierInfos,
    voirHistorique,
    ajouterConducteur,
  ];
}