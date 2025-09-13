import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/insurance/models/insurance_structure_model.dart';
import 'email_notification_service.dart';

/// 🔔 Service de notifications pour les agents
class AgentNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔄 Stream des véhicules en attente pour une agence (temps réel)
  static Stream<List<PendingVehicle>> streamPendingVehicles(String agencyId) {
    return _firestore
        .collection('vehicules_en_attente')
        .where('agencyId', isEqualTo: agencyId)
        .where('status', isEqualTo: VehicleStatus.enAttenteValidation.value)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint('[AGENT_NOTIFICATIONS] 📊 ${snapshot.docs.length} véhicules en attente pour agence: $agencyId');
          return snapshot.docs
              .map((doc) => PendingVehicle.fromMap(doc.data()))
              .toList();
        });
  }

  /// 🔄 Stream du nombre de véhicules en attente
  static Stream<int> streamPendingVehiclesCount(String agencyId) {
    return streamPendingVehicles(agencyId)
        .map((vehicles) => vehicles.length);
  }

  /// 🔄 Stream des notifications non lues pour un agent
  static Stream<List<Map<String, dynamic>>> streamAgentNotifications(String agentId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: agentId)
        .where('recipientType', isEqualTo: 'agent')
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// 📢 Créer une notification pour les agents d'une agence
  static Future<void> notifyAgentsOfNewVehicle({
    required String agencyId,
    required PendingVehicle vehicle,
  }) async {
    try {
      // Récupérer tous les agents de l'agence
      final agentsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('agenceId', isEqualTo: agencyId)
          .where('isActive', isEqualTo: true)
          .get();

      // Créer une notification pour chaque agent
      final batch = _firestore.batch();
      
      for (final agentDoc in agentsQuery.docs) {
        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, {
          'recipientId': agentDoc.id,
          'recipientType': 'agent',
          'type': 'new_vehicle_pending',
          'title': 'Nouveau véhicule à valider',
          'message': 'Un nouveau véhicule ${vehicle.brand} ${vehicle.model} (${vehicle.plate}) a été soumis par ${vehicle.conducteurFullName}',
          'data': {
            'vehicleId': vehicle.vehicleId,
            'agencyId': vehicle.agencyId,
            'companyId': vehicle.companyId,
            'conducteurId': vehicle.conducteurId,
            'vehicleBrand': vehicle.brand,
            'vehicleModel': vehicle.model,
            'vehiclePlate': vehicle.plate,
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('[AGENT_NOTIFICATIONS] ✅ Notifications envoyées à ${agentsQuery.docs.length} agents pour véhicule: ${vehicle.vehicleId}');

    } catch (e) {
      debugPrint('[AGENT_NOTIFICATIONS] ❌ Erreur envoi notifications: $e');
    }
  }

  /// ✅ Marquer une notification comme lue
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('[AGENT_NOTIFICATIONS] ❌ Erreur marquage notification: $e');
    }
  }

  /// ✅ Marquer toutes les notifications d'un agent comme lues
  static Future<void> markAllNotificationsAsRead(String agentId) async {
    try {
      final notificationsQuery = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: agentId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in notificationsQuery.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      debugPrint('[AGENT_NOTIFICATIONS] ✅ ${notificationsQuery.docs.length} notifications marquées comme lues pour agent: $agentId');
    } catch (e) {
      debugPrint('[AGENT_NOTIFICATIONS] ❌ Erreur marquage notifications: $e');
    }
  }

  /// 📊 Obtenir le nombre de notifications non lues
  static Future<int> getUnreadNotificationsCount(String agentId) async {
    try {
      final query = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: agentId)
          .where('recipientType', isEqualTo: 'agent')
          .where('isRead', isEqualTo: false)
          .get();

      return query.docs.length;
    } catch (e) {
      debugPrint('[AGENT_NOTIFICATIONS] ❌ Erreur comptage notifications: $e');
      return 0;
    }
  }

  /// 📧 Traiter les notifications de constats finalisés
  static Future<void> traiterNotificationsConstats() async {
    try {
      // Récupérer les notifications en attente
      final query = await _firestore
          .collection('notifications_agents')
          .where('statut', isEqualTo: 'en_attente')
          .where('type', isEqualTo: 'constat_finalise')
          .limit(10)
          .get();

      for (final doc in query.docs) {
        final notification = doc.data();
        final emailAgent = notification['destinataire'] as String;
        final sessionId = notification['sessionId'] as String;
        final pdfUrl = notification['pdfUrl'] as String?;

        try {
          // Envoyer l'email avec le PDF en pièce jointe
          await _envoyerEmailConstatFinalise(
            emailAgent: emailAgent,
            sessionId: sessionId,
            pdfUrl: pdfUrl,
            participantData: notification['participantData'] as Map<String, dynamic>? ?? {},
          );

          // Marquer comme traité
          await doc.reference.update({
            'statut': 'envoye',
            'dateEnvoi': Timestamp.fromDate(DateTime.now()),
          });

          debugPrint('[AGENT_NOTIFICATIONS] ✅ Email envoyé à $emailAgent pour session $sessionId');

        } catch (e) {
          // Marquer comme erreur
          await doc.reference.update({
            'statut': 'erreur',
            'erreur': e.toString(),
            'dateErreur': Timestamp.fromDate(DateTime.now()),
          });

          debugPrint('[AGENT_NOTIFICATIONS] ❌ Erreur envoi email à $emailAgent: $e');
        }
      }

    } catch (e) {
      debugPrint('[AGENT_NOTIFICATIONS] ❌ Erreur traitement notifications: $e');
    }
  }

  /// 📧 Envoyer un email de constat finalisé à un agent
  static Future<void> _envoyerEmailConstatFinalise({
    required String emailAgent,
    required String sessionId,
    required String? pdfUrl,
    required Map<String, dynamic> participantData,
  }) async {
    final donneesFormulaire = participantData['donneesFormulaire'] as Map<String, dynamic>? ?? {};
    final donneesPersonnelles = donneesFormulaire['donneesPersonnelles'] as Map<String, dynamic>? ?? {};
    final donneesVehicule = donneesFormulaire['donneesVehicule'] as Map<String, dynamic>? ?? {};
    final donneesAssurance = donneesFormulaire['donneesAssurance'] as Map<String, dynamic>? ?? {};

    final conducteurNom = '${donneesPersonnelles['prenom'] ?? ''} ${donneesPersonnelles['nom'] ?? ''}'.trim();
    final vehiculeInfo = '${donneesVehicule['marque'] ?? ''} ${donneesVehicule['modele'] ?? ''} (${donneesVehicule['immatriculation'] ?? ''})'.trim();
    final numeroPolice = donneesAssurance['numeroPolice'] ?? 'N/A';

    final objet = 'Nouveau constat d\'accident finalisé - Session $sessionId';

    final contenu = '''
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px 10px 0 0;">
        <h1 style="margin: 0; font-size: 24px;">🚗 Constat d'accident finalisé</h1>
        <p style="margin: 10px 0 0 0; opacity: 0.9;">Nouveau constat nécessitant votre attention</p>
      </div>

      <div style="background: #f8f9fa; padding: 20px; border-radius: 0 0 10px 10px;">
        <h2 style="color: #333; margin-top: 0;">Détails du constat</h2>

        <div style="background: white; padding: 15px; border-radius: 8px; margin: 15px 0; border-left: 4px solid #667eea;">
          <h3 style="color: #667eea; margin-top: 0;">📋 Informations générales</h3>
          <p><strong>Code de session:</strong> $sessionId</p>
          <p><strong>Date de finalisation:</strong> ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}</p>
        </div>

        <div style="background: white; padding: 15px; border-radius: 8px; margin: 15px 0; border-left: 4px solid #28a745;">
          <h3 style="color: #28a745; margin-top: 0;">👤 Assuré concerné</h3>
          <p><strong>Conducteur:</strong> $conducteurNom</p>
          <p><strong>Véhicule:</strong> $vehiculeInfo</p>
          <p><strong>N° Police:</strong> $numeroPolice</p>
        </div>

        ${pdfUrl != null ? '''
        <div style="background: white; padding: 15px; border-radius: 8px; margin: 15px 0; border-left: 4px solid #ffc107;">
          <h3 style="color: #ffc107; margin-top: 0;">📄 Document PDF</h3>
          <p>Le constat complet est disponible au format PDF :</p>
          <a href="$pdfUrl" style="display: inline-block; background: #667eea; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; margin-top: 10px;">
            📥 Télécharger le constat PDF
          </a>
        </div>
        ''' : ''}

        <div style="background: #e9ecef; padding: 15px; border-radius: 8px; margin: 20px 0;">
          <p style="margin: 0; font-size: 14px; color: #6c757d;">
            <strong>Action requise:</strong> Veuillez examiner ce constat et prendre les mesures appropriées selon vos procédures internes.
          </p>
        </div>

        <hr style="border: none; border-top: 1px solid #dee2e6; margin: 20px 0;">

        <p style="font-size: 12px; color: #6c757d; margin: 0;">
          Cet email a été généré automatiquement par l'application Constat Tunisie.<br>
          Pour toute question, veuillez contacter le support technique.
        </p>
      </div>
    </div>
    ''';

    await EmailNotificationService.envoyerEmail(
      destinataire: emailAgent,
      objet: objet,
      contenu: contenu,
      type: 'constat_finalise',
    );
  }
}
