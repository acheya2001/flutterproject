import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:constat_tunisie/core/providers/auth_provider.dart';
import 'package:constat_tunisie/core/utils/dynamic_asset_generator.dart';
import 'package:logger/logger.dart';

class InsuranceHomeScreen extends StatefulWidget {
  const InsuranceHomeScreen({super.key});

  @override
  State<InsuranceHomeScreen> createState() => _InsuranceHomeScreenState();
}

class _InsuranceHomeScreenState extends State<InsuranceHomeScreen> {
  final Logger _logger = Logger();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _logger.i('InsuranceHomeScreen initialisé');
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();
      
      if (!mounted) return;
      
      Navigator.of(context).pushReplacementNamed('/auth');
    } catch (e) {
      _logger.e('Erreur lors de la déconnexion', e);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la déconnexion')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assurance - Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Tableau de bord',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Constats',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildReportsList();
      case 2:
        return _buildProfile();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistiques
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistiques',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Nouveaux', '12', Colors.blue),
                      _buildStatItem('En cours', '8', Colors.orange),
                      _buildStatItem('Terminés', '24', Colors.green),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Constats récents
          Text(
            'Constats récents',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: index % 3 == 0 
                        ? Colors.blue 
                        : index % 3 == 1 
                            ? Colors.orange 
                            : Colors.green,
                    child: const Icon(Icons.description, color: Colors.white),
                  ),
                  title: Text('Constat #${2000 + index}'),
                  subtitle: Text('Date: ${DateTime.now().subtract(Duration(days: index)).toString().substring(0, 10)}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _logger.i('Sélection du constat #${2000 + index}');
                    // Navigation vers le détail du constat
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 20,
      itemBuilder: (context, index) {
        final status = index % 3 == 0 ? 'Nouveau' : index % 3 == 1 ? 'En cours' : 'Terminé';
        final statusColor = index % 3 == 0 ? Colors.blue : index % 3 == 1 ? Colors.orange : Colors.green;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor,
              child: const Icon(Icons.description, color: Colors.white),
            ),
            title: Text('Constat #${2000 + index}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: ${DateTime.now().subtract(Duration(days: index)).toString().substring(0, 10)}'),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _logger.i('Sélection du constat #${2000 + index}');
              // Navigation vers le détail du constat
            },
          ),
        );
      },
    );
  }

  Widget _buildProfile() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Avatar
          FutureBuilder<Widget>(
            future: DynamicAssetGenerator.generateAvatar(
              text: user?.displayName ?? 'Assurance',
              radius: 50,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircleAvatar(
                  radius: 50,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              return snapshot.data ?? 
                const CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.business, size: 50),
                );
            },
          ),
          const SizedBox(height: 16),
          // Nom
          Text(
            user?.displayName ?? 'Compagnie d\'assurance',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          // Email
          Text(
            user?.email ?? 'Email non disponible',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          // Rôle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(50),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Assurance',
              style: TextStyle(color: Colors.blue),
            ),
          ),
          const SizedBox(height: 32),
          // Informations du profil
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildProfileItem(Icons.phone, 'Téléphone', user?.phoneNumber ?? 'Non renseigné'),
                  const Divider(),
                  _buildProfileItem(Icons.calendar_today, 'Membre depuis', user?.createdAt != null 
                      ? '${user!.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'
                      : 'Date inconnue'),
                  const Divider(),
                  _buildProfileItem(Icons.location_on, 'Adresse', 'Tunis, Tunisie'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Bouton de modification du profil
          ElevatedButton.icon(
            onPressed: () {
              _logger.i('Modification du profil');
              // Navigation vers la page de modification du profil
            },
            icon: const Icon(Icons.edit),
            label: const Text('Modifier le profil'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(50),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}