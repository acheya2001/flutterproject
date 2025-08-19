const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

// Configuration Gmail (utiliser les mêmes credentials que votre système existant)
const gmailConfig = {
  service: 'gmail',
  auth: {
    user: 'constat.tunisie.app@gmail.com',
    pass: 'Acheya123' // TODO: Utiliser des variables d'environnement sécurisées
  }
};

const transporter = nodemailer.createTransporter(gmailConfig);

/**
 * 📧 Envoyer notification de nouveau véhicule à un agent
 */
exports.sendVehicleNotificationEmail = functions.https.onCall(async (data, context) => {
  try {
    const { to, agentName, vehicleName, plate, conducteurId, agencyName } = data;

    const htmlTemplate = `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #2196F3; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background: #f9f9f9; }
            .vehicle-info { background: white; padding: 15px; margin: 15px 0; border-left: 4px solid #2196F3; }
            .button { display: inline-block; background: #2196F3; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; margin: 15px 0; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🚗 Nouveau Véhicule en Attente</h1>
                <p>Constat Tunisie - Notification Agent</p>
            </div>
            
            <div class="content">
                <h2>Bonjour ${agentName},</h2>
                
                <p>Un nouveau véhicule a été soumis pour validation dans votre agence <strong>${agencyName}</strong>.</p>
                
                <div class="vehicle-info">
                    <h3>📋 Détails du véhicule :</h3>
                    <ul>
                        <li><strong>Véhicule :</strong> ${vehicleName}</li>
                        <li><strong>Immatriculation :</strong> ${plate}</li>
                        <li><strong>Conducteur ID :</strong> ${conducteurId}</li>
                        <li><strong>Agence :</strong> ${agencyName}</li>
                        <li><strong>Date de soumission :</strong> ${new Date().toLocaleDateString('fr-TN')}</li>
                    </ul>
                </div>
                
                <p>Veuillez vous connecter à votre dashboard pour examiner les documents et valider ou rejeter ce véhicule.</p>
                
                <a href="https://constat-tunisie.web.app/agent/pending-vehicles" class="button">
                    Voir les Véhicules en Attente
                </a>
                
                <p><strong>⏰ Action requise :</strong> Merci de traiter cette demande dans les plus brefs délais.</p>
            </div>
            
            <div class="footer">
                <p>Cet email a été envoyé automatiquement par Constat Tunisie</p>
                <p>© 2024 Constat Tunisie - Tous droits réservés</p>
            </div>
        </div>
    </body>
    </html>
    `;

    const mailOptions = {
      from: 'Constat Tunisie <constat.tunisie.app@gmail.com>',
      to: to,
      subject: `🚗 Nouveau véhicule en attente - ${plate}`,
      html: htmlTemplate
    };

    await transporter.sendMail(mailOptions);
    
    console.log(`✅ Email envoyé à ${to} pour véhicule ${plate}`);
    return { success: true, message: 'Email envoyé avec succès' };
    
  } catch (error) {
    console.error('❌ Erreur envoi email:', error);
    throw new functions.https.HttpsError('internal', 'Erreur lors de l\'envoi de l\'email');
  }
});

/**
 * 📧 Envoyer notification de statut véhicule au conducteur
 */
exports.sendVehicleStatusEmail = functions.https.onCall(async (data, context) => {
  try {
    const { to, conducteurName, vehicleName, plate, isValidated, rejectionReason, agencyName } = data;

    const statusColor = isValidated ? '#4CAF50' : '#F44336';
    const statusText = isValidated ? 'VALIDÉ' : 'REJETÉ';
    const statusIcon = isValidated ? '✅' : '❌';

    const htmlTemplate = `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: ${statusColor}; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background: #f9f9f9; }
            .status-info { background: white; padding: 15px; margin: 15px 0; border-left: 4px solid ${statusColor}; }
            .button { display: inline-block; background: ${statusColor}; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; margin: 15px 0; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
            .rejection { background: #ffebee; padding: 15px; border-left: 4px solid #f44336; margin: 15px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>${statusIcon} Véhicule ${statusText}</h1>
                <p>Constat Tunisie - Notification Conducteur</p>
            </div>
            
            <div class="content">
                <h2>Bonjour ${conducteurName},</h2>
                
                <p>Votre véhicule a été <strong>${statusText.toLowerCase()}</strong> par l'agence <strong>${agencyName}</strong>.</p>
                
                <div class="status-info">
                    <h3>📋 Détails :</h3>
                    <ul>
                        <li><strong>Véhicule :</strong> ${vehicleName}</li>
                        <li><strong>Immatriculation :</strong> ${plate}</li>
                        <li><strong>Statut :</strong> <span style="color: ${statusColor}; font-weight: bold;">${statusText}</span></li>
                        <li><strong>Agence :</strong> ${agencyName}</li>
                        <li><strong>Date de traitement :</strong> ${new Date().toLocaleDateString('fr-TN')}</li>
                    </ul>
                </div>
                
                ${!isValidated && rejectionReason ? `
                <div class="rejection">
                    <h3>❌ Raison du rejet :</h3>
                    <p>${rejectionReason}</p>
                    <p><strong>Action requise :</strong> Veuillez corriger les informations et soumettre à nouveau votre véhicule.</p>
                </div>
                ` : ''}
                
                ${isValidated ? `
                <p>🎉 <strong>Félicitations !</strong> Votre véhicule est maintenant validé. Vous pouvez maintenant créer des constats d'accident avec ce véhicule.</p>
                ` : ''}
                
                <a href="https://constat-tunisie.web.app/conducteur/vehicles" class="button">
                    Voir Mes Véhicules
                </a>
            </div>
            
            <div class="footer">
                <p>Cet email a été envoyé automatiquement par Constat Tunisie</p>
                <p>© 2024 Constat Tunisie - Tous droits réservés</p>
            </div>
        </div>
    </body>
    </html>
    `;

    const mailOptions = {
      from: 'Constat Tunisie <constat.tunisie.app@gmail.com>',
      to: to,
      subject: `${statusIcon} Véhicule ${statusText} - ${plate}`,
      html: htmlTemplate
    };

    await transporter.sendMail(mailOptions);
    
    console.log(`✅ Email statut envoyé à ${to} pour véhicule ${plate}`);
    return { success: true, message: 'Email envoyé avec succès' };
    
  } catch (error) {
    console.error('❌ Erreur envoi email statut:', error);
    throw new functions.https.HttpsError('internal', 'Erreur lors de l\'envoi de l\'email');
  }
});

/**
 * 📧 Envoyer notification de nouveau constat aux agents
 */
exports.sendConstatNotificationEmail = functions.https.onCall(async (data, context) => {
  try {
    const { to, constatsId, location, vehiclePlates, agencyName } = data;

    const htmlTemplate = `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #FF9800; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background: #f9f9f9; }
            .constat-info { background: white; padding: 15px; margin: 15px 0; border-left: 4px solid #FF9800; }
            .button { display: inline-block; background: #FF9800; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; margin: 15px 0; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>📋 Nouveau Constat Finalisé</h1>
                <p>Constat Tunisie - Notification Agent</p>
            </div>
            
            <div class="content">
                <h2>Nouveau constat d'accident</h2>
                
                <p>Un nouveau constat d'accident a été finalisé et nécessite votre attention.</p>
                
                <div class="constat-info">
                    <h3>📋 Détails du constat :</h3>
                    <ul>
                        <li><strong>ID Constat :</strong> ${constatsId}</li>
                        <li><strong>Lieu :</strong> ${location}</li>
                        <li><strong>Véhicules impliqués :</strong> ${vehiclePlates.join(', ')}</li>
                        <li><strong>Agence :</strong> ${agencyName}</li>
                        <li><strong>Date :</strong> ${new Date().toLocaleDateString('fr-TN')}</li>
                    </ul>
                </div>
                
                <p>Veuillez examiner ce constat et prendre les mesures nécessaires.</p>
                
                <a href="https://constat-tunisie.web.app/agent/constats" class="button">
                    Voir les Constats
                </a>
            </div>
            
            <div class="footer">
                <p>Cet email a été envoyé automatiquement par Constat Tunisie</p>
                <p>© 2024 Constat Tunisie - Tous droits réservés</p>
            </div>
        </div>
    </body>
    </html>
    `;

    const mailOptions = {
      from: 'Constat Tunisie <constat.tunisie.app@gmail.com>',
      to: to,
      subject: `📋 Nouveau constat finalisé - ${location}`,
      html: htmlTemplate
    };

    await transporter.sendMail(mailOptions);
    
    console.log(`✅ Email constat envoyé à ${to}`);
    return { success: true, message: 'Email envoyé avec succès' };
    
  } catch (error) {
    console.error('❌ Erreur envoi email constat:', error);
    throw new functions.https.HttpsError('internal', 'Erreur lors de l\'envoi de l\'email');
  }
});

/**
 * 📱 Envoyer SMS de notification (optionnel - nécessite un service SMS)
 */
exports.sendSMSNotification = functions.https.onCall(async (data, context) => {
  try {
    const { to, message, type } = data;
    
    // TODO: Intégrer avec un service SMS (Twilio, etc.)
    console.log(`📱 SMS à envoyer à ${to}: ${message}`);
    
    // Pour l'instant, on simule l'envoi
    return { success: true, message: 'SMS envoyé avec succès (simulé)' };
    
  } catch (error) {
    console.error('❌ Erreur envoi SMS:', error);
    throw new functions.https.HttpsError('internal', 'Erreur lors de l\'envoi du SMS');
  }
});
