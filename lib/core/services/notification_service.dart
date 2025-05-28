import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // URL de l'API SMS (à remplacer par votre propre endpoint)
  final String _smsApiUrl = 'https://api.votre-service-sms.com';
  
  // Clé API SMS (à remplacer par votre propre clé)
  final String _smsApiKey = 'votre_cle_api_sms';
  
  // URL de l'API Email (à remplacer par votre propre endpoint)
  final String _emailApiUrl = 'https://api.votre-service-email.com';
  
  // Clé API Email (à remplacer par votre propre clé)
  final String _emailApiKey = 'votre_cle_api_email';

  // Initialiser le service de notifications
  Future<void> initialize() async {
    try {
      debugPrint('[NotificationService] Initialisation du service de notifications');
      
      // Demander l'autorisation pour les notifications
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      debugPrint('[NotificationService] Autorisation des notifications: ${settings.authorizationStatus}');
      
      // Configurer les gestionnaires de notifications
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      
      // Obtenir le token FCM
      final String? token = await _messaging.getToken();
      debugPrint('[NotificationService] Token FCM: $token');
      
    } catch (e) {
      debugPrint('[NotificationService] Erreur lors de l\'initialisation: $e');
    }
  }

  // Gérer les messages reçus en premier plan
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[NotificationService] Message reçu en premier plan: ${message.messageId}');
    debugPrint('[NotificationService] Titre: ${message.notification?.title}');
    debugPrint('[NotificationService] Corps: ${message.notification?.body}');
    debugPrint('[NotificationService] Données: ${message.data}');
    
    // Ici, vous pouvez afficher une notification locale ou mettre à jour l'interface utilisateur
  }

  // Gérer les messages ouverts par l'utilisateur
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('[NotificationService] Message ouvert par l\'utilisateur: ${message.messageId}');
    debugPrint('[NotificationService] Données: ${message.data}');
    
    // Ici, vous pouvez naviguer vers un écran spécifique en fonction des données du message
  }

  // Enregistrer le token FCM pour un utilisateur
  Future<void> saveUserToken(String userId) async {
    try {
      debugPrint('[NotificationService] Enregistrement du token pour l\'utilisateur: $userId');
      
      final String? token = await _messaging.getToken();
      
      if (token != null) {
        await _firestore.collection('user_tokens').doc(userId).set({
          'token': token,
          'platform': defaultTargetPlatform.toString(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        debugPrint('[NotificationService] Token enregistré avec succès');
      }
    } catch (e) {
      debugPrint('[NotificationService] Erreur lors de l\'enregistrement du token: $e');
    }
  }

  // Envoyer une notification à un utilisateur spécifique
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      debugPrint('[NotificationService] Envoi d\'une notification à l\'utilisateur: $userId');
      
      // Récupérer le token de l'utilisateur
      final tokenDoc = await _firestore.collection('user_tokens').doc(userId).get();
      
      if (tokenDoc.exists && tokenDoc.data() != null) {
        final String? token = tokenDoc.data()!['token'] as String?;
        
        if (token != null) {
          // Envoyer la notification via Cloud Functions ou un service tiers
          // Ceci est un exemple simplifié, vous devriez utiliser Cloud Functions ou un serveur backend
          
          final response = await http.post(
            Uri.parse('https://fcm.googleapis.com/fcm/send'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'key=VOTRE_CLE_SERVEUR_FCM', // Remplacer par votre clé serveur FCM
            },
            body: jsonEncode({
              'to': token,
              'notification': {
                'title': title,
                'body': body,
              },
              'data': data ?? {},
            }),
          );
          
          if (response.statusCode == 200) {
            debugPrint('[NotificationService] Notification envoyée avec succès');
          } else {
            debugPrint('[NotificationService] Erreur lors de l\'envoi de la notification: ${response.statusCode} - ${response.body}');
          }
        }
      } else {
        debugPrint('[NotificationService] Token non trouvé pour l\'utilisateur: $userId');
      }
    } catch (e) {
      debugPrint('[NotificationService] Erreur lors de l\'envoi de la notification: $e');
    }
  }

  // Envoyer un SMS
  Future<bool> sendSMS({
    required String to,
    required String message,
  }) async {
    try {
      debugPrint('[NotificationService] Envoi d\'un SMS au numéro: $to');
      
      // Appeler l'API SMS
      final response = await http.post(
        Uri.parse('$_smsApiUrl/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_smsApiKey',
        },
        body: jsonEncode({
          'to': to,
          'message': message,
        }),
      );
      
      if (response.statusCode == 200) {
        debugPrint('[NotificationService] SMS envoyé avec succès');
        return true;
      } else {
        debugPrint('[NotificationService] Erreur lors de l\'envoi du SMS: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[NotificationService] Erreur lors de l\'envoi du SMS: $e');
      return false;
    }
  }

  // Envoyer un email
  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String body,
    List<String>? attachments,
  }) async {
    try {
      debugPrint('[NotificationService] Envoi d\'un email à: $to');
      
      // Appeler l'API Email
      final response = await http.post(
        Uri.parse('$_emailApiUrl/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_emailApiKey',
        },
        body: jsonEncode({
          'to': to,
          'subject': subject,
          'body': body,
          'attachments': attachments ?? [],
        }),
      );
      
      if (response.statusCode == 200) {
        debugPrint('[NotificationService] Email envoyé avec succès');
        return true;
      } else {
        debugPrint('[NotificationService] Erreur lors de l\'envoi de l\'email: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[NotificationService] Erreur lors de l\'envoi de l\'email: $e');
      return false;
    }
  }

  // Se désabonner des notifications
  Future<void> unsubscribe(String userId) async {
    try {
      debugPrint('[NotificationService] Désabonnement des notifications pour l\'utilisateur: $userId');
      
      // Supprimer le token de l'utilisateur
      await _firestore.collection('user_tokens').doc(userId).delete();
      
      debugPrint('[NotificationService] Désabonnement réussi');
    } catch (e) {
      debugPrint('[NotificationService] Erreur lors du désabonnement: $e');
    }
  }
}
