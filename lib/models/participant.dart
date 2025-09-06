import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour un participant à une session d'accident
class Participant {
  final String id;
  final String sessionId;
  final String role; // A, B, C, D... (véhicules impliqués)
  final bool isRegistered; // true si utilisateur inscrit, false si invité
  final String? userId; // null si non inscrit
  
  // Identité du conducteur (case 7)
  final String nom;
  final String prenom;
  final String adresse;
  final String tel;
  final String email;
  final String cin;
  final String permisNum;
  final String permisCat;
  final DateTime? permisDate;
  
  // Assurance (case 6)
  final String? assureurId;
  final String? agenceId;
  final String policeNum;
  final DateTime? attestationDu;
  final DateTime? attestationAu;
  
  // Assuré si différent (case 8)
  final String? assureNom;
  final String? assureAdresse;
  
  // Véhicule (case 9)
  final String vehMarque;
  final String vehType;
  final String immatriculation;
  final String sensSuivi;
  final String venantDe;
  final String allantA;
  
  // Dégâts et choc (cases 10-11)
  final String degatsText;
  final List<String> degatsPhotos;
  final Map<String, dynamic>? chocInitial; // Point de choc sur schéma
  
  // Circonstances (case 12)
  final List<bool> circonstances; // 17 cases à cocher
  final int nbCirconstances;
  
  // Pièces jointes
  final List<String> piecesJointes; // URLs/IDs des fichiers
  
  // Signature
  final Map<String, dynamic>? signature; // {otpLog, timestamp, ip, device, hash}
  final String statutPartie; // en_saisie, signe
  
  final DateTime? dateCreation;
  final DateTime? dateModification;

  Participant({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.isRegistered,
    this.userId,
    required this.nom,
    required this.prenom,
    required this.adresse,
    required this.tel,
    required this.email,
    required this.cin,
    required this.permisNum,
    required this.permisCat,
    this.permisDate,
    this.assureurId,
    this.agenceId,
    required this.policeNum,
    this.attestationDu,
    this.attestationAu,
    this.assureNom,
    this.assureAdresse,
    required this.vehMarque,
    required this.vehType,
    required this.immatriculation,
    required this.sensSuivi,
    required this.venantDe,
    required this.allantA,
    required this.degatsText,
    required this.degatsPhotos,
    this.chocInitial,
    required this.circonstances,
    required this.nbCirconstances,
    required this.piecesJointes,
    this.signature,
    required this.statutPartie,
    this.dateCreation,
    this.dateModification,
  });

  /// États possibles d'un participant
  static const String STATUT_EN_SAISIE = 'en_saisie';
  static const String STATUT_SIGNE = 'signe';
  static const String STATUT_REFUSE = 'refuse';

  /// Rôles des véhicules
  static const String ROLE_A = 'A';
  static const String ROLE_B = 'B';
  static const String ROLE_C = 'C';
  static const String ROLE_D = 'D';

  factory Participant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Participant(
      id: doc.id,
      sessionId: data['sessionId'] ?? '',
      role: data['role'] ?? ROLE_A,
      isRegistered: data['isRegistered'] ?? false,
      userId: data['userId'],
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      adresse: data['adresse'] ?? '',
      tel: data['tel'] ?? '',
      email: data['email'] ?? '',
      cin: data['cin'] ?? '',
      permisNum: data['permisNum'] ?? '',
      permisCat: data['permisCat'] ?? '',
      permisDate: (data['permisDate'] as Timestamp?)?.toDate(),
      assureurId: data['assureurId'],
      agenceId: data['agenceId'],
      policeNum: data['policeNum'] ?? '',
      attestationDu: (data['attestationDu'] as Timestamp?)?.toDate(),
      attestationAu: (data['attestationAu'] as Timestamp?)?.toDate(),
      assureNom: data['assureNom'],
      assureAdresse: data['assureAdresse'],
      vehMarque: data['vehMarque'] ?? '',
      vehType: data['vehType'] ?? '',
      immatriculation: data['immatriculation'] ?? '',
      sensSuivi: data['sensSuivi'] ?? '',
      venantDe: data['venantDe'] ?? '',
      allantA: data['allantA'] ?? '',
      degatsText: data['degatsText'] ?? '',
      degatsPhotos: List<String>.from(data['degatsPhotos'] ?? []),
      chocInitial: data['chocInitial'] != null ? 
          Map<String, dynamic>.from(data['chocInitial']) : null,
      circonstances: List<bool>.from(data['circonstances'] ?? List.filled(17, false)),
      nbCirconstances: data['nbCirconstances'] ?? 0,
      piecesJointes: List<String>.from(data['piecesJointes'] ?? []),
      signature: data['signature'] != null ? 
          Map<String, dynamic>.from(data['signature']) : null,
      statutPartie: data['statutPartie'] ?? STATUT_EN_SAISIE,
      dateCreation: (data['dateCreation'] as Timestamp?)?.toDate(),
      dateModification: (data['dateModification'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sessionId': sessionId,
      'role': role,
      'isRegistered': isRegistered,
      'userId': userId,
      'nom': nom,
      'prenom': prenom,
      'adresse': adresse,
      'tel': tel,
      'email': email,
      'cin': cin,
      'permisNum': permisNum,
      'permisCat': permisCat,
      'permisDate': permisDate != null ? Timestamp.fromDate(permisDate!) : null,
      'assureurId': assureurId,
      'agenceId': agenceId,
      'policeNum': policeNum,
      'attestationDu': attestationDu != null ? Timestamp.fromDate(attestationDu!) : null,
      'attestationAu': attestationAu != null ? Timestamp.fromDate(attestationAu!) : null,
      'assureNom': assureNom,
      'assureAdresse': assureAdresse,
      'vehMarque': vehMarque,
      'vehType': vehType,
      'immatriculation': immatriculation,
      'sensSuivi': sensSuivi,
      'venantDe': venantDe,
      'allantA': allantA,
      'degatsText': degatsText,
      'degatsPhotos': degatsPhotos,
      'chocInitial': chocInitial,
      'circonstances': circonstances,
      'nbCirconstances': nbCirconstances,
      'piecesJointes': piecesJointes,
      'signature': signature,
      'statutPartie': statutPartie,
      'dateCreation': dateCreation != null ? Timestamp.fromDate(dateCreation!) : FieldValue.serverTimestamp(),
      'dateModification': FieldValue.serverTimestamp(),
    };
  }

  /// Vérifie si le participant a signé
  bool get isSigned => statutPartie == STATUT_SIGNE;

  /// Vérifie si toutes les données obligatoires sont remplies
  bool get isComplete {
    return nom.isNotEmpty &&
           prenom.isNotEmpty &&
           tel.isNotEmpty &&
           email.isNotEmpty &&
           cin.isNotEmpty &&
           permisNum.isNotEmpty &&
           policeNum.isNotEmpty &&
           vehMarque.isNotEmpty &&
           vehType.isNotEmpty &&
           immatriculation.isNotEmpty &&
           piecesJointes.length >= 3; // Minimum: carte grise, attestation, permis
  }

  /// Compte le nombre de circonstances cochées
  int get circonstancesCount => circonstances.where((c) => c).length;

  /// Labels des 17 circonstances du constat papier
  static const List<String> circonstancesLabels = [
    '1. Stationnait',
    '2. Quittait un stationnement',
    '3. Prenait un stationnement',
    '4. Sortait d\'un parking, lieu privé, chemin de terre',
    '5. S\'engageait dans un parking, lieu privé, chemin de terre',
    '6. S\'engageait sur une place à sens giratoire',
    '7. Circulait sur une place à sens giratoire',
    '8. Heurtait par l\'arrière',
    '9. Roulait dans le même sens et sur la même file',
    '10. Changeait de file',
    '11. Doublait',
    '12. Virait à droite',
    '13. Virait à gauche',
    '14. Reculait',
    '15. Empiétait sur une voie réservée à la circulation en sens inverse',
    '16. Venait de droite (dans un carrefour)',
    '17. N\'avait pas observé un signal de priorité ou un feu de signalisation',
  ];

  Participant copyWith({
    String? id,
    String? sessionId,
    String? role,
    bool? isRegistered,
    String? userId,
    String? nom,
    String? prenom,
    String? adresse,
    String? tel,
    String? email,
    String? cin,
    String? permisNum,
    String? permisCat,
    DateTime? permisDate,
    String? assureurId,
    String? agenceId,
    String? policeNum,
    DateTime? attestationDu,
    DateTime? attestationAu,
    String? assureNom,
    String? assureAdresse,
    String? vehMarque,
    String? vehType,
    String? immatriculation,
    String? sensSuivi,
    String? venantDe,
    String? allantA,
    String? degatsText,
    List<String>? degatsPhotos,
    Map<String, dynamic>? chocInitial,
    List<bool>? circonstances,
    int? nbCirconstances,
    List<String>? piecesJointes,
    Map<String, dynamic>? signature,
    String? statutPartie,
    DateTime? dateCreation,
    DateTime? dateModification,
  }) {
    return Participant(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      isRegistered: isRegistered ?? this.isRegistered,
      userId: userId ?? this.userId,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      adresse: adresse ?? this.adresse,
      tel: tel ?? this.tel,
      email: email ?? this.email,
      cin: cin ?? this.cin,
      permisNum: permisNum ?? this.permisNum,
      permisCat: permisCat ?? this.permisCat,
      permisDate: permisDate ?? this.permisDate,
      assureurId: assureurId ?? this.assureurId,
      agenceId: agenceId ?? this.agenceId,
      policeNum: policeNum ?? this.policeNum,
      attestationDu: attestationDu ?? this.attestationDu,
      attestationAu: attestationAu ?? this.attestationAu,
      assureNom: assureNom ?? this.assureNom,
      assureAdresse: assureAdresse ?? this.assureAdresse,
      vehMarque: vehMarque ?? this.vehMarque,
      vehType: vehType ?? this.vehType,
      immatriculation: immatriculation ?? this.immatriculation,
      sensSuivi: sensSuivi ?? this.sensSuivi,
      venantDe: venantDe ?? this.venantDe,
      allantA: allantA ?? this.allantA,
      degatsText: degatsText ?? this.degatsText,
      degatsPhotos: degatsPhotos ?? this.degatsPhotos,
      chocInitial: chocInitial ?? this.chocInitial,
      circonstances: circonstances ?? this.circonstances,
      nbCirconstances: nbCirconstances ?? this.nbCirconstances,
      piecesJointes: piecesJointes ?? this.piecesJointes,
      signature: signature ?? this.signature,
      statutPartie: statutPartie ?? this.statutPartie,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
    );
  }
}
