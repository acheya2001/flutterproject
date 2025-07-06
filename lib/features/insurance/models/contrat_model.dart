import 'package:cloud_firestore/cloud_firestore.dart';

/// 📄 Modèle pour un contrat d'assurance automobile
class ContratModel {
  final String id;
  final String numeroContrat; // Numéro unique du contrat
  final String compagnieId;
  final String agenceId;
  final String agentId; // Agent qui a créé le contrat
  final String conducteurId; // ID du conducteur assuré
  final String vehiculeId; // ID du véhicule assuré
  final DateTime dateDebut;
  final DateTime dateFin;
  final DateTime dateCreation;
  final DateTime? dateModification;
  final ContratStatus status;
  final TypeFormule formule; // Tiers simple, Tiers étendu, Tous risques
  final double prime; // Prime annuelle
  final double franchise; // Franchise en cas de sinistre
  final List<String> garanties; // Liste des garanties incluses
  final Map<String, dynamic> conditions; // Conditions particulières
  final String? numeroQuittance; // Numéro de quittance de paiement
  final DateTime? dateQuittance;

  ContratModel({
    required this.id,
    required this.numeroContrat,
    required this.compagnieId,
    required this.agenceId,
    required this.agentId,
    required this.conducteurId,
    required this.vehiculeId,
    required this.dateDebut,
    required this.dateFin,
    required this.dateCreation,
    this.dateModification,
    this.status = ContratStatus.actif,
    required this.formule,
    required this.prime,
    required this.franchise,
    this.garanties = const [],
    this.conditions = const {},
    this.numeroQuittance,
    this.dateQuittance,
  });

  /// Créer depuis Firestore
  factory ContratModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContratModel(
      id: doc.id,
      numeroContrat: data['numero_contrat'] ?? '',
      compagnieId: data['compagnie_id'] ?? '',
      agenceId: data['agence_id'] ?? '',
      agentId: data['agent_id'] ?? '',
      conducteurId: data['conducteur_id'] ?? '',
      vehiculeId: data['vehicule_id'] ?? '',
      dateDebut: (data['date_debut'] as Timestamp).toDate(),
      dateFin: (data['date_fin'] as Timestamp).toDate(),
      dateCreation: (data['date_creation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateModification: (data['date_modification'] as Timestamp?)?.toDate(),
      status: ContratStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ContratStatus.actif,
      ),
      formule: TypeFormule.values.firstWhere(
        (f) => f.name == data['formule'],
        orElse: () => TypeFormule.tiersSimple,
      ),
      prime: (data['prime'] ?? 0).toDouble(),
      franchise: (data['franchise'] ?? 0).toDouble(),
      garanties: List<String>.from(data['garanties'] ?? []),
      conditions: Map<String, dynamic>.from(data['conditions'] ?? {}),
      numeroQuittance: data['numero_quittance'],
      dateQuittance: (data['date_quittance'] as Timestamp?)?.toDate(),
    );
  }

  /// Convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'numero_contrat': numeroContrat,
      'compagnie_id': compagnieId,
      'agence_id': agenceId,
      'agent_id': agentId,
      'conducteur_id': conducteurId,
      'vehicule_id': vehiculeId,
      'date_debut': Timestamp.fromDate(dateDebut),
      'date_fin': Timestamp.fromDate(dateFin),
      'date_creation': Timestamp.fromDate(dateCreation),
      'date_modification': dateModification != null ? Timestamp.fromDate(dateModification!) : null,
      'status': status.name,
      'formule': formule.name,
      'prime': prime,
      'franchise': franchise,
      'garanties': garanties,
      'conditions': conditions,
      'numero_quittance': numeroQuittance,
      'date_quittance': dateQuittance != null ? Timestamp.fromDate(dateQuittance!) : null,
    };
  }

  /// Vérifier si le contrat est valide
  bool get estValide {
    final maintenant = DateTime.now();
    return status == ContratStatus.actif && 
           maintenant.isAfter(dateDebut) && 
           maintenant.isBefore(dateFin);
  }

  /// Obtenir le nombre de jours restants
  int get joursRestants {
    final maintenant = DateTime.now();
    if (maintenant.isAfter(dateFin)) return 0;
    return dateFin.difference(maintenant).inDays;
  }

  /// Vérifier si le contrat expire bientôt (moins de 30 jours)
  bool get expireBientot => joursRestants <= 30 && joursRestants > 0;

  /// Copier avec modifications
  ContratModel copyWith({
    String? id,
    String? numeroContrat,
    String? compagnieId,
    String? agenceId,
    String? agentId,
    String? conducteurId,
    String? vehiculeId,
    DateTime? dateDebut,
    DateTime? dateFin,
    DateTime? dateCreation,
    DateTime? dateModification,
    ContratStatus? status,
    TypeFormule? formule,
    double? prime,
    double? franchise,
    List<String>? garanties,
    Map<String, dynamic>? conditions,
    String? numeroQuittance,
    DateTime? dateQuittance,
  }) {
    return ContratModel(
      id: id ?? this.id,
      numeroContrat: numeroContrat ?? this.numeroContrat,
      compagnieId: compagnieId ?? this.compagnieId,
      agenceId: agenceId ?? this.agenceId,
      agentId: agentId ?? this.agentId,
      conducteurId: conducteurId ?? this.conducteurId,
      vehiculeId: vehiculeId ?? this.vehiculeId,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
      status: status ?? this.status,
      formule: formule ?? this.formule,
      prime: prime ?? this.prime,
      franchise: franchise ?? this.franchise,
      garanties: garanties ?? this.garanties,
      conditions: conditions ?? this.conditions,
      numeroQuittance: numeroQuittance ?? this.numeroQuittance,
      dateQuittance: dateQuittance ?? this.dateQuittance,
    );
  }

  @override
  String toString() {
    return 'ContratModel(id: $id, numero: $numeroContrat, status: $status, valide: $estValide)';
  }
}

/// 📋 Statut d'un contrat
enum ContratStatus {
  actif,
  suspendu,
  expire,
  resilie,
  enAttente,
}

/// 🛡️ Types de formules d'assurance
enum TypeFormule {
  tiersSimple,
  tiersEtendu,
  tousRisques,
}

/// 🚗 Extension pour les formules
extension TypeFormuleExtension on TypeFormule {
  String get displayName {
    switch (this) {
      case TypeFormule.tiersSimple:
        return 'Tiers Simple';
      case TypeFormule.tiersEtendu:
        return 'Tiers Étendu';
      case TypeFormule.tousRisques:
        return 'Tous Risques';
    }
  }

  String get description {
    switch (this) {
      case TypeFormule.tiersSimple:
        return 'Responsabilité civile uniquement';
      case TypeFormule.tiersEtendu:
        return 'RC + Vol + Incendie + Bris de glace';
      case TypeFormule.tousRisques:
        return 'Couverture complète tous dommages';
    }
  }

  List<String> get garantiesIncluses {
    switch (this) {
      case TypeFormule.tiersSimple:
        return ['Responsabilité civile', 'Défense recours'];
      case TypeFormule.tiersEtendu:
        return [
          'Responsabilité civile',
          'Défense recours',
          'Vol',
          'Incendie',
          'Bris de glace',
          'Catastrophes naturelles'
        ];
      case TypeFormule.tousRisques:
        return [
          'Responsabilité civile',
          'Défense recours',
          'Vol',
          'Incendie',
          'Bris de glace',
          'Catastrophes naturelles',
          'Dommages tous accidents',
          'Assistance 24h/24',
          'Véhicule de remplacement'
        ];
    }
  }
}

/// 📋 Extension pour les statuts
extension ContratStatusExtension on ContratStatus {
  String get displayName {
    switch (this) {
      case ContratStatus.actif:
        return 'Actif';
      case ContratStatus.suspendu:
        return 'Suspendu';
      case ContratStatus.expire:
        return 'Expiré';
      case ContratStatus.resilie:
        return 'Résilié';
      case ContratStatus.enAttente:
        return 'En Attente';
    }
  }

  bool get estActif => this == ContratStatus.actif;
}
