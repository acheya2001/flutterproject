import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

/// 🔍 Widget de débogage pour vérifier les constats agent
class TestAgentConstatsDebug extends StatefulWidget {
  const TestAgentConstatsDebug({Key? key}) : super(key: key);

  @override
  State<TestAgentConstatsDebug> createState() => _TestAgentConstatsDebugState();
}

class _TestAgentConstatsDebugState extends State<TestAgentConstatsDebug> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _resultMessage = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Debug Agent Constats'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _verifierConstatsAgent,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('🔍 Vérifier Constats Agent'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testerOuverturePDF,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('🔗 Tester Ouverture PDF'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _resultMessage.isEmpty 
                        ? 'Cliquez sur le bouton pour vérifier les constats agent'
                        : _resultMessage,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔍 Vérifier les constats dans agent_constats
  Future<void> _verifierConstatsAgent() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      const agentId = 't1DwAgepD4W1p9lTJyQDnxcxyf72'; // Agent de test
      
      String result = '🔍 VÉRIFICATION CONSTATS AGENT\n';
      result += '=' * 50 + '\n\n';
      result += 'Agent ID: $agentId\n\n';

      // 1. Vérifier agent_constats
      final constatsQuery = await _firestore
          .collection('agent_constats')
          .where('agentId', isEqualTo: agentId)
          .orderBy('createdAt', descending: true)
          .get();

      result += '📋 COLLECTION "agent_constats":\n';
      result += '-' * 30 + '\n';
      result += 'Total trouvé: ${constatsQuery.docs.length}\n\n';

      if (constatsQuery.docs.isEmpty) {
        result += '⚠️  Aucun constat trouvé dans agent_constats\n\n';
      } else {
        for (int i = 0; i < constatsQuery.docs.length; i++) {
          final doc = constatsQuery.docs[i];
          final data = doc.data();
          
          result += '📄 CONSTAT ${i + 1}:\n';
          result += '   ID: ${doc.id}\n';
          result += '   Session: ${data['sessionId']}\n';
          result += '   Code: ${data['codeConstat']}\n';
          result += '   Client: ${data['clientNom']}\n';
          result += '   Statut: ${data['statutTraitement']}\n';
          final pdfUrl = data['pdfUrl'] as String?;
          result += '   PDF URL: $pdfUrl\n';
          result += '   PDF Valide: ${pdfUrl != null && pdfUrl.startsWith('https://') ? '✅' : '❌'}\n';
          result += '   PDF Envoyé: ${data['pdfEnvoye']}\n';
          result += '   Date création: ${data['createdAt']}\n';
          result += '   Agence: ${data['agenceNom']}\n';
          result += '   Compagnie: ${data['compagnieNom']}\n\n';
        }
      }

      // 2. Vérifier notifications
      final notificationsQuery = await _firestore
          .collection('notifications')
          .where('agentId', isEqualTo: agentId)
          .where('type', isEqualTo: 'nouveau_constat')
          .get();

      result += '🔔 COLLECTION "notifications":\n';
      result += '-' * 30 + '\n';
      result += 'Total trouvé: ${notificationsQuery.docs.length}\n\n';

      for (int i = 0; i < notificationsQuery.docs.length; i++) {
        final doc = notificationsQuery.docs[i];
        final data = doc.data();
        final donnees = data['donnees'] as Map<String, dynamic>? ?? {};
        
        result += '🔔 NOTIFICATION ${i + 1}:\n';
        result += '   ID: ${doc.id}\n';
        result += '   Titre: ${data['titre']}\n';
        result += '   Lu: ${data['lu']}\n';
        result += '   Session: ${donnees['sessionId']}\n';
        result += '   Code: ${donnees['codeConstat']}\n';
        result += '   PDF URL: ${donnees['pdfUrl']}\n\n';
      }

      // 3. Vérifier envois_constats
      final envoisQuery = await _firestore
          .collection('envois_constats')
          .where('agentId', isEqualTo: agentId)
          .get();

      result += '📤 COLLECTION "envois_constats":\n';
      result += '-' * 30 + '\n';
      result += 'Total trouvé: ${envoisQuery.docs.length}\n\n';

      for (int i = 0; i < envoisQuery.docs.length; i++) {
        final doc = envoisQuery.docs[i];
        final data = doc.data();
        
        result += '📤 ENVOI ${i + 1}:\n';
        result += '   ID: ${doc.id}\n';
        result += '   Session: ${data['sessionId']}\n';
        result += '   Code: ${data['codeConstat']}\n';
        result += '   PDF URL: ${data['pdfUrl']}\n';
        result += '   Statut: ${data['statut']}\n\n';
      }

      result += '\n✅ Vérification terminée\n';
      
      setState(() {
        _resultMessage = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _resultMessage = '❌ Erreur: $e';
        _isLoading = false;
      });
    }
  }

  /// 🔗 Tester l'ouverture d'un PDF
  Future<void> _testerOuverturePDF() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      const agentId = 't1DwAgepD4W1p9lTJyQDnxcxyf72';

      String result = '🔗 TEST OUVERTURE PDF\n';
      result += '=' * 30 + '\n\n';

      // Récupérer le premier constat avec PDF
      final constatsQuery = await _firestore
          .collection('agent_constats')
          .where('agentId', isEqualTo: agentId)
          .where('pdfUrl', isNotEqualTo: null)
          .limit(1)
          .get();

      if (constatsQuery.docs.isEmpty) {
        result += '❌ Aucun constat avec PDF trouvé\n';
      } else {
        final doc = constatsQuery.docs.first;
        final data = doc.data();
        final pdfUrl = data['pdfUrl'] as String?;

        result += '📄 Constat trouvé:\n';
        result += '   Code: ${data['codeConstat']}\n';
        result += '   PDF URL: $pdfUrl\n\n';

        if (pdfUrl != null && pdfUrl.isNotEmpty) {
          result += '🔗 Test d\'ouverture...\n';

          try {
            final uri = Uri.parse(pdfUrl);

            // Test 1: canLaunchUrl
            final canLaunch = await canLaunchUrl(uri);
            result += '   canLaunchUrl: ${canLaunch ? '✅' : '❌'}\n';

            if (canLaunch) {
              // Test 2: Essayer d'ouvrir
              result += '   Tentative d\'ouverture...\n';
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              result += '   ✅ Ouverture réussie!\n';
            } else {
              result += '   ❌ Impossible d\'ouvrir l\'URL\n';
            }

          } catch (e) {
            result += '   ❌ Erreur ouverture: $e\n';
          }
        } else {
          result += '❌ URL PDF vide ou nulle\n';
        }
      }

      setState(() {
        _resultMessage = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _resultMessage = '❌ Erreur test: $e';
        _isLoading = false;
      });
    }
  }
}
