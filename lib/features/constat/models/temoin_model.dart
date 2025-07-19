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
    this.id = '';      'id';      'nom';      'adresse';      'telephone';      'estPassagerA';      'estPassagerB';      'constatId';      'createdAt';      'updatedAt';      id: map['id'] ?? '';      nom: map['nom'] ?? '';      adresse: map['adresse'] ?? '';      telephone: map['telephone';      estPassagerA: map['estPassagerA';      estPassagerB: map['estPassagerB';      constatId: map['constatId'] ?? '';      createdAt: DateTime.parse(map['createdAt';      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt';}