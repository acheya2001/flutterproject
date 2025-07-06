class ConducteurInfoModel {
  final String id;
  final String nom;
  final String prenom;
  final String adresse;
  final String telephone;
  final String numeroPermis;
  final String userId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ConducteurInfoModel({
    this.id = '',
    required this.nom,
    required this.prenom,
    required this.adresse,
    required this.telephone,
    required this.numeroPermis,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'adresse': adresse,
      'telephone': telephone,
      'numeroPermis': numeroPermis,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Alias pour toJson() - compatibilité Firestore
  Map<String, dynamic> toMap() => toJson();

  factory ConducteurInfoModel.fromJson(Map<String, dynamic> json) {
    return ConducteurInfoModel(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      adresse: json['adresse'] ?? '',
      telephone: json['telephone'] ?? '',
      numeroPermis: json['numeroPermis'] ?? '',
      userId: json['userId'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  /// Alias pour fromJson() - compatibilité Firestore
  factory ConducteurInfoModel.fromMap(Map<String, dynamic> map) =>
      ConducteurInfoModel.fromJson(map);

  ConducteurInfoModel copyWith({
    String? id,
    String? nom,
    String? prenom,
    String? adresse,
    String? telephone,
    String? numeroPermis,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConducteurInfoModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      adresse: adresse ?? this.adresse,
      telephone: telephone ?? this.telephone,
      numeroPermis: numeroPermis ?? this.numeroPermis,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
