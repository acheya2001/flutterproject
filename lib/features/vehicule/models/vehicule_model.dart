import 'package:cloud_firestore/cloud_firestore.dart';

class VehiculeModel {
  final String? id;
  final String proprietaireId;
  final String immatriculation;
  final String marque;
  final String modele;
  final String compagnieAssurance;
  final String numeroContrat; // Était numeroPolice dans mon exemple, adapté à votre modèle
  final String quittance; // Numéro de quittance d'assurance
  final String agence;
  final DateTime? dateDebutValidite; // Était dateDebutAssurance
  final DateTime? dateFinValidite;   // Était dateFinAssurance
  final String? photoCarteGriseRecto;
  final String? photoCarteGriseVerso;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Getters pour la compatibilité si l'ancien code les utilise encore
  String? get assureur => compagnieAssurance;
  DateTime? get dateDebutAssurance => dateDebutValidite;
  DateTime? get dateFinAssurance => dateFinValidite;
  String? get numeroPolice => numeroContrat; // Pour compatibilité

  // Champs qui n'existent pas dans votre modèle mais que mon code précédent utilisait.
  // Ils sont retirés des constructeurs et toMap, mais gardés ici pour montrer la différence.
  // String couleur; (n'existe pas dans votre modèle)
  // String energie; (n'existe pas dans votre modèle)
  // int puissanceFiscale; (n'existe pas dans votre modèle)
  // String numeroChassis; (n'existe pas dans votre modèle)
  // DateTime dateMiseEnCirculation; (n'existe pas dans votre modèle)
  // String usage; (n'existe pas dans votre modèle)
  // String nomPrenomProprietaire; (n'existe pas dans votre modèle)
  // String adresseProprietaire; (n'existe pas dans votre modèle)
  // String telephoneProprietaire; (n'existe pas dans votre modèle)
  // String? photoAssuranceUrl; (n'existe pas dans votre modèle)


  VehiculeModel({
    this.id,
    required this.proprietaireId,
    required this.immatriculation,
    required this.marque,
    required this.modele,
    required this.compagnieAssurance,
    required this.numeroContrat,
    required this.quittance,
    required this.agence,
    this.dateDebutValidite,
    this.dateFinValidite,
    this.photoCarteGriseRecto,
    this.photoCarteGriseVerso,
    this.createdAt,
    this.updatedAt,
  });

  bool get estAssuranceValide {
    if (dateFinValidite == null) return false; // Ou true si null signifie illimité
    return dateFinValidite!.isAfter(DateTime.now());
  }

  int get joursRestantsAssurance {
    if (dateFinValidite == null) return 0; // Ou un grand nombre si illimité
    final now = DateTime.now();
    if (dateFinValidite!.isBefore(now)) return 0;
    return dateFinValidite!.difference(now).inDays;
  }

  VehiculeModel copyWith({
    String? id,
    String? proprietaireId,
    String? immatriculation,
    String? marque,
    String? modele,
    String? compagnieAssurance,
    String? numeroContrat,
    String? quittance,
    String? agence,
    DateTime? dateDebutValidite,
    DateTime? dateFinValidite,
    String? photoCarteGriseRecto,
    String? photoCarteGriseVerso,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehiculeModel(
      id: id ?? this.id,
      proprietaireId: proprietaireId ?? this.proprietaireId,
      immatriculation: immatriculation ?? this.immatriculation,
      marque: marque ?? this.marque,
      modele: modele ?? this.modele,
      compagnieAssurance: compagnieAssurance ?? this.compagnieAssurance,
      numeroContrat: numeroContrat ?? this.numeroContrat,
      quittance: quittance ?? this.quittance,
      agence: agence ?? this.agence,
      dateDebutValidite: dateDebutValidite ?? this.dateDebutValidite,
      dateFinValidite: dateFinValidite ?? this.dateFinValidite,
      photoCarteGriseRecto: photoCarteGriseRecto ?? this.photoCarteGriseRecto,
      photoCarteGriseVerso: photoCarteGriseVerso ?? this.photoCarteGriseVerso,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // id est géré par Firestore, ne pas l'inclure ici sauf si nécessaire pour des sous-collections
      'proprietaireId': proprietaireId,
      'immatriculation': immatriculation,
      'marque': marque,
      'modele': modele,
      'compagnieAssurance': compagnieAssurance,
      'numeroContrat': numeroContrat,
      'quittance': quittance,
      'agence': agence,
      'dateDebutValidite': dateDebutValidite != null ? Timestamp.fromDate(dateDebutValidite!) : null,
      'dateFinValidite': dateFinValidite != null ? Timestamp.fromDate(dateFinValidite!) : null,
      'photoCarteGriseRecto': photoCarteGriseRecto,
      'photoCarteGriseVerso': photoCarteGriseVerso,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory VehiculeModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) throw Exception("Document data was null!");

    return VehiculeModel(
      id: doc.id,
      proprietaireId: data['proprietaireId'] ?? '',
      immatriculation: data['immatriculation'] ?? '',
      marque: data['marque'] ?? '',
      modele: data['modele'] ?? '',
      compagnieAssurance: data['compagnieAssurance'] ?? data['assureur'] ?? '', // Compatibilité
      numeroContrat: data['numeroContrat'] ?? data['numeroPolice'] ?? '', // Compatibilité
      quittance: data['quittance'] ?? '',
      agence: data['agence'] ?? '',
      dateDebutValidite: (data['dateDebutValidite'] as Timestamp?)?.toDate() ?? (data['dateDebutAssurance'] as Timestamp?)?.toDate(), // Compatibilité
      dateFinValidite: (data['dateFinValidite'] as Timestamp?)?.toDate() ?? (data['dateFinAssurance'] as Timestamp?)?.toDate(), // Compatibilité
      photoCarteGriseRecto: data['photoCarteGriseRecto'],
      photoCarteGriseVerso: data['photoCarteGriseVerso'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
    factory VehiculeModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return VehiculeModel(
      id: id ?? data['id'],
      proprietaireId: data['proprietaireId'] ?? '',
      immatriculation: data['immatriculation'] ?? '',
      marque: data['marque'] ?? '',
      modele: data['modele'] ?? '',
      compagnieAssurance: data['compagnieAssurance'] ?? data['assureur'] ?? '',
      numeroContrat: data['numeroContrat'] ?? data['numeroPolice'] ?? '',
      quittance: data['quittance'] ?? '',
      agence: data['agence'] ?? '',
      dateDebutValidite: data['dateDebutValidite'] != null
          ? (data['dateDebutValidite'] is Timestamp
              ? (data['dateDebutValidite'] as Timestamp).toDate()
              : DateTime.tryParse(data['dateDebutValidite'].toString()))
          : data['dateDebutAssurance'] != null
              ? (data['dateDebutAssurance'] is Timestamp
                  ? (data['dateDebutAssurance'] as Timestamp).toDate()
                  : DateTime.tryParse(data['dateDebutAssurance'].toString()))
              : null,
      dateFinValidite: data['dateFinValidite'] != null
          ? (data['dateFinValidite'] is Timestamp
              ? (data['dateFinValidite'] as Timestamp).toDate()
              : DateTime.tryParse(data['dateFinValidite'].toString()))
          : data['dateFinAssurance'] != null
              ? (data['dateFinAssurance'] is Timestamp
                  ? (data['dateFinAssurance'] as Timestamp).toDate()
                  : DateTime.tryParse(data['dateFinAssurance'].toString()))
              : null,
      photoCarteGriseRecto: data['photoCarteGriseRecto'],
      photoCarteGriseVerso: data['photoCarteGriseVerso'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['createdAt'].toString()))
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['updatedAt'].toString()))
          : null,
    );
  }


  @override
  String toString() {
    return 'VehiculeModel(id: $id, immatriculation: $immatriculation, marque: $marque, modele: $modele)';
  }
}