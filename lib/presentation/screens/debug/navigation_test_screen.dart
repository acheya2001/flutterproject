import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class NavigationTestScreen extends StatelessWidget {
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
            _buildHeader('Test de navigation'),
            _buildNavigationButton(context, 'Créer un constat', '/report/create'),
            _buildNavigationButton(context, 'Dashboard', '/dashboard'),
            _buildNavigationButton(context, 'Login', '/'),
            _buildHeader('Informations de débogage'),
            _buildDebugInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildNavigationButton(BuildContext context, String title, String route) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ElevatedButton(
        onPressed: () {
          _logger.d('Navigation vers: $route');
          try {
            Navigator.of(context).pushNamed(route);
            _logger.d('Navigation réussie');
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

  Widget _buildDebugInfo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Routes disponibles:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('/, /register, /dashboard, /report/create'),
            SizedBox(height: 16),
            Text('Contexte valide: ${context != null}'),
            Text('MediaQuery: ${MediaQuery.of(context).size}'),
          ],
        ),
      ),
    );
  }
}
