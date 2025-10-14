import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🧪 Test simple de notification
class TestNotificationSimple extends StatefulWidget {
  const TestNotificationSimple({super.key});

  @override
  State<TestNotificationSimple> createState() => _TestNotificationSimpleState();
}

class _TestNotificationSimpleState extends State<TestNotificationSimple> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String _resultMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Test Notification Simple'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🧪 Test de notification avec les bons champs',
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
                      '🎯 Ce test va créer une notification avec:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('• recipientId: t1DwAgepD4W1p9lTJyQDnxcxyf72'),
                    Text('• recipientType: agent'),
                    Text('• isRead: false'),
                    Text('• createdAt: timestamp'),
                    Text('• type: nouveau_constat'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Bouton de test
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _creerNotificationCorrecte,
                icon: Icon(Icons.add_alert, color: Colors.white),
                label: const Text(
                  '🧪 Créer notification avec bons champs',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _verifierNotifications,
                icon: Icon(Icons.search, color: Colors.white),
                label: const Text(
                  '🔍 Vérifier notifications créées',
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

  /// 🧪 Créer une notification avec les bons champs
  Future<void> _creerNotificationCorrecte() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      const agentId = 't1DwAgepD4W1p9lTJyQDnxcxyf72';
      
      // Créer avec les champs que l'app agent utilise
      final docRef = await _firestore.collection('notifications').add({
        // ✅ Champs corrects selon les logs d'erreur
        'recipientId': agentId,
        'recipientType': 'agent',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        
        // Contenu de la notification
        'type': 'nouveau_constat',
        'titre': 'Test - Nouveau constat reçu',
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
        _resultMessage = '✅ SUCCÈS!\n\n'
            'Notification créée avec les BONS champs:\n\n'
            '📋 ID: ${docRef.id}\n'
            '👤 recipientId: $agentId\n'
            '🏷️ recipientType: agent\n'
            '📖 isRead: false\n'
            '⏰ createdAt: ${DateTime.now()}\n'
            '📄 type: nouveau_constat\n\n'
            'Maintenant l\'agent devrait pouvoir voir cette notification!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _resultMessage = '❌ ERREUR: $e';
        _isLoading = false;
      });
    }
  }

  /// 🔍 Vérifier les notifications
  Future<void> _verifierNotifications() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      const agentId = 't1DwAgepD4W1p9lTJyQDnxcxyf72';
      
      // Requête exacte que l'app agent utilise (sans orderBy pour éviter l'index)
      final query = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: agentId)
          .where('recipientType', isEqualTo: 'agent')
          .where('isRead', isEqualTo: false)
          .get();
      
      String result = '🔍 VÉRIFICATION NOTIFICATIONS:\n';
      result += '=' * 40 + '\n\n';
      result += 'Requête utilisée par l\'app agent:\n';
      result += '• recipientId == $agentId\n';
      result += '• recipientType == agent\n';
      result += '• isRead == false\n\n';
      result += 'Résultats trouvés: ${query.docs.length}\n\n';
      
      if (query.docs.isEmpty) {
        result += '⚠️  AUCUNE NOTIFICATION TROUVÉE\n';
        result += 'L\'agent ne verra rien dans son interface.\n';
      } else {
        result += '✅ NOTIFICATIONS TROUVÉES:\n\n';
        for (final doc in query.docs) {
          final data = doc.data();
          result += '📋 ID: ${doc.id.substring(0, 8)}...\n';
          result += '   Type: ${data['type']}\n';
          result += '   Titre: ${data['titre']}\n';
          result += '   recipientId: ${data['recipientId']}\n';
          result += '   recipientType: ${data['recipientType']}\n';
          result += '   isRead: ${data['isRead']}\n';
          result += '   createdAt: ${data['createdAt']}\n\n';
        }
        result += '🎉 L\'agent devrait voir ces ${query.docs.length} notification(s)!';
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
}
