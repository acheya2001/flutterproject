import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// 👥 Modèle pour un participant à une session d'accident (nouveau système)
/// Supporte les conducteurs inscrits et non-inscrits
class AccidentParticipant {
  final String id;
  final String sessionId;
  final String role; // 'A', 'B', 'C', 'D'...
  final bool isRegistered; // true = inscrit, false = invité non-inscrit
  final String? userId; // null si non-inscrit
  
  // Profil éphémère pour non-inscrits
  final String nom;
  final String prenom;
  final String telephone;
  final String email;
  final String? cin;
  final String? permisNum;
  final String? permisCat;
  final DateTime? permisDate;
  
  // Case 6 - Société d'assurance
  final String? assureurId; // ID de la compagnie
  final String? agenceId; // ID de l'agence
  final String numeroPolice;
  final DateTime? attestationDu;
  final DateTime? attestationAu;
  
  // Case 7 - Identité du conducteur (si différent de l'assuré)
  final String? conducteurNom;
  final String? conducteurPrenom;
  final String? conducteurAdresse;
  final String? conducteurTel;
  final String? conducteurPermis;
  final DateTime? conducteurPermisDate;
  
  // Case 8 - Assuré (si différent du conducteur)
  final String? assureNom;
  final String? assurePrenom;
  final String? assureAdresse;
  
  // Case 9 - Identité du véhicule
  final String vehiculeMarque;
  final String vehiculeType;
  final String immatriculation;
  final String? sensSuivi;
  final String? venantDe;
  final String? allantA;
  
  // Case 10 - Point de choc initial
  final Map<String, dynamic>? chocInitial; // Schéma avec points
  
  // Case 11 - Dégâts apparents
  final String? degatsText;
  final List<String> degatsPhotos; // IDs des photos de dégâts
  
  // Case 12 - Circonstances (17 cases à cocher)
  final List<bool> circonstances; // Index 0-16 pour cases 1-17
  final int nbCirconstances; // Compteur affiché
  
  // Pièces jointes obligatoires
  final List<String> piecesJointes; // carte grise, attestation, permis
  
  // Signature électronique
  final SignatureData? signature;
  final String statutPartie; // 'en_saisie', 'signe'
  
  // Métadonnées
  final DateTime createdAt;
  final DateTime updatedAt;

  AccidentParticipant({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.isRegistered,
    this.userId,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.email,
    this.cin,
    this.permisNum,
    this.permisCat,
    this.permisDate,
    this.assureurId,
    this.agenceId,
    required this.numeroPolice,
    this.attestationDu,
    this.attestationAu,
    this.conducteurNom,
    this.conducteurPrenom,
    this.conducteurAdresse,
    this.conducteurTel,
    this.conducteurPermis,
    this.conducteurPermisDate,
    this.assureNom,
    this.assurePrenom,
    this.assureAdresse,
    required this.vehiculeMarque,
    required this.vehiculeType,
    required this.immatriculation,
    this.sensSuivi,
    this.venantDe,
    this.allantA,
    this.chocInitial,
    this.degatsText,
    this.degatsPhotos = const [],
    this.circonstances = const [],
    this.nbCirconstances = 0,
    this.piecesJointes = const [],
    this.signature,
    this.statutPartie = 'en_saisie',
    required this.createdAt,
    required this.updatedAt,
  });

  factory AccidentParticipant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AccidentParticipant(
      id: doc.id,
      sessionId: data['sessionId'] ?? '',
      role: data['role'] ?? 'A',
      isRegistered: data['isRegistered'] ?? false,
      userId: data['userId'],
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      telephone: data['telephone'] ?? '',
      email: data['email'] ?? '',
      cin: data['cin'],
      permisNum: data['permisNum'],
      permisCat: data['permisCat'],
      permisDate: data['permisDate'] != null 
          ? (data['permisDate'] as Timestamp).toDate() 
          : null,
      assureurId: data['assureurId'],
      agenceId: data['agenceId'],
      numeroPolice: data['numeroPolice'] ?? '',
      attestationDu: data['attestationDu'] != null 
          ? (data['attestationDu'] as Timestamp).toDate() 
          : null,
      attestationAu: data['attestationAu'] != null 
          ? (data['attestationAu'] as Timestamp).toDate() 
          : null,
      conducteurNom: data['conducteurNom'],
      conducteurPrenom: data['conducteurPrenom'],
      conducteurAdresse: data['conducteurAdresse'],
      conducteurTel: data['conducteurTel'],
      conducteurPermis: data['conducteurPermis'],
      conducteurPermisDate: data['conducteurPermisDate'] != null 
          ? (data['conducteurPermisDate'] as Timestamp).toDate() 
          : null,
      assureNom: data['assureNom'],
      assurePrenom: data['assurePrenom'],
      assureAdresse: data['assureAdresse'],
      vehiculeMarque: data['vehiculeMarque'] ?? '',
      vehiculeType: data['vehiculeType'] ?? '',
      immatriculation: data['immatriculation'] ?? '',
      sensSuivi: data['sensSuivi'],
      venantDe: data['venantDe'],
      allantA: data['allantA'],
      chocInitial: data['chocInitial'],
      degatsText: data['degatsText'],
      degatsPhotos: List<String>.from(data['degatsPhotos'] ?? []),
      circonstances: List<bool>.from(data['circonstances'] ?? List.filled(17, false)),
      nbCirconstances: data['nbCirconstances'] ?? 0,
      piecesJointes: List<String>.from(data['piecesJointes'] ?? []),
      signature: data['signature'] != null 
          ? SignatureData.fromMap(data['signature']) 
          : null,
      statutPartie: data['statutPartie'] ?? 'en_saisie',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
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
      'telephone': telephone,
      'email': email,
      'cin': cin,
      'permisNum': permisNum,
      'permisCat': permisCat,
      'permisDate': permisDate != null 
          ? Timestamp.fromDate(permisDate!) 
          : null,
      'assureurId': assureurId,
      'agenceId': agenceId,
      'numeroPolice': numeroPolice,
      'attestationDu': attestationDu != null 
          ? Timestamp.fromDate(attestationDu!) 
          : null,
      'attestationAu': attestationAu != null 
          ? Timestamp.fromDate(attestationAu!) 
          : null,
      'conducteurNom': conducteurNom,
      'conducteurPrenom': conducteurPrenom,
      'conducteurAdresse': conducteurAdresse,
      'conducteurTel': conducteurTel,
      'conducteurPermis': conducteurPermis,
      'conducteurPermisDate': conducteurPermisDate != null 
          ? Timestamp.fromDate(conducteurPermisDate!) 
          : null,
      'assureNom': assureNom,
      'assurePrenom': assurePrenom,
      'assureAdresse': assureAdresse,
      'vehiculeMarque': vehiculeMarque,
      'vehiculeType': vehiculeType,
      'immatriculation': immatriculation,
      'sensSuivi': sensSuivi,
      'venantDe': venantDe,
      'allantA': allantA,
      'chocInitial': chocInitial,
      'degatsText': degatsText,
      'degatsPhotos': degatsPhotos,
      'circonstances': circonstances,
      'nbCirconstances': nbCirconstances,
      'piecesJointes': piecesJointes,
      'signature': signature?.toMap(),
      'statutPartie': statutPartie,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Vérifie si toutes les sections obligatoires sont remplies
  bool get isComplete {
    // Vérifications de base
    if (nom.isEmpty || prenom.isEmpty || telephone.isEmpty || email.isEmpty) {
      return false;
    }
    
    // Véhicule obligatoire
    if (vehiculeMarque.isEmpty || vehiculeType.isEmpty || immatriculation.isEmpty) {
      return false;
    }
    
    // Assurance obligatoire
    if (numeroPolice.isEmpty) {
      return false;
    }
    
    // Point de choc obligatoire
    if (chocInitial == null) {
      return false;
    }
    
    // Pièces jointes minimales
    if (piecesJointes.length < 3) { // carte grise, attestation, permis
      return false;
    }
    
    return true;
  }

  /// Compte le nombre de circonstances cochées
  int get circonstancesCount {
    return circonstances.where((c) => c).length;
  }
}

/// 🖊️ Données de signature électronique avec OTP
class SignatureData {
  final String otpLog; // Log de l'OTP utilisé
  final DateTime timestamp;
  final String ipAddress;
  final String deviceInfo;
  final String pdfHash; // Hash du PDF signé

  SignatureData({
    required this.otpLog,
    required this.timestamp,
    required this.ipAddress,
    required this.deviceInfo,
    required this.pdfHash,
  });

  factory SignatureData.fromMap(Map<String, dynamic> map) {
    return SignatureData(
      otpLog: map['otpLog'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      ipAddress: map['ipAddress'] ?? '',
      deviceInfo: map['deviceInfo'] ?? '',
      pdfHash: map['pdfHash'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'otpLog': otpLog,
      'timestamp': timestamp.toIso8601String(),
      'ipAddress': ipAddress,
      'deviceInfo': deviceInfo,
      'pdfHash': pdfHash,
    };
  }
}
