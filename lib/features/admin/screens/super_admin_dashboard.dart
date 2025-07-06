import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 👑 Dashboard Super Admin avec vue globale
class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  bool _isLoading = true;
  Map<String, dynamic> _globalStats = {};
  List<Map<String, dynamic>> _compagnies = [];
  List<Map<String, dynamic>> _demandesRecentes = [];

  @override
  void initState() {
    super.initState();
    _loadGlobalData();
  }

  Future<void> _loadGlobalData() async {
    setState(() => _isLoading = true);
    
    try {
      // Charger les statistiques globales
      await _loadGlobalStats();
      
      // Charger les compagnies avec leurs statistiques
      await _loadCompagniesWithStats();
      
      // Charger les demandes récentes
      await _loadRecentDemandes();
      
    } catch (e) {
      print('❌ Erreur chargement données: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadGlobalStats() async {
    final compagniesSnapshot = await FirebaseFirestore.instance
        .collection('compagnies_assurance')
        .get();
    
    final agencesSnapshot = await FirebaseFirestore.instance
        .collection('agences_assurance')
        .get();
    
    final demandesSnapshot = await FirebaseFirestore.instance
        .collection('demandes_agents')
        .get();
    
    final agentsSnapshot = await FirebaseFirestore.instance
        .collection('agents_assurance')
        .get();

    final demandesEnAttente = demandesSnapshot.docs
        .where((doc) => doc.data()['statut'] == 'en_attente')
        .length;

    setState(() {
      _globalStats = {
        'totalCompagnies': compagniesSnapshot.docs.length,
        'totalAgences': agencesSnapshot.docs.length,
        'totalDemandes': demandesSnapshot.docs.length,
        'demandesEnAttente': demandesEnAttente,
        'totalAgents': agentsSnapshot.docs.length,
      };
    });
  }

  Future<void> _loadCompagniesWithStats() async {
    final compagniesSnapshot = await FirebaseFirestore.instance
        .collection('compagnies_assurance')
        .get();

    List<Map<String, dynamic>> compagniesWithStats = [];

    for (final compagnieDoc in compagniesSnapshot.docs) {
      final compagnieData = compagnieDoc.data();
      compagnieData['id'] = compagnieDoc.id;

      // Compter les agences de cette compagnie
      final agencesSnapshot = await FirebaseFirestore.instance
          .collection('agences_assurance')
          .where('compagnieId', isEqualTo: compagnieDoc.id)
          .get();

      // Compter les demandes de cette compagnie
      final demandesSnapshot = await FirebaseFirestore.instance
          .collection('demandes_agents')
          .where('compagnieId', isEqualTo: compagnieDoc.id)
          .get();

      // Compter les agents de cette compagnie
      final agentsSnapshot = await FirebaseFirestore.instance
          .collection('agents_assurance')
          .where('compagnieId', isEqualTo: compagnieDoc.id)
          .get();

      compagnieData['stats'] = {
        'agences': agencesSnapshot.docs.length,
        'demandes': demandesSnapshot.docs.length,
        'agents': agentsSnapshot.docs.length,
        'demandesEnAttente': demandesSnapshot.docs
            .where((doc) => doc.data()['statut'] == 'en_attente')
            .length,
      };

      compagniesWithStats.add(compagnieData);
    }

    setState(() => _compagnies = compagniesWithStats);
  }

  Future<void> _loadRecentDemandes() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('demandes_agents')
        .orderBy('dateCreation', descending: true)
        .limit(10)
        .get();

    setState(() {
      _demandesRecentes = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('👑 Super Administration'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGlobalData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/user-type-selection');
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadGlobalData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGlobalStatsGrid(),
                    const SizedBox(height: 24),
                    _buildCompagniesSection(),
                    const SizedBox(height: 24),
                    _buildRecentDemandesSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGlobalStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📊 Statistiques Globales',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
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
            _buildStatCard(
              'Compagnies',
              _globalStats['totalCompagnies']?.toString() ?? '0',
              Icons.business,
              Colors.blue,
            ),
            _buildStatCard(
              'Agences',
              _globalStats['totalAgences']?.toString() ?? '0',
              Icons.store,
              Colors.green,
            ),
            _buildStatCard(
              'Demandes en Attente',
              _globalStats['demandesEnAttente']?.toString() ?? '0',
              Icons.pending_actions,
              Colors.orange,
            ),
            _buildStatCard(
              'Agents Actifs',
              _globalStats['totalAgents']?.toString() ?? '0',
              Icons.people,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompagniesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🏢 Compagnies d\'Assurance',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _compagnies.length,
          itemBuilder: (context, index) {
            final compagnie = _compagnies[index];
            final stats = compagnie['stats'] as Map<String, dynamic>;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.business, color: Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                compagnie['nom'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                compagnie['adresse'] ?? '',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniStat('Agences', stats['agences'].toString(), Icons.store),
                        ),
                        Expanded(
                          child: _buildMiniStat('Agents', stats['agents'].toString(), Icons.people),
                        ),
                        Expanded(
                          child: _buildMiniStat('Demandes', stats['demandesEnAttente'].toString(), Icons.pending),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentDemandesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '📋 Demandes Récentes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Naviguer vers la liste complète des demandes
              },
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _demandesRecentes.length,
          itemBuilder: (context, index) {
            final demande = _demandesRecentes[index];
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  child: Text(
                    '${demande['prenom']?[0] ?? ''}${demande['nom']?[0] ?? ''}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text('${demande['prenom']} ${demande['nom']}'),
                subtitle: Text('${demande['compagnieNom']} - ${demande['agenceNom']}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'En attente',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () {
                  // TODO: Ouvrir les détails de la demande
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
