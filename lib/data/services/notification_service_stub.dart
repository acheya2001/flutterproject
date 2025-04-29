// Ce fichier est un stub pour remplacer temporairement le service de notification

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    // Ne fait rien
    print('Notifications désactivées temporairement');
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Ne fait rien
    print('Notification simulée: $title - $body');
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // Ne fait rien
    print('Notification programmée simulée pour $scheduledDate: $title - $body');
  }

  Future<void> cancelNotification(int id) async {
    // Ne fait rien
    print('Annulation de notification simulée: $id');
  }

  Future<void> cancelAllNotifications() async {
    // Ne fait rien
    print('Annulation de toutes les notifications simulée');
  }
}
