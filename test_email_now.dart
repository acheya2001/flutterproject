import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

/// 🧪 Test immédiat d'envoi d'email Gmail
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase avec configuration simple
  await Firebase.initializeApp();

  runApp(TestEmailApp());
}

class TestEmailApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Email Gmail',
      home: TestEmailScreen(),
    );
  }
}

class TestEmailScreen extends StatefulWidget {
  @override
  _TestEmailScreenState createState() => _TestEmailScreenState();
}

class _TestEmailScreenState extends State<TestEmailScreen> {
  bool _isLoading = false;
  String _result = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🧪 Test Email Gmail'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '🔥 TEST GMAIL API MAINTENANT',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            
            // Bouton de test principal
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _testEmailNow,
                icon: Icon(Icons.email, size: 30),
                label: Text(
                  'ENVOYER EMAIL TEST',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            if (_isLoading)
              Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('Envoi en cours...', style: TextStyle(fontSize: 16)),
                ],
              ),
            
            if (_result.isNotEmpty)
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[50],
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _result,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _testEmailNow() async {
    setState(() {
      _isLoading = true;
      _result = '🚀 Début du test...\n';
    });

    try {
      // Configuration Firebase Functions
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      
      setState(() {
        _result += '📧 Préparation de l\'email...\n';
      });
      
      // Données de test
      final email = 'hammami123rahma@gmail.com';
      final sessionCode = 'TEST${DateTime.now().millisecondsSinceEpoch % 10000}';
      
      setState(() {
        _result += '📧 Destinataire: $email\n';
        _result += '🔑 Code session: $sessionCode\n';
        _result += '⏳ Envoi en cours...\n';
      });
      
      // Appel de la fonction Firebase Gmail App Password
      final HttpsCallable callable = functions.httpsCallable('sendEmail');
      final result = await callable.call({
        'to': email,
        'subject': '🧪 Test Gmail API - Constat Tunisie',
        'sessionCode': sessionCode,
        'sessionId': 'test_session_${DateTime.now().millisecondsSinceEpoch}',
        'conducteurNom': 'Test Automatique',
        'text': 'Ceci est un test automatique de Gmail API depuis l\'application Constat Tunisie.',
      });
      
      setState(() {
        _result += '\n✅ RÉPONSE REÇUE:\n';
        _result += '${result.data}\n';
      });
      
      if (result.data['success'] == true) {
        setState(() {
          _result += '\n🎉 SUCCÈS! Email envoyé!\n';
          _result += '📧 Message ID: ${result.data['messageId']}\n';
          _result += '\n📬 Vérifiez votre boîte email:\n';
          _result += 'hammami123rahma@gmail.com\n';
        });
      } else {
        setState(() {
          _result += '\n❌ ÉCHEC: ${result.data['message']}\n';
        });
      }
      
    } catch (e) {
      setState(() {
        _result += '\n❌ ERREUR: $e\n';
        
        // Messages d'aide
        if (e.toString().contains('Function not found')) {
          _result += '\n🔧 SOLUTION: Déployez les fonctions:\n';
          _result += 'firebase deploy --only functions\n';
        } else if (e.toString().contains('unauthenticated')) {
          _result += '\n🔐 SOLUTION: Connectez-vous à Firebase\n';
        } else if (e.toString().contains('permission-denied')) {
          _result += '\n🔒 SOLUTION: Vérifiez les règles Firebase\n';
        }
      });
    }
    
    setState(() {
      _isLoading = false;
    });
  }
}
