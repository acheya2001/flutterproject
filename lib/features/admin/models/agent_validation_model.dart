import 'package:cloud_firestore/cloud_firestore.dart';

/// 📋 Statuts de validation
enum ValidationStatus {
  enAttente,
  approuve,
  rejete,
}

extension ValidationStatusExtension on ValidationStatus {
  String get name {
    switch (this) {
      case ValidationStatus.enAttente:
        return 'En attente';
      case ValidationStatus.approuve:
        return 'Approuvé';
      case ValidationStatus.rejete:
        return 'Rejeté';
    }
  }

  String get value {
    switch (this) {
      case ValidationStatus.enAttente:
        return 'en_attente';
      case ValidationStatus.approuve:
        return 'approuve';
      case ValidationStatus.rejete:
        return 'rejete';
    }
  }

  static ValidationStatus fromString(String value) {
    switch (value) {
      case 'en_attente':
        return ValidationStatus.enAttente;
      case 'approuve':
        return ValidationStatus.approuve;
      case 'rejete':
        return ValidationStatus.rejete;
      default:
        return ValidationStatus.enAttente;
    }
  }
}

/// 🏢 Modèle pour la validation des agents d'assurance
class AgentValidationModel {
  final String id;
  final String userId; // ID de l'utilisateur qui demande la validation
  final String email;
  final String nom;
  final String prenom;
  final String telephone;
  final String compagnieDemandee;
  final String agenceDemandee;
  final List<String> zoneGeographique;
  final String delegation;
  final String matriculeAgent; // Matricule professionnel
  final String? numeroCarteAgent; // Numéro de carte d'agent
  final List<String> documents; // URLs des documents uploadés
  final ValidationStatus statut;
  final String? adminValidateur; // ID de l'admin qui a validé/rejeté
  final DateTime? dateValidation;
  final String? commentaireAdmin;
  final String? raisonRejet; // Raison du rejet si applicable
  final DateTime createdAt;
  final DateTime updatedAt;

  const AgentValidationModel({
    required this.id,
    required this.userId,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.compagnieDemandee,
    required this.agenceDemandee,
    required this.zoneGeographique,
    required this.delegation,
    required this.matriculeAgent,
    this.numeroCarteAgent,
    required this.documents,
    required this.statut,
    this.adminValidateur,
    this.dateValidation,
    this.commentaireAdmin,
    this.raisonRejet,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Créer depuis Firestore
  factory AgentValidationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AgentValidationModel(
      id: doc.id,
      userId: data['user_id'] ?? '',
      email: data['email'] ?? '',
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      telephone: data['telephone'] ?? '',
      compagnieDemandee: data['compagnie_demandee'] ?? '',
      agenceDemandee: data['agence_demandee'] ?? '',
      zoneGeographique: List<String>.from(data['zone_geographique'] ?? []),
      delegation: data['delegation'] ?? '',
      matriculeAgent: data['matricule_agent'] ?? '',
      numeroCarteAgent: data['numero_carte_agent'],
      documents: List<String>.from(data['documents'] ?? []),
      statut: ValidationStatusExtension.fromString(data['statut'] ?? 'en_attente'),
      adminValidateur: data['admin_validateur'],
      dateValidation: data['date_validation'] != null 
          ? (data['date_validation'] as Timestamp).toDate()
          : null,
      commentaireAdmin: data['commentaire_admin'],
      raisonRejet: data['raison_rejet'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'compagnie_demandee': compagnieDemandee,
      'agence_demandee': agenceDemandee,
      'zone_geographique': zoneGeographique,
      'delegation': delegation,
      'matricule_agent': matriculeAgent,
      'numero_carte_agent': numeroCarteAgent,
      'documents': documents,
      'statut': statut.value,
      'admin_validateur': adminValidateur,
      'date_validation': dateValidation != null 
          ? Timestamp.fromDate(dateValidation!)
          : null,
      'commentaire_admin': commentaireAdmin,
      'raison_rejet': raisonRejet,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copier avec modifications
  AgentValidationModel copyWith({
    String? id,
    String? userId,
    String? email,
    String? nom,
    String? prenom,
    String? telephone,
    String? compagnieDemandee,
    String? agenceDemandee,
    List<String>? zoneGeographique,
    String? delegation,
    String? matriculeAgent,
    String? numeroCarteAgent,
    List<String>? documents,
    ValidationStatus? statut,
    String? adminValidateur,
    DateTime? dateValidation,
    String? commentaireAdmin,
    String? raisonRejet,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AgentValidationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      telephone: telephone ?? this.telephone,
      compagnieDemandee: compagnieDemandee ?? this.compagnieDemandee,
      agenceDemandee: agenceDemandee ?? this.agenceDemandee,
      zoneGeographique: zoneGeographique ?? this.zoneGeographique,
      delegation: delegation ?? this.delegation,
      matriculeAgent: matriculeAgent ?? this.matriculeAgent,
      numeroCarteAgent: numeroCarteAgent ?? this.numeroCarteAgent,
      documents: documents ?? this.documents,
      statut: statut ?? this.statut,
      adminValidateur: adminValidateur ?? this.adminValidateur,
      dateValidation: dateValidation ?? this.dateValidation,
      commentaireAdmin: commentaireAdmin ?? this.commentaireAdmin,
      raisonRejet: raisonRejet ?? this.raisonRejet,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Vérifier si la demande est en attente
  bool get isEnAttente => statut == ValidationStatus.enAttente;

  /// Vérifier si la demande est approuvée
  bool get isApprouve => statut == ValidationStatus.approuve;

  /// Vérifier si la demande est rejetée
  bool get isRejete => statut == ValidationStatus.rejete;

  /// Obtenir le nom complet
  String get nomComplet => '$prenom $nom';

  /// Obtenir la zone géographique formatée
  String get zoneFormatee => zoneGeographique.join(', ');

  /// Obtenir le délai depuis la création (en jours)
  int get joursDepuisCreation {
    return DateTime.now().difference(createdAt).inDays;
  }

  /// Vérifier si la demande est urgente (plus de 7 jours)
  bool get isUrgente => joursDepuisCreation > 7;

  @override
  String toString() {
    return 'AgentValidationModel(id: $id, nom: $nomComplet, statut: ${statut.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgentValidationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 📄 Types de documents requis pour la validation
class RequiredDocuments {
  static const String carteAgent = 'carte_agent';
  static const String attestationTravail = 'attestation_travail';
  static const String cinRecto = 'cin_recto';
  static const String cinVerso = 'cin_verso';
  static const String diplome = 'diplome';
  static const String cv = 'cv';

  /// Obtenir tous les documents requis
  static List<String> get allRequired => [
    carteAgent,
    attestationTravail,
    cinRecto,
    cinVerso,
  ];

  /// Obtenir les documents optionnels
  static List<String> get optional => [
    diplome,
    cv,
  ];

  /// Obtenir le nom français d'un document
  static String getDocumentName(String document) {
    switch (document) {
      case carteAgent:
        return 'Carte d\'agent d\'assurance';
      case attestationTravail:
        return 'Attestation de travail';
      case cinRecto:
        return 'CIN (Recto)';
      case cinVerso:
        return 'CIN (Verso)';
      case diplome:
        return 'Diplôme';
      case cv:
        return 'CV';
      default:
        return document;
    }
  }
}
