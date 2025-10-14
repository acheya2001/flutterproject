import 'package:flutter/material.dart';
import '../services/constat_agent_notification_service.dart';

/// 📧 Exemple d'utilisation du service d'envoi de PDF aux agents
class ConstatAgentNotificationExample {
  
  /// 🎯 Exemple 1: Envoi simple à partir d'un ID de session
  static Future<void> exempleEnvoiSimple() async {
    try {
      const sessionId = 'GM855wjm5kUBpxoKHGFG'; // ID de session réel
      
      print('📧 [EXEMPLE] Début envoi PDF aux agents pour session: $sessionId');
      
      final resultat = await ConstatAgentNotificationService.envoyerConstatAuxAgents(
        sessionId: sessionId,
      );
      
      if (resultat['success']) {
        print('✅ [EXEMPLE] Envoi réussi !');
        print('   - Agents contactés: ${resultat['totalAgents']}');
        print('   - Envois réussis: ${resultat['envoisReussis']}');
        print('   - Envois échoués: ${resultat['envoisEchoues']}');
      } else {
        print('❌ [EXEMPLE] Envoi échoué: ${resultat['error']}');
      }
      
    } catch (e) {
      print('❌ [EXEMPLE] Erreur: $e');
    }
  }
  
  /// 🎯 Exemple 2: Widget de test pour l'interface
  static Widget buildTestWidget() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Envoi PDF Agents'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📧 Test d\'envoi de PDF aux agents',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            const Text(
              'Ce test va :\n'
              '1. Identifier les agents responsables de chaque participant\n'
              '2. Générer un PDF personnalisé pour chaque agent\n'
              '3. Envoyer le PDF par email\n'
              '4. Afficher le résultat',
              style: TextStyle(fontSize: 14),
            ),
            
            const SizedBox(height: 24),
            
            ElevatedButton.icon(
              onPressed: () => exempleEnvoiSimple(),
              icon: const Icon(Icons.send),
              label: const Text('Tester l\'envoi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Comment ça marche :',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Le service identifie automatiquement l\'agent responsable de chaque conducteur\n'
                    '• Un PDF personnalisé est généré pour chaque agent\n'
                    '• L\'email contient les informations du client de l\'agent\n'
                    '• Le PDF est accessible via un lien de téléchargement sécurisé',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 🎯 Exemple 3: Utilisation dans un widget existant
  static void exempleIntegrationWidget(BuildContext context, String sessionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📧 Envoyer aux Agents'),
        content: const Text(
          'Voulez-vous envoyer le PDF du constat aux agents d\'assurance responsables ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              // Afficher un indicateur de chargement
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Envoi en cours...'),
                    ],
                  ),
                ),
              );
              
              try {
                final resultat = await ConstatAgentNotificationService.envoyerConstatAuxAgents(
                  sessionId: sessionId,
                );
                
                Navigator.of(context).pop(); // Fermer le loading
                
                // Afficher le résultat
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      resultat['success'] 
                        ? '✅ PDF envoyé à ${resultat['envoisReussis']} agent(s)'
                        : '❌ Erreur: ${resultat['error']}'
                    ),
                    backgroundColor: resultat['success'] ? Colors.green : Colors.red,
                  ),
                );
                
              } catch (e) {
                Navigator.of(context).pop(); // Fermer le loading
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Erreur: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}

/// 📱 Page de test complète
class ConstatAgentNotificationTestPage extends StatefulWidget {
  const ConstatAgentNotificationTestPage({super.key});

  @override
  State<ConstatAgentNotificationTestPage> createState() => _ConstatAgentNotificationTestPageState();
}

class _ConstatAgentNotificationTestPageState extends State<ConstatAgentNotificationTestPage> {
  final TextEditingController _sessionIdController = TextEditingController(
    text: 'GM855wjm5kUBpxoKHGFG', // ID de session par défaut
  );
  
  bool _isLoading = false;
  Map<String, dynamic>? _lastResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Envoi PDF Agents'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _sessionIdController,
              decoration: const InputDecoration(
                labelText: 'ID de Session',
                hintText: 'Entrez l\'ID de la session collaborative',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _testerEnvoi,
                icon: _isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
                label: Text(_isLoading ? 'Envoi en cours...' : 'Tester l\'envoi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            if (_lastResult != null) ...[
              const Text(
                'Dernier résultat :',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _lastResult!['success'] ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _lastResult!['success'] ? Colors.green[200]! : Colors.red[200]!,
                  ),
                ),
                child: Text(
                  _lastResult!['success']
                    ? '✅ Succès !\n'
                      'Agents contactés: ${_lastResult!['totalAgents']}\n'
                      'Envois réussis: ${_lastResult!['envoisReussis']}\n'
                      'Envois échoués: ${_lastResult!['envoisEchoues']}'
                    : '❌ Erreur !\n${_lastResult!['error']}',
                  style: TextStyle(
                    color: _lastResult!['success'] ? Colors.green[800] : Colors.red[800],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Future<void> _testerEnvoi() async {
    if (_sessionIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un ID de session'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _lastResult = null;
    });
    
    try {
      final resultat = await ConstatAgentNotificationService.envoyerConstatAuxAgents(
        sessionId: _sessionIdController.text.trim(),
      );
      
      setState(() {
        _lastResult = resultat;
      });
      
    } catch (e) {
      setState(() {
        _lastResult = {
          'success': false,
          'error': e.toString(),
        };
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _sessionIdController.dispose();
    super.dispose();
  }
}
