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
    this.numeroPermis = '',
    required this.userId,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
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

  factory ConducteurInfoModel.fromMap(Map<String, dynamic> json) {
    return ConducteurInfoModel(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      adresse: json['adresse'] ?? '',
      telephone: json['telephone'] ?? '',
      numeroPermis: json['numeroPermis'] ?? '',
      userId: json['userId'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
}