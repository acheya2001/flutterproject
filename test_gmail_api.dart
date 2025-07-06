import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// 🧪 Script de test pour Gmail API
class TestGmailAPI {
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');

  /// 🔥 Test d'envoi d'email via Gmail API
  static Future<bool> testGmailEmail({
    String? testEmail,
  }) async {
    try {
      debugPrint('🧪 === TEST GMAIL API ===');
      
      final email = testEmail ?? 'hammami123rahma@gmail.com';
      final sessionCode = 'TEST${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      
      debugPrint('📧 Email de test: $email');
      debugPrint('🔑 Code de session: $sessionCode');
      
      // Appeler la fonction Firebase Gmail
      final HttpsCallable callable = _functions.httpsCallable('sendEmail');
      final result = await callable.call({
        'to': email,
        'subject': '🧪 Test Gmail API - Constat Tunisie',
        'sessionCode': sessionCode,
        'sessionId': 'test_session_${DateTime.now().millisecondsSinceEpoch}',
        'conducteurNom': 'Test Automatique',
        'text': 'Ceci est un test automatique de Gmail API depuis l\'application Constat Tunisie.',
      });
      
      debugPrint('✅ Réponse Gmail API: ${result.data}');
      
      if (result.data['success'] == true) {
        debugPrint('🎉 TEST RÉUSSI! Email envoyé via Gmail API');
        debugPrint('📧 Message ID: ${result.data['messageId']}');
        return true;
      } else {
        debugPrint('❌ TEST ÉCHOUÉ: ${result.data['message']}');
        return false;
      }
      
    } catch (e) {
      debugPrint('❌ Erreur lors du test Gmail API: $e');
      return false;
    }
  }

  /// 🧪 Test d'envoi d'email simple
  static Future<bool> testSimpleGmailEmail({
    String? testEmail,
  }) async {
    try {
      debugPrint('🧪 === TEST EMAIL SIMPLE GMAIL ===');
      
      final email = testEmail ?? 'hammami123rahma@gmail.com';
      
      final HttpsCallable callable = _functions.httpsCallable('sendEmail');
      final result = await callable.call({
        'to': email,
        'subject': '📧 Test Email Simple - Gmail API',
        'text': 'Bonjour!\n\nCeci est un test d\'email simple envoyé via Gmail API depuis Firebase Functions.\n\nSi vous recevez cet email, la configuration Gmail OAuth2 fonctionne parfaitement!\n\nCordialement,\nL\'équipe Constat Tunisie',
      });
      
      debugPrint('✅ Réponse: ${result.data}');
      
      if (result.data['success'] == true) {
        debugPrint('🎉 EMAIL SIMPLE ENVOYÉ avec succès!');
        return true;
      } else {
        debugPrint('❌ Échec de l\'envoi de l\'email simple');
        return false;
      }
      
    } catch (e) {
      debugPrint('❌ Erreur lors du test email simple: $e');
      return false;
    }
  }

  /// 🧪 Test complet Gmail API
  static Future<void> runCompleteTest() async {
    debugPrint('\n🚀 === DÉBUT DES TESTS GMAIL API ===\n');
    
    // Test 1: Email simple
    debugPrint('📧 Test 1: Email simple...');
    final test1 = await testSimpleGmailEmail();
    debugPrint(test1 ? '✅ Test 1 RÉUSSI' : '❌ Test 1 ÉCHOUÉ');
    
    await Future.delayed(Duration(seconds: 2));
    
    // Test 2: Email d'invitation
    debugPrint('\n📧 Test 2: Email d\'invitation...');
    final test2 = await testGmailEmail();
    debugPrint(test2 ? '✅ Test 2 RÉUSSI' : '❌ Test 2 ÉCHOUÉ');
    
    // Résumé
    debugPrint('\n📊 === RÉSUMÉ DES TESTS ===');
    debugPrint('📧 Email simple: ${test1 ? "✅ RÉUSSI" : "❌ ÉCHOUÉ"}');
    debugPrint('📧 Email invitation: ${test2 ? "✅ RÉUSSI" : "❌ ÉCHOUÉ"}');
    
    if (test1 && test2) {
      debugPrint('\n🎉 TOUS LES TESTS RÉUSSIS! Gmail API fonctionne parfaitement!');
      debugPrint('📧 Vérifiez votre boîte email: hammami123rahma@gmail.com');
    } else {
      debugPrint('\n❌ CERTAINS TESTS ONT ÉCHOUÉ. Vérifiez la configuration.');
    }
    
    debugPrint('\n🏁 === FIN DES TESTS ===\n');
  }
}

/// 🎯 Widget de test pour l'interface
class GmailTestWidget extends StatefulWidget {
  @override
  _GmailTestWidgetState createState() => _GmailTestWidgetState();
}

class _GmailTestWidgetState extends State<GmailTestWidget> {
  bool _isLoading = false;
  String _result = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🧪 Test Gmail API'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '🔥 Test Gmail API',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testSimpleEmail,
              child: Text('📧 Test Email Simple'),
            ),
            SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testInvitationEmail,
              child: Text('🚗 Test Email Invitation'),
            ),
            SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _runCompleteTest,
              child: Text('🚀 Test Complet'),
            ),
            SizedBox(height: 20),
            
            if (_isLoading)
              CircularProgressIndicator(),
            
            if (_result.isNotEmpty)
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: SingleChildScrollView(
                    child: Text(_result),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _testSimpleEmail() async {
    setState(() {
      _isLoading = true;
      _result = 'Test en cours...';
    });

    final success = await TestGmailAPI.testSimpleGmailEmail();
    
    setState(() {
      _isLoading = false;
      _result = success 
        ? '✅ Email simple envoyé avec succès!\nVérifiez votre boîte email.' 
        : '❌ Échec de l\'envoi de l\'email simple.';
    });
  }

  Future<void> _testInvitationEmail() async {
    setState(() {
      _isLoading = true;
      _result = 'Test en cours...';
    });

    final success = await TestGmailAPI.testGmailEmail();
    
    setState(() {
      _isLoading = false;
      _result = success 
        ? '✅ Email d\'invitation envoyé avec succès!\nVérifiez votre boîte email.' 
        : '❌ Échec de l\'envoi de l\'email d\'invitation.';
    });
  }

  Future<void> _runCompleteTest() async {
    setState(() {
      _isLoading = true;
      _result = 'Tests complets en cours...';
    });

    await TestGmailAPI.runCompleteTest();
    
    setState(() {
      _isLoading = false;
      _result = '✅ Tests terminés! Consultez les logs pour les détails.';
    });
  }
}
