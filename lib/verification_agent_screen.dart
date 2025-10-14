import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔍 Écran de vérification des agents
class VerificationAgentScreen extends StatefulWidget {
  const VerificationAgentScreen({super.key});

  @override
  State<VerificationAgentScreen> createState() => _VerificationAgentScreenState();
}

class _VerificationAgentScreenState extends State<VerificationAgentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String _resultMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Vérification Agent'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔍 Vérification de l\'agent trouvé',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Informations trouvées dans les logs
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 Informations des logs:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('• Agent ID: t1DwAgepD4W1p9lTJyQDnxcxyf72'),
                    Text('• Email Agent: agentdemo@gmail.com'),
                    Text('• Conducteur: qZ33rPfNQ1g7tmjzED4Uh4ZYS5Y2'),
                    Text('• Session: GM855wjm5kUBpxoKHGFG'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Boutons de vérification
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🔍 Vérifications:'),
                    const SizedBox(height: 12),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _verifierContratConducteur,
                        icon: const Icon(Icons.assignment),
                        label: const Text('1. Vérifier contrat du conducteur'),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _verifierInfosAgent,
                        icon: const Icon(Icons.person),
                        label: const Text('2. Vérifier infos de l\'agent'),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _verifierNotifications,
                        icon: const Icon(Icons.notifications),
                        label: const Text('3. Vérifier notifications créées'),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _verifierTout,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('🎯 Vérifier tout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
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

  /// 1️⃣ Vérifier le contrat du conducteur
  Future<void> _verifierContratConducteur() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      const conducteurId = 'qZ33rPfNQ1g7tmjzED4Uh4ZYS5Y2';
      
      String result = '📋 VÉRIFICATION CONTRAT CONDUCTEUR:\n\n';
      result += 'Conducteur ID: $conducteurId\n\n';
      
      // Chercher dans contrats
      final contratsQuery = await _firestore
          .collection('contrats')
          .where('conducteurId', isEqualTo: conducteurId)
          .get();
      
      result += '📄 CONTRATS TROUVÉS: ${contratsQuery.docs.length}\n\n';
      
      for (final doc in contratsQuery.docs) {
        final data = doc.data();
        result += '• Contrat ID: ${doc.id}\n';
        result += '  Agent ID: ${data['agentId']}\n';
        result += '  Agent Email: ${data['agentEmail']}\n';
        result += '  Statut: ${data['statut']}\n';
        result += '  Créé le: ${data['createdAt']}\n';
        result += '  Véhicule: ${data['vehiculeMarque']} ${data['vehiculeModele']}\n';
        result += '  Immatriculation: ${data['numeroImmatriculation']}\n\n';
      }
      
      // Chercher dans demandes_contrats
      final demandesQuery = await _firestore
          .collection('demandes_contrats')
          .where('conducteurId', isEqualTo: conducteurId)
          .get();
      
      result += '📋 DEMANDES CONTRATS: ${demandesQuery.docs.length}\n\n';
      
      for (final doc in demandesQuery.docs) {
        final data = doc.data();
        result += '• Demande ID: ${doc.id}\n';
        result += '  Agent ID: ${data['agentId']}\n';
        result += '  Agent Email: ${data['agentEmail']}\n';
        result += '  Statut: ${data['statut']}\n';
        result += '  Véhicule: ${data['vehiculeMarque']} ${data['vehiculeModele']}\n\n';
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

  /// 2️⃣ Vérifier les infos de l'agent
  Future<void> _verifierInfosAgent() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      const agentId = 't1DwAgepD4W1p9lTJyQDnxcxyf72';
      
      String result = '👤 VÉRIFICATION INFOS AGENT:\n\n';
      result += 'Agent ID: $agentId\n\n';
      
      // Chercher dans agents_assurance
      final agentDoc = await _firestore
          .collection('agents_assurance')
          .doc(agentId)
          .get();
      
      if (agentDoc.exists) {
        final data = agentDoc.data()!;
        result += '✅ AGENT TROUVÉ:\n';
        result += '• Nom: ${data['nom']}\n';
        result += '• Prénom: ${data['prenom']}\n';
        result += '• Email: ${data['email']}\n';
        result += '• Téléphone: ${data['telephone']}\n';
        result += '• Agence: ${data['agenceNom']}\n';
        result += '• Compagnie: ${data['compagnieNom']}\n';
        result += '• Statut: ${data['statut']}\n';
        result += '• Créé le: ${data['createdAt']}\n\n';
      } else {
        result += '❌ AGENT NON TROUVÉ dans agents_assurance\n\n';
      }
      
      // Chercher dans users (comptes Firebase Auth)
      final userQuery = await _firestore
          .collection('users')
          .where('uid', isEqualTo: agentId)
          .get();
      
      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data();
        result += '✅ COMPTE UTILISATEUR TROUVÉ:\n';
        result += '• Email: ${userData['email']}\n';
        result += '• Rôle: ${userData['role']}\n';
        result += '• Statut: ${userData['statut']}\n';
        result += '• Compagnie ID: ${userData['compagnieId']}\n';
        result += '• Agence ID: ${userData['agenceId']}\n\n';
      } else {
        result += '❌ COMPTE UTILISATEUR NON TROUVÉ\n\n';
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

  /// 3️⃣ Vérifier les notifications créées
  Future<void> _verifierNotifications() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      const agentId = 't1DwAgepD4W1p9lTJyQDnxcxyf72';
      
      String result = '🔔 VÉRIFICATION NOTIFICATIONS:\n\n';
      result += 'Agent ID: $agentId\n\n';
      
      // Chercher les notifications
      final notificationsQuery = await _firestore
          .collection('notifications')
          .where('destinataireId', isEqualTo: agentId)
          .orderBy('dateCreation', descending: true)
          .limit(10)
          .get();
      
      result += '📱 NOTIFICATIONS TROUVÉES: ${notificationsQuery.docs.length}\n\n';
      
      for (final doc in notificationsQuery.docs) {
        final data = doc.data();
        result += '• Notification ID: ${doc.id}\n';
        result += '  Type: ${data['type']}\n';
        result += '  Titre: ${data['titre']}\n';
        result += '  Message: ${data['message']}\n';
        result += '  Lu: ${data['lu']}\n';
        result += '  Date: ${data['dateCreation']}\n';
        
        final donnees = data['donnees'] as Map<String, dynamic>?;
        if (donnees != null) {
          result += '  Session: ${donnees['sessionId']}\n';
          result += '  Code: ${donnees['codeConstat']}\n';
          result += '  Client: ${donnees['clientNom']}\n';
        }
        result += '\n';
      }
      
      // Chercher dans agent_constats
      final constatsQuery = await _firestore
          .collection('agent_constats')
          .where('agentId', isEqualTo: agentId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      
      result += '📋 CONSTATS AGENT: ${constatsQuery.docs.length}\n\n';
      
      for (final doc in constatsQuery.docs) {
        final data = doc.data();
        result += '• Constat ID: ${doc.id}\n';
        result += '  Session: ${data['sessionId']}\n';
        result += '  Code: ${data['codeConstat']}\n';
        result += '  Client: ${data['clientNom']}\n';
        result += '  Statut: ${data['statutTraitement']}\n';
        result += '  PDF: ${data['pdfEnvoye']}\n\n';
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

  /// 🎯 Vérifier tout
  Future<void> _verifierTout() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      String result = '🎯 VÉRIFICATION COMPLÈTE:\n\n';
      
      // 1. Contrats
      await _verifierContratConducteur();
      result += _resultMessage + '\n' + '='*50 + '\n\n';
      
      // 2. Agent
      await _verifierInfosAgent();
      result += _resultMessage + '\n' + '='*50 + '\n\n';
      
      // 3. Notifications
      await _verifierNotifications();
      result += _resultMessage;
      
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
