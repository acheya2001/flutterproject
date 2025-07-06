import 'package:flutter/foundation.dart';

/// 🧪 Service de test pour vérifier si le code email fonctionne
class TestEmailService {
  
  /// 🧪 Test de simulation d'envoi d'email
  static Future<bool> testEmailSimulation({
    required String email,
    required String sessionCode,
    required String sessionId,
  }) async {
    try {
      debugPrint('🧪 === TEST SIMULATION EMAIL ===');
      debugPrint('📧 Destinataire: $email');
      debugPrint('🔑 Code session: $sessionCode');
      debugPrint('🆔 ID session: $sessionId');
      
      // Simulation d'un délai d'envoi
      await Future.delayed(const Duration(seconds: 2));
      
      // Créer le contenu de l'email (pour vérification)
      final emailContent = _creerContenuEmail(sessionCode, sessionId);
      
      debugPrint('📄 Contenu de l\'email créé:');
      debugPrint('═══════════════════════════════════════');
      debugPrint(emailContent);
      debugPrint('═══════════════════════════════════════');
      
      // Simulation de succès
      debugPrint('✅ Simulation d\'envoi réussie!');
      debugPrint('📬 L\'email SERAIT envoyé à: $email');
      debugPrint('🎯 Avec le code de session: $sessionCode');
      
      return true;
      
    } catch (e) {
      debugPrint('❌ Erreur lors de la simulation: $e');
      return false;
    }
  }
  
  /// 📄 Crée le contenu de l'email d'invitation
  static String _creerContenuEmail(String sessionCode, String sessionId) {
    return '''
╔══════════════════════════════════════════════════════════╗
║                    🚗 CONSTAT TUNISIE                    ║
║              Invitation Session Collaborative            ║
╠══════════════════════════════════════════════════════════╣
║                                                          ║
║  Bonjour,                                               ║
║                                                          ║
║  Vous êtes invité(e) à rejoindre une session de        ║
║  constat d'accident collaboratif.                       ║
║                                                          ║
║  📋 INFORMATIONS DE LA SESSION:                         ║
║  ┌─────────────────────────────────────────────────────┐ ║
║  │ Code de Session: $sessionCode                        │ ║
║  │ ID de Session:   $sessionId                          │ ║
║  └─────────────────────────────────────────────────────┘ ║
║                                                          ║
║  📱 INSTRUCTIONS:                                        ║
║  1. Ouvrez l'application Constat Tunisie                ║
║  2. Appuyez sur "Rejoindre une session"                 ║
║  3. Saisissez le code: $sessionCode                     ║
║  4. Commencez à remplir le constat ensemble             ║
║                                                          ║
║  ⚠️  IMPORTANT:                                          ║
║  Ce code de session est valide pendant 24 heures.      ║
║  Assurez-vous d'avoir l'application installée.         ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝

Cet email a été envoyé par l'application Constat Tunisie.
Application de constat d'accident collaboratif.
    ''';
  }
  
  /// 🧪 Test de validation d'email
  static bool testEmailValidation(String email) {
    debugPrint('🧪 Test de validation pour: $email');
    
    final isValid = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
    
    debugPrint(isValid 
      ? '✅ Email valide: $email' 
      : '❌ Email invalide: $email');
      
    return isValid;
  }
  
  /// 🧪 Test complet de simulation
  static Future<Map<String, dynamic>> testCompletSimulation() async {
    debugPrint('🧪 === TEST COMPLET DE SIMULATION ===');
    
    final results = <String, dynamic>{};
    
    // Test 1: Validation d'email
    final emailTest = testEmailValidation('hammami123rahma@gmail.com');
    results['email_validation'] = emailTest;
    
    // Test 2: Simulation d'envoi
    final sendTest = await testEmailSimulation(
      email: 'hammami123rahma@gmail.com',
      sessionCode: 'TEST${DateTime.now().millisecondsSinceEpoch % 1000}',
      sessionId: 'simulation_${DateTime.now().millisecondsSinceEpoch}',
    );
    results['email_simulation'] = sendTest;
    
    // Test 3: Génération de contenu
    final content = _creerContenuEmail('ABC123', 'test_session_id');
    results['content_generation'] = content.isNotEmpty;
    results['content_preview'] = content.substring(0, 100) + '...';
    
    // Résultats
    final allSuccess = emailTest && sendTest && content.isNotEmpty;
    results['overall_success'] = allSuccess;
    
    debugPrint('🎯 === RÉSULTATS DU TEST ===');
    debugPrint('Email Validation: ${emailTest ? "✅" : "❌"}');
    debugPrint('Email Simulation: ${sendTest ? "✅" : "❌"}');
    debugPrint('Content Generation: ${content.isNotEmpty ? "✅" : "❌"}');
    debugPrint('Overall Success: ${allSuccess ? "✅ TOUS LES TESTS RÉUSSIS" : "❌ CERTAINS TESTS ONT ÉCHOUÉ"}');
    
    return results;
  }
}
