import 'package:cloud_firestore/cloud_firestore.dart'; // Ajout pour Timestamp

class ConducteurPartieModel {
  final String userId; // UserID du conducteur remplissant cette partie
  final String role; // 'A', 'B', 'C', etc.
  final bool isOwner; // Si ce conducteur est propriétaire du véhicule qu'il déclare pour cette partie
  bool isSubmitted; // Si cette partie a été soumise par le conducteur
  final Map<String, dynamic> donneesRemplies; // Toutes les données du formulaire pour cette partie
  final DateTime? submittedAt;

  ConducteurPartieModel({
    required this.userId,
    required this.role,
    this.isOwner = true, // Par défaut, on peut supposer qu'il est propriétaire
    this.isSubmitted = false,
    required this.donneesRemplies,
    this.submittedAt,
  });

  ConducteurPartieModel copyWith({
    String? userId,
    String? role,
    bool? isOwner,
    bool? isSubmitted,
    Map<String, dynamic>? donneesRemplies,
    DateTime? submittedAt,
  }) {
    return ConducteurPartieModel(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      isOwner: isOwner ?? this.isOwner,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      donneesRemplies: donneesRemplies ?? this.donneesRemplies,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': role,
      'isOwner': isOwner,
      'isSubmitted': isSubmitted,
      'donneesRemplies': donneesRemplies,
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null, // Convertir en Timestamp
    };
  }

  factory ConducteurPartieModel.fromMap(Map<String, dynamic> map) {
    return ConducteurPartieModel(
      userId: map['userId'] as String? ?? '',
      role: map['role'] as String? ?? '',
      isOwner: map['isOwner'] as bool? ?? true,
      isSubmitted: map['isSubmitted'] as bool? ?? false,
      donneesRemplies: Map<String, dynamic>.from(map['donneesRemplies'] as Map? ?? {}),
      submittedAt: (map['submittedAt'] as Timestamp?)?.toDate(), // Convertir depuis Timestamp
    );
  }
}