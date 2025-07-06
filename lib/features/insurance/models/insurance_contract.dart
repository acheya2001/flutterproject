import 'package:cloud_firestore/cloud_firestore.dart';
import 'simple_vehicle_model.dart';

/// 📋 Modèle de contrat d'assurance
class InsuranceContract {
  final String id;
  final String numeroContrat;
  final String compagnieAssurance;
  final String agence;
  final String gouvernorat;
  
  // Informations de l'assuré
  final String nomAssure;
  final String prenomAssure;
  final String cinAssure;
  final String telephoneAssure;
  final String adresseAssure;
  
  // Véhicule assuré
  final SimpleVehicleModel vehicule;
  
  // Dates du contrat
  final DateTime dateDebut;
  final DateTime dateFin;
  
  // Statut et métadonnées
  final bool isActive;
  final String agentId; // ID de l'agent qui a créé le contrat
  final DateTime createdAt;
  final DateTime? updatedAt;

  InsuranceContract({
    required this.id,
    required this.numeroContrat,
    required this.compagnieAssurance,
    required this.agence,
    required this.gouvernorat,
    required this.nomAssure,
    required this.prenomAssure,
    required this.cinAssure,
    required this.telephoneAssure,
    required this.adresseAssure,
    required this.vehicule,
    required this.dateDebut,
    required this.dateFin,
    required this.isActive,
    required this.agentId,
    required this.createdAt,
    this.updatedAt,
  });

  /// Créer depuis Firestore
  factory InsuranceContract.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return InsuranceContract(
      id: doc.id,
      numeroContrat: data['numeroContrat'] ?? '',
      compagnieAssurance: data['compagnieAssurance'] ?? '',
      agence: data['agence'] ?? '',
      gouvernorat: data['gouvernorat'] ?? '',
      nomAssure: data['nomAssure'] ?? '',
      prenomAssure: data['prenomAssure'] ?? '',
      cinAssure: data['cinAssure'] ?? '',
      telephoneAssure: data['telephoneAssure'] ?? '',
      adresseAssure: data['adresseAssure'] ?? '',
      vehicule: SimpleVehicleModel.fromMap(data['vehicule'] ?? {}),
      dateDebut: (data['dateDebut'] as Timestamp).toDate(),
      dateFin: (data['dateFin'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      agentId: data['agentId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  /// Créer depuis Map
  factory InsuranceContract.fromMap(Map<String, dynamic> data) {
    return InsuranceContract(
      id: data['id'] ?? '',
      numeroContrat: data['numeroContrat'] ?? '',
      compagnieAssurance: data['compagnieAssurance'] ?? '',
      agence: data['agence'] ?? '',
      gouvernorat: data['gouvernorat'] ?? '',
      nomAssure: data['nomAssure'] ?? '',
      prenomAssure: data['prenomAssure'] ?? '',
      cinAssure: data['cinAssure'] ?? '',
      telephoneAssure: data['telephoneAssure'] ?? '',
      adresseAssure: data['adresseAssure'] ?? '',
      vehicule: SimpleVehicleModel.fromMap(data['vehicule'] ?? {}),
      dateDebut: data['dateDebut'] is Timestamp
          ? (data['dateDebut'] as Timestamp).toDate()
          : DateTime.parse(data['dateDebut']),
      dateFin: data['dateFin'] is Timestamp
          ? (data['dateFin'] as Timestamp).toDate()
          : DateTime.parse(data['dateFin']),
      isActive: data['isActive'] ?? true,
      agentId: data['agentId'] ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt']),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(data['updatedAt']))
          : null,
    );
  }

  /// Convertir vers Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'numeroContrat': numeroContrat,
      'compagnieAssurance': compagnieAssurance,
      'agence': agence,
      'gouvernorat': gouvernorat,
      'nomAssure': nomAssure,
      'prenomAssure': prenomAssure,
      'cinAssure': cinAssure,
      'telephoneAssure': telephoneAssure,
      'adresseAssure': adresseAssure,
      'vehicule': vehicule.toMap(),
      'dateDebut': Timestamp.fromDate(dateDebut),
      'dateFin': Timestamp.fromDate(dateFin),
      'isActive': isActive,
      'agentId': agentId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Convertir vers Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numeroContrat': numeroContrat,
      'compagnieAssurance': compagnieAssurance,
      'agence': agence,
      'gouvernorat': gouvernorat,
      'nomAssure': nomAssure,
      'prenomAssure': prenomAssure,
      'cinAssure': cinAssure,
      'telephoneAssure': telephoneAssure,
      'adresseAssure': adresseAssure,
      'vehicule': vehicule.toMap(),
      'dateDebut': dateDebut.toIso8601String(),
      'dateFin': dateFin.toIso8601String(),
      'isActive': isActive,
      'agentId': agentId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Créer une copie avec des modifications
  InsuranceContract copyWith({
    String? id,
    SimpleVehicleModel? vehicule,
    bool? isActive,
  }) {
    return InsuranceContract(
      id: id ?? this.id,
      numeroContrat: numeroContrat,
      compagnieAssurance: compagnieAssurance,
      agence: agence,
      gouvernorat: gouvernorat,
      nomAssure: nomAssure,
      prenomAssure: prenomAssure,
      cinAssure: cinAssure,
      telephoneAssure: telephoneAssure,
      adresseAssure: adresseAssure,
      vehicule: vehicule ?? this.vehicule,
      dateDebut: dateDebut,
      dateFin: dateFin,
      isActive: isActive ?? this.isActive,
      agentId: agentId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Vérifier si le contrat est expiré
  bool get isExpired => DateTime.now().isAfter(dateFin);

  /// Vérifier si le contrat est valide (actif et non expiré)
  bool get isValid => isActive && !isExpired;

  /// Nombre de jours restants
  int get daysRemaining {
    if (isExpired) return 0;
    return dateFin.difference(DateTime.now()).inDays;
  }

  /// Alias pour compatibilité
  int get joursRestants => daysRemaining;

  /// Propriétés manquantes pour compatibilité
  String get typeContrat => 'Standard';
  double get prime => 1200.0;
  List<String> get garanties => ['Responsabilité Civile', 'Vol et Incendie'];
  bool get bientotExpire => daysRemaining <= 30 && daysRemaining > 0;

  /// Nom complet de l'assuré
  String get nomCompletAssure => '$prenomAssure $nomAssure';

  /// Description du véhicule
  String get descriptionVehicule => '${vehicule.marque} ${vehicule.modele} (${vehicule.numeroImmatriculation})';

  @override
  String toString() {
    return 'InsuranceContract(id: $id, numeroContrat: $numeroContrat, compagnie: $compagnieAssurance)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InsuranceContract && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
