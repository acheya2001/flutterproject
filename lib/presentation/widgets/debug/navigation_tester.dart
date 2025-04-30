import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class NavigationTester extends StatelessWidget {
  final Logger _logger = Logger();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test de Navigation'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tester la navigation',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildNavigationButton(
              context,
              'Dashboard',
              '/dashboard',
            ),
            _buildNavigationButton(
              context,
              'Créer un constat',
              '/report/create',
            ),
            _buildNavigationButton(
              context,
              'Liste des constats',
              '/report/list',
            ),
            _buildNavigationButton(
              context,
              'Profil',
              '/profile',
            ),
            _buildNavigationButton(
              context,
              'Liste des véhicules',
              '/vehicle/list',
            ),
            _buildNavigationButton(
              context,
              'Ajouter un véhicule',
              '/vehicle/add',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButton(
    BuildContext context,
    String title,
    String route, [
    Map<String, dynamic>? arguments,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ElevatedButton(
        onPressed: () {
          _logger.d('Test de navigation vers: $route');
          try {
            if (arguments != null) {
              Navigator.of(context).pushNamed(route, arguments: arguments);
            } else {
              Navigator.of(context).pushNamed(route);
            }
          } catch (e) {
            _logger.e('Erreur de navigation: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur: $e')),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(title),
        ),
      ),
    );
  }
}
