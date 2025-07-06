const functions = require("firebase-functions");
const nodemailer = require("nodemailer");
const { google } = require("googleapis");

// 🔥 Configuration Gmail OAuth2 - ANDROID CLIENT CREDENTIALS
const CLIENT_ID = '1059917372502-bcja6qd5feh9rpndg3klveh1pcihruj5.apps.googleusercontent.com';
const CLIENT_SECRET = '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'; // Gardé pour OAuth2
const REDIRECT_URI = 'https://developers.google.com/oauthplayground';
const REFRESH_TOKEN = '1//04fqCR47aG8PuCgYIARAAGAQSNwF-L9IrbmVfT1Ip925nf40rYtGez0sw_fJH341WZM9UHDhdWnkShe5AONoFyep4P6lS2E1VsFw';
const GMAIL_USER = 'constat.tunisie.app@gmail.com';

// Configuration OAuth2 Client
const oAuth2Client = new google.auth.OAuth2(
  CLIENT_ID,
  CLIENT_SECRET,
  REDIRECT_URI
);

// OAuth2 client configuré automatiquement

console.log("✅ Gmail OAuth2 configuré avec succès - Version 5.0 (OAuth2 corrigé)");

// 🔥 NOUVELLE FONCTION GMAIL API - Remplace SendGrid
exports.sendEmail = functions.region("europe-west1").https.onCall(async (data) => {
  console.log("📧 === DÉBUT ENVOI EMAIL VIA GMAIL API ===");
  console.log("📧 Données reçues:", JSON.stringify(data, null, 2));

  try {
    // Validation des paramètres
    const { to, subject, text, html, sessionCode, sessionId, conducteurNom } = data;

    if (!to) {
      throw new functions.https.HttpsError('invalid-argument', 'Le paramètre "to" est requis.');
    }

    console.log(`📧 Envoi email à: ${to}`);
    console.log(`📧 Sujet: ${subject || 'Email depuis Constat Tunisie'}`);

    // Configuration simple avec App Password Gmail
    const transport = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: GMAIL_USER, // constat.tunisie.app@gmail.com
        pass: 'ivcc pzfm szqa xjzv', // App Password Gmail sécurisé
      },
    });

    console.log("✅ Transporteur Gmail configuré avec App Password");

    // Contenu de l'email
    const mailOptions = {
      from: `Constat Tunisie <${GMAIL_USER}>`,
      to: to,
      subject: subject || 'Email depuis Constat Tunisie',
      text: text || 'Email envoyé depuis l\'application Constat Tunisie',
      html: html || `<p>${text || 'Email envoyé depuis l\'application Constat Tunisie'}</p>`,
    };

    // Envoi de l'email
    const result = await transport.sendMail(mailOptions);
    console.log(`✅ Email envoyé avec succès à ${to} via Gmail OAuth2`);
    console.log(`📧 Message ID: ${result.messageId}`);

    return {
      success: true,
      message: 'Email sent successfully via Gmail!',
      to: to,
      messageId: result.messageId
    };

  } catch (error) {
    console.error('❌ Erreur lors de l\'envoi de l\'email Gmail:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Erreur lors de l\'envoi de l\'email Gmail: ' + error.message
    );
  }
});

// 🚀 NOUVELLE FONCTION : Gmail OAuth2 (SOLUTION RECOMMANDÉE)
exports.sendEmailGmail = functions.region("europe-west1").https.onCall(async (data, context) => {
  console.log('🚀 Gmail OAuth2 configuré avec succès');

  try {
    // Authentification optionnelle pour les tests
    console.log('📧 Utilisateur authentifié:', context.auth ? 'Oui' : 'Non (mode test)');

    const { to, subject, sessionCode, sessionId, conducteurNom } = data;

    if (!to || !sessionCode) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Les paramètres to et sessionCode sont requis.'
      );
    }

    // Configuration Gmail App Password - Plus simple et fiable
    console.log('📧 Configuration Gmail App Password en cours...');

    console.log(`📧 Envoi email à: ${to}`);
    console.log(`📧 Code session: ${sessionCode}`);

    // Configuration du transporteur Nodemailer avec Gmail App Password
    const transport = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: GMAIL_USER, // constat.tunisie.app@gmail.com
        pass: 'ivcc pzfm szqa xjzv', // App Password Gmail sécurisé
      },
    });

    console.log("✅ Transporteur Gmail configuré avec App Password");

    // Template HTML professionnel pour l'invitation
    const htmlContent = `
    <!DOCTYPE html>
    <html lang="fr">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Invitation Constat Collaboratif</title>
        <style>
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                line-height: 1.6;
                color: #333;
                max-width: 600px;
                margin: 0 auto;
                padding: 20px;
                background-color: #f4f4f4;
            }
            .container {
                background: white;
                padding: 30px;
                border-radius: 10px;
                box-shadow: 0 0 20px rgba(0,0,0,0.1);
            }
            .header {
                text-align: center;
                border-bottom: 3px solid #2196F3;
                padding-bottom: 20px;
                margin-bottom: 30px;
            }
            .car-emoji {
                font-size: 48px;
                margin-bottom: 10px;
            }
            .title {
                color: #2196F3;
                font-size: 24px;
                font-weight: bold;
                margin: 0;
            }
            .subtitle {
                color: #666;
                font-size: 16px;
                margin: 5px 0 0 0;
            }
            .session-code {
                background: linear-gradient(135deg, #2196F3, #21CBF3);
                color: white;
                padding: 15px;
                border-radius: 8px;
                text-align: center;
                margin: 20px 0;
                font-size: 20px;
                font-weight: bold;
                letter-spacing: 2px;
            }
            .instructions {
                background: #f8f9fa;
                padding: 20px;
                border-radius: 8px;
                margin: 20px 0;
                border-left: 4px solid #2196F3;
            }
            .step {
                margin: 10px 0;
                padding-left: 20px;
                position: relative;
            }
            .step::before {
                content: "✓";
                position: absolute;
                left: 0;
                color: #4CAF50;
                font-weight: bold;
            }
            .warning {
                background: #fff3cd;
                border: 1px solid #ffeaa7;
                color: #856404;
                padding: 15px;
                border-radius: 8px;
                margin: 20px 0;
            }
            .footer {
                text-align: center;
                margin-top: 30px;
                padding-top: 20px;
                border-top: 1px solid #eee;
                color: #666;
                font-size: 14px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <div class="car-emoji">🚗💥</div>
                <h1 class="title">Invitation Constat Collaboratif</h1>
                <p class="subtitle">Déclaration d'accident automobile</p>
            </div>

            <p>Bonjour,</p>

            <p>Vous avez été invité(e) par <strong>${conducteurNom || 'un conducteur'}</strong> à participer à une déclaration de constat d'accident collaborative via l'application <strong>Constat Tunisie</strong>.</p>

            <div class="session-code">
                <div>Code de session</div>
                <div>${sessionCode}</div>
            </div>

            <div class="instructions">
                <h3>📱 Comment rejoindre la session :</h3>
                <div class="step">Téléchargez l'application "Constat Tunisie" sur votre smartphone</div>
                <div class="step">Créez votre compte ou connectez-vous</div>
                <div class="step">Sélectionnez "Rejoindre une session"</div>
                <div class="step">Saisissez le code de session ci-dessus</div>
                <div class="step">Remplissez vos informations dans le constat partagé</div>
            </div>

            <div class="warning">
                <strong>⚠️ Important :</strong> Cette session expire dans 24 heures. Veuillez rejoindre la déclaration dès que possible pour éviter tout retard dans le traitement de votre dossier d'assurance.
            </div>

            <p>Si vous rencontrez des difficultés, n'hésitez pas à contacter le support technique.</p>

            <div class="footer">
                <p><strong>Constat Tunisie</strong><br>
                Application officielle de déclaration d'accidents<br>
                📧 ${GMAIL_USER} | 📞 +216 XX XXX XXX</p>
            </div>
        </div>
    </body>
    </html>
    `;

    const mailOptions = {
      from: `Constat Tunisie App <${GMAIL_USER}>`,
      to: to,
      subject: subject || `🚗 Invitation au constat - Code: ${sessionCode}`,
      text: `
Bonjour,

Vous avez été invité par ${conducteurNom || 'un conducteur'} à remplir un constat dans l'application Constat Tunisie.

Code session : ${sessionCode}

Merci de vous connecter à l'app pour poursuivre la déclaration.

Bien à vous,
L'équipe Constat Tunisie
      `,
      html: htmlContent,
    };

    const result = await transport.sendMail(mailOptions);
    console.log(`Email envoyé avec succès à ${to} via Gmail OAuth2.`);

    return {
      success: true,
      message: 'Email sent successfully via Gmail!',
      to: to,
      sessionCode: sessionCode,
      messageId: result.messageId
    };

  } catch (error) {
    console.error('Erreur lors de l\'envoi de l\'email Gmail:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Erreur lors de l\'envoi de l\'email Gmail: ' + error.message
    );
  }
});

// 🗑️ Fonctions Resend et SendGrid supprimées - Utilisation exclusive de Gmail API

// ========== NOUVELLES FONCTIONS POUR GESTION DES DEMANDES PROFESSIONNELLES ==========

// Template HTML pour email d'acceptation
const getAcceptanceEmailTemplate = (nomComplet, role, motDePasse, loginUrl) => {
  return `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #1976D2, #42A5F5); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .credentials { background: #e3f2fd; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #1976D2; }
            .button { display: inline-block; background: #1976D2; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
            .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🎉 Félicitations !</h1>
                <p>Votre compte professionnel a été approuvé</p>
            </div>
            <div class="content">
                <h2>Bonjour ${nomComplet},</h2>
                <p>Excellente nouvelle ! Votre demande de compte professionnel en tant que <strong>${role}</strong> a été approuvée par notre équipe.</p>

                <div class="credentials">
                    <h3>🔐 Vos identifiants de connexion :</h3>
                    <p><strong>Email :</strong> Votre email de demande</p>
                    <p><strong>Mot de passe temporaire :</strong> <code>${motDePasse}</code></p>
                    <p><em>⚠️ Vous devrez changer ce mot de passe lors de votre première connexion.</em></p>
                </div>

                <p>Vous pouvez maintenant accéder à votre espace professionnel :</p>
                <a href="${loginUrl}" class="button">Se connecter maintenant</a>

                <h3>📋 Prochaines étapes :</h3>
                <ul>
                    <li>Connectez-vous avec vos identifiants</li>
                    <li>Changez votre mot de passe temporaire</li>
                    <li>Complétez votre profil professionnel</li>
                    <li>Explorez les fonctionnalités disponibles</li>
                </ul>

                <p>Si vous avez des questions, n'hésitez pas à nous contacter à <a href="mailto:support@constat-tunisie.app">support@constat-tunisie.app</a></p>

                <p>Bienvenue dans l'équipe Constat Tunisie ! 🚀</p>
            </div>
            <div class="footer">
                <p>© 2024 Constat Tunisie - Application de gestion des constats d'assurance</p>
                <p>Cet email a été envoyé automatiquement, merci de ne pas y répondre.</p>
            </div>
        </div>
    </body>
    </html>
  `;
};

// Template HTML pour email de rejet
const getRejectionEmailTemplate = (nomComplet, role, motifRejet, supportEmail) => {
  return `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #f44336, #ef5350); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .reason { background: #ffebee; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #f44336; }
            .button { display: inline-block; background: #1976D2; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
            .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>📋 Mise à jour de votre demande</h1>
                <p>Concernant votre demande de compte professionnel</p>
            </div>
            <div class="content">
                <h2>Bonjour ${nomComplet},</h2>
                <p>Nous vous remercions pour votre intérêt à rejoindre notre plateforme en tant que <strong>${role}</strong>.</p>

                <p>Après examen attentif de votre dossier, nous ne pouvons malheureusement pas donner suite à votre demande pour le motif suivant :</p>

                <div class="reason">
                    <h3>📝 Motif :</h3>
                    <p>${motifRejet}</p>
                </div>

                <h3>🔄 Que faire maintenant ?</h3>
                <ul>
                    <li>Vérifiez que toutes les informations fournies sont correctes</li>
                    <li>Assurez-vous de répondre à tous les critères requis</li>
                    <li>Vous pouvez soumettre une nouvelle demande après correction</li>
                    <li>Contactez notre support pour plus d'informations</li>
                </ul>

                <p>Notre équipe support reste à votre disposition pour vous accompagner :</p>
                <a href="mailto:${supportEmail}" class="button">Contacter le support</a>

                <p>Nous vous encourageons à corriger les points mentionnés et à renouveler votre demande.</p>

                <p>Cordialement,<br>L'équipe Constat Tunisie</p>
            </div>
            <div class="footer">
                <p>© 2024 Constat Tunisie - Application de gestion des constats d'assurance</p>
                <p>Cet email a été envoyé automatiquement, merci de ne pas y répondre.</p>
            </div>
        </div>
    </body>
    </html>
  `;
};

// Cloud Function pour envoyer email d'acceptation
exports.sendAcceptanceEmail = functions.region("europe-west1").https.onCall(async (data) => {
  console.log("📧 === ENVOI EMAIL ACCEPTATION ===");
  console.log("📧 Données reçues:", JSON.stringify(data, null, 2));

  try {
    const { email, nomComplet, role, motDePasse, appName, loginUrl } = data;

    if (!email || !nomComplet || !role || !motDePasse) {
      throw new functions.https.HttpsError('invalid-argument', 'Paramètres manquants pour l\'email d\'acceptation.');
    }

    const transport = nodemailer.createTransporter({
      service: 'gmail',
      auth: {
        user: GMAIL_USER,
        pass: 'ivcc pzfm szqa xjzv', // App Password Gmail
      },
    });

    const mailOptions = {
      from: `"${appName || 'Constat Tunisie'}" <${GMAIL_USER}>`,
      to: email,
      subject: `🎉 Votre compte ${role} a été approuvé - Constat Tunisie`,
      html: getAcceptanceEmailTemplate(nomComplet, role, motDePasse, loginUrl || 'https://constat-tunisie.app/login'),
    };

    await transport.sendMail(mailOptions);

    console.log(`✅ Email d'acceptation envoyé à ${email}`);
    return { success: true };

  } catch (error) {
    console.error('❌ Erreur envoi email acceptation:', error);
    throw new functions.https.HttpsError('internal', 'Erreur lors de l\'envoi de l\'email d\'acceptation: ' + error.message);
  }
});

// Cloud Function pour envoyer email de rejet
exports.sendRejectionEmail = functions.region("europe-west1").https.onCall(async (data) => {
  console.log("📧 === ENVOI EMAIL REJET ===");
  console.log("📧 Données reçues:", JSON.stringify(data, null, 2));

  try {
    const { email, nomComplet, role, motifRejet, appName, supportEmail } = data;

    if (!email || !nomComplet || !role || !motifRejet) {
      throw new functions.https.HttpsError('invalid-argument', 'Paramètres manquants pour l\'email de rejet.');
    }

    const transport = nodemailer.createTransporter({
      service: 'gmail',
      auth: {
        user: GMAIL_USER,
        pass: 'ivcc pzfm szqa xjzv', // App Password Gmail
      },
    });

    const mailOptions = {
      from: `"${appName || 'Constat Tunisie'}" <${GMAIL_USER}>`,
      to: email,
      subject: `📋 Mise à jour de votre demande de compte ${role} - Constat Tunisie`,
      html: getRejectionEmailTemplate(nomComplet, role, motifRejet, supportEmail || 'support@constat-tunisie.app'),
    };

    await transport.sendMail(mailOptions);

    console.log(`✅ Email de rejet envoyé à ${email}`);
    return { success: true };

  } catch (error) {
    console.error('❌ Erreur envoi email rejet:', error);
    throw new functions.https.HttpsError('internal', 'Erreur lors de l\'envoi de l\'email de rejet: ' + error.message);
  }
});

// Template HTML pour notification admin
const getAdminNotificationTemplate = (nomComplet, email, role, requestId, dashboardUrl) => {
  return `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #ff9800, #ffb74d); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .request-info { background: #fff3e0; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #ff9800; }
            .button { display: inline-block; background: #ff9800; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
            .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🔔 Nouvelle demande de compte</h1>
                <p>Action requise - Validation administrative</p>
            </div>
            <div class="content">
                <h2>Nouvelle demande reçue</h2>
                <p>Une nouvelle demande de compte professionnel vient d'être soumise et nécessite votre validation.</p>

                <div class="request-info">
                    <h3>📋 Détails de la demande :</h3>
                    <p><strong>Nom :</strong> ${nomComplet}</p>
                    <p><strong>Email :</strong> ${email}</p>
                    <p><strong>Rôle demandé :</strong> ${role}</p>
                    <p><strong>ID de la demande :</strong> ${requestId}</p>
                    <p><strong>Date :</strong> ${new Date().toLocaleDateString('fr-FR')}</p>
                </div>

                <p>Veuillez examiner cette demande et prendre une décision (approuver ou rejeter) dans les plus brefs délais.</p>

                <a href="${dashboardUrl}" class="button">Examiner la demande</a>

                <p><em>⏰ Temps de traitement recommandé : 2-3 jours ouvrables</em></p>
            </div>
            <div class="footer">
                <p>© 2024 Constat Tunisie - Tableau de bord administrateur</p>
                <p>Cet email a été envoyé automatiquement depuis le système.</p>
            </div>
        </div>
    </body>
    </html>
  `;
};

// Cloud Function pour notifier les admins
exports.sendNewRequestNotification = functions.region("europe-west1").https.onCall(async (data) => {
  console.log("📧 === NOTIFICATION ADMIN NOUVELLE DEMANDE ===");
  console.log("📧 Données reçues:", JSON.stringify(data, null, 2));

  try {
    const { nomComplet, email, role, requestId, adminEmail, dashboardUrl } = data;

    if (!nomComplet || !email || !role || !requestId) {
      throw new functions.https.HttpsError('invalid-argument', 'Paramètres manquants pour la notification admin.');
    }

    const transport = nodemailer.createTransporter({
      service: 'gmail',
      auth: {
        user: GMAIL_USER,
        pass: 'ivcc pzfm szqa xjzv', // App Password Gmail
      },
    });

    const mailOptions = {
      from: `"Constat Tunisie Admin" <${GMAIL_USER}>`,
      to: adminEmail || 'constat.tunisie.app@gmail.com',
      subject: `🔔 Nouvelle demande de compte ${role} - Action requise`,
      html: getAdminNotificationTemplate(nomComplet, email, role, requestId, dashboardUrl || 'https://admin.constat-tunisie.app/requests'),
    };

    await transport.sendMail(mailOptions);

    console.log(`✅ Notification admin envoyée pour la demande ${requestId}`);
    return { success: true };

  } catch (error) {
    console.error('❌ Erreur notification admin:', error);
    throw new functions.https.HttpsError('internal', 'Erreur lors de l\'envoi de la notification admin: ' + error.message);
  }
});