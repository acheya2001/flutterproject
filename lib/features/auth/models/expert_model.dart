import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../utils/user_type.dart';
import 'user_model.dart';

class ExpertModel extends UserModel {
  final String cabinet;
  final String agrement;
  final List<String> expertiseIds;

  ExpertModel({
    required String id,
    required String email,
    required String nom,
    required String prenom,
    required String telephone,
    required this.cabinet,
    required this.agrement,
    this.expertiseIds = const [],
    String? adresse,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
          uid: id,
          email: email,
          nom: nom,
          prenom: prenom,
          telephone: telephone,
          adresse: adresse,
          userType: UserType.expert,
          dateCreation: createdAt,
          dateModification: updatedAt,
        );

  @override
  Map<String, dynamic> toFirestore() {
    final map = super.toFirestore();
    map.addAll({
      'cabinet': cabinet,
      'agrement': agrement,
      'expertiseIds': expertiseIds,
    });
    return map;
  }

  static ExpertModel fromMap(Map<String, dynamic> map) {
    try {
      return ExpertModel(
        id: map['id'] as String? ?? '',
        email: map['email'] as String? ?? '',
        nom: map['nom'] as String? ?? '',
        prenom: map['prenom'] as String? ?? '',
        telephone: map['telephone'] as String? ?? '',
        cabinet: map['cabinet'] as String? ?? '',
        agrement: map['agrement'] as String? ?? '',
        expertiseIds: List<String>.from(map['expertiseIds'] ?? []),
        adresse: map['adresse'] as String?,
        createdAt: (map['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (map['dateModification'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('Erreur lors de la conversion de ExpertModel: $e');
      return ExpertModel(
        id: '',
        email: '',
        nom: '',
        prenom: '',
        telephone: '',
        cabinet: '',
        agrement: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  String toString() {
    return 'ExpertModel{id: $id, email: $email, nom: $nom, prenom: $prenom, cabinet: $cabinet, agrement: $agrement}';
  }
}
