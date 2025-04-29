import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:constat_tunisie/core/providers/auth_provider.dart';
import 'package:constat_tunisie/core/utils/dynamic_asset_generator.dart';
import 'package:logger/logger.dart';

class ExpertHomeScreen extends StatefulWidget {
  const ExpertHomeScreen({super.key});

  @override
  State<ExpertHomeScreen> createState() => _ExpertHomeScreenState();
}

class _ExpertHomeScreenState extends State<ExpertHomeScreen> with SingleTickerProviderStateMixin {
  final Logger _logger = Logger();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _logger.i('ExpertHomeScreen initialisé');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expert - Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'À évaluer'),
            Tab(text: 'En cours'),
            Tab(text: 'Terminés'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportsList('À évaluer', Colors.orange),
          _buildReportsList('En cours', Colors.blue),
          _buildReportsList('Terminés', Colors.green),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _logger.i('Ouverture du profil expert');
          _showExpertProfile(context);
        },
        child: const Icon(Icons.person),
      ),
    );
  }

  Widget _buildReportsList(String status, Color statusColor) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor,
              child: const Icon(Icons.description, color: Colors.white),
            ),
            title: Text('Constat #${3000 + index}'),
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
              _logger.i('Sélection du constat #${3000 + index}');
              // Navigation vers le détail du constat
            },
          ),
        );
      },
    );
  }

  void _showExpertProfile(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Avatar
                    FutureBuilder<Widget>(
                      future: DynamicAssetGenerator.generateAvatar(
                        text: user?.displayName ?? 'Expert',
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
                            child: Icon(Icons.person, size: 50),
                          );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Nom
                    Text(
                      user?.displayName ?? 'Expert',
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
                        color: Colors.purple.withAlpha(50),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Expert',
                        style: TextStyle(color: Colors.purple),
                      ),
                    ),
                    const SizedBox(height: 32),
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
                                _buildStatItem('À évaluer', '5', Colors.orange),
                                _buildStatItem('En cours', '3', Colors.blue),
                                _buildStatItem('Terminés', '42', Colors.green),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
                            _buildProfileItem(Icons.location_on, 'Zone d\'expertise', 'Tunis, Tunisie'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Bouton de modification du profil
                    ElevatedButton.icon(
                      onPressed: () {
                        _logger.i('Modification du profil');
                        Navigator.pop(context);
                        // Navigation vers la page de modification du profil
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Modifier le profil'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
          Icon(icon, color: Colors.purple),
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