import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/user_type.dart';
import 'user_model.dart';

class ConducteurModel extends UserModel {
  final String cin;
  final List<String> vehiculeIds;

  ConducteurModel({ 
    required String id,
    required String email,
    required String nom,
    required String prenom,
    required String telephone,
    required this.cin,
    String? adresse,
    this.vehiculeIds = const [],
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
          uid: id,
          email: email,
          nom: nom,
          prenom: prenom,
          telephone: telephone,
          userType: UserType.conducteur,
          adresse: adresse,
          dateCreation: createdAt,
          dateModification: updatedAt,
        );

  // Modifier la méthode fromMap pour accepter un seul argument
  factory ConducteurModel.fromMap(Map<String, dynamic> data) {
    return ConducteurModel(
      id: data['id'] as String? ?? '',
      email: data['email'] as String? ?? '',
      nom: data['nom'] as String? ?? '',
      prenom: data['prenom'] as String? ?? '',
      telephone: data['telephone'] as String? ?? '',
      cin: data['cin'] as String? ?? '',
      adresse: data['adresse'] as String?,
      vehiculeIds: List<String>.from(data['vehiculeIds'] ?? []),
      createdAt: (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['dateModification'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    final baseMap = super.toFirestore();
    return {
      ...baseMap,
      'cin': cin,
      'vehiculeIds': vehiculeIds,
    };
  }

  @override
  String toString() {
    return 'ConducteurModel{id: $id, nom: $nom, prenom: $prenom, cin: $cin, vehiculeIds: $vehiculeIds}';
  }




}