import 'package:flutter/material.dart';
import 'package:constat_tunisie/core/enums/user_role.dart';
import 'package:constat_tunisie/core/providers/auth_provider.dart';
import 'package:constat_tunisie/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

class DriverHomeScreen extends StatelessWidget {
  final Logger _logger = Logger();

  DriverHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/auth');
                }
              } catch (e) {
                _logger.e('Erreur lors de la déconnexion: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur lors de la déconnexion: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profil utilisateur
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.driverColor,
                      radius: 30,
                      child: Text(
                        user?.displayName?.isNotEmpty == true
                            ? user!.displayName![0].toUpperCase()
                            : 'C',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'Conducteur',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'Email non disponible',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rôle: ${user?.role.displayName ?? 'Conducteur'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Actions rapides
            const Text(
              'Actions rapides',
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
              children: [
                _buildActionCard(
                  context,
                  icon: Icons.add_circle,
                  title: 'Nouveau constat',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.of(context).pushNamed('/new-report');
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.history,
                  title: 'Mes constats',
                  color: Colors.green,
                  onTap: () {
                    Navigator.of(context).pushNamed('/my-reports');
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.person,
                  title: 'Mon profil',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.of(context).pushNamed('/profile');
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.help,
                  title: 'Aide',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.of(context).pushNamed('/help');
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Constats récents
            const Text(
              'Constats récents',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Liste des constats récents
            _buildRecentReportsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentReportsList() {
    // Simuler des données de constats récents
    final recentReports = [
      {'id': '1000', 'date': '2025-04-29'},
      {'id': '1001', 'date': '2025-04-28'},
      {'id': '1002', 'date': '2025-04-27'},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentReports.length,
      itemBuilder: (context, index) {
        final report = recentReports[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(
                Icons.description,
                color: Colors.white,
              ),
            ),
            title: Text('Constat #${report['id']}'),
            subtitle: Text('Date: ${report['date']}'),
            trailing: IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                // Naviguer vers les détails du constat
                Navigator.of(context).pushNamed(
                  '/report-details',
                  arguments: report['id'],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
