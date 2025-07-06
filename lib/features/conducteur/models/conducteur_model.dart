import 'package:cloud_firestore/cloud_firestore.dart';

class ConducteurModel {
  final String? id;
  final String nom;
  final String prenom;
  final String? email;
  final String telephone;
  final String? adresse;
  final String? permisNumero;
  final DateTime? permisDelivreLe;
  final DateTime? permisValideJusquau;
  final String? urlPhotoPermis;
  final String? urlPhotoCIN;
  final List<String> vehiculeIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ConducteurModel({
    this.id,
    required this.nom,
    required this.prenom,
    this.email,
    required this.telephone,
    this.adresse,
    this.permisNumero,
    this.permisDelivreLe,
    this.permisValideJusquau,
    this.urlPhotoPermis,
    this.urlPhotoCIN,
    this.vehiculeIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  // Vérifier si le permis est valide
  bool get estPermisValide {
    if (permisValideJusquau == null) return false;
    return permisValideJusquau!.isAfter(DateTime.now());
  }

  // Calculer le nombre de jours restants avant expiration du permis
  int get joursRestantsPermis {
    if (permisValideJusquau == null) return 0;
    final now = DateTime.now();
    if (permisValideJusquau!.isBefore(now)) return 0;
    return permisValideJusquau!.difference(now).inDays;
  }

  // Créer une copie du modèle avec des valeurs modifiées
  ConducteurModel copyWith({
    String? id,
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? adresse,
    String? permisNumero,
    DateTime? permisDelivreLe,
    DateTime? permisValideJusquau,
    String? urlPhotoPermis,
    String? urlPhotoCIN,
    List<String>? vehiculeIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConducteurModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      adresse: adresse ?? this.adresse,
      permisNumero: permisNumero ?? this.permisNumero,
      permisDelivreLe: permisDelivreLe ?? this.permisDelivreLe,
      permisValideJusquau: permisValideJusquau ?? this.permisValideJusquau,
      urlPhotoPermis: urlPhotoPermis ?? this.urlPhotoPermis,
      urlPhotoCIN: urlPhotoCIN ?? this.urlPhotoCIN,
      vehiculeIds: vehiculeIds ?? this.vehiculeIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convertir le modèle en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'adresse': adresse,
      'permisNumero': permisNumero,
      'permisDelivreLe': permisDelivreLe != null
          ? Timestamp.fromDate(permisDelivreLe!)
          : null,
      'permisValideJusquau': permisValideJusquau != null
          ? Timestamp.fromDate(permisValideJusquau!)
          : null,
      'urlPhotoPermis': urlPhotoPermis,
      'urlPhotoCIN': urlPhotoCIN,
      'vehiculeIds': vehiculeIds,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : Timestamp.now(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : Timestamp.now(),
    };
  }

  // Créer un modèle à partir d'un document Firestore
  factory ConducteurModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ConducteurModel(
      id: doc.id,
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      email: data['email'],
      telephone: data['telephone'] ?? '',
      adresse: data['adresse'],
      permisNumero: data['permisNumero'],
      permisDelivreLe: data['permisDelivreLe'] != null
          ? (data['permisDelivreLe'] as Timestamp).toDate()
          : null,
      permisValideJusquau: data['permisValideJusquau'] != null
          ? (data['permisValideJusquau'] as Timestamp).toDate()
          : null,
      urlPhotoPermis: data['urlPhotoPermis'],
      urlPhotoCIN: data['urlPhotoCIN'],
      vehiculeIds: List<String>.from(data['vehiculeIds'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Créer un modèle à partir d'un Map
  factory ConducteurModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return ConducteurModel(
      id: id,
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      email: data['email'],
      telephone: data['telephone'] ?? '',
      adresse: data['adresse'],
      permisNumero: data['permisNumero'],
      permisDelivreLe: data['permisDelivreLe'] != null
          ? (data['permisDelivreLe'] as Timestamp).toDate()
          : null,
      permisValideJusquau: data['permisValideJusquau'] != null
          ? (data['permisValideJusquau'] as Timestamp).toDate()
          : null,
      urlPhotoPermis: data['urlPhotoPermis'],
      urlPhotoCIN: data['urlPhotoCIN'],
      vehiculeIds: List<String>.from(data['vehiculeIds'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
