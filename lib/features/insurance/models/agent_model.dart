import 'package:cloud_firestore/cloud_firestore.dart';

/// 👨‍💼 Modèle pour un agent d'assurance
class AgentModel {
  final String uid;
  final String email;
  final String nom;
  final String prenom;
  final String telephone;
  final String? adresse;
  final String compagnieId;
  final String agenceId;
  final String matricule; // Numéro d'agent unique
  final String poste; // Conseiller, Chef d'agence, etc.
  final List<String> specialites; // Auto, Habitation, Vie, etc.
  final bool peutCreerContrats;
  final bool peutValiderSinistres;
  final double? commission; // Pourcentage de commission
  final DateTime dateCreation;
  final DateTime? dateModification;
  final bool actif;
  final List<String> permissions;
  final Map<String, dynamic> statistiques; // Nombre de contrats, sinistres traités, etc.

  AgentModel({
    required this.uid,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.telephone,
    this.adresse,
    required this.compagnieId,
    required this.agenceId,
    required this.matricule,
    required this.poste,
    this.specialites = const [],
    this.peutCreerContrats = true,
    this.peutValiderSinistres = true,
    this.commission,
    required this.dateCreation,
    this.dateModification,
    this.actif = true,
    this.permissions = const [],
    this.statistiques = const {},
  });

  /// Créer depuis Firestore
  factory AgentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AgentModel(
      uid: doc.id,
      email: data['email'] ?? '',
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      telephone: data['telephone'] ?? '',
      adresse: data['adresse'],
      compagnieId: data['compagnie_id'] ?? '',
      agenceId: data['agence_id'] ?? '',
      matricule: data['matricule'] ?? '',
      poste: data['poste'] ?? '',
      specialites: List<String>.from(data['specialites'] ?? []),
      peutCreerContrats: data['peut_creer_contrats'] ?? true,
      peutValiderSinistres: data['peut_valider_sinistres'] ?? true,
      commission: data['commission']?.toDouble(),
      permissions: List<String>.from(data['permissions'] ?? []),
      dateCreation: (data['date_creation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateModification: (data['date_modification'] as Timestamp?)?.toDate(),
      actif: data['actif'] ?? true,
      statistiques: Map<String, dynamic>.from(data['statistiques'] ?? {}),
    );
  }

  /// Convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'adresse': adresse,
      'compagnie_id': compagnieId,
      'agence_id': agenceId,
      'matricule': matricule,
      'poste': poste,
      'specialites': specialites,
      'peut_creer_contrats': peutCreerContrats,
      'peut_valider_sinistres': peutValiderSinistres,
      'commission': commission,
      'permissions': permissions,
      'date_creation': Timestamp.fromDate(dateCreation),
      'date_modification': dateModification != null ? Timestamp.fromDate(dateModification!) : null,
      'actif': actif,
      'statistiques': statistiques,
    };
  }

  /// Obtenir le nom complet
  String get nomComplet => '$prenom $nom';

  /// Vérifier si l'agent peut effectuer une action
  bool peutEffectuerAction(String action) {
    switch (action) {
      case 'creer_contrat':
        return peutCreerContrats && actif;
      case 'valider_sinistre':
        return peutValiderSinistres && actif;
      default:
        return permissions.contains(action) && actif;
    }
  }

  /// Copier avec modifications
  AgentModel copyWith({
    String? uid,
    String? email,
    String? nom,
    String? prenom,
    String? telephone,
    String? adresse,
    String? compagnieId,
    String? agenceId,
    String? matricule,
    String? poste,
    List<String>? specialites,
    bool? peutCreerContrats,
    bool? peutValiderSinistres,
    double? commission,
    DateTime? dateCreation,
    DateTime? dateModification,
    bool? actif,
    List<String>? permissions,
    Map<String, dynamic>? statistiques,
  }) {
    return AgentModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      telephone: telephone ?? this.telephone,
      adresse: adresse ?? this.adresse,
      compagnieId: compagnieId ?? this.compagnieId,
      agenceId: agenceId ?? this.agenceId,
      matricule: matricule ?? this.matricule,
      poste: poste ?? this.poste,
      specialites: specialites ?? this.specialites,
      peutCreerContrats: peutCreerContrats ?? this.peutCreerContrats,
      peutValiderSinistres: peutValiderSinistres ?? this.peutValiderSinistres,
      commission: commission ?? this.commission,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
      actif: actif ?? this.actif,
      permissions: permissions ?? this.permissions,
      statistiques: statistiques ?? this.statistiques,
    );
  }

  @override
  String toString() {
    return 'AgentModel(uid: $uid, nom: $nomComplet, matricule: $matricule, agence: $agenceId)';
  }
}

/// 🧑‍🔧 Modèle pour un expert automobile
class ExpertModel {
  final String uid;
  final String email;
  final String nom;
  final String prenom;
  final String telephone;
  final String? adresse;
  final String numeroAgrement; // Numéro d'agrément expert
  final List<String> compagniesPartenaires; // IDs des compagnies avec lesquelles il travaille
  final List<String> specialites; // Automobile, Moto, Poids lourd, etc.
  final String zoneIntervention; // Gouvernorat ou région
  final bool disponible;
  final double? tarifHoraire;
  final DateTime dateCreation;
  final DateTime? dateModification;
  final bool actif;
  final List<String> permissions;
  final Map<String, dynamic> statistiques; // Nombre d'expertises, délai moyen, etc.

  ExpertModel({
    required this.uid,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.telephone,
    this.adresse,
    required this.numeroAgrement,
    this.compagniesPartenaires = const [],
    this.specialites = const [],
    required this.zoneIntervention,
    this.disponible = true,
    this.tarifHoraire,
    required this.dateCreation,
    this.dateModification,
    this.actif = true,
    this.permissions = const [],
    this.statistiques = const {},
  });

  /// Créer depuis Firestore
  factory ExpertModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpertModel(
      uid: doc.id,
      email: data['email'] ?? '',
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      telephone: data['telephone'] ?? '',
      adresse: data['adresse'],
      numeroAgrement: data['numero_agrement'] ?? '',
      compagniesPartenaires: List<String>.from(data['compagnies_partenaires'] ?? []),
      specialites: List<String>.from(data['specialites'] ?? []),
      zoneIntervention: data['zone_intervention'] ?? '',
      disponible: data['disponible'] ?? true,
      tarifHoraire: data['tarif_horaire']?.toDouble(),
      permissions: List<String>.from(data['permissions'] ?? []),
      dateCreation: (data['date_creation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateModification: (data['date_modification'] as Timestamp?)?.toDate(),
      actif: data['actif'] ?? true,
      statistiques: Map<String, dynamic>.from(data['statistiques'] ?? {}),
    );
  }

  /// Convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'adresse': adresse,
      'numero_agrement': numeroAgrement,
      'compagnies_partenaires': compagniesPartenaires,
      'specialites': specialites,
      'zone_intervention': zoneIntervention,
      'disponible': disponible,
      'tarif_horaire': tarifHoraire,
      'permissions': permissions,
      'date_creation': Timestamp.fromDate(dateCreation),
      'date_modification': dateModification != null ? Timestamp.fromDate(dateModification!) : null,
      'actif': actif,
      'statistiques': statistiques,
    };
  }

  /// Obtenir le nom complet
  String get nomComplet => '$prenom $nom';

  /// Vérifier si l'expert peut travailler avec une compagnie
  bool peutTravailerAvec(String compagnieId) {
    return compagniesPartenaires.contains(compagnieId) && 
           disponible && 
           actif;
  }

  @override
  String toString() {
    return 'ExpertModel(uid: $uid, nom: $nomComplet, agrement: $numeroAgrement, zone: $zoneIntervention)';
  }
}
