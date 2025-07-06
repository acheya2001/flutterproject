import 'package:cloud_firestore/cloud_firestore.dart';

/// 🏢 Modèle pour les agents d'assurance (modèle indépendant)
class AgentAssuranceModel {
  final String uid;
  final String email;
  final String nom;
  final String prenom;
  final String telephone;
  final String? adresse;
  final String numeroAgent;
  final String compagnie;
  final String agence;
  final String gouvernorat;
  final String poste;
  final String? carteIdRecto;
  final String? carteIdVerso;
  final String? permisRecto;
  final String? permisVerso;
  final bool isActive;
  final DateTime? dateEmbauche;
  final String? statut;

  final DateTime createdAt;
  final DateTime updatedAt;

  AgentAssuranceModel({
    required this.uid,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.numeroAgent,
    required this.compagnie,
    required this.agence,
    required this.gouvernorat,
    required this.poste,
    this.adresse,
    this.carteIdRecto,
    this.carteIdVerso,
    this.permisRecto,
    this.permisVerso,
    this.isActive = true,
    this.dateEmbauche,
    this.statut = 'actif',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Nom complet de l'agent
  String get nomComplet => '$prenom $nom';

  /// Informations de l'agence
  String get agenceComplete => '$agence - $gouvernorat';

  /// Informations de la compagnie
  String get compagnieComplete => '$compagnie ($poste)';

  /// Créer depuis Map Firestore
  factory AgentAssuranceModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return AgentAssuranceModel(
      uid: id ?? map['uid'] ?? '',
      email: map['email'] ?? '',
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      telephone: map['telephone'] ?? '',
      numeroAgent: map['numeroAgent'] ?? '',
      compagnie: map['compagnie'] ?? '',
      agence: map['agence'] ?? '',
      gouvernorat: map['gouvernorat'] ?? '',
      poste: map['poste'] ?? '',
      adresse: map['adresse'],
      carteIdRecto: map['carteIdRecto'],
      carteIdVerso: map['carteIdVerso'],
      permisRecto: map['permisRecto'],
      permisVerso: map['permisVerso'],
      isActive: map['isActive'] ?? true,
      dateEmbauche: map['dateEmbauche'] != null
          ? (map['dateEmbauche'] as Timestamp).toDate()
          : null,
      statut: map['statut'] ?? 'actif',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'numeroAgent': numeroAgent,
      'compagnie': compagnie,
      'agence': agence,
      'gouvernorat': gouvernorat,
      'poste': poste,
      'adresse': adresse,
      'carteIdRecto': carteIdRecto,
      'carteIdVerso': carteIdVerso,
      'permisRecto': permisRecto,
      'permisVerso': permisVerso,
      'isActive': isActive,
      'dateEmbauche': dateEmbauche != null ? Timestamp.fromDate(dateEmbauche!) : null,
      'statut': statut,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userType': 'assureur',
    };
  }

  /// Copier avec modifications
  AgentAssuranceModel copyWith({
    String? uid,
    String? email,
    String? nom,
    String? prenom,
    String? telephone,
    String? numeroAgent,
    String? compagnie,
    String? agence,
    String? gouvernorat,
    String? poste,
    String? adresse,
    String? carteIdRecto,
    String? carteIdVerso,
    String? permisRecto,
    String? permisVerso,
    bool? isActive,
    DateTime? dateEmbauche,
    String? statut,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AgentAssuranceModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      telephone: telephone ?? this.telephone,
      numeroAgent: numeroAgent ?? this.numeroAgent,
      compagnie: compagnie ?? this.compagnie,
      agence: agence ?? this.agence,
      gouvernorat: gouvernorat ?? this.gouvernorat,
      poste: poste ?? this.poste,
      adresse: adresse ?? this.adresse,
      carteIdRecto: carteIdRecto ?? this.carteIdRecto,
      carteIdVerso: carteIdVerso ?? this.carteIdVerso,
      permisRecto: permisRecto ?? this.permisRecto,
      permisVerso: permisVerso ?? this.permisVerso,
      isActive: isActive ?? this.isActive,
      dateEmbauche: dateEmbauche ?? this.dateEmbauche,
      statut: statut ?? this.statut,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Validation des données
  List<String> validate() {
    final errors = <String>[];

    if (email.isEmpty || !email.contains('@')) {
      errors.add('Email invalide');
    }

    if (nom.isEmpty) {
      errors.add('Nom requis');
    }

    if (prenom.isEmpty) {
      errors.add('Prénom requis');
    }

    if (telephone.isEmpty) {
      errors.add('Téléphone requis');
    }

    if (numeroAgent.isEmpty) {
      errors.add('Numéro d\'agent requis');
    }

    if (compagnie.isEmpty) {
      errors.add('Compagnie requise');
    }

    if (agence.isEmpty) {
      errors.add('Agence requise');
    }

    if (gouvernorat.isEmpty) {
      errors.add('Gouvernorat requis');
    }

    if (poste.isEmpty) {
      errors.add('Poste requis');
    }

    return errors;
  }

  /// Vérifier si les données sont valides
  bool get isValid => validate().isEmpty;

  @override
  String toString() {
    return 'AgentAssuranceModel(id: $uid, email: $email, nomComplet: $nomComplet, compagnie: $compagnie, agence: $agence)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgentAssuranceModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
