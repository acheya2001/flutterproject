import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 📢 Service de gestion des notifications
class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 📨 Créer une notification
  static Future<void> createNotification({
    required String recipientId,
    required String recipientType, // 'conducteur', 'agent', 'admin'
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'recipientId': recipientId,
        'recipientType': recipientType,
        'type': type,
        'title': title,
        'message': message,
        'data': data ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la création de la notification: $e');
    }
  }

  /// 📋 Obtenir les notifications d'un utilisateur
  static Future<List<Map<String, dynamic>>> getUserNotifications(
    String userId,
    String userType,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('recipientType', isEqualTo: userType)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des notifications: $e');
    }
  }

  /// 🔄 Stream des notifications en temps réel
  static Stream<List<Map<String, dynamic>>> streamUserNotifications(
    String userId,
    String userType,
  ) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .where('recipientType', isEqualTo: userType)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  /// ✅ Marquer une notification comme lue
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Erreur lors du marquage de la notification: $e');
    }
  }

  /// ✅ Marquer toutes les notifications comme lues
  static Future<void> markAllAsRead(String userId, String userType) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('recipientType', isEqualTo: userType)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors du marquage des notifications: $e');
    }
  }

  /// 🗑️ Supprimer une notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la notification: $e');
    }
  }

  /// 📊 Obtenir le nombre de notifications non lues
  static Future<int> getUnreadCount(String userId, String userType) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('recipientType', isEqualTo: userType)
          .where('isRead', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// 🔄 Stream du nombre de notifications non lues
  static Stream<int> streamUnreadCount(String userId, String userType) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .where('recipientType', isEqualTo: userType)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// 📢 Notifications spécifiques pour les véhicules

  /// Notifier les agents d'un nouveau véhicule
  static Future<void> notifyAgentsNewVehicle({
    required List<String> agentIds,
    required String vehicleId,
    required String conducteurId,
    required String vehicleName,
    required String plate,
    required String agencyId,
    required String companyId,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final agentId in agentIds) {
        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, {
          'recipientId': agentId,
          'recipientType': 'agent',
          'type': 'new_vehicle_pending',
          'title': 'Nouveau véhicule en attente',
          'message': 'Un nouveau véhicule $vehicleName ($plate) a été soumis pour validation',
          'data': {
            'vehicleId': vehicleId,
            'conducteurId': conducteurId,
            'agencyId': agencyId,
            'companyId': companyId,
            'vehicleName': vehicleName,
            'plate': plate,
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors de la notification des agents: $e');
    }
  }

  /// Notifier le conducteur de la validation/rejet de son véhicule
  static Future<void> notifyConducteurVehicleStatus({
    required String conducteurId,
    required String vehicleId,
    required String vehicleName,
    required String plate,
    required bool isValidated,
    String? rejectionReason,
  }) async {
    try {
      await createNotification(
        recipientId: conducteurId,
        recipientType: 'conducteur',
        type: isValidated ? 'vehicle_validated' : 'vehicle_rejected',
        title: isValidated ? 'Véhicule validé' : 'Véhicule rejeté',
        message: isValidated
            ? 'Votre véhicule $vehicleName ($plate) a été validé par l\'agence'
            : 'Votre véhicule $vehicleName ($plate) a été rejeté. ${rejectionReason ?? ''}',
        data: {
          'vehicleId': vehicleId,
          'vehicleName': vehicleName,
          'plate': plate,
          'isValidated': isValidated,
          if (rejectionReason != null) 'rejectionReason': rejectionReason,
        },
      );
    } catch (e) {
      throw Exception('Erreur lors de la notification du conducteur: $e');
    }
  }

  /// 📢 Notifications pour les constats

  /// Notifier les participants d'un nouveau constat
  static Future<void> notifyConstatsParticipants({
    required List<String> participantIds,
    required String constatsId,
    required String initiatorName,
    required String location,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final participantId in participantIds) {
        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, {
          'recipientId': participantId,
          'recipientType': 'conducteur',
          'type': 'constat_invitation',
          'title': 'Invitation à un constat',
          'message': '$initiatorName vous invite à participer à un constat d\'accident à $location',
          'data': {
            'constatsId': constatsId,
            'initiatorName': initiatorName,
            'location': location,
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors de la notification des participants: $e');
    }
  }

  /// Notifier la finalisation d'un constat
  static Future<void> notifyConstatsFinalized({
    required List<String> participantIds,
    required List<String> agentIds,
    required String constatsId,
    required String location,
  }) async {
    try {
      final batch = _firestore.batch();

      // Notifier les participants
      for (final participantId in participantIds) {
        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, {
          'recipientId': participantId,
          'recipientType': 'conducteur',
          'type': 'constat_finalized',
          'title': 'Constat finalisé',
          'message': 'Le constat d\'accident à $location a été finalisé et signé par toutes les parties',
          'data': {
            'constatsId': constatsId,
            'location': location,
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Notifier les agents
      for (final agentId in agentIds) {
        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, {
          'recipientId': agentId,
          'recipientType': 'agent',
          'type': 'constat_finalized',
          'title': 'Nouveau constat finalisé',
          'message': 'Un constat d\'accident à $location a été finalisé et nécessite votre attention',
          'data': {
            'constatsId': constatsId,
            'location': location,
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors de la notification de finalisation: $e');
    }
  }
}
