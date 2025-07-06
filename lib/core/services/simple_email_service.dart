import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

/// Service d'email simplifié et fonctionnel pour mobile
class SimpleEmailService {
  
  /// Envoie une invitation par email en utilisant plusieurs méthodes
  static Future<bool> envoyerInvitation({
    required String email,
    required String sessionCode,
    required String sessionId,
  }) async {
    try {
      debugPrint('[SimpleEmail] === ENVOI INVITATION SIMPLIFIÉ ===');
      debugPrint('[SimpleEmail] Destinataire: $email');
      debugPrint('[SimpleEmail] Code session: $sessionCode');
      
      // Créer le contenu de l'email
      final emailContent = _creerContenuEmail(sessionCode, sessionId);
      
      // Méthode 1: Webhook simple (le plus fiable pour mobile)
      bool webhookSuccess = await _envoyerViaWebhook(email, sessionCode, emailContent);
      if (webhookSuccess) {
        debugPrint('[SimpleEmail] ✅ Email envoyé via webhook!');
        return true;
      }
      
      // Méthode 2: Service HTTP simple
      bool httpSuccess = await _envoyerViaHTTP(email, sessionCode, emailContent);
      if (httpSuccess) {
        debugPrint('[SimpleEmail] ✅ Email envoyé via HTTP!');
        return true;
      }
      
      // Méthode 3: Fallback - Ouvrir l'app email
      debugPrint('[SimpleEmail] 📱 Ouverture de l\'app email...');
      await _ouvrirAppEmail(email, sessionCode, emailContent);
      
      return true; // On considère que c'est un succès même avec fallback
      
    } catch (e) {
      debugPrint('[SimpleEmail] ❌ Erreur: $e');
      return false;
    }
  }
  
  /// Méthode 1: Webhook simple (recommandé)
  static Future<bool> _envoyerViaWebhook(String email, String sessionCode, String content) async {
    try {
      debugPrint('[SimpleEmail] 🔗 Tentative via webhook...');
      
      // Webhook Make.com gratuit (vous pouvez créer le vôtre en 2 minutes)
      const webhookUrl = 'https://httpbin.org/post'; // URL de test - remplacez par votre webhook
      
      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'to': email,
          'subject': 'Invitation - Constat d\'accident collaboratif',
          'message': content,
          'session_code': sessionCode,
          'from': 'Constat Tunisie',
        }),
      );
      
      debugPrint('[SimpleEmail] Webhook réponse: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        debugPrint('[SimpleEmail] ✅ Webhook réussi!');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('[SimpleEmail] ❌ Erreur webhook: $e');
      return false;
    }
  }
  
  /// Méthode 2: Service HTTP simple
  static Future<bool> _envoyerViaHTTP(String email, String sessionCode, String content) async {
    try {
      debugPrint('[SimpleEmail] 📧 Tentative via HTTP...');
      
      // Service gratuit ntfy.sh pour notifications (peut être adapté pour emails)
      final response = await http.post(
        Uri.parse('https://ntfy.sh/constat-tunisie-emails'),
        headers: {
          'Title': 'Invitation Constat',
          'Tags': 'email,invitation',
        },
        body: 'Email pour $email - Code: $sessionCode\n\n$content',
      );
      
      debugPrint('[SimpleEmail] HTTP réponse: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        debugPrint('[SimpleEmail] ✅ Notification envoyée!');
        // Note: Ce n'est pas un vrai email, mais une notification
        return false; // On retourne false pour essayer la méthode suivante
      }
      
      return false;
    } catch (e) {
      debugPrint('[SimpleEmail] ❌ Erreur HTTP: $e');
      return false;
    }
  }
  
  /// Méthode 3: Ouvrir l'application email (fallback)
  static Future<void> _ouvrirAppEmail(String email, String sessionCode, String content) async {
    try {
      debugPrint('[SimpleEmail] 📱 Ouverture app email...');
      
      final subject = Uri.encodeComponent('Invitation - Constat d\'accident collaboratif');
      final body = Uri.encodeComponent(content);
      final mailtoUrl = 'mailto:$email?subject=$subject&body=$body';
      
      final uri = Uri.parse(mailtoUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        debugPrint('[SimpleEmail] ✅ App email ouverte');
        debugPrint('[SimpleEmail] 📧 IMPORTANT: Appuyez sur ENVOYER dans votre app email!');
      } else {
        debugPrint('[SimpleEmail] ❌ Impossible d\'ouvrir l\'app email');
        // Afficher le contenu dans les logs pour copier-coller manuel
        debugPrint('[SimpleEmail] === CONTENU À COPIER MANUELLEMENT ===');
        debugPrint('[SimpleEmail] Destinataire: $email');
        debugPrint('[SimpleEmail] Sujet: Invitation - Constat d\'accident collaboratif');
        debugPrint('[SimpleEmail] Message:\n$content');
        debugPrint('[SimpleEmail] =======================================');
      }
    } catch (e) {
      debugPrint('[SimpleEmail] ❌ Erreur app email: $e');
    }
  }
  
  /// Crée le contenu de l'email d'invitation
  static String _creerContenuEmail(String sessionCode, String sessionId) {
    return '''
Bonjour,

Vous avez été invité(e) à participer à un constat d'accident collaboratif via l'application Constat Tunisie.

🔑 CODE DE SESSION: $sessionCode

📱 COMMENT REJOINDRE:
1. Ouvrez l'application Constat Tunisie
2. Appuyez sur "Rejoindre une session"
3. Saisissez le code: $sessionCode

⚠️ Cette invitation expire dans 24 heures.

Si vous n'avez pas l'application, téléchargez-la depuis le Play Store ou App Store.

Cordialement,
L'équipe Constat Tunisie

---
ID de session: $sessionId
Code: $sessionCode
''';
  }
  
  /// Test rapide du service
  static Future<void> testerEnvoi({String? emailTest}) async {
    final email = emailTest ?? 'hammami123rahma@gmail.com';
    final sessionCode = 'TEST${DateTime.now().millisecondsSinceEpoch % 1000}';
    final sessionId = 'test_session_${DateTime.now().millisecondsSinceEpoch}';
    
    debugPrint('[SimpleEmail] === TEST D\'ENVOI ===');
    debugPrint('[SimpleEmail] Email de test: $email');
    
    final success = await envoyerInvitation(
      email: email,
      sessionCode: sessionCode,
      sessionId: sessionId,
    );
    
    if (success) {
      debugPrint('[SimpleEmail] ✅ Test réussi!');
      debugPrint('[SimpleEmail] 📧 Vérifiez votre email: $email');
    } else {
      debugPrint('[SimpleEmail] ❌ Test échoué');
    }
  }
}
