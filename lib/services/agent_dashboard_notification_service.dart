import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 📱 Service de gestion des notifications dans le dashboard agent
class AgentDashboardNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📋 Récupérer les notifications d'un agent (avec champs EXACTS du dashboard)
  static Stream<QuerySnapshot> getNotificationsAgent(String agentId) {
    return _firestore
        .collection('notifications')
        .where('agentId', isEqualTo: agentId)            // ✅ agentId (comme dans le dashboard)
        .snapshots();
  }

  /// 📋 Récupérer les notifications non lues d'un agent (avec champs EXACTS du dashboard)
  static Stream<QuerySnapshot> getNotificationsNonLues(String agentId) {
    return _firestore
        .collection('notifications')
        .where('agentId', isEqualTo: agentId)             // ✅ agentId (comme dans le dashboard)
        .where('lu', isEqualTo: false)                    // ✅ lu (comme dans le dashboard)
        .snapshots();
  }

  /// 📊 Compter les notifications non lues
  static Stream<int> compterNotificationsNonLues(String agentId) {
    return getNotificationsNonLues(agentId).map((snapshot) => snapshot.docs.length);
  }

  /// ✅ Marquer une notification comme lue (avec champs EXACTS du dashboard)
  static Future<void> marquerCommeLue(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'lu': true,                                       // ✅ lu (comme dans le dashboard)
        'dateLecture': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Erreur marquage notification lue: $e');
    }
  }

  /// ✅ Marquer toutes les notifications comme lues (avec champs corrects)
  static Future<void> marquerToutesCommeLues(String agentId) async {
    try {
      final batch = _firestore.batch();

      final notifications = await _firestore
          .collection('notifications')
          .where('agentId', isEqualTo: agentId)             // ✅ agentId (comme dans le dashboard)
          .where('lu', isEqualTo: false)                    // ✅ lu (comme dans le dashboard)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {
          'lu': true,                                       // ✅ lu (comme dans le dashboard)
          'dateLecture': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('❌ Erreur marquage toutes notifications lues: $e');
    }
  }

  /// 🔔 Obtenir les notifications de constats pour un agent (avec champs EXACTS du dashboard)
  static Stream<QuerySnapshot> getNotificationsConstats(String agentId) {
    return _firestore
        .collection('notifications')
        .where('agentId', isEqualTo: agentId)               // ✅ agentId (comme dans le dashboard)
        .where('type', isEqualTo: 'nouveau_constat')
        .snapshots();
  }

  /// 📊 Obtenir les statistiques des notifications
  static Future<Map<String, int>> getStatistiquesNotifications(String agentId) async {
    try {
      final toutes = await _firestore
          .collection('notifications')
          .where('destinataireId', isEqualTo: agentId)
          .where('destinataireType', isEqualTo: 'agent')
          .get();

      final nonLues = toutes.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['lu'] == false;
      }).length;

      final constats = toutes.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['type'] == 'nouveau_constat';
      }).length;

      return {
        'total': toutes.docs.length,
        'nonLues': nonLues,
        'lues': toutes.docs.length - nonLues,
        'constats': constats,
      };
    } catch (e) {
      print('❌ Erreur statistiques notifications: $e');
      return {
        'total': 0,
        'nonLues': 0,
        'lues': 0,
        'constats': 0,
      };
    }
  }

  /// 📅 Formater une date de notification
  static String formaterDate(dynamic timestamp) {
    if (timestamp == null) return 'Date inconnue';
    
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return 'Date invalide';
    }
    
    final maintenant = DateTime.now();
    final difference = maintenant.difference(date);
    
    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// 🎨 Obtenir l'icône selon le type de notification
  static String getIconeNotification(String type) {
    switch (type) {
      case 'nouveau_constat':
        return '📄';
      case 'contrat_expire':
        return '⚠️';
      case 'nouveau_client':
        return '👤';
      case 'paiement_recu':
        return '💰';
      case 'document_requis':
        return '📋';
      default:
        return '🔔';
    }
  }

  /// 🎨 Obtenir la couleur selon le type de notification
  static String getCouleurNotification(String type) {
    switch (type) {
      case 'nouveau_constat':
        return '#FF6B35'; // Orange
      case 'contrat_expire':
        return '#DC2626'; // Rouge
      case 'nouveau_client':
        return '#059669'; // Vert
      case 'paiement_recu':
        return '#7C3AED'; // Violet
      case 'document_requis':
        return '#2563EB'; // Bleu
      default:
        return '#6B7280'; // Gris
    }
  }

  /// 🗑️ Supprimer une notification
  static Future<void> supprimerNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('❌ Erreur suppression notification: $e');
    }
  }

  /// 🔔 Obtenir les notifications récentes (dernières 24h)
  static Stream<QuerySnapshot> getNotificationsRecentes(String agentId) {
    final hier = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1)));
    
    return _firestore
        .collection('notifications')
        .where('destinataireId', isEqualTo: agentId)
        .where('destinataireType', isEqualTo: 'agent')
        .where('dateCreation', isGreaterThan: hier)
        .orderBy('dateCreation', descending: true)
        .snapshots();
  }

  /// 🎯 Obtenir les notifications par type
  static Stream<QuerySnapshot> getNotificationsParType(String agentId, String type) {
    return _firestore
        .collection('notifications')
        .where('destinataireId', isEqualTo: agentId)
        .where('destinataireType', isEqualTo: 'agent')
        .where('type', isEqualTo: type)
        .orderBy('dateCreation', descending: true)
        .snapshots();
  }

  /// 📱 Créer une notification personnalisée
  static Future<void> creerNotification({
    required String destinataireId,
    required String titre,
    required String message,
    required String type,
    Map<String, dynamic>? donnees,
    Duration? dureeExpiration,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'type': type,
        'destinataireId': destinataireId,
        'destinataireType': 'agent',
        'titre': titre,
        'message': message,
        'donnees': donnees ?? {},
        'lu': false,
        'dateCreation': FieldValue.serverTimestamp(),
        'dateExpiration': dureeExpiration != null
            ? Timestamp.fromDate(DateTime.now().add(dureeExpiration))
            : Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
      });
    } catch (e) {
      print('❌ Erreur création notification: $e');
    }
  }
}
