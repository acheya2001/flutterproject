import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/accident_session.dart';
import '../../../models/participant.dart';
import '../../../models/constat.dart';
import '../../../models/notification_sinistre.dart';

/// Service pour gérer les sessions d'accident et constats
class AccidentSessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Crée une nouvelle session d'accident
  Future<String> createSession(AccidentSession session) async {
    try {
      final docRef = await _firestore.collection('accident_sessions').add(session.toFirestore());
      
      // Log de création
      await _logAction(docRef.id, 'session_created', {
        'createurUserId': session.createurUserId,
        'codePublic': session.codePublic,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la session: $e');
    }
  }

  /// Met à jour une session d'accident
  Future<void> updateSession(String sessionId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('accident_sessions').doc(sessionId).update({
        ...updates,
        'dateModification': FieldValue.serverTimestamp(),
      });

      // Log de modification
      await _logAction(sessionId, 'session_updated', updates);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la session: $e');
    }
  }

  /// Récupère une session par son ID
  Future<AccidentSession?> getSession(String sessionId) async {
    try {
      final doc = await _firestore.collection('accident_sessions').doc(sessionId).get();
      if (doc.exists) {
        return AccidentSession.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la session: $e');
    }
  }

  /// Récupère une session par son code public
  Future<AccidentSession?> getSessionByCode(String codePublic) async {
    try {
      final query = await _firestore
          .collection('accident_sessions')
          .where('codePublic', isEqualTo: codePublic)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return AccidentSession.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la session: $e');
    }
  }

  /// Récupère les sessions d'un utilisateur
  Future<List<AccidentSession>> getUserSessions(String userId) async {
    try {
      final query = await _firestore
          .collection('accident_sessions')
          .where('createurUserId', isEqualTo: userId)
          .orderBy('dateCreation', descending: true)
          .get();

      return query.docs.map((doc) => AccidentSession.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des sessions: $e');
    }
  }

  /// Ajoute un participant à une session
  Future<String> addParticipant(Participant participant) async {
    try {
      final docRef = await _firestore.collection('participants').add(participant.toFirestore());
      
      // Mettre à jour le statut de la session si nécessaire
      await _updateSessionStatus(participant.sessionId);

      // Log d'ajout de participant
      await _logAction(participant.sessionId, 'participant_added', {
        'participantId': docRef.id,
        'role': participant.role,
        'isRegistered': participant.isRegistered,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du participant: $e');
    }
  }

  /// Met à jour un participant
  Future<void> updateParticipant(String participantId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('participants').doc(participantId).update({
        ...updates,
        'dateModification': FieldValue.serverTimestamp(),
      });

      // Récupérer le participant pour obtenir le sessionId
      final participantDoc = await _firestore.collection('participants').doc(participantId).get();
      if (participantDoc.exists) {
        final sessionId = participantDoc.data()!['sessionId'];
        await _updateSessionStatus(sessionId);

        // Log de modification
        await _logAction(sessionId, 'participant_updated', {
          'participantId': participantId,
          ...updates,
        });
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du participant: $e');
    }
  }

  /// Récupère les participants d'une session
  Future<List<Participant>> getSessionParticipants(String sessionId) async {
    try {
      final query = await _firestore
          .collection('participants')
          .where('sessionId', isEqualTo: sessionId)
          .orderBy('role')
          .get();

      return query.docs.map((doc) => Participant.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des participants: $e');
    }
  }

  /// Crée une invitation pour rejoindre une session
  Future<Invitation> createInvitation(String sessionId, String role) async {
    try {
      final invitation = Invitation(
        id: '',
        sessionId: sessionId,
        rolePropose: role,
        urlToken: Invitation.generateToken(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      final docRef = await _firestore.collection('invitations').add(invitation.toFirestore());
      
      // Log de création d'invitation
      await _logAction(sessionId, 'invitation_created', {
        'invitationId': docRef.id,
        'role': role,
        'token': invitation.urlToken,
      });

      return invitation.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'invitation: $e');
    }
  }

  /// Récupère une invitation par son token
  Future<Invitation?> getInvitationByToken(String token) async {
    try {
      final query = await _firestore
          .collection('invitations')
          .where('urlToken', isEqualTo: token)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return Invitation.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'invitation: $e');
    }
  }

  /// Marque une invitation comme utilisée
  Future<void> useInvitation(String invitationId, String? userId) async {
    try {
      await _firestore.collection('invitations').doc(invitationId).update({
        'joinedAt': FieldValue.serverTimestamp(),
        'joinedByUserId': userId,
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'utilisation de l\'invitation: $e');
    }
  }

  /// Signe un participant (signature électronique)
  Future<void> signParticipant(String participantId, Map<String, dynamic> signatureData) async {
    try {
      await _firestore.collection('participants').doc(participantId).update({
        'signature': signatureData,
        'statutPartie': Participant.STATUT_SIGNE,
        'dateModification': FieldValue.serverTimestamp(),
      });

      // Récupérer le participant pour obtenir le sessionId
      final participantDoc = await _firestore.collection('participants').doc(participantId).get();
      if (participantDoc.exists) {
        final sessionId = participantDoc.data()!['sessionId'];
        await _updateSessionStatus(sessionId);

        // Log de signature
        await _logAction(sessionId, 'participant_signed', {
          'participantId': participantId,
          'signatureTimestamp': signatureData['timestamp'],
        });
      }
    } catch (e) {
      throw Exception('Erreur lors de la signature: $e');
    }
  }

  /// Met à jour automatiquement le statut d'une session selon l'état des participants
  Future<void> _updateSessionStatus(String sessionId) async {
    try {
      final session = await getSession(sessionId);
      if (session == null) return;

      final participants = await getSessionParticipants(sessionId);
      
      String newStatus = session.statut;

      // Logique de mise à jour du statut
      if (participants.isEmpty) {
        newStatus = AccidentSession.STATUT_BROUILLON;
      } else if (participants.any((p) => p.statutPartie == Participant.STATUT_EN_SAISIE)) {
        newStatus = AccidentSession.STATUT_PARTIES_EN_SAISIE;
      } else if (participants.every((p) => p.isComplete && p.statutPartie != Participant.STATUT_SIGNE)) {
        newStatus = AccidentSession.STATUT_PRET_A_SIGNER;
      } else if (participants.any((p) => p.statutPartie == Participant.STATUT_SIGNE) &&
                 participants.any((p) => p.statutPartie != Participant.STATUT_SIGNE)) {
        newStatus = AccidentSession.STATUT_SIGNATURE_EN_COURS;
      } else if (participants.every((p) => p.statutPartie == Participant.STATUT_SIGNE)) {
        newStatus = AccidentSession.STATUT_SIGNE_VALIDE;
      }

      if (newStatus != session.statut) {
        await updateSession(sessionId, {'statut': newStatus});
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du statut: $e');
    }
  }

  /// Envoie une notification
  Future<void> sendNotification(NotificationSinistre notification) async {
    try {
      await _firestore.collection('notifications_sinistre').add(notification.toFirestore());
      
      // TODO: Implémenter l'envoi réel (push, email, SMS)
      
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de la notification: $e');
    }
  }

  /// Log d'une action pour audit
  Future<void> _logAction(String sessionId, String action, Map<String, dynamic> details) async {
    try {
      await _firestore.collection('audit_logs').add({
        'sessionId': sessionId,
        'action': action,
        'details': details,
        'userId': _auth.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'ip': null, // TODO: Récupérer l'IP si nécessaire
        'userAgent': null, // TODO: Récupérer le user agent si nécessaire
      });
    } catch (e) {
      print('Erreur lors du log d\'audit: $e');
    }
  }

  /// Vérifie si une session est dans les délais légaux
  bool isSessionInLegalDeadline(AccidentSession session) {
    return session.isInLegalDeadline;
  }

  /// Calcule les jours restants avant expiration
  int getDaysUntilDeadline(AccidentSession session) {
    return session.deadlineDeclaration.difference(DateTime.now()).inDays;
  }

  /// Récupère les sessions expirant bientôt (pour notifications)
  Future<List<AccidentSession>> getExpiringSessions() async {
    try {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final query = await _firestore
          .collection('accident_sessions')
          .where('deadlineDeclaration', isLessThanOrEqualTo: Timestamp.fromDate(tomorrow))
          .where('statut', whereIn: [
            AccidentSession.STATUT_BROUILLON,
            AccidentSession.STATUT_EN_ATTENTE_INVITES,
            AccidentSession.STATUT_PARTIES_EN_SAISIE,
          ])
          .get();

      return query.docs.map((doc) => AccidentSession.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des sessions expirant: $e');
    }
  }
}
