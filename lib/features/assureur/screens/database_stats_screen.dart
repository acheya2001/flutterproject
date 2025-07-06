import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/widgets/custom_app_bar.dart';

class DatabaseStatsScreen extends ConsumerStatefulWidget {
  const DatabaseStatsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DatabaseStatsScreen> createState() => _DatabaseStatsScreenState();
}

class _DatabaseStatsScreenState extends ConsumerState<DatabaseStatsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, int> _counts = {};
  List<Map<String, dynamic>> _sampleData = [];
  bool _isLoading = false;
  String _selectedCollection = 'contracts';

  @override
  void initState() {
    super.initState();
    _verifyDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Statistiques Base de Données',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _verifyDatabase,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Statistiques générales
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Statistiques de la Base de Données',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.5,
                            children: [
                              _buildStatCard('Compagnies', _counts['insurance_companies'] ?? 0, Icons.business, Colors.blue),
                              _buildStatCard('Agences', _counts['agences'] ?? 0, Icons.location_city, Colors.green),
                              _buildStatCard('Agents', _counts['assureurs'] ?? 0, Icons.person_pin, Colors.orange),
                              _buildStatCard('Conducteurs', _counts['conducteurs'] ?? 0, Icons.people, Colors.purple),
                              _buildStatCard('Contrats', _counts['contracts'] ?? 0, Icons.description, Colors.red),
                              _buildStatCard('Utilisateurs', _counts['users'] ?? 0, Icons.account_circle, Colors.teal),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Sélecteur de collection
                  Row(
                    children: [
                      const Text(
                        'Voir les données:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedCollection,
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(value: 'contracts', child: Text('Contrats')),
                            const DropdownMenuItem(value: 'assureurs', child: Text('Agents')),
                            const DropdownMenuItem(value: 'conducteurs', child: Text('Conducteurs')),
                            const DropdownMenuItem(value: 'agences', child: Text('Agences')),
                            const DropdownMenuItem(value: 'insurance_companies', child: Text('Compagnies')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCollection = value;
                              });
                              _loadSampleData(value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Données d'exemple
                  Expanded(
                    child: _sampleData.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.data_usage, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'Sélectionnez une collection pour voir les données',
                                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _sampleData.length,
                            itemBuilder: (context, index) {
                              final data = _sampleData[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  title: Text(
                                    _getItemTitle(data),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(_getItemSubtitle(data)),
                                  trailing: _getItemTrailing(data),
                                  onTap: () => _showItemDetails(data),
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

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getItemTitle(Map<String, dynamic> data) {
    switch (_selectedCollection) {
      case 'contracts':
        return 'Contrat ${data['numero_contrat'] ?? 'N/A'}';
      case 'assureurs':
        return '${data['prenom'] ?? ''} ${data['nom'] ?? ''}';
      case 'conducteurs':
        return '${data['prenom'] ?? ''} ${data['nom'] ?? ''}';
      case 'agences':
        return data['nom'] ?? 'Agence';
      case 'insurance_companies':
        return data['nom'] ?? 'Compagnie';
      default:
        return 'Élément';
    }
  }

  String _getItemSubtitle(Map<String, dynamic> data) {
    switch (_selectedCollection) {
      case 'contracts':
        return 'Compagnie: ${data['compagnie']?['code'] ?? 'N/A'} | Conducteur: ${data['conducteur']?['prenom'] ?? ''} ${data['conducteur']?['nom'] ?? ''}';
      case 'assureurs':
        return 'Compagnie: ${data['compagnie'] ?? 'N/A'} | Poste: ${data['poste'] ?? 'N/A'}';
      case 'conducteurs':
        return 'CIN: ${data['cin'] ?? 'N/A'} | Profession: ${data['profession'] ?? 'N/A'}';
      case 'agences':
        return 'Compagnie: ${data['compagnie'] ?? 'N/A'} | Gouvernorat: ${data['gouvernorat'] ?? 'N/A'}';
      case 'insurance_companies':
        return 'Code: ${data['code'] ?? 'N/A'} | Statut: ${data['statut'] ?? 'N/A'}';
      default:
        return 'Détails';
    }
  }

  Widget? _getItemTrailing(Map<String, dynamic> data) {
    String? status;
    switch (_selectedCollection) {
      case 'contracts':
        status = data['statut'];
        break;
      case 'assureurs':
      case 'conducteurs':
        status = data['statut'];
        break;
      case 'agences':
      case 'insurance_companies':
        status = data['statut'];
        break;
    }

    if (status != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getStatusColor(status),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      );
    }
    return null;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'actif':
      case 'active':
        return Colors.green;
      case 'en_attente':
        return Colors.orange;
      case 'suspendu':
        return Colors.red;
      case 'expire':
        return Colors.grey;
      default:
        return Colors.blue;
    }
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
      });

      // Charger les données d'exemple pour la collection sélectionnée
      await _loadSampleData(_selectedCollection);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la vérification: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSampleData(String collection) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(collection)
          .limit(20)
          .get();

      List<Map<String, dynamic>> data = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      setState(() {
        _sampleData = data;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des données: $e')),
        );
      }
    }
  }

  void _showItemDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Détails - ${_getItemTitle(data)}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: data.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          '${entry.key}:',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(
                        child: Text(entry.value?.toString() ?? 'N/A'),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }
}
