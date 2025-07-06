import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// 🔔 Service de gestion des notifications pour les contrats d'assurance
class InsuranceNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// 📤 Envoyer une notification de nouveau contrat au conducteur
  static Future<bool> sendContractNotification({
    required String conducteurEmail,
    required String numeroContrat,
    required String vehiculeImmatriculation,
    required String compagnieNom,
    required String agentNom,
  }) async {
    try {
      print('🔔 [NOTIFICATION] Envoi notification contrat: $numeroContrat');

      // 1. Trouver l'utilisateur par email
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: conducteurEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        print('❌ [NOTIFICATION] Utilisateur non trouvé: $conducteurEmail');
        return false;
      }

      final userData = userQuery.docs.first;
      final userId = userData.id;
      final fcmToken = userData.data()['fcmToken'] as String?;

      // 2. Créer la notification dans Firestore
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'nouveau_contrat',
        'title': '🚗 Nouveau contrat d\'assurance',
        'message': 'Votre véhicule $vehiculeImmatriculation a été assuré chez $compagnieNom',
        'data': {
          'numeroContrat': numeroContrat,
          'vehiculeImmatriculation': vehiculeImmatriculation,
          'compagnieNom': compagnieNom,
          'agentNom': agentNom,
          'action': 'view_contract',
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Envoyer push notification si token FCM disponible
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _sendPushNotification(
          token: fcmToken,
          title: '🚗 Nouveau contrat d\'assurance',
          body: 'Votre véhicule $vehiculeImmatriculation a été assuré chez $compagnieNom',
          data: {
            'type': 'nouveau_contrat',
            'numeroContrat': numeroContrat,
            'vehiculeImmatriculation': vehiculeImmatriculation,
          },
        );
      }

      print('✅ [NOTIFICATION] Notification envoyée avec succès');
      return true;
    } catch (e) {
      print('❌ [NOTIFICATION] Erreur envoi notification: $e');
      return false;
    }
  }

  /// 📱 Envoyer une push notification via FCM
  static Future<void> _sendPushNotification({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      const String serverKey = 'YOUR_FCM_SERVER_KEY'; // À configurer
      
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'to': token,
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
          },
          'data': data,
          'priority': 'high',
        }),
      );

      if (response.statusCode == 200) {
        print('✅ [FCM] Push notification envoyée');
      } else {
        print('❌ [FCM] Erreur envoi push: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [FCM] Erreur push notification: $e');
    }
  }

  /// 📧 Envoyer notification par email
  static Future<bool> sendEmailNotification({
    required String recipientEmail,
    required String numeroContrat,
    required String vehiculeImmatriculation,
    required String compagnieNom,
  }) async {
    try {
      // Template email pour nouveau contrat
      final emailBody = '''
      <!DOCTYPE html>
      <html>
      <head>
          <meta charset="UTF-8">
          <title>Nouveau Contrat d'Assurance</title>
      </head>
      <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center;">
              <h1 style="color: white; margin: 0;">🚗 Nouveau Contrat d'Assurance</h1>
          </div>
          
          <div style="padding: 30px; background: #f8f9fa;">
              <h2 style="color: #333;">Félicitations !</h2>
              <p style="font-size: 16px; line-height: 1.6;">
                  Votre véhicule <strong>$vehiculeImmatriculation</strong> a été assuré avec succès chez <strong>$compagnieNom</strong>.
              </p>
              
              <div style="background: white; padding: 20px; border-radius: 8px; margin: 20px 0;">
                  <h3 style="color: #667eea; margin-top: 0;">Détails du contrat</h3>
                  <p><strong>Numéro de contrat :</strong> $numeroContrat</p>
                  <p><strong>Véhicule :</strong> $vehiculeImmatriculation</p>
                  <p><strong>Compagnie :</strong> $compagnieNom</p>
                  <p><strong>Date :</strong> ${DateTime.now().toString().split(' ')[0]}</p>
              </div>
              
              <div style="text-align: center; margin: 30px 0;">
                  <a href="constat://contract/$numeroContrat" 
                     style="background: #667eea; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">
                      Voir mon contrat
                  </a>
              </div>
              
              <p style="color: #666; font-size: 14px;">
                  Vous pouvez maintenant utiliser votre véhicule en toute sérénité. 
                  En cas d'accident, utilisez l'application Constat Tunisie pour déclarer rapidement votre sinistre.
              </p>
          </div>
          
          <div style="background: #333; color: white; padding: 20px; text-align: center;">
              <p style="margin: 0;">© 2025 Constat Tunisie - Votre partenaire assurance</p>
          </div>
      </body>
      </html>
      ''';

      // Ici vous pouvez intégrer votre service d'email (Gmail API, SendGrid, etc.)
      print('📧 [EMAIL] Email préparé pour: $recipientEmail');
      return true;
    } catch (e) {
      print('❌ [EMAIL] Erreur envoi email: $e');
      return false;
    }
  }

  /// 🔔 Initialiser les notifications locales
  static Future<void> initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(initializationSettings);
  }

  /// 📱 Afficher notification locale
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'contract_channel',
      'Contrats d\'assurance',
      channelDescription: 'Notifications pour les contrats d\'assurance',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  /// 📋 Récupérer les notifications d'un utilisateur
  static Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// ✅ Marquer une notification comme lue
  static Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }
}
