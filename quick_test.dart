import 'package:flutter/material.dart';
import 'lib/core/services/firebase_email_service.dart';
import 'lib/widgets/test_pdf_widget.dart';

/// 🧪 Test rapide Gmail API
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 === TEST RAPIDE GMAIL API ===');
  
  try {
    // Test d'envoi d'email d'invitation
    print('📧 Envoi d\'un email de test...');
    
    final success = await FirebaseEmailService.envoyerInvitation(
      email: 'hammami123rahma@gmail.com',
      sessionCode: 'TEST123',
      sessionId: 'test_session_${DateTime.now().millisecondsSinceEpoch}',
      customMessage: 'Ceci est un test automatique de Gmail API depuis votre application Flutter !',
    );
    
    if (success) {
      print('🎉 ✅ EMAIL ENVOYÉ AVEC SUCCÈS !');
      print('📧 Vérifiez votre boîte email: hammami123rahma@gmail.com');
      print('🔥 Gmail API fonctionne parfaitement dans votre app !');
    } else {
      print('❌ Échec de l\'envoi de l\'email');
    }
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
  
  print('🏁 Test terminé');
}

/// 🎯 Widget de test simple
class QuickTestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('🧪 Test Gmail API'),
          backgroundColor: Colors.green,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '🔥 Gmail API Configuré !',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  print('🧪 Test en cours...');
                  
                  final success = await FirebaseEmailService.envoyerInvitation(
                    email: 'hammami123rahma@gmail.com',
                    sessionCode: 'APP${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                    sessionId: 'app_test_${DateTime.now().millisecondsSinceEpoch}',
                  );
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success 
                        ? '✅ Email envoyé ! Vérifiez votre boîte email.' 
                        : '❌ Échec de l\'envoi'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                },
                child: Text('📧 Tester Gmail API'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TestPDFWidget()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: Text('📄 Tester PDF Amélioré'),
              ),
              SizedBox(height: 20),
              Text(
                '📧 Email de test: hammami123rahma@gmail.com',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
