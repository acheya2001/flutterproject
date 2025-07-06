import 'package:cloud_firestore/cloud_firestore.dart';
import 'conducteur_partie_model.dart';

class ConstatSessionModel {
  final String sessionId; // ID du document Firestore
  final String createdBy; // UserID de celui qui a créé
  final DateTime createdAt;
  final int nombreVehicules; // Nombre total de véhicules impliqués
  final List<ConducteurPartieModel> parties; // Liste des parties de chaque conducteur
  final bool isComplete; // True si toutes les parties sont soumises et validées
  final String? sessionCode; // Code court pour rejoindre la session (optionnel mais utile)
  final String? lieuAccident; // Peut être pré-rempli par l'initiateur
  final DateTime? dateAccident; // Peut être pré-rempli par l'initiateur


  ConstatSessionModel({
    required this.sessionId,
    required this.createdBy,
    required this.createdAt,
    required this.nombreVehicules,
    required this.parties,
    this.isComplete = false,
    this.sessionCode,
    this.lieuAccident,
    this.dateAccident,
  });

  Map<String, dynamic> toMap() {
    return {
      // sessionId n'est pas dans la map car c'est l'ID du document
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'nombreVehicules': nombreVehicules,
      'isComplete': isComplete,
      'parties': parties.map((p) => p.toMap()).toList(),
      'sessionCode': sessionCode,
      'lieuAccident': lieuAccident,
      'dateAccident': dateAccident != null ? Timestamp.fromDate(dateAccident!) : null,
    };
  }

  factory ConstatSessionModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ConstatSessionModel(
      sessionId: documentId,
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      nombreVehicules: map['nombreVehicules'] as int? ?? 0,
      isComplete: map['isComplete'] as bool? ?? false,
      parties: (map['parties'] as List<dynamic>?)
              ?.map((p) => ConducteurPartieModel.fromMap(p as Map<String, dynamic>))
              .toList() ??
          <ConducteurPartieModel>[],
      sessionCode: map['sessionCode'] as String?,
      lieuAccident: map['lieuAccident'] as String?,
      dateAccident: (map['dateAccident'] as Timestamp?)?.toDate(),
    );
  }
}