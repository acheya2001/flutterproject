import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/auth/models/user_model.dart';
import '../utils/user_type.dart';

/// Modèle pour les compagnies d'assurance
class CompagnieAssurance {
  final String id;
  final String nom;
  final String siret;
  final String adresseSiege;
  final String telephone;
  final String email;
  final String logoUrl;
  final bool active;
  final DateTime dateCreation;
  final String? description;
  final Map<String, dynamic>? parametres;

  CompagnieAssurance({
    required this.id,
    required this.nom,
    required this.siret,
    required this.adresseSiege,
    required this.telephone,
    required this.email,
    required this.logoUrl,
    this.active = true,
    required this.dateCreation,
    this.description,
    this.parametres,
  });

  factory CompagnieAssurance.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CompagnieAssurance(
      id: doc.id,
      nom: data['nom'] ?? '',
      siret: data['siret'] ?? '',
      adresseSiege: data['adresseSiege'] ?? '',
      telephone: data['telephone'] ?? '',
      email: data['email'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      active: data['active'] ?? true,
      dateCreation: (data['dateCreation'] as Timestamp).toDate(),
      description: data['description'],
      parametres: data['parametres'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'siret': siret,
      'adresseSiege': adresseSiege,
      'telephone': telephone,
      'email': email,
      'logoUrl': logoUrl,
      'active': active,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'description': description,
      'parametres': parametres,
    };
  }
}

/// Modèle pour les agences
class AgenceAssurance {
  final String id;
  final String compagnieId;
  final String nom;
  final String code;
  final String adresse;
  final String gouvernorat;
  final String ville;
  final String telephone;
  final String email;
  final String responsableId;
  final bool active;
  final DateTime dateCreation;
  final Map<String, dynamic>? parametres;

  AgenceAssurance({
    required this.id,
    required this.compagnieId,
    required this.nom,
    required this.code,
    required this.adresse,
    required this.gouvernorat,
    required this.ville,
    required this.telephone,
    required this.email,
    required this.responsableId,
    this.active = true,
    required this.dateCreation,
    this.parametres,
  });

  factory AgenceAssurance.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AgenceAssurance(
      id: doc.id,
      compagnieId: data['compagnieId'] ?? '',
      nom: data['nom'] ?? '',
      code: data['code'] ?? '',
      adresse: data['adresse'] ?? '',
      gouvernorat: data['gouvernorat'] ?? '',
      ville: data['ville'] ?? '',
      telephone: data['telephone'] ?? '',
      email: data['email'] ?? '',
      responsableId: data['responsableId'] ?? '',
      active: data['active'] ?? true,
      dateCreation: (data['dateCreation'] as Timestamp).toDate(),
      parametres: data['parametres'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'compagnieId': compagnieId,
      'nom': nom,
      'code': code,
      'adresse': adresse,
      'gouvernorat': gouvernorat,
      'ville': ville,
      'telephone': telephone,
      'email': email,
      'responsableId': responsableId,
      'active': active,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'parametres': parametres,
    };
  }
}

/// Modèle pour les agents d'assurance
class AgentAssurance {
  final String id;
  final String compagnieId;
  final String agenceId;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final String matricule;
  final String poste;
  final bool active;
  final DateTime dateCreation;
  final DateTime? dateEmbauche;
  final Map<String, dynamic>? parametres;

  AgentAssurance({
    required this.id,
    required this.compagnieId,
    required this.agenceId,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.matricule,
    required this.poste,
    this.active = true,
    required this.dateCreation,
    this.dateEmbauche,
    this.parametres,
  });

  factory AgentAssurance.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AgentAssurance(
      id: doc.id,
      compagnieId: data['compagnieId'] ?? '',
      agenceId: data['agenceId'] ?? '',
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      email: data['email'] ?? '',
      telephone: data['telephone'] ?? '',
      matricule: data['matricule'] ?? '',
      poste: data['poste'] ?? '',
      active: data['active'] ?? true,
      dateCreation: (data['dateCreation'] as Timestamp).toDate(),
      dateEmbauche: data['dateEmbauche'] != null 
          ? (data['dateEmbauche'] as Timestamp).toDate() 
          : null,
      parametres: data['parametres'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'compagnieId': compagnieId,
      'agenceId': agenceId,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'matricule': matricule,
      'poste': poste,
      'active': active,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'dateEmbauche': dateEmbauche != null 
          ? Timestamp.fromDate(dateEmbauche!) 
          : null,
      'parametres': parametres,
    };
  }

  String get nomComplet => '$prenom $nom';
}

/// Énumération des rôles administratifs
enum RoleAdmin {
  superAdmin,
  responsableCompagnie,
  responsableAgence,
  agent,
}

extension RoleAdminExtension on RoleAdmin {
  String get label {
    switch (this) {
      case RoleAdmin.superAdmin:
        return 'Super Administrateur';
      case RoleAdmin.responsableCompagnie:
        return 'Responsable Compagnie';
      case RoleAdmin.responsableAgence:
        return 'Responsable Agence';
      case RoleAdmin.agent:
        return 'Agent';
    }
  }

  String get value {
    switch (this) {
      case RoleAdmin.superAdmin:
        return 'super_admin';
      case RoleAdmin.responsableCompagnie:
        return 'responsable_compagnie';
      case RoleAdmin.responsableAgence:
        return 'responsable_agence';
      case RoleAdmin.agent:
        return 'agent';
    }
  }
}
