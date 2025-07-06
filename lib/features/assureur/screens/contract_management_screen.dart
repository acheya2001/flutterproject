import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/widgets/custom_app_bar.dart';

class ContractManagementScreen extends ConsumerStatefulWidget {
  const ContractManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ContractManagementScreen> createState() => _ContractManagementScreenState();
}

class _ContractManagementScreenState extends ConsumerState<ContractManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Map<String, dynamic>? _agentData;
  List<Map<String, dynamic>> _contracts = [];
  List<Map<String, dynamic>> _conducteurs = [];
  bool _isLoading = true;
  int _selectedIndex = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAgentData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Gestion des Contrats',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAgentData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _selectedIndex,
              children: [
                _buildDashboardTab(),
                _buildContractsTab(),
                _buildConducteursTab(),
                _buildStatsTab(),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Tableau de Bord',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Contrats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Conducteurs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Statistiques',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informations Agent
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations Agent',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_agentData != null) ...[
                    _buildInfoRow('Nom', '${_agentData!['prenom']} ${_agentData!['nom']}'),
                    _buildInfoRow('Email', _agentData!['email']),
                    _buildInfoRow('Compagnie', _agentData!['compagnie']),
                    _buildInfoRow('Agence', _agentData!['agence']),
                    _buildInfoRow('Gouvernorat', _agentData!['gouvernorat']),
                    _buildInfoRow('Poste', _agentData!['poste']),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Statistiques rapides
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Contrats',
                  '${_contracts.length}',
                  Icons.description,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Conducteurs',
                  '${_conducteurs.length}',
                  Icons.people,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Actifs',
                  '${_contracts.where((c) => c['statut'] == 'actif').length}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'En attente',
                  '${_contracts.where((c) => c['statut'] == 'en_attente').length}',
                  Icons.pending,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContractsTab() {
    List<Map<String, dynamic>> filteredContracts = _contracts.where((contract) {
      if (_searchQuery.isEmpty) return true;
      
      String searchLower = _searchQuery.toLowerCase();
      String contractNumber = contract['numero_contrat']?.toString().toLowerCase() ?? '';
      String conducteurNom = '${contract['conducteur']?['prenom'] ?? ''} ${contract['conducteur']?['nom'] ?? ''}'.toLowerCase();
      String vehicule = '${contract['vehicule']?['marque'] ?? ''} ${contract['vehicule']?['modele'] ?? ''}'.toLowerCase();
      String immatriculation = contract['vehicule']?['immatriculation']?.toString().toLowerCase() ?? '';
      
      return contractNumber.contains(searchLower) ||
             conducteurNom.contains(searchLower) ||
             vehicule.contains(searchLower) ||
             immatriculation.contains(searchLower);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barre de recherche
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher un contrat...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),
          
          Text(
            'Contrats (${filteredContracts.length})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: filteredContracts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? 'Aucun contrat trouvé' : 'Aucun résultat pour "$_searchQuery"',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredContracts.length,
                    itemBuilder: (context, index) {
                      final contract = filteredContracts[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(contract['statut']),
                            child: Icon(
                              _getStatusIcon(contract['statut']),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            'Contrat ${contract['numero_contrat'] ?? 'N/A'}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Conducteur: ${contract['conducteur']?['prenom'] ?? ''} ${contract['conducteur']?['nom'] ?? ''}'),
                              Text('Véhicule: ${contract['vehicule']?['marque'] ?? ''} ${contract['vehicule']?['modele'] ?? ''} (${contract['vehicule']?['annee'] ?? ''})'),
                              Text('Immatriculation: ${contract['vehicule']?['immatriculation'] ?? 'N/A'}'),
                              Text('Prime: ${contract['assurance']?['prime_annuelle'] ?? 'N/A'} DT/an'),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(contract['statut']),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              contract['statut'] ?? 'N/A',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                          onTap: () => _showContractDetails(contract),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConducteursTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conducteurs (${_conducteurs.length})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _conducteurs.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun conducteur trouvé',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _conducteurs.length,
                    itemBuilder: (context, index) {
                      final conducteur = _conducteurs[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              '${conducteur['prenom']?[0] ?? ''}${conducteur['nom']?[0] ?? ''}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          title: Text(
                            '${conducteur['prenom'] ?? ''} ${conducteur['nom'] ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CIN: ${conducteur['cin'] ?? 'N/A'}'),
                              Text('Téléphone: ${conducteur['telephone'] ?? 'N/A'}'),
                              Text('Profession: ${conducteur['profession'] ?? 'N/A'}'),
                              Text('Permis: ${conducteur['permis_numero'] ?? 'N/A'} (${conducteur['permis_categorie'] ?? 'N/A'})'),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: conducteur['statut'] == 'actif' ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              conducteur['statut'] ?? 'N/A',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    Map<String, int> compagnieStats = {};
    Map<String, int> statusStats = {};

    for (var contract in _contracts) {
      String compagnie = contract['compagnie']?['code'] ?? 'Inconnue';
      String status = contract['statut'] ?? 'Inconnu';

      compagnieStats[compagnie] = (compagnieStats[compagnie] ?? 0) + 1;
      statusStats[status] = (statusStats[status] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques Détaillées',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Statistiques par compagnie
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Répartition par Compagnie',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...compagnieStats.entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${entry.value}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Statistiques par statut
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Répartition par Statut',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...statusStats.entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(entry.key),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${entry.value}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value?.toString() ?? 'N/A'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'actif':
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

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'actif':
        return Icons.check_circle;
      case 'en_attente':
        return Icons.pending;
      case 'suspendu':
        return Icons.pause_circle;
      case 'expire':
        return Icons.cancel;
      default:
        return Icons.description;
    }
  }

  Future<void> _loadAgentData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simuler un agent connecté (prendre le premier agent disponible)
      QuerySnapshot agentsSnapshot = await _firestore.collection('assureurs').limit(1).get();

      if (agentsSnapshot.docs.isNotEmpty) {
        _agentData = agentsSnapshot.docs.first.data() as Map<String, dynamic>;
        String agentId = agentsSnapshot.docs.first.id;

        // Charger les contrats de cet agent
        QuerySnapshot contractsSnapshot = await _firestore
            .collection('contracts')
            .where('createdBy', isEqualTo: agentId)
            .get();

        _contracts = contractsSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

        // Charger tous les conducteurs
        QuerySnapshot conducteursSnapshot = await _firestore
            .collection('conducteurs')
            .limit(50)
            .get();

        _conducteurs = conducteursSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

        print('📊 Agent connecté: ${_agentData!['prenom']} ${_agentData!['nom']}');
        print('📄 Contrats: ${_contracts.length}');
        print('👥 Conducteurs: ${_conducteurs.length}');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des données: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du chargement des données')),
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

  void _showContractDetails(Map<String, dynamic> contract) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Détails du Contrat'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Numéro', contract['numero_contrat']),
                _buildDetailRow('Compagnie', contract['compagnie']?['nom']),
                _buildDetailRow('Statut', contract['statut']),
                const Divider(),
                const Text('Conducteur:', style: TextStyle(fontWeight: FontWeight.bold)),
                _buildDetailRow('Nom', '${contract['conducteur']?['prenom']} ${contract['conducteur']?['nom']}'),
                _buildDetailRow('CIN', contract['conducteur']?['cin']),
                _buildDetailRow('Téléphone', contract['conducteur']?['telephone']),
                const Divider(),
                const Text('Véhicule:', style: TextStyle(fontWeight: FontWeight.bold)),
                _buildDetailRow('Marque/Modèle', '${contract['vehicule']?['marque']} ${contract['vehicule']?['modele']}'),
                _buildDetailRow('Année', contract['vehicule']?['annee']?.toString()),
                _buildDetailRow('Immatriculation', contract['vehicule']?['immatriculation']),
                _buildDetailRow('Couleur', contract['vehicule']?['couleur']),
                _buildDetailRow('Carburant', contract['vehicule']?['carburant']),
                const Divider(),
                const Text('Assurance:', style: TextStyle(fontWeight: FontWeight.bold)),
                _buildDetailRow('Type', contract['assurance']?['type_couverture']),
                _buildDetailRow('Prime annuelle', '${contract['assurance']?['prime_annuelle']} DT'),
                _buildDetailRow('Franchise', '${contract['assurance']?['franchise']} DT'),
                _buildDetailRow('Bonus/Malus', contract['assurance']?['bonus_malus']),
              ],
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

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value?.toString() ?? 'N/A'),
          ),
        ],
      ),
    );
  }
}
