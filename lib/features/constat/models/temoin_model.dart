class TemoinModel {
  final String id;
  final String nom;
  final String adresse;
  final String? telephone;
  final bool estPassagerA;
  final bool estPassagerB;
  final String constatId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TemoinModel({
    this.id = '',
    required this.nom,
    required this.adresse,
    this.telephone,
    this.estPassagerA = false,
    this.estPassagerB = false,
    required this.constatId,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'adresse': adresse,
      'telephone': telephone,
      'estPassagerA': estPassagerA,
      'estPassagerB': estPassagerB,
      'constatId': constatId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory TemoinModel.fromMap(Map<String, dynamic> map) {
    return TemoinModel(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      adresse: map['adresse'] ?? '',
      telephone: map['telephone'],
      estPassagerA: map['estPassagerA'] ?? false,
      estPassagerB: map['estPassagerB'] ?? false,
      constatId: map['constatId'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }}