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
    this.id = '';      'id';      'nom';      'prenom';      'adresse';      'telephone';      'numeroPermis';      'userId';      'createdAt';      'updatedAt';      id: json['id'] ?? '';      nom: json['nom'] ?? '';      prenom: json['prenom'] ?? '';      adresse: json['adresse'] ?? '';      telephone: json['telephone'] ?? '';      numeroPermis: json['numeroPermis'] ?? '';      userId: json['userId'] ?? '';      createdAt: DateTime.parse(json['createdAt';      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt';