import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🧪 Script de test pour vérifier le dashboard agent
class TestAgentDashboard {
  static Future<void> testAgentData() async {
    print('🔍 Test du dashboard agent...');
    
    try {
      // 1. Vérifier les agents dans la collection users
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .get();
      
      print('👥 Agents trouvés dans users: ${usersSnapshot.docs.length}');
      
      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        print('👤 Agent: ${data['prenom']} ${data['nom']} - ID: ${doc.id} - Email: ${data['email']}');
        
        // 2. Vérifier les demandes affectées à cet agent
        final demandesSnapshot = await FirebaseFirestore.instance
            .collection('demandes_contrats')
            .where('agentId', isEqualTo: doc.id)
            .get();
        
        print('📋 Demandes affectées à ${data['prenom']}: ${demandesSnapshot.docs.length}');
        
        for (final demandeDoc in demandesSnapshot.docs) {
          final demandeData = demandeDoc.data();
          print('  📄 Demande ${demandeData['numero']} - Statut: ${demandeData['statut']}');
        }
      }
      
      // 3. Vérifier toutes les demandes de contrats
      final allDemandesSnapshot = await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .get();
      
      print('📊 Total demandes de contrats: ${allDemandesSnapshot.docs.length}');
      
      for (final doc in allDemandesSnapshot.docs) {
        final data = doc.data();
        print('📄 Demande ${data['numero']} - Statut: ${data['statut']} - AgentId: ${data['agentId']}');
      }
      
    } catch (e) {
      print('❌ Erreur test: $e');
    }
  }
  
  /// 🔧 Créer des données de test si nécessaire
  static Future<void> createTestData() async {
    print('🔧 Création de données de test...');
    
    try {
      // Créer une demande de test affectée à un agent
      await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .add({
        'numero': 'D-TEST-${DateTime.now().millisecondsSinceEpoch}',
        'statut': 'affectee',
        'agentId': 'AGENT_ID_TEST', // Remplacer par un vrai ID d'agent
        'agentNom': 'Agent Test',
        'prenom': 'Ahmed',
        'nom': 'Ben Ali',
        'email': 'ahmed.benali@test.com',
        'marque': 'Peugeot',
        'modele': '208',
        'immatriculation': '123 TUN 456',
        'formuleAssurance': 'tous_risques',
        'formuleAssuranceLabel': 'Tous Risques',
        'dateCreation': FieldValue.serverTimestamp(),
        'dateAffectation': FieldValue.serverTimestamp(),
        'compagnieId': 'test_compagnie',
        'agenceId': 'test_agence',
      });
      
      print('✅ Demande de test créée');
      
    } catch (e) {
      print('❌ Erreur création test: $e');
    }
  }
}

/// 🎯 Widget de test pour le dashboard
class TestAgentDashboardWidget extends StatelessWidget {
  const TestAgentDashboardWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Test Agent Dashboard'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => TestAgentDashboard.testAgentData(),
              child: const Text('🔍 Tester les données agent'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => TestAgentDashboard.createTestData(),
              child: const Text('🔧 Créer données de test'),
            ),
            const SizedBox(height: 32),
            const Text(
              '📝 Instructions:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Cliquez "Tester les données agent" pour voir les logs\n'
              '2. Vérifiez la console pour les résultats\n'
              '3. Si aucune demande trouvée, créez des données de test\n'
              '4. Connectez-vous en tant qu\'agent pour voir le dashboard',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
