import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// 🏢 Hiérarchie d'Administration
/// 
/// 1. SUPER_ADMIN - Admin principal de l'application (constat.tunisie.app@gmail.com)
/// 2. ADMIN_COMPAGNIE - Admin de chaque compagnie d'assurance
/// 3. ADMIN_AGENCE - Admin de chaque agence
/// 4. ADMIN_REGIONAL - Admin régional (gouvernorat)

enum TypeAdmin {
  superAdmin,      // Admin principal de l'app
  adminCompagnie,  // Admin d'une compagnie
  adminAgence,     // Admin d'une agence
  adminRegional,   // Admin régional
}

/// 📋 Modèle pour un administrateur
class AdminHierarchyModel {
  final String id;
  final String email;
  final String nom;
  final String prenom;
  final String telephone;
  final TypeAdmin typeAdmin;
  final String? compagnieId;  // Pour admin compagnie/agence
  final String? agenceId;     // Pour admin agence
  final List<String> gouvernoratsGeres; // Pour admin régional
  final List<String> permissions;
  final bool actif;
  final DateTime dateCreation;
  final DateTime? derniereConnexion;
  final Map<String, int> statistiques;

  const AdminHierarchyModel({
    required this.id,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.typeAdmin,
    this.compagnieId,
    this.agenceId,
    required this.gouvernoratsGeres,
    required this.permissions,
    required this.actif,
    required this.dateCreation,
    this.derniereConnexion,
    required this.statistiques,
  });

  /// Créer depuis Firestore
  factory AdminHierarchyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminHierarchyModel.fromMap(data, doc.id);
  }

  /// Créer depuis Map
  factory AdminHierarchyModel.fromMap(Map<String, dynamic> data, [String? id]) {
    return AdminHierarchyModel(
      id: id ?? data['id'] ?? '',
      email: data['email'] ?? '',
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      telephone: data['telephone'] ?? '',
      typeAdmin: _parseTypeAdmin(data['typeAdmin']),
      compagnieId: data['compagnieId'],
      agenceId: data['agenceId'],
      gouvernoratsGeres: List<String>.from(data['gouvernoratsGeres'] ?? []),
      permissions: List<String>.from(data['permissions'] ?? []),
      actif: data['actif'] ?? true,
      dateCreation: (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      derniereConnexion: (data['derniereConnexion'] as Timestamp?)?.toDate(),
      statistiques: Map<String, int>.from(data['statistiques'] ?? {
        'demandesTraitees': 0,
        'demandesApprouvees': 0,
        'demandesRefusees': 0,
      }),
    );
  }

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'typeAdmin': typeAdmin.toString().split('.').last,
      'compagnieId': compagnieId,
      'agenceId': agenceId,
      'gouvernoratsGeres': gouvernoratsGeres,
      'permissions': permissions,
      'actif': actif,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'derniereConnexion': derniereConnexion != null 
          ? Timestamp.fromDate(derniereConnexion!) 
          : null,
      'statistiques': statistiques,
    };
  }

  /// Parser le type d'admin depuis string
  static TypeAdmin _parseTypeAdmin(dynamic value) {
    if (value == null) return TypeAdmin.adminRegional;
    
    final stringValue = value.toString().toLowerCase();
    switch (stringValue) {
      case 'superadmin':
        return TypeAdmin.superAdmin;
      case 'admincompagnie':
        return TypeAdmin.adminCompagnie;
      case 'adminagence':
        return TypeAdmin.adminAgence;
      default:
        return TypeAdmin.adminRegional;
    }
  }

  /// Vérifier si l'admin peut approuver une demande
  bool peutApprouverDemande(Map<String, dynamic> demande) {
    switch (typeAdmin) {
      case TypeAdmin.superAdmin:
        return true; // Super admin peut tout approuver
        
      case TypeAdmin.adminCompagnie:
        return demande['compagnie'] != null && 
               _getCompagnieFromName(demande['compagnie']) == compagnieId;
        
      case TypeAdmin.adminAgence:
        return demande['compagnie'] != null && 
               demande['agence'] != null &&
               _getCompagnieFromName(demande['compagnie']) == compagnieId &&
               _getAgenceFromName(demande['agence']) == agenceId;
        
      case TypeAdmin.adminRegional:
        return demande['gouvernorat'] != null &&
               gouvernoratsGeres.contains(demande['gouvernorat']);
    }
  }

  /// Obtenir les permissions selon le type d'admin
  static List<String> getPermissionsParType(TypeAdmin type) {
    switch (type) {
      case TypeAdmin.superAdmin:
        return [
          'approuver_toutes_demandes',
          'gerer_admins',
          'gerer_compagnies',
          'voir_statistiques_globales',
          'gerer_experts',
          'gerer_constats',
        ];
        
      case TypeAdmin.adminCompagnie:
        return [
          'approuver_demandes_compagnie',
          'gerer_agences',
          'gerer_agents_compagnie',
          'voir_statistiques_compagnie',
          'gerer_contrats_compagnie',
        ];
        
      case TypeAdmin.adminAgence:
        return [
          'approuver_demandes_agence',
          'gerer_agents_agence',
          'voir_statistiques_agence',
          'gerer_contrats_agence',
        ];
        
      case TypeAdmin.adminRegional:
        return [
          'approuver_demandes_region',
          'voir_statistiques_region',
          'gerer_constats_region',
        ];
    }
  }

  /// Obtenir le nom d'affichage du type d'admin
  String get typeAdminNom {
    switch (typeAdmin) {
      case TypeAdmin.superAdmin:
        return 'Super Administrateur';
      case TypeAdmin.adminCompagnie:
        return 'Admin Compagnie';
      case TypeAdmin.adminAgence:
        return 'Admin Agence';
      case TypeAdmin.adminRegional:
        return 'Admin Régional';
    }
  }

  /// Obtenir la description du rôle
  String get descriptionRole {
    switch (typeAdmin) {
      case TypeAdmin.superAdmin:
        return 'Gestion complète de l\'application';
      case TypeAdmin.adminCompagnie:
        return 'Gestion de la compagnie et ses agences';
      case TypeAdmin.adminAgence:
        return 'Gestion de l\'agence et ses agents';
      case TypeAdmin.adminRegional:
        return 'Gestion régionale (${gouvernoratsGeres.join(', ')})';
    }
  }

  /// Méthodes utilitaires pour mapper noms vers IDs
  String? _getCompagnieFromName(String nomCompagnie) {
    // TODO: Implémenter la logique de mapping nom -> ID
    // Pour l'instant, retourner le nom comme ID
    return nomCompagnie;
  }

  String? _getAgenceFromName(String nomAgence) {
    // TODO: Implémenter la logique de mapping nom -> ID
    // Pour l'instant, retourner le nom comme ID
    return nomAgence;
  }

  /// Copier avec modifications
  AdminHierarchyModel copyWith({
    String? id,
    String? email,
    String? nom,
    String? prenom,
    String? telephone,
    TypeAdmin? typeAdmin,
    String? compagnieId,
    String? agenceId,
    List<String>? gouvernoratsGeres,
    List<String>? permissions,
    bool? actif,
    DateTime? dateCreation,
    DateTime? derniereConnexion,
    Map<String, int>? statistiques,
  }) {
    return AdminHierarchyModel(
      id: id ?? this.id,
      email: email ?? this.email,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      telephone: telephone ?? this.telephone,
      typeAdmin: typeAdmin ?? this.typeAdmin,
      compagnieId: compagnieId ?? this.compagnieId,
      agenceId: agenceId ?? this.agenceId,
      gouvernoratsGeres: gouvernoratsGeres ?? this.gouvernoratsGeres,
      permissions: permissions ?? this.permissions,
      actif: actif ?? this.actif,
      dateCreation: dateCreation ?? this.dateCreation,
      derniereConnexion: derniereConnexion ?? this.derniereConnexion,
      statistiques: statistiques ?? this.statistiques,
    );
  }

  @override
  String toString() {
    return 'AdminHierarchyModel(id: $id, email: $email, type: $typeAdminNom)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminHierarchyModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 📊 Modèle pour une demande d'inscription avec workflow d'approbation
class DemandeInscriptionModel {
  final String id;
  final String email;
  final String nom;
  final String prenom;
  final String telephone;
  final String compagnie;
  final String agence;
  final String gouvernorat;
  final String poste;
  final String numeroAgent;
  final String userType;
  final String statut; // en_attente, approuvee, refusee, en_cours_traitement
  final DateTime dateCreation;
  final String? adminTraitantId;
  final DateTime? dateTraitement;
  final String? motifRefus;
  final String? commentaireAdmin;
  final String motDePasseTemporaire;
  final List<String> documentsJoints;

  const DemandeInscriptionModel({
    required this.id,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.compagnie,
    required this.agence,
    required this.gouvernorat,
    required this.poste,
    required this.numeroAgent,
    required this.userType,
    required this.statut,
    required this.dateCreation,
    this.adminTraitantId,
    this.dateTraitement,
    this.motifRefus,
    this.commentaireAdmin,
    required this.motDePasseTemporaire,
    required this.documentsJoints,
  });

  /// Créer depuis Firestore
  factory DemandeInscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DemandeInscriptionModel.fromMap(data, doc.id);
  }

  /// Créer depuis Map
  factory DemandeInscriptionModel.fromMap(Map<String, dynamic> data, [String? id]) {
    return DemandeInscriptionModel(
      id: id ?? data['id'] ?? '',
      email: data['email'] ?? '',
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      telephone: data['telephone'] ?? '',
      compagnie: data['compagnie'] ?? '',
      agence: data['agence'] ?? '',
      gouvernorat: data['gouvernorat'] ?? '',
      poste: data['poste'] ?? '',
      numeroAgent: data['numeroAgent'] ?? '',
      userType: data['userType'] ?? 'assureur',
      statut: data['statut'] ?? 'en_attente',
      dateCreation: (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminTraitantId: data['adminTraitantId'],
      dateTraitement: (data['dateTraitement'] as Timestamp?)?.toDate(),
      motifRefus: data['motifRefus'],
      commentaireAdmin: data['commentaireAdmin'],
      motDePasseTemporaire: data['motDePasseTemporaire'] ?? '',
      documentsJoints: List<String>.from(data['documentsJoints'] ?? []),
    );
  }

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'compagnie': compagnie,
      'agence': agence,
      'gouvernorat': gouvernorat,
      'poste': poste,
      'numeroAgent': numeroAgent,
      'userType': userType,
      'statut': statut,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'adminTraitantId': adminTraitantId,
      'dateTraitement': dateTraitement != null 
          ? Timestamp.fromDate(dateTraitement!) 
          : null,
      'motifRefus': motifRefus,
      'commentaireAdmin': commentaireAdmin,
      'motDePasseTemporaire': motDePasseTemporaire,
      'documentsJoints': documentsJoints,
    };
  }

  /// Vérifier si la demande peut être traitée
  bool get peutEtreTraitee => statut == 'en_attente';

  /// Obtenir la couleur selon le statut
  Color get couleurStatut {
    switch (statut) {
      case 'en_attente':
        return Colors.orange;
      case 'en_cours_traitement':
        return Colors.blue;
      case 'approuvee':
        return Colors.green;
      case 'refusee':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Obtenir l'icône selon le statut
  IconData get iconeStatut {
    switch (statut) {
      case 'en_attente':
        return Icons.pending_actions;
      case 'en_cours_traitement':
        return Icons.hourglass_empty;
      case 'approuvee':
        return Icons.check_circle;
      case 'refusee':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  String toString() {
    return 'DemandeInscriptionModel(id: $id, email: $email, statut: $statut)';
  }
}
