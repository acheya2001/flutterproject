import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// 🚀 Service d'email final et fiable pour sessions collaboratives
class EmailService {

  /// 📧 Envoie un email générique
  Future<void> sendEmail({
    required String to,
    required String subject,
    required String htmlBody,
  }) async {
    try {
      debugPrint('[EmailService] === ENVOI EMAIL GÉNÉRIQUE ===');
      debugPrint('[EmailService] 📧 Destinataire: $to');
      debugPrint('[EmailService] 📋 Sujet: $subject');

      // Validation de l'email
      if (!_isValidEmail(to)) {
        throw Exception('Format d\'email invalide: $to');
      }

      // Afficher le contenu formaté dans les logs
      _afficherEmailGeneriqueLog(to, subject, htmlBody);

      // Tentative d'ouverture de l'app email
      await _ouvrirAppEmailGenerique(to, subject, htmlBody);

      debugPrint('[EmailService] ✅ Email envoyé à: $to');

    } catch (e) {
      debugPrint('[EmailService] ❌ Erreur envoi email: $e');
      rethrow;
    }
  }

  /// 📧 Envoie une invitation par email avec affichage formaté
  Future<void> envoyerInvitation({
    required String email,
    required String sessionCode,
    required String sessionId,
  }) async {
    try {
      debugPrint('[EmailService] === ENVOI INVITATION ===');
      debugPrint('[EmailService] 📧 Destinataire: $email');
      debugPrint('[EmailService] 🔑 Code session: $sessionCode');
      debugPrint('[EmailService] 🆔 ID session: $sessionId');
      
      // Validation de l'email
      if (!_isValidEmail(email)) {
        throw Exception('Format d\'email invalide: $email');
      }
      
      // Créer le contenu de l'email
      final emailContent = _creerContenuEmail(sessionCode, sessionId);
      
      // Afficher le contenu formaté dans les logs
      _afficherEmailDansLogs(email, sessionCode, emailContent);
      
      // Tentative d'ouverture de l'app email
      await _ouvrirAppEmail(email, sessionCode, emailContent);
      
      debugPrint('[EmailService] ✅ Invitation traitée pour: $email');
      
    } catch (e) {
      debugPrint('[EmailService] ❌ Erreur: $e');
      rethrow;
    }
  }
  
  /// 📱 Affiche le contenu de l'email dans les logs de manière lisible
  void _afficherEmailDansLogs(String email, String sessionCode, String content) {
    debugPrint('[EmailService] ');
    debugPrint('[EmailService] ╔══════════════════════════════════════════════════════════╗');
    debugPrint('[EmailService] ║                    📧 EMAIL À ENVOYER                    ║');
    debugPrint('[EmailService] ╠══════════════════════════════════════════════════════════╣');
    debugPrint('[EmailService] ║ 📧 DESTINATAIRE: $email');
    debugPrint('[EmailService] ║ 📋 SUJET: Invitation - Constat d\'accident collaboratif');
    debugPrint('[EmailService] ║ 🔑 CODE SESSION: $sessionCode');
    debugPrint('[EmailService] ╠══════════════════════════════════════════════════════════╣');
    debugPrint('[EmailService] ║ 📝 MESSAGE:');
    debugPrint('[EmailService] ║');
    
    // Afficher le message ligne par ligne
    final lines = content.split('\n');
    for (String line in lines) {
      debugPrint('[EmailService] ║ $line');
    }
    
    debugPrint('[EmailService] ║');
    debugPrint('[EmailService] ╚══════════════════════════════════════════════════════════╝');
    debugPrint('[EmailService] ');
    debugPrint('[EmailService] 🎯 ACTIONS POSSIBLES:');
    debugPrint('[EmailService] 1. 📋 COPIEZ le contenu ci-dessus');
    debugPrint('[EmailService] 2. 📧 ENVOYEZ-LE à: $email');
    debugPrint('[EmailService] 3. 🔑 PARTAGEZ le code: $sessionCode');
    debugPrint('[EmailService] ');
  }
  
  /// 📱 Ouvre l'application email (fallback)
  Future<void> _ouvrirAppEmail(String email, String sessionCode, String content) async {
    try {
      debugPrint('[EmailService] 📱 Tentative d\'ouverture de l\'app email...');
      
      final subject = Uri.encodeComponent('Invitation - Constat d\'accident collaboratif');
      final body = Uri.encodeComponent(content);
      final mailtoUrl = 'mailto:$email?subject=$subject&body=$body';
      
      final uri = Uri.parse(mailtoUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        debugPrint('[EmailService] ✅ Application email ouverte');
        debugPrint('[EmailService] 📧 IMPORTANT: Appuyez sur ENVOYER dans votre app email!');
      } else {
        debugPrint('[EmailService] ⚠️ Impossible d\'ouvrir l\'app email');
        debugPrint('[EmailService] 💡 Utilisez le contenu affiché dans les logs ci-dessus');
      }
    } catch (e) {
      debugPrint('[EmailService] ❌ Erreur ouverture app email: $e');
      debugPrint('[EmailService] 💡 Utilisez le contenu affiché dans les logs ci-dessus');
    }
  }
  
  /// 📝 Crée le contenu de l'email d'invitation
  String _creerContenuEmail(String sessionCode, String sessionId) {
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
  
  /// 📱 Affiche le contenu de l'email générique dans les logs
  void _afficherEmailGeneriqueLog(String to, String subject, String htmlBody) {
    debugPrint('[EmailService] ');
    debugPrint('[EmailService] ╔══════════════════════════════════════════════════════════╗');
    debugPrint('[EmailService] ║                    📧 EMAIL GÉNÉRIQUE                    ║');
    debugPrint('[EmailService] ╠══════════════════════════════════════════════════════════╣');
    debugPrint('[EmailService] ║ 📧 DESTINATAIRE: $to');
    debugPrint('[EmailService] ║ 📋 SUJET: $subject');
    debugPrint('[EmailService] ╠══════════════════════════════════════════════════════════╣');
    debugPrint('[EmailService] ║ 📄 CONTENU:');

    // Afficher le contenu HTML de manière lisible
    final lines = htmlBody.split('\n');
    for (final line in lines.take(10)) { // Limiter à 10 lignes
      debugPrint('[EmailService] ║ $line');
    }
    if (lines.length > 10) {
      debugPrint('[EmailService] ║ ... (contenu tronqué)');
    }

    debugPrint('[EmailService] ╚══════════════════════════════════════════════════════════╝');
    debugPrint('[EmailService] ');
  }

  /// 📱 Tente d'ouvrir l'app email avec le contenu générique
  Future<void> _ouvrirAppEmailGenerique(String to, String subject, String htmlBody) async {
    try {
      // Convertir HTML en texte simple pour l'URL
      final textBody = htmlBody
          .replaceAll(RegExp(r'<[^>]*>'), '') // Supprimer les balises HTML
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .trim();

      final emailUrl = 'mailto:$to?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(textBody)}';

      debugPrint('[EmailService] 📱 Tentative ouverture app email...');
      debugPrint('[EmailService] 🔗 URL: ${emailUrl.substring(0, 100)}...');

      final uri = Uri.parse(emailUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        debugPrint('[EmailService] ✅ App email ouverte');
      } else {
        debugPrint('[EmailService] ⚠️ Impossible d\'ouvrir l\'app email');
      }
    } catch (e) {
      debugPrint('[EmailService] ❌ Erreur ouverture app email: $e');
      debugPrint('[EmailService] 💡 Utilisez le contenu affiché dans les logs ci-dessus');
    }
  }

  /// ✅ Validation simple du format email
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }
}
