import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/collaborative_session_model.dart';
import 'collaborative_pdf_service.dart';
import 'modern_tunisian_pdf_service.dart';
import 'agent_notification_service.dart';
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
      print('🔄 [STATUT] Début mise à jour statut pour userId: $userId, nouveau statut: ${nouveauStatut.name}');
      final sessionDoc = await _firestore.collection(_sessionsCollection).doc(sessionId).get();

      if (!sessionDoc.exists) {
        throw Exception('Session non trouvée');
      }

      final sessionData = sessionDoc.data()!;

      // Gestion sécurisée du type de participants
      List<Map<String, dynamic>> participants = [];
      final participantsData = sessionData['participants'];

      if (participantsData != null) {
        if (participantsData is List) {
          // Si c'est déjà une liste, la convertir en sécurité
          participants = participantsData.map((item) {
            if (item is Map<String, dynamic>) {
              return item;
            } else if (item is Map) {
              return Map<String, dynamic>.from(item);
            } else {
              print('⚠️ [STATUT] Participant ignoré (type invalide): $item');
              return <String, dynamic>{};
            }
          }).where((item) => item.isNotEmpty).toList();
        } else if (participantsData is Map) {
          // Si c'est un Map, le convertir en liste
          print('🔄 [STATUT] Conversion Map vers List pour participants');
          participants = [Map<String, dynamic>.from(participantsData)];
        } else {
          print('⚠️ [STATUT] Type de participants non supporté: ${participantsData.runtimeType}');
        }
      }

      print('📊 [STATUT] Participants chargés: ${participants.length}');

      // Trouver et mettre à jour le participant
      bool participantTrouve = false;
      for (int i = 0; i < participants.length; i++) {
        if (participants[i]['userId'] == userId) {
          final ancienStatut = participants[i]['statut'];
          participants[i]['statut'] = nouveauStatut.name;
          if (nouveauStatut == ParticipantStatus.formulaire_fini) {
            participants[i]['dateFormulaireFini'] = Timestamp.fromDate(DateTime.now());
          } else if (nouveauStatut == ParticipantStatus.signe) {
            participants[i]['dateSignature'] = Timestamp.fromDate(DateTime.now());
          }
          print('🔄 [STATUT] Participant $userId: $ancienStatut → ${nouveauStatut.name}');
          participantTrouve = true;
          break;
        }
      }

      if (!participantTrouve) {
        throw Exception('Participant non trouvé dans la session');
      }

      // Calculer la nouvelle progression avec sessionId pour comptage signatures
      final progression = await _calculerProgression(participants, sessionId);

      // Déterminer le nouveau statut de session
      final nouveauStatutSession = _determinerStatutSession(participants, progression);

      // Mettre à jour la session
      print('🔄 [STATUT] Mise à jour session avec ${participants.length} participants, ${progression.signaturesEffectuees} signatures');
      await _firestore.collection(_sessionsCollection).doc(sessionId).update({
        'participants': participants,
        'progression': progression.toMap(),
        'statut': nouveauStatutSession.name,
        'dateModification': Timestamp.fromDate(DateTime.now()),
      });
      print('✅ [STATUT] Statut participant mis à jour avec succès');
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
      print('🔄 [SIGNATURE] Début ajout signature pour userId: $userId, sessionId: $sessionId');
      print('🔄 [SIGNATURE] Collection: $_sessionsCollection');
      print('🔄 [SIGNATURE] RoleVehicule: $roleVehicule');

      // Vérifier que la session existe
      final sessionDoc = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) {
        throw Exception('Session $sessionId non trouvée');
      }

      print('✅ [SIGNATURE] Session trouvée: ${sessionDoc.id}');

      // Sauvegarder la signature dans la sous-collection
      final signatureData = {
        'userId': userId,
        'roleVehicule': roleVehicule,
        'signatureBase64': signatureBase64,
        'dateSignature': Timestamp.fromDate(DateTime.now()),
        'dateCreation': DateTime.now().toIso8601String(),
      };

      print('🔄 [SIGNATURE] Sauvegarde dans: $_sessionsCollection/$sessionId/signatures/$userId');

      await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection('signatures')
          .doc(userId)
          .set(signatureData);

      print('✅ [SIGNATURE] Signature sauvegardée dans Firestore');

      // Vérifier que la signature a été sauvegardée
      final signatureDoc = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection('signatures')
          .doc(userId)
          .get();

      if (signatureDoc.exists) {
        print('✅ [SIGNATURE] Vérification: signature bien enregistrée');
      } else {
        print('❌ [SIGNATURE] ERREUR: signature non trouvée après sauvegarde');
      }

      // Mettre à jour le statut du participant
      print('🔄 [SIGNATURE] Mise à jour statut participant...');
      await mettreAJourStatutParticipant(
        sessionId: sessionId,
        userId: userId,
        nouveauStatut: ParticipantStatus.signe,
      );

      // Vérifier à nouveau après la mise à jour
      print('🔄 [SIGNATURE] Vérification finale après mise à jour...');
      final finalSignaturesSnapshot = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection('signatures')
          .get();

      print('🔍 [SIGNATURE] Nombre de signatures après mise à jour: ${finalSignaturesSnapshot.docs.length}');
      for (final doc in finalSignaturesSnapshot.docs) {
        print('🔍 [SIGNATURE] - ID: ${doc.id}, Data: ${doc.data()}');
      }

      print('✅ [SIGNATURE] Signature ajoutée avec succès pour $userId');

      // 🔄 Forcer la mise à jour de la progression pour corriger le bug d'affichage
      try {
        await forcerMiseAJourProgressionSignatures(sessionId);
        print('🔄 [SIGNATURE] Progression forcée mise à jour automatiquement');
      } catch (e) {
        print('⚠️ [SIGNATURE] Erreur mise à jour progression forcée: $e');
      }

    } catch (e) {
      print('❌ [SIGNATURE] Erreur ajout signature: $e');
      print('❌ [SIGNATURE] Stack trace: ${StackTrace.current}');
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

  /// 🏁 Finaliser la session et déclencher la génération PDF + envoi
  static Future<void> finaliserSession(String sessionId) async {
    try {
      print('🏁 [FINALISATION] Début finalisation session $sessionId');

      // 1. Récupérer les données de la session
      final sessionDoc = await _firestore.collection(_sessionsCollection).doc(sessionId).get();
      if (!sessionDoc.exists) {
        throw Exception('Session non trouvée');
      }

      final sessionData = sessionDoc.data()!;
      final participants = List<Map<String, dynamic>>.from(sessionData['participants'] ?? []);

      // 2. Vérifier que tout est prêt pour la finalisation
      final progression = await _calculerProgression(participants, sessionId);
      final nombreVehicules = sessionData['nombreVehicules'] ?? 2;

      // Vérifier aussi les signatures dans la sous-collection
      final signaturesSnapshot = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection('signatures')
          .get();

      final signaturesEnSousCollection = signaturesSnapshot.docs.length;
      final signaturesMaximales = math.max(progression.signaturesEffectuees, signaturesEnSousCollection);

      print('🔍 [FINALISATION] Vérification signatures:');
      print('   - Participants: ${participants.length}');
      print('   - Nombre véhicules: $nombreVehicules');
      print('   - Signatures depuis statuts: ${progression.signaturesEffectuees}');
      print('   - Signatures en sous-collection: $signaturesEnSousCollection');
      print('   - Signatures maximales: $signaturesMaximales');

      if (signaturesMaximales < nombreVehicules) {
        throw Exception('Toutes les signatures ne sont pas encore effectuées ($signaturesMaximales/$nombreVehicules)');
      }

      // 3. Marquer la session comme finalisée
      await _firestore.collection(_sessionsCollection).doc(sessionId).update({
        'statut': 'finalise',
        'dateFinalisation': Timestamp.fromDate(DateTime.now()),
        'dateModification': Timestamp.fromDate(DateTime.now()),
      });

      // 4. Récupérer toutes les données nécessaires pour le PDF
      final donneesAccident = sessionData['donneesAccident'] ?? {};
      final participantsData = await _recupererDonneesParticipants(sessionId, participants);
      final croquisData = await _recupererDonneesCroquis(sessionId);

      // 5. Générer le PDF au format tunisien officiel
      print('📄 [FINALISATION] Génération du PDF format tunisien...');
      final pdfUrl = await ModernTunisianPdfService.genererConstatModerne(
        sessionId: sessionId,
      );

      // 6. Mettre à jour la session avec l'URL du PDF
      await _firestore.collection(_sessionsCollection).doc(sessionId).update({
        'pdfUrl': pdfUrl,
        'dateModification': Timestamp.fromDate(DateTime.now()),
      });

      // 7. Envoyer aux agents d'assurance
      print('📧 [FINALISATION] Envoi aux agents...');
      await _envoyerAuxAgents(sessionId, participantsData, pdfUrl);

      // 8. Traiter les notifications en attente
      print('📧 [FINALISATION] Traitement des notifications...');
      await AgentNotificationService.traiterNotificationsConstats();

      print('✅ [FINALISATION] Session finalisée avec succès');

    } catch (e) {
      print('❌ [FINALISATION] Erreur: $e');
      rethrow;
    }
  }

  /// 📋 Récupérer les données complètes des participants
  static Future<List<Map<String, dynamic>>> _recupererDonneesParticipants(
    String sessionId,
    List<Map<String, dynamic>> participants
  ) async {
    final participantsData = <Map<String, dynamic>>[];

    for (final participant in participants) {
      final userId = participant['userId'] as String;

      // Récupérer le formulaire du participant
      final formulaireDoc = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection('formulaires')
          .doc(userId)
          .get();

      if (formulaireDoc.exists) {
        final donneesFormulaire = formulaireDoc.data()!;
        participantsData.add({
          ...participant,
          'donneesFormulaire': donneesFormulaire,
        });
      }
    }

    return participantsData;
  }

  /// 🎨 Récupérer les données du croquis
  static Future<Map<String, dynamic>> _recupererDonneesCroquis(String sessionId) async {
    try {
      final croquisDoc = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection('croquis')
          .doc('principal')
          .get();

      if (croquisDoc.exists) {
        return croquisDoc.data()!;
      }
    } catch (e) {
      print('⚠️ [FINALISATION] Erreur récupération croquis: $e');
    }

    return {};
  }

  /// 📧 Envoyer le constat aux agents d'assurance responsables des véhicules
  static Future<void> _envoyerAuxAgents(String sessionId, List<Map<String, dynamic>> participantsData, String pdfUrl) async {
    try {
      for (final participant in participantsData) {
        final donneesFormulaire = participant['donneesFormulaire'] as Map<String, dynamic>? ?? {};
        final donneesVehicule = donneesFormulaire['donneesVehicule'] as Map<String, dynamic>? ?? {};
        final donneesAssurance = donneesFormulaire['donneesAssurance'] as Map<String, dynamic>? ?? {};

        final immatriculation = donneesVehicule['immatriculation'] as String?;
        final numeroPolice = donneesAssurance['numeroPolice'] as String?;

        if (immatriculation != null && numeroPolice != null) {
          // 1. Chercher le contrat par numéro de police et immatriculation
          final contratQuery = await _firestore
              .collection('contrats')
              .where('numeroPolice', isEqualTo: numeroPolice)
              .where('immatriculation', isEqualTo: immatriculation)
              .limit(1)
              .get();

          if (contratQuery.docs.isNotEmpty) {
            final contratData = contratQuery.docs.first.data();
            final agentId = contratData['agentId'] as String?;

            if (agentId != null) {
              // 2. Récupérer les informations de l'agent responsable
              final agentDoc = await _firestore
                  .collection('agents_assurance')
                  .doc(agentId)
                  .get();

              if (agentDoc.exists) {
                final agentData = agentDoc.data()!;
                final emailAgent = agentData['email'] as String?;

                if (emailAgent != null) {
                  // 3. Envoyer l'email à l'agent responsable du contrat
                  await _envoyerEmailAgent(emailAgent, sessionId, participant, pdfUrl, contratQuery.docs.first.id);
                  print('📧 [FINALISATION] Email envoyé à $emailAgent pour contrat ${contratQuery.docs.first.id}');
                } else {
                  print('⚠️ [FINALISATION] Email agent non trouvé pour agent $agentId');
                }
              } else {
                print('⚠️ [FINALISATION] Agent $agentId non trouvé');
              }
            } else {
              print('⚠️ [FINALISATION] AgentId non défini pour le contrat');
            }
          } else {
            print('⚠️ [FINALISATION] Contrat non trouvé pour police $numeroPolice et immatriculation $immatriculation');
          }
        } else {
          print('⚠️ [FINALISATION] Données manquantes: immatriculation=$immatriculation, numeroPolice=$numeroPolice');
        }
      }
    } catch (e) {
      print('❌ [FINALISATION] Erreur envoi emails: $e');
    }
  }

  /// 📧 Envoyer un email à un agent spécifique
  static Future<void> _envoyerEmailAgent(String emailAgent, String sessionId, Map<String, dynamic> participantData, String pdfUrl, String contratId) async {
    try {
      // Créer une notification dans Firestore pour déclencher l'envoi d'email
      await _firestore.collection('notifications_agents').add({
        'destinataire': emailAgent,
        'type': 'constat_finalise',
        'sessionId': sessionId,
        'contratId': contratId,
        'participantData': participantData,
        'pdfUrl': pdfUrl,
        'dateCreation': Timestamp.fromDate(DateTime.now()),
        'statut': 'en_attente',
        'objet': 'Nouveau constat d\'accident finalisé - Contrat $contratId',
        'message': 'Un nouveau constat d\'accident a été finalisé pour un véhicule sous votre gestion. Le PDF du constat est disponible en pièce jointe.',
      });

      print('✅ [FINALISATION] Notification créée pour $emailAgent');
    } catch (e) {
      print('❌ [FINALISATION] Erreur création notification: $e');
    }
  }

  /// 🐛 Déboguer les signatures d'une session
  static Future<void> debuggerSignatures(String sessionId) async {
    try {
      print('🔍 [DEBUG] === DÉBUT DEBUG SIGNATURES POUR SESSION $sessionId ===');

      // 1. Récupérer les données de la session
      final sessionDoc = await _firestore.collection(_sessionsCollection).doc(sessionId).get();
      if (!sessionDoc.exists) {
        print('❌ [DEBUG] Session non trouvée');
        return;
      }

      final sessionData = sessionDoc.data()!;
      final participants = List<Map<String, dynamic>>.from(sessionData['participants'] ?? []);
      final nombreVehicules = sessionData['nombreVehicules'] ?? 2;

      print('🔍 [DEBUG] Nombre de véhicules: $nombreVehicules');
      print('🔍 [DEBUG] Nombre de participants: ${participants.length}');

      // 2. Analyser chaque participant
      for (int i = 0; i < participants.length; i++) {
        final participant = participants[i];
        final statut = participant['statut'] as String?;
        final aSigne = participant['aSigne'] as bool? ?? false;
        final userId = participant['userId'] as String?;
        final nom = participant['nom'] as String? ?? 'Inconnu';

        print('🔍 [DEBUG] Participant $i: $nom (ID: $userId)');
        print('   - Statut: $statut');
        print('   - A signé: $aSigne');
      }

      // 3. Vérifier la sous-collection signatures
      final signaturesSnapshot = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection('signatures')
          .get();

      print('🔍 [DEBUG] Signatures dans sous-collection: ${signaturesSnapshot.docs.length}');
      for (final doc in signaturesSnapshot.docs) {
        final data = doc.data();
        print('   - Signature ID: ${doc.id}');
        print('   - Données: $data');
      }

      // 4. Calculer la progression
      final progression = await _calculerProgression(participants, sessionId);
      print('🔍 [DEBUG] Progression calculée:');
      print('   - Participants rejoints: ${progression.participantsRejoints}');
      print('   - Formulaires terminés: ${progression.formulairesTermines}');
      print('   - Croquis validés: ${progression.croquisValides}');
      print('   - Signatures effectuées: ${progression.signaturesEffectuees}');
      print('   - Peut finaliser: ${progression.peutFinaliser}');

      print('🔍 [DEBUG] === FIN DEBUG SIGNATURES ===');
    } catch (e) {
      print('❌ [DEBUG] Erreur debug signatures: $e');
    }
  }

  /// 🔍 Vérifier et corriger les statuts des participants
  static Future<void> verifierEtCorrigerStatuts(String sessionId) async {
    try {
      print('🔍 [VERIFICATION] Début vérification statuts pour session $sessionId');

      final sessionDoc = await _firestore.collection(_sessionsCollection).doc(sessionId).get();
      if (!sessionDoc.exists) {
        print('❌ [VERIFICATION] Session non trouvée');
        return;
      }

      final sessionData = sessionDoc.data()!;
      final participants = List<Map<String, dynamic>>.from(sessionData['participants'] ?? []);
      bool misAJour = false;

      for (int i = 0; i < participants.length; i++) {
        final participant = participants[i];
        final userId = participant['userId'] as String;
        final statutActuel = participant['statut'] as String? ?? 'en_attente';

        // Vérifier si le participant a un formulaire terminé
        final formulaireDoc = await _firestore
            .collection(_sessionsCollection)
            .doc(sessionId)
            .collection('formulaires')
            .doc(userId)
            .get();

        if (formulaireDoc.exists && formulaireDoc.data()?['complete'] == true) {
          if (statutActuel == 'rejoint' || statutActuel == 'en_attente') {
            print('🔧 [VERIFICATION] Correction statut $userId: $statutActuel → formulaire_fini');
            participants[i]['statut'] = 'formulaire_fini';
            participants[i]['dateFormulaireFini'] = Timestamp.fromDate(DateTime.now());
            misAJour = true;
          }
        }
      }

      if (misAJour) {
        print('🔄 [VERIFICATION] Mise à jour des statuts corrigés');
        final progression = await _calculerProgression(participants, sessionId);
        final nouveauStatutSession = _determinerStatutSession(participants, progression);

        await _firestore.collection(_sessionsCollection).doc(sessionId).update({
          'participants': participants,
          'progression': progression.toMap(),
          'statut': nouveauStatutSession.name,
          'dateModification': Timestamp.fromDate(DateTime.now()),
        });
        print('✅ [VERIFICATION] Statuts corrigés avec succès');
      } else {
        print('✅ [VERIFICATION] Aucune correction nécessaire');
      }
    } catch (e) {
      print('❌ [VERIFICATION] Erreur: $e');
    }
  }

  /// 🔄 Forcer la mise à jour de la progression des signatures
  static Future<void> forcerMiseAJourProgressionSignatures(String sessionId) async {
    try {
      print('🔄 [FORCE-UPDATE] Début mise à jour forcée progression signatures');

      final sessionDoc = await _firestore.collection(_sessionsCollection).doc(sessionId).get();
      if (!sessionDoc.exists) {
        print('❌ [FORCE-UPDATE] Session non trouvée');
        return;
      }

      final sessionData = sessionDoc.data()!;
      final participants = List<Map<String, dynamic>>.from(sessionData['participants'] ?? []);

      // Compter les signatures réelles depuis la sous-collection
      final signaturesSnapshot = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection('signatures')
          .get();

      final signaturesReelles = signaturesSnapshot.docs.length;
      print('🔍 [FORCE-UPDATE] Signatures réelles trouvées: $signaturesReelles');

      // Mettre à jour les statuts des participants selon les signatures
      bool participantsMisAJour = false;
      for (int i = 0; i < participants.length; i++) {
        final userId = participants[i]['userId'] as String?;
        if (userId != null) {
          final signatureDoc = await _firestore
              .collection(_sessionsCollection)
              .doc(sessionId)
              .collection('signatures')
              .doc(userId)
              .get();

          if (signatureDoc.exists) {
            if (participants[i]['statut'] != 'signe') {
              participants[i]['statut'] = 'signe';
              participantsMisAJour = true;
              print('🔄 [FORCE-UPDATE] Statut mis à jour pour $userId: signe');
            }
            if (participants[i]['aSigne'] != true) {
              participants[i]['aSigne'] = true;
              participantsMisAJour = true;
              print('🔄 [FORCE-UPDATE] aSigne mis à jour pour $userId: true');
            }
          }
        }
      }

      // Recalculer la progression avec le comptage correct
      final progression = await _calculerProgression(participants, sessionId);
      final nouveauStatutSession = _determinerStatutSession(participants, progression);

      print('🔍 [FORCE-UPDATE] Nouvelle progression: ${progression.signaturesEffectuees}/${participants.length}');

      // Mettre à jour la session
      await _firestore.collection(_sessionsCollection).doc(sessionId).update({
        'participants': participants,
        'progression': progression.toMap(),
        'statut': nouveauStatutSession.name,
        'dateModification': Timestamp.fromDate(DateTime.now()),
      });

      print('✅ [FORCE-UPDATE] Progression signatures mise à jour avec succès');

    } catch (e) {
      print('❌ [FORCE-UPDATE] Erreur: $e');
      rethrow;
    }
  }

  /// 🔧 Forcer la recalculation complète du statut de session
  static Future<void> forcerRecalculStatutSession(String sessionId) async {
    try {
      print('🔧 [RECALCUL-STATUT] Début recalcul statut pour session $sessionId');

      final sessionDoc = await _firestore.collection(_sessionsCollection).doc(sessionId).get();
      if (!sessionDoc.exists) {
        print('❌ [RECALCUL-STATUT] Session non trouvée');
        return;
      }

      final sessionData = sessionDoc.data()!;
      final participants = List<Map<String, dynamic>>.from(sessionData['participants'] ?? []);

      print('🔍 [RECALCUL-STATUT] Participants trouvés: ${participants.length}');

      // Recalculer la progression avec la nouvelle logique
      final progression = await _calculerProgression(participants, sessionId);
      final nouveauStatutSession = _determinerStatutSession(participants, progression);

      print('🔍 [RECALCUL-STATUT] Ancienne progression: ${sessionData['progression']}');
      print('🔍 [RECALCUL-STATUT] Nouvelle progression: ${progression.toMap()}');
      print('🔍 [RECALCUL-STATUT] Ancien statut: ${sessionData['statut']}');
      print('🔍 [RECALCUL-STATUT] Nouveau statut: ${nouveauStatutSession.name}');

      // Mettre à jour la session avec le nouveau statut
      await _firestore.collection(_sessionsCollection).doc(sessionId).update({
        'progression': progression.toMap(),
        'statut': nouveauStatutSession.name,
        'dateModification': Timestamp.fromDate(DateTime.now()),
      });

      print('✅ [RECALCUL-STATUT] Statut session recalculé avec succès');
      print('✅ [RECALCUL-STATUT] Nouveau statut: ${nouveauStatutSession.name}');

    } catch (e) {
      print('❌ [RECALCUL-STATUT] Erreur: $e');
      rethrow;
    }
  }

  /// 🚨 CORRECTION DIRECTE - Méthode pour corriger immédiatement le problème de statut
  static Future<void> corrigerStatutSessionProblematique() async {
    try {
      print('🚨 CORRECTION DIRECTE - Recherche des sessions problématiques...');

      // Rechercher les sessions avec statut "finalise" mais progression incomplète
      final sessionsQuery = await _firestore
          .collection(_sessionsCollection)
          .where('statut', isEqualTo: 'finalise')
          .get();

      print('🔍 Sessions "finalisées" trouvées: ${sessionsQuery.docs.length}');

      for (final sessionDoc in sessionsQuery.docs) {
        final sessionData = sessionDoc.data();
        final sessionId = sessionDoc.id;
        final participants = List<Map<String, dynamic>>.from(sessionData['participants'] ?? []);

        print('\n📋 Analyse session: $sessionId');
        print('   • Participants: ${participants.length}');

        // Calculer la vraie progression
        final progression = await _calculerProgression(participants, sessionId);
        final total = participants.length;

        // Vérifier si la session est vraiment finalisée
        final vraimementFinalisee = progression.formulairesTermines == total &&
                                   progression.croquisValides == total &&
                                   progression.signaturesEffectuees == total &&
                                   total > 0;

        print('   • Formulaires: ${progression.formulairesTermines}/$total');
        print('   • Croquis: ${progression.croquisValides}/$total');
        print('   • Signatures: ${progression.signaturesEffectuees}/$total');
        print('   • Vraiment finalisée? ${vraimementFinalisee ? "✅ Oui" : "❌ Non"}');

        if (!vraimementFinalisee) {
          // Cette session a un statut incorrect, la corriger
          final nouveauStatut = _determinerStatutSession(participants, progression);

          print('   🔧 CORRECTION NÉCESSAIRE:');
          print('      • Ancien statut: finalise ❌');
          print('      • Nouveau statut: ${nouveauStatut.name} ✅');

          // Mettre à jour le statut et la progression
          await _firestore.collection(_sessionsCollection).doc(sessionId).update({
            'statut': nouveauStatut.name,
            'progression': progression.toMap(),
            'dateModification': Timestamp.fromDate(DateTime.now()),
            'correctionAppliquee': true,
            'correctionDate': Timestamp.fromDate(DateTime.now()),
          });

          print('   ✅ Session corrigée avec succès!');
        } else {
          print('   ✅ Session correctement finalisée, aucune correction nécessaire');
        }
      }

      print('\n🎉 CORRECTION DIRECTE TERMINÉE!');
      print('   Toutes les sessions problématiques ont été corrigées.');

    } catch (e) {
      print('❌ Erreur lors de la correction directe: $e');
      rethrow;
    }
  }

  /// 🔧 Méthodes utilitaires privées
  static Future<SessionProgress> _calculerProgression(List<Map<String, dynamic>> participants, [String? sessionId]) async {
    int participantsRejoints = 0;
    int formulairesTermines = 0;
    int croquisValides = 0;
    int signaturesEffectuees = 0;

    print('🔍 [PROGRESSION] ===== CALCUL PROGRESSION DÉTAILLÉ =====');

    for (final participant in participants) {
      final statut = participant['statut'] as String?;
      final aSigne = participant['aSigne'] as bool? ?? false;
      final formulaireStatus = participant['formulaireStatus'] as String?;
      final formulaireComplete = participant['formulaireComplete'] as bool? ?? false;
      final userId = participant['userId'] as String? ?? 'inconnu';

      print('🔍 [PROGRESSION] Participant $userId:');
      print('   - statut: $statut');
      print('   - formulaireStatus: $formulaireStatus');
      print('   - formulaireComplete: $formulaireComplete');
      print('   - aSigne: $aSigne');

      if (statut != null && statut != 'en_attente') {
        participantsRejoints++;
      }

      // 🔥 CORRECTION: Utiliser formulaireStatus et formulaireComplete pour déterminer si terminé
      if (formulaireStatus == 'termine' || formulaireComplete == true || statut == 'formulaire_fini') {
        formulairesTermines++;
        print('   ✅ Formulaire terminé');
      } else {
        print('   ❌ Formulaire non terminé');
      }

      // 🔥 CORRECTION: Si le participant a signé, cela implique qu'il a validé le croquis
      if (statut == 'croquis_valide' || statut == 'signe' || (statut == 'formulaire_fini' && aSigne)) {
        croquisValides++;
        print('   ✅ Croquis validé (statut: $statut, aSigne: $aSigne)');
      } else {
        print('   ❌ Croquis non validé (statut: $statut, aSigne: $aSigne)');
      }

      // Compter les signatures depuis le statut OU le champ aSigne
      if (statut == 'signe' || aSigne) {
        signaturesEffectuees++;
        print('   ✅ Signature effectuée');
      } else {
        print('   ❌ Signature non effectuée');
      }
    }

    print('🔍 [PROGRESSION] RÉSULTATS:');
    print('   - Participants rejoints: $participantsRejoints/${participants.length}');
    print('   - Formulaires terminés: $formulairesTermines/${participants.length}');
    print('   - Croquis validés: $croquisValides/${participants.length}');
    print('   - Signatures effectuées: $signaturesEffectuees/${participants.length}');

    // 🔥 CORRECTION: Compter aussi depuis la sous-collection signatures si sessionId fourni
    if (sessionId != null) {
      try {
        final signaturesSnapshot = await _firestore
            .collection(_sessionsCollection)
            .doc(sessionId)
            .collection('signatures')
            .get();

        final signaturesEnSousCollection = signaturesSnapshot.docs.length;

        // Utiliser le maximum entre les deux méthodes de comptage
        signaturesEffectuees = math.max(signaturesEffectuees, signaturesEnSousCollection);

        print('🔍 [PROGRESSION] Signatures depuis statuts: ${signaturesEffectuees - signaturesEnSousCollection + signaturesEffectuees}');
        print('🔍 [PROGRESSION] Signatures depuis sous-collection: $signaturesEnSousCollection');
        print('🔍 [PROGRESSION] Signatures finales: $signaturesEffectuees');
      } catch (e) {
        print('❌ [PROGRESSION] Erreur comptage signatures: $e');
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

    print('🔍 [STATUT] ===== CALCUL STATUT SESSION =====');
    print('🔍 [STATUT] Total participants: $total');
    print('🔍 [STATUT] Formulaires terminés: ${progression.formulairesTermines}/$total');
    print('🔍 [STATUT] Croquis validés: ${progression.croquisValides}/$total');
    print('🔍 [STATUT] Signatures effectuées: ${progression.signaturesEffectuees}/$total');

    // 🔥 CORRECTION: Vérifier si TOUT est terminé avant de finaliser
    if (progression.formulairesTermines == total &&
        progression.croquisValides == total &&
        progression.signaturesEffectuees == total &&
        total > 0) {
      print('✅ [STATUT] TOUTES CONDITIONS REMPLIES → finalise');
      print('✅ [STATUT] Détail: formulaires(${progression.formulairesTermines}/$total), croquis(${progression.croquisValides}/$total), signatures(${progression.signaturesEffectuees}/$total)');
      return SessionStatus.finalise;
    }
    // Vérifier si tous ont signé (mais pas tout terminé)
    else if (progression.signaturesEffectuees == total && total > 0) {
      print('🔄 [STATUT] SIGNATURES COMPLÈTES mais session incomplète');
      print('🔄 [STATUT] Manque: formulaires(${progression.formulairesTermines}/$total), croquis(${progression.croquisValides}/$total)');
      print('🔄 [STATUT] Résultat: signe (pas finalise)');
      return SessionStatus.signe; // Garder statut "signé" jusqu'à finalisation complète
    }
    // Vérifier si tous ont validé le croquis
    else if (progression.croquisValides == total && total > 0) {
      print('🔄 [STATUT] CROQUIS VALIDÉS → pret_signature');
      return SessionStatus.pret_signature;
    }
    // Vérifier si tous ont terminé leur formulaire
    else if (progression.formulairesTermines == total && total > 0) {
      print('🔄 [STATUT] FORMULAIRES TERMINÉS → validation_croquis');
      return SessionStatus.validation_croquis;
    }
    // Vérifier si tous ont rejoint
    else if (progression.participantsRejoints == total && total > 0) {
      print('🔄 [STATUT] PARTICIPANTS REJOINTS → en_cours');
      return SessionStatus.en_cours;
    }
    // Quelques participants ont rejoint
    else if (progression.participantsRejoints > 0) {
      print('🔄 [STATUT] QUELQUES PARTICIPANTS REJOINTS → attente_participants');
      print('🔄 [STATUT] Rejoints: ${progression.participantsRejoints}/$total');
      return SessionStatus.attente_participants;
    }
    // Aucun participant
    else {
      print('🔄 [STATUT] AUCUN PARTICIPANT → creation');
      return SessionStatus.creation;
    }
  }

  static String _genererCodeSession() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = math.Random();
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

        // Conversion sécurisée pour éviter les erreurs de cast
        final userIdParticipantStr = userId_participant?.toString() ?? '';
        final userIdStr = userId.toString();

        if (userIdParticipantStr == userIdStr) {
          participants[i]['formulaireStatus'] = nouvelEtat.name;
          participants[i]['formulaireComplete'] = nouvelEtat == FormulaireStatus.termine;

          // Mettre à jour les dates selon l'état
          if (nouvelEtat == FormulaireStatus.termine) {
            participants[i]['dateFormulaireFini'] = DateTime.now().toIso8601String();
            participants[i]['statut'] = ParticipantStatus.formulaire_fini.name; // 🔥 Utiliser l'enum correct
            print('✅ [STATUT] Participant ${participants[i]['nom']} ${participants[i]['prenom']} marqué comme FORMULAIRE_FINI');
          } else if (nouvelEtat == FormulaireStatus.en_cours) {
            participants[i]['statut'] = ParticipantStatus.rejoint.name; // 🔥 Utiliser l'enum correct
            print('✅ [STATUT] Participant ${participants[i]['nom']} ${participants[i]['prenom']} marqué comme REJOINT');
          }

          print('🔍 [DEBUG] Statut final du participant: ${participants[i]['statut']}');

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
