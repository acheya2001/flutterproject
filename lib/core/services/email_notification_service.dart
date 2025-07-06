import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// 📧 Service de notifications par email
class EmailNotificationService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📧 Envoyer un email de confirmation d'acceptation
  static Future<bool> sendAcceptanceEmail({
    required String email,
    required String nomComplet,
    required String role,
    required String motDePasse,
  }) async {
    try {
      debugPrint('[EMAIL_SERVICE] 📧 Envoi email acceptation à: $email');

      final callable = _functions.httpsCallable('sendAcceptanceEmail');
      
      final result = await callable.call({
        'email': email,
        'nomComplet': nomComplet,
        'role': role,
        'motDePasse': motDePasse,
        'appName': 'Constat Tunisie',
        'loginUrl': 'https://constat-tunisie.app/login',
      });

      if (result.data['success'] == true) {
        debugPrint('[EMAIL_SERVICE] ✅ Email acceptation envoyé avec succès');
        
        // Enregistrer l'envoi dans Firestore
        await _logEmailSent(
          email: email,
          type: 'acceptance',
          status: 'sent',
          details: {
            'nom_complet': nomComplet,
            'role': role,
          },
        );
        
        return true;
      } else {
        throw Exception(result.data['error'] ?? 'Erreur inconnue');
      }

    } catch (e) {
      debugPrint('[EMAIL_SERVICE] ❌ Erreur envoi email acceptation: $e');
      
      // Enregistrer l'échec dans Firestore
      await _logEmailSent(
        email: email,
        type: 'acceptance',
        status: 'failed',
        error: e.toString(),
      );
      
      return false;
    }
  }

  /// 📧 Envoyer un email de rejet
  static Future<bool> sendRejectionEmail({
    required String email,
    required String nomComplet,
    required String role,
    required String motifRejet,
  }) async {
    try {
      debugPrint('[EMAIL_SERVICE] 📧 Envoi email rejet à: $email');

      final callable = _functions.httpsCallable('sendRejectionEmail');
      
      final result = await callable.call({
        'email': email,
        'nomComplet': nomComplet,
        'role': role,
        'motifRejet': motifRejet,
        'appName': 'Constat Tunisie',
        'supportEmail': 'support@constat-tunisie.app',
      });

      if (result.data['success'] == true) {
        debugPrint('[EMAIL_SERVICE] ✅ Email rejet envoyé avec succès');
        
        // Enregistrer l'envoi dans Firestore
        await _logEmailSent(
          email: email,
          type: 'rejection',
          status: 'sent',
          details: {
            'nom_complet': nomComplet,
            'role': role,
            'motif_rejet': motifRejet,
          },
        );
        
        return true;
      } else {
        throw Exception(result.data['error'] ?? 'Erreur inconnue');
      }

    } catch (e) {
      debugPrint('[EMAIL_SERVICE] ❌ Erreur envoi email rejet: $e');
      
      // Enregistrer l'échec dans Firestore
      await _logEmailSent(
        email: email,
        type: 'rejection',
        status: 'failed',
        error: e.toString(),
      );
      
      return false;
    }
  }

  /// 📧 Envoyer un email de notification de nouvelle demande aux admins
  static Future<bool> sendNewRequestNotificationToAdmins({
    required String nomComplet,
    required String email,
    required String role,
    required String requestId,
  }) async {
    try {
      debugPrint('[EMAIL_SERVICE] 📧 Notification nouvelle demande aux admins');

      final callable = _functions.httpsCallable('sendNewRequestNotification');
      
      final result = await callable.call({
        'nomComplet': nomComplet,
        'email': email,
        'role': role,
        'requestId': requestId,
        'adminEmail': 'constat.tunisie.app@gmail.com',
        'dashboardUrl': 'https://admin.constat-tunisie.app/requests',
      });

      if (result.data['success'] == true) {
        debugPrint('[EMAIL_SERVICE] ✅ Notification admin envoyée avec succès');
        return true;
      } else {
        throw Exception(result.data['error'] ?? 'Erreur inconnue');
      }

    } catch (e) {
      debugPrint('[EMAIL_SERVICE] ❌ Erreur notification admin: $e');
      return false;
    }
  }

  /// 📝 Enregistrer l'envoi d'email dans Firestore
  static Future<void> _logEmailSent({
    required String email,
    required String type,
    required String status,
    Map<String, dynamic>? details,
    String? error,
  }) async {
    try {
      await _firestore.collection('email_logs').add({
        'email': email,
        'type': type, // 'acceptance', 'rejection', 'notification'
        'status': status, // 'sent', 'failed'
        'details': details ?? {},
        'error': error,
        'sent_at': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[EMAIL_SERVICE] ❌ Erreur log email: $e');
    }
  }

  /// 📊 Obtenir les statistiques d'envoi d'emails
  static Future<Map<String, dynamic>> getEmailStats() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      final querySnapshot = await _firestore
          .collection('email_logs')
          .where('sent_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      final stats = {
        'total_today': querySnapshot.docs.length,
        'sent_today': 0,
        'failed_today': 0,
        'by_type': <String, int>{},
      };

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String;
        final type = data['type'] as String;

        if (status == 'sent') {
          stats['sent_today'] = (stats['sent_today'] as int) + 1;
        } else if (status == 'failed') {
          stats['failed_today'] = (stats['failed_today'] as int) + 1;
        }

        final byType = stats['by_type'] as Map<String, int>;
        byType[type] = (byType[type] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      debugPrint('[EMAIL_SERVICE] ❌ Erreur stats email: $e');
      return {
        'total_today': 0,
        'sent_today': 0,
        'failed_today': 0,
        'by_type': <String, int>{},
      };
    }
  }

  /// 🔄 Réessayer l'envoi d'un email échoué
  static Future<bool> retryFailedEmail(String emailLogId) async {
    try {
      final doc = await _firestore.collection('email_logs').doc(emailLogId).get();
      
      if (!doc.exists) {
        throw Exception('Log email introuvable');
      }

      final data = doc.data()!;
      final email = data['email'] as String;
      final type = data['type'] as String;
      final details = data['details'] as Map<String, dynamic>;

      bool success = false;

      switch (type) {
        case 'acceptance':
          success = await sendAcceptanceEmail(
            email: email,
            nomComplet: details['nom_complet'] ?? '',
            role: details['role'] ?? '',
            motDePasse: details['mot_de_passe'] ?? '',
          );
          break;
        case 'rejection':
          success = await sendRejectionEmail(
            email: email,
            nomComplet: details['nom_complet'] ?? '',
            role: details['role'] ?? '',
            motifRejet: details['motif_rejet'] ?? '',
          );
          break;
      }

      if (success) {
        // Marquer l'ancien log comme réessayé
        await _firestore.collection('email_logs').doc(emailLogId).update({
          'retried_at': FieldValue.serverTimestamp(),
          'retry_success': true,
        });
      }

      return success;
    } catch (e) {
      debugPrint('[EMAIL_SERVICE] ❌ Erreur retry email: $e');
      return false;
    }
  }

  /// 🧪 Tester la configuration email
  static Future<bool> testEmailConfiguration() async {
    try {
      final callable = _functions.httpsCallable('testEmailConfig');
      final result = await callable.call({
        'testEmail': 'constat.tunisie.app@gmail.com',
      });

      return result.data['success'] == true;
    } catch (e) {
      debugPrint('[EMAIL_SERVICE] ❌ Erreur test config: $e');
      return false;
    }
  }
}
