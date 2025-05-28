import 'package:cloud_firestore/cloud_firestore.dart';

class ConducteurInfoModel {
  final String? id;
  final String nom;
  final String prenom;
  final String adresse;
  final String? telephone;
  final String? numeroPermis;
  final DateTime? dateDelivrancePermis;
  final bool? permisValide;
  final bool? estProprietaire;
  final String? photoPermisUrl;
  final String userId; // Lien avec l'utilisateur connecté
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  ConducteurInfoModel({
    this.id,
    required this.nom,
    required this.prenom,
    required this.adresse,
    this.telephone,
    this.numeroPermis,
    this.dateDelivrancePermis,
    this.permisValide,
    this.estProprietaire,
    this.photoPermisUrl,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'adresse': adresse,
      'telephone': telephone,
      'numeroPermis': numeroPermis,
      'dateDelivrancePermis': dateDelivrancePermis,
      'permisValide': permisValide,
      'estProprietaire': estProprietaire,
      'photoPermisUrl': photoPermisUrl,
      'userId': userId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static ConducteurInfoModel fromMap(Map<String, dynamic> map) {
    return ConducteurInfoModel(
      id: map['id'],
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      adresse: map['adresse'] ?? '',
      telephone: map['telephone'],
      numeroPermis: map['numeroPermis'],
      dateDelivrancePermis: map['dateDelivrancePermis'] != null 
          ? (map['dateDelivrancePermis'] as Timestamp).toDate() : null,
      permisValide: map['permisValide'],
      estProprietaire: map['estProprietaire'],
      photoPermisUrl: map['photoPermisUrl'],
      userId: map['userId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  ConducteurInfoModel copyWith({
    String? id,
    String? nom,
    String? prenom,
    String? adresse,
    String? telephone,
    String? numeroPermis,
    DateTime? dateDelivrancePermis,
    bool? permisValide,
    bool? estProprietaire,
    String? photoPermisUrl,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConducteurInfoModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      adresse: adresse ?? this.adresse,
      telephone: telephone ?? this.telephone,
      numeroPermis: numeroPermis ?? this.numeroPermis,
      dateDelivrancePermis: dateDelivrancePermis ?? this.dateDelivrancePermis,
      permisValide: permisValide ?? this.permisValide,
      estProprietaire: estProprietaire ?? this.estProprietaire,
      photoPermisUrl: photoPermisUrl ?? this.photoPermisUrl,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
