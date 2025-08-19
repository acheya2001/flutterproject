import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// 🔔 Service de notifications en temps réel
class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 📤 Envoyer notification à un agent quand un véhicule est ajouté
  static Future<void> notifyAgentNewVehicule({
    required String agenceId,
    required String vehiculeId,
    required String conducteurId,
    required String conducteurNom,
    required String vehiculeInfo,
  }) async {
    try {
      // Trouver l'agent de cette agence
      final agentQuery = await _firestore
          .collection('agents_assurance')
          .where('agenceId', isEqualTo: agenceId)
          .limit(1)
          .get();

      if (agentQuery.docs.isNotEmpty) {
        final agentId = agentQuery.docs.first.id;
        
        // Créer la notification
        await _firestore.collection('notifications').add({
          'type': 'nouveau_vehicule',
          'destinataireId': agentId,
          'destinataireType': 'agent',
          'titre': 'Nouveau véhicule à assurer',
          'message': 'Le conducteur $conducteurNom a ajouté un véhicule : $vehiculeInfo',
          'donnees': {
            'vehiculeId': vehiculeId,
            'conducteurId': conducteurId,
            'agenceId': agenceId,
            'action': 'creer_contrat',
          },
          'lu': false,
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 30)),
          ),
        });

        debugPrint('✅ Notification envoyée à l\'agent $agentId');
      }
    } catch (e) {
      debugPrint('❌ Erreur envoi notification: $e');
    }
  }

  /// 📤 Notifier le conducteur que son contrat est créé
  static Future<void> notifyContractCreated({
    required String conducteurId,
    required String vehiculeId,
    required String numeroContrat,
    required String agenceNom,
    required String vehiculeInfo,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'type': 'contrat_cree',
        'destinataireId': conducteurId,
        'destinataireType': 'conducteur',
        'titre': 'Contrat d\'assurance créé',
        'message': 'Votre véhicule $vehiculeInfo est maintenant assuré par $agenceNom',
        'donnees': {
          'vehiculeId': vehiculeId,
          'numeroContrat': numeroContrat,
          'agenceNom': agenceNom,
          'action': 'voir_contrat',
        },
        'lu': false,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 90)),
        ),
      });

      debugPrint('✅ Notification contrat envoyée au conducteur $conducteurId');
    } catch (e) {
      debugPrint('❌ Erreur notification contrat: $e');
    }
  }

  /// 📥 Récupérer les notifications d'un utilisateur
  static Stream<QuerySnapshot> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('destinataireId', isEqualTo: userId)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// ✅ Marquer une notification comme lue
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'lu': true});
    } catch (e) {
      debugPrint('❌ Erreur marquage lu: $e');
    }
  }

  /// 🧹 Nettoyer les anciennes notifications
  static Future<void> cleanExpiredNotifications() async {
    try {
      final expiredQuery = await _firestore
          .collection('notifications')
          .where('expiresAt', isLessThan: Timestamp.now())
          .get();

      final batch = _firestore.batch();
      for (final doc in expiredQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      debugPrint('✅ ${expiredQuery.docs.length} notifications expirées supprimées');
    } catch (e) {
      debugPrint('❌ Erreur nettoyage notifications: $e');
    }
  }

  /// 📊 Compter les notifications non lues
  static Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('destinataireId', isEqualTo: userId)
        .where('lu', isEqualTo: false)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
