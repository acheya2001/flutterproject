class AssuranceInfoModel {
  final String id;
  final String societeAssurance;
  final String numeroContrat;
  final String agence;
  final String conducteurId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AssuranceInfoModel({
    this.id = '',
    required this.societeAssurance,
    required this.numeroContrat,
    required this.agence,
    required this.conducteurId,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'societeAssurance': societeAssurance,
      'numeroContrat': numeroContrat,
      'agence': agence,
      'conducteurId': conducteurId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory AssuranceInfoModel.fromMap(Map<String, dynamic> json) {
    return AssuranceInfoModel(
      id: json['id'] ?? '',
      societeAssurance: json['societeAssurance'] ?? '',
      numeroContrat: json['numeroContrat'] ?? '',
      agence: json['agence'] ?? '',
      conducteurId: json['conducteurId'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
}