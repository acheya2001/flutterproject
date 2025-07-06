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
    required this.venantDe,
    required this.allantA,
    required this.degatsApparents,
    required this.conducteurId,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
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

  /// Alias pour toJson() - compatibilité Firestore
  Map<String, dynamic> toMap() => toJson();

  factory VehiculeAccidentModel.fromJson(Map<String, dynamic> json) {
    return VehiculeAccidentModel(
      id: json['id'] ?? '',
      marque: json['marque'] ?? '',
      type: json['type'] ?? '',
      numeroImmatriculation: json['numeroImmatriculation'] ?? '',
      venantDe: json['venantDe'] ?? '',
      allantA: json['allantA'] ?? '',
      degatsApparents: List<String>.from(json['degatsApparents'] ?? []),
      conducteurId: json['conducteurId'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  /// Alias pour fromJson() - compatibilité Firestore
  factory VehiculeAccidentModel.fromMap(Map<String, dynamic> map) =>
      VehiculeAccidentModel.fromJson(map);

  VehiculeAccidentModel copyWith({
    String? id,
    String? marque,
    String? type,
    String? numeroImmatriculation,
    String? venantDe,
    String? allantA,
    List<String>? degatsApparents,
    String? conducteurId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehiculeAccidentModel(
      id: id ?? this.id,
      marque: marque ?? this.marque,
      type: type ?? this.type,
      numeroImmatriculation: numeroImmatriculation ?? this.numeroImmatriculation,
      venantDe: venantDe ?? this.venantDe,
      allantA: allantA ?? this.allantA,
      degatsApparents: degatsApparents ?? this.degatsApparents,
      conducteurId: conducteurId ?? this.conducteurId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
