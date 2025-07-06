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
    required this.estPassagerA,
    required this.estPassagerB,
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

  // Alias pour toMap pour compatibilité
  Map<String, dynamic> toJson() => toMap();

  factory TemoinModel.fromMap(Map<String, dynamic> map) {
    return TemoinModel(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      adresse: map['adresse'] ?? '',
      telephone: map['telephone'],
      estPassagerA: map['estPassagerA'] ?? false,
      estPassagerB: map['estPassagerB'] ?? false,
      constatId: map['constatId'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  // Alias pour fromMap pour compatibilité
  factory TemoinModel.fromJson(Map<String, dynamic> json) => TemoinModel.fromMap(json);

  TemoinModel copyWith({
    String? id,
    String? nom,
    String? adresse,
    String? telephone,
    bool? estPassagerA,
    bool? estPassagerB,
    String? constatId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TemoinModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      adresse: adresse ?? this.adresse,
      telephone: telephone ?? this.telephone,
      estPassagerA: estPassagerA ?? this.estPassagerA,
      estPassagerB: estPassagerB ?? this.estPassagerB,
      constatId: constatId ?? this.constatId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}