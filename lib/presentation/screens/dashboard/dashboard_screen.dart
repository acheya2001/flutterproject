import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:constat_tunisie/core/providers/auth_provider.dart';
import 'package:logger/logger.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Logger _logger = Logger();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              _logger.d('Navigation vers les paramètres');
              _navigateWithDebug(context, '/settings');
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              _logger.d('Déconnexion');
              try {
                await authProvider.signOut();
                Navigator.of(context).pushReplacementNamed('/');
              } catch (e) {
                _logger.e('Erreur lors de la déconnexion: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur lors de la déconnexion')),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenue, ${user?.displayName ?? "Utilisateur"}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildDashboardCard(
                      context,
                      'Nouveau constat',
                      Icons.add_circle,
                      Colors.blue,
                      () => _navigateWithDebug(context, '/report/create'),
                    ),
                    _buildDashboardCard(
                      context,
                      'Rejoindre un constat',
                      Icons.group_add,
                      Colors.green,
                      () => _navigateWithDebug(context, '/report/join'),
                    ),
                    _buildDashboardCard(
                      context,
                      'Mes constats',
                      Icons.description,
                      Colors.orange,
                      () => _navigateWithDebug(context, '/report/list'),
                    ),
                    _buildDashboardCard(
                      context,
                      'Mon profil',
                      Icons.person,
                      Colors.purple,
                      () => _navigateWithDebug(context, '/profile'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateWithDebug(BuildContext context, String route, [Map<String, dynamic>? arguments]) {
    _logger.d('Tentative de navigation vers: $route');
    try {
      if (arguments != null) {
        Navigator.of(context).pushNamed(route, arguments: arguments);
      } else {
        Navigator.of(context).pushNamed(route);
      }
      _logger.d('Navigation réussie vers: $route');
    } catch (e) {
      _logger.e('Erreur de navigation vers $route: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de navigation: $e')),
      );
    }
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: () {
        _logger.d('Carte cliquée: $title');
        onTap();
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withOpacity(0.7)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
