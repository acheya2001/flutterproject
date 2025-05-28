import '../../../conducteur/models/conducteur_info_model.dart';
import '../../../conducteur/models/vehicule_accident_model.dart';
import '../../../conducteur/models/assurance_info_model.dart';
import 'proprietaire_info.dart';

class ConducteurSessionInfo {
  final String position; // A, B, C, D
  final String? userId;
  final String? email;
  final bool isInvited;
  final bool hasJoined;
  final bool isCompleted;
  final DateTime? joinedAt;
  final DateTime? completedAt;
  final ConducteurInfoModel? conducteurInfo;
  final VehiculeAccidentModel? vehiculeInfo;
  final AssuranceInfoModel? assuranceInfo;
  final bool isProprietaire;
  final ProprietaireInfo? proprietaireInfo;
  final List<int>? circonstances;
  final List<String>? degatsApparents;
  final String? observations;

  ConducteurSessionInfo({
    required this.position,
    this.userId,
    this.email,
    required this.isInvited,
    required this.hasJoined,
    required this.isCompleted,
    this.joinedAt,
    this.completedAt,
    this.conducteurInfo,
    this.vehiculeInfo,
    this.assuranceInfo,
    required this.isProprietaire,
    this.proprietaireInfo,
    this.circonstances,
    this.degatsApparents,
    this.observations,
  });

  ConducteurSessionInfo copyWith({
    String? position,
    String? userId,
    String? email,
    bool? isInvited,
    bool? hasJoined,
    bool? isCompleted,
    DateTime? joinedAt,
    DateTime? completedAt,
    ConducteurInfoModel? conducteurInfo,
    VehiculeAccidentModel? vehiculeInfo,
    AssuranceInfoModel? assuranceInfo,
    bool? isProprietaire,
    ProprietaireInfo? proprietaireInfo,
    List<int>? circonstances,
    List<String>? degatsApparents,
    String? observations,
  }) {
    return ConducteurSessionInfo(
      position: position ?? this.position,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      isInvited: isInvited ?? this.isInvited,
      hasJoined: hasJoined ?? this.hasJoined,
      isCompleted: isCompleted ?? this.isCompleted,
      joinedAt: joinedAt ?? this.joinedAt,
      completedAt: completedAt ?? this.completedAt,
      conducteurInfo: conducteurInfo ?? this.conducteurInfo,
      vehiculeInfo: vehiculeInfo ?? this.vehiculeInfo,
      assuranceInfo: assuranceInfo ?? this.assuranceInfo,
      isProprietaire: isProprietaire ?? this.isProprietaire,
      proprietaireInfo: proprietaireInfo ?? this.proprietaireInfo,
      circonstances: circonstances ?? this.circonstances,
      degatsApparents: degatsApparents ?? this.degatsApparents,
      observations: observations ?? this.observations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'userId': userId,
      'email': email,
      'isInvited': isInvited,
      'hasJoined': hasJoined,
      'isCompleted': isCompleted,
      'joinedAt': joinedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'conducteurInfo': conducteurInfo?.toJson(),
      'vehiculeInfo': vehiculeInfo?.toJson(),
      'assuranceInfo': assuranceInfo?.toJson(),
      'isProprietaire': isProprietaire,
      'proprietaireInfo': proprietaireInfo?.toJson(),
      'circonstances': circonstances,
      'degatsApparents': degatsApparents,
      'observations': observations,
    };
  }

  factory ConducteurSessionInfo.fromJson(Map<String, dynamic> json) {
    return ConducteurSessionInfo(
      position: json['position'] ?? '',
      userId: json['userId'],
      email: json['email'],
      isInvited: json['isInvited'] ?? false,
      hasJoined: json['hasJoined'] ?? false,
      isCompleted: json['isCompleted'] ?? false,
      joinedAt: json['joinedAt'] != null ? DateTime.parse(json['joinedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      conducteurInfo: json['conducteurInfo'] != null 
          ? ConducteurInfoModel.fromJson(json['conducteurInfo']) 
          : null,
      vehiculeInfo: json['vehiculeInfo'] != null 
          ? VehiculeAccidentModel.fromJson(json['vehiculeInfo']) 
          : null,
      assuranceInfo: json['assuranceInfo'] != null 
          ? AssuranceInfoModel.fromJson(json['assuranceInfo']) 
          : null,
      isProprietaire: json['isProprietaire'] ?? true,
      proprietaireInfo: json['proprietaireInfo'] != null 
          ? ProprietaireInfo.fromJson(json['proprietaireInfo']) 
          : null,
      circonstances: json['circonstances'] != null 
          ? List<int>.from(json['circonstances']) 
          : null,
      degatsApparents: json['degatsApparents'] != null 
          ? List<String>.from(json['degatsApparents']) 
          : null,
      observations: json['observations'],
    );
  }
}
