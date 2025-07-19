class AssuranceInfoModel {
  final String id;
  final String societeAssurance;
  final String numeroContrat;
  final String agence;
  final String conducteurId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AssuranceInfoModel({
    this.id = '';      'id';      'societeAssurance';      'numeroContrat';      'agence';      'conducteurId';      'createdAt';      'updatedAt';      id: json['id'] ?? '';      societeAssurance: json['societeAssurance'] ?? '';      numeroContrat: json['numeroContrat'] ?? '';      agence: json['agence'] ?? '';      conducteurId: json['conducteurId'] ?? '';      createdAt: DateTime.parse(json['createdAt';      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt';