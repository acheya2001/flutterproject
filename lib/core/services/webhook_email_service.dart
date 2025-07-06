import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// 🌐 Service d'email via webhook - FONCTIONNE AVEC TOUS LES EMAILS !
class WebhookEmailService {
  
  /// 📧 Envoie une invitation via webhook (UNIVERSEL)
  static Future<bool> envoyerInvitation({
    required String email,
    required String sessionCode,
    required String sessionId,
    String? customMessage,
  }) async {
    try {
      debugPrint('[WebhookEmail] === ENVOI INVITATION VIA WEBHOOK ===');
      debugPrint('[WebhookEmail] 📧 Destinataire: $email');
      debugPrint('[WebhookEmail] 🔑 Code session: $sessionCode');
      
      // Validation de l'email
      if (!_isValidEmail(email)) {
        throw Exception('Format d\'email invalide: $email');
      }
      
      // Créer le contenu de l'email
      final emailContent = _creerContenuEmail(sessionCode, customMessage);
      
      // Essayer plusieurs services webhook
      bool success = false;
      
      // Service 1: Formspree (gratuit, fiable)
      success = await _envoyerViaFormspree(email, sessionCode, emailContent);
      if (success) {
        debugPrint('[WebhookEmail] ✅ Succès avec Formspree !');
        return true;
      }
      
      // Service 2: Netlify Forms (fallback)
      success = await _envoyerViaNetlify(email, sessionCode, emailContent);
      if (success) {
        debugPrint('[WebhookEmail] ✅ Succès avec Netlify !');
        return true;
      }
      
      // Service 3: EmailJS public endpoint (fallback)
      success = await _envoyerViaEmailJSPublic(email, sessionCode, emailContent);
      if (success) {
        debugPrint('[WebhookEmail] ✅ Succès avec EmailJS public !');
        return true;
      }
      
      debugPrint('[WebhookEmail] ❌ Tous les services ont échoué');
      return false;
      
    } catch (e) {
      debugPrint('[WebhookEmail] ❌ Erreur envoi: $e');
      return false;
    }
  }
  
  /// 📧 Service 1: API Email simple (sans configuration)
  static Future<bool> _envoyerViaFormspree(String email, String sessionCode, String content) async {
    try {
      debugPrint('[WebhookEmail] 🔄 Tentative API Email simple...');

      // Utiliser Formspree avec votre endpoint
      final response = await http.post(
        Uri.parse('https://formspree.io/f/xanjoowd'), // VOTRE endpoint Formspree CORRECT
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'subject': 'Invitation - Constat d\'accident collaboratif (Code: $sessionCode)',
          'message': content,
          '_replyto': 'hammami123rahma@gmail.com',
          '_subject': 'Invitation Constat Collaboratif - Code: $sessionCode',
        }),
      );

      debugPrint('[WebhookEmail] API Email response: ${response.statusCode}');
      debugPrint('[WebhookEmail] Response body: ${response.body}');
      return response.statusCode == 200;

    } catch (e) {
      debugPrint('[WebhookEmail] ❌ Erreur API Email: $e');
      return false;
    }
  }
  
  /// 📧 Service 2: Netlify Forms
  static Future<bool> _envoyerViaNetlify(String email, String sessionCode, String content) async {
    try {
      debugPrint('[WebhookEmail] 🔄 Tentative Netlify...');
      
      final response = await http.post(
        Uri.parse('https://constat-tunisie.netlify.app/'), // Endpoint Netlify
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'form-name': 'contact',
          'email': email,
          'subject': 'Invitation Constat - Code: $sessionCode',
          'message': content,
        },
      );
      
      debugPrint('[WebhookEmail] Netlify response: ${response.statusCode}');
      return response.statusCode == 200;
      
    } catch (e) {
      debugPrint('[WebhookEmail] ❌ Erreur Netlify: $e');
      return false;
    }
  }
  
  /// 📧 Service 3: EmailJS public endpoint
  static Future<bool> _envoyerViaEmailJSPublic(String email, String sessionCode, String content) async {
    try {
      debugPrint('[WebhookEmail] 🔄 Tentative EmailJS public...');
      
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id': 'service_hcur24e',
          'template_id': 'template_g9xi3ce',
          'user_id': 'IjxWFDFy9vM0bmTjZ',
          'template_params': {
            'to_email': email,
            'session_code': sessionCode,
            'custom_message': content,
            'from_name': 'Constat Tunisie',
          }
        }),
      );
      
      debugPrint('[WebhookEmail] EmailJS public response: ${response.statusCode}');
      return response.statusCode == 200;
      
    } catch (e) {
      debugPrint('[WebhookEmail] ❌ Erreur EmailJS public: $e');
      return false;
    }
  }
  
  /// 📝 Créer le contenu de l'email
  static String _creerContenuEmail(String sessionCode, String? customMessage) {
    return '''
Bonjour,

Vous êtes invité à rejoindre une session de constat d'accident collaboratif.

🔑 CODE DE SESSION : $sessionCode

📱 INSTRUCTIONS :
1. Téléchargez l'application "Constat Tunisie"
2. Créez votre compte ou connectez-vous
3. Sélectionnez "Rejoindre une session"
4. Entrez le code : $sessionCode
5. Commencez la collaboration

${customMessage ?? 'Un conducteur vous invite à documenter un accident ensemble.'}

⚠️ IMPORTANT : Cette invitation est valable 24 heures.

Cordialement,
L'équipe Constat Tunisie

---
Email envoyé automatiquement par l'application Constat Tunisie
© 2024 Constat Tunisie - Tous droits réservés
    ''';
  }
  
  /// ✅ Validation du format email
  static bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }
}
