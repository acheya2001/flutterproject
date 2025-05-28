import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/user_type.dart';

class UserModel {
  final String id;
  final String email;
  final String nom;
  final String prenom;
  final String telephone;
  final String? adresse;
  final UserType type;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.telephone,
    this.adresse,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
  });

  // Créer une copie du modèle avec des modifications
  UserModel copyWith({
    String? id,
    String? email,
    String? nom,
    String? prenom,
    String? telephone,
    String? adresse,
    UserType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      telephone: telephone ?? this.telephone,
      adresse: adresse ?? this.adresse,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'adresse': adresse,
      'type': type.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static UserModel fromMap(Map<String, dynamic> map, String docId) {
    final userType = _getUserTypeFromString(map['type'] as String? ?? 'conducteur');
    
    return UserModel(
      id: docId,
      email: map['email'] as String? ?? '',
      nom: map['nom'] as String? ?? '',
      prenom: map['prenom'] as String? ?? '',
      telephone: map['telephone'] as String? ?? '',
      adresse: map['adresse'] as String?,
      type: userType,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static UserModel fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final userType = _getUserTypeFromString(data['type'] as String? ?? 'conducteur');
    
    return UserModel(
      id: doc.id,
      email: data['email'] as String? ?? '',
      nom: data['nom'] as String? ?? '',
      prenom: data['prenom'] as String? ?? '',
      telephone: data['telephone'] as String? ?? '',
      adresse: data['adresse'] as String?,
      type: userType,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static UserType _getUserTypeFromString(String type) {
    switch (type) {
      case 'conducteur':
        return UserType.conducteur;
      case 'assureur':
        return UserType.assureur;
      case 'expert':
        return UserType.expert;
      default:
        return UserType.conducteur;
    }
  }

  // Nom complet de l'utilisateur
  String get nomComplet => '$prenom $nom';

  @override
  String toString() {
    return 'UserModel{id: $id, email: $email, nom: $nom, prenom: $prenom, telephone: $telephone, type: $type}';
  }
}