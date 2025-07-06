import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp
import 'package:equatable/equatable.dart';

// Corrected: Use models from the /conducteur/models/ path
import '../../conducteur/models/conducteur_info_model.dart';
import '../../conducteur/models/vehicule_accident_model.dart';
import '../../conducteur/models/assurance_info_model.dart';
import 'proprietaire_info.dart';
import 'temoin_model.dart';

class ConducteurSessionInfo extends Equatable {
  final String position;
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
  final List<TemoinModel>? temoins;
  final String? observations;
  final List<String>? photosAccidentUrls;
  final String? photoPermisUrl;
  final String? photoCarteGriseUrl;
  final String? photoAttestationUrl;
  final String? signatureUrl;

  const ConducteurSessionInfo({
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
    this.temoins,
    this.observations,
    this.photosAccidentUrls,
    this.photoPermisUrl,
    this.photoCarteGriseUrl,
    this.photoAttestationUrl,
    this.signatureUrl,
  });

  factory ConducteurSessionInfo.fromJson(Map<String, dynamic> json) {
    return ConducteurSessionInfo(
      position: json['position'] as String,
      userId: json['userId'] as String?,
      email: json['email'] as String?,
      isInvited: json['isInvited'] as bool? ?? false,
      hasJoined: json['hasJoined'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      joinedAt: (json['joinedAt'] as Timestamp?)?.toDate(),
      completedAt: (json['completedAt'] as Timestamp?)?.toDate(),
      conducteurInfo: json['conducteurInfo'] != null
          ? ConducteurInfoModel.fromJson(json['conducteurInfo'] as Map<String, dynamic>)
          : null,
      vehiculeInfo: json['vehiculeInfo'] != null
          ? VehiculeAccidentModel.fromJson(json['vehiculeInfo'] as Map<String, dynamic>)
          : null,
      assuranceInfo: json['assuranceInfo'] != null
          ? AssuranceInfoModel.fromJson(json['assuranceInfo'] as Map<String, dynamic>)
          : null,
      isProprietaire: json['isProprietaire'] as bool? ?? true,
      proprietaireInfo: json['proprietaireInfo'] != null
          ? ProprietaireInfo.fromJson(json['proprietaireInfo'] as Map<String, dynamic>)
          : null,
      circonstances: (json['circonstances'] as List<dynamic>?)?.map((e) => e as int).toList(),
      degatsApparents: (json['degatsApparents'] as List<dynamic>?)?.map((e) => e as String).toList(),
      temoins: (json['temoins'] as List<dynamic>?)
          ?.map((e) => TemoinModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      observations: json['observations'] as String?,
      photosAccidentUrls: (json['photosAccidentUrls'] as List<dynamic>?)?.map((e) => e as String).toList(),
      photoPermisUrl: json['photoPermisUrl'] as String?,
      photoCarteGriseUrl: json['photoCarteGriseUrl'] as String?,
      photoAttestationUrl: json['photoAttestationUrl'] as String?,
      signatureUrl: json['signatureUrl'] as String?,
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
      'joinedAt': joinedAt != null ? Timestamp.fromDate(joinedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'conducteurInfo': conducteurInfo?.toJson(),
      'vehiculeInfo': vehiculeInfo?.toJson(),
      'assuranceInfo': assuranceInfo?.toJson(),
      'isProprietaire': isProprietaire,
      'proprietaireInfo': proprietaireInfo?.toJson(),
      'circonstances': circonstances,
      'degatsApparents': degatsApparents,
      'temoins': temoins?.map((e) => e.toJson()).toList(),
      'observations': observations,
      'photosAccidentUrls': photosAccidentUrls,
      'photoPermisUrl': photoPermisUrl,
      'photoCarteGriseUrl': photoCarteGriseUrl,
      'photoAttestationUrl': photoAttestationUrl,
      'signatureUrl': signatureUrl,
    };
  }

  /// Alias pour toJson() - compatibilité Firestore
  Map<String, dynamic> toMap() => toJson();

  /// Alias pour fromJson() - compatibilité Firestore
  factory ConducteurSessionInfo.fromMap(Map<String, dynamic> map) =>
      ConducteurSessionInfo.fromJson(map);

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
    List<TemoinModel>? temoins,
    String? observations,
    List<String>? photosAccidentUrls,
    String? photoPermisUrl,
    String? photoCarteGriseUrl,
    String? photoAttestationUrl,
    String? signatureUrl,
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
      temoins: temoins ?? this.temoins,
      observations: observations ?? this.observations,
      photosAccidentUrls: photosAccidentUrls ?? this.photosAccidentUrls,
      photoPermisUrl: photoPermisUrl ?? this.photoPermisUrl,
      photoCarteGriseUrl: photoCarteGriseUrl ?? this.photoCarteGriseUrl,
      photoAttestationUrl: photoAttestationUrl ?? this.photoAttestationUrl,
      signatureUrl: signatureUrl ?? this.signatureUrl,
    );
  }

  @override
  List<Object?> get props => [
        position,
        userId,
        email,
        isInvited,
        hasJoined,
        isCompleted,
        joinedAt,
        completedAt,
        conducteurInfo,
        vehiculeInfo,
        assuranceInfo,
        isProprietaire,
        proprietaireInfo,
        circonstances,
        degatsApparents,
        temoins,
        observations,
        photosAccidentUrls,
        photoPermisUrl,
        photoCarteGriseUrl,
        photoAttestationUrl,
        signatureUrl,
      ];
}
