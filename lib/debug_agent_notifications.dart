import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔍 Debug des notifications agent
class DebugAgentNotifications extends StatefulWidget {
  const DebugAgentNotifications({super.key});

  @override
  State<DebugAgentNotifications> createState() => _DebugAgentNotificationsState();
}

class _DebugAgentNotificationsState extends State<DebugAgentNotifications> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String _resultMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Debug Notifications Agent'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔍 Debug des notifications pour l\'agent',
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
                onPressed: _isLoading ? null : _verifierToutesCollections,
                icon: Icon(Icons.search, color: Colors.white),
                label: const Text(
                  '🔍 Vérifier toutes les collections',
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
                onPressed: _isLoading ? null : _creerNotificationDansAncienneCollection,
                icon: Icon(Icons.add, color: Colors.white),
                label: const Text(
                  '➕ Créer dans notifications_agents',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
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
                onPressed: _isLoading ? null : _creerDansEnvoisConstats,
                icon: Icon(Icons.send, color: Colors.white),
                label: const Text(
                  '📤 Créer dans envois_constats',
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

  /// 🔍 Vérifier toutes les collections
  Future<void> _verifierToutesCollections() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      const agentId = 't1DwAgepD4W1p9lTJyQDnxcxyf72';
      const agentEmail = 'agentdemo@gmail.com';
      
      String result = '🔍 VÉRIFICATION TOUTES COLLECTIONS:\n';
      result += '=' * 50 + '\n\n';

      // 1. Collection notifications (notre nouvelle)
      try {
        final notificationsQuery = await _firestore
            .collection('notifications')
            .where('destinataireId', isEqualTo: agentId)
            .get();

        result += '📱 COLLECTION "notifications" (NOUVELLE):\n';
        result += '-' * 40 + '\n';
        result += 'Total trouvé: ${notificationsQuery.docs.length}\n\n';

        if (notificationsQuery.docs.isEmpty) {
          result += '   ⚠️  Aucune notification trouvée\n';
        } else {
          for (final doc in notificationsQuery.docs) {
            final data = doc.data();
            result += '✅ ID: ${doc.id.substring(0, 8)}...\n';
            result += '   Type: ${data['type']}\n';
            result += '   Titre: ${data['titre']}\n';
            result += '   Lu: ${data['lu']}\n';
            result += '   Date: ${data['dateCreation']}\n\n';
          }
        }
        result += '\n';
      } catch (e) {
        result += '❌ ERREUR notifications: $e\n\n';
      }
      
      // 2. Collection notifications_agents (ancienne)
      try {
        final notificationsAgentsQuery = await _firestore
            .collection('notifications_agents')
            .where('destinataire', isEqualTo: agentEmail)
            .get();

        result += '📧 COLLECTION "notifications_agents" (ANCIENNE):\n';
        result += '-' * 40 + '\n';
        result += 'Total trouvé: ${notificationsAgentsQuery.docs.length}\n\n';

        if (notificationsAgentsQuery.docs.isEmpty) {
          result += '   ⚠️  Aucune notification trouvée\n';
        } else {
          for (final doc in notificationsAgentsQuery.docs) {
            final data = doc.data();
            result += '✅ ID: ${doc.id.substring(0, 8)}...\n';
            result += '   Type: ${data['type']}\n';
            result += '   Titre: ${data['titre']}\n';
            result += '   Destinataire: ${data['destinataire']}\n';
            result += '   Lu: ${data['lu']}\n\n';
          }
        }
        result += '\n';
      } catch (e) {
        result += '❌ ERREUR notifications_agents: $e\n\n';
      }
      
      // 3. Collection envois_constats
      try {
        final envoisQuery = await _firestore
            .collection('envois_constats')
            .where('agentId', isEqualTo: agentId)
            .get();

        result += '📤 COLLECTION "envois_constats" (INTERFACE AGENT):\n';
        result += '-' * 40 + '\n';
        result += 'Total trouvé: ${envoisQuery.docs.length}\n\n';

        if (envoisQuery.docs.isEmpty) {
          result += '   ⚠️  Aucun envoi trouvé\n';
        } else {
          for (final doc in envoisQuery.docs) {
            final data = doc.data();
            result += '✅ ID: ${doc.id.substring(0, 8)}...\n';
            result += '   Session: ${data['sessionId']}\n';
            result += '   Code: ${data['codeConstat']}\n';
            result += '   Statut: ${data['statut']}\n';
            result += '   Client: ${data['clientNom']}\n\n';
          }
        }
        result += '\n';
      } catch (e) {
        result += '❌ ERREUR envois_constats: $e\n\n';
      }

      // 4. Collection agent_constats (notre nouvelle)
      try {
        final agentConstatsQuery = await _firestore
            .collection('agent_constats')
            .where('agentId', isEqualTo: agentId)
            .get();

        result += '📋 COLLECTION "agent_constats" (ESPACE SINISTRE):\n';
        result += '-' * 40 + '\n';
        result += 'Total trouvé: ${agentConstatsQuery.docs.length}\n\n';

        if (agentConstatsQuery.docs.isEmpty) {
          result += '   ⚠️  Aucun constat trouvé\n';
        } else {
          for (final doc in agentConstatsQuery.docs) {
            final data = doc.data();
            result += '✅ ID: ${doc.id.substring(0, 8)}...\n';
            result += '   Code: ${data['codeConstat']}\n';
            result += '   Client: ${data['clientNom']}\n';
            result += '   Statut: ${data['statutTraitement']}\n';
            result += '   PDF: ${data['pdfEnvoye']}\n\n';
          }
        }
        result += '\n';
      } catch (e) {
        result += '❌ ERREUR agent_constats: $e\n\n';
      }

      result += '=' * 50 + '\n';
      result += '🎯 RÉSUMÉ:\n';
      result += '• notifications: Nouvelle collection pour notifications\n';
      result += '• notifications_agents: Ancienne collection (compatibilité)\n';
      result += '• envois_constats: Collection pour interface agent\n';
      result += '• agent_constats: Collection pour espace sinistre\n';
      
      setState(() {
        _resultMessage = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _resultMessage = '❌ Erreur générale: $e';
        _isLoading = false;
      });
    }
  }

  /// ➕ Créer notification dans l'ancienne collection
  Future<void> _creerNotificationDansAncienneCollection() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      const agentEmail = 'agentdemo@gmail.com';
      
      // Créer dans notifications_agents (ancienne collection)
      await _firestore.collection('notifications_agents').add({
        'destinataire': agentEmail,
        'type': 'constat_finalise',
        'titre': 'Nouveau constat reçu',
        'message': 'Constat GM855wjm5kUBpxoKHGFG finalisé',
        'sessionId': 'GM855wjm5kUBpxoKHGFG',
        'codeConstat': '9CRTCN',
        'pdfUrl': 'https://firebasestorage.googleapis.com/v0/b/assuranceaccident-2c2fa.appspot.com/o/constats%2Ftest.pdf?alt=media',
        'lu': false,
        'dateCreation': FieldValue.serverTimestamp(),
      });
      
      setState(() {
        _resultMessage = '✅ SUCCÈS!\n\n'
            'Notification créée dans la collection "notifications_agents"\n\n'
            '📧 Destinataire: $agentEmail\n'
            '📋 Type: constat_finalise\n'
            '🎯 Titre: Nouveau constat reçu\n'
            '📅 Date: ${DateTime.now()}\n\n'
            'Utilisez "Vérifier toutes les collections" pour voir le résultat.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _resultMessage = '❌ Erreur: $e';
        _isLoading = false;
      });
    }
  }

  /// 📤 Créer dans envois_constats
  Future<void> _creerDansEnvoisConstats() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      const agentId = 't1DwAgepD4W1p9lTJyQDnxcxyf72';
      
      // Créer dans envois_constats
      await _firestore.collection('envois_constats').add({
        'agentId': agentId,
        'agentEmail': 'agentdemo@gmail.com',
        'sessionId': 'GM855wjm5kUBpxoKHGFG',
        'codeConstat': '9CRTCN',
        'pdfUrl': 'https://firebasestorage.googleapis.com/v0/b/assuranceaccident-2c2fa.appspot.com/o/constats%2Ftest.pdf?alt=media',
        'statut': 'envoye',
        'dateEnvoi': FieldValue.serverTimestamp(),
        'clientNom': 'Test Client',
        'clientRole': 'A',
      });
      
      setState(() {
        _resultMessage = '✅ SUCCÈS!\n\n'
            'Document créé dans la collection "envois_constats"\n\n'
            '👤 Agent ID: $agentId\n'
            '📧 Email: agentdemo@gmail.com\n'
            '📋 Session: GM855wjm5kUBpxoKHGFG\n'
            '🎯 Code: 9CRTCN\n'
            '📅 Date: ${DateTime.now()}\n\n'
            'Utilisez "Vérifier toutes les collections" pour voir le résultat.';
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
