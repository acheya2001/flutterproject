import 'package:flutter/foundation.dart';
import 'firebase_email_service.dart';

/// 🧪 Service de test pour Firebase Functions + SendGrid
class FirebaseEmailTestService {
  
  /// 🧪 Test rapide d'envoi d'email via Firebase Functions
  static Future<bool> testEmailSending({
    String? testEmail,
  }) async {
    try {
      debugPrint('[FirebaseEmailTest] === DÉBUT TEST FIREBASE EMAIL ===');
      
      final email = testEmail ?? 'hammami123rahma@gmail.com';
      final sessionCode = 'TEST${DateTime.now().millisecondsSinceEpoch % 1000}';
      final sessionId = 'firebase_test_${DateTime.now().millisecondsSinceEpoch}';
      
      debugPrint('[FirebaseEmailTest] 📧 Email de test: $email');
      debugPrint('[FirebaseEmailTest] 🔑 Code de session: $sessionCode');
      debugPrint('[FirebaseEmailTest] 🆔 ID de session: $sessionId');
      
      final success = await FirebaseEmailService.envoyerInvitation(
        email: email,
        sessionCode: sessionCode,
        sessionId: sessionId,
        customMessage: 'Ceci est un test d\'invitation via Firebase Functions + SendGrid.',
      );
      
      if (success) {
        debugPrint('[FirebaseEmailTest] ✅ Test réussi! Email envoyé via Firebase Functions.');
        return true;
      } else {
        debugPrint('[FirebaseEmailTest] ❌ Test échoué. Vérifiez la configuration SendGrid.');
        return false;
      }
      
    } catch (e) {
      debugPrint('[FirebaseEmailTest] ❌ Erreur lors du test: $e');
      return false;
    }
  }

  /// 🧪 Test d'envoi d'email simple
  static Future<bool> testSimpleEmail({
    String? testEmail,
  }) async {
    try {
      debugPrint('[FirebaseEmailTest] === TEST EMAIL SIMPLE ===');
      
      final email = testEmail ?? 'hammami123rahma@gmail.com';
      
      final success = await FirebaseEmailService.sendEmail(
        to: email,
        subject: 'Test Firebase Functions - Constat Tunisie',
        body: 'Ceci est un test d\'email simple envoyé via Firebase Functions + SendGrid.\n\nSi vous recevez cet email, la configuration fonctionne parfaitement!',
        isHtml: false,
      );
      
      if (success) {
        debugPrint('[FirebaseEmailTest] ✅ Email simple envoyé avec succès!');
        return true;
      } else {
        debugPrint('[FirebaseEmailTest] ❌ Échec de l\'envoi de l\'email simple.');
        return false;
      }
      
    } catch (e) {
      debugPrint('[FirebaseEmailTest] ❌ Erreur lors du test simple: $e');
      return false;
    }
  }

  /// 🧪 Test d'envoi d'email HTML
  static Future<bool> testHtmlEmail({
    String? testEmail,
  }) async {
    try {
      debugPrint('[FirebaseEmailTest] === TEST EMAIL HTML ===');
      
      final email = testEmail ?? 'hammami123rahma@gmail.com';
      
      final htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head>
          <meta charset="UTF-8">
          <title>Test Firebase Functions</title>
      </head>
      <body style="font-family: Arial, sans-serif; padding: 20px; background-color: #f5f5f5;">
          <div style="max-width: 600px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
              <h1 style="color: #333; text-align: center;">🔥 Test Firebase Functions</h1>
              <p style="color: #666; font-size: 16px; line-height: 1.6;">
                  Félicitations ! Votre configuration Firebase Functions + SendGrid fonctionne parfaitement.
              </p>
              <div style="background-color: #e8f5e8; padding: 15px; border-radius: 5px; margin: 20px 0;">
                  <p style="color: #2d5a2d; margin: 0; font-weight: bold;">
                      ✅ Email HTML envoyé avec succès via Firebase Functions
                  </p>
              </div>
              <p style="color: #666; font-size: 14px; text-align: center; margin-top: 30px;">
                  Constat Tunisie - Test Firebase Functions
              </p>
          </div>
      </body>
      </html>
      ''';
      
      final success = await FirebaseEmailService.sendEmail(
        to: email,
        subject: 'Test HTML Firebase Functions - Constat Tunisie',
        body: htmlContent,
        isHtml: true,
      );
      
      if (success) {
        debugPrint('[FirebaseEmailTest] ✅ Email HTML envoyé avec succès!');
        return true;
      } else {
        debugPrint('[FirebaseEmailTest] ❌ Échec de l\'envoi de l\'email HTML.');
        return false;
      }
      
    } catch (e) {
      debugPrint('[FirebaseEmailTest] ❌ Erreur lors du test HTML: $e');
      return false;
    }
  }

  /// 🧪 Test complet de tous les types d'emails
  static Future<Map<String, bool>> testAllEmailTypes({
    String? testEmail,
  }) async {
    final email = testEmail ?? 'hammami123rahma@gmail.com';
    final results = <String, bool>{};
    
    debugPrint('[FirebaseEmailTest] === TEST COMPLET FIREBASE FUNCTIONS ===');
    debugPrint('[FirebaseEmailTest] 📧 Email de test: $email');
    
    // Test 1: Email d'invitation
    debugPrint('[FirebaseEmailTest] 🧪 Test 1/3: Email d\'invitation...');
    results['invitation'] = await testEmailSending(testEmail: email);
    await Future.delayed(const Duration(seconds: 2));
    
    // Test 2: Email simple
    debugPrint('[FirebaseEmailTest] 🧪 Test 2/3: Email simple...');
    results['simple'] = await testSimpleEmail(testEmail: email);
    await Future.delayed(const Duration(seconds: 2));
    
    // Test 3: Email HTML
    debugPrint('[FirebaseEmailTest] 🧪 Test 3/3: Email HTML...');
    results['html'] = await testHtmlEmail(testEmail: email);
    
    // Résultats finaux
    debugPrint('[FirebaseEmailTest] === RÉSULTATS FINAUX ===');
    results.forEach((type, success) {
      debugPrint('[FirebaseEmailTest] $type: ${success ? "✅ Succès" : "❌ Échec"}');
    });
    
    final allSuccess = results.values.every((success) => success);
    debugPrint('[FirebaseEmailTest] 🎯 Résultat global: ${allSuccess ? "✅ TOUS LES TESTS RÉUSSIS" : "❌ CERTAINS TESTS ONT ÉCHOUÉ"}');
    
    return results;
  }
}
