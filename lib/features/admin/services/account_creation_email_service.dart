import 'package:flutter/material.dart';
import '../../../core/services/firebase_email_service.dart';
import '../models/professional_request_model_final.dart';

/// 📧 Service pour envoyer les emails de création de compte
class AccountCreationEmailService {
  
  /// 📧 Envoyer les identifiants de connexion par email
  static Future<bool> sendAccountCredentials({
    required ProfessionalRequestModel request,
    required String temporaryPassword,
    required String uid,
  }) async {
    try {
      debugPrint('[ACCOUNT_EMAIL] 📧 Envoi identifiants à: ${request.email}');

      final htmlContent = _buildAccountCreationEmail(
        request: request,
        temporaryPassword: temporaryPassword,
        uid: uid,
      );

      final success = await FirebaseEmailService.sendEmail(
        to: request.email,
        subject: '🎉 Votre compte professionnel Constat Tunisie est créé !',
        body: htmlContent,
        isHtml: true,
      );

      if (success) {
        debugPrint('[ACCOUNT_EMAIL] ✅ Email envoyé avec succès');
      } else {
        debugPrint('[ACCOUNT_EMAIL] ❌ Erreur envoi email');
      }

      return success;

    } catch (e) {
      debugPrint('[ACCOUNT_EMAIL] ❌ Erreur: $e');
      return false;
    }
  }

  /// 🎨 Construire le contenu HTML de l'email
  static String _buildAccountCreationEmail({
    required ProfessionalRequestModel request,
    required String temporaryPassword,
    required String uid,
  }) {
    final roleFormate = _formatRole(request.roleDemande);
    final companyInfo = _getCompanyInfo(request);

    return '''
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Compte Créé - Constat Tunisie</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            background-color: #f5f7fa;
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background: white;
            border-radius: 12px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.1);
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
            font-weight: 600;
        }
        .content {
            padding: 30px;
        }
        .success-badge {
            background: #10b981;
            color: white;
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 14px;
            font-weight: 600;
            display: inline-block;
            margin-bottom: 20px;
        }
        .credentials-box {
            background: #f8fafc;
            border: 2px solid #e2e8f0;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
        }
        .credential-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 10px 0;
            border-bottom: 1px solid #e2e8f0;
        }
        .credential-item:last-child {
            border-bottom: none;
        }
        .credential-label {
            font-weight: 600;
            color: #4a5568;
        }
        .credential-value {
            font-family: 'Courier New', monospace;
            background: #667eea;
            color: white;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 14px;
        }
        .warning-box {
            background: #fef3cd;
            border: 1px solid #fbbf24;
            border-radius: 8px;
            padding: 15px;
            margin: 20px 0;
        }
        .warning-box h4 {
            color: #92400e;
            margin: 0 0 10px 0;
        }
        .info-section {
            background: #eff6ff;
            border-left: 4px solid #3b82f6;
            padding: 15px;
            margin: 20px 0;
        }
        .button {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 12px 24px;
            text-decoration: none;
            border-radius: 6px;
            font-weight: 600;
            margin: 10px 0;
        }
        .footer {
            background: #f8fafc;
            padding: 20px;
            text-align: center;
            color: #6b7280;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎉 Félicitations !</h1>
            <p>Votre compte professionnel a été créé avec succès</p>
        </div>
        
        <div class="content">
            <div class="success-badge">✅ Compte Approuvé</div>
            
            <h2>Bonjour ${request.nomComplet},</h2>
            
            <p>Nous avons le plaisir de vous informer que votre demande de compte professionnel en tant que <strong>$roleFormate</strong> a été approuvée et que votre compte a été créé avec succès.</p>
            
            $companyInfo
            
            <div class="credentials-box">
                <h3>🔐 Vos identifiants de connexion</h3>
                <div class="credential-item">
                    <span class="credential-label">Email :</span>
                    <span class="credential-value">${request.email}</span>
                </div>
                <div class="credential-item">
                    <span class="credential-label">Mot de passe temporaire :</span>
                    <span class="credential-value">$temporaryPassword</span>
                </div>
            </div>
            
            <div class="warning-box">
                <h4>⚠️ Important - Sécurité</h4>
                <ul>
                    <li>Ce mot de passe est <strong>temporaire</strong></li>
                    <li>Vous devrez le changer lors de votre première connexion</li>
                    <li>Ne partagez jamais vos identifiants</li>
                    <li>Conservez ce mot de passe en lieu sûr</li>
                </ul>
            </div>
            
            <div class="info-section">
                <h4>📱 Prochaines étapes</h4>
                <ol>
                    <li>Téléchargez l'application Constat Tunisie</li>
                    <li>Connectez-vous avec vos identifiants</li>
                    <li>Changez votre mot de passe</li>
                    <li>Complétez votre profil</li>
                    <li>Commencez à utiliser l'application</li>
                </ol>
            </div>
            
            <div style="text-align: center; margin: 30px 0;">
                <a href="#" class="button">📱 Télécharger l'Application</a>
            </div>
            
            <p>Si vous avez des questions ou besoin d'aide, n'hésitez pas à nous contacter à <a href="mailto:support@constat-tunisie.tn">support@constat-tunisie.tn</a></p>
            
            <p>Bienvenue dans l'équipe Constat Tunisie !</p>
        </div>
        
        <div class="footer">
            <p>© 2025 Constat Tunisie - Tous droits réservés</p>
            <p>Cet email a été envoyé automatiquement, merci de ne pas y répondre.</p>
        </div>
    </div>
</body>
</html>
    ''';
  }

  /// 🎯 Formater le rôle pour l'affichage
  static String _formatRole(String role) {
    switch (role) {
      case 'agent_agence':
        return 'Agent d\'Agence';
      case 'expert_auto':
        return 'Expert Automobile';
      case 'admin_compagnie':
        return 'Administrateur de Compagnie';
      case 'admin_agence':
        return 'Administrateur d\'Agence';
      default:
        return role;
    }
  }

  /// 🏢 Obtenir les informations de la compagnie
  static String _getCompanyInfo(ProfessionalRequestModel request) {
    final compagnie = request.compagnie ?? '';
    final agence = request.nomAgence ?? '';
    
    if (compagnie.isNotEmpty || agence.isNotEmpty) {
      return '''
      <div class="info-section">
          <h4>🏢 Informations professionnelles</h4>
          ${compagnie.isNotEmpty ? '<p><strong>Compagnie :</strong> $compagnie</p>' : ''}
          ${agence.isNotEmpty ? '<p><strong>Agence :</strong> $agence</p>' : ''}
          ${request.zoneIntervention?.isNotEmpty == true ? '<p><strong>Zone :</strong> ${request.zoneIntervention}</p>' : ''}
      </div>
      ''';
    }
    
    return '';
  }

  /// 📧 Envoyer un email de notification à l'admin
  static Future<bool> sendAdminNotification({
    required ProfessionalRequestModel request,
    required String adminEmail,
    required bool accountCreated,
    String? error,
  }) async {
    try {
      final subject = accountCreated 
          ? '✅ Compte créé pour ${request.nomComplet}'
          : '❌ Erreur création compte pour ${request.nomComplet}';

      final content = accountCreated
          ? 'Le compte professionnel de ${request.nomComplet} (${request.email}) a été créé avec succès.'
          : 'Erreur lors de la création du compte pour ${request.nomComplet} (${request.email}): $error';

      return await FirebaseEmailService.sendEmail(
        to: adminEmail,
        subject: subject,
        body: '''
        <div style="font-family: Arial, sans-serif; padding: 20px;">
            <h2>$subject</h2>
            <p>$content</p>
            <hr>
            <p><small>Notification automatique - Constat Tunisie Admin</small></p>
        </div>
        ''',
        isHtml: true,
      );

    } catch (e) {
      debugPrint('[ACCOUNT_EMAIL] ❌ Erreur notification admin: $e');
      return false;
    }
  }
}
