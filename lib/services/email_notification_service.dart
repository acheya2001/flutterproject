import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// 📧 Service d'envoi d'emails pour les notifications
class EmailNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Configuration Gmail OAuth2 (à remplacer par vos vraies clés)
  static const String _refreshToken = '1//04fqCR47aG8PuCgYIARAAGAQSNwF-L9IrbmVfT1Ip925nf40rYtGez0sw_fJH341WZM9UHDhdWnkShe5AONoFyep4P6lS2E1VsFw';
  static const String _clientId = '1059917372502-bcja6qd5feh9rpndg3klveh1pcihruj5.apps.googleusercontent.com';
  static const String _clientSecret = 'GOCSPX-your-client-secret'; // À configurer
  static const String _fromEmail = 'constat.tunisie.app@gmail.com';

  /// 👤 Envoyer un email de création de compte
  static Future<Map<String, dynamic>> sendAccountCreatedEmail({
    required String recipientEmail,
    required String recipientName,
    required String tempPassword,
    required String loginUrl,
  }) async {
    try {
      debugPrint('[EMAIL_SERVICE] 📧 Envoi email création compte à: $recipientEmail');

      // Template HTML pour l'email
      final htmlContent = _buildAccountCreatedEmailTemplate(
        recipientName: recipientName,
        tempPassword: tempPassword,
        loginUrl: loginUrl,
      );

      // Envoyer l'email
      final emailResult = await _sendEmail(
        to: recipientEmail,
        subject: '🎉 Votre compte Constat Tunisie a été créé',
        htmlContent: htmlContent,
      );

      if (emailResult['success']) {
        // Enregistrer dans les logs
        await _logEmailSent(
          to: recipientEmail,
          subject: 'Création de compte',
          type: 'account_created',
          status: 'sent',
          content: 'Identifiants de connexion envoyés',
        );

        debugPrint('[EMAIL_SERVICE] ✅ Email création compte envoyé avec succès');
        return {'success': true, 'message': 'Email envoyé avec succès'};
      } else {
        throw Exception(emailResult['error']);
      }
    } catch (e) {
      debugPrint('[EMAIL_SERVICE] ❌ Erreur envoi email création compte: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 🔐 Envoyer un email de réinitialisation de mot de passe
  static Future<Map<String, dynamic>> sendPasswordResetEmail({
    required String toEmail,
    required String adminName,
    required String newPassword,
    required String agenceName,
  }) async {
    try {
      debugPrint('[EMAIL_SERVICE] 📧 Envoi email reset MDP à: $toEmail');

      // Template HTML pour l'email
      final htmlContent = _buildPasswordResetEmailTemplate(
        adminName: adminName,
        newPassword: newPassword,
        agenceName: agenceName,
      );

      // Envoyer l'email
      final emailResult = await _sendEmail(
        to: toEmail,
        subject: '🔐 Réinitialisation de votre mot de passe - Constat Tunisie',
        htmlContent: htmlContent,
      );

      if (emailResult['success']) {
        // Enregistrer dans les logs
        await _logEmailSent(
          to: toEmail,
          subject: 'Réinitialisation mot de passe',
          type: 'password_reset',
          status: 'sent',
          content: 'Nouveau mot de passe envoyé',
        );

        debugPrint('[EMAIL_SERVICE] ✅ Email envoyé avec succès');
        return {
          'success': true,
          'message': 'Email de réinitialisation envoyé avec succès',
        };
      } else {
        throw Exception(emailResult['error']);
      }

    } catch (e) {
      debugPrint('[EMAIL_SERVICE] ❌ Erreur envoi email: $e');
      
      // Enregistrer l'erreur dans les logs
      await _logEmailSent(
        to: toEmail,
        subject: 'Réinitialisation mot de passe',
        type: 'password_reset',
        status: 'failed',
        content: 'Erreur: $e',
      );

      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de l\'envoi de l\'email',
      };
    }
  }

  /// 📧 Envoyer un email générique
  static Future<Map<String, dynamic>> _sendEmail({
    required String to,
    required String subject,
    required String htmlContent,
  }) async {
    try {
      // Pour le moment, on simule l'envoi d'email
      // En production, vous devriez utiliser un service comme SendGrid, AWS SES, etc.
      
      debugPrint('[EMAIL_SERVICE] 📤 Simulation envoi email à: $to');
      debugPrint('[EMAIL_SERVICE] 📋 Sujet: $subject');
      
      // Simuler un délai d'envoi
      await Future.delayed(const Duration(seconds: 1));
      
      // En production, remplacez cette simulation par un vrai service d'email
      // Exemple avec une API REST :
      /*
      final response = await http.post(
        Uri.parse('https://api.sendgrid.com/v3/mail/send'),
        headers: {
          'Authorization': 'Bearer YOUR_SENDGRID_API_KEY',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'personalizations': [
            {
              'to': [{'email': to}],
              'subject': subject,
            }
          ],
          'from': {'email': _fromEmail},
          'content': [
            {
              'type': 'text/html',
              'value': htmlContent,
            }
          ],
        }),
      );

      if (response.statusCode == 202) {
        return {'success': true};
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
      */

      return {'success': true};

    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🎨 Template HTML pour l'email de réinitialisation
  static String _buildPasswordResetEmailTemplate({
    required String adminName,
    required String newPassword,
    required String agenceName,
  }) {
    return '''
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Réinitialisation de mot de passe</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f8fafc;
        }
        .container {
            background: white;
            border-radius: 16px;
            padding: 30px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 12px;
            color: white;
        }
        .header h1 {
            margin: 0;
            font-size: 24px;
        }
        .content {
            margin-bottom: 30px;
        }
        .password-box {
            background: #f0f9ff;
            border: 2px solid #0ea5e9;
            border-radius: 12px;
            padding: 20px;
            text-align: center;
            margin: 20px 0;
        }
        .password {
            font-size: 24px;
            font-weight: bold;
            color: #0ea5e9;
            font-family: 'Courier New', monospace;
            letter-spacing: 2px;
        }
        .warning {
            background: #fef3c7;
            border: 1px solid #f59e0b;
            border-radius: 8px;
            padding: 15px;
            margin: 20px 0;
        }
        .footer {
            text-align: center;
            color: #6b7280;
            font-size: 14px;
            border-top: 1px solid #e5e7eb;
            padding-top: 20px;
        }
        .button {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 12px 24px;
            text-decoration: none;
            border-radius: 8px;
            margin: 10px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔐 Réinitialisation de mot de passe</h1>
            <p>Constat Tunisie - Système de gestion</p>
        </div>
        
        <div class="content">
            <h2>Bonjour $adminName,</h2>
            
            <p>Votre mot de passe pour l'agence <strong>$agenceName</strong> a été réinitialisé par votre administrateur.</p>
            
            <div class="password-box">
                <p><strong>Votre nouveau mot de passe :</strong></p>
                <div class="password">$newPassword</div>
            </div>
            
            <div class="warning">
                <strong>⚠️ Important :</strong>
                <ul>
                    <li>Changez ce mot de passe lors de votre prochaine connexion</li>
                    <li>Ne partagez jamais votre mot de passe</li>
                    <li>Utilisez un mot de passe fort et unique</li>
                </ul>
            </div>
            
            <p>Vous pouvez maintenant vous connecter à votre tableau de bord avec ce nouveau mot de passe.</p>
            
            <div style="text-align: center;">
                <a href="#" class="button">Se connecter au tableau de bord</a>
            </div>
        </div>
        
        <div class="footer">
            <p>Cet email a été envoyé automatiquement par le système Constat Tunisie.</p>
            <p>Si vous n'avez pas demandé cette réinitialisation, contactez immédiatement votre administrateur.</p>
            <p>© 2024 Constat Tunisie - Tous droits réservés</p>
        </div>
    </div>
</body>
</html>
    ''';
  }

  /// 🎨 Template HTML pour l'email de création de compte
  static String _buildAccountCreatedEmailTemplate({
    required String recipientName,
    required String tempPassword,
    required String loginUrl,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Compte créé - Constat Tunisie</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f8fafc;
        }
        .container {
            background: white;
            border-radius: 12px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            font-size: 28px;
        }
        .content {
            padding: 30px;
        }
        .credentials-box {
            background: #f3f4f6;
            border-left: 4px solid #10b981;
            padding: 20px;
            margin: 20px 0;
            border-radius: 8px;
        }
        .password {
            font-family: 'Courier New', monospace;
            font-size: 18px;
            font-weight: bold;
            color: #1f2937;
            background: #e5e7eb;
            padding: 10px;
            border-radius: 6px;
            text-align: center;
            margin: 10px 0;
        }
        .warning {
            background: #fef3c7;
            border: 1px solid #f59e0b;
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
        }
        .footer {
            text-align: center;
            color: #6b7280;
            font-size: 14px;
            border-top: 1px solid #e5e7eb;
            padding-top: 20px;
        }
        .button {
            display: inline-block;
            background: #10b981;
            color: white;
            padding: 12px 24px;
            text-decoration: none;
            border-radius: 8px;
            margin: 10px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎉 Bienvenue sur Constat Tunisie</h1>
            <p>Votre compte a été créé avec succès</p>
        </div>

        <div class="content">
            <h2>Bonjour $recipientName,</h2>

            <p>Votre compte conducteur a été créé par votre agent d'assurance. Vous pouvez maintenant accéder à votre espace personnel pour gérer vos contrats et véhicules.</p>

            <div class="credentials-box">
                <p><strong>Vos identifiants de connexion :</strong></p>
                <p><strong>Email :</strong> Votre adresse email</p>
                <p><strong>Mot de passe temporaire :</strong></p>
                <div class="password">$tempPassword</div>
            </div>

            <div class="warning">
                <strong>⚠️ Important :</strong>
                <ul>
                    <li>Changez ce mot de passe lors de votre première connexion</li>
                    <li>Ne partagez jamais vos identifiants</li>
                    <li>Gardez vos informations de connexion en sécurité</li>
                </ul>
            </div>

            <p><strong>Avec votre compte, vous pouvez :</strong></p>
            <ul>
                <li>✅ Consulter vos contrats d'assurance</li>
                <li>✅ Gérer vos véhicules assurés</li>
                <li>✅ Faire de nouvelles demandes d'assurance</li>
                <li>✅ Déclarer des sinistres</li>
                <li>✅ Suivre le traitement de vos dossiers</li>
            </ul>

            <div style="text-align: center;">
                <a href="$loginUrl" class="button">Se connecter maintenant</a>
            </div>
        </div>

        <div class="footer">
            <p>Cet email a été envoyé automatiquement par le système Constat Tunisie.</p>
            <p>Si vous avez des questions, contactez votre agent d'assurance.</p>
            <p>© 2024 Constat Tunisie - Tous droits réservés</p>
        </div>
    </div>
</body>
</html>
    ''';
  }

  /// 📝 Enregistrer l'envoi d'email dans les logs
  static Future<void> _logEmailSent({
    required String to,
    required String subject,
    required String type,
    required String status,
    required String content,
  }) async {
    try {
      await _firestore.collection('email_logs').add({
        'to': to,
        'subject': subject,
        'type': type,
        'status': status,
        'content': content,
        'sentAt': FieldValue.serverTimestamp(),
        'from': _fromEmail,
      });
    } catch (e) {
      debugPrint('[EMAIL_SERVICE] ❌ Erreur log email: $e');
    }
  }

  /// 📧 Envoyer un email de bienvenue pour nouvel admin
  static Future<Map<String, dynamic>> sendWelcomeEmail({
    required String toEmail,
    required String adminName,
    required String password,
    required String agenceName,
    required String compagnieName,
  }) async {
    try {
      final htmlContent = _buildWelcomeEmailTemplate(
        adminName: adminName,
        password: password,
        agenceName: agenceName,
        compagnieName: compagnieName,
      );

      final emailResult = await _sendEmail(
        to: toEmail,
        subject: '🎉 Bienvenue dans l\'équipe - Constat Tunisie',
        htmlContent: htmlContent,
      );

      if (emailResult['success']) {
        await _logEmailSent(
          to: toEmail,
          subject: 'Email de bienvenue',
          type: 'welcome',
          status: 'sent',
          content: 'Compte créé avec mot de passe',
        );

        return {
          'success': true,
          'message': 'Email de bienvenue envoyé avec succès',
        };
      } else {
        throw Exception(emailResult['error']);
      }

    } catch (e) {
      await _logEmailSent(
        to: toEmail,
        subject: 'Email de bienvenue',
        type: 'welcome',
        status: 'failed',
        content: 'Erreur: $e',
      );

      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de l\'envoi de l\'email de bienvenue',
      };
    }
  }

  /// 🎨 Template HTML pour l'email de bienvenue
  static String _buildWelcomeEmailTemplate({
    required String adminName,
    required String password,
    required String agenceName,
    required String compagnieName,
  }) {
    return '''
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bienvenue dans l'équipe</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f8fafc;
        }
        .container {
            background: white;
            border-radius: 16px;
            padding: 30px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding: 20px;
            background: linear-gradient(135deg, #10b981 0%, #059669 100%);
            border-radius: 12px;
            color: white;
        }
        .credentials-box {
            background: #f0fdf4;
            border: 2px solid #10b981;
            border-radius: 12px;
            padding: 20px;
            margin: 20px 0;
        }
        .password {
            font-size: 20px;
            font-weight: bold;
            color: #059669;
            font-family: 'Courier New', monospace;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎉 Bienvenue dans l'équipe !</h1>
            <p>Constat Tunisie - $compagnieName</p>
        </div>
        
        <div class="content">
            <h2>Bonjour $adminName,</h2>
            
            <p>Félicitations ! Vous avez été nommé(e) <strong>Administrateur de l'agence $agenceName</strong>.</p>
            
            <div class="credentials-box">
                <h3>🔑 Vos identifiants de connexion :</h3>
                <p><strong>Email :</strong> Votre adresse email</p>
                <p><strong>Mot de passe :</strong> <span class="password">$password</span></p>
            </div>
            
            <p>Vous pouvez maintenant accéder à votre tableau de bord pour gérer votre agence.</p>
        </div>
    </div>
</body>
</html>
    ''';
  }
}
