/// 🏢 Structure hiérarchique des assurances
/// 
/// Hiérarchie: Super Admin → Admin Compagnie → Admin Agence → Agents

class CompagnieAssurance {
  final String id;
  final String nom;
  final String logo;
  final String adresse;
  final String telephone;
  final String email;
  final String adminCompagnieId; // ID de l'admin principal de la compagnie
  final DateTime dateCreation;
  final bool active;
  final Map<String, dynamic> metadata;

  const CompagnieAssurance({
    required this.id,
    required this.nom,
    required this.logo,
    required this.adresse,
    required this.telephone,
    required this.email,
    required this.adminCompagnieId,
    required this.dateCreation,
    this.active = true,
    this.metadata = const {},
  });

  factory CompagnieAssurance.fromMap(Map<String, dynamic> map) {
    return CompagnieAssurance(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      logo: map['logo'] ?? '',
      adresse: map['adresse'] ?? '',
      telephone: map['telephone'] ?? '',
      email: map['email'] ?? '',
      adminCompagnieId: map['adminCompagnieId'] ?? '',
      dateCreation: DateTime.fromMillisecondsSinceEpoch(map['dateCreation'] ?? 0),
      active: map['active'] ?? true,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'logo': logo,
      'adresse': adresse,
      'telephone': telephone,
      'email': email,
      'adminCompagnieId': adminCompagnieId,
      'dateCreation': dateCreation.millisecondsSinceEpoch,
      'active': active,
      'metadata': metadata,
    };
  }
}

class AgenceAssurance {
  final String id;
  final String compagnieId; // Référence à la compagnie parent
  final String nom;
  final String adresse;
  final String ville;
  final String gouvernorat;
  final String telephone;
  final String email;
  final String adminAgenceId; // ID de l'admin de cette agence
  final DateTime dateCreation;
  final bool active;
  final Map<String, dynamic> metadata;

  const AgenceAssurance({
    required this.id,
    required this.compagnieId,
    required this.nom,
    required this.adresse,
    required this.ville,
    required this.gouvernorat,
    required this.telephone,
    required this.email,
    required this.adminAgenceId,
    required this.dateCreation,
    this.active = true,
    this.metadata = const {},
  });

  factory AgenceAssurance.fromMap(Map<String, dynamic> map) {
    return AgenceAssurance(
      id: map['id'] ?? '',
      compagnieId: map['compagnieId'] ?? '',
      nom: map['nom'] ?? '',
      adresse: map['adresse'] ?? '',
      ville: map['ville'] ?? '',
      gouvernorat: map['gouvernorat'] ?? '',
      telephone: map['telephone'] ?? '',
      email: map['email'] ?? '',
      adminAgenceId: map['adminAgenceId'] ?? '',
      dateCreation: DateTime.fromMillisecondsSinceEpoch(map['dateCreation'] ?? 0),
      active: map['active'] ?? true,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'compagnieId': compagnieId,
      'nom': nom,
      'adresse': adresse,
      'ville': ville,
      'gouvernorat': gouvernorat,
      'telephone': telephone,
      'email': email,
      'adminAgenceId': adminAgenceId,
      'dateCreation': dateCreation.millisecondsSinceEpoch,
      'active': active,
      'metadata': metadata,
    };
  }
}

class AdminUser {
  final String id;
  final String email;
  final String nom;
  final String prenom;
  final String telephone;
  final AdminType type;
  final String? compagnieId; // null pour super admin
  final String? agenceId; // null pour admin compagnie et super admin
  final DateTime dateCreation;
  final bool active;
  final Map<String, dynamic> permissions;

  const AdminUser({
    required this.id,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.type,
    this.compagnieId,
    this.agenceId,
    required this.dateCreation,
    this.active = true,
    this.permissions = const {},
  });

  factory AdminUser.fromMap(Map<String, dynamic> map) {
    return AdminUser(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      telephone: map['telephone'] ?? '',
      type: AdminType.values.firstWhere(
        (e) => e.toString() == 'AdminType.${map['type']}',
        orElse: () => AdminType.agence,
      ),
      compagnieId: map['compagnieId'],
      agenceId: map['agenceId'],
      dateCreation: DateTime.fromMillisecondsSinceEpoch(map['dateCreation'] ?? 0),
      active: map['active'] ?? true,
      permissions: Map<String, dynamic>.from(map['permissions'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'type': type.toString().split('.').last,
      'compagnieId': compagnieId,
      'agenceId': agenceId,
      'dateCreation': dateCreation.millisecondsSinceEpoch,
      'active': active,
      'permissions': permissions,
    };
  }

  /// Vérifie si cet admin peut gérer une demande
  bool canManageRequest(String? requestCompagnieId, String? requestAgenceId) {
    switch (type) {
      case AdminType.superAdmin:
        return true; // Super admin peut tout gérer
      case AdminType.compagnie:
        return compagnieId == requestCompagnieId;
      case AdminType.agence:
        return compagnieId == requestCompagnieId && agenceId == requestAgenceId;
    }
  }
}

enum AdminType {
  superAdmin,
  compagnie,
  agence,
}

class DemandeAgent {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final String cin;
  final String compagnieId;
  final String agenceId;
  final String? documentUrl;
  final DateTime dateCreation;
  final StatutDemande statut;
  final String? adminTraitantId; // ID de l'admin qui a traité la demande
  final DateTime? dateTraitement;
  final String? commentaire;

  const DemandeAgent({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.cin,
    required this.compagnieId,
    required this.agenceId,
    this.documentUrl,
    required this.dateCreation,
    this.statut = StatutDemande.enAttente,
    this.adminTraitantId,
    this.dateTraitement,
    this.commentaire,
  });

  factory DemandeAgent.fromMap(Map<String, dynamic> map) {
    return DemandeAgent(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      email: map['email'] ?? '',
      telephone: map['telephone'] ?? '',
      cin: map['cin'] ?? '',
      compagnieId: map['compagnieId'] ?? '',
      agenceId: map['agenceId'] ?? '',
      documentUrl: map['documentUrl'],
      dateCreation: DateTime.fromMillisecondsSinceEpoch(map['dateCreation'] ?? 0),
      statut: StatutDemande.values.firstWhere(
        (e) => e.toString() == 'StatutDemande.${map['statut']}',
        orElse: () => StatutDemande.enAttente,
      ),
      adminTraitantId: map['adminTraitantId'],
      dateTraitement: map['dateTraitement'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(map['dateTraitement'])
        : null,
      commentaire: map['commentaire'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'cin': cin,
      'compagnieId': compagnieId,
      'agenceId': agenceId,
      'documentUrl': documentUrl,
      'dateCreation': dateCreation.millisecondsSinceEpoch,
      'statut': statut.toString().split('.').last,
      'adminTraitantId': adminTraitantId,
      'dateTraitement': dateTraitement?.millisecondsSinceEpoch,
      'commentaire': commentaire,
    };
  }
}

enum StatutDemande {
  enAttente,
  approuvee,
  rejetee,
}
