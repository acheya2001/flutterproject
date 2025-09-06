import 'package:cloud_firestore/cloud_firestore.dart';

/// 🚗 Modèle pour représenter un véhicule avec toutes ses données
class Vehicule {
  final String? id;
  final String conducteurId;
  
  // Informations de base du véhicule
  final String marque;
  final String modele;
  final String numeroImmatriculation;
  final String couleur;
  final int annee;
  final String typeVehicule; // VP, VU, PL, MOTO, TAXI, etc. (catégories tunisiennes)
  final String carburant; // essence, diesel, électrique, hybride
  final String usage; // Personnel, Professionnel, Taxi
  final int nombrePlaces;
  final String numeroSerie; // VIN
  
  // Informations techniques
  final String puissanceFiscale;
  final String cylindree;
  final double poids;
  final String genre; // VP (Voiture Particulière), etc.
  
  // Documents du véhicule
  final String numeroCarteGrise;
  final DateTime datePremiereImmatriculation;
  final DateTime dateMiseEnCirculation;
  final String? imageCarteGriseUrl;
  
  // Informations du propriétaire/conducteur
  final String nomProprietaire;
  final String prenomProprietaire;
  final String adresseProprietaire;
  final String numeroPermis;
  final String categoriePermis; // A, B, C, D, etc.
  final DateTime dateObtentionPermis;
  final DateTime dateExpirationPermis;
  final String? imagePermisUrl;
  
  // Informations d'assurance
  final bool estAssure;
  final String? compagnieAssuranceId;
  final String? compagnieAssuranceNom;
  final String? agenceAssuranceId;
  final String? agenceAssuranceNom;
  final String? numeroContratAssurance;
  final DateTime? dateDebutAssurance;
  final DateTime? dateFinAssurance;
  final DateTime? dateDerniereAssurance;
  final String? typeAssurance; // au tiers, tous risques, etc.
  final String? statutAssurance; // non_assure, en_attente_validation, assure, expire

  // État du compte
  final String etatCompte; // Actif, Suspendu
  
  // Informations de contrôle technique
  final DateTime? dateProchainControle;
  final bool controleValide;
  
  // Métadonnées
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final bool isActive;

  Vehicule({
    this.id,
    required this.conducteurId,
    required this.marque,
    required this.modele,
    required this.numeroImmatriculation,
    required this.couleur,
    required this.annee,
    required this.typeVehicule,
    required this.carburant,
    required this.usage,
    required this.nombrePlaces,
    required this.numeroSerie,
    required this.puissanceFiscale,
    required this.cylindree,
    required this.poids,
    required this.genre,
    required this.numeroCarteGrise,
    required this.datePremiereImmatriculation,
    required this.dateMiseEnCirculation,
    this.imageCarteGriseUrl,
    required this.nomProprietaire,
    required this.prenomProprietaire,
    required this.adresseProprietaire,
    required this.numeroPermis,
    required this.categoriePermis,
    required this.dateObtentionPermis,
    required this.dateExpirationPermis,
    this.imagePermisUrl,
    this.estAssure = false,
    this.compagnieAssuranceId,
    this.compagnieAssuranceNom,
    this.agenceAssuranceId,
    this.agenceAssuranceNom,
    this.numeroContratAssurance,
    this.dateDebutAssurance,
    this.dateFinAssurance,
    this.dateDerniereAssurance,
    this.typeAssurance,
    this.statutAssurance,
    this.etatCompte = 'Actif',
    this.dateProchainControle,
    this.controleValide = true,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.isActive = true,
  });

  /// Créer un véhicule depuis les données Firestore
  factory Vehicule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Vehicule(
      id: doc.id,
      conducteurId: data['conducteurId'] ?? '',
      marque: data['marque'] ?? '',
      modele: data['modele'] ?? '',
      numeroImmatriculation: data['numeroImmatriculation'] ?? '',
      couleur: data['couleur'] ?? '',
      annee: data['annee'] ?? DateTime.now().year,
      typeVehicule: data['typeVehicule'] ?? 'VP',
      carburant: data['carburant'] ?? 'Essence',
      usage: data['usage'] ?? 'Personnel',
      nombrePlaces: data['nombrePlaces'] ?? 5,
      numeroSerie: data['numeroSerie'] ?? '',
      puissanceFiscale: data['puissanceFiscale'] ?? '',
      cylindree: data['cylindree'] ?? '',
      poids: (data['poids'] ?? 0.0).toDouble(),
      genre: data['genre'] ?? '',
      numeroCarteGrise: data['numeroCarteGrise'] ?? '',
      datePremiereImmatriculation: (data['datePremiereImmatriculation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateMiseEnCirculation: (data['dateMiseEnCirculation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageCarteGriseUrl: data['imageCarteGriseUrl'],
      nomProprietaire: data['nomProprietaire'] ?? '',
      prenomProprietaire: data['prenomProprietaire'] ?? '',
      adresseProprietaire: data['adresseProprietaire'] ?? '',
      numeroPermis: data['numeroPermis'] ?? '',
      categoriePermis: data['categoriePermis'] ?? '',
      dateObtentionPermis: (data['dateObtentionPermis'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateExpirationPermis: (data['dateExpirationPermis'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imagePermisUrl: data['imagePermisUrl'],
      estAssure: data['estAssure'] ?? false,
      compagnieAssuranceId: data['compagnieAssuranceId'],
      compagnieAssuranceNom: data['compagnieAssuranceNom'],
      agenceAssuranceId: data['agenceAssuranceId'],
      agenceAssuranceNom: data['agenceAssuranceNom'],
      numeroContratAssurance: data['numeroContratAssurance'],
      dateDebutAssurance: (data['dateDebutAssurance'] as Timestamp?)?.toDate(),
      dateFinAssurance: (data['dateFinAssurance'] as Timestamp?)?.toDate(),
      dateDerniereAssurance: (data['dateDerniereAssurance'] as Timestamp?)?.toDate(),
      typeAssurance: data['typeAssurance'],
      statutAssurance: data['statutAssurance'],
      etatCompte: data['etatCompte'] ?? 'Actif',
      dateProchainControle: (data['dateProchainControle'] as Timestamp?)?.toDate(),
      controleValide: data['controleValide'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      isActive: data['isActive'] ?? true,
    );
  }

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'conducteurId': conducteurId,
      'marque': marque,
      'modele': modele,
      'numeroImmatriculation': numeroImmatriculation,
      'couleur': couleur,
      'annee': annee,
      'typeVehicule': typeVehicule,
      'carburant': carburant,
      'usage': usage,
      'nombrePlaces': nombrePlaces,
      'numeroSerie': numeroSerie,
      'puissanceFiscale': puissanceFiscale,
      'cylindree': cylindree,
      'poids': poids,
      'genre': genre,
      'numeroCarteGrise': numeroCarteGrise,
      'datePremiereImmatriculation': Timestamp.fromDate(datePremiereImmatriculation),
      'dateMiseEnCirculation': Timestamp.fromDate(dateMiseEnCirculation),
      'imageCarteGriseUrl': imageCarteGriseUrl,
      'nomProprietaire': nomProprietaire,
      'prenomProprietaire': prenomProprietaire,
      'adresseProprietaire': adresseProprietaire,
      'numeroPermis': numeroPermis,
      'categoriePermis': categoriePermis,
      'dateObtentionPermis': Timestamp.fromDate(dateObtentionPermis),
      'dateExpirationPermis': Timestamp.fromDate(dateExpirationPermis),
      'imagePermisUrl': imagePermisUrl,
      'estAssure': estAssure,
      'compagnieAssuranceId': compagnieAssuranceId,
      'compagnieAssuranceNom': compagnieAssuranceNom,
      'agenceAssuranceId': agenceAssuranceId,
      'agenceAssuranceNom': agenceAssuranceNom,
      'numeroContratAssurance': numeroContratAssurance,
      'dateDebutAssurance': dateDebutAssurance != null ? Timestamp.fromDate(dateDebutAssurance!) : null,
      'dateFinAssurance': dateFinAssurance != null ? Timestamp.fromDate(dateFinAssurance!) : null,
      'dateDerniereAssurance': dateDerniereAssurance != null ? Timestamp.fromDate(dateDerniereAssurance!) : null,
      'typeAssurance': typeAssurance,
      'statutAssurance': statutAssurance,
      'etatCompte': etatCompte,
      'dateProchainControle': dateProchainControle != null ? Timestamp.fromDate(dateProchainControle!) : null,
      'controleValide': controleValide,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'isActive': isActive,
    };
  }

  /// Créer une copie avec des modifications
  Vehicule copyWith({
    String? id,
    String? conducteurId,
    String? marque,
    String? modele,
    String? numeroImmatriculation,
    String? couleur,
    int? annee,
    String? typeVehicule,
    String? carburant,
    String? usage,
    int? nombrePlaces,
    String? numeroSerie,
    String? puissanceFiscale,
    String? cylindree,
    double? poids,
    String? genre,
    String? numeroCarteGrise,
    DateTime? datePremiereImmatriculation,
    DateTime? dateMiseEnCirculation,
    String? imageCarteGriseUrl,
    String? nomProprietaire,
    String? prenomProprietaire,
    String? adresseProprietaire,
    String? numeroPermis,
    String? categoriePermis,
    DateTime? dateObtentionPermis,
    DateTime? dateExpirationPermis,
    String? imagePermisUrl,
    bool? estAssure,
    String? compagnieAssuranceId,
    String? compagnieAssuranceNom,
    String? agenceAssuranceId,
    String? agenceAssuranceNom,
    String? numeroContratAssurance,
    DateTime? dateDebutAssurance,
    DateTime? dateFinAssurance,
    DateTime? dateDerniereAssurance,
    String? typeAssurance,
    String? statutAssurance,
    String? etatCompte,
    DateTime? dateProchainControle,
    bool? controleValide,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Vehicule(
      id: id ?? this.id,
      conducteurId: conducteurId ?? this.conducteurId,
      marque: marque ?? this.marque,
      modele: modele ?? this.modele,
      numeroImmatriculation: numeroImmatriculation ?? this.numeroImmatriculation,
      couleur: couleur ?? this.couleur,
      annee: annee ?? this.annee,
      typeVehicule: typeVehicule ?? this.typeVehicule,
      carburant: carburant ?? this.carburant,
      usage: usage ?? this.usage,
      nombrePlaces: nombrePlaces ?? this.nombrePlaces,
      numeroSerie: numeroSerie ?? this.numeroSerie,
      puissanceFiscale: puissanceFiscale ?? this.puissanceFiscale,
      cylindree: cylindree ?? this.cylindree,
      poids: poids ?? this.poids,
      genre: genre ?? this.genre,
      numeroCarteGrise: numeroCarteGrise ?? this.numeroCarteGrise,
      datePremiereImmatriculation: datePremiereImmatriculation ?? this.datePremiereImmatriculation,
      dateMiseEnCirculation: dateMiseEnCirculation ?? this.dateMiseEnCirculation,
      imageCarteGriseUrl: imageCarteGriseUrl ?? this.imageCarteGriseUrl,
      nomProprietaire: nomProprietaire ?? this.nomProprietaire,
      prenomProprietaire: prenomProprietaire ?? this.prenomProprietaire,
      adresseProprietaire: adresseProprietaire ?? this.adresseProprietaire,
      numeroPermis: numeroPermis ?? this.numeroPermis,
      categoriePermis: categoriePermis ?? this.categoriePermis,
      dateObtentionPermis: dateObtentionPermis ?? this.dateObtentionPermis,
      dateExpirationPermis: dateExpirationPermis ?? this.dateExpirationPermis,
      imagePermisUrl: imagePermisUrl ?? this.imagePermisUrl,
      estAssure: estAssure ?? this.estAssure,
      compagnieAssuranceId: compagnieAssuranceId ?? this.compagnieAssuranceId,
      compagnieAssuranceNom: compagnieAssuranceNom ?? this.compagnieAssuranceNom,
      agenceAssuranceId: agenceAssuranceId ?? this.agenceAssuranceId,
      agenceAssuranceNom: agenceAssuranceNom ?? this.agenceAssuranceNom,
      numeroContratAssurance: numeroContratAssurance ?? this.numeroContratAssurance,
      dateDebutAssurance: dateDebutAssurance ?? this.dateDebutAssurance,
      dateFinAssurance: dateFinAssurance ?? this.dateFinAssurance,
      dateDerniereAssurance: dateDerniereAssurance ?? this.dateDerniereAssurance,
      typeAssurance: typeAssurance ?? this.typeAssurance,
      statutAssurance: statutAssurance ?? this.statutAssurance,
      etatCompte: etatCompte ?? this.etatCompte,
      dateProchainControle: dateProchainControle ?? this.dateProchainControle,
      controleValide: controleValide ?? this.controleValide,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      createdBy: createdBy,
      isActive: isActive ?? this.isActive,
    );
  }
}
