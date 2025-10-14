import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/constat_agent_notification_service.dart';
import 'services/agent_dashboard_notification_service.dart';

/// 🧪 Page de test pour les notifications d'agents
class TestNotificationAgentPage extends StatefulWidget {
  const TestNotificationAgentPage({super.key});

  @override
  State<TestNotificationAgentPage> createState() => _TestNotificationAgentPageState();
}

class _TestNotificationAgentPageState extends State<TestNotificationAgentPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String _resultMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Test Notifications Agent'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🧪 Tests des notifications d\'agents',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Test 1: Vérifier les contrats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📋 Test 1: Vérifier les contrats avec agents'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testerContrats,
                      child: const Text('Vérifier les contrats'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test 2: Créer une notification test
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🔔 Test 2: Créer une notification test'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _creerNotificationTest,
                      child: const Text('Créer notification test'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test 3: Lister les notifications
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📱 Test 3: Lister les notifications'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _listerNotifications,
                      child: const Text('Lister notifications'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test 4: Tester avec une vraie session
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🎯 Test 4: Tester avec session GM855wjm5kUBpxoKHGFG'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testerAvecVraieSession,
                      child: const Text('Tester avec vraie session'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Résultats
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
            
            if (_resultMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  _resultMessage,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 📋 Test 1: Vérifier les contrats
  Future<void> _testerContrats() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      final contrats = await _firestore.collection('contrats').get();
      
      String result = '📋 CONTRATS TROUVÉS:\n\n';
      result += 'Total: ${contrats.docs.length}\n\n';
      
      for (final doc in contrats.docs.take(5)) {
        final data = doc.data();
        result += '• ID: ${doc.id}\n';
        result += '  Conducteur: ${data['conducteurId']}\n';
        result += '  Agent: ${data['agentId']}\n';
        result += '  Email Agent: ${data['agentEmail']}\n';
        result += '  Statut: ${data['statut']}\n\n';
      }
      
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

  /// 🔔 Test 2: Créer une notification test
  Future<void> _creerNotificationTest() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      // Créer une notification test
      await AgentDashboardNotificationService.creerNotification(
        destinataireId: 'test_agent_id',
        titre: 'Test Notification',
        message: 'Ceci est un test de notification',
        type: 'nouveau_constat',
        donnees: {
          'sessionId': 'test_session',
          'codeConstat': 'TEST123',
          'clientNom': 'Client Test',
          'pdfUrl': 'https://test.pdf',
        },
      );
      
      setState(() {
        _resultMessage = '✅ Notification test créée avec succès!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _resultMessage = '❌ Erreur création notification: $e';
        _isLoading = false;
      });
    }
  }

  /// 📱 Test 3: Lister les notifications
  Future<void> _listerNotifications() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      final notifications = await _firestore
          .collection('notifications')
          .orderBy('dateCreation', descending: true)
          .limit(10)
          .get();
      
      String result = '📱 NOTIFICATIONS TROUVÉES:\n\n';
      result += 'Total: ${notifications.docs.length}\n\n';
      
      for (final doc in notifications.docs) {
        final data = doc.data();
        result += '• ID: ${doc.id}\n';
        result += '  Type: ${data['type']}\n';
        result += '  Destinataire: ${data['destinataireId']}\n';
        result += '  Titre: ${data['titre']}\n';
        result += '  Lu: ${data['lu']}\n\n';
      }
      
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

  /// 🎯 Test 4: Tester avec une vraie session
  Future<void> _testerAvecVraieSession() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      String result = '🎯 TEST AVEC VRAIE SESSION:\n\n';
      
      // 1. Vérifier la session
      final sessionDoc = await _firestore
          .collection('sessions_collaboratives')
          .doc('GM855wjm5kUBpxoKHGFG')
          .get();
      
      if (!sessionDoc.exists) {
        result += '❌ Session GM855wjm5kUBpxoKHGFG non trouvée\n';
      } else {
        final sessionData = sessionDoc.data()!;
        result += '✅ Session trouvée\n';
        result += 'Participants: ${sessionData['participants']?.length ?? 0}\n\n';
        
        // 2. Pour chaque participant, chercher l'agent
        final participants = sessionData['participants'] as List<dynamic>? ?? [];
        
        for (final participant in participants) {
          final conducteurId = participant['userId'];
          result += '👤 Participant: ${participant['prenom']} ${participant['nom']}\n';
          result += '   ID: $conducteurId\n';
          
          // Chercher dans les contrats
          final contratsQuery = await _firestore
              .collection('contrats')
              .where('conducteurId', isEqualTo: conducteurId)
              .get();
          
          result += '   Contrats trouvés: ${contratsQuery.docs.length}\n';
          
          for (final contratDoc in contratsQuery.docs) {
            final contratData = contratDoc.data();
            result += '   • Contrat: ${contratDoc.id}\n';
            result += '     Agent: ${contratData['agentId']}\n';
            result += '     Email: ${contratData['agentEmail']}\n';
            result += '     Statut: ${contratData['statut']}\n';
          }
          
          result += '\n';
        }
      }
      
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
}
