import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/user_type.dart';
import 'user_model.dart';

/// 🚗 Modèle pour les conducteurs
class ConducteurModel extends UserModel {
  final String cin;
  final List<String> vehiculeIds;

  ConducteurModel({
    required String uid,
    required String email,
    required String nom,
    required String prenom,
    required String telephone,
    required String adresse,
    required this.cin,
    this.vehiculeIds = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super(
          uid: uid,
          email: email,
          nom: nom,
          prenom: prenom,
          telephone: telephone,
          adresse: adresse,
          userType: UserType.conducteur,
          dateCreation: createdAt ?? DateTime.now(),
          dateModification: updatedAt ?? DateTime.now(),
          accountStatus: AccountStatus.active,
          permissions: const [],
        );

  factory ConducteurModel.fromMap(Map<String, dynamic> data) {
    return ConducteurModel(
      uid: data['uid'] as String? ?? data['id'] as String? ?? '',
      email: data['email'] as String? ?? '',
      nom: data['nom'] as String? ?? '',
      prenom: data['prenom'] as String? ?? '',
      telephone: data['telephone'] as String? ?? '',
      adresse: data['adresse'] as String? ?? '',
      cin: data['cin'] as String? ?? '',
      vehiculeIds: List<String>.from(data['vehiculeIds'] ?? []),
      createdAt: data['dateCreation'] is Timestamp
          ? (data['dateCreation'] as Timestamp).toDate()
          : data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      updatedAt: data['dateModification'] is Timestamp
          ? (data['dateModification'] as Timestamp).toDate()
          : data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'cin': cin,
      'vehiculeIds': vehiculeIds,
    });
    return map;
  }

  @override
  String toString() {
    return 'ConducteurModel{uid: $uid, nom: $nom, prenom: $prenom, cin: $cin, vehiculeIds: $vehiculeIds}';
  }
}