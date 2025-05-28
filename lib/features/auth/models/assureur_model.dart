import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../utils/user_type.dart';
import 'user_model.dart';

class AssureurModel extends UserModel {
  final String compagnie;
  final String matricule;
  final List<String> dossierIds;

  AssureurModel({
    required String id,
    required String email,
    required String nom,
    required String prenom,
    required String telephone,
    required this.compagnie,
    required this.matricule,
    this.dossierIds = const [],
    String? adresse,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
          id: id,
          email: email,
          nom: nom,
          prenom: prenom,
          telephone: telephone,
          adresse: adresse,
          type: UserType.assureur,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'compagnie': compagnie,
      'matricule': matricule,
      'dossierIds': dossierIds,
    });
    return map;
  }

  static AssureurModel fromMap(Map<String, dynamic> map) {
    try {
      return AssureurModel(
        id: map['id'] as String? ?? '',
        email: map['email'] as String? ?? '',
        nom: map['nom'] as String? ?? '',
        prenom: map['prenom'] as String? ?? '',
        telephone: map['telephone'] as String? ?? '',
        compagnie: map['compagnie'] as String? ?? '',
        matricule: map['matricule'] as String? ?? '',
        dossierIds: List<String>.from(map['dossierIds'] ?? []),
        adresse: map['adresse'] as String?,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('Erreur lors de la conversion de AssureurModel: $e');
      return AssureurModel(
        id: '',
        email: '',
        nom: '',
        prenom: '',
        telephone: '',
        compagnie: '',
        matricule: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  String toString() {
    return 'AssureurModel{id: $id, email: $email, nom: $nom, prenom: $prenom, compagnie: $compagnie, matricule: $matricule}';
  }
}
