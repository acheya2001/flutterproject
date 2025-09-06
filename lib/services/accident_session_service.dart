import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/accident_session.dart';
import '../models/accident_participant.dart';

/// 🚨 Service pour gérer les sessions d'accident collaboratives
class AccidentSessionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections Firestore
  static const String _sessionsCollection = 'accident_sessions';
  static const String _participantsCollection = 'accident_participants';
  static const String _invitationsCollection = 'accident_invitations';

  /// 🆕 Créer une nouvelle session d'accident
  static Future<AccidentSession> creerNouvelleSession({
    required String lieu,
    String? lieuGps,
    DateTime? dateAccident,
    TimeOfDay? heureAccident,
    int nombreVehicules = 2,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    final now = DateTime.now();
    final codePublic = _genererCodePublic();
    final deadline = _calculerDeadlineDeclaration(dateAccident ?? now);

    // Créer la localisation
    final localisation = <String, dynamic>{
      'adresse': lieu,
      'lat': null,
      'lng': null,
      'ville': '',
      'codePostal': '',
    };

    if (lieuGps != null && lieuGps.contains(',')) {
      final coords = lieuGps.split(',');
      if (coords.length == 2) {
        localisation['lat'] = double.tryParse(coords[0]);
        localisation['lng'] = double.tryParse(coords[1]);
      }
    }

    final session = AccidentSession(
      id: '', // Sera défini par Firestore
      codePublic: codePublic,
      createurUserId: user.uid,
      createurVehiculeId: '', // TODO: Passer le véhicule sélectionné
      statut: AccidentSession.STATUT_BROUILLON,
      dateOuverture: now,
      dateAccident: dateAccident,
      heureAccident: heureAccident,
      localisation: localisation,
      blesses: false,
      degatsAutres: false,
      temoins: [],
      identitesVehicules: {},
      pointsChocInitial: {},
      degatsApparents: {},
      circonstances: {},
      observationsVehicules: {},
      signatures: {},
      croquisFileId: null,
      croquisData: null,
      observations: '',
      photos: [],
      nombreParticipants: 2,
      rolesDisponibles: ['A', 'B'],
      deadlineDeclaration: deadline,
      declarationUnilaterale: false,
      dateCreation: now,
      dateModification: now,
    );

    final docRef = await _firestore
        .collection(_sessionsCollection)
        .add(session.toFirestore());

    return AccidentSession.fromFirestore(await docRef.get());
  }

  /// 🔍 Rejoindre une session avec un code public
  static Future<AccidentSession?> rejoindreSesssionParCode(String codePublic) async {
    final query = await _firestore
        .collection(_sessionsCollection)
        .where('codePublic', isEqualTo: codePublic.toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    return AccidentSession.fromFirestore(query.docs.first);
  }

  /// 👥 Ajouter un participant à une session
  static Future<AccidentParticipant> ajouterParticipant({
    required String sessionId,
    required String partie, // 'A' ou 'B'
    String? userId,
  }) async {
    final user = _auth.currentUser;
    final participantUserId = userId ?? user?.uid;
    
    if (participantUserId == null) {
      throw Exception('Utilisateur non connecté');
    }

    // Vérifier si le participant existe déjà pour cette session
    final existingQuery = await _firestore
        .collection(_participantsCollection)
        .where('sessionId', isEqualTo: sessionId)
        .where('userId', isEqualTo: participantUserId)
        .limit(1)
        .get();

    if (existingQuery.docs.isNotEmpty) {
      return AccidentParticipant.fromFirestore(existingQuery.docs.first);
    }

    final now = DateTime.now();
    final participant = AccidentParticipant(
      id: '', // Sera défini par Firestore
      sessionId: sessionId,
      userId: participantUserId,
      partie: partie,
      statut: ParticipantStatut.brouillon,
      nomConducteur: '',
      prenomConducteur: '',
      adresseConducteur: '',
      telephoneConducteur: '',
      marqueVehicule: '',
      typeVehicule: '',
      numeroImmatriculation: '',
      nomAssurance: '',
      numeroPolice: '',
      conducteurHabituel: true,
      createdAt: now,
      updatedAt: now,
    );

    final docRef = await _firestore
        .collection(_participantsCollection)
        .add(participant.toFirestore());

    return AccidentParticipant.fromFirestore(await docRef.get());
  }

  /// 📋 Récupérer les participants d'une session
  static Stream<List<AccidentParticipant>> getParticipantsSession(String sessionId) {
    return _firestore
        .collection(_participantsCollection)
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('partie')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AccidentParticipant.fromFirestore(doc))
            .toList());
  }

  /// 📝 Mettre à jour une session
  static Future<void> mettreAJourSession(
    String sessionId,
    Map<String, dynamic> updates,
  ) async {
    await _firestore
        .collection(_sessionsCollection)
        .doc(sessionId)
        .update({
          ...updates,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  /// 👤 Mettre à jour un participant
  static Future<void> mettreAJourParticipant(
    String participantId,
    Map<String, dynamic> updates,
  ) async {
    await _firestore
        .collection(_participantsCollection)
        .doc(participantId)
        .update({
          ...updates,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  /// 🔍 Récupérer un participant par ID
  static Future<AccidentParticipant?> getParticipantParId(String participantId) async {
    final doc = await _firestore
        .collection(_participantsCollection)
        .doc(participantId)
        .get();

    if (!doc.exists) return null;
    return AccidentParticipant.fromFirestore(doc);
  }

  /// ✍️ Signer en tant que participant
  static Future<void> signerParticipant(
    String participantId,
    Map<String, dynamic> signatureData,
  ) async {
    await mettreAJourParticipant(participantId, {
      'signe': true,
      'dateSignature': FieldValue.serverTimestamp(),
      'signatureData': signatureData,
      'statut': ParticipantStatut.signe,
    });
  }

  /// 📊 Vérifier si toutes les parties ont signé
  static Future<bool> toutesPartiesOntSigne(String sessionId) async {
    final participants = await _firestore
        .collection(_participantsCollection)
        .where('sessionId', isEqualTo: sessionId)
        .get();

    if (participants.docs.isEmpty) return false;

    return participants.docs.every((doc) {
      final data = doc.data();
      return data['signe'] == true;
    });
  }

  /// 🔄 Mettre à jour le statut de la session selon l'état des participants
  static Future<void> mettreAJourStatutSession(String sessionId) async {
    final participants = await _firestore
        .collection(_participantsCollection)
        .where('sessionId', isEqualTo: sessionId)
        .get();

    if (participants.docs.isEmpty) return;

    final tousSignes = participants.docs.every((doc) {
      final data = doc.data();
      return data['signe'] == true;
    });

    final nouveauStatut = tousSignes 
        ? AccidentSession.STATUT_SIGNE_VALIDE
        : AccidentSession.STATUT_SIGNATURE_EN_COURS;

    await mettreAJourSession(sessionId, {'statut': nouveauStatut});
  }

  /// 📱 Récupérer les sessions de l'utilisateur connecté
  static Stream<List<AccidentSession>> getSessionsUtilisateur() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection(_sessionsCollection)
        .where('createurUserId', isEqualTo: user.uid)
        .orderBy('dateOuverture', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AccidentSession.fromFirestore(doc))
            .toList());
  }

  /// 🔍 Récupérer une session par ID
  static Future<AccidentSession?> getSessionParId(String sessionId) async {
    final doc = await _firestore
        .collection(_sessionsCollection)
        .doc(sessionId)
        .get();

    if (!doc.exists) return null;
    return AccidentSession.fromFirestore(doc);
  }

  /// 🗑️ Supprimer une session (et tous ses participants)
  static Future<void> supprimerSession(String sessionId) async {
    final batch = _firestore.batch();

    // Supprimer tous les participants
    final participants = await _firestore
        .collection(_participantsCollection)
        .where('sessionId', isEqualTo: sessionId)
        .get();

    for (final doc in participants.docs) {
      batch.delete(doc.reference);
    }

    // Supprimer la session
    batch.delete(_firestore.collection(_sessionsCollection).doc(sessionId));

    await batch.commit();
  }

  /// 🎲 Générer un code public unique
  static String _genererCodePublic() {
    final now = DateTime.now();
    final year = now.year;
    final random = Random();
    final code = random.nextInt(9999).toString().padLeft(4, '0');
    return 'ACC-$year-$code';
  }

  /// ⏰ Calculer la deadline de déclaration (5 jours ouvrés)
  static DateTime _calculerDeadlineDeclaration(DateTime dateAccident) {
    var deadline = dateAccident;
    var joursAjoutes = 0;

    while (joursAjoutes < 5) {
      deadline = deadline.add(const Duration(days: 1));
      // Exclure les weekends (samedi = 6, dimanche = 7)
      if (deadline.weekday < 6) {
        joursAjoutes++;
      }
    }

    return deadline;
  }

  /// 📧 Envoyer une invitation à rejoindre la session
  static Future<void> envoyerInvitation({
    required String sessionId,
    required String emailDestinataire,
    required String codePublic,
  }) async {
    // TODO: Implémenter l'envoi d'email avec le code de session
    // Pour l'instant, on stocke juste l'invitation en base
    await _firestore.collection(_invitationsCollection).add({
      'sessionId': sessionId,
      'emailDestinataire': emailDestinataire,
      'codePublic': codePublic,
      'statut': 'envoyee',
      'dateEnvoi': FieldValue.serverTimestamp(),
    });
  }

  /// 📋 Obtenir une session par son ID
  static Future<AccidentSession?> obtenirSessionParId(String sessionId) async {
    try {
      final doc = await _firestore.collection(_sessionsCollection).doc(sessionId).get();

      if (!doc.exists) {
        return null;
      }

      // Utiliser le factory method existant du modèle
      return AccidentSession.fromFirestore(doc);
    } catch (e) {
      print('Erreur lors de la récupération de la session: $e');
      return null;
    }
  }

  /// ✅ Finaliser une session d'accident
  static Future<void> finaliserSession(String sessionId) async {
    try {
      await _firestore.collection(_sessionsCollection).doc(sessionId).update({
        'statut': 'finalise',
        'dateFinalisation': FieldValue.serverTimestamp(),
      });

      print('Session $sessionId finalisée avec succès');
    } catch (e) {
      print('Erreur lors de la finalisation de la session: $e');
      throw Exception('Impossible de finaliser la session: $e');
    }
  }

  /// 📊 Obtenir les statistiques d'une session
  static Future<Map<String, dynamic>> obtenirStatistiquesSession(String sessionId) async {
    try {
      final session = await obtenirSessionParId(sessionId);
      if (session == null) {
        throw Exception('Session introuvable');
      }

      final totalVehicules = session.nombreParticipants;
      final vehiculesCompletes = session.signatures.length;

      return {
        'totalVehicules': totalVehicules,
        'vehiculesCompletes': vehiculesCompletes,
        'pourcentageCompletion': totalVehicules > 0
            ? (vehiculesCompletes / totalVehicules * 100).round()
            : 0,
        'statut': session.statut,
        'blesses': session.blesses,
        'degatsAutres': session.degatsAutres,
        'rolesDisponibles': session.rolesDisponibles,
      };
    } catch (e) {
      print('Erreur lors du calcul des statistiques: $e');
      return {};
    }
  }

  /// 🔄 Mettre à jour le statut d'un véhicule
  static Future<void> mettreAJourStatutVehicule(
    String sessionId,
    String vehiculeId,
    String nouveauStatut,
  ) async {
    try {
      await _firestore.collection(_sessionsCollection).doc(sessionId).update({
        'identitesVehicules.$vehiculeId.statut': nouveauStatut,
        'identitesVehicules.$vehiculeId.dateMiseAJour': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur lors de la mise à jour du véhicule: $e');
      throw Exception('Impossible de mettre à jour le véhicule: $e');
    }
  }
}
