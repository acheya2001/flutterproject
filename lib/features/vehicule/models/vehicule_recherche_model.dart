import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔍 Contexte de recherche véhicule
enum ContexteRecherche {
  declarationAccident,
  verification,
  expertise,
  controle,
}

extension ContexteRechercheExtension on ContexteRecherche {
  String get name {
    switch (this) {
      case ContexteRecherche.declarationAccident:
        return 'Déclaration d\'accident';
      case ContexteRecherche.verification:
        return 'Vérification';
      case ContexteRecherche.expertise:
        return 'Expertise';
      case ContexteRecherche.controle:
        return 'Contrôle';
    }
  }

  String get value {
    switch (this) {
      case ContexteRecherche.declarationAccident:
        return 'declaration_accident';
      case ContexteRecherche.verification:
        return 'verification';
      case ContexteRecherche.expertise:
        return 'expertise';
      case ContexteRecherche.controle:
        return 'controle';
    }
  }

  static ContexteRecherche fromString(String value) {
    switch (value) {
      case 'declaration_accident':
        return ContexteRecherche.declarationAccident;
      case 'verification':
        return ContexteRecherche.verification;
      case 'expertise':
        return ContexteRecherche.expertise;
      case 'controle':
        return ContexteRecherche.controle;
      default:
        return ContexteRecherche.declarationAccident;
    }
  }
}

/// 🔍 Critères de recherche véhicule
class CriteresRecherche {
  final String? assurance;
  final String? numeroContrat;
  final String? immatriculation;
  final String? marque;
  final String? modele;
  final String? proprietaireNom;
  final String? proprietairePrenom;
  final String? proprietaireCin;

  const CriteresRecherche({
    this.assurance,
    this.numeroContrat,
    this.immatriculation,
    this.marque,
    this.modele,
    this.proprietaireNom,
    this.proprietairePrenom,
    this.proprietaireCin,
  });

  factory CriteresRecherche.fromMap(Map<String, dynamic> map) {
    return CriteresRecherche(
      assurance: map['assurance'],
      numeroContrat: map['numero_contrat'],
      immatriculation: map['immatriculation'],
      marque: map['marque'],
      modele: map['modele'],
      proprietaireNom: map['proprietaire_nom'],
      proprietairePrenom: map['proprietaire_prenom'],
      proprietaireCin: map['proprietaire_cin'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assurance': assurance,
      'numero_contrat': numeroContrat,
      'immatriculation': immatriculation,
      'marque': marque,
      'modele': modele,
      'proprietaire_nom': proprietaireNom,
      'proprietaire_prenom': proprietairePrenom,
      'proprietaire_cin': proprietaireCin,
    };
  }

  /// Vérifier si au moins un critère est renseigné
  bool get hasAnyCriteria {
    return assurance != null ||
           numeroContrat != null ||
           immatriculation != null ||
           marque != null ||
           modele != null ||
           proprietaireNom != null ||
           proprietairePrenom != null ||
           proprietaireCin != null;
  }

  /// Obtenir le nombre de critères renseignés
  int get criteriaCount {
    int count = 0;
    if (assurance?.isNotEmpty == true) count++;
    if (numeroContrat?.isNotEmpty == true) count++;
    if (immatriculation?.isNotEmpty == true) count++;
    if (marque?.isNotEmpty == true) count++;
    if (modele?.isNotEmpty == true) count++;
    if (proprietaireNom?.isNotEmpty == true) count++;
    if (proprietairePrenom?.isNotEmpty == true) count++;
    if (proprietaireCin?.isNotEmpty == true) count++;
    return count;
  }

  /// Obtenir la description des critères
  String get description {
    final List<String> parts = [];

    if (assurance?.isNotEmpty == true) {
      parts.add('Assurance: $assurance');
    }
    if (numeroContrat?.isNotEmpty == true) {
      parts.add('Contrat: $numeroContrat');
    }
    if (immatriculation?.isNotEmpty == true) {
      parts.add('Immat: $immatriculation');
    }
    if (marque?.isNotEmpty == true) {
      parts.add('Marque: $marque');
    }

    return parts.join(', ');
  }
}

/// 🔍 Modèle de recherche véhicule
class VehiculeRechercheModel {
  final String id;
  final String conducteurRechercheur;
  final CriteresRecherche criteres;
  final bool resultatTrouve;
  final String? vehiculeTrouve;
  final List<String> vehiculesPossibles; // Si plusieurs résultats
  final DateTime dateRecherche;
  final ContexteRecherche contexte;
  final String? sessionId; // Si dans le cadre d'une déclaration
  final String? commentaire;
  final int tempsRecherche; // En millisecondes
  final String? adresseIP;
  final DateTime createdAt;

  const VehiculeRechercheModel({
    required this.id,
    required this.conducteurRechercheur,
    required this.criteres,
    required this.resultatTrouve,
    this.vehiculeTrouve,
    required this.vehiculesPossibles,
    required this.dateRecherche,
    required this.contexte,
    this.sessionId,
    this.commentaire,
    required this.tempsRecherche,
    this.adresseIP,
    required this.createdAt,
  });

  /// Créer depuis Firestore
  factory VehiculeRechercheModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VehiculeRechercheModel(
      id: doc.id,
      conducteurRechercheur: data['conducteur_rechercheur'] ?? '',
      criteres: CriteresRecherche.fromMap(data['criteres'] ?? {}),
      resultatTrouve: data['resultat_trouve'] ?? false,
      vehiculeTrouve: data['vehicule_trouve'],
      vehiculesPossibles: List<String>.from(data['vehicules_possibles'] ?? []),
      dateRecherche: (data['date_recherche'] as Timestamp).toDate(),
      contexte: ContexteRechercheExtension.fromString(data['contexte'] ?? 'declaration_accident'),
      sessionId: data['session_id'],
      commentaire: data['commentaire'],
      tempsRecherche: data['temps_recherche'] ?? 0,
      adresseIP: data['adresse_ip'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'conducteur_rechercheur': conducteurRechercheur,
      'criteres': criteres.toMap(),
      'resultat_trouve': resultatTrouve,
      'vehicule_trouve': vehiculeTrouve,
      'vehicules_possibles': vehiculesPossibles,
      'date_recherche': Timestamp.fromDate(dateRecherche),
      'contexte': contexte.value,
      'session_id': sessionId,
      'commentaire': commentaire,
      'temps_recherche': tempsRecherche,
      'adresse_ip': adresseIP,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Copier avec modifications
  VehiculeRechercheModel copyWith({
    String? id,
    String? conducteurRechercheur,
    CriteresRecherche? criteres,
    bool? resultatTrouve,
    String? vehiculeTrouve,
    List<String>? vehiculesPossibles,
    DateTime? dateRecherche,
    ContexteRecherche? contexte,
    String? sessionId,
    String? commentaire,
    int? tempsRecherche,
    String? adresseIP,
    DateTime? createdAt,
  }) {
    return VehiculeRechercheModel(
      id: id ?? this.id,
      conducteurRechercheur: conducteurRechercheur ?? this.conducteurRechercheur,
      criteres: criteres ?? this.criteres,
      resultatTrouve: resultatTrouve ?? this.resultatTrouve,
      vehiculeTrouve: vehiculeTrouve ?? this.vehiculeTrouve,
      vehiculesPossibles: vehiculesPossibles ?? this.vehiculesPossibles,
      dateRecherche: dateRecherche ?? this.dateRecherche,
      contexte: contexte ?? this.contexte,
      sessionId: sessionId ?? this.sessionId,
      commentaire: commentaire ?? this.commentaire,
      tempsRecherche: tempsRecherche ?? this.tempsRecherche,
      adresseIP: adresseIP ?? this.adresseIP,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Vérifier si la recherche a donné plusieurs résultats
  bool get hasMultipleResults => vehiculesPossibles.length > 1;

  /// Vérifier si la recherche a été rapide (moins de 5 secondes)
  bool get isRapide => tempsRecherche < 5000;

  /// Obtenir le score de précision de la recherche
  double get scorePrecision {
    if (!resultatTrouve) return 0.0;
    if (vehiculeTrouve != null) return 1.0;
    if (vehiculesPossibles.length <= 3) return 0.8;
    if (vehiculesPossibles.length <= 10) return 0.6;
    return 0.4;
  }

  /// Obtenir la description de la recherche
  String get description {
    final List<String> parts = [];
    
    if (criteres.assurance?.isNotEmpty == true) {
      parts.add('Assurance: ${criteres.assurance}');
    }
    if (criteres.numeroContrat?.isNotEmpty == true) {
      parts.add('Contrat: ${criteres.numeroContrat}');
    }
    if (criteres.immatriculation?.isNotEmpty == true) {
      parts.add('Immat: ${criteres.immatriculation}');
    }
    if (criteres.marque?.isNotEmpty == true) {
      parts.add('Marque: ${criteres.marque}');
    }
    
    return parts.join(', ');
  }

  @override
  String toString() {
    return 'VehiculeRechercheModel(id: $id, criteres: ${criteres.criteriaCount}, trouvé: $resultatTrouve)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VehiculeRechercheModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 📊 Statistiques de recherche
class StatistiquesRecherche {
  final int totalRecherches;
  final int recherchesReussies;
  final int recherchesEchouees;
  final double tempsRecherchesMoyen;
  final Map<String, int> recherchesParAssurance;
  final Map<String, int> recherchesParContexte;

  const StatistiquesRecherche({
    required this.totalRecherches,
    required this.recherchesReussies,
    required this.recherchesEchouees,
    required this.tempsRecherchesMoyen,
    required this.recherchesParAssurance,
    required this.recherchesParContexte,
  });

  /// Obtenir le taux de réussite
  double get tauxReussite {
    if (totalRecherches == 0) return 0.0;
    return (recherchesReussies / totalRecherches) * 100;
  }

  /// Obtenir l'assurance la plus recherchée
  String? get assurancePlusRecherchee {
    if (recherchesParAssurance.isEmpty) return null;
    return recherchesParAssurance.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Obtenir le contexte le plus fréquent
  String? get contextePlusFrequent {
    if (recherchesParContexte.isEmpty) return null;
    return recherchesParContexte.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}
