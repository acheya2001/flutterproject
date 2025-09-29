import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'sinistres_tab_clean.dart';

/// 🚗 Dashboard conducteur simplifié et fonctionnel
class ConducteurDashboardSimple extends StatefulWidget {
  const ConducteurDashboardSimple({Key? key}) : super(key: key);

  @override
  State<ConducteurDashboardSimple> createState() => _ConducteurDashboardSimpleState();
}

class _ConducteurDashboardSimpleState extends State<ConducteurDashboardSimple> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _demandes = [];
  List<Map<String, dynamic>> _vehicules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      setState(() => _isLoading = true);

      // Charger les demandes depuis Firestore
      final demandesSnapshot = await FirebaseFirestore.instance
          .collection('demandes_contrat')
          .where('conducteurId', isEqualTo: user.uid)
          .get();

      // Charger les véhicules depuis Firestore
      final vehiculesSnapshot = await FirebaseFirestore.instance
          .collection('vehicules')
          .where('conducteurId', isEqualTo: user.uid)
          .get();

      setState(() {
        _demandes = demandesSnapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();

        _vehicules = vehiculesSnapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();

        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement données: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Dashboard Conducteur'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomePage(),
          _buildDemandesPage(),
          _buildVehiculesPage(),
          _buildSinistresPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Demandes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Véhicules',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Sinistres',
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bienvenue
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bienvenue !',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (context, snapshot) {
                      final user = snapshot.data;
                      return Text(
                        'Connecté en tant que: ${user?.email ?? 'Utilisateur'}',
                        style: TextStyle(color: Colors.grey[600]),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Statistiques
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Demandes',
                  _demandes.length.toString(),
                  Icons.description,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Véhicules',
                  _demandes.where((d) {
                    final statut = d['statut'] ?? '';
                    return ['contrat_actif', 'documents_completes', 'frequence_choisie'].contains(statut);
                  }).length.toString(),
                  Icons.directions_car,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Actions rapides
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Actions rapides',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/conducteur/nouvelle-demande'),
                          icon: const Icon(Icons.add),
                          label: const Text('Nouvelle demande'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _declareAccident,
                          icon: const Icon(Icons.warning),
                          label: const Text('Déclarer accident'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemandesPage() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_demandes.isEmpty) {
      return const Center(
        child: Text('Aucune demande trouvée'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _demandes.length,
      itemBuilder: (context, index) {
        final demande = _demandes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text('Demande #${demande['numero'] ?? index + 1}'),
            subtitle: Text('Statut: ${demande['statut'] ?? 'En cours'}'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _voirDetailDemande(demande),
          ),
        );
      },
    );
  }

  Widget _buildVehiculesPage() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_vehicules.isEmpty) {
      return const Center(
        child: Text('Aucun véhicule trouvé'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _vehicules.length,
      itemBuilder: (context, index) {
        final vehicule = _vehicules[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text('${vehicule['marque'] ?? 'Véhicule'} ${vehicule['modele'] ?? ''}'),
            subtitle: Text('Immatriculation: ${vehicule['immatriculation'] ?? 'N/A'}'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _voirDetailVehicule(vehicule),
          ),
        );
      },
    );
  }

  Widget _buildSinistresPage() {
    return const SinistresTabClean();
  }

  void _declareAccident() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous devez être connecté pour déclarer un accident'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Naviguer vers l'écran des accidents
      Navigator.pushNamed(context, '/conducteur/accidents');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _voirDetailDemande(Map<String, dynamic> demande) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détail Demande #${demande['numero'] ?? 'N/A'}'),
        content: Text('Statut: ${demande['statut'] ?? 'En cours'}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _voirDetailVehicule(Map<String, dynamic> vehicule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${vehicule['marque'] ?? 'Véhicule'} ${vehicule['modele'] ?? ''}'),
        content: Text('Immatriculation: ${vehicule['immatriculation'] ?? 'N/A'}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
