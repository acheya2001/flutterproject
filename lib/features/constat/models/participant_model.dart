import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum ParticipantRole {
  conducteur,
  proprietaire,
  temoin,
}

class ParticipantModel {
  final String id;
  final String constatId;
  final String? userId;
  final String nom;
  final String prenom;
  final String telephone;
  final String? email;
  final String? adresse;
  final String? permisNumero;
  final DateTime? permisDelivreLe;
  final DateTime? permisValideJusquau;
  final String? urlPhotoPermis;
  final String? urlPhotoCIN;
  final ParticipantRole role;
  final String? vehiculeId;
  final bool estProprietaire;
  final bool permisValide;
  final bool assuranceValide;
  final DateTime createdAt;
  final DateTime updatedAt;

  ParticipantModel({
    required this.id,
    required this.constatId,
    this.userId,
    required this.nom,
    required this.prenom,
    required this.telephone,
    this.email,
    this.adresse,
    this.permisNumero,
    this.permisDelivreLe,
    this.permisValideJusquau,
    this.urlPhotoPermis,
    this.urlPhotoCIN,
    required this.role,
    this.vehiculeId,
    required this.estProprietaire,
    required this.permisValide,
    required this.assuranceValide,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'constatId': constatId,
      'userId': userId,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'email': email,
      'adresse': adresse,
      'permisNumero': permisNumero,
      'permisDelivreLe': permisDelivreLe,
      'permisValideJusquau': permisValideJusquau,
      'urlPhotoPermis': urlPhotoPermis,
      'urlPhotoCIN': urlPhotoCIN,
      'role': role.toString().split('.').last,
      'vehiculeId': vehiculeId,
      'estProprietaire': estProprietaire,
      'permisValide': permisValide,
      'assuranceValide': assuranceValide,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static ParticipantModel fromMap(Map<String, dynamic> map) {
    try {
      return ParticipantModel(
        id: map['id'] as String? ?? '',
        constatId: map['constatId'] as String? ?? '',
        userId: map['userId'] as String?,
        nom: map['nom'] as String? ?? '',
        prenom: map['prenom'] as String? ?? '',
        telephone: map['telephone'] as String? ?? '',
        email: map['email'] as String?,
        adresse: map['adresse'] as String?,
        permisNumero: map['permisNumero'] as String?,
        permisDelivreLe: (map['permisDelivreLe'] as Timestamp?)?.toDate(),
        permisValideJusquau: (map['permisValideJusquau'] as Timestamp?)?.toDate(),
        urlPhotoPermis: map['urlPhotoPermis'] as String?,
        urlPhotoCIN: map['urlPhotoCIN'] as String?,
        role: ParticipantRole.values.firstWhere(
          (e) => e.toString().split('.').last == (map['role'] as String? ?? 'conducteur'),
          orElse: () => ParticipantRole.conducteur,
        ),
        vehiculeId: map['vehiculeId'] as String?,
        estProprietaire: map['estProprietaire'] as bool? ?? false,
        permisValide: map['permisValide'] as bool? ?? false,
        assuranceValide: map['assuranceValide'] as bool? ?? false,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('Erreur lors de la conversion de ParticipantModel: $e');
      return ParticipantModel(
        id: '',
        constatId: '',
        nom: '',
        prenom: '',
        telephone: '',
        role: ParticipantRole.conducteur,
        estProprietaire: false,
        permisValide: false,
        assuranceValide: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  ParticipantModel copyWith({
    String? id,
    String? constatId,
    String? userId,
    String? nom,
    String? prenom,
    String? telephone,
    String? email,
    String? adresse,
    String? permisNumero,
    DateTime? permisDelivreLe,
    DateTime? permisValideJusquau,
    String? urlPhotoPermis,
    String? urlPhotoCIN,
    ParticipantRole? role,
    String? vehiculeId,
    bool? estProprietaire,
    bool? permisValide,
    bool? assuranceValide,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParticipantModel(
      id: id ?? this.id,
      constatId: constatId ?? this.constatId,
      userId: userId ?? this.userId,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      adresse: adresse ?? this.adresse,
      permisNumero: permisNumero ?? this.permisNumero,
      permisDelivreLe: permisDelivreLe ?? this.permisDelivreLe,
      permisValideJusquau: permisValideJusquau ?? this.permisValideJusquau,
      urlPhotoPermis: urlPhotoPermis ?? this.urlPhotoPermis,
      urlPhotoCIN: urlPhotoCIN ?? this.urlPhotoCIN,
      role: role ?? this.role,
      vehiculeId: vehiculeId ?? this.vehiculeId,
      estProprietaire: estProprietaire ?? this.estProprietaire,
      permisValide: permisValide ?? this.permisValide,
      assuranceValide: assuranceValide ?? this.assuranceValide,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ParticipantModel{id: $id, nom: $nom, prenom: $prenom, role: $role}';
  }
}
