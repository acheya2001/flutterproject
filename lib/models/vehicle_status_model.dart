import 'package:cloud_firestore/cloud_firestore.dart';

/// 📊 Modèle pour le suivi des statuts de véhicule
class VehicleStatusModel {
  final String vehicleId;
  final String conducteurId;
  final String currentStatus;
  final String? agentId;
  final String? agentNom;
  final String? agenceId;
  final String? agenceNom;
  final String? rejectionReason;
  final DateTime lastUpdated;
  final List<StatusHistoryEntry> history;

  VehicleStatusModel({
    required this.vehicleId,
    required this.conducteurId,
    required this.currentStatus,
    this.agentId,
    this.agentNom,
    this.agenceId,
    this.agenceNom,
    this.rejectionReason,
    required this.lastUpdated,
    required this.history,
  });

  factory VehicleStatusModel.fromMap(Map<String, dynamic> data) {
    return VehicleStatusModel(
      vehicleId: data['vehicleId'] ?? '',
      conducteurId: data['conducteurId'] ?? '',
      currentStatus: data['currentStatus'] ?? '',
      agentId: data['agentId'],
      agentNom: data['agentNom'],
      agenceId: data['agenceId'],
      agenceNom: data['agenceNom'],
      rejectionReason: data['rejectionReason'],
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      history: (data['history'] as List<dynamic>?)
          ?.map((item) => StatusHistoryEntry.fromMap(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'conducteurId': conducteurId,
      'currentStatus': currentStatus,
      'agentId': agentId,
      'agentNom': agentNom,
      'agenceId': agenceId,
      'agenceNom': agenceNom,
      'rejectionReason': rejectionReason,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'history': history.map((entry) => entry.toMap()).toList(),
    };
  }
}

/// 📝 Entrée d'historique de statut
class StatusHistoryEntry {
  final String status;
  final DateTime timestamp;
  final String? actorId;
  final String? actorName;
  final String? actorRole;
  final String? comment;
  final String? reason;

  StatusHistoryEntry({
    required this.status,
    required this.timestamp,
    this.actorId,
    this.actorName,
    this.actorRole,
    this.comment,
    this.reason,
  });

  factory StatusHistoryEntry.fromMap(Map<String, dynamic> data) {
    return StatusHistoryEntry(
      status: data['status'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      actorId: data['actorId'],
      actorName: data['actorName'],
      actorRole: data['actorRole'],
      comment: data['comment'],
      reason: data['reason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'actorId': actorId,
      'actorName': actorName,
      'actorRole': actorRole,
      'comment': comment,
      'reason': reason,
    };
  }
}

/// 🏷️ Statuts possibles pour un véhicule
class VehicleStatus {
  static const String enAttente = 'En attente';
  static const String affecteAgent = 'Affecté à Agent';
  static const String contratCree = 'Contrat Créé';
  static const String documentsRequis = 'Documents Demandés';
  static const String traiteAgent = 'Traité par Agent';
  static const String rejete = 'Rejeté';
  static const String annule = 'Annulé';

  static const List<String> allStatuses = [
    enAttente,
    affecteAgent,
    contratCree,
    documentsRequis,
    traiteAgent,
    rejete,
    annule,
  ];

  /// 🎨 Couleur associée au statut
  static String getStatusColor(String status) {
    switch (status) {
      case enAttente:
        return 'orange';
      case affecteAgent:
        return 'blue';
      case contratCree:
        return 'green';
      case documentsRequis:
        return 'purple';
      case traiteAgent:
        return 'teal';
      case rejete:
        return 'red';
      case annule:
        return 'grey';
      default:
        return 'grey';
    }
  }

  /// 📝 Description du statut
  static String getStatusDescription(String status) {
    switch (status) {
      case enAttente:
        return 'Votre demande est en cours d\'examen par l\'agence';
      case affecteAgent:
        return 'Votre dossier a été affecté à un agent pour traitement';
      case contratCree:
        return 'Votre contrat d\'assurance a été créé avec succès';
      case documentsRequis:
        return 'Des documents supplémentaires sont requis';
      case traiteAgent:
        return 'Votre dossier a été traité par l\'agent';
      case rejete:
        return 'Votre demande a été rejetée';
      case annule:
        return 'Votre demande a été annulée';
      default:
        return 'Statut inconnu';
    }
  }

  /// 🔄 Étape suivante possible
  static String? getNextStep(String status) {
    switch (status) {
      case enAttente:
        return 'Affectation à un agent';
      case affecteAgent:
        return 'Création du contrat';
      case documentsRequis:
        return 'Envoi des documents';
      case contratCree:
        return 'Contrat finalisé';
      default:
        return null;
    }
  }
}
