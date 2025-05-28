import 'package:cloud_firestore/cloud_firestore.dart';

class VehiculeAccidentModel {
  final String? id;
  final String marque;
  final String type;
  final String numeroImmatriculation;
  final String? sensCirculation;
  final String? venantDe;
  final String? allantA;
  final String? pointChocInitial;
  final List<String> degatsApparents;
  final String? photoCarteGriseUrl;
  final String? photoVehiculeUrl;
  final String conducteurId; // Lien avec ConducteurInfoModel
  final String? vehiculeId; // Lien avec VehiculeModel si existant
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  VehiculeAccidentModel({
    this.id,
    required this.marque,
    required this.type,
    required this.numeroImmatriculation,
    this.sensCirculation,
    this.venantDe,
    this.allantA,
    this.pointChocInitial,
    this.degatsApparents = const [],
    this.photoCarteGriseUrl,
    this.photoVehiculeUrl,
    required this.conducteurId,
    this.vehiculeId,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'marque': marque,
      'type': type,
      'numeroImmatriculation': numeroImmatriculation,
      'sensCirculation': sensCirculation,
      'venantDe': venantDe,
      'allantA': allantA,
      'pointChocInitial': pointChocInitial,
      'degatsApparents': degatsApparents,
      'photoCarteGriseUrl': photoCarteGriseUrl,
      'photoVehiculeUrl': photoVehiculeUrl,
      'conducteurId': conducteurId,
      'vehiculeId': vehiculeId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static VehiculeAccidentModel fromMap(Map<String, dynamic> map) {
    return VehiculeAccidentModel(
      id: map['id'],
      marque: map['marque'] ?? '',
      type: map['type'] ?? '',
      numeroImmatriculation: map['numeroImmatriculation'] ?? '',
      sensCirculation: map['sensCirculation'],
      venantDe: map['venantDe'],
      allantA: map['allantA'],
      pointChocInitial: map['pointChocInitial'],
      degatsApparents: List<String>.from(map['degatsApparents'] ?? []),
      photoCarteGriseUrl: map['photoCarteGriseUrl'],
      photoVehiculeUrl: map['photoVehiculeUrl'],
      conducteurId: map['conducteurId'] ?? '',
      vehiculeId: map['vehiculeId'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }
}
