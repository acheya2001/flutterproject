import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(VerifyDatabaseApp());
}

class VerifyDatabaseApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vérification Base de Données',
      home: VerifyDatabaseScreen(),
    );
  }
}

class VerifyDatabaseScreen extends StatefulWidget {
  @override
  _VerifyDatabaseScreenState createState() => _VerifyDatabaseScreenState();
}

class _VerifyDatabaseScreenState extends State<VerifyDatabaseScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, int> _counts = {};
  List<Map<String, dynamic>> _sampleData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _verifyDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vérification Base de Données'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Statistiques de la Base de Données',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 16),
                          ..._counts.entries.map((entry) => Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(entry.key, style: TextStyle(fontSize: 16)),
                                    Text(
                                      '${entry.value}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _verifyDatabase,
                          child: Text('Actualiser'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _showSampleContracts,
                          child: Text('Voir Contrats'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: _sampleData.isEmpty
                        ? Center(
                            child: Text(
                              'Cliquez sur "Voir Contrats" pour afficher des exemples',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _sampleData.length,
                            itemBuilder: (context, index) {
                              final contract = _sampleData[index];
                              return Card(
                                margin: EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  title: Text(
                                    'Contrat ${contract['numero_contrat'] ?? 'N/A'}',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Compagnie: ${contract['compagnie']?['code'] ?? 'N/A'}'),
                                      Text('Conducteur: ${contract['conducteur']?['prenom'] ?? ''} ${contract['conducteur']?['nom'] ?? ''}'),
                                      Text('Véhicule: ${contract['vehicule']?['marque'] ?? ''} ${contract['vehicule']?['modele'] ?? ''}'),
                                      Text('Immatriculation: ${contract['vehicule']?['immatriculation'] ?? 'N/A'}'),
                                    ],
                                  ),
                                  trailing: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: contract['statut'] == 'actif' ? Colors.green : Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      contract['statut'] ?? 'N/A',
                                      style: TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _verifyDatabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, int> counts = {};

      // Compter les documents dans chaque collection
      List<String> collections = [
        'insurance_companies',
        'agences',
        'users',
        'user_types',
        'assureurs',
        'conducteurs',
        'contracts',
      ];

      for (String collection in collections) {
        QuerySnapshot snapshot = await _firestore.collection(collection).get();
        counts[collection] = snapshot.docs.length;
      }

      setState(() {
        _counts = counts;
        _isLoading = false;
      });

      print('📊 Statistiques de la base de données:');
      counts.forEach((key, value) {
        print('  $key: $value documents');
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('❌ Erreur lors de la vérification: $e');
    }
  }

  Future<void> _showSampleContracts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('contracts')
          .limit(10)
          .get();

      List<Map<String, dynamic>> contracts = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      setState(() {
        _sampleData = contracts;
        _isLoading = false;
      });

      print('📄 Échantillon de contrats récupéré: ${contracts.length} contrats');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('❌ Erreur lors de la récupération des contrats: $e');
    }
  }
}
