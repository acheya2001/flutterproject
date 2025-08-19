class VehiculeAccidentModel {
  final String id;
  final String marque;
  final String type;
  final String numeroImmatriculation;
  final String venantDe;
  final String allantA;
  final List<String> degatsApparents;
  final String conducteurId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  VehiculeAccidentModel({
    this.id = '',
    required this.marque,
    required this.type,
    required this.numeroImmatriculation,
    this.venantDe = '',
    this.allantA = '',
    this.degatsApparents = const [],
    required this.conducteurId,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'marque': marque,
      'type': type,
      'numeroImmatriculation': numeroImmatriculation,
      'venantDe': venantDe,
      'allantA': allantA,
      'degatsApparents': degatsApparents,
      'conducteurId': conducteurId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory VehiculeAccidentModel.fromMap(Map<String, dynamic> json) {
    return VehiculeAccidentModel(
      id: json['id'] ?? '',
      marque: json['marque'] ?? '',
      type: json['type'] ?? '',
      numeroImmatriculation: json['numeroImmatriculation'] ?? '',
      venantDe: json['venantDe'] ?? '',
      allantA: json['allantA'] ?? '',
      degatsApparents: List<String>.from(json['degatsApparents'] ?? []),
      conducteurId: json['conducteurId'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
}