import 'package:cloud_firestore/cloud_firestore.dart';

/// 🚗 Modèle pour un participant à une session d'accident (Partie A ou B)
class AccidentParticipant {
  final String id;
  final String sessionId;
  final String userId; // ID de l'utilisateur connecté
  final String partie; // 'A' ou 'B'
  final String statut;
  
  // Section 6 - Conducteur
  final String nomConducteur;
  final String prenomConducteur;
  final String adresseConducteur;
  final String telephoneConducteur;
  final String? emailConducteur;
  final DateTime? dateNaissanceConducteur;
  final String? numeroPermis;
  final String? categoriePermis;
  final DateTime? dateValiditePermis;
  
  // Section 7 - Véhicule
  final String marqueVehicule;
  final String typeVehicule;
  final String numeroImmatriculation;
  final String? numeroSerie;
  final String? sensSuivi; // "venant de" / "allant à"
  
  // Section 8 - Société d'assurance
  final String nomAssurance;
  final String numeroPolice;
  final String? numeroCarteVerte;
  final DateTime? dateValiditeAssurance;
  final String? agenceAssurance;
  final bool? assuranceValide;
  
  // Section 9 - Conducteur habituel
  final bool conducteurHabituel;
  final String? nomConducteurHabituel;
  final String? prenomConducteurHabituel;
  
  // Section 10 - Point de choc initial
  final Map<String, dynamic>? pointChocData; // Coordonnées sur le schéma
  
  // Section 11 - Dégâts apparents
  final String? degatsApparents;
  
  // Section 12 - Circonstances (17 cases à cocher)
  final List<int> circonstancesSelectionnees; // Liste des numéros 11-17
  
  // Section 14 - Observations spécifiques à cette partie
  final String? observationsPartie;
  
  // Signature numérique
  final bool signe;
  final DateTime? dateSignature;
  final String? signatureFileId; // ID du fichier de signature
  final Map<String, dynamic>? signatureData; // Données de la signature
  
  // Photos spécifiques à cette partie
  final List<String> photosFileIds;
  
  // Métadonnées
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  AccidentParticipant({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.partie,
    required this.statut,
    required this.nomConducteur,
    required this.prenomConducteur,
    required this.adresseConducteur,
    required this.telephoneConducteur,
    this.emailConducteur,
    this.dateNaissanceConducteur,
    this.numeroPermis,
    this.categoriePermis,
    this.dateValiditePermis,
    required this.marqueVehicule,
    required this.typeVehicule,
    required this.numeroImmatriculation,
    this.numeroSerie,
    this.sensSuivi,
    required this.nomAssurance,
    required this.numeroPolice,
    this.numeroCarteVerte,
    this.dateValiditeAssurance,
    this.agenceAssurance,
    this.assuranceValide,
    required this.conducteurHabituel,
    this.nomConducteurHabituel,
    this.prenomConducteurHabituel,
    this.pointChocData,
    this.degatsApparents,
    this.circonstancesSelectionnees = const [],
    this.observationsPartie,
    this.signe = false,
    this.dateSignature,
    this.signatureFileId,
    this.signatureData,
    this.photosFileIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory AccidentParticipant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AccidentParticipant(
      id: doc.id,
      sessionId: data['sessionId'] ?? '',
      userId: data['userId'] ?? '',
      partie: data['partie'] ?? 'A',
      statut: data['statut'] ?? 'brouillon',
      nomConducteur: data['nomConducteur'] ?? '',
      prenomConducteur: data['prenomConducteur'] ?? '',
      adresseConducteur: data['adresseConducteur'] ?? '',
      telephoneConducteur: data['telephoneConducteur'] ?? '',
      emailConducteur: data['emailConducteur'],
      dateNaissanceConducteur: data['dateNaissanceConducteur'] != null 
          ? (data['dateNaissanceConducteur'] as Timestamp).toDate() 
          : null,
      numeroPermis: data['numeroPermis'],
      categoriePermis: data['categoriePermis'],
      dateValiditePermis: data['dateValiditePermis'] != null 
          ? (data['dateValiditePermis'] as Timestamp).toDate() 
          : null,
      marqueVehicule: data['marqueVehicule'] ?? '',
      typeVehicule: data['typeVehicule'] ?? '',
      numeroImmatriculation: data['numeroImmatriculation'] ?? '',
      numeroSerie: data['numeroSerie'],
      sensSuivi: data['sensSuivi'],
      nomAssurance: data['nomAssurance'] ?? '',
      numeroPolice: data['numeroPolice'] ?? '',
      numeroCarteVerte: data['numeroCarteVerte'],
      dateValiditeAssurance: data['dateValiditeAssurance'] != null 
          ? (data['dateValiditeAssurance'] as Timestamp).toDate() 
          : null,
      agenceAssurance: data['agenceAssurance'],
      assuranceValide: data['assuranceValide'],
      conducteurHabituel: data['conducteurHabituel'] ?? true,
      nomConducteurHabituel: data['nomConducteurHabituel'],
      prenomConducteurHabituel: data['prenomConducteurHabituel'],
      pointChocData: data['pointChocData'],
      degatsApparents: data['degatsApparents'],
      circonstancesSelectionnees: List<int>.from(data['circonstancesSelectionnees'] ?? []),
      observationsPartie: data['observationsPartie'],
      signe: data['signe'] ?? false,
      dateSignature: data['dateSignature'] != null 
          ? (data['dateSignature'] as Timestamp).toDate() 
          : null,
      signatureFileId: data['signatureFileId'],
      signatureData: data['signatureData'],
      photosFileIds: List<String>.from(data['photosFileIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'partie': partie,
      'statut': statut,
      'nomConducteur': nomConducteur,
      'prenomConducteur': prenomConducteur,
      'adresseConducteur': adresseConducteur,
      'telephoneConducteur': telephoneConducteur,
      'emailConducteur': emailConducteur,
      'dateNaissanceConducteur': dateNaissanceConducteur != null 
          ? Timestamp.fromDate(dateNaissanceConducteur!) 
          : null,
      'numeroPermis': numeroPermis,
      'categoriePermis': categoriePermis,
      'dateValiditePermis': dateValiditePermis != null 
          ? Timestamp.fromDate(dateValiditePermis!) 
          : null,
      'marqueVehicule': marqueVehicule,
      'typeVehicule': typeVehicule,
      'numeroImmatriculation': numeroImmatriculation,
      'numeroSerie': numeroSerie,
      'sensSuivi': sensSuivi,
      'nomAssurance': nomAssurance,
      'numeroPolice': numeroPolice,
      'numeroCarteVerte': numeroCarteVerte,
      'dateValiditeAssurance': dateValiditeAssurance != null 
          ? Timestamp.fromDate(dateValiditeAssurance!) 
          : null,
      'agenceAssurance': agenceAssurance,
      'assuranceValide': assuranceValide,
      'conducteurHabituel': conducteurHabituel,
      'nomConducteurHabituel': nomConducteurHabituel,
      'prenomConducteurHabituel': prenomConducteurHabituel,
      'pointChocData': pointChocData,
      'degatsApparents': degatsApparents,
      'circonstancesSelectionnees': circonstancesSelectionnees,
      'observationsPartie': observationsPartie,
      'signe': signe,
      'dateSignature': dateSignature != null 
          ? Timestamp.fromDate(dateSignature!) 
          : null,
      'signatureFileId': signatureFileId,
      'signatureData': signatureData,
      'photosFileIds': photosFileIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  AccidentParticipant copyWith({
    String? statut,
    String? nomConducteur,
    String? prenomConducteur,
    String? adresseConducteur,
    String? telephoneConducteur,
    String? emailConducteur,
    DateTime? dateNaissanceConducteur,
    String? numeroPermis,
    String? categoriePermis,
    DateTime? dateValiditePermis,
    String? marqueVehicule,
    String? typeVehicule,
    String? numeroImmatriculation,
    String? numeroSerie,
    String? sensSuivi,
    String? nomAssurance,
    String? numeroPolice,
    String? numeroCarteVerte,
    DateTime? dateValiditeAssurance,
    String? agenceAssurance,
    bool? assuranceValide,
    bool? conducteurHabituel,
    String? nomConducteurHabituel,
    String? prenomConducteurHabituel,
    Map<String, dynamic>? pointChocData,
    String? degatsApparents,
    List<int>? circonstancesSelectionnees,
    String? observationsPartie,
    bool? signe,
    DateTime? dateSignature,
    String? signatureFileId,
    Map<String, dynamic>? signatureData,
    List<String>? photosFileIds,
    Map<String, dynamic>? metadata,
  }) {
    return AccidentParticipant(
      id: id,
      sessionId: sessionId,
      userId: userId,
      partie: partie,
      statut: statut ?? this.statut,
      nomConducteur: nomConducteur ?? this.nomConducteur,
      prenomConducteur: prenomConducteur ?? this.prenomConducteur,
      adresseConducteur: adresseConducteur ?? this.adresseConducteur,
      telephoneConducteur: telephoneConducteur ?? this.telephoneConducteur,
      emailConducteur: emailConducteur ?? this.emailConducteur,
      dateNaissanceConducteur: dateNaissanceConducteur ?? this.dateNaissanceConducteur,
      numeroPermis: numeroPermis ?? this.numeroPermis,
      categoriePermis: categoriePermis ?? this.categoriePermis,
      dateValiditePermis: dateValiditePermis ?? this.dateValiditePermis,
      marqueVehicule: marqueVehicule ?? this.marqueVehicule,
      typeVehicule: typeVehicule ?? this.typeVehicule,
      numeroImmatriculation: numeroImmatriculation ?? this.numeroImmatriculation,
      numeroSerie: numeroSerie ?? this.numeroSerie,
      sensSuivi: sensSuivi ?? this.sensSuivi,
      nomAssurance: nomAssurance ?? this.nomAssurance,
      numeroPolice: numeroPolice ?? this.numeroPolice,
      numeroCarteVerte: numeroCarteVerte ?? this.numeroCarteVerte,
      dateValiditeAssurance: dateValiditeAssurance ?? this.dateValiditeAssurance,
      agenceAssurance: agenceAssurance ?? this.agenceAssurance,
      assuranceValide: assuranceValide ?? this.assuranceValide,
      conducteurHabituel: conducteurHabituel ?? this.conducteurHabituel,
      nomConducteurHabituel: nomConducteurHabituel ?? this.nomConducteurHabituel,
      prenomConducteurHabituel: prenomConducteurHabituel ?? this.prenomConducteurHabituel,
      pointChocData: pointChocData ?? this.pointChocData,
      degatsApparents: degatsApparents ?? this.degatsApparents,
      circonstancesSelectionnees: circonstancesSelectionnees ?? this.circonstancesSelectionnees,
      observationsPartie: observationsPartie ?? this.observationsPartie,
      signe: signe ?? this.signe,
      dateSignature: dateSignature ?? this.dateSignature,
      signatureFileId: signatureFileId ?? this.signatureFileId,
      signatureData: signatureData ?? this.signatureData,
      photosFileIds: photosFileIds ?? this.photosFileIds,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      metadata: metadata ?? this.metadata,
    );
  }
}

/// 📊 États possibles d'un participant
class ParticipantStatut {
  static const String brouillon = 'brouillon';
  static const String invite = 'invite';
  static const String enSaisie = 'en_saisie';
  static const String pretASigner = 'pret_a_signer';
  static const String signe = 'signe';
  static const String refuseDeSigner = 'refuse_de_signer';

  static String getLibelle(String statut) {
    switch (statut) {
      case brouillon:
        return 'Brouillon';
      case invite:
        return 'Invité';
      case enSaisie:
        return 'En saisie';
      case pretASigner:
        return 'Prêt à signer';
      case signe:
        return 'Signé';
      case refuseDeSigner:
        return 'Refusé de signer';
      default:
        return statut;
    }
  }
}

/// 🚦 Circonstances de l'accident (cases 11-17 du constat)
class CirconstancesAccident {
  static const Map<int, String> circonstances = {
    11: 'doublait',
    12: 'virait à droite',
    13: 'virait à gauche',
    14: 'reculait',
    15: 'empiétait sur la partie de chaussée réservée à la circulation en sens inverse',
    16: 'venait de droite (dans un carrefour)',
    17: 'n\'avait pas observé le signal de priorité',
  };

  static String getLibelle(int numero) {
    return circonstances[numero] ?? 'Circonstance inconnue';
  }

  static List<int> get allNumeros => circonstances.keys.toList();
}
