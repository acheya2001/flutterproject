import 'package:flutter/foundation.dart';
import 'email_service.dart';

/// Service de test pour vérifier l'envoi d'emails
class EmailTestService {
  static final EmailService _emailService = EmailService();

  /// Test rapide d'envoi d'email
  static Future<bool> testEmailSending({
    String? testEmail,
  }) async {
    try {
      debugPrint('[EmailTest] === DÉBUT TEST EMAIL ===');
      
      final email = testEmail ?? 'hammami123rahma@gmail.com';
      final sessionCode = 'TEST123';
      final sessionId = 'test_session_id';
      
      debugPrint('[EmailTest] Email de test: $email');
      debugPrint('[EmailTest] Code de session: $sessionCode');
      
      await _emailService.envoyerInvitation(
        email: email,
        sessionCode: sessionCode,
        sessionId: sessionId,
      );
      
      debugPrint('[EmailTest] ✅ Test terminé avec succès');
      debugPrint('[EmailTest] 📧 Vérifiez votre boîte email: $email');
      debugPrint('[EmailTest] 📧 N\'oubliez pas de vérifier le dossier spam!');
      
      return true;
    } catch (e) {
      debugPrint('[EmailTest] ❌ Erreur lors du test: $e');
      return false;
    }
  }

  /// Test avec plusieurs emails
  static Future<Map<String, bool>> testMultipleEmails(List<String> emails) async {
    Map<String, bool> results = {};
    
    debugPrint('[EmailTest] === TEST MULTIPLE EMAILS ===');
    debugPrint('[EmailTest] Nombre d\'emails à tester: ${emails.length}');
    
    for (String email in emails) {
      if (email.trim().isNotEmpty) {
        debugPrint('[EmailTest] Test en cours pour: $email');
        
        try {
          await _emailService.envoyerInvitation(
            email: email.trim(),
            sessionCode: 'TEST${DateTime.now().millisecondsSinceEpoch % 1000}',
            sessionId: 'test_${DateTime.now().millisecondsSinceEpoch}',
          );
          
          results[email] = true;
          debugPrint('[EmailTest] ✅ Succès pour: $email');
        } catch (e) {
          results[email] = false;
          debugPrint('[EmailTest] ❌ Échec pour: $email - $e');
        }
        
        // Délai entre les envois pour éviter le spam
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    
    debugPrint('[EmailTest] === RÉSULTATS FINAUX ===');
    results.forEach((email, success) {
      debugPrint('[EmailTest] $email: ${success ? "✅ Succès" : "❌ Échec"}');
    });
    
    return results;
  }

  /// Affiche les informations de configuration
  static void showConfigurationInfo() {
    debugPrint('[EmailTest] === INFORMATIONS DE CONFIGURATION ===');
    debugPrint('[EmailTest] Pour configurer l\'envoi d\'emails:');
    debugPrint('[EmailTest] 1. Créez un compte sur emailjs.com');
    debugPrint('[EmailTest] 2. Connectez votre Gmail');
    debugPrint('[EmailTest] 3. Créez un template d\'email');
    debugPrint('[EmailTest] 4. Mettez à jour les clés dans email_service.dart');
    debugPrint('[EmailTest] 5. Consultez EMAIL_CONFIG_GUIDE.md pour plus de détails');
    debugPrint('[EmailTest] =======================================');
  }

  /// Test de validation d'email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  /// Génère un code de session de test
  static String generateTestSessionCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'TEST${timestamp % 100000}';
  }
}
