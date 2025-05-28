import 'conducteur_session_info.dart';

class SessionConstatModel {
  final String id;
  final String sessionCode;
  final DateTime dateAccident;
  final String lieuAccident;
  final Map<String, dynamic>? coordonnees;
  final int nombreConducteurs;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SessionStatus status;
  final Map<String, ConducteurSessionInfo> conducteursInfo;
  final List<String> invitationsSent;
  final Map<String, bool> validationStatus;

  SessionConstatModel({
    required this.id,
    required this.sessionCode,
    required this.dateAccident,
    required this.lieuAccident,
    this.coordonnees,
    required this.nombreConducteurs,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.conducteursInfo,
    required this.invitationsSent,
    required this.validationStatus,
  });

  SessionConstatModel copyWith({
    String? id,
    String? sessionCode,
    DateTime? dateAccident,
    String? lieuAccident,
    Map<String, dynamic>? coordonnees,
    int? nombreConducteurs,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    SessionStatus? status,
    Map<String, ConducteurSessionInfo>? conducteursInfo,
    List<String>? invitationsSent,
    Map<String, bool>? validationStatus,
  }) {
    return SessionConstatModel(
      id: id ?? this.id,
      sessionCode: sessionCode ?? this.sessionCode,
      dateAccident: dateAccident ?? this.dateAccident,
      lieuAccident: lieuAccident ?? this.lieuAccident,
      coordonnees: coordonnees ?? this.coordonnees,
      nombreConducteurs: nombreConducteurs ?? this.nombreConducteurs,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      conducteursInfo: conducteursInfo ?? this.conducteursInfo,
      invitationsSent: invitationsSent ?? this.invitationsSent,
      validationStatus: validationStatus ?? this.validationStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionCode': sessionCode,
      'dateAccident': dateAccident.toIso8601String(),
      'lieuAccident': lieuAccident,
      'coordonnees': coordonnees,
      'nombreConducteurs': nombreConducteurs,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.toString(),
      'conducteursInfo': conducteursInfo.map((key, value) => MapEntry(key, value.toJson())),
      'invitationsSent': invitationsSent,
      'validationStatus': validationStatus,
    };
  }

  factory SessionConstatModel.fromJson(Map<String, dynamic> json) {
    return SessionConstatModel(
      id: json['id'] ?? '',
      sessionCode: json['sessionCode'] ?? '',
      dateAccident: DateTime.parse(json['dateAccident']),
      lieuAccident: json['lieuAccident'] ?? '',
      coordonnees: json['coordonnees'],
      nombreConducteurs: json['nombreConducteurs'] ?? 2,
      createdBy: json['createdBy'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      status: SessionStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => SessionStatus.draft,
      ),
      conducteursInfo: (json['conducteursInfo'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, ConducteurSessionInfo.fromJson(value))),
      invitationsSent: List<String>.from(json['invitationsSent'] ?? []),
      validationStatus: Map<String, bool>.from(json['validationStatus'] ?? {}),
    );
  }
}

enum SessionStatus {
  draft,
  invitationsSent,
  inProgress,
  completed,
  cancelled
}
