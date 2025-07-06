import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/insurance/test_user_setup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const TestAgentApp());
}

class TestAgentApp extends StatelessWidget {
  const TestAgentApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Agent Creation',
      home: const TestAgentScreen(),
    );
  }
}

class TestAgentScreen extends StatefulWidget {
  const TestAgentScreen({Key? key}) : super(key: key);

  @override
  State<TestAgentScreen> createState() => _TestAgentScreenState();
}

class _TestAgentScreenState extends State<TestAgentScreen> {
  bool _isLoading = false;
  String _result = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Agent Creation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testAgentCreation,
              child: _isLoading 
                ? const CircularProgressIndicator()
                : const Text('Créer Agent de Test'),
            ),
            const SizedBox(height: 20),
            if (_result.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_result),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _testAgentCreation() async {
    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      print('🚀 Début test Firebase...');

      // Test 1: Vérifier la connexion Firebase
      final firestore = FirebaseFirestore.instance;

      print('✅ Firebase instances créées');

      // Test 2: Essayer de lire une collection
      try {
        final testQuery = await firestore.collection('users').limit(1).get();
        print('✅ Lecture Firestore réussie, ${testQuery.docs.length} documents');
      } catch (e) {
        print('❌ Erreur lecture Firestore: $e');
      }

      // Test 3: Créer l'agent
      print('🚀 Début création agent...');
      final result = await TestUserSetup.createTestAgent();
      print('📋 Résultat: $result');

      setState(() {
        _result = 'Résultat: ${result['message']}\n'
                 'Succès: ${result['success']}\n'
                 'Email: ${result['email'] ?? 'N/A'}\n'
                 'UserId: ${result['userId'] ?? 'N/A'}';
        if (result['error'] != null) {
          _result += '\nErreur: ${result['error']}';
        }
      });
    } catch (e, stackTrace) {
      print('💥 Erreur dans _testAgentCreation: $e');
      print('📍 Stack: $stackTrace');
      setState(() {
        _result = 'Erreur: $e\nStack: $stackTrace';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
