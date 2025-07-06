import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../utils/user_type.dart';
import 'user_model.dart';

class AssureurModel extends UserModel {
  final String compagnie;
  final String matricule;
  final String agenceId;
  final String agenceNom;
  final String gouvernorat;
  final String poste; // Agent Commercial, Responsable Agence, etc.
  final List<String> permissions; // Permissions spécifiques
  final List<String> dossierIds;
  final DateTime? dateEmbauche;
  final String statut; // actif, suspendu, inactif

  AssureurModel({
    required String id,
    required String email,
    required String nom,
    required String prenom,
    required String telephone,
    required this.compagnie,
    required this.matricule,
    required this.agenceId,
    required this.agenceNom,
    required this.gouvernorat,
    required this.poste,
    this.permissions = const [],
    this.dossierIds = const [],
    this.dateEmbauche,
    this.statut = 'actif',
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
          userType: UserType.assureur,
          dateCreation: createdAt,
          dateModification: updatedAt,
          compagnieId: compagnie,
          matricule: matricule,
        );

  @override
  Map<String, dynamic> toFirestore() {
    final map = super.toFirestore();
    map.addAll({
      'compagnie': compagnie,
      'agenceId': agenceId,
      'agenceNom': agenceNom,
      'gouvernorat': gouvernorat,
      'poste': poste,
      'permissions': permissions,
      'dossierIds': dossierIds,
      'dateEmbauche': dateEmbauche?.toIso8601String(),
      'statut': statut,
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
        agenceId: map['agenceId'] as String? ?? '',
        agenceNom: map['agenceNom'] as String? ?? '',
        gouvernorat: map['gouvernorat'] as String? ?? '',
        poste: map['poste'] as String? ?? 'Agent Commercial',
        permissions: List<String>.from(map['permissions'] ?? []),
        dossierIds: List<String>.from(map['dossierIds'] ?? []),
        dateEmbauche: map['dateEmbauche'] != null ? DateTime.parse(map['dateEmbauche']) : null,
        statut: map['statut'] as String? ?? 'actif',
        adresse: map['adresse'] as String?,
        createdAt: (map['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (map['dateModification'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
        agenceId: '',
        agenceNom: '',
        gouvernorat: '',
        poste: 'Agent Commercial',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  String toString() {
    return 'AssureurModel{id: $id, email: $email, nom: $nom, prenom: $prenom, compagnie: $compagnie, agence: $agenceNom, gouvernorat: $gouvernorat, poste: $poste}';
  }
}
