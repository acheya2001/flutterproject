import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// 🔥 Service d'email utilisant Firebase Functions + Gmail OAuth2
class FirebaseEmailService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');

  /// 📧 Envoie une invitation par email via Firebase Functions + Gmail API
  static Future<bool> envoyerInvitation({
    required String email,
    required String sessionCode,
    required String sessionId,
    String? customMessage,
    String? customSubject,
    bool isAccountEmail = false, // Nouveau paramètre pour les emails de comptes
  }) async {
    try {
      debugPrint('[FirebaseEmail] === ENVOI INVITATION VIA GMAIL API ===');
      debugPrint('[FirebaseEmail] 📧 Destinataire: $email');
      debugPrint('[FirebaseEmail] 🔑 Code session: $sessionCode');
      debugPrint('[FirebaseEmail] 🆔 ID session: $sessionId');

      // Validation de l'email
      if (!_isValidEmail(email)) {
        throw Exception('Format d\'email invalide: $email');
      }

      // Créer le contenu HTML avec le template approprié
      final htmlContent = isAccountEmail
        ? _creerContenuHtmlCompte(
            sessionCode: sessionCode,
            sessionId: sessionId,
            customMessage: customMessage ?? 'Votre compte a été traité.',
          )
        : _creerContenuHtmlInvitation(
            sessionCode: sessionCode,
            sessionId: sessionId,
            customMessage: customMessage ?? 'Un conducteur vous invite à rejoindre une session de constat collaboratif.',
          );

      // Appeler la fonction Firebase Gmail avec le nouveau template HTML
      final HttpsCallable callable = _functions.httpsCallable('sendEmail');
      final result = await callable.call({
        'to': email,
        'subject': customSubject ?? '🚗 Invitation au constat - Code: $sessionCode',
        'html': htmlContent,
        'sessionCode': sessionCode,
        'sessionId': sessionId,
        'conducteurNom': 'Un conducteur',
      });

      debugPrint('[FirebaseEmail] ✅ Réponse Gmail API: ${result.data}');

      if (result.data != null && result.data['success'] == true) {
        debugPrint('[FirebaseEmail] 🎉 Email envoyé avec succès!');
        return true;
      } else {
        debugPrint('[FirebaseEmail] ❌ Échec de l\'envoi: ${result.data?['message'] ?? 'Réponse invalide'}');
        return false;
      }

    } catch (e) {
      debugPrint('[FirebaseEmail] ❌ Erreur lors de l\'envoi Gmail: $e');

      // Si l'erreur contient "INTERNAL" mais que les logs montrent un succès,
      // on peut considérer que l'email a été envoyé
      if (e.toString().contains('INTERNAL')) {
        debugPrint('[FirebaseEmail] ⚠️ Erreur INTERNAL mais email probablement envoyé (vérifiez les logs Firebase)');
        // Pour l'instant, on retourne false pour être sûr, mais vous pouvez changer en true si nécessaire
        return false;
      }

      return false;
    }
  }

  /// 📧 Envoie un email de notification de compte (approbation/refus)
  static Future<bool> envoyerNotificationCompte({
    required String email,
    required String userName,
    required String userType,
    required bool isApproved,
    String? rejectionReason,
  }) async {
    try {
      debugPrint('[FirebaseEmail] === ENVOI NOTIFICATION COMPTE ===');
      debugPrint('[FirebaseEmail] 📧 Destinataire: $email');
      debugPrint('[FirebaseEmail] 👤 Utilisateur: $userName');
      debugPrint('[FirebaseEmail] ✅ Approuvé: $isApproved');

      if (!_isValidEmail(email)) {
        throw Exception('Format d\'email invalide: $email');
      }

      // Créer le contenu HTML spécifique pour les notifications de compte
      final htmlContent = _creerContenuHtmlNotificationCompte(
        userName: userName,
        userType: userType,
        isApproved: isApproved,
        rejectionReason: rejectionReason,
      );

      final subject = isApproved
        ? '✅ Votre compte Constat Tunisie a été approuvé !'
        : '❌ Votre demande de compte Constat Tunisie';

      // Appeler la fonction Firebase Gmail
      final HttpsCallable callable = _functions.httpsCallable('sendEmail');
      final result = await callable.call({
        'to': email,
        'subject': subject,
        'html': htmlContent,
      });

      debugPrint('[FirebaseEmail] ✅ Réponse Gmail API: ${result.data}');
      return result.data['success'] == true;

    } catch (e) {
      debugPrint('[FirebaseEmail] ❌ Erreur envoi notification compte: $e');
      return false;
    }
  }

  /// 📧 Envoie un email simple via Firebase Functions
  static Future<bool> sendEmail({
    required String to,
    required String subject,
    required String body,
    bool isHtml = false,
  }) async {
    try {
      debugPrint('[FirebaseEmail] === ENVOI EMAIL SIMPLE ===');
      debugPrint('[FirebaseEmail] 📧 Destinataire: $to');
      debugPrint('[FirebaseEmail] 🏷️ Sujet: $subject');

      if (!_isValidEmail(to)) {
        throw Exception('Format d\'email invalide: $to');
      }

      final HttpsCallable callable = _functions.httpsCallable('sendEmail');
      final result = await callable.call({
        'to': to,
        'subject': subject,
        if (isHtml) 'html': body else 'text': body,
      });

      debugPrint('[FirebaseEmail] ✅ Réponse Gmail API: ${result.data}');
      return result.data['success'] == true;

    } catch (e) {
      debugPrint('[FirebaseEmail] ❌ Erreur lors de l\'envoi: $e');
      return false;
    }
  }

  /// ✅ Valide le format d'un email
  static bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  /// 🎨 Crée le contenu HTML pour les notifications de compte (approbation/refus)
  static String _creerContenuHtmlNotificationCompte({
    required String userName,
    required String userType,
    required bool isApproved,
    String? rejectionReason,
  }) {
    final userTypeLabel = userType == 'assureur' ? 'Agent d\'Assurance' : 'Expert';

    if (isApproved) {
      return '''
      <!DOCTYPE html>
      <html>
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Compte Approuvé - Constat Tunisie</title>
      </head>
      <body style="margin: 0; padding: 20px; font-family: system-ui, sans-serif, Arial; background-color: #f5f5f5;">
          <div style="font-family: system-ui, sans-serif, Arial; font-size: 14px; max-width: 600px; margin: 0 auto;">
            <div style="background-color: #4CAF50; padding: 30px; border-radius: 10px 10px 0 0; text-align: center;">
              <h1 style="color: white; margin: 0; font-size: 28px;">🎉 Félicitations !</h1>
              <p style="color: white; margin: 10px 0 0 0; font-size: 18px;">Votre compte a été approuvé</p>
            </div>

            <div style="background-color: white; padding: 30px; border-radius: 0 0 10px 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
              <h2 style="color: #333; margin-top: 0;">Bonjour $userName,</h2>

              <p style="color: #555; line-height: 1.6; font-size: 16px;">
                Excellente nouvelle ! Votre demande de compte <strong>$userTypeLabel</strong> sur la plateforme
                <strong>Constat Tunisie</strong> a été approuvée par nos administrateurs.
              </p>

              <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                <h3 style="color: #4CAF50; margin-top: 0;">✅ Votre compte est maintenant actif</h3>
                <ul style="color: #555; line-height: 1.8;">
                  <li>Vous pouvez vous connecter à l'application</li>
                  <li>Toutes les fonctionnalités professionnelles sont disponibles</li>
                  <li>Vous pouvez gérer vos dossiers et clients</li>
                  <li>Collaboration avec les autres professionnels activée</li>
                </ul>
              </div>

              <div style="text-align: center; margin: 30px 0;">
                <a href="#" style="background-color: #4CAF50; color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; font-weight: bold; display: inline-block;">
                  Se connecter maintenant
                </a>
              </div>

              <p style="color: #555; line-height: 1.6;">
                Merci de faire confiance à <strong>Constat Tunisie</strong> pour vos activités professionnelles.
              </p>

              <p style="color: #555; line-height: 1.6;">
                Cordialement,<br>
                <strong>L'équipe Constat Tunisie</strong>
              </p>
            </div>

            <div style="text-align: center; margin-top: 20px; color: #888; font-size: 12px;">
              <p>Cet email a été envoyé automatiquement. Merci de ne pas y répondre.</p>
              <p>© 2024 Constat Tunisie - Tous droits réservés</p>
            </div>
          </div>
      </body>
      </html>
      ''';
    } else {
      return '''
      <!DOCTYPE html>
      <html>
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Demande de Compte - Constat Tunisie</title>
      </head>
      <body style="margin: 0; padding: 20px; font-family: system-ui, sans-serif, Arial; background-color: #f5f5f5;">
          <div style="font-family: system-ui, sans-serif, Arial; font-size: 14px; max-width: 600px; margin: 0 auto;">
            <div style="background-color: #f44336; padding: 30px; border-radius: 10px 10px 0 0; text-align: center;">
              <h1 style="color: white; margin: 0; font-size: 28px;">❌ Demande non approuvée</h1>
              <p style="color: white; margin: 10px 0 0 0; font-size: 18px;">Votre demande de compte</p>
            </div>

            <div style="background-color: white; padding: 30px; border-radius: 0 0 10px 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
              <h2 style="color: #333; margin-top: 0;">Bonjour $userName,</h2>

              <p style="color: #555; line-height: 1.6; font-size: 16px;">
                Nous vous remercions pour votre demande de compte <strong>$userTypeLabel</strong> sur
                <strong>Constat Tunisie</strong>.
              </p>

              <p style="color: #555; line-height: 1.6; font-size: 16px;">
                Après examen, nous ne pouvons pas approuver votre demande pour la raison suivante :
              </p>

              <div style="background-color: #ffebee; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #f44336;">
                <p style="color: #c62828; margin: 0; font-weight: bold;">
                  ${rejectionReason ?? 'Informations insuffisantes ou critères non remplis'}
                </p>
              </div>

              <p style="color: #555; line-height: 1.6;">
                Vous pouvez soumettre une nouvelle demande en corrigeant les points mentionnés ci-dessus.
              </p>

              <p style="color: #555; line-height: 1.6;">
                Pour toute question, n'hésitez pas à nous contacter.
              </p>

              <p style="color: #555; line-height: 1.6;">
                Cordialement,<br>
                <strong>L'équipe Constat Tunisie</strong>
              </p>
            </div>

            <div style="text-align: center; margin-top: 20px; color: #888; font-size: 12px;">
              <p>Cet email a été envoyé automatiquement. Merci de ne pas y répondre.</p>
              <p>© 2024 Constat Tunisie - Tous droits réservés</p>
            </div>
          </div>
      </body>
      </html>
      ''';
    }
  }

  /// 🎨 Crée le contenu HTML de l'email d'invitation
  static String _creerContenuHtmlInvitation({
    required String sessionCode,
    required String sessionId,
    required String customMessage,
  }) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Invitation - Constat d'Accident Collaboratif</title>
    </head>
    <body style="margin: 0; padding: 20px; font-family: system-ui, sans-serif, Arial; background-color: #f5f5f5;">
        <div style="font-family: system-ui, sans-serif, Arial; font-size: 14px; max-width: 600px; margin: 0 auto;">
          <div style="background-color: #f8f9fa; padding: 20px; border-radius: 10px;">

            <!-- En-tête -->
            <div style="text-align: center; margin-bottom: 20px;">
              <div style="font-size: 32px; margin-bottom: 10px;">🚗</div>
              <h2 style="color: #2563eb; margin: 0;">Invitation - Constat d'Accident Collaboratif</h2>
            </div>

            <!-- Message principal -->
            <div style="margin-bottom: 20px;">
              <p>Bonjour,</p>
              <p>Vous avez été invité(e) à participer à un constat d'accident collaboratif via l'application <strong>Constat Tunisie</strong>.</p>
            </div>

            <!-- Informations de la session -->
            <div style="margin: 20px 0; padding: 15px; border-width: 1px; border-style: solid; border-color: #2563eb; border-radius: 8px; background-color: white;">
              <table role="presentation" style="width: 100%;">
                <tr>
                  <td style="vertical-align: top; width: 60px;">
                    <div style="padding: 8px; background-color: #eff6ff; border-radius: 8px; font-size: 24px; text-align: center;" role="img">🔑</div>
                  </td>
                  <td style="vertical-align: top; padding-left: 15px;">
                    <div style="color: #1f2937; font-size: 16px;"><strong>Code de session</strong></div>
                    <div style="color: #6b7280; font-size: 13px;">Utilisez ce code pour rejoindre</div>
                    <p style="font-size: 24px; font-weight: bold; color: #2563eb; letter-spacing: 2px; margin: 5px 0;">$sessionCode</p>
                  </td>
                </tr>
              </table>
            </div>

            <!-- Instructions -->
            <div style="margin: 20px 0;">
              <h3 style="color: #1f2937; font-size: 18px;">📱 Comment rejoindre la session :</h3>
              <ol style="color: #374151; line-height: 1.6;">
                <li>Ouvrez l'application <strong>Constat Tunisie</strong> sur votre téléphone</li>
                <li>Appuyez sur <strong>"Rejoindre une session"</strong></li>
                <li>Saisissez le code de session : <strong>$sessionCode</strong></li>
                <li>Remplissez vos informations dans le constat collaboratif</li>
              </ol>
            </div>

            <!-- Bouton d'action -->
            <div style="text-align: center; margin: 30px 0;">
              <a href="#" style="background-color: #2563eb; color: white; padding: 12px 30px; text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block; font-size: 16px;">🚀 Rejoindre la Session</a>
            </div>

            <!-- Informations importantes -->
            <div style="background-color: #fef3c7; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #f59e0b;">
              <p style="margin: 0; color: #92400e; font-weight: bold;">⚠️ Informations importantes :</p>
              <ul style="color: #92400e; margin: 10px 0; padding-left: 20px;">
                <li>Cette invitation expire dans <strong>24 heures</strong></li>
                <li>Ayez vos documents à portée de main (permis, carte grise, attestation d'assurance)</li>
                <li>Prenez des photos de l'accident si ce n'est pas déjà fait</li>
                <li>Assurez-vous d'avoir une connexion internet stable</li>
              </ul>
            </div>

            <!-- Message personnalisé -->
            <div style="margin: 20px 0; padding: 15px; background-color: #f3f4f6; border-radius: 8px;">
              <p style="margin: 0; color: #374151; font-style: italic;">$customMessage</p>
            </div>

            <!-- Pied de page -->
            <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #e5e7eb; text-align: center; color: #6b7280; font-size: 12px;">
              <p>Cet email a été envoyé automatiquement par l'application <strong>Constat Tunisie</strong>.</p>
              <p>Si vous n'êtes pas concerné par cet accident, veuillez ignorer cet email.</p>
              <p style="margin-top: 15px;"><strong>Constat Tunisie</strong> - Votre assistant pour les constats d'accidents</p>
              <p style="color: #94a3b8; margin: 10px 0 0 0; font-size: 11px;">ID de session: $sessionId</p>
            </div>

          </div>
        </div>
    </body>
    </html>
    ''';
  }

  /// Envoie un email pour les comptes professionnels (approbation/rejet)
  static Future<bool> envoyerEmailCompteProfessionnel({
    required String email,
    required String sujet,
    required String titre,
    required String message,
    required String couleurPrincipale,
    required String icone,
  }) async {
    try {
      debugPrint('[FirebaseEmail] 📧 Envoi email compte professionnel à: $email');
      debugPrint('[FirebaseEmail] 📧 Sujet: $sujet');
      debugPrint('[FirebaseEmail] 📧 Titre: $titre');

      // Validation de l'email
      if (!_isValidEmail(email)) {
        throw Exception('Format d\'email invalide: $email');
      }

      debugPrint('[FirebaseEmail] 🔧 Génération du template HTML...');

      // Générer le contenu HTML pour le compte professionnel
      final htmlContent = _genererTemplateCompteProfessionnel(
        titre: titre,
        message: message,
        couleurPrincipale: couleurPrincipale,
        icone: icone,
      );

      debugPrint('[FirebaseEmail] ✅ Template HTML généré (${htmlContent.length} caractères)');
      debugPrint('[FirebaseEmail] 🔧 Appel de la fonction Firebase...');

      // Utiliser la méthode sendEmail existante qui fonctionne
      final success = await sendEmail(
        to: email,
        subject: sujet,
        body: htmlContent,
        isHtml: true,
      );

      if (success) {
        debugPrint('[FirebaseEmail] 🎉 Email compte professionnel envoyé avec succès!');
      } else {
        debugPrint('[FirebaseEmail] ❌ Échec de l\'envoi de l\'email');
      }

      return success;
    } catch (e) {
      debugPrint('[FirebaseEmail] ❌ Erreur lors de l\'envoi de l\'email: $e');
      debugPrint('[FirebaseEmail] ❌ Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Génère le template HTML pour les emails de comptes professionnels
  static String _genererTemplateCompteProfessionnel({
    required String titre,
    required String message,
    required String couleurPrincipale,
    required String icone,
  }) {
    return '''
    <!DOCTYPE html>
    <html lang="fr">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>$titre</title>
        <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f8fafc; }
            .container { max-width: 600px; margin: 0 auto; background-color: white; }
            .header { background: linear-gradient(135deg, $couleurPrincipale 0%, #1e40af 100%); padding: 40px 20px; text-align: center; }
            .header h1 { color: white; margin: 0; font-size: 28px; font-weight: 600; }
            .content { padding: 40px 30px; }
            .status-card { background-color: $couleurPrincipale; color: white; padding: 20px; border-radius: 12px; text-align: center; margin: 20px 0; }
            .status-card h2 { margin: 0; font-size: 20px; font-weight: 600; }
            .message { color: #374151; line-height: 1.6; font-size: 16px; margin: 20px 0; }
            .footer { background-color: #f9fafb; padding: 20px; text-align: center; color: #6b7280; font-size: 14px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>$icone Constat Tunisie</h1>
            </div>

            <div class="content">
                <div class="status-card">
                    <h2>$icone $titre</h2>
                </div>

                <div class="message">
                    $message
                </div>
            </div>

            <div class="footer">
                <p>Cet email a été envoyé automatiquement par l'application <strong>Constat Tunisie</strong>.</p>
                <p><strong>Constat Tunisie</strong> - Votre plateforme de gestion des constats d'accidents</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  /// 🎨 Crée le contenu HTML pour les emails de comptes professionnels
  static String _creerContenuHtmlCompte({
    required String sessionCode,
    required String sessionId,
    required String customMessage,
  }) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Constat Tunisie - Notification de compte</title>
    </head>
    <body style="margin: 0; padding: 20px; font-family: system-ui, sans-serif, Arial; background-color: #f5f5f5;">
        <div style="font-family: system-ui, sans-serif, Arial; font-size: 14px; max-width: 600px; margin: 0 auto;">
          <div style="background-color: #f8f9fa; padding: 20px; border-radius: 10px;">

            <!-- En-tête -->
            <div style="text-align: center; margin-bottom: 20px;">
              <div style="font-size: 32px; margin-bottom: 10px;">🏢</div>
              <h2 style="color: #2563eb; margin: 0;">Constat Tunisie - Compte Professionnel</h2>
            </div>

            <!-- Message personnalisé -->
            <div style="margin: 20px 0; padding: 15px; background-color: #f3f4f6; border-radius: 8px;">
              <p style="margin: 0; color: #374151; white-space: pre-line;">$customMessage</p>
            </div>

            <!-- Pied de page -->
            <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #e5e7eb; text-align: center; color: #6b7280; font-size: 12px;">
              <p>Cet email a été envoyé automatiquement par l'application <strong>Constat Tunisie</strong>.</p>
              <p><strong>Constat Tunisie</strong> - Votre plateforme de gestion des constats d'accidents</p>
              <p>Support : constat.tunisie.app@gmail.com</p>
              <p style="color: #94a3b8; margin: 10px 0 0 0; font-size: 11px;">ID: $sessionId</p>
            </div>

          </div>
        </div>
    </body>
    </html>
    ''';
  }
}
