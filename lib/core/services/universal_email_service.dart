import 'package:flutter/foundation.dart';
import 'package:emailjs/emailjs.dart' as emailjs;

/// 🌍 Service d'email universel - Peut envoyer à N'IMPORTE QUEL email !
class UniversalEmailService {
  
  // Configuration EmailJS - VOS CLÉS RÉELLES
  static const String _serviceId = 'service_hcur24e';
  static const String _templateId = 'template_g9xi3ce';
  static const String _publicKey = 'IjxWFDFy9vM0bmTjZ';
  
  /// 📧 Envoie une invitation à N'IMPORTE QUEL email
  static Future<bool> envoyerInvitation({
    required String email,
    required String sessionCode,
    required String sessionId,
    String? customMessage,
  }) async {
    try {
      debugPrint('[UniversalEmail] === ENVOI INVITATION UNIVERSELLE ===');
      debugPrint('[UniversalEmail] 📧 Destinataire: $email');
      debugPrint('[UniversalEmail] 🔑 Code session: $sessionCode');
      debugPrint('[UniversalEmail] 🆔 ID session: $sessionId');
      
      // Validation de l'email
      if (!_isValidEmail(email)) {
        throw Exception('Format d\'email invalide: $email');
      }
      
      // Paramètres pour le template EmailJS
      final templateParams = {
        'to_email': email,
        'session_code': sessionCode,
        'session_id': sessionId,
        'custom_message': customMessage ?? 'Un conducteur vous invite à rejoindre une session de constat.',
        'app_name': 'Constat Tunisie',
        'from_name': 'Constat Tunisie',
      };
      
      // Envoi via EmailJS
      await emailjs.send(
        _serviceId,
        _templateId,
        templateParams,
        emailjs.Options(
          publicKey: _publicKey,
          limitRate: const emailjs.LimitRate(
            id: 'app',
            throttle: 10000,
          ),
        ),
      );
      
      debugPrint('[UniversalEmail] ✅ Email envoyé avec succès via EmailJS !');
      return true;
      
    } catch (e) {
      debugPrint('[UniversalEmail] ❌ Erreur envoi email: $e');
      return false;
    }
  }
  
  /// 📧 Envoie un email simple
  static Future<bool> sendEmail({
    required String to,
    required String subject,
    required String message,
  }) async {
    try {
      debugPrint('[UniversalEmail] === ENVOI EMAIL SIMPLE ===');
      debugPrint('[UniversalEmail] 📧 Destinataire: $to');
      debugPrint('[UniversalEmail] 🏷️ Sujet: $subject');
      
      if (!_isValidEmail(to)) {
        throw Exception('Format d\'email invalide: $to');
      }
      
      final templateParams = {
        'to_email': to,
        'subject': subject,
        'message': message,
        'from_name': 'Constat Tunisie',
      };
      
      await emailjs.send(
        _serviceId,
        'template_simple', // Template pour emails simples
        templateParams,
        emailjs.Options(
          publicKey: _publicKey,
          limitRate: const emailjs.LimitRate(
            id: 'app',
            throttle: 10000,
          ),
        ),
      );
      
      debugPrint('[UniversalEmail] ✅ Email simple envoyé avec succès !');
      return true;
      
    } catch (e) {
      debugPrint('[UniversalEmail] ❌ Erreur envoi email simple: $e');
      return false;
    }
  }
  
  /// ✅ Validation du format email
  static bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }
  
  /// 🔧 Configuration des clés EmailJS
  static void configurer({
    required String serviceId,
    required String templateId,
    required String publicKey,
  }) {
    // Cette méthode permettra de configurer les clés dynamiquement
    debugPrint('[UniversalEmail] Configuration EmailJS mise à jour');
  }
}
