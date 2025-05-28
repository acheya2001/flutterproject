import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../../features/vehicule/models/vehicule_model.dart';
import 'notification_service.dart';

class NotificationReminderService {
  static final NotificationReminderService _instance = NotificationReminderService._internal();
  factory NotificationReminderService() => _instance;
  NotificationReminderService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Timer? _dailyCheckTimer;
  bool _isInitialized = false;

  // Initialiser le service de notifications
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('[NotificationReminderService] Initialisation du service de rappels');
      
      // Initialiser les fuseaux horaires
      tz.initializeTimeZones();
      
      // Configuration pour Android
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Configuration pour iOS (utilisation de la version compatible)
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
      );
      
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      // Demander les permissions pour les notifications
      await _requestPermissions();
      
      // Démarrer la vérification quotidienne
      _startDailyCheck();
      
      _isInitialized = true;
      debugPrint('[NotificationReminderService] Service initialisé avec succès');
    } catch (e) {
      debugPrint('[NotificationReminderService] Erreur lors de l\'initialisation: $e');
    }
  }

  // Demander les permissions (version simplifiée)
  Future<void> _requestPermissions() async {
    try {
      // Permissions Android uniquement pour éviter les erreurs
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
      }
    } catch (e) {
      debugPrint('[NotificationReminderService] Erreur lors de la demande de permissions: $e');
    }
  }

  // Gérer le tap sur une notification
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    debugPrint('[NotificationReminderService] Notification tappée: ${notificationResponse.payload}');
    // Ici vous pouvez naviguer vers l'écran approprié
  }

  // Démarrer la vérification quotidienne
  void _startDailyCheck() {
    // Annuler le timer existant s'il y en a un
    _dailyCheckTimer?.cancel();
    
    // Calculer le temps jusqu'à la prochaine vérification (9h00 du matin)
    final now = DateTime.now();
    var nextCheck = DateTime(now.year, now.month, now.day, 9, 0, 0);
    
    // Si on est déjà passé 9h00 aujourd'hui, programmer pour demain
    if (nextCheck.isBefore(now)) {
      nextCheck = nextCheck.add(const Duration(days: 1));
    }
    
    final timeUntilNextCheck = nextCheck.difference(now);
    
    debugPrint('[NotificationReminderService] Prochaine vérification programmée dans: ${timeUntilNextCheck.inHours}h ${timeUntilNextCheck.inMinutes % 60}min');
    
    // Programmer la première vérification
    Timer(timeUntilNextCheck, () {
      _performDailyCheck();
      
      // Puis programmer une vérification quotidienne
      _dailyCheckTimer = Timer.periodic(const Duration(days: 1), (timer) {
        _performDailyCheck();
      });
    });
  }

  // Effectuer la vérification quotidienne
  Future<void> _performDailyCheck() async {
    try {
      debugPrint('[NotificationReminderService] Début de la vérification quotidienne');
      
      // Récupérer tous les véhicules de la base de données
      final vehiculesSnapshot = await _firestore.collection('vehicules').get();
      
      for (final doc in vehiculesSnapshot.docs) {
        try {
          final vehicule = VehiculeModel.fromFirestore(doc);
          await _checkVehiculeInsurance(vehicule);
        } catch (e) {
          debugPrint('[NotificationReminderService] Erreur lors de la vérification du véhicule ${doc.id}: $e');
        }
      }
      
      debugPrint('[NotificationReminderService] Vérification quotidienne terminée');
    } catch (e) {
      debugPrint('[NotificationReminderService] Erreur lors de la vérification quotidienne: $e');
    }
  }

  // Vérifier l'assurance d'un véhicule
  Future<void> _checkVehiculeInsurance(VehiculeModel vehicule) async {
    if (vehicule.dateFinValidite == null) return;
    
    final now = DateTime.now();
    final expirationDate = vehicule.dateFinValidite!;
    final daysRemaining = expirationDate.difference(now).inDays;
    
    debugPrint('[NotificationReminderService] Véhicule ${vehicule.immatriculation}: $daysRemaining jours restants');
    
    // Vérifier si on est dans la dernière semaine (1 à 7 jours)
    if (daysRemaining >= 1 && daysRemaining <= 7) {
      await _sendInsuranceReminderNotification(vehicule, daysRemaining);
    }
    // Vérifier si l'assurance a expiré aujourd'hui
    else if (daysRemaining == 0) {
      await _sendInsuranceExpiredNotification(vehicule);
    }
    // Vérifier si l'assurance est expirée depuis plusieurs jours
    else if (daysRemaining < 0 && daysRemaining >= -3) {
      await _sendInsuranceOverdueNotification(vehicule, -daysRemaining);
    }
  }

  // Envoyer une notification de rappel d'assurance
  Future<void> _sendInsuranceReminderNotification(VehiculeModel vehicule, int daysRemaining) async {
    try {
      const title = 'Assurance à renouveler';
      final body = daysRemaining == 1
          ? 'L\'assurance de votre véhicule ${vehicule.immatriculation} expire demain !'
          : 'L\'assurance de votre véhicule ${vehicule.immatriculation} expire dans $daysRemaining jours.';
      
      // Notification locale
      await _showLocalNotification(
        id: vehicule.id.hashCode + daysRemaining,
        title: title,
        body: body,
        payload: 'insurance_reminder_${vehicule.id}',
      );
      
      // Notification push si l'utilisateur a un token
      await _sendPushNotification(vehicule.proprietaireId, title, body);
      
      // Enregistrer la notification dans Firestore pour historique
      await _saveNotificationHistory(
        vehicule.proprietaireId,
        vehicule.id!,
        'insurance_reminder',
        title,
        body,
        daysRemaining,
      );
      
      debugPrint('[NotificationReminderService] Notification envoyée pour ${vehicule.immatriculation}: $daysRemaining jours restants');
    } catch (e) {
      debugPrint('[NotificationReminderService] Erreur lors de l\'envoi de la notification: $e');
    }
  }

  // Envoyer une notification d'expiration
  Future<void> _sendInsuranceExpiredNotification(VehiculeModel vehicule) async {
    try {
      const title = 'Assurance expirée !';
      final body = 'L\'assurance de votre véhicule ${vehicule.immatriculation} a expiré aujourd\'hui. Renouvelez-la immédiatement.';
      
      await _showLocalNotification(
        id: vehicule.id.hashCode,
        title: title,
        body: body,
        payload: 'insurance_expired_${vehicule.id}',
        priority: Priority.high,
      );
      
      await _sendPushNotification(vehicule.proprietaireId, title, body);
      
      await _saveNotificationHistory(
        vehicule.proprietaireId,
        vehicule.id!,
        'insurance_expired',
        title,
        body,
        0,
      );
      
      debugPrint('[NotificationReminderService] Notification d\'expiration envoyée pour ${vehicule.immatriculation}');
    } catch (e) {
      debugPrint('[NotificationReminderService] Erreur lors de l\'envoi de la notification d\'expiration: $e');
    }
  }

  // Envoyer une notification de retard
  Future<void> _sendInsuranceOverdueNotification(VehiculeModel vehicule, int daysOverdue) async {
    try {
      const title = 'Assurance en retard !';
      final body = 'L\'assurance de votre véhicule ${vehicule.immatriculation} est expirée depuis $daysOverdue jour(s). Renouvelez-la d\'urgence !';
      
      await _showLocalNotification(
        id: vehicule.id.hashCode - daysOverdue,
        title: title,
        body: body,
        payload: 'insurance_overdue_${vehicule.id}',
        priority: Priority.high,
      );
      
      await _sendPushNotification(vehicule.proprietaireId, title, body);
      
      await _saveNotificationHistory(
        vehicule.proprietaireId,
        vehicule.id!,
        'insurance_overdue',
        title,
        body,
        -daysOverdue,
      );
      
      debugPrint('[NotificationReminderService] Notification de retard envoyée pour ${vehicule.immatriculation}: $daysOverdue jours de retard');
    } catch (e) {
      debugPrint('[NotificationReminderService] Erreur lors de l\'envoi de la notification de retard: $e');
    }
  }

  // Afficher une notification locale (version simplifiée)
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    Priority priority = Priority.defaultPriority,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'insurance_reminders',
        'Rappels d\'assurance',
        channelDescription: 'Notifications de rappel pour le renouvellement d\'assurance',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );
      
      const notificationDetails = NotificationDetails(
        android: androidDetails,
      );
      
      await _localNotifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NotificationReminderService] Erreur lors de l\'affichage de la notification locale: $e');
    }
  }

  // Envoyer une notification push
  Future<void> _sendPushNotification(String userId, String title, String body) async {
    try {
      await _notificationService.sendNotificationToUser(
        userId: userId,
        title: title,
        body: body,
        data: {
          'type': 'insurance_reminder',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('[NotificationReminderService] Erreur lors de l\'envoi de la notification push: $e');
    }
  }

  // Sauvegarder l'historique des notifications
  Future<void> _saveNotificationHistory(
    String userId,
    String vehiculeId,
    String type,
    String title,
    String body,
    int daysRemaining,
  ) async {
    try {
      await _firestore.collection('notification_history').add({
        'userId': userId,
        'vehiculeId': vehiculeId,
        'type': type,
        'title': title,
        'body': body,
        'daysRemaining': daysRemaining,
        'sentAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      debugPrint('[NotificationReminderService] Erreur lors de la sauvegarde de l\'historique: $e');
    }
  }

  // Programmer des notifications pour un véhicule spécifique
  Future<void> scheduleInsuranceReminders(VehiculeModel vehicule) async {
    if (vehicule.dateFinValidite == null || vehicule.id == null) return;
    
    try {
      debugPrint('[NotificationReminderService] Programmation des rappels pour ${vehicule.immatriculation}');
      
      final expirationDate = vehicule.dateFinValidite!;
      final now = DateTime.now();
      
      // Annuler les notifications existantes pour ce véhicule
      await cancelVehiculeReminders(vehicule.id!);
      
      // Programmer les notifications pour les 7 derniers jours
      for (int i = 7; i >= 1; i--) {
        final notificationDate = expirationDate.subtract(Duration(days: i));
        
        // Ne programmer que les notifications futures
        if (notificationDate.isAfter(now)) {
          final scheduledDate = tz.TZDateTime.from(
            DateTime(notificationDate.year, notificationDate.month, notificationDate.day, 9, 0),
            tz.local,
          );
          
          const title = 'Assurance à renouveler';
          final body = i == 1
              ? 'L\'assurance de votre véhicule ${vehicule.immatriculation} expire demain !'
              : 'L\'assurance de votre véhicule ${vehicule.immatriculation} expire dans $i jours.';
          
          await _localNotifications.zonedSchedule(
            vehicule.id.hashCode + i,
            title,
            body,
            scheduledDate,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'insurance_reminders',
                'Rappels d\'assurance',
                channelDescription: 'Notifications de rappel pour le renouvellement d\'assurance',
                importance: Importance.high,
                priority: Priority.high,
                showWhen: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            payload: 'scheduled_reminder_${vehicule.id}_$i',
          );
          
          debugPrint('[NotificationReminderService] Notification programmée pour le ${notificationDate.day}/${notificationDate.month}/${notificationDate.year} ($i jours avant expiration)');
        }
      }
    } catch (e) {
      debugPrint('[NotificationReminderService] Erreur lors de la programmation des rappels: $e');
    }
  }

  // Annuler les rappels pour un véhicule
  Future<void> cancelVehiculeReminders(String vehiculeId) async {
    try {
      final actualHashCode = vehiculeId.hashCode;
      
      // Annuler les notifications programmées (1 à 7 jours)
      for (int i = 1; i <= 7; i++) {
        await _localNotifications.cancel(actualHashCode + i);
      }
      
      // Annuler les autres notifications liées à ce véhicule
      await _localNotifications.cancel(actualHashCode); // Expiration
      await _localNotifications.cancel(actualHashCode - 1); // 1 jour de retard
      await _localNotifications.cancel(actualHashCode - 2); // 2 jours de retard
      await _localNotifications.cancel(actualHashCode - 3); // 3 jours de retard
      
      debugPrint('[NotificationReminderService] Rappels annulés pour le véhicule $vehiculeId');
    } catch (e) {
      debugPrint('[NotificationReminderService] Erreur lors de l\'annulation des rappels: $e');
    }
  }

  // Récupérer l'historique des notifications pour un utilisateur
  Future<List<Map<String, dynamic>>> getNotificationHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notification_history')
          .where('userId', isEqualTo: userId)
          .orderBy('sentAt', descending: true)
          .limit(50)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('[NotificationReminderService] Erreur lors de la récupération de l\'historique: $e');
      return [];
    }
  }

  // Marquer une notification comme lue
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notification_history')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      debugPrint('[NotificationReminderService] Erreur lors du marquage comme lu: $e');
    }
  }

  // Arrêter le service
  void dispose() {
    _dailyCheckTimer?.cancel();
    debugPrint('[NotificationReminderService] Service arrêté');
  }
}