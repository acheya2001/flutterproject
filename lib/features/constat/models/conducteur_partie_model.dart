import 'package:cloud_firestore/cloud_firestore.dart';

class ConducteurPartieModel {
  final String userId;
  final String role; // 'A', 'B', 'C', etc.
  final bool isOwner; // Si ce conducteur est propriétaire du véhicule
  final bool isSubmitted;
  final Map<String, dynamic> donneesRemplies;
  final DateTime? submittedAt;

  ConducteurPartieModel({
    required this.userId,
    required this.role,
    this.isOwner = true, // Par défaut, on peut supposer qu'il est propriétaire
    this.isSubmitted = false,
    this.donneesRemplies = const {},
    this.submittedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': role,
      'isOwner': isOwner,
      'isSubmitted': isSubmitted,
      'donneesRemplies': donneesRemplies,
      'submittedAt': submittedAt?.toIso8601String(),
    };
  }

  factory ConducteurPartieModel.fromMap(Map<String, dynamic> map) {
    return ConducteurPartieModel(
      userId: map['userId'] as String? ?? '',
      role: map['role'] as String? ?? '',
      isOwner: map['isOwner'] ?? true,
      isSubmitted: map['isSubmitted'] ?? false,
      donneesRemplies: Map<String, dynamic>.from(map['donneesRemplies'] ?? {}),
      submittedAt: map['submittedAt'] != null ? DateTime.parse(map['submittedAt']) : null,
    );
  }
}