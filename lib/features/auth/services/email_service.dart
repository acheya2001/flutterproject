import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

/// 📧 Service d'envoi d'emails via Gmail API
class EmailService {
  // Configuration Gmail OAuth2
  static const String _clientId = '1059917372502-bcja6qd5feh9rpndg3klveh1pcihruj5.apps.googleusercontent.com';
  static const String _refreshToken = '1//04fqCR47aG8PuCgYIARAAGAQSNwF-L9IrbmVfT1Ip925nf40rYtGez0sw_fJH341WZM9UHDhdWnkShe5AONoFyep4P6lS2E1VsFw';
  static const String _senderEmail = 'constat.tunisie.app@gmail.com';
  
  // URLs de l'API Gmail
  static const String _tokenUrl = 'https://oauth2.googleapis.com/token';
  static const String _gmailApiUrl = 'https://gmail.googleapis.com/gmail/v1/users/me/messages/send';

  /// 🔑 Obtenir un access token via refresh token
  static Future<String?> _getAccessToken() async {
    try {
      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _clientId,
          'refresh_token': _refreshToken,
          'grant_type': 'refresh_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['access_token'];
      } else {
        debugPrint('❌ Erreur obtention access token: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Exception obtention access token: $e');
      return null;
    }
  }

  /// 📧 Envoyer un email via Gmail API
  static Future<bool> sendEmail({
    required String to,
    required String subject,
    required String htmlBody,
    String? textBody,
  }) async {
    try {
      // Obtenir l'access token
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        debugPrint('❌ Impossible d\'obtenir l\'access token');
        return false;
      }

      // Créer le message email au format RFC 2822
      final emailMessage = _createEmailMessage(
        to: to,
        subject: subject,
        htmlBody: htmlBody,
        textBody: textBody,
      );

      // Encoder en base64url
      final encodedMessage = base64Url.encode(utf8.encode(emailMessage));

      // Envoyer via Gmail API
      final response = await http.post(
        Uri.parse(_gmailApiUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'raw': encodedMessage,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Email envoyé avec succès à $to');
        return true;
      } else {
        debugPrint('❌ Erreur envoi email: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception envoi email: $e');
      return false;
    }
  }

  /// 📝 Créer le message email au format RFC 2822
  static String _createEmailMessage({
    required String to,
    required String subject,
    required String htmlBody,
    String? textBody,
  }) {
    final boundary = 'boundary_${DateTime.now().millisecondsSinceEpoch}';
    
    final message = StringBuffer();
    
    // En-têtes
    message.writeln('From: Constat Tunisie <$_senderEmail>');
    message.writeln('To: $to');
    message.writeln('Subject: $subject');
    message.writeln('MIME-Version: 1.0');
    message.writeln('Content-Type: multipart/alternative; boundary="$boundary"');
    message.writeln();
    
    // Partie texte (si fournie)
    if (textBody != null) {
      message.writeln('--$boundary');
      message.writeln('Content-Type: text/plain; charset=UTF-8');
      message.writeln('Content-Transfer-Encoding: quoted-printable');
      message.writeln();
      message.writeln(textBody);
      message.writeln();
    }
    
    // Partie HTML
    message.writeln('--$boundary');
    message.writeln('Content-Type: text/html; charset=UTF-8');
    message.writeln('Content-Transfer-Encoding: quoted-printable');
    message.writeln();
    message.writeln(htmlBody);
    message.writeln();
    
    // Fin du message
    message.writeln('--$boundary--');
    
    return message.toString();
  }

  /// 📧 Envoyer un email de notification de compte approuvé
  static Future<bool> sendAccountApprovedEmail({
    required String to,
    required String userName,
    required String userType,
  }) async {
    print('🔍 DEBUG: sendAccountApprovedEmail - to: $to, userName: $userName, userType: $userType');
    final subject = '✅ Votre compte Constat Tunisie a été approuvé !';
    
    final htmlBody = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Compte Approuvé</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #4CAF50, #45a049); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .success-icon { font-size: 48px; margin-bottom: 20px; }
        .button { display: inline-block; background: #4CAF50; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
        .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="success-icon">✅</div>
            <h1>Félicitations !</h1>
            <p>Votre compte professionnel a été approuvé</p>
        </div>
        
        <div class="content">
            <h2>Bonjour $userName,</h2>
            
            <p>Excellente nouvelle ! Votre demande de compte <strong>${userType == 'assureur' ? 'Agent d\'Assurance' : 'Expert'}</strong> sur la plateforme Constat Tunisie a été approuvée par nos administrateurs.</p>
            
            <p><strong>Vous pouvez maintenant :</strong></p>
            <ul>
                <li>✅ Vous connecter à votre compte</li>
                <li>✅ Accéder à toutes les fonctionnalités professionnelles</li>
                <li>✅ Gérer vos dossiers et clients</li>
                <li>✅ Collaborer avec les autres professionnels</li>
            </ul>
            
            <div style="text-align: center;">
                <a href="#" class="button">Se connecter maintenant</a>
            </div>
            
            <p><strong>Informations importantes :</strong></p>
            <ul>
                <li>Votre compte est maintenant actif</li>
                <li>Vous avez accès aux permissions de base de votre rôle</li>
                <li>En cas de problème, contactez notre support</li>
            </ul>
            
            <p>Merci de faire confiance à Constat Tunisie pour vos activités professionnelles.</p>
            
            <p>Cordialement,<br>
            <strong>L'équipe Constat Tunisie</strong></p>
        </div>
        
        <div class="footer">
            <p>Cet email a été envoyé automatiquement. Merci de ne pas y répondre.</p>
            <p>© 2024 Constat Tunisie - Tous droits réservés</p>
        </div>
    </div>
</body>
</html>
    ''';

    final textBody = '''
Félicitations !

Bonjour $userName,

Votre demande de compte ${userType == 'assureur' ? 'Agent d\'Assurance' : 'Expert'} sur Constat Tunisie a été approuvée.

Vous pouvez maintenant vous connecter et accéder à toutes les fonctionnalités professionnelles.

Cordialement,
L'équipe Constat Tunisie
    ''';

    print('🔍 DEBUG: Appel sendEmail avec sujet: $subject');
    final result = await sendEmail(
      to: to,
      subject: subject,
      htmlBody: htmlBody,
      textBody: textBody,
    );
    print(result ? '✅ DEBUG: sendAccountApprovedEmail réussi' : '❌ DEBUG: sendAccountApprovedEmail échoué');
    return result;
  }

  /// 📧 Envoyer un email de notification de compte rejeté
  static Future<bool> sendAccountRejectedEmail({
    required String to,
    required String userName,
    required String userType,
    required String reason,
  }) async {
    final subject = '❌ Votre demande de compte Constat Tunisie';
    
    final htmlBody = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Demande de Compte</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #f44336, #d32f2f); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .warning-icon { font-size: 48px; margin-bottom: 20px; }
        .reason-box { background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .button { display: inline-block; background: #2196F3; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
        .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="warning-icon">⚠️</div>
            <h1>Demande de Compte</h1>
            <p>Information concernant votre demande</p>
        </div>
        
        <div class="content">
            <h2>Bonjour $userName,</h2>
            
            <p>Nous avons examiné votre demande de compte <strong>${userType == 'assureur' ? 'Agent d\'Assurance' : 'Expert'}</strong> sur la plateforme Constat Tunisie.</p>
            
            <p>Malheureusement, nous ne pouvons pas approuver votre demande pour la raison suivante :</p>
            
            <div class="reason-box">
                <strong>Raison :</strong> $reason
            </div>
            
            <p><strong>Que faire maintenant ?</strong></p>
            <ul>
                <li>📝 Vérifiez que tous vos documents sont valides et lisibles</li>
                <li>📞 Contactez notre support pour plus d'informations</li>
                <li>🔄 Vous pouvez soumettre une nouvelle demande après correction</li>
            </ul>
            
            <div style="text-align: center;">
                <a href="#" class="button">Contacter le Support</a>
            </div>
            
            <p>Nous restons à votre disposition pour vous aider à résoudre ce problème.</p>
            
            <p>Cordialement,<br>
            <strong>L'équipe Constat Tunisie</strong></p>
        </div>
        
        <div class="footer">
            <p>Cet email a été envoyé automatiquement. Merci de ne pas y répondre.</p>
            <p>© 2024 Constat Tunisie - Tous droits réservés</p>
        </div>
    </div>
</body>
</html>
    ''';

    final textBody = '''
Bonjour $userName,

Votre demande de compte ${userType == 'assureur' ? 'Agent d\'Assurance' : 'Expert'} sur Constat Tunisie n'a pas pu être approuvée.

Raison : $reason

Vous pouvez contacter notre support ou soumettre une nouvelle demande après correction.

Cordialement,
L'équipe Constat Tunisie
    ''';

    return await sendEmail(
      to: to,
      subject: subject,
      htmlBody: htmlBody,
      textBody: textBody,
    );
  }

  /// 📧 Envoyer un email de notification aux admins pour nouvelle demande
  static Future<bool> sendNewRequestNotificationToAdmins({
    required String applicantName,
    required String applicantEmail,
    required String userType,
    required List<String> adminEmails,
  }) async {
    final subject = '🆕 Nouvelle demande de compte professionnel - Constat Tunisie';
    
    final htmlBody = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nouvelle Demande</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #2196F3, #1976D2); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .info-icon { font-size: 48px; margin-bottom: 20px; }
        .info-box { background: white; border: 1px solid #ddd; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .button { display: inline-block; background: #4CAF50; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
        .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="info-icon">🆕</div>
            <h1>Nouvelle Demande</h1>
            <p>Demande de compte professionnel en attente</p>
        </div>
        
        <div class="content">
            <h2>Cher Administrateur,</h2>
            
            <p>Une nouvelle demande de compte professionnel a été soumise sur la plateforme Constat Tunisie et nécessite votre validation.</p>
            
            <div class="info-box">
                <h3>📋 Détails de la demande :</h3>
                <ul>
                    <li><strong>Nom :</strong> $applicantName</li>
                    <li><strong>Email :</strong> $applicantEmail</li>
                    <li><strong>Type :</strong> ${userType == 'assureur' ? 'Agent d\'Assurance' : 'Expert'}</li>
                    <li><strong>Date :</strong> ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}</li>
                </ul>
            </div>
            
            <p><strong>Actions requises :</strong></p>
            <ul>
                <li>🔍 Examiner les documents fournis</li>
                <li>✅ Approuver ou ❌ Rejeter la demande</li>
                <li>📧 L'utilisateur sera notifié automatiquement</li>
            </ul>
            
            <div style="text-align: center;">
                <a href="#" class="button">Examiner la Demande</a>
            </div>
            
            <p>Merci de traiter cette demande dans les plus brefs délais.</p>
            
            <p>Cordialement,<br>
            <strong>Système Constat Tunisie</strong></p>
        </div>
        
        <div class="footer">
            <p>Cet email a été envoyé automatiquement. Merci de ne pas y répondre.</p>
            <p>© 2024 Constat Tunisie - Tous droits réservés</p>
        </div>
    </div>
</body>
</html>
    ''';

    // Envoyer à tous les admins
    bool allSent = true;
    for (final adminEmail in adminEmails) {
      final sent = await sendEmail(
        to: adminEmail,
        subject: subject,
        htmlBody: htmlBody,
      );
      if (!sent) allSent = false;
    }

    return allSent;
  }
}
