import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// 📧 Service de notification email pour les agents
class EmailNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// 📧 Envoyer notification de nouveau véhicule à un agent
  static Future<void> sendVehicleValidationNotification({
    required String agentEmail,
    required String agentName,
    required String vehicleName,
    required String plate,
    required String conducteurId,
    required String agencyName,
  }) async {
    try {
      // Appeler la fonction Cloud pour envoyer l'email
      final callable = _functions.httpsCallable('sendVehicleNotificationEmail');
      
      await callable.call({
        'to': agentEmail,
        'agentName': agentName,
        'vehicleName': vehicleName,
        'plate': plate,
        'conducteurId': conducteurId,
        'agencyName': agencyName,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Logger l'envoi
      await _logEmailSent(
        recipient: agentEmail,
        type: 'vehicle_validation_notification',
        data: {
          'agentName': agentName,
          'vehicleName': vehicleName,
          'plate': plate,
          'conducteurId': conducteurId,
        },
      );

      print('✅ Email envoyé à $agentEmail pour véhicule $plate');
    } catch (e) {
      print('❌ Erreur envoi email: $e');
      
      // Logger l'erreur
      await _logEmailError(
        recipient: agentEmail,
        type: 'vehicle_validation_notification',
        error: e.toString(),
      );
    }
  }

  /// 📧 Envoyer notification de statut véhicule au conducteur
  static Future<void> sendVehicleStatusNotification({
    required String conducteurEmail,
    required String conducteurName,
    required String vehicleName,
    required String plate,
    required bool isValidated,
    String? rejectionReason,
    required String agencyName,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendVehicleStatusEmail');
      
      await callable.call({
        'to': conducteurEmail,
        'conducteurName': conducteurName,
        'vehicleName': vehicleName,
        'plate': plate,
        'isValidated': isValidated,
        'rejectionReason': rejectionReason,
        'agencyName': agencyName,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await _logEmailSent(
        recipient: conducteurEmail,
        type: 'vehicle_status_notification',
        data: {
          'conducteurName': conducteurName,
          'vehicleName': vehicleName,
          'plate': plate,
          'isValidated': isValidated,
          'rejectionReason': rejectionReason,
        },
      );

      print('✅ Email statut envoyé à $conducteurEmail pour véhicule $plate');
    } catch (e) {
      print('❌ Erreur envoi email statut: $e');
      
      await _logEmailError(
        recipient: conducteurEmail,
        type: 'vehicle_status_notification',
        error: e.toString(),
      );
    }
  }

  /// 📧 Envoyer notification de nouveau constat aux agents
  static Future<void> sendConstatNotificationToAgents({
    required List<String> agentEmails,
    required String constatsId,
    required String location,
    required List<String> vehiclePlates,
    required String agencyName,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendConstatNotificationEmail');
      
      for (final email in agentEmails) {
        await callable.call({
          'to': email,
          'constatsId': constatsId,
          'location': location,
          'vehiclePlates': vehiclePlates,
          'agencyName': agencyName,
          'timestamp': DateTime.now().toIso8601String(),
        });

        await _logEmailSent(
          recipient: email,
          type: 'constat_notification',
          data: {
            'constatsId': constatsId,
            'location': location,
            'vehiclePlates': vehiclePlates,
          },
        );
      }

      print('✅ Emails constat envoyés à ${agentEmails.length} agents');
    } catch (e) {
      print('❌ Erreur envoi emails constat: $e');
    }
  }

  /// 📱 Envoyer SMS de notification (optionnel)
  static Future<void> sendSMSNotification({
    required String phoneNumber,
    required String message,
    required String type,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendSMSNotification');
      
      await callable.call({
        'to': phoneNumber,
        'message': message,
        'type': type,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await _logSMSSent(
        recipient: phoneNumber,
        type: type,
        message: message,
      );

      print('✅ SMS envoyé à $phoneNumber');
    } catch (e) {
      print('❌ Erreur envoi SMS: $e');
    }
  }

  /// 📊 Logger l'envoi d'email
  static Future<void> _logEmailSent({
    required String recipient,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('email_logs').add({
        'recipient': recipient,
        'type': type,
        'status': 'sent',
        'data': data,
        'sentAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Erreur log email: $e');
    }
  }

  /// 📊 Logger l'erreur d'email
  static Future<void> _logEmailError({
    required String recipient,
    required String type,
    required String error,
  }) async {
    try {
      await _firestore.collection('email_logs').add({
        'recipient': recipient,
        'type': type,
        'status': 'error',
        'error': error,
        'attemptedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Erreur log email error: $e');
    }
  }

  /// 📊 Logger l'envoi de SMS
  static Future<void> _logSMSSent({
    required String recipient,
    required String type,
    required String message,
  }) async {
    try {
      await _firestore.collection('sms_logs').add({
        'recipient': recipient,
        'type': type,
        'message': message,
        'status': 'sent',
        'sentAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Erreur log SMS: $e');
    }
  }

  /// 📈 Obtenir les statistiques d'envoi
  static Future<Map<String, int>> getEmailStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('email_logs');
      
      if (startDate != null) {
        query = query.where('sentAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      
      if (endDate != null) {
        query = query.where('sentAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      
      final stats = <String, int>{
        'total': snapshot.docs.length,
        'sent': 0,
        'error': 0,
      };

      for (final doc in snapshot.docs) {
        final status = doc.data() as Map<String, dynamic>;
        final statusValue = status['status'] as String;
        stats[statusValue] = (stats[statusValue] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('❌ Erreur stats email: $e');
      return {'total': 0, 'sent': 0, 'error': 0};
    }
  }

  /// 🔄 Réessayer l'envoi des emails en erreur
  static Future<void> retryFailedEmails() async {
    try {
      final failedEmails = await _firestore
          .collection('email_logs')
          .where('status', isEqualTo: 'error')
          .where('attemptedAt', isGreaterThan: Timestamp.fromDate(
              DateTime.now().subtract(const Duration(hours: 24))))
          .get();

      print('🔄 Réessai de ${failedEmails.docs.length} emails en erreur');

      for (final doc in failedEmails.docs) {
        final data = doc.data();
        final type = data['type'] as String;
        
        // Réessayer selon le type
        switch (type) {
          case 'vehicle_validation_notification':
            // TODO: Réessayer l'envoi
            break;
          case 'vehicle_status_notification':
            // TODO: Réessayer l'envoi
            break;
        }
      }
    } catch (e) {
      print('❌ Erreur réessai emails: $e');
    }
  }
}
