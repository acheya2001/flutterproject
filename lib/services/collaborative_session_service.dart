import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/collaborative_session_model.dart';
import '../models/guest_participant_model.dart';
import '../models/accident_session_complete.dart';

/// 🎯 Service principal pour gérer les sessions collaboratives
class CollaborativeSessionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _sessionsCollection = 'sessions_collaboratives';
  static const String _guestDataCollection = 'guest_participants_data';

  /// 🆕 Créer une nouvelle session collaborative
  static Future<CollaborativeSession> creerSessionCollaborative({
    required String typeAccident,
    required int nombreVehicules,
    required String nomCreateur,
    required String prenomCreateur,
    required String emailCreateur,
    required String telephoneCreateur,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Générer code de session unique (6 caractères alphanumériques)
      final codeSession = _genererCodeSession();
      
      // Générer données QR Code
      final qrCodeData = _genererQRCodeData(codeSession, typeAccident);

      // Créer le participant créateur
      final participantCreateur = SessionParticipant(
        userId: user.uid,
        nom: nomCreateur,
        prenom: prenomCreateur,
        email: emailCreateur,
        telephone: telephoneCreateur,
        roleVehicule: 'A', // Le créateur est toujours véhicule A
        type: ParticipantType.inscrit,
        statut: ParticipantStatus.rejoint,
        estCreateur: true,
        dateRejoint: DateTime.now(),
      );

      // Créer la session
      final session = CollaborativeSession(
        id: '', // Sera défini après création
        codeSession: codeSession,
        qrCodeData: qrCodeData,
        typeAccident: typeAccident,
        nombreVehicules: nombreVehicules,
        statut: SessionStatus.creation,
        conducteurCreateur: user.uid,
        participants: [participantCreateur],
        progression: SessionProgress(
          participantsRejoints: 1,
          formulairesTermines: 0,
          croquisValides: 0,
          signaturesEffectuees: 0,
          croquisCree: false,
          peutFinaliser: false,
        ),
        parametres: SessionSettings(),
        dateCreation: DateTime.now(),
      );

      // Sauvegarder en Firestore
      print('💾 [CREATION] Sauvegarde dans collection: $_sessionsCollection');
      print('💾 [CREATION] Code session: ${session.codeSession}');

      final docRef = await _firestore.collection(_sessionsCollection).add(session.toMap());

      print('✅ Session collaborative créée: ${docRef.id}');
      print('✅ Code session généré: ${session.codeSession}');

      // Retourner la session avec l'ID
      return CollaborativeSession(
        id: docRef.id,
        codeSession: session.codeSession,
        qrCodeData: session.qrCodeData,
        typeAccident: session.typeAccident,
        nombreVehicules: session.nombreVehicules,
        statut: session.statut,
        conducteurCreateur: session.conducteurCreateur,
        participants: session.participants,
        progression: session.progression,
        parametres: session.parametres,
        dateCreation: session.dateCreation,
      );
    } catch (e) {
      print('❌ Erreur création session collaborative: $e');
      throw Exception('Impossible de créer la session: $e');
    }
  }

  /// 🔍 Rejoindre une session par code
  static Future<CollaborativeSession?> rejoindreSession({
    required String codeSession,
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required ParticipantType type,
    String? adresse,
    String? cin,
  }) async {
    try {
      print('🔍 [REJOINDRE] Début recherche session avec code: $codeSession');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Rechercher la session par code
      print('🔍 [REJOINDRE] Recherche dans collection: $_sessionsCollection');
      final querySnapshot = await _firestore
          .collection(_sessionsCollection)
          .where('codeSession', isEqualTo: codeSession)
          .limit(1)
          .get();

      print('🔍 [REJOINDRE] Résultats trouvés: ${querySnapshot.docs.length}');

      if (querySnapshot.docs.isEmpty) {
        // Essayer de chercher toutes les sessions pour debug
        print('🔍 [DEBUG] Recherche de toutes les sessions actives...');
        final allSessions = await _firestore
            .collection(_sessionsCollection)
            .where('statut', whereIn: ['creation', 'attente_participants', 'en_cours'])
            .get();

        print('🔍 [DEBUG] Sessions actives trouvées: ${allSessions.docs.length}');
        for (var doc in allSessions.docs) {
          final data = doc.data();
          print('🔍 [DEBUG] Session ${doc.id}: code=${data['codeSession']}, statut=${data['statut']}');
        }

        throw Exception('Session non trouvée avec ce code: $codeSession');
      }

      final sessionDoc = querySnapshot.docs.first;
      final session = CollaborativeSession.fromMap(sessionDoc.data(), sessionDoc.id);

      // Vérifier si l'utilisateur n'est pas déjà dans la session
      final existeDejaParticipant = session.participants.any((p) => p.userId == user.uid);
      if (existeDejaParticipant) {
        throw Exception('Vous participez déjà à cette session');
      }

      // Vérifier si la session peut encore accepter des participants
      if (session.participants.length >= session.nombreVehicules) {
        throw Exception('Cette session est complète');
      }

      // Déterminer le rôle véhicule (A, B, C, etc.)
      final rolesUtilises = session.participants.map((p) => p.roleVehicule).toSet();
      final roleVehicule = _obtenirProchainRole(rolesUtilises, session.nombreVehicules);

      // Créer le nouveau participant
      final nouveauParticipant = SessionParticipant(
        userId: user.uid,
        nom: nom,
        prenom: prenom,
        email: email,
        telephone: telephone,
        roleVehicule: roleVehicule,
        type: type,
        statut: ParticipantStatus.rejoint,
        estCreateur: false,
        dateRejoint: DateTime.now(),
        adresse: adresse,
        cin: cin,
      );

      // Mettre à jour la session
      final participantsMisAJour = [...session.participants, nouveauParticipant];
      final progressionMiseAJour = SessionProgress(
        participantsRejoints: participantsMisAJour.length,
        formulairesTermines: session.progression.formulairesTermines,
        croquisValides: session.progression.croquisValides,
        signaturesEffectuees: session.progression.signaturesEffectuees,
        croquisCree: session.progression.croquisCree,
        peutFinaliser: session.progression.peutFinaliser,
      );

      // Déterminer le nouveau statut
      SessionStatus nouveauStatut = session.statut;
      if (participantsMisAJour.length == session.nombreVehicules) {
        nouveauStatut = SessionStatus.en_cours;
      } else if (session.statut == SessionStatus.creation) {
        nouveauStatut = SessionStatus.attente_participants;
      }

      // Sauvegarder les modifications
      await _firestore.collection(_sessionsCollection).doc(session.id).update({
        'participants': participantsMisAJour.map((p) => p.toMap()).toList(),
        'progression': progressionMiseAJour.toMap(),
        'statut': nouveauStatut.name,
        'dateModification': Timestamp.fromDate(DateTime.now()),
      });

      // Retourner la session mise à jour
      return CollaborativeSession(
        id: session.id,
        codeSession: session.codeSession,
        qrCodeData: session.qrCodeData,
        typeAccident: session.typeAccident,
        nombreVehicules: session.nombreVehicules,
        statut: nouveauStatut,
        conducteurCreateur: session.conducteurCreateur,
        participants: participantsMisAJour,
        progression: progressionMiseAJour,
        parametres: session.parametres,
        dateCreation: session.dateCreation,
        dateModification: DateTime.now(),
      );
    } catch (e) {
      print('❌ Erreur rejoindre session: $e');
      throw Exception('Impossible de rejoindre la session: $e');
    }
  }

  /// 📋 Obtenir une session par ID
  static Future<CollaborativeSession?> obtenirSession(String sessionId) async {
    try {
      final doc = await _firestore.collection(_sessionsCollection).doc(sessionId).get();
      if (!doc.exists) return null;
      
      return CollaborativeSession.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('❌ Erreur obtenir session: $e');
      return null;
    }
  }

  /// 📋 Obtenir une session par code
  static Future<CollaborativeSession?> obtenirSessionParCode(String codeSession) async {
    try {
      final querySnapshot = await _firestore
          .collection(_sessionsCollection)
          .where('codeSession', isEqualTo: codeSession)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;
      
      final doc = querySnapshot.docs.first;
      return CollaborativeSession.fromMap(doc.data(), doc.id);
    } catch (e) {
      print('❌ Erreur obtenir session par code: $e');
      return null;
    }
  }

  /// 🔄 Stream en temps réel d'une session
  static Stream<CollaborativeSession?> streamSession(String sessionId) {
    return _firestore
        .collection(_sessionsCollection)
        .doc(sessionId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return CollaborativeSession.fromMap(doc.data()!, doc.id);
    });
  }

  /// 💾 Sauvegarder les données d'un participant invité
  static Future<void> sauvegarderDonneesInvite(GuestParticipant guestData) async {
    try {
      await _firestore
          .collection(_guestDataCollection)
          .doc('${guestData.sessionId}_${guestData.participantId}')
          .set(guestData.toMap());
    } catch (e) {
      print('❌ Erreur sauvegarde données invité: $e');
      throw Exception('Impossible de sauvegarder les données: $e');
    }
  }

  /// 📋 Obtenir les données d'un participant invité
  static Future<GuestParticipant?> obtenirDonneesInvite(String sessionId, String participantId) async {
    try {
      final doc = await _firestore
          .collection(_guestDataCollection)
          .doc('${sessionId}_$participantId')
          .get();
      
      if (!doc.exists) return null;
      return GuestParticipant.fromMap(doc.data()!);
    } catch (e) {
      print('❌ Erreur obtenir données invité: $e');
      return null;
    }
  }

  /// 📊 Mettre à jour le statut d'un participant
  static Future<void> mettreAJourStatutParticipant({
    required String sessionId,
    required String userId,
    required ParticipantStatus nouveauStatut,
  }) async {
    try {
      final sessionDoc = await _firestore.collection(_sessionsCollection).doc(sessionId).get();

      if (!sessionDoc.exists) {
        throw Exception('Session non trouvée');
      }

      final sessionData = sessionDoc.data()!;
      final participants = List<Map<String, dynamic>>.from(sessionData['participants'] ?? []);

      // Trouver et mettre à jour le participant
      bool participantTrouve = false;
      for (int i = 0; i < participants.length; i++) {
        if (participants[i]['userId'] == userId) {
          participants[i]['statut'] = nouveauStatut.name;
          if (nouveauStatut == ParticipantStatus.formulaire_fini) {
            participants[i]['dateFormulaireFini'] = Timestamp.fromDate(DateTime.now());
          } else if (nouveauStatut == ParticipantStatus.signe) {
            participants[i]['dateSignature'] = Timestamp.fromDate(DateTime.now());
          }
          participantTrouve = true;
          break;
        }
      }

      if (!participantTrouve) {
        throw Exception('Participant non trouvé dans la session');
      }

      // Calculer la nouvelle progression
      final progression = _calculerProgression(participants);

      // Déterminer le nouveau statut de session
      final nouveauStatutSession = _determinerStatutSession(participants, progression);

      // Mettre à jour la session
      await _firestore.collection(_sessionsCollection).doc(sessionId).update({
        'participants': participants,
        'progression': progression.toMap(),
        'statut': nouveauStatutSession.name,
        'dateModification': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('❌ Erreur mise à jour statut participant: $e');
      throw Exception('Impossible de mettre à jour le statut: $e');
    }
  }

  /// 💾 Sauvegarder les données de formulaire d'un participant
  static Future<void> sauvegarderDonneesFormulaire({
    required String sessionId,
    required String userId,
    required Map<String, dynamic> donneesFormulaire,
  }) async {
    try {
      // Sauvegarder les données du formulaire
      await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection('formulaires')
          .doc(userId)
          .set({
        ...donneesFormulaire,
        'userId': userId,
        'dateModification': Timestamp.fromDate(DateTime.now()),
        'complete': true,
      });

      // Mettre à jour le statut du participant
      await mettreAJourStatutParticipant(
        sessionId: sessionId,
        userId: userId,
        nouveauStatut: ParticipantStatus.formulaire_fini,
      );
    } catch (e) {
      print('❌ Erreur sauvegarde formulaire: $e');
      throw Exception('Impossible de sauvegarder le formulaire: $e');
    }
  }

  /// 📋 Obtenir les données de formulaire d'un participant
  static Future<Map<String, dynamic>?> obtenirDonneesFormulaire(String sessionId, String userId) async {
    try {
      final doc = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection('formulaires')
          .doc(userId)
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('❌ Erreur obtenir données formulaire: $e');
      return null;
    }
  }

  /// 🔄 Stream des données de formulaire d'un participant
  static Stream<Map<String, dynamic>?> streamDonneesFormulaire(String sessionId, String userId) {
    return _firestore
        .collection(_sessionsCollection)
        .doc(sessionId)
        .collection('formulaires')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  /// 📊 Stream de tous les formulaires d'une session
  static Stream<List<Map<String, dynamic>>> streamTousLesFormulaires(String sessionId) {
    return _firestore
        .collection(_sessionsCollection)
        .doc(sessionId)
        .collection('formulaires')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
          'userId': doc.id,
          ...doc.data(),
        }).toList());
  }

  /// 📝 Mettre à jour les circonstances d'un participant
  static Future<void> mettreAJourCirconstances({
    required String sessionId,
    required String userId,
    required String roleVehicule,
    required List<String> circonstances,
  }) async {
    try {
      // Sauvegarder les circonstances dans la sous-collection
      await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection('circonstances')
          .doc(userId)
          .set({
        'userId': userId,
        'roleVehicule': roleVehicule,
        'circonstances': circonstances,
        'dateModification': Timestamp.fromDate(DateTime.now()),
      });

      print('✅ Circonstances sauvegardées pour $userId');
    } catch (e) {
      print('❌ Erreur sauvegarde circonstances: $e');
      throw Exception('Impossible de sauvegarder les circonstances: $e');
    }
  }

  /// 📋 Obtenir les circonstances d'un participant
  static Future<Map<String, dynamic>?> obtenirCirconstances(String sessionId, String userId) async {
    try {
      final doc = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection('circonstances')
          .doc(userId)
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('❌ Erreur obtenir circonstances: $e');
      return null;
    }
  }

  /// ✍️ Ajouter une signature
  static Future<void> ajouterSignature({
    required String sessionId,
    required String userId,
    required String signatureBase64,
    required String roleVehicule,
  }) async {
    try {
      // Sauvegarder la signature dans la sous-collection
      await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection('signatures')
          .doc(userId)
          .set({
        'userId': userId,
        'roleVehicule': roleVehicule,
        'signatureBase64': signatureBase64,
        'dateSignature': Timestamp.fromDate(DateTime.now()),
      });

      // Mettre à jour le statut du participant
      await mettreAJourStatutParticipant(
        sessionId: sessionId,
        userId: userId,
        nouveauStatut: ParticipantStatus.signe,
      );

      print('✅ Signature ajoutée pour $userId');
    } catch (e) {
      print('❌ Erreur ajout signature: $e');
      throw Exception('Impossible d\'ajouter la signature: $e');
    }
  }

  /// 📋 Obtenir toutes les signatures d'une session
  static Future<List<Map<String, dynamic>>> obtenirToutesLesSignatures(String sessionId) async {
    try {
      final snapshot = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection('signatures')
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('❌ Erreur obtenir signatures: $e');
      return [];
    }
  }

  /// 🔧 Méthodes utilitaires privées
  static SessionProgress _calculerProgression(List<Map<String, dynamic>> participants) {
    int participantsRejoints = 0;
    int formulairesTermines = 0;
    int croquisValides = 0;
    int signaturesEffectuees = 0;

    for (final participant in participants) {
      final statut = participant['statut'] as String?;

      if (statut != null && statut != 'en_attente') {
        participantsRejoints++;
      }

      if (statut == 'formulaire_fini' || statut == 'croquis_valide' || statut == 'signe') {
        formulairesTermines++;
      }

      if (statut == 'croquis_valide' || statut == 'signe') {
        croquisValides++;
      }

      if (statut == 'signe') {
        signaturesEffectuees++;
      }
    }

    return SessionProgress(
      participantsRejoints: participantsRejoints,
      formulairesTermines: formulairesTermines,
      croquisValides: croquisValides,
      signaturesEffectuees: signaturesEffectuees,
      croquisCree: false, // Sera mis à jour séparément
      peutFinaliser: signaturesEffectuees == participants.length,
    );
  }

  static SessionStatus _determinerStatutSession(List<Map<String, dynamic>> participants, SessionProgress progression) {
    final total = participants.length;

    // Vérifier si tous ont signé
    if (progression.signaturesEffectuees == total && total > 0) {
      return SessionStatus.finalise; // Changé de 'signe' à 'finalise'
    }
    // Vérifier si tous ont validé le croquis
    else if (progression.croquisValides == total && total > 0) {
      return SessionStatus.pret_signature;
    }
    // Vérifier si tous ont terminé leur formulaire
    else if (progression.formulairesTermines == total && total > 0) {
      return SessionStatus.validation_croquis;
    }
    // Vérifier si tous ont rejoint
    else if (progression.participantsRejoints == total && total > 0) {
      return SessionStatus.en_cours;
    }
    // Quelques participants ont rejoint
    else if (progression.participantsRejoints > 0) {
      return SessionStatus.attente_participants;
    }
    // Aucun participant
    else {
      return SessionStatus.creation;
    }
  }

  static String _genererCodeSession() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  static String _genererQRCodeData(String codeSession, String typeAccident) {
    return 'CONSTAT_TUNISIE:$codeSession:$typeAccident:${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 📝 Sauvegarder les informations générales d'une session collaborative
  static Future<void> sauvegarderInfosGenerales({
    required String sessionId,
    required DateTime dateAccident,
    required String heureAccident,
    required String lieuAccident,
    required String lieuGps,
    required bool blesses,
    required String detailsBlesses,
    required List<Map<String, dynamic>> temoins,
  }) async {
    try {
      await _firestore.collection(_sessionsCollection).doc(sessionId).update({
        'donneesCommunes': {
          'dateAccident': dateAccident.toIso8601String(),
          'heureAccident': heureAccident,
          'lieuAccident': lieuAccident,
          'lieuGps': lieuGps,
          'blesses': blesses,
          'detailsBlesses': detailsBlesses,
          'temoins': temoins,
          'dateModification': DateTime.now().toIso8601String(),
        },
        'dateModification': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Erreur sauvegarde infos générales: $e');
      throw Exception('Impossible de sauvegarder les informations générales: $e');
    }
  }

  /// 🔍 Rechercher des sessions par code
  static Future<List<CollaborativeSession>> getSessionsByCode(String code) async {
    try {
      print('🔍 [RECHERCHE] Recherche session avec code: $code');

      final querySnapshot = await _firestore
          .collection(_sessionsCollection)
          .where('codeSession', isEqualTo: code.toUpperCase())
          .where('statut', whereIn: ['creation', 'attente_participants', 'en_cours', 'validation_croquis', 'pret_signature'])
          .get();

      print('🔍 [RECHERCHE] Sessions trouvées: ${querySnapshot.docs.length}');

      final sessions = querySnapshot.docs.map((doc) {
        final data = doc.data();
        print('🔍 [RECHERCHE] Session ${doc.id}: code=${data['codeSession']}, statut=${data['statut']}');
        return CollaborativeSession.fromMap(data, doc.id);
      }).toList();

      return sessions;
    } catch (e) {
      print('❌ Erreur recherche session par code: $e');
      return [];
    }
  }

  /// 📝 Mettre à jour l'état du formulaire d'un participant
  static Future<void> mettreAJourEtatFormulaire({
    required String sessionId,
    required String userId,
    required FormulaireStatus nouvelEtat,
  }) async {
    try {
      print('📝 [FORMULAIRE] Mise à jour état: $userId → ${nouvelEtat.name}');

      final sessionRef = _firestore.collection(_sessionsCollection).doc(sessionId);
      final sessionDoc = await sessionRef.get();

      if (!sessionDoc.exists) {
        print('❌ Session non trouvée: $sessionId');
        return;
      }

      final sessionData = sessionDoc.data()!;
      final participants = List<Map<String, dynamic>>.from(sessionData['participants'] ?? []);

      // Trouver et mettre à jour le participant
      bool participantTrouve = false;
      for (int i = 0; i < participants.length; i++) {
        final userId_participant = participants[i]['userId'];
        print('🔍 [DEBUG] Comparaison userId: $userId_participant (${userId_participant.runtimeType}) vs $userId (${userId.runtimeType})');

        if (userId_participant.toString() == userId.toString()) {
          participants[i]['formulaireStatus'] = nouvelEtat.name;
          participants[i]['formulaireComplete'] = nouvelEtat == FormulaireStatus.termine;

          // Mettre à jour les dates selon l'état
          if (nouvelEtat == FormulaireStatus.termine) {
            participants[i]['dateFormulaireFini'] = DateTime.now().toIso8601String();
            participants[i]['statut'] = ParticipantStatus.formulaire_fini.name;
          } else if (nouvelEtat == FormulaireStatus.en_cours) {
            participants[i]['statut'] = ParticipantStatus.rejoint.name;
          }

          participantTrouve = true;
          break;
        }
      }

      if (!participantTrouve) {
        print('❌ Participant non trouvé: $userId');
        return;
      }

      // Calculer la progression globale
      final formulairesTermines = participants.where((p) =>
        p['formulaireStatus'] == FormulaireStatus.termine.name
      ).length;

      final progression = sessionData['progression'] as Map<String, dynamic>? ?? {};
      progression['formulairesTermines'] = formulairesTermines;

      // Déterminer si la session peut passer au statut suivant
      SessionStatus nouveauStatut = SessionStatus.values.firstWhere(
        (s) => s.name == sessionData['statut'],
        orElse: () => SessionStatus.en_cours,
      );

      if (formulairesTermines == participants.length) {
        nouveauStatut = SessionStatus.validation_croquis;
      }

      // Sauvegarder les modifications
      await sessionRef.update({
        'participants': participants,
        'progression': progression,
        'statut': nouveauStatut.name,
        'dateModification': DateTime.now().toIso8601String(),
      });

      print('✅ État formulaire mis à jour: ${nouvelEtat.name}');
      print('📊 Progression: $formulairesTermines/${participants.length} terminés');

    } catch (e) {
      print('❌ Erreur mise à jour état formulaire: $e');
      throw Exception('Impossible de mettre à jour l\'état du formulaire: $e');
    }
  }

  static String _obtenirProchainRole(Set<String> rolesUtilises, int nombreVehicules) {
    const roles = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O'];
    for (int i = 0; i < nombreVehicules && i < roles.length; i++) {
      if (!rolesUtilises.contains(roles[i])) {
        return roles[i];
      }
    }
    return 'Z'; // Fallback
  }
}
