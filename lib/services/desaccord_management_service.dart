import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/accident_session.dart';
import 'email_notification_service.dart';

/// ⚖️ Service de gestion des désaccords et refus de signature
class DesaccordManagementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🚫 Enregistrer un refus de signature
  static Future<void> enregistrerRefusSignature({
    required String sessionId,
    required String role,
    required String raisonRefus,
    required String commentaireConducteur,
    String? telephoneConducteur,
    String? emailConducteur,
  }) async {
    try {
      // 1. Enregistrer le refus dans la session
      await _firestore.collection('accident_sessions').doc(sessionId).update({
        'refus.$role': {
          'statut': 'refuse_signer',
          'raison': raisonRefus,
          'commentaire': commentaireConducteur,
          'dateRefus': Timestamp.now(),
          'telephone': telephoneConducteur,
          'email': emailConducteur,
        },
        'statut': AccidentSession.STATUT_DESACCORD,
        'dateModification': Timestamp.now(),
      });

      // 2. Créer un dossier de litige
      await _creerDossierLitige(sessionId, role, raisonRefus, commentaireConducteur);

      // 3. Notifier les autres parties
      await _notifierDesaccord(sessionId, role, raisonRefus);

      // 4. Logger l'événement
      await _loggerDesaccord(sessionId, role, 'refus_signature', raisonRefus);

    } catch (e) {
      print('Erreur enregistrement refus: $e');
      rethrow;
    }
  }

  /// 🤝 Enregistrer un désaccord sur le contenu
  static Future<void> enregistrerDesaccordContenu({
    required String sessionId,
    required String role,
    required String sectionContestee,
    required String versionProposee,
    required String justification,
  }) async {
    try {
      // 1. Enregistrer le désaccord
      await _firestore.collection('accident_sessions').doc(sessionId).update({
        'desaccords.$role': {
          'type': 'desaccord_contenu',
          'section_contestee': sectionContestee,
          'version_proposee': versionProposee,
          'justification': justification,
          'dateDesaccord': Timestamp.now(),
          'statut': 'en_attente_resolution',
        },
        'statut': AccidentSession.STATUT_DESACCORD,
        'dateModification': Timestamp.now(),
      });

      // 2. Créer une demande de médiation
      await _creerDemandeMeditation(sessionId, role, sectionContestee, versionProposee, justification);

      // 3. Notifier les parties concernées
      await _notifierDesaccordContenu(sessionId, role, sectionContestee);

      // 4. Logger l'événement
      await _loggerDesaccord(sessionId, role, 'desaccord_contenu', sectionContestee);

    } catch (e) {
      print('Erreur enregistrement désaccord: $e');
      rethrow;
    }
  }

  /// 📋 Créer un dossier de litige
  static Future<void> _creerDossierLitige(
    String sessionId,
    String role,
    String raison,
    String commentaire,
  ) async {
    await _firestore.collection('litiges').add({
      'sessionId': sessionId,
      'type': 'refus_signature',
      'vehiculeRefusant': role,
      'raison': raison,
      'commentaire': commentaire,
      'dateCreation': Timestamp.now(),
      'statut': 'ouvert',
      'priorite': _calculerPrioriteLitige(raison),
      'assigneA': null,
      'resolutionProposee': null,
      'dateResolution': null,
      'historique': [
        {
          'action': 'creation_litige',
          'date': Timestamp.now(),
          'details': 'Refus de signature du véhicule $role',
        }
      ],
    });
  }

  /// 🤝 Créer une demande de médiation
  static Future<void> _creerDemandeMeditation(
    String sessionId,
    String role,
    String section,
    String versionProposee,
    String justification,
  ) async {
    await _firestore.collection('mediations').add({
      'sessionId': sessionId,
      'type': 'desaccord_contenu',
      'vehiculeDemandeur': role,
      'sectionContestee': section,
      'versionProposee': versionProposee,
      'justification': justification,
      'dateCreation': Timestamp.now(),
      'statut': 'en_attente_mediateur',
      'mediateurAssigne': null,
      'propositionMediation': null,
      'accepteParties': {},
      'dateResolution': null,
    });
  }

  /// 📧 Notifier un désaccord aux autres parties
  static Future<void> _notifierDesaccord(String sessionId, String role, String raison) async {
    try {
      // Récupérer la session
      final sessionDoc = await _firestore.collection('accident_sessions').doc(sessionId).get();
      if (!sessionDoc.exists) return;

      final session = AccidentSession.fromFirestore(sessionDoc);

      // Notifier le créateur
      await _notifierCreateurDesaccord(session, role, raison);

      // Notifier les autres participants
      await _notifierAutresParticipants(session, role, raison);

      // Notifier les compagnies d'assurance
      await _notifierCompagniesDesaccord(session, role, raison);

    } catch (e) {
      print('Erreur notification désaccord: $e');
    }
  }

  /// 📧 Notifier le créateur du désaccord
  static Future<void> _notifierCreateurDesaccord(AccidentSession session, String role, String raison) async {
    try {
      final createurDoc = await _firestore.collection('users').doc(session.createurUserId).get();
      final email = createurDoc.data()?['email'];

      if (email != null) {
        await EmailNotificationService.envoyerNotificationDesaccord(
          destinataire: email,
          codeConstat: session.codePublic,
          vehiculeRefusant: role,
          raisonRefus: raison,
          estCreateur: true,
        );
      }
    } catch (e) {
      print('Erreur notification créateur: $e');
    }
  }

  /// 📧 Notifier les autres participants
  static Future<void> _notifierAutresParticipants(AccidentSession session, String roleRefusant, String raison) async {
    for (final role in session.rolesDisponibles) {
      if (role == roleRefusant) continue;

      try {
        // Récupérer l'email du participant
        final email = await _obtenirEmailParticipant(session.id, role);
        if (email != null) {
          await EmailNotificationService.envoyerNotificationDesaccord(
            destinataire: email,
            codeConstat: session.codePublic,
            vehiculeRefusant: roleRefusant,
            raisonRefus: raison,
            estCreateur: false,
          );
        }
      } catch (e) {
        print('Erreur notification participant $role: $e');
      }
    }
  }

  /// 📧 Notifier les compagnies d'assurance
  static Future<void> _notifierCompagniesDesaccord(AccidentSession session, String role, String raison) async {
    try {
      // Identifier toutes les compagnies impliquées
      for (final entry in session.identitesVehicules.entries) {
        final vehiculeRole = entry.key;
        final identite = entry.value;

        // Récupérer les infos de la compagnie
        final compagnieQuery = await _firestore
            .collection('compagnies_assurance')
            .where('nom', isEqualTo: identite.compagnieAssurance)
            .limit(1)
            .get();

        if (compagnieQuery.docs.isNotEmpty) {
          final compagnieData = compagnieQuery.docs.first.data();
          final emailCompagnie = compagnieData['email'];

          if (emailCompagnie != null) {
            await EmailNotificationService.envoyerNotificationDesaccordCompagnie(
              destinataire: emailCompagnie,
              codeConstat: session.codePublic,
              vehiculeRefusant: role,
              vehiculeAssure: vehiculeRole,
              numeroPolice: identite.numeroPolice,
              raisonRefus: raison,
            );
          }
        }
      }
    } catch (e) {
      print('Erreur notification compagnies: $e');
    }
  }

  /// 📧 Notifier un désaccord de contenu
  static Future<void> _notifierDesaccordContenu(String sessionId, String role, String section) async {
    // Implémentation similaire à _notifierDesaccord mais pour désaccord de contenu
    // TODO: Implémenter selon les besoins spécifiques
  }

  /// 🔄 Traitement automatique des sessions avec désaccord
  static Future<void> traiterSessionsAvecDesaccord() async {
    try {
      // Récupérer toutes les sessions en désaccord
      final sessionsQuery = await _firestore
          .collection('accident_sessions')
          .where('statut', isEqualTo: AccidentSession.STATUT_DESACCORD)
          .get();

      for (final sessionDoc in sessionsQuery.docs) {
        await _traiterSessionDesaccord(sessionDoc.id, sessionDoc.data());
      }

    } catch (e) {
      print('Erreur traitement sessions désaccord: $e');
    }
  }

  /// 📋 Traiter une session en désaccord
  static Future<void> _traiterSessionDesaccord(String sessionId, Map<String, dynamic> sessionData) async {
    try {
      // Vérifier si transmission possible malgré le désaccord
      final peutTransmettre = _evaluerTransmissionPossible(sessionData);

      if (peutTransmettre) {
        // Transmettre avec mention du désaccord
        await _transmettreAvecDesaccord(sessionId, sessionData);
      } else {
        // Escalader vers médiation
        await _escaladerVersMeditation(sessionId, sessionData);
      }

    } catch (e) {
      print('Erreur traitement session désaccord $sessionId: $e');
    }
  }

  /// ✅ Évaluer si transmission possible malgré désaccord
  static bool _evaluerTransmissionPossible(Map<String, dynamic> sessionData) {
    // Critères pour transmission malgré désaccord :
    // - Au moins 50% des véhicules ont signé
    // - Informations essentielles complètes
    // - Pas de désaccord sur les faits principaux

    final refus = sessionData['refus'] as Map<String, dynamic>? ?? {};
    final signatures = sessionData['signatures'] as Map<String, dynamic>? ?? {};
    final nombreVehicules = sessionData['nombreParticipants'] as int? ?? 2;

    final nombreRefus = refus.length;
    final nombreSignatures = signatures.length;
    final tauxSignature = nombreSignatures / nombreVehicules;

    // Transmission possible si plus de 50% ont signé
    return tauxSignature > 0.5;
  }

  /// 📤 Transmettre avec mention du désaccord
  static Future<void> _transmettreAvecDesaccord(String sessionId, Map<String, dynamic> sessionData) async {
    try {
      // Marquer comme transmis avec désaccord
      await _firestore.collection('accident_sessions').doc(sessionId).update({
        'statut': AccidentSession.STATUT_TRANSMIS_AVEC_DESACCORD,
        'dateTransmission': Timestamp.now(),
        'noteDesaccord': 'Constat transmis malgré désaccord de certaines parties',
      });

      // TODO: Implémenter la transmission avec annotations spéciales
      print('Session $sessionId transmise avec désaccord');

    } catch (e) {
      print('Erreur transmission avec désaccord: $e');
    }
  }

  /// 🤝 Escalader vers médiation
  static Future<void> _escaladerVersMeditation(String sessionId, Map<String, dynamic> sessionData) async {
    try {
      // Créer une demande de médiation globale
      await _firestore.collection('mediations_globales').add({
        'sessionId': sessionId,
        'type': 'escalade_desaccord',
        'dateCreation': Timestamp.now(),
        'statut': 'en_attente_mediateur',
        'priorite': 'haute',
        'delaiResolution': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 15)),
        ),
      });

      // Marquer la session
      await _firestore.collection('accident_sessions').doc(sessionId).update({
        'statut': AccidentSession.STATUT_EN_MEDIATION,
        'dateEscalade': Timestamp.now(),
      });

    } catch (e) {
      print('Erreur escalade médiation: $e');
    }
  }

  /// 📊 Calculer la priorité d'un litige
  static String _calculerPrioriteLitige(String raison) {
    switch (raison.toLowerCase()) {
      case 'desaccord_responsabilite':
      case 'contestation_faits':
        return 'haute';
      case 'probleme_technique':
      case 'information_manquante':
        return 'moyenne';
      default:
        return 'normale';
    }
  }

  /// 📧 Obtenir l'email d'un participant
  static Future<String?> _obtenirEmailParticipant(String sessionId, String role) async {
    try {
      final participantQuery = await _firestore
          .collection('session_participants')
          .where('sessionId', isEqualTo: sessionId)
          .where('role', isEqualTo: role)
          .limit(1)
          .get();

      if (participantQuery.docs.isNotEmpty) {
        return participantQuery.docs.first.data()['email'];
      }
    } catch (e) {
      print('Erreur récupération email participant: $e');
    }
    return null;
  }

  /// 📊 Logger un événement de désaccord
  static Future<void> _loggerDesaccord(String sessionId, String role, String type, String details) async {
    await _firestore.collection('desaccord_logs').add({
      'sessionId': sessionId,
      'vehicule': role,
      'type': type,
      'details': details,
      'timestamp': Timestamp.now(),
      'adresseIP': null, // TODO: IP réelle
    });
  }

  /// 📊 Statistiques des désaccords
  static Future<Map<String, dynamic>> obtenirStatistiquesDesaccords() async {
    final stats = <String, dynamic>{};

    // Désaccords aujourd'hui
    final debutJour = DateTime.now().subtract(Duration(
      hours: DateTime.now().hour,
      minutes: DateTime.now().minute,
      seconds: DateTime.now().second,
    ));

    final desaccordsQuery = await _firestore
        .collection('accident_sessions')
        .where('statut', isEqualTo: AccidentSession.STATUT_DESACCORD)
        .where('dateModification', isGreaterThanOrEqualTo: Timestamp.fromDate(debutJour))
        .count()
        .get();

    stats['desaccords_aujourd_hui'] = desaccordsQuery.count;

    // Litiges ouverts
    final litigesQuery = await _firestore
        .collection('litiges')
        .where('statut', isEqualTo: 'ouvert')
        .count()
        .get();

    stats['litiges_ouverts'] = litigesQuery.count;

    // Médiations en cours
    final mediationsQuery = await _firestore
        .collection('mediations')
        .where('statut', isEqualTo: 'en_attente_mediateur')
        .count()
        .get();

    stats['mediations_en_cours'] = mediationsQuery.count;

    return stats;
  }
}
