import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🧪 Test des notifications dans le dashboard agent
class TestAgentNotificationsDashboard extends StatefulWidget {
  const TestAgentNotificationsDashboard({super.key});

  @override
  State<TestAgentNotificationsDashboard> createState() => _TestAgentNotificationsDashboardState();
}

class _TestAgentNotificationsDashboardState extends State<TestAgentNotificationsDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String _resultMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Test Notifications Dashboard Agent'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🧪 Test des notifications dans le dashboard agent',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Informations
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎯 Ce test va :',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('• Créer une notification de constat avec les bons champs'),
                    Text('• Vérifier que l\'icône de notification l\'affiche'),
                    Text('• Tester le compteur de notifications non lues'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '👤 Agent testé:',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800]),
                          ),
                          const SizedBox(height: 4),
                          Text('• ID: t1DwAgepD4W1p9lTJyQDnxcxyf72'),
                          Text('• Email: agentdemo@gmail.com'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Boutons de test
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _creerNotificationConstat,
                icon: Icon(Icons.add_alert, color: Colors.white),
                label: const Text(
                  '📄 Créer notification de constat',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _verifierCompteurNotifications,
                icon: Icon(Icons.notifications, color: Colors.white),
                label: const Text(
                  '🔔 Vérifier compteur notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _supprimerToutesNotifications,
                icon: Icon(Icons.delete_sweep, color: Colors.white),
                label: const Text(
                  '🗑️ Supprimer toutes les notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _resultMessage,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
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

  /// 📄 Créer une notification de constat
  Future<void> _creerNotificationConstat() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      const agentId = 't1DwAgepD4W1p9lTJyQDnxcxyf72';
      
      // Créer une notification de constat avec les VRAIS champs du dashboard
      final docRef = await _firestore.collection('notifications').add({
        // ✅ Champs EXACTS utilisés par le dashboard agent
        'agentId': agentId,                         // ✅ agentId (pas recipientId)
        'lu': false,                                // ✅ lu (pas isRead)
        'dateCreation': FieldValue.serverTimestamp(), // ✅ dateCreation (pas createdAt)
        
        // Contenu spécifique au constat
        'type': 'nouveau_constat',
        'titre': 'Nouveau constat reçu',
        'message': 'Constat GM855wjm5kUBpxoKHGFG - Client: Test Client',
        'donnees': {
          'sessionId': 'GM855wjm5kUBpxoKHGFG',
          'codeConstat': '9CRTCN',
          'clientNom': 'Test Client',
          'clientRole': 'A',
          'pdfUrl': 'https://firebasestorage.googleapis.com/v0/b/assuranceaccident-2c2fa.appspot.com/o/constats%2Ftest.pdf?alt=media',
        },
        'dateExpiration': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
      });
      
      setState(() {
        _resultMessage = '✅ NOTIFICATION CRÉÉE!\n\n'
            'ID: ${docRef.id}\n'
            'Type: nouveau_constat\n'
            'Agent: $agentId\n'
            'Titre: Nouveau constat reçu\n'
            'lu: false\n'
            'dateCreation: ${DateTime.now()}\n\n'
            '🎯 Maintenant :\n'
            '1. Allez dans le dashboard agent\n'
            '2. Vérifiez l\'icône de notification (🔔)\n'
            '3. Elle devrait afficher un badge rouge avec "1"\n'
            '4. Cliquez dessus pour voir la notification';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _resultMessage = '❌ ERREUR: $e';
        _isLoading = false;
      });
    }
  }

  /// 🔔 Vérifier le compteur de notifications
  Future<void> _verifierCompteurNotifications() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      const agentId = 't1DwAgepD4W1p9lTJyQDnxcxyf72';
      
      // Requête EXACTE utilisée par le dashboard agent
      final query = await _firestore
          .collection('notifications')
          .where('agentId', isEqualTo: agentId)     // ✅ agentId (comme dans le dashboard)
          .where('lu', isEqualTo: false)            // ✅ lu (comme dans le dashboard)
          .get();
      
      String result = '🔔 COMPTEUR NOTIFICATIONS:\n';
      result += '=' * 40 + '\n\n';
      result += 'Agent ID: $agentId\n';
      result += 'Notifications non lues: ${query.docs.length}\n\n';
      
      if (query.docs.isEmpty) {
        result += '⚠️  AUCUNE NOTIFICATION NON LUE\n';
        result += 'L\'icône ne devrait pas avoir de badge.\n';
      } else {
        result += '✅ NOTIFICATIONS TROUVÉES:\n\n';
        for (final doc in query.docs) {
          final data = doc.data();
          result += '📄 ${doc.id.substring(0, 8)}...\n';
          result += '   Type: ${data['type']}\n';
          result += '   Titre: ${data['titre']}\n';
          result += '   lu: ${data['lu']}\n';
          result += '   dateCreation: ${data['dateCreation']}\n\n';
        }
        result += '🎯 L\'icône devrait afficher: ${query.docs.length}';
      }
      
      setState(() {
        _resultMessage = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _resultMessage = '❌ ERREUR: $e';
        _isLoading = false;
      });
    }
  }

  /// 🗑️ Supprimer toutes les notifications
  Future<void> _supprimerToutesNotifications() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      const agentId = 't1DwAgepD4W1p9lTJyQDnxcxyf72';
      
      // Récupérer toutes les notifications de l'agent
      final query = await _firestore
          .collection('notifications')
          .where('agentId', isEqualTo: agentId)     // ✅ agentId (comme dans le dashboard)
          .get();
      
      // Supprimer en batch
      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      setState(() {
        _resultMessage = '✅ SUPPRESSION TERMINÉE!\n\n'
            'Notifications supprimées: ${query.docs.length}\n\n'
            '🎯 Maintenant :\n'
            '1. L\'icône de notification ne devrait plus avoir de badge\n'
            '2. Le compteur devrait être à 0\n'
            '3. Aucune notification dans la liste';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _resultMessage = '❌ ERREUR: $e';
        _isLoading = false;
      });
    }
  }
}
