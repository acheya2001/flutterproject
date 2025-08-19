import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/insurance/models/insurance_structure_model.dart';

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
}
