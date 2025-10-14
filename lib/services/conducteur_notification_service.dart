import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 🔔 Service de notification pour le conducteur
class ConducteurNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📧 Notifier le conducteur qu'un expert a été assigné à son constat
  static Future<Map<String, dynamic>> notifierExpertAssigne({
    required String conducteurId,
    required String codeConstat,
    required String sessionId,
    required Map<String, dynamic> expertData,
    required String agentId,
    String? commentaire,
    int? delaiInterventionHeures,
  }) async {
    try {
      debugPrint('[NOTIFICATION] 📧 Notification expert assigné pour conducteur: $conducteurId');

      // Créer la notification
      final notificationData = {
        'type': 'expert_assigne',
        'titre': 'Expert assigné à votre constat',
        'message': 'Un expert a été assigné à votre constat $codeConstat',
        'conducteurId': conducteurId,
        'codeConstat': codeConstat,
        'sessionId': sessionId,
        'agentId': agentId,
        'expertData': {
          'id': expertData['id'],
          'nom': expertData['nom'],
          'codeExpert': expertData['codeExpert'],
          'telephone': expertData['telephone'],
          'email': expertData['email'],
        },
        'commentaire': commentaire,
        'delaiInterventionHeures': delaiInterventionHeures,
        'dateCreation': FieldValue.serverTimestamp(),
        'lu': false,
        'statut': 'nouveau',
        'priorite': 'normale',
      };

      // Sauvegarder la notification
      final notificationRef = await _firestore
          .collection('notifications_conducteur')
          .add(notificationData);

      debugPrint('[NOTIFICATION] ✅ Notification créée: ${notificationRef.id}');

      // Mettre à jour le compteur de notifications non lues
      await _updateNotificationCounter(conducteurId);

      return {
        'success': true,
        'notificationId': notificationRef.id,
        'message': 'Notification envoyée avec succès',
      };

    } catch (e) {
      debugPrint('[NOTIFICATION] ❌ Erreur création notification: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 📊 Mettre à jour le compteur de notifications non lues
  static Future<void> _updateNotificationCounter(String conducteurId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications_conducteur')
          .where('conducteurId', isEqualTo: conducteurId)
          .where('lu', isEqualTo: false)
          .get();

      final count = snapshot.docs.length;

      await _firestore
          .collection('users')
          .doc(conducteurId)
          .update({
        'notificationsNonLues': count,
        'lastNotificationUpdate': FieldValue.serverTimestamp(),
      });

      debugPrint('[NOTIFICATION] 📊 Compteur mis à jour: $count notifications non lues');

    } catch (e) {
      debugPrint('[NOTIFICATION] ❌ Erreur mise à jour compteur: $e');
    }
  }

  /// 📋 Récupérer les notifications d'un conducteur
  static Future<List<Map<String, dynamic>>> getNotifications({
    required String conducteurId,
    int limit = 20,
    bool onlyUnread = false,
  }) async {
    try {
      Query query = _firestore
          .collection('notifications_conducteur')
          .where('conducteurId', isEqualTo: conducteurId)
          .orderBy('dateCreation', descending: true)
          .limit(limit);

      if (onlyUnread) {
        query = query.where('lu', isEqualTo: false);
      }

      final snapshot = await query.get();
      
      List<Map<String, dynamic>> notifications = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        notifications.add(data);
      }

      debugPrint('[NOTIFICATION] 📋 ${notifications.length} notifications récupérées');
      return notifications;

    } catch (e) {
      debugPrint('[NOTIFICATION] ❌ Erreur récupération notifications: $e');
      return [];
    }
  }

  /// ✅ Marquer une notification comme lue
  static Future<bool> marquerCommeLue(String notificationId, String conducteurId) async {
    try {
      await _firestore
          .collection('notifications_conducteur')
          .doc(notificationId)
          .update({
        'lu': true,
        'dateLecture': FieldValue.serverTimestamp(),
      });

      // Mettre à jour le compteur
      await _updateNotificationCounter(conducteurId);

      debugPrint('[NOTIFICATION] ✅ Notification marquée comme lue: $notificationId');
      return true;

    } catch (e) {
      debugPrint('[NOTIFICATION] ❌ Erreur marquage lecture: $e');
      return false;
    }
  }

  /// ✅ Marquer toutes les notifications comme lues
  static Future<bool> marquerToutesCommeLues(String conducteurId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications_conducteur')
          .where('conducteurId', isEqualTo: conducteurId)
          .where('lu', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'lu': true,
          'dateLecture': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // Mettre à jour le compteur
      await _updateNotificationCounter(conducteurId);

      debugPrint('[NOTIFICATION] ✅ ${snapshot.docs.length} notifications marquées comme lues');
      return true;

    } catch (e) {
      debugPrint('[NOTIFICATION] ❌ Erreur marquage toutes lues: $e');
      return false;
    }
  }

  /// 🔔 Stream des notifications en temps réel
  static Stream<List<Map<String, dynamic>>> streamNotifications({
    required String conducteurId,
    int limit = 20,
  }) {
    return _firestore
        .collection('notifications_conducteur')
        .where('conducteurId', isEqualTo: conducteurId)
        .orderBy('dateCreation', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// 📊 Obtenir le nombre de notifications non lues
  static Future<int> getUnreadCount(String conducteurId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications_conducteur')
          .where('conducteurId', isEqualTo: conducteurId)
          .where('lu', isEqualTo: false)
          .get();

      return snapshot.docs.length;

    } catch (e) {
      debugPrint('[NOTIFICATION] ❌ Erreur comptage non lues: $e');
      return 0;
    }
  }

  /// 🗑️ Supprimer une notification
  static Future<bool> supprimerNotification(String notificationId, String conducteurId) async {
    try {
      await _firestore
          .collection('notifications_conducteur')
          .doc(notificationId)
          .delete();

      // Mettre à jour le compteur
      await _updateNotificationCounter(conducteurId);

      debugPrint('[NOTIFICATION] 🗑️ Notification supprimée: $notificationId');
      return true;

    } catch (e) {
      debugPrint('[NOTIFICATION] ❌ Erreur suppression notification: $e');
      return false;
    }
  }

  /// 🎨 Obtenir l'icône selon le type de notification
  static String getNotificationIcon(String type) {
    switch (type) {
      case 'expert_assigne':
        return '👨‍🔧';
      case 'expertise_terminee':
        return '✅';
      case 'document_disponible':
        return '📄';
      case 'rappel':
        return '⏰';
      default:
        return '🔔';
    }
  }

  /// 🎨 Obtenir la couleur selon le type de notification
  static String getNotificationColor(String type) {
    switch (type) {
      case 'expert_assigne':
        return 'blue';
      case 'expertise_terminee':
        return 'green';
      case 'document_disponible':
        return 'purple';
      case 'rappel':
        return 'orange';
      default:
        return 'grey';
    }
  }

  /// 📅 Formater la date de notification
  static String formatNotificationDate(dynamic date) {
    if (date == null) return 'Date inconnue';
    
    try {
      DateTime dateTime;
      if (date is Timestamp) {
        dateTime = date.toDate();
      } else if (date is String) {
        dateTime = DateTime.tryParse(date) ?? DateTime.now();
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return 'Date invalide';
      }
      
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'À l\'instant';
      } else if (difference.inMinutes < 60) {
        return 'Il y a ${difference.inMinutes} min';
      } else if (difference.inHours < 24) {
        return 'Il y a ${difference.inHours}h';
      } else if (difference.inDays < 7) {
        return 'Il y a ${difference.inDays} jour(s)';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return 'Date invalide';
    }
  }
}
