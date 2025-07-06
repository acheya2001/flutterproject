import 'package:flutter/foundation.dart';
import 'firebase_email_service.dart';

/// 📧 Service d'emails pour les approbations de demandes
/// Utilise la même méthode que les invitations de conducteurs avec contenu personnalisé
class ApprovalEmailService {

  /// 📧 Envoyer un email d'approbation de demande
  static Future<bool> sendApprovalEmail({
    required String toEmail,
    required String nomComplet,
    required String role,
    required String motDePasseTemporaire,
  }) async {
    try {
      debugPrint('[ApprovalEmail] 📧 Envoi email d\'approbation à: $toEmail');

      // Utiliser la méthode envoyerInvitation qui fonctionne, avec un message personnalisé
      final success = await FirebaseEmailService.envoyerInvitation(
        email: toEmail,
        sessionCode: motDePasseTemporaire,
        sessionId: 'compte_approuve_${DateTime.now().millisecondsSinceEpoch}',
        customMessage: _createApprovalTextMessage(nomComplet, role, motDePasseTemporaire),
        customSubject: '✅ Votre compte Constat Tunisie a été approuvé !',
        isAccountEmail: true, // Utiliser le template de compte professionnel
      );

      if (success) {
        debugPrint('[ApprovalEmail] ✅ Email d\'approbation envoyé avec succès');
      } else {
        debugPrint('[ApprovalEmail] ❌ Échec envoi email d\'approbation');
      }

      return success;
    } catch (e) {
      debugPrint('[ApprovalEmail] ❌ Exception envoi email: $e');
      return false;
    }
  }
  
  /// 📧 Envoyer un email de rejet de demande
  static Future<bool> sendRejectionEmail({
    required String toEmail,
    required String nomComplet,
    required String role,
    required String motifRejet,
  }) async {
    try {
      debugPrint('[ApprovalEmail] 📧 Envoi email de rejet à: $toEmail');

      // Utiliser la méthode envoyerInvitation qui fonctionne, avec un message personnalisé
      final success = await FirebaseEmailService.envoyerInvitation(
        email: toEmail,
        sessionCode: 'REJET_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        sessionId: 'compte_rejete_${DateTime.now().millisecondsSinceEpoch}',
        customMessage: _createRejectionTextMessage(nomComplet, role, motifRejet),
        customSubject: '❌ Votre demande de compte Constat Tunisie',
        isAccountEmail: true, // Utiliser le template de compte professionnel
      );

      if (success) {
        debugPrint('[ApprovalEmail] ✅ Email de rejet envoyé avec succès');
      } else {
        debugPrint('[ApprovalEmail] ❌ Erreur envoi email de rejet');
      }

      return success;
    } catch (e) {
      debugPrint('[ApprovalEmail] ❌ Exception envoi email: $e');
      return false;
    }
  }

  /// 📝 Créer le message texte d'approbation
  static String _createApprovalTextMessage(String nomComplet, String role, String motDePasse) {
    return '''
🎉 FÉLICITATIONS $nomComplet !

Votre demande de COMPTE PROFESSIONNEL a été APPROUVÉE !

📋 DÉTAILS DE VOTRE COMPTE :
• Rôle : $role
• Mot de passe temporaire : $motDePasse

🔐 PREMIÈRE CONNEXION :
1. Ouvrez l'application Constat Tunisie
2. Connectez-vous avec votre email et ce mot de passe
3. Changez votre mot de passe lors de la première connexion

⚠️ IMPORTANT : Changez votre mot de passe pour sécuriser votre compte.

Bienvenue dans l'équipe Constat Tunisie ! 🚗

---
Équipe Constat Tunisie
Support : constat.tunisie.app@gmail.com
    ''';
  }

  /// 📝 Créer le message texte de rejet
  static String _createRejectionTextMessage(String nomComplet, String role, String motifRejet) {
    return '''
Bonjour $nomComplet,

Votre demande de COMPTE PROFESSIONNEL pour le rôle "$role" n'a pas pu être approuvée.

❌ MOTIF DU REJET :
$motifRejet

💡 PROCHAINES ÉTAPES :
• Vérifiez vos informations
• Corrigez les points mentionnés
• Soumettez une nouvelle demande

📞 BESOIN D'AIDE ?
Contactez-nous : constat.tunisie.app@gmail.com

Nous vous encourageons à soumettre une nouvelle demande corrigée.

---
Équipe Constat Tunisie
Support : constat.tunisie.app@gmail.com
    ''';
  }
}
