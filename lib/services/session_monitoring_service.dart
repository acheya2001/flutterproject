import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/accident_session.dart';
import 'email_notification_service.dart';

/// ⏰ Service de surveillance et relance automatique des sessions
class SessionMonitoringService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// 🔄 Vérifier toutes les sessions en cours et envoyer des relances
  static Future<void> verifierSessionsEnCours() async {
    try {
      final maintenant = DateTime.now();
      
      // Récupérer toutes les sessions actives
      final sessionsQuery = await _firestore
          .collection('accident_sessions')
          .where('statut', whereIn: [
            AccidentSession.STATUT_BROUILLON,
            AccidentSession.STATUT_EN_COURS,
          ])
          .get();

      for (final sessionDoc in sessionsQuery.docs) {
        final session = AccidentSession.fromFirestore(sessionDoc);
        await _traiterSession(session, maintenant);
      }

    } catch (e) {
      print('❌ Erreur monitoring sessions: $e');
    }
  }

  /// 📋 Traiter une session individuelle
  static Future<void> _traiterSession(AccidentSession session, DateTime maintenant) async {
    final tempsEcoule = maintenant.difference(session.dateCreation);
    final deadline = session.deadlineDeclaration;

    // Vérifier expiration
    if (maintenant.isAfter(deadline)) {
      await _gererExpiration(session);
      return;
    }

    // Calculer les seuils de relance
    final dureeTotal = deadline.difference(session.dateCreation);
    final seuil24h = session.dateCreation.add(Duration(hours: 24));
    final seuil48h = session.dateCreation.add(Duration(hours: 48));
    final seuil12hAvantExpiration = deadline.subtract(Duration(hours: 12));

    // Envoyer relances selon les seuils
    if (maintenant.isAfter(seuil24h) && !session.relance24hEnvoyee) {
      await _envoyerRelance(session, 'relance_24h');
    }
    
    if (maintenant.isAfter(seuil48h) && !session.relance48hEnvoyee) {
      await _envoyerRelance(session, 'relance_48h');
    }
    
    if (maintenant.isAfter(seuil12hAvantExpiration) && !session.relanceUrgenceEnvoyee) {
      await _envoyerRelance(session, 'relance_urgence');
    }
  }

  /// 📧 Envoyer une relance aux participants non terminés
  static Future<void> _envoyerRelance(AccidentSession session, String typeRelance) async {
    try {
      // Identifier les participants qui n'ont pas terminé
      final participantsNonTermines = <String>[];
      
      for (final role in session.rolesDisponibles) {
        if (role == 'A') continue; // Le créateur a déjà rempli sa partie
        
        final identite = session.identitesVehicules[role];
        final signature = session.signatures[role];
        
        if (identite == null || signature == null) {
          participantsNonTermines.add(role);
        }
      }

      if (participantsNonTermines.isEmpty) return;

      // Envoyer notifications selon le type
      for (final role in participantsNonTermines) {
        await _envoyerNotificationRelance(session, role, typeRelance);
      }

      // Marquer la relance comme envoyée
      await _marquerRelanceEnvoyee(session.id, typeRelance);

    } catch (e) {
      print('❌ Erreur envoi relance: $e');
    }
  }

  /// 📱 Envoyer notification de relance à un participant
  static Future<void> _envoyerNotificationRelance(
    AccidentSession session,
    String role,
    String typeRelance,
  ) async {
    final urgence = typeRelance == 'relance_urgence';
    final heuresRestantes = session.deadlineDeclaration.difference(DateTime.now()).inHours;

    // Message selon le type de relance
    String titre;
    String message;
    
    switch (typeRelance) {
      case 'relance_24h':
        titre = '⏰ Constat en attente';
        message = 'Votre partie du constat ${session.codePublic} n\'est pas encore complétée. '
                 'Vous avez encore ${heuresRestantes}h pour la finaliser.';
        break;
      case 'relance_48h':
        titre = '⚠️ Constat urgent';
        message = 'URGENT: Votre partie du constat ${session.codePublic} doit être complétée. '
                 'Il ne reste que ${heuresRestantes}h avant expiration.';
        break;
      case 'relance_urgence':
        titre = '🚨 DERNIÈRE CHANCE';
        message = 'DERNIÈRE CHANCE: Le constat ${session.codePublic} expire dans ${heuresRestantes}h. '
                 'Complétez votre partie maintenant ou elle sera archivée.';
        break;
      default:
        return;
    }

    // 1. Notification push (si utilisateur inscrit)
    await _envoyerNotificationPush(session, role, titre, message, urgence);

    // 2. Email de relance
    await _envoyerEmailRelance(session, role, typeRelance, heuresRestantes);

    // 3. SMS si urgence
    if (urgence) {
      await _envoyerSMSUrgence(session, role, heuresRestantes);
    }
  }

  /// 📱 Envoyer notification push
  static Future<void> _envoyerNotificationPush(
    AccidentSession session,
    String role,
    String titre,
    String message,
    bool urgence,
  ) async {
    try {
      // Chercher l'utilisateur associé à ce rôle
      final participantQuery = await _firestore
          .collection('session_participants')
          .where('sessionId', isEqualTo: session.id)
          .where('role', isEqualTo: role)
          .limit(1)
          .get();

      if (participantQuery.docs.isEmpty) return;

      final participantData = participantQuery.docs.first.data();
      final userId = participantData['userId'];
      
      if (userId == null) return; // Participant non inscrit

      // Récupérer le token FCM
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'];
      
      if (fcmToken == null) return;

      // Envoyer la notification
      // TODO: Implémenter l'envoi FCM avec Firebase Admin SDK
      print('📱 Notification push envoyée: $titre');

    } catch (e) {
      print('❌ Erreur notification push: $e');
    }
  }

  /// 📧 Envoyer email de relance
  static Future<void> _envoyerEmailRelance(
    AccidentSession session,
    String role,
    String typeRelance,
    int heuresRestantes,
  ) async {
    try {
      // Récupérer l'email du participant
      final email = await _obtenirEmailParticipant(session, role);
      if (email == null) return;

      await EmailNotificationService.envoyerRelanceConstat(
        destinataire: email,
        codeConstat: session.codePublic,
        vehiculeRole: role,
        heuresRestantes: heuresRestantes,
        typeRelance: typeRelance,
      );

    } catch (e) {
      print('❌ Erreur email relance: $e');
    }
  }

  /// 📱 Envoyer SMS d'urgence
  static Future<void> _envoyerSMSUrgence(
    AccidentSession session,
    String role,
    int heuresRestantes,
  ) async {
    try {
      // Récupérer le téléphone du participant
      final telephone = await _obtenirTelephoneParticipant(session, role);
      if (telephone == null) return;

      final message = '🚨 URGENT: Constat ${session.codePublic} expire dans ${heuresRestantes}h. '
                     'Complétez votre partie maintenant: [LIEN_APP]';

      // TODO: Implémenter l'envoi SMS via service externe
      print('📱 SMS urgence envoyé à $telephone: $message');

    } catch (e) {
      print('❌ Erreur SMS urgence: $e');
    }
  }

  /// ⏰ Gérer l'expiration d'une session
  static Future<void> _gererExpiration(AccidentSession session) async {
    try {
      // Marquer comme expirée
      await _firestore.collection('accident_sessions').doc(session.id).update({
        'statut': AccidentSession.STATUT_EXPIRE,
        'dateExpiration': Timestamp.now(),
        'raisonExpiration': 'delai_depasse',
      });

      // Archiver la session
      await _archiverSession(session);

      // Notifier tous les participants
      await _notifierExpiration(session);

      print('⏰ Session ${session.codePublic} expirée et archivée');

    } catch (e) {
      print('❌ Erreur gestion expiration: $e');
    }
  }

  /// 📦 Archiver une session expirée
  static Future<void> _archiverSession(AccidentSession session) async {
    // Déplacer vers la collection d'archives
    await _firestore.collection('accident_sessions_archives').doc(session.id).set({
      ...session.toFirestore(),
      'dateArchivage': Timestamp.now(),
      'raisonArchivage': 'expiration_delai',
    });

    // Garder une référence dans la collection principale
    await _firestore.collection('accident_sessions').doc(session.id).update({
      'archive': true,
      'archiveRef': 'accident_sessions_archives/${session.id}',
    });
  }

  /// 📧 Notifier l'expiration à tous les participants
  static Future<void> _notifierExpiration(AccidentSession session) async {
    // Notifier le créateur
    await _notifierExpirationCreateur(session);

    // Notifier les participants non terminés
    for (final role in session.rolesDisponibles) {
      if (role == 'A') continue;
      
      final identite = session.identitesVehicules[role];
      if (identite == null) {
        await _notifierExpirationParticipant(session, role);
      }
    }
  }

  /// 📧 Notifier le créateur de l'expiration
  static Future<void> _notifierExpirationCreateur(AccidentSession session) async {
    try {
      final createurDoc = await _firestore.collection('users').doc(session.createurUserId).get();
      final email = createurDoc.data()?['email'];
      
      if (email != null) {
        await EmailNotificationService.envoyerNotificationExpiration(
          destinataire: email,
          codeConstat: session.codePublic,
          estCreateur: true,
        );
      }
    } catch (e) {
      print('❌ Erreur notification créateur: $e');
    }
  }

  /// 📧 Notifier un participant de l'expiration
  static Future<void> _notifierExpirationParticipant(AccidentSession session, String role) async {
    try {
      final email = await _obtenirEmailParticipant(session, role);
      if (email != null) {
        await EmailNotificationService.envoyerNotificationExpiration(
          destinataire: email,
          codeConstat: session.codePublic,
          estCreateur: false,
        );
      }
    } catch (e) {
      print('❌ Erreur notification participant: $e');
    }
  }

  /// ✅ Marquer une relance comme envoyée
  static Future<void> _marquerRelanceEnvoyee(String sessionId, String typeRelance) async {
    final Map<String, dynamic> updates = {};
    
    switch (typeRelance) {
      case 'relance_24h':
        updates['relance24hEnvoyee'] = true;
        updates['dateRelance24h'] = Timestamp.now();
        break;
      case 'relance_48h':
        updates['relance48hEnvoyee'] = true;
        updates['dateRelance48h'] = Timestamp.now();
        break;
      case 'relance_urgence':
        updates['relanceUrgenceEnvoyee'] = true;
        updates['dateRelanceUrgence'] = Timestamp.now();
        break;
    }

    await _firestore.collection('accident_sessions').doc(sessionId).update(updates);
  }

  /// 📧 Obtenir l'email d'un participant
  static Future<String?> _obtenirEmailParticipant(AccidentSession session, String role) async {
    // Chercher dans les participants de la session
    final participantQuery = await _firestore
        .collection('session_participants')
        .where('sessionId', isEqualTo: session.id)
        .where('role', isEqualTo: role)
        .limit(1)
        .get();

    if (participantQuery.docs.isNotEmpty) {
      return participantQuery.docs.first.data()['email'];
    }

    return null;
  }

  /// 📱 Obtenir le téléphone d'un participant
  static Future<String?> _obtenirTelephoneParticipant(AccidentSession session, String role) async {
    // Chercher dans les participants de la session
    final participantQuery = await _firestore
        .collection('session_participants')
        .where('sessionId', isEqualTo: session.id)
        .where('role', isEqualTo: role)
        .limit(1)
        .get();

    if (participantQuery.docs.isNotEmpty) {
      return participantQuery.docs.first.data()['telephone'];
    }

    return null;
  }

  /// 📊 Statistiques de monitoring
  static Future<Map<String, dynamic>> obtenirStatistiquesMonitoring() async {
    final maintenant = DateTime.now();
    
    // Sessions actives
    final activesQuery = await _firestore
        .collection('accident_sessions')
        .where('statut', whereIn: [
          AccidentSession.STATUT_BROUILLON,
          AccidentSession.STATUT_EN_COURS,
        ])
        .count()
        .get();

    // Sessions expirées aujourd'hui
    final debutJour = DateTime(maintenant.year, maintenant.month, maintenant.day);
    final expiresQuery = await _firestore
        .collection('accident_sessions')
        .where('statut', isEqualTo: AccidentSession.STATUT_EXPIRE)
        .where('dateExpiration', isGreaterThanOrEqualTo: Timestamp.fromDate(debutJour))
        .count()
        .get();

    // Sessions en retard (dépassé 48h sans finalisation)
    final seuil48h = maintenant.subtract(const Duration(hours: 48));
    final retardQuery = await _firestore
        .collection('accident_sessions')
        .where('statut', whereIn: [
          AccidentSession.STATUT_BROUILLON,
          AccidentSession.STATUT_EN_COURS,
        ])
        .where('dateCreation', isLessThan: Timestamp.fromDate(seuil48h))
        .count()
        .get();

    return {
      'sessions_actives': activesQuery.count,
      'sessions_expirees_aujourd_hui': expiresQuery.count,
      'sessions_en_retard': retardQuery.count,
      'derniere_verification': maintenant.toIso8601String(),
    };
  }
}
