import 'package:flutter/foundation.dart';
import 'firebase_email_service.dart';

/// 🔥 Service d'email utilisant Gmail API via Firebase Functions
class EmailService {
  /// 📧 Envoie une invitation par email via Gmail API
  Future<bool> envoyerInvitation({
    required String email,
    required String sessionCode,
    required String sessionId,
    String? invitationLink,
    String? customMessage,
  }) async {
    debugPrint('[EmailService] === REDIRECTION VERS GMAIL API ===');
    debugPrint('[EmailService] 📧 Destinataire: $email');

    // Rediriger vers Firebase Gmail API
    return await FirebaseEmailService.envoyerInvitation(
      email: email,
      sessionCode: sessionCode,
      sessionId: sessionId,
      customMessage: customMessage ?? 'Un conducteur vous invite à rejoindre une session de constat.',
    );
  }

  /// 📧 Envoie un email simple via Gmail API
  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String body,
  }) async {
    debugPrint('[EmailService] === REDIRECTION VERS GMAIL API ===');
    debugPrint('[EmailService] 📧 Destinataire: $to');

    // Rediriger vers Firebase Gmail API
    return await FirebaseEmailService.sendEmail(
      to: to,
      subject: subject,
      body: body,
      isHtml: false,
    );
  }

  /// 📧 Envoie un email avec pièce jointe (non supporté par Gmail API pour l'instant)
  Future<bool> sendEmailWithAttachment({
    required String to,
    required String subject,
    required String body,
    required String attachmentPath,
  }) async {
    debugPrint('[EmailService] ❌ Pièces jointes non supportées par Gmail API');
    debugPrint('[EmailService] Envoi de l\'email sans pièce jointe...');
    
    return await sendEmail(
      to: to,
      subject: subject,
      body: body,
    );
  }
}
