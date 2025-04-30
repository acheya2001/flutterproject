import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleModel {
  final String id;
  final String ownerId;
  final String brand;
  final String model;
  final int year;
  final String licensePlate;
  final String vin; // Vehicle Identification Number
  final int power;
  final String type; // voiture, moto, camion, etc.
  final String color;
  final List<String> photos;
  final String? activeContractId;
  final DateTime createdAt;
  final DateTime updatedAt;

  VehicleModel({
    required this.id,
    required this.ownerId,
    required this.brand,
    required this.model,
    required this.year,
    required this.licensePlate,
    required this.vin,
    required this.power,
    required this.type,
    required this.color,
    required this.photos,
    this.activeContractId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convertir un document Firestore en VehicleModel
  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VehicleModel(
      id: doc.id,
      ownerId: data['proprietaireId'] ?? '',
      brand: data['marque'] ?? '',
      model: data['modele'] ?? '',
      year: data['annee'] ?? 0,
      licensePlate: data['immatriculation'] ?? '',
      vin: data['numeroSerie'] ?? '',
      power: data['puissance'] ?? 0,
      type: data['typeVehicule'] ?? '',
      color: data['couleur'] ?? '',
      photos: List<String>.from(data['photos'] ?? []),
      activeContractId: data['contratActifId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convertir VehicleModel en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'proprietaireId': ownerId,
      'marque': brand,
      'modele': model,
      'annee': year,
      'immatriculation': licensePlate,
      'numeroSerie': vin,
      'puissance': power,
      'typeVehicule': type,
      'couleur': color,
      'photos': photos,
      'contratActifId': activeContractId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Créer une copie de VehicleModel avec des champs mis à jour
  VehicleModel copyWith({
    String? id,
    String? ownerId,
    String? brand,
    String? model,
    int? year,
    String? licensePlate,
    String? vin,
    int? power,
    String? type,
    String? color,
    List<String>? photos,
    String? activeContractId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      licensePlate: licensePlate ?? this.licensePlate,
      vin: vin ?? this.vin,
      power: power ?? this.power,
      type: type ?? this.type,
      color: color ?? this.color,
      photos: photos ?? this.photos,
      activeContractId: activeContractId ?? this.activeContractId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}