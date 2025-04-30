import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

// Logger global
final logger = Logger();

class FirebaseConfig {
  // Instances Firebase
  static FirebaseAuth auth = FirebaseAuth.instance;
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static FirebaseStorage storage = FirebaseStorage.instance;
  static FirebaseMessaging messaging = FirebaseMessaging.instance;
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseCrashlytics crashlytics = FirebaseCrashlytics.instance;

  // Initialisation de Firebase
  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      
      // Configuration de Crashlytics
      await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
      
      // Intercepter les erreurs Flutter et les envoyer à Crashlytics
      FlutterError.onError = (FlutterErrorDetails details) {
        logger.e('Erreur Flutter: ${details.exception}');
        crashlytics.recordFlutterError(details);
      };
      
      // Configuration des notifications
      await _configureMessaging();
      
      logger.i('Firebase initialisé avec succès');
    } catch (e) {
      logger.e('Erreur lors de l\'initialisation de Firebase: $e');
      rethrow;
    }
  }

  // Configuration des notifications push
  static Future<void> _configureMessaging() async {
    // Demander la permission pour les notifications
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    logger.i('Statut des autorisations de notification: ${settings.authorizationStatus}');
    
    // Obtenir le token FCM
    String? token = await messaging.getToken();
    if (token != null) {
      logger.i('Token FCM: $token');
      await _saveTokenToDatabase(token);
    }
    
    // Écouter les changements de token
    messaging.onTokenRefresh.listen(_saveTokenToDatabase);
    
    // Configurer les gestionnaires de messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      logger.i('Message reçu en premier plan: ${message.notification?.title}');
      // Afficher une notification locale
    });
    
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logger.i('Message ouvert: ${message.notification?.title}');
      // Naviguer vers l'écran approprié
    });
  }

  // Sauvegarder le token FCM dans Firestore
  static Future<void> _saveTokenToDatabase(String token) async {
    final user = auth.currentUser;
    if (user != null) {
      await firestore.collection('users').doc(user.uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    }
  }

  // Méthode pour nettoyer les tokens FCM obsolètes
  static Future<void> cleanupFCMTokens() async {
    final user = auth.currentUser;
    if (user != null) {
      final currentToken = await messaging.getToken();
      if (currentToken != null) {
        final userDoc = await firestore.collection('users').doc(user.uid).get();
        final tokens = List<String>.from(userDoc.data()?['fcmTokens'] ?? []);
        
        // Garder uniquement le token actuel
        await firestore.collection('users').doc(user.uid).update({
          'fcmTokens': [currentToken],
        });
      }
    }
  }
}