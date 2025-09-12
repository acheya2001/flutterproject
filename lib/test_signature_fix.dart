import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/collaborative_session_service.dart';
import 'services/signature_debug_service.dart';

/// 🧪 Test rapide pour corriger le problème de signatures
class TestSignatureFix extends StatefulWidget {
  const TestSignatureFix({Key? key}) : super(key: key);

  @override
  State<TestSignatureFix> createState() => _TestSignatureFixState();
}

class _TestSignatureFixState extends State<TestSignatureFix> {
  String _sessionId = '';
  String _logs = '';

  void _addLog(String message) {
    setState(() {
      _logs += '${DateTime.now().toString().substring(11, 19)} - $message\n';
    });
    print(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Signature Fix'),
        backgroundColor: Colors.red[600],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Input pour Session ID
            TextField(
              decoration: const InputDecoration(
                labelText: 'Session ID',
                hintText: 'Entrez l\'ID de votre session collaborative',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _sessionId = value,
            ),
            
            const SizedBox(height: 20),
            
            // Boutons de test
            Wrap(
              spacing: 10,
              children: [
                ElevatedButton(
                  onPressed: _sessionId.isEmpty ? null : _testDebugSignatures,
                  child: const Text('Debug Signatures'),
                ),
                ElevatedButton(
                  onPressed: _sessionId.isEmpty ? null : _testAjoutSignature,
                  child: const Text('Test Ajout'),
                ),
                ElevatedButton(
                  onPressed: _sessionId.isEmpty ? null : _testSignatureDirecte,
                  child: const Text('Signature Directe'),
                ),
                ElevatedButton(
                  onPressed: _sessionId.isEmpty ? null : _repererSignatures,
                  child: const Text('Réparer'),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Zone de logs
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _logs.isEmpty ? 'Logs apparaîtront ici...' : _logs,
                    style: const TextStyle(
                      color: Colors.green,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Bouton clear logs
            ElevatedButton(
              onPressed: () => setState(() => _logs = ''),
              child: const Text('Clear Logs'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testDebugSignatures() async {
    _addLog('🔍 Début debug signatures...');
    try {
      await SignatureDebugService.debugSignatures(_sessionId);
      _addLog('✅ Debug terminé - voir console pour détails');
    } catch (e) {
      _addLog('❌ Erreur debug: $e');
    }
  }

  Future<void> _testAjoutSignature() async {
    _addLog('🧪 Test ajout signature...');
    try {
      await SignatureDebugService.testAjoutSignature(_sessionId);
      _addLog('✅ Test ajout terminé');
    } catch (e) {
      _addLog('❌ Erreur test ajout: $e');
    }
  }

  Future<void> _testSignatureDirecte() async {
    _addLog('🔥 Test signature directe...');
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _addLog('❌ Utilisateur non connecté');
        return;
      }

      _addLog('👤 Utilisateur: ${user.uid}');
      
      // Test direct avec CollaborativeSessionService
      await CollaborativeSessionService.ajouterSignature(
        sessionId: _sessionId,
        userId: user.uid,
        signatureBase64: 'TEST_SIGNATURE_BASE64_DIRECT',
        roleVehicule: 'conducteur_a',
      );
      
      _addLog('✅ Signature directe ajoutée');
      
      // Vérifier immédiatement
      await _testDebugSignatures();
      
    } catch (e) {
      _addLog('❌ Erreur signature directe: $e');
    }
  }

  Future<void> _repererSignatures() async {
    _addLog('🔧 Réparation signatures...');
    try {
      await SignatureDebugService.repererSignatures(_sessionId);
      _addLog('✅ Réparation terminée');
      await _testDebugSignatures();
    } catch (e) {
      _addLog('❌ Erreur réparation: $e');
    }
  }
}

/// 🚀 Fonction pour lancer le test depuis n'importe où
void showSignatureTestDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: const TestSignatureFix(),
      ),
    ),
  );
}
