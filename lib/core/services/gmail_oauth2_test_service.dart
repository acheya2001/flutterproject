import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Service de test pour Gmail OAuth2
class GmailOAuth2TestService {
  
  /// 🧪 Test d'envoi d'email via Gmail OAuth2
  static Future<bool> testGmailOAuth2({
    required String email,
    required String sessionCode,
    String? conducteurNom,
  }) async {
    try {
      debugPrint('[GmailOAuth2Test] === DÉBUT TEST GMAIL OAUTH2 ===');
      debugPrint('[GmailOAuth2Test] 📧 Email de test: $email');
      debugPrint('[GmailOAuth2Test] 🔑 Code session: $sessionCode');
      debugPrint('[GmailOAuth2Test] 👤 Conducteur: ${conducteurNom ?? "Test User"}');
      
      // Appeler la nouvelle fonction Firebase Gmail OAuth2
      final callable = FirebaseFunctions.instance.httpsCallable('sendEmailGmail');
      
      final result = await callable.call({
        'to': email,
        'sessionCode': sessionCode,
        'conducteurNom': conducteurNom ?? 'Test User',
        'subject': '🚗 Test Gmail OAuth2 - Invitation Constat',
      });
      
      debugPrint('[GmailOAuth2Test] 📤 Réponse Firebase: ${result.data}');
      
      if (result.data != null && result.data['success'] == true) {
        debugPrint('[GmailOAuth2Test] ✅ Test Gmail OAuth2 réussi!');
        debugPrint('[GmailOAuth2Test] 📧 Email envoyé vers: $email');
        debugPrint('[GmailOAuth2Test] 🆔 Message ID: ${result.data['messageId'] ?? 'N/A'}');
        return true;
      } else {
        debugPrint('[GmailOAuth2Test] ❌ Test Gmail OAuth2 échoué.');
        debugPrint('[GmailOAuth2Test] 📄 Détails: ${result.data}');
        return false;
      }
      
    } catch (e) {
      debugPrint('[GmailOAuth2Test] ❌ Erreur lors du test Gmail OAuth2: $e');
      
      // Messages d'erreur spécifiques
      if (e.toString().contains('Gmail OAuth2 non configuré')) {
        debugPrint('[GmailOAuth2Test] 🔧 SOLUTION: Configurez CLIENT_ID et CLIENT_SECRET dans functions/index.js');
      } else if (e.toString().contains('Function not found')) {
        debugPrint('[GmailOAuth2Test] 🚀 SOLUTION: Déployez les fonctions avec: firebase deploy --only functions');
      } else if (e.toString().contains('unauthenticated')) {
        debugPrint('[GmailOAuth2Test] 🔐 SOLUTION: Connectez-vous à l\'application');
      }
      
      return false;
    }
  }

  /// 🧪 Test simple Gmail OAuth2
  static Future<bool> testSimpleGmailOAuth2({
    String? testEmail,
  }) async {
    final email = testEmail ?? 'hammami123rahma@gmail.com';
    final sessionCode = 'SIMPLE${DateTime.now().millisecondsSinceEpoch % 1000}';
    
    return await testGmailOAuth2(
      email: email,
      sessionCode: sessionCode,
      conducteurNom: 'Test Simple Gmail OAuth2',
    );
  }

  /// 🧪 Test complet Gmail OAuth2 avec plusieurs emails
  static Future<Map<String, bool>> testMultipleGmailOAuth2({
    List<String>? emails,
  }) async {
    final testEmails = emails ?? [
      'hammami123rahma@gmail.com',
      'test@example.com',
    ];
    
    final results = <String, bool>{};
    
    debugPrint('[GmailOAuth2Test] === TEST MULTIPLE GMAIL OAUTH2 ===');
    debugPrint('[GmailOAuth2Test] 📧 Emails à tester: ${testEmails.length}');
    
    for (int i = 0; i < testEmails.length; i++) {
      final email = testEmails[i];
      final sessionCode = 'MULTI${DateTime.now().millisecondsSinceEpoch % 1000}_$i';
      
      debugPrint('[GmailOAuth2Test] 🧪 Test ${i + 1}/${testEmails.length}: $email');
      
      try {
        final success = await testGmailOAuth2(
          email: email,
          sessionCode: sessionCode,
          conducteurNom: 'Test Multiple $i',
        );
        
        results[email] = success;
        debugPrint('[GmailOAuth2Test] ${success ? "✅" : "❌"} Résultat pour $email: ${success ? "Succès" : "Échec"}');
        
        // Délai entre les tests pour éviter le spam
        if (i < testEmails.length - 1) {
          await Future.delayed(const Duration(seconds: 3));
        }
        
      } catch (e) {
        results[email] = false;
        debugPrint('[GmailOAuth2Test] ❌ Erreur pour $email: $e');
      }
    }
    
    debugPrint('[GmailOAuth2Test] === RÉSULTATS FINAUX GMAIL OAUTH2 ===');
    results.forEach((email, success) {
      debugPrint('[GmailOAuth2Test] $email: ${success ? "✅ Succès" : "❌ Échec"}');
    });
    
    return results;
  }

  /// 📊 Statistiques des tests Gmail OAuth2
  static void printTestStats(Map<String, bool> results) {
    final total = results.length;
    final successes = results.values.where((success) => success).length;
    final failures = total - successes;
    final successRate = total > 0 ? (successes / total * 100).toStringAsFixed(1) : '0.0';
    
    debugPrint('[GmailOAuth2Test] === STATISTIQUES ===');
    debugPrint('[GmailOAuth2Test] 📊 Total: $total');
    debugPrint('[GmailOAuth2Test] ✅ Succès: $successes');
    debugPrint('[GmailOAuth2Test] ❌ Échecs: $failures');
    debugPrint('[GmailOAuth2Test] 📈 Taux de succès: $successRate%');
  }
}
