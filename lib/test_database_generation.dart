import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(TestDatabaseApp());
}

class TestDatabaseApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Génération DB',
      home: TestDatabaseScreen(),
    );
  }
}

class TestDatabaseScreen extends StatefulWidget {
  @override
  _TestDatabaseScreenState createState() => _TestDatabaseScreenState();
}

class _TestDatabaseScreenState extends State<TestDatabaseScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _status = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Génération Base de Données'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _testCompagniesGeneration,
              child: Text('Tester Génération Compagnies'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testAgencesGeneration,
              child: Text('Tester Génération Agences'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testAgentsGeneration,
              child: Text('Tester Génération Agents'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testConducteursGeneration,
              child: Text('Tester Génération Conducteurs'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testContratsGeneration,
              child: Text('Tester Génération Contrats'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _status,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateStatus(String message) {
    setState(() {
      _status += '${DateTime.now().toString().substring(11, 19)} - $message\n';
    });
    print(message);
  }

  Future<void> _testCompagniesGeneration() async {
    _updateStatus('🚀 Test génération compagnies...');
    
    try {
      List<String> compagnies = ['STAR', 'GAT', 'BH', 'MAGHREBIA'];
      
      for (String compagnie in compagnies) {
        await _firestore.collection('insurance_companies').doc(compagnie.toLowerCase()).set({
          'code': compagnie,
          'nom': compagnie,
          'nom_complet': _getCompagnieNomComplet(compagnie),
          'adresse_siege': 'Avenue Habib Bourguiba, Tunis',
          'telephone': '+216 71 ${Random().nextInt(900000) + 100000}',
          'email': '${compagnie.toLowerCase()}@assurance.tn',
          'date_creation': DateTime.now().subtract(Duration(days: Random().nextInt(7300))),
          'statut': 'active',
        });
        _updateStatus('✅ Compagnie $compagnie créée');
      }
      _updateStatus('✅ Test compagnies terminé avec succès !');
    } catch (e) {
      _updateStatus('❌ Erreur compagnies: $e');
    }
  }

  Future<void> _testAgencesGeneration() async {
    _updateStatus('🏢 Test génération agences...');
    
    try {
      List<String> compagnies = ['STAR', 'GAT'];
      List<String> gouvernorats = ['Tunis', 'Ariana', 'Manouba'];
      
      for (String compagnie in compagnies) {
        for (String gouvernorat in gouvernorats) {
          String agenceId = '${compagnie.toLowerCase()}_${gouvernorat.toLowerCase()}_agence1';
          
          await _firestore.collection('agences').doc(agenceId).set({
            'id': agenceId,
            'nom': 'Agence $compagnie $gouvernorat 1',
            'compagnie': compagnie,
            'gouvernorat': gouvernorat,
            'adresse': '${Random().nextInt(200) + 1} Avenue Habib Bourguiba, $gouvernorat',
            'telephone': '+216 71 ${Random().nextInt(900000) + 100000}',
            'email': 'agence1.${gouvernorat.toLowerCase()}@${compagnie.toLowerCase()}.tn',
            'responsable': 'Ahmed Ben Ali',
            'date_ouverture': DateTime.now().subtract(Duration(days: Random().nextInt(3650))),
            'statut': 'active',
          });
          _updateStatus('✅ Agence $agenceId créée');
        }
      }
      _updateStatus('✅ Test agences terminé avec succès !');
    } catch (e) {
      _updateStatus('❌ Erreur agences: $e');
    }
  }

  Future<void> _testAgentsGeneration() async {
    _updateStatus('👥 Test génération agents...');
    
    try {
      // Récupérer quelques agences
      QuerySnapshot agencesSnapshot = await _firestore.collection('agences').limit(3).get();
      
      for (QueryDocumentSnapshot agenceDoc in agencesSnapshot.docs) {
        Map<String, dynamic> agenceData = agenceDoc.data() as Map<String, dynamic>;
        
        String prenom = 'Ahmed';
        String nom = 'Ben Ali';
        String email = '${prenom.toLowerCase()}.${nom.toLowerCase().replaceAll(' ', '')}@${agenceData['compagnie'].toString().toLowerCase()}.tn';
        
        String userId = _firestore.collection('users').doc().id;
        
        // Créer l'utilisateur
        await _firestore.collection('users').doc(userId).set({
          'uid': userId,
          'email': email,
          'nom': nom,
          'prenom': prenom,
          'telephone': '+216 ${Random().nextInt(90000000) + 10000000}',
          'role': 'assureur',
          'compagnie': agenceData['compagnie'],
          'agence': agenceData['id'],
          'gouvernorat': agenceData['gouvernorat'],
          'date_creation': DateTime.now(),
          'statut': 'actif',
        });

        // Créer le type d'utilisateur
        await _firestore.collection('user_types').doc(userId).set({
          'type': 'assureur',
          'userId': userId,
        });

        // Créer l'entrée dans assureurs
        await _firestore.collection('assureurs').doc(userId).set({
          'userId': userId,
          'email': email,
          'nom': nom,
          'prenom': prenom,
          'compagnie': agenceData['compagnie'],
          'agence': agenceData['id'],
          'gouvernorat': agenceData['gouvernorat'],
          'poste': 'Agent Commercial',
          'date_embauche': DateTime.now().subtract(Duration(days: Random().nextInt(1825))),
          'statut': 'actif',
        });

        _updateStatus('✅ Agent $prenom $nom créé pour ${agenceData['compagnie']}');
      }
      _updateStatus('✅ Test agents terminé avec succès !');
    } catch (e) {
      _updateStatus('❌ Erreur agents: $e');
    }
  }

  Future<void> _testConducteursGeneration() async {
    _updateStatus('🚗 Test génération conducteurs...');
    
    try {
      for (int i = 1; i <= 10; i++) {
        String prenom = 'Conducteur$i';
        String nom = 'Test';
        String email = '${prenom.toLowerCase()}.${nom.toLowerCase()}@gmail.com';
        
        String userId = _firestore.collection('users').doc().id;
        
        // Créer l'utilisateur
        await _firestore.collection('users').doc(userId).set({
          'uid': userId,
          'email': email,
          'nom': nom,
          'prenom': prenom,
          'telephone': '+216 ${Random().nextInt(90000000) + 10000000}',
          'role': 'conducteur',
          'date_creation': DateTime.now(),
          'statut': 'actif',
        });

        // Créer le type d'utilisateur
        await _firestore.collection('user_types').doc(userId).set({
          'type': 'conducteur',
          'userId': userId,
        });

        // Créer l'entrée dans conducteurs
        await _firestore.collection('conducteurs').doc(userId).set({
          'userId': userId,
          'email': email,
          'nom': nom,
          'prenom': prenom,
          'cin': '${Random().nextInt(90000000) + 10000000}',
          'telephone': '+216 ${Random().nextInt(90000000) + 10000000}',
          'profession': 'Ingénieur',
          'permis_numero': 'P${Random().nextInt(9000000) + 1000000}',
          'permis_date_obtention': DateTime.now().subtract(Duration(days: Random().nextInt(7300) + 365)),
          'permis_categorie': 'B',
          'date_creation': DateTime.now(),
          'statut': 'actif',
        });

        _updateStatus('✅ Conducteur $prenom $nom créé');
      }
      _updateStatus('✅ Test conducteurs terminé avec succès !');
    } catch (e) {
      _updateStatus('❌ Erreur conducteurs: $e');
    }
  }

  Future<void> _testContratsGeneration() async {
    _updateStatus('📄 Test génération contrats...');
    
    try {
      // Récupérer quelques agents et conducteurs
      QuerySnapshot agentsSnapshot = await _firestore.collection('assureurs').limit(2).get();
      QuerySnapshot conducteursSnapshot = await _firestore.collection('conducteurs').limit(5).get();
      
      if (agentsSnapshot.docs.isEmpty || conducteursSnapshot.docs.isEmpty) {
        _updateStatus('❌ Pas assez d\'agents ou conducteurs pour créer des contrats');
        return;
      }

      for (int i = 1; i <= 10; i++) {
        QueryDocumentSnapshot agent = agentsSnapshot.docs[Random().nextInt(agentsSnapshot.docs.length)];
        QueryDocumentSnapshot conducteur = conducteursSnapshot.docs[Random().nextInt(conducteursSnapshot.docs.length)];
        
        Map<String, dynamic> agentData = agent.data() as Map<String, dynamic>;
        Map<String, dynamic> conducteurData = conducteur.data() as Map<String, dynamic>;
        
        String contractId = _firestore.collection('contracts').doc().id;
        
        await _firestore.collection('contracts').doc(contractId).set({
          'id': contractId,
          'numero_contrat': 'C${agentData['compagnie']}${DateTime.now().year}${i.toString().padLeft(6, '0')}',
          'compagnie': {
            'code': agentData['compagnie'],
            'nom': _getCompagnieNomComplet(agentData['compagnie']),
          },
          'agent': {
            'id': agent.id,
            'nom': agentData['nom'],
            'prenom': agentData['prenom'],
            'email': agentData['email'],
          },
          'conducteur': {
            'id': conducteur.id,
            'nom': conducteurData['nom'],
            'prenom': conducteurData['prenom'],
            'cin': conducteurData['cin'],
            'telephone': conducteurData['telephone'],
          },
          'vehicule': {
            'marque': 'Peugeot',
            'modele': '208',
            'annee': 2020,
            'immatriculation': '${Random().nextInt(900) + 100} TUN ${Random().nextInt(9000) + 1000}',
            'couleur': 'Blanc',
            'carburant': 'Essence',
          },
          'assurance': {
            'type_couverture': 'Tous Risques',
            'date_debut': DateTime.now().subtract(Duration(days: Random().nextInt(365))),
            'date_fin': DateTime.now().add(Duration(days: Random().nextInt(365) + 1)),
            'prime_annuelle': Random().nextInt(2000) + 300,
          },
          'date_creation': DateTime.now(),
          'statut': 'actif',
          'createdBy': agent.id,
          'conducteurId': conducteur.id,
        });

        _updateStatus('✅ Contrat $i créé');
      }
      _updateStatus('✅ Test contrats terminé avec succès !');
    } catch (e) {
      _updateStatus('❌ Erreur contrats: $e');
    }
  }

  String _getCompagnieNomComplet(String code) {
    switch (code) {
      case 'STAR': return 'Société Tunisienne d\'Assurance et de Réassurance';
      case 'GAT': return 'Groupe Assurances Tunis';
      case 'BH': return 'BH Assurance';
      case 'MAGHREBIA': return 'Compagnie d\'Assurance Maghrebia';
      default: return code;
    }
  }
}
