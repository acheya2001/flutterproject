import 'package:cloud_firestore/cloud_firestore.dart';

/// 🚨 Modèle de sinistre
class SinistreModel {
  final String id;
  final String numeroSinistre;
  final String sessionId;
  final String codeSession;
  
  // Informations du conducteur déclarant
  final String conducteurDeclarantId;
  final String vehiculeId;
  final String contratId;
  final String compagnieId;
  final String agenceId;
  
  // Informations de l'accident
  final DateTime dateAccident;
  final String heureAccident;
  final String lieuAccident;
  final String lieuGps;
  
  // Détails
  final String typeAccident;
  final int nombreVehicules;
  final bool blesses;
  final bool degatsMateriels;
  
  // Statut et workflow
  final SinistreStatut statut;
  final StatutSession statutSession;
  
  // Participants
  final List<Map<String, dynamic>> conducteurs;
  
  // Données du constat
  final Map<String, dynamic> croquisData;
  final Map<String, dynamic> circonstances;
  final List<Map<String, dynamic>> photos;
  
  // Métadonnées
  final DateTime dateCreation;
  final DateTime dateModification;
  final bool creeParConducteur;
  final String? commentaireStatut;

  SinistreModel({
    required this.id,
    required this.numeroSinistre,
    required this.sessionId,
    required this.codeSession,
    required this.conducteurDeclarantId,
    required this.vehiculeId,
    required this.contratId,
    required this.compagnieId,
    required this.agenceId,
    required this.dateAccident,
    required this.heureAccident,
    required this.lieuAccident,
    required this.lieuGps,
    required this.typeAccident,
    required this.nombreVehicules,
    required this.blesses,
    required this.degatsMateriels,
    required this.statut,
    required this.statutSession,
    required this.conducteurs,
    required this.croquisData,
    required this.circonstances,
    required this.photos,
    required this.dateCreation,
    required this.dateModification,
    required this.creeParConducteur,
    this.commentaireStatut,
  });

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'numeroSinistre': numeroSinistre,
      'sessionId': sessionId,
      'codeSession': codeSession,
      'conducteurDeclarantId': conducteurDeclarantId,
      'vehiculeId': vehiculeId,
      'contratId': contratId,
      'compagnieId': compagnieId,
      'agenceId': agenceId,
      'dateAccident': Timestamp.fromDate(dateAccident),
      'heureAccident': heureAccident,
      'lieuAccident': lieuAccident,
      'lieuGps': lieuGps,
      'typeAccident': typeAccident,
      'nombreVehicules': nombreVehicules,
      'blesses': blesses,
      'degatsMateriels': degatsMateriels,
      'statut': statut.name,
      'statutSession': statutSession.name,
      'conducteurs': conducteurs,
      'croquisData': croquisData,
      'circonstances': circonstances,
      'photos': photos,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'dateModification': Timestamp.fromDate(dateModification),
      'creeParConducteur': creeParConducteur,
      'commentaireStatut': commentaireStatut,
    };
  }

  /// Créer depuis Map Firestore
  factory SinistreModel.fromMap(Map<String, dynamic> map, String id) {
    return SinistreModel(
      id: id,
      numeroSinistre: map['numeroSinistre'] ?? '',
      sessionId: map['sessionId'] ?? '',
      codeSession: map['codeSession'] ?? '',
      conducteurDeclarantId: map['conducteurDeclarantId'] ?? '',
      vehiculeId: map['vehiculeId'] ?? '',
      contratId: map['contratId'] ?? '',
      compagnieId: map['compagnieId'] ?? '',
      agenceId: map['agenceId'] ?? '',
      dateAccident: (map['dateAccident'] as Timestamp?)?.toDate() ?? DateTime.now(),
      heureAccident: map['heureAccident'] ?? '',
      lieuAccident: map['lieuAccident'] ?? '',
      lieuGps: map['lieuGps'] ?? '',
      typeAccident: map['typeAccident'] ?? '',
      nombreVehicules: map['nombreVehicules'] ?? 2,
      blesses: map['blesses'] ?? false,
      degatsMateriels: map['degatsMateriels'] ?? false,
      statut: SinistreStatut.values.firstWhere(
        (s) => s.name == map['statut'],
        orElse: () => SinistreStatut.enAttente,
      ),
      statutSession: StatutSession.values.firstWhere(
        (s) => s.name == map['statutSession'],
        orElse: () => StatutSession.enAttenteParticipants,
      ),
      conducteurs: (map['conducteurs'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      croquisData: map['croquisData'] ?? {},
      circonstances: map['circonstances'] ?? {},
      photos: (map['photos'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      dateCreation: (map['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateModification: (map['dateModification'] as Timestamp?)?.toDate() ?? DateTime.now(),
      creeParConducteur: map['creeParConducteur'] ?? true,
      commentaireStatut: map['commentaireStatut'],
    );
  }

  /// Copier avec modifications
  SinistreModel copyWith({
    String? id,
    String? numeroSinistre,
    String? sessionId,
    String? codeSession,
    String? conducteurDeclarantId,
    String? vehiculeId,
    String? contratId,
    String? compagnieId,
    String? agenceId,
    DateTime? dateAccident,
    String? heureAccident,
    String? lieuAccident,
    String? lieuGps,
    String? typeAccident,
    int? nombreVehicules,
    bool? blesses,
    bool? degatsMateriels,
    SinistreStatut? statut,
    StatutSession? statutSession,
    List<Map<String, dynamic>>? conducteurs,
    Map<String, dynamic>? croquisData,
    Map<String, dynamic>? circonstances,
    List<Map<String, dynamic>>? photos,
    DateTime? dateCreation,
    DateTime? dateModification,
    bool? creeParConducteur,
    String? commentaireStatut,
  }) {
    return SinistreModel(
      id: id ?? this.id,
      numeroSinistre: numeroSinistre ?? this.numeroSinistre,
      sessionId: sessionId ?? this.sessionId,
      codeSession: codeSession ?? this.codeSession,
      conducteurDeclarantId: conducteurDeclarantId ?? this.conducteurDeclarantId,
      vehiculeId: vehiculeId ?? this.vehiculeId,
      contratId: contratId ?? this.contratId,
      compagnieId: compagnieId ?? this.compagnieId,
      agenceId: agenceId ?? this.agenceId,
      dateAccident: dateAccident ?? this.dateAccident,
      heureAccident: heureAccident ?? this.heureAccident,
      lieuAccident: lieuAccident ?? this.lieuAccident,
      lieuGps: lieuGps ?? this.lieuGps,
      typeAccident: typeAccident ?? this.typeAccident,
      nombreVehicules: nombreVehicules ?? this.nombreVehicules,
      blesses: blesses ?? this.blesses,
      degatsMateriels: degatsMateriels ?? this.degatsMateriels,
      statut: statut ?? this.statut,
      statutSession: statutSession ?? this.statutSession,
      conducteurs: conducteurs ?? this.conducteurs,
      croquisData: croquisData ?? this.croquisData,
      circonstances: circonstances ?? this.circonstances,
      photos: photos ?? this.photos,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
      creeParConducteur: creeParConducteur ?? this.creeParConducteur,
      commentaireStatut: commentaireStatut ?? this.commentaireStatut,
    );
  }
}

/// 📊 Statuts de sinistre
enum SinistreStatut {
  enAttente('En attente', 'Le sinistre est en attente de traitement'),
  enCours('En cours', 'Le sinistre est en cours de traitement'),
  enExpertise('En expertise', 'Le sinistre est en cours d\'expertise'),
  termine('Terminé', 'Le sinistre a été traité'),
  rejete('Rejeté', 'Le sinistre a été rejeté'),
  clos('Clos', 'Le sinistre est clos');

  const SinistreStatut(this.label, this.description);
  final String label;
  final String description;
}

/// 📈 Statuts de session de constat
enum StatutSession {
  enAttenteParticipants('En attente participants', 'En attente que tous les conducteurs rejoignent'),
  enCoursRemplissage('En cours de remplissage', 'Les conducteurs remplissent le constat'),
  enAttenteValidation('En attente validation', 'En attente de validation par tous les conducteurs'),
  termine('Terminé', 'Le constat est terminé et validé'),
  envoye('Envoyé', 'Le constat a été envoyé aux agences');

  const StatutSession(this.label, this.description);
  final String label;
  final String description;
}
