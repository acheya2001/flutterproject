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

  Map<String, dynamic> toJson() {
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

  factory AssuranceInfoModel.fromJson(Map<String, dynamic> json) {
    return AssuranceInfoModel(
      id: json['id'] ?? '',
      societeAssurance: json['societeAssurance'] ?? '',
      numeroContrat: json['numeroContrat'] ?? '',
      agence: json['agence'] ?? '',
      conducteurId: json['conducteurId'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  AssuranceInfoModel copyWith({
    String? id,
    String? societeAssurance,
    String? numeroContrat,
    String? agence,
    String? conducteurId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AssuranceInfoModel(
      id: id ?? this.id,
      societeAssurance: societeAssurance ?? this.societeAssurance,
      numeroContrat: numeroContrat ?? this.numeroContrat,
      agence: agence ?? this.agence,
      conducteurId: conducteurId ?? this.conducteurId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
