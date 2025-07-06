import 'package:cloud_firestore/cloud_firestore.dart';
import '../../vehicule/models/vehicule_model.dart';

/// 🚗 Modèle pour un véhicule assuré (extension du VehiculeModel)
class VehiculeAssureModel {
  final String id;
  final String vehiculeId; // Référence au VehiculeModel
  final String contratId; // Référence au ContratModel
  final String compagnieId;
  final String agenceId;
  final String conducteurId;
  final DateTime dateCreation;
  final DateTime? dateModification;
  final bool actif;
  
  // Informations d'assurance spécifiques
  final String numeroContrat;
  final String numeroQuittance;
  final DateTime dateDebutCouverture;
  final DateTime dateFinCouverture;
  final double valeurAssuree;
  final String formule; // Tiers, Tiers étendu, Tous risques
  final List<String> garanties;
  final double franchise;
  final Map<String, dynamic> conditions;

  VehiculeAssureModel({
    required this.id,
    required this.vehiculeId,
    required this.contratId,
    required this.compagnieId,
    required this.agenceId,
    required this.conducteurId,
    required this.dateCreation,
    this.dateModification,
    this.actif = true,
    required this.numeroContrat,
    required this.numeroQuittance,
    required this.dateDebutCouverture,
    required this.dateFinCouverture,
    required this.valeurAssuree,
    required this.formule,
    this.garanties = const [],
    required this.franchise,
    this.conditions = const {},
  });

  /// Créer depuis Firestore
  factory VehiculeAssureModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VehiculeAssureModel(
      id: doc.id,
      vehiculeId: data['vehicule_id'] ?? '',
      contratId: data['contrat_id'] ?? '',
      compagnieId: data['compagnie_id'] ?? '',
      agenceId: data['agence_id'] ?? '',
      conducteurId: data['conducteur_id'] ?? '',
      dateCreation: (data['date_creation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateModification: (data['date_modification'] as Timestamp?)?.toDate(),
      actif: data['actif'] ?? true,
      numeroContrat: data['numero_contrat'] ?? '',
      numeroQuittance: data['numero_quittance'] ?? '',
      dateDebutCouverture: (data['date_debut_couverture'] as Timestamp).toDate(),
      dateFinCouverture: (data['date_fin_couverture'] as Timestamp).toDate(),
      valeurAssuree: (data['valeur_assuree'] ?? 0).toDouble(),
      formule: data['formule'] ?? '',
      garanties: List<String>.from(data['garanties'] ?? []),
      franchise: (data['franchise'] ?? 0).toDouble(),
      conditions: Map<String, dynamic>.from(data['conditions'] ?? {}),
    );
  }

  /// Convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'vehicule_id': vehiculeId,
      'contrat_id': contratId,
      'compagnie_id': compagnieId,
      'agence_id': agenceId,
      'conducteur_id': conducteurId,
      'date_creation': Timestamp.fromDate(dateCreation),
      'date_modification': dateModification != null ? Timestamp.fromDate(dateModification!) : null,
      'actif': actif,
      'numero_contrat': numeroContrat,
      'numero_quittance': numeroQuittance,
      'date_debut_couverture': Timestamp.fromDate(dateDebutCouverture),
      'date_fin_couverture': Timestamp.fromDate(dateFinCouverture),
      'valeur_assuree': valeurAssuree,
      'formule': formule,
      'garanties': garanties,
      'franchise': franchise,
      'conditions': conditions,
    };
  }

  /// Vérifier si l'assurance est valide
  bool get estAssuranceValide {
    final maintenant = DateTime.now();
    return actif && 
           maintenant.isAfter(dateDebutCouverture) && 
           maintenant.isBefore(dateFinCouverture);
  }

  /// Obtenir le nombre de jours restants de couverture
  int get joursRestantsCouverture {
    final maintenant = DateTime.now();
    if (maintenant.isAfter(dateFinCouverture)) return 0;
    return dateFinCouverture.difference(maintenant).inDays;
  }

  /// Vérifier si l'assurance expire bientôt (moins de 30 jours)
  bool get expireBientot => joursRestantsCouverture <= 30 && joursRestantsCouverture > 0;

  /// Copier avec modifications
  VehiculeAssureModel copyWith({
    String? id,
    String? vehiculeId,
    String? contratId,
    String? compagnieId,
    String? agenceId,
    String? conducteurId,
    DateTime? dateCreation,
    DateTime? dateModification,
    bool? actif,
    String? numeroContrat,
    String? numeroQuittance,
    DateTime? dateDebutCouverture,
    DateTime? dateFinCouverture,
    double? valeurAssuree,
    String? formule,
    List<String>? garanties,
    double? franchise,
    Map<String, dynamic>? conditions,
  }) {
    return VehiculeAssureModel(
      id: id ?? this.id,
      vehiculeId: vehiculeId ?? this.vehiculeId,
      contratId: contratId ?? this.contratId,
      compagnieId: compagnieId ?? this.compagnieId,
      agenceId: agenceId ?? this.agenceId,
      conducteurId: conducteurId ?? this.conducteurId,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
      actif: actif ?? this.actif,
      numeroContrat: numeroContrat ?? this.numeroContrat,
      numeroQuittance: numeroQuittance ?? this.numeroQuittance,
      dateDebutCouverture: dateDebutCouverture ?? this.dateDebutCouverture,
      dateFinCouverture: dateFinCouverture ?? this.dateFinCouverture,
      valeurAssuree: valeurAssuree ?? this.valeurAssuree,
      formule: formule ?? this.formule,
      garanties: garanties ?? this.garanties,
      franchise: franchise ?? this.franchise,
      conditions: conditions ?? this.conditions,
    );
  }

  @override
  String toString() {
    return 'VehiculeAssureModel(id: $id, contrat: $numeroContrat, valide: $estAssuranceValide)';
  }
}

/// 🚗 Modèle combiné véhicule + assurance pour l'affichage
class VehiculeAvecAssuranceModel {
  final VehiculeModel vehicule;
  final VehiculeAssureModel? assurance;
  final String? compagnieNom;
  final String? agenceNom;

  VehiculeAvecAssuranceModel({
    required this.vehicule,
    this.assurance,
    this.compagnieNom,
    this.agenceNom,
  });

  /// Vérifier si le véhicule est assuré
  bool get estAssure => assurance != null && assurance!.estAssuranceValide;

  /// Obtenir le statut d'assurance
  String get statutAssurance {
    if (assurance == null) return 'Non assuré';
    if (!assurance!.actif) return 'Assurance suspendue';
    if (!assurance!.estAssuranceValide) return 'Assurance expirée';
    if (assurance!.expireBientot) return 'Expire bientôt';
    return 'Assuré';
  }

  /// Obtenir la couleur du statut
  String get couleurStatut {
    if (assurance == null) return 'red';
    if (!assurance!.actif) return 'orange';
    if (!assurance!.estAssuranceValide) return 'red';
    if (assurance!.expireBientot) return 'orange';
    return 'green';
  }

  /// Obtenir les informations d'assurance pour l'affichage
  Map<String, String> get infosAssurance {
    if (assurance == null) {
      return {
        'compagnie': 'Aucune',
        'contrat': 'Aucun',
        'validite': 'Non assuré',
        'formule': 'Aucune',
      };
    }

    return {
      'compagnie': compagnieNom ?? 'Inconnue',
      'contrat': assurance!.numeroContrat,
      'validite': '${assurance!.dateDebutCouverture.day}/${assurance!.dateDebutCouverture.month}/${assurance!.dateDebutCouverture.year} - ${assurance!.dateFinCouverture.day}/${assurance!.dateFinCouverture.month}/${assurance!.dateFinCouverture.year}',
      'formule': assurance!.formule,
      'agence': agenceNom ?? 'Inconnue',
      'quittance': assurance!.numeroQuittance,
    };
  }

  @override
  String toString() {
    return 'VehiculeAvecAssuranceModel(vehicule: ${vehicule.nomComplet}, assure: $estAssure)';
  }
}

/// 🚗 Extension pour le VehiculeModel existant
extension VehiculeModelExtension on VehiculeModel {
  /// Obtenir le nom complet du véhicule
  String get nomComplet => '$marque $modele';

  /// Obtenir l'immatriculation formatée
  String get immatriculationFormatee {
    if (immatriculation.length >= 6) {
      return '${immatriculation.substring(0, 3)} TN ${immatriculation.substring(3)}';
    }
    return immatriculation;
  }

  /// Vérifier si l'assurance est valide (utilise les champs existants)
  bool get estAssuranceValideActuelle {
    return dateFinValidite != null && dateFinValidite!.isAfter(DateTime.now());
  }

  /// Obtenir les informations d'assurance actuelles
  Map<String, String> get infosAssuranceActuelles {
    return {
      'compagnie': compagnieAssurance,
      'contrat': numeroContrat,
      'agence': agence,
      'quittance': quittance,
      'validite': dateFinValidite != null 
          ? '${dateDebutValidite?.day}/${dateDebutValidite?.month}/${dateDebutValidite?.year} - ${dateFinValidite!.day}/${dateFinValidite!.month}/${dateFinValidite!.year}'
          : 'Non définie',
    };
  }
}
