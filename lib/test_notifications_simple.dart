import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🧪 Test simple des notifications
class TestNotificationsSimple extends StatefulWidget {
  const TestNotificationsSimple({super.key});

  @override
  State<TestNotificationsSimple> createState() => _TestNotificationsSimpleState();
}

class _TestNotificationsSimpleState extends State<TestNotificationsSimple> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String _resultMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Test Notifications Simple'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🧪 Test simple des notifications',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Informations de l'agent
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '👤 Agent testé:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('• ID: t1DwAgepD4W1p9lTJyQDnxcxyf72'),
                    Text('• Email: agentdemo@gmail.com'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Boutons de test
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _listerNotifications,
                icon: const Icon(Icons.list),
                label: const Text('📋 Lister toutes les notifications'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _listerConstatsAgent,
                icon: const Icon(Icons.assignment),
                label: const Text('📄 Lister constats agent'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _creerNotificationTest,
                icon: const Icon(Icons.add),
                label: const Text('➕ Créer notification test'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Résultats
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
            
            if (_resultMessage.isNotEmpty)
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _resultMessage,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 📋 Lister toutes les notifications
  Future<void> _listerNotifications() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      const agentId = 't1DwAgepD4W1p9lTJyQDnxcxyf72';
      
      String result = '📋 TOUTES LES NOTIFICATIONS:\n\n';
      
      // Requête simple sans orderBy
      final notificationsQuery = await _firestore
          .collection('notifications')
          .where('destinataireId', isEqualTo: agentId)
          .get();
      
      result += 'Total trouvé: ${notificationsQuery.docs.length}\n\n';
      
      for (final doc in notificationsQuery.docs) {
        final data = doc.data();
        result += '• ${doc.id}\n';
        result += '  Type: ${data['type']}\n';
        result += '  Titre: ${data['titre']}\n';
        result += '  Lu: ${data['lu']}\n';
        result += '  Date: ${data['dateCreation']}\n';
        
        final donnees = data['donnees'] as Map<String, dynamic>?;
        if (donnees != null) {
          result += '  Session: ${donnees['sessionId']}\n';
          result += '  Code: ${donnees['codeConstat']}\n';
        }
        result += '\n';
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

  /// 📄 Lister les constats agent
  Future<void> _listerConstatsAgent() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      const agentId = 't1DwAgepD4W1p9lTJyQDnxcxyf72';
      
      String result = '📄 CONSTATS AGENT:\n\n';
      
      // Requête simple
      final constatsQuery = await _firestore
          .collection('agent_constats')
          .where('agentId', isEqualTo: agentId)
          .get();
      
      result += 'Total trouvé: ${constatsQuery.docs.length}\n\n';
      
      for (final doc in constatsQuery.docs) {
        final data = doc.data();
        result += '• ${doc.id}\n';
        result += '  Session: ${data['sessionId']}\n';
        result += '  Code: ${data['codeConstat']}\n';
        result += '  Client: ${data['clientNom']}\n';
        result += '  Statut: ${data['statutTraitement']}\n';
        result += '  PDF: ${data['pdfEnvoye']}\n';
        result += '  Date: ${data['createdAt']}\n\n';
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

  /// ➕ Créer une notification test
  Future<void> _creerNotificationTest() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      const agentId = 't1DwAgepD4W1p9lTJyQDnxcxyf72';
      
      // Créer une notification simple
      await _firestore.collection('notifications').add({
        'type': 'test',
        'destinataireId': agentId,
        'destinataireType': 'agent',
        'titre': 'Test Notification',
        'message': 'Ceci est un test créé à ${DateTime.now()}',
        'donnees': {
          'test': true,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        'lu': false,
        'dateCreation': FieldValue.serverTimestamp(),
        'dateExpiration': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
      });
      
      setState(() {
        _resultMessage = '✅ Notification test créée avec succès!\n\nActualisez la liste pour la voir.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _resultMessage = '❌ Erreur création: $e';
        _isLoading = false;
      });
    }
  }
}
