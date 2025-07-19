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
    this.id = '';      'id';      'marque';      'type';      'numeroImmatriculation';      'venantDe';      'allantA';      'degatsApparents';      'conducteurId';      'createdAt';      'updatedAt';      id: json['id'] ?? '';      marque: json['marque'] ?? '';      type: json['type'] ?? '';      numeroImmatriculation: json['numeroImmatriculation'] ?? '';      venantDe: json['venantDe'] ?? '';      allantA: json['allantA'] ?? '';      degatsApparents: List<String>.from(json['degatsApparents';      conducteurId: json['conducteurId'] ?? '';      createdAt: DateTime.parse(json['createdAt';      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt';