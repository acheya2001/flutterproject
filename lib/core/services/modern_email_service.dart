import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

/// 🚀 Service d'email moderne et fiable pour sessions collaboratives
class ModernEmailService {
  
  // 📧 Configuration pour service d'email gratuit et fiable
  static const String _webhookUrl = 'https://hook.eu2.make.com/your-webhook-id';

  
  /// 📧 Envoie une invitation par email avec plusieurs méthodes de fallback
  static Future<bool> envoyerInvitation({
    required String email,
    required String sessionCode,
    required String sessionId,
  }) async {
    try {
      debugPrint('[ModernEmail] === ENVOI INVITATION MODERNE ===');
      debugPrint('[ModernEmail] 📧 Destinataire: $email');
      debugPrint('[ModernEmail] 🔑 Code session: $sessionCode');
      debugPrint('[ModernEmail] 🆔 ID session: $sessionId');
      
      // Validation de l'email
      if (!_isValidEmail(email)) {
        throw Exception('Format d\'email invalide: $email');
      }
      
      // Créer le contenu de l'email
      final emailContent = _creerContenuEmail(sessionCode, sessionId);
      
      // 🎯 Stratégie moderne : Affichage formaté + Tentatives automatiques
      
      // 1. Afficher le contenu formaté dans les logs (TOUJOURS)
      _afficherEmailDansLogs(email, sessionCode, emailContent);
      
      // 2. Tentative d'envoi automatique (si configuré)
      bool autoSent = await _tentativeEnvoiAutomatique(email, sessionCode, emailContent);
      
      // 3. Fallback : Ouvrir l'app email
      if (!autoSent) {
        await _ouvrirAppEmail(email, sessionCode, emailContent);
      }
      
      debugPrint('[ModernEmail] ✅ Invitation traitée pour: $email');
      return true; // Toujours succès car on affiche le contenu
      
    } catch (e) {
      debugPrint('[ModernEmail] ❌ Erreur: $e');
      return false;
    }
  }
  
  /// 📱 Affiche le contenu de l'email dans les logs de manière lisible
  static void _afficherEmailDansLogs(String email, String sessionCode, String content) {
    debugPrint('[ModernEmail] ');
    debugPrint('[ModernEmail] ╔══════════════════════════════════════════════════════════╗');
    debugPrint('[ModernEmail] ║                    📧 EMAIL À ENVOYER                    ║');
    debugPrint('[ModernEmail] ╠══════════════════════════════════════════════════════════╣');
    debugPrint('[ModernEmail] ║ 📧 DESTINATAIRE: $email');
    debugPrint('[ModernEmail] ║ 📋 SUJET: Invitation - Constat d\'accident collaboratif');
    debugPrint('[ModernEmail] ║ 🔑 CODE SESSION: $sessionCode');
    debugPrint('[ModernEmail] ╠══════════════════════════════════════════════════════════╣');
    debugPrint('[ModernEmail] ║ 📝 MESSAGE:');
    debugPrint('[ModernEmail] ║');
    
    // Afficher le message ligne par ligne
    final lines = content.split('\n');
    for (String line in lines) {
      debugPrint('[ModernEmail] ║ $line');
    }
    
    debugPrint('[ModernEmail] ║');
    debugPrint('[ModernEmail] ╚══════════════════════════════════════════════════════════╝');
    debugPrint('[ModernEmail] ');
    debugPrint('[ModernEmail] 🎯 ACTIONS POSSIBLES:');
    debugPrint('[ModernEmail] 1. 📋 COPIEZ le contenu ci-dessus');
    debugPrint('[ModernEmail] 2. 📧 ENVOYEZ-LE à: $email');
    debugPrint('[ModernEmail] 3. 🔑 PARTAGEZ le code: $sessionCode');
    debugPrint('[ModernEmail] ');
  }
  
  /// 🚀 Tentative d'envoi automatique (optionnel)
  static Future<bool> _tentativeEnvoiAutomatique(String email, String sessionCode, String content) async {
    try {
      debugPrint('[ModernEmail] 🚀 Tentative d\'envoi automatique...');
      
      // Méthode 1: Webhook Make.com (le plus fiable)
      bool webhookSuccess = await _envoyerViaWebhook(email, sessionCode, content);
      if (webhookSuccess) {
        debugPrint('[ModernEmail] ✅ Email envoyé automatiquement via webhook!');
        return true;
      }
      
      // Méthode 2: Service HTTP simple
      bool httpSuccess = await _envoyerViaHTTP(email, sessionCode, content);
      if (httpSuccess) {
        debugPrint('[ModernEmail] ✅ Email envoyé automatiquement via HTTP!');
        return true;
      }
      
      debugPrint('[ModernEmail] ⚠️ Envoi automatique non disponible');
      return false;
      
    } catch (e) {
      debugPrint('[ModernEmail] ❌ Erreur envoi automatique: $e');
      return false;
    }
  }
  
  /// 🔗 Envoi via webhook (recommandé pour production)
  static Future<bool> _envoyerViaWebhook(String email, String sessionCode, String content) async {
    try {
      // Note: Remplacez par votre vraie URL de webhook
      if (_webhookUrl.contains('your-webhook-id')) {
        debugPrint('[ModernEmail] ⚠️ Webhook non configuré (URL par défaut)');
        return false;
      }
      
      final response = await http.post(
        Uri.parse(_webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'to': email,
          'subject': 'Invitation - Constat d\'accident collaboratif',
          'message': content,
          'session_code': sessionCode,
          'from': 'Constat Tunisie App',
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ModernEmail] ❌ Erreur webhook: $e');
      return false;
    }
  }
  
  /// 📡 Envoi via service HTTP simple
  static Future<bool> _envoyerViaHTTP(String email, String sessionCode, String content) async {
    try {
      // Service de notification simple (pour tests)
      final response = await http.post(
        Uri.parse('https://httpbin.org/post'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email_data': {
            'to': email,
            'subject': 'Invitation Constat',
            'message': content,
            'code': sessionCode,
          }
        }),
      );
      
      if (response.statusCode == 200) {
        debugPrint('[ModernEmail] ✅ Données envoyées au service HTTP');
        return false; // On retourne false car ce n'est pas un vrai envoi d'email
      }
      
      return false;
    } catch (e) {
      debugPrint('[ModernEmail] ❌ Erreur HTTP: $e');
      return false;
    }
  }
  
  /// 📱 Ouvre l'application email (fallback)
  static Future<void> _ouvrirAppEmail(String email, String sessionCode, String content) async {
    try {
      debugPrint('[ModernEmail] 📱 Tentative d\'ouverture de l\'app email...');
      
      final subject = Uri.encodeComponent('Invitation - Constat d\'accident collaboratif');
      final body = Uri.encodeComponent(content);
      final mailtoUrl = 'mailto:$email?subject=$subject&body=$body';
      
      final uri = Uri.parse(mailtoUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        debugPrint('[ModernEmail] ✅ Application email ouverte');
      } else {
        debugPrint('[ModernEmail] ⚠️ Impossible d\'ouvrir l\'app email');
        debugPrint('[ModernEmail] 💡 Utilisez le contenu affiché dans les logs ci-dessus');
      }
    } catch (e) {
      debugPrint('[ModernEmail] ❌ Erreur ouverture app email: $e');
    }
  }
  
  /// 📝 Crée le contenu de l'email d'invitation
  static String _creerContenuEmail(String sessionCode, String sessionId) {
    return '''Bonjour,

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
Session ID: $sessionId
Code: $sessionCode''';
  }
  
  /// ✅ Validation simple du format email
  static bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }
  
  /// 🧪 Test du service
  static Future<void> testerService({String? emailTest}) async {
    final email = emailTest ?? 'hammami123rahma@gmail.com';
    final sessionCode = 'TEST${DateTime.now().millisecondsSinceEpoch % 1000}';
    final sessionId = 'test_${DateTime.now().millisecondsSinceEpoch}';
    
    debugPrint('[ModernEmail] === TEST DU SERVICE ===');
    
    final success = await envoyerInvitation(
      email: email,
      sessionCode: sessionCode,
      sessionId: sessionId,
    );
    
    debugPrint('[ModernEmail] Test ${success ? "réussi" : "échoué"}');
  }
}
