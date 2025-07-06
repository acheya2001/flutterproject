import 'package:cloud_firestore/cloud_firestore.dart';

/// 📄 Modèle pour un contrat d'assurance
class ContratAssuranceModel {
  final String id;
  final String numeroContrat;
  final String compagnieId;
  final String agenceId;
  final String agentId;
  final String conducteurId;
  final String vehiculeId;
  final String typeContrat;
  final DateTime dateDebut;
  final DateTime dateFin;
  final DateTime dateCreation;
  final String statut;
  final Map<String, dynamic> prime;
  final List<String> couvertures;
  final Map<String, dynamic> franchises;
  final List<String> documents;
  final List<Map<String, dynamic>> historiquePaiements;
  final String? notes;

  const ContratAssuranceModel({
    required this.id,
    required this.numeroContrat,
    required this.compagnieId,
    required this.agenceId,
    required this.agentId,
    required this.conducteurId,
    required this.vehiculeId,
    required this.typeContrat,
    required this.dateDebut,
    required this.dateFin,
    required this.dateCreation,
    required this.statut,
    required this.prime,
    required this.couvertures,
    required this.franchises,
    required this.documents,
    required this.historiquePaiements,
    this.notes,
  });

  /// Créer depuis Firestore
  factory ContratAssuranceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContratAssuranceModel.fromMap(data, doc.id);
  }

  /// Créer depuis Map
  factory ContratAssuranceModel.fromMap(Map<String, dynamic> data, [String? id]) {
    return ContratAssuranceModel(
      id: id ?? data['id'] ?? '',
      numeroContrat: data['numeroContrat'] ?? '',
      compagnieId: data['compagnieId'] ?? '',
      agenceId: data['agenceId'] ?? '',
      agentId: data['agentId'] ?? '',
      conducteurId: data['conducteurId'] ?? '',
      vehiculeId: data['vehiculeId'] ?? '',
      typeContrat: data['typeContrat'] ?? 'responsabilite_civile',
      dateDebut: (data['dateDebut'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateFin: (data['dateFin'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 365)),
      dateCreation: (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      statut: data['statut'] ?? 'actif',
      prime: Map<String, dynamic>.from(data['prime'] ?? {
        'montantAnnuel': 0.0,
        'montantMensuel': 0.0,
        'devise': 'TND',
      }),
      couvertures: List<String>.from(data['couvertures'] ?? []),
      franchises: Map<String, dynamic>.from(data['franchises'] ?? {}),
      documents: List<String>.from(data['documents'] ?? []),
      historiquePaiements: List<Map<String, dynamic>>.from(
        (data['historiquePaiements'] ?? []).map((item) => Map<String, dynamic>.from(item)),
      ),
      notes: data['notes'],
    );
  }

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'numeroContrat': numeroContrat,
      'compagnieId': compagnieId,
      'agenceId': agenceId,
      'agentId': agentId,
      'conducteurId': conducteurId,
      'vehiculeId': vehiculeId,
      'typeContrat': typeContrat,
      'dateDebut': Timestamp.fromDate(dateDebut),
      'dateFin': Timestamp.fromDate(dateFin),
      'dateCreation': Timestamp.fromDate(dateCreation),
      'statut': statut,
      'prime': prime,
      'couvertures': couvertures,
      'franchises': franchises,
      'documents': documents,
      'historiquePaiements': historiquePaiements,
      'notes': notes,
    };
  }

  /// Vérifier si le contrat est actif
  bool get isActif => statut == 'actif' && DateTime.now().isBefore(dateFin);

  /// Vérifier si le contrat expire bientôt (dans les 30 jours)
  bool get expireBientot {
    final maintenant = DateTime.now();
    final dans30Jours = maintenant.add(const Duration(days: 30));
    return dateFin.isBefore(dans30Jours) && dateFin.isAfter(maintenant);
  }

  /// Obtenir le montant de la prime selon la fréquence
  double getPrime(String frequence) {
    switch (frequence.toLowerCase()) {
      case 'mensuel':
      case 'mensuelle':
        return (prime['montantMensuel'] ?? 0.0).toDouble();
      case 'annuel':
      case 'annuelle':
        return (prime['montantAnnuel'] ?? 0.0).toDouble();
      default:
        return (prime['montantAnnuel'] ?? 0.0).toDouble();
    }
  }

  /// Copier avec modifications
  ContratAssuranceModel copyWith({
    String? id,
    String? numeroContrat,
    String? compagnieId,
    String? agenceId,
    String? agentId,
    String? conducteurId,
    String? vehiculeId,
    String? typeContrat,
    DateTime? dateDebut,
    DateTime? dateFin,
    DateTime? dateCreation,
    String? statut,
    Map<String, dynamic>? prime,
    List<String>? couvertures,
    Map<String, dynamic>? franchises,
    List<String>? documents,
    List<Map<String, dynamic>>? historiquePaiements,
    String? notes,
  }) {
    return ContratAssuranceModel(
      id: id ?? this.id,
      numeroContrat: numeroContrat ?? this.numeroContrat,
      compagnieId: compagnieId ?? this.compagnieId,
      agenceId: agenceId ?? this.agenceId,
      agentId: agentId ?? this.agentId,
      conducteurId: conducteurId ?? this.conducteurId,
      vehiculeId: vehiculeId ?? this.vehiculeId,
      typeContrat: typeContrat ?? this.typeContrat,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      dateCreation: dateCreation ?? this.dateCreation,
      statut: statut ?? this.statut,
      prime: prime ?? this.prime,
      couvertures: couvertures ?? this.couvertures,
      franchises: franchises ?? this.franchises,
      documents: documents ?? this.documents,
      historiquePaiements: historiquePaiements ?? this.historiquePaiements,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'ContratAssuranceModel(id: $id, numeroContrat: $numeroContrat, statut: $statut)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContratAssuranceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 🚙 Modèle pour un véhicule assuré
class VehiculeAssureModel {
  final String id;
  final String conducteurId;
  final String? contratId;
  final String immatriculation;
  final String marque;
  final String modele;
  final int annee;
  final String couleur;
  final String numeroSerie;
  final String typeVehicule;
  final String carburant;
  final int? puissance;
  final int? nombrePlaces;
  final double valeurVehicule;
  final DateTime? dateAchat;
  final int? kilometrage;
  final List<String> photos;
  final List<String> documents;
  final DateTime dateCreation;
  final String statut;

  const VehiculeAssureModel({
    required this.id,
    required this.conducteurId,
    this.contratId,
    required this.immatriculation,
    required this.marque,
    required this.modele,
    required this.annee,
    required this.couleur,
    required this.numeroSerie,
    required this.typeVehicule,
    required this.carburant,
    this.puissance,
    this.nombrePlaces,
    required this.valeurVehicule,
    this.dateAchat,
    this.kilometrage,
    required this.photos,
    required this.documents,
    required this.dateCreation,
    required this.statut,
  });

  /// Créer depuis Firestore
  factory VehiculeAssureModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VehiculeAssureModel.fromMap(data, doc.id);
  }

  /// Créer depuis Map
  factory VehiculeAssureModel.fromMap(Map<String, dynamic> data, [String? id]) {
    return VehiculeAssureModel(
      id: id ?? data['id'] ?? '',
      conducteurId: data['conducteurId'] ?? '',
      contratId: data['contratId'],
      immatriculation: data['immatriculation'] ?? '',
      marque: data['marque'] ?? '',
      modele: data['modele'] ?? '',
      annee: data['annee'] ?? DateTime.now().year,
      couleur: data['couleur'] ?? '',
      numeroSerie: data['numeroSerie'] ?? '',
      typeVehicule: data['typeVehicule'] ?? 'voiture',
      carburant: data['carburant'] ?? 'essence',
      puissance: data['puissance'],
      nombrePlaces: data['nombrePlaces'],
      valeurVehicule: (data['valeurVehicule'] ?? 0.0).toDouble(),
      dateAchat: (data['dateAchat'] as Timestamp?)?.toDate(),
      kilometrage: data['kilometrage'],
      photos: List<String>.from(data['photos'] ?? []),
      documents: List<String>.from(data['documents'] ?? []),
      dateCreation: (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      statut: data['statut'] ?? 'actif',
    );
  }

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'conducteurId': conducteurId,
      'contratId': contratId,
      'immatriculation': immatriculation,
      'marque': marque,
      'modele': modele,
      'annee': annee,
      'couleur': couleur,
      'numeroSerie': numeroSerie,
      'typeVehicule': typeVehicule,
      'carburant': carburant,
      'puissance': puissance,
      'nombrePlaces': nombrePlaces,
      'valeurVehicule': valeurVehicule,
      'dateAchat': dateAchat != null ? Timestamp.fromDate(dateAchat!) : null,
      'kilometrage': kilometrage,
      'photos': photos,
      'documents': documents,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'statut': statut,
    };
  }

  /// Vérifier si le véhicule est assuré
  bool get isAssure => contratId != null && statut == 'actif';

  /// Obtenir l'âge du véhicule
  int get age => DateTime.now().year - annee;

  /// Copier avec modifications
  VehiculeAssureModel copyWith({
    String? id,
    String? conducteurId,
    String? contratId,
    String? immatriculation,
    String? marque,
    String? modele,
    int? annee,
    String? couleur,
    String? numeroSerie,
    String? typeVehicule,
    String? carburant,
    int? puissance,
    int? nombrePlaces,
    double? valeurVehicule,
    DateTime? dateAchat,
    int? kilometrage,
    List<String>? photos,
    List<String>? documents,
    DateTime? dateCreation,
    String? statut,
  }) {
    return VehiculeAssureModel(
      id: id ?? this.id,
      conducteurId: conducteurId ?? this.conducteurId,
      contratId: contratId ?? this.contratId,
      immatriculation: immatriculation ?? this.immatriculation,
      marque: marque ?? this.marque,
      modele: modele ?? this.modele,
      annee: annee ?? this.annee,
      couleur: couleur ?? this.couleur,
      numeroSerie: numeroSerie ?? this.numeroSerie,
      typeVehicule: typeVehicule ?? this.typeVehicule,
      carburant: carburant ?? this.carburant,
      puissance: puissance ?? this.puissance,
      nombrePlaces: nombrePlaces ?? this.nombrePlaces,
      valeurVehicule: valeurVehicule ?? this.valeurVehicule,
      dateAchat: dateAchat ?? this.dateAchat,
      kilometrage: kilometrage ?? this.kilometrage,
      photos: photos ?? this.photos,
      documents: documents ?? this.documents,
      dateCreation: dateCreation ?? this.dateCreation,
      statut: statut ?? this.statut,
    );
  }

  @override
  String toString() {
    return 'VehiculeAssureModel(id: $id, immatriculation: $immatriculation, marque: $marque $modele)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VehiculeAssureModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
