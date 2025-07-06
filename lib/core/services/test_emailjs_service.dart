import 'package:flutter/foundation.dart';
import 'package:emailjs/emailjs.dart' as emailjs;

/// 🧪 Service de test EmailJS simple
class TestEmailJSService {
  
  // VOS CLÉS EMAILJS
  static const String _serviceId = 'service_hcur24e';
  static const String _templateId = 'template_g9xi3ce';
  static const String _publicKey = 'IjxWFDFy9vM0bmTjZ';
  
  /// 🧪 Test simple EmailJS
  static Future<bool> testEmailJS({
    required String email,
  }) async {
    try {
      debugPrint('[TestEmailJS] === TEST EMAILJS SIMPLE ===');
      debugPrint('[TestEmailJS] 📧 Destinataire: $email');
      debugPrint('[TestEmailJS] 🔑 Service ID: $_serviceId');
      debugPrint('[TestEmailJS] 📄 Template ID: $_templateId');
      debugPrint('[TestEmailJS] 🔐 Public Key: $_publicKey');
      
      // Paramètres simples pour le test
      final templateParams = {
        'to_email': email,
        'session_code': 'TEST123',
        'custom_message': 'Test EmailJS - Si vous recevez cet email, EmailJS fonctionne !',
        'from_name': 'Constat Tunisie Test',
      };
      
      debugPrint('[TestEmailJS] 📤 Envoi en cours...');
      
      // Envoi via EmailJS
      await emailjs.send(
        _serviceId,
        _templateId,
        templateParams,
        emailjs.Options(
          publicKey: _publicKey,
          limitRate: const emailjs.LimitRate(
            id: 'test',
            throttle: 10000,
          ),
        ),
      );
      
      debugPrint('[TestEmailJS] ✅ EMAIL ENVOYÉ AVEC SUCCÈS !');
      return true;
      
    } catch (e) {
      debugPrint('[TestEmailJS] ❌ ERREUR EMAILJS: $e');
      debugPrint('[TestEmailJS] Type d\'erreur: ${e.runtimeType}');
      return false;
    }
  }
}
