import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class ReportDetailsScreen extends StatelessWidget {
  final String reportId;
  final Logger _logger = Logger();
  
  ReportDetailsScreen({Key? key, required this.reportId}) : super(key: key);

  // Ajoutez cette méthode statique à la classe ReportDetailsScreen
  static void navigateTo(BuildContext context, String reportId) {
    Navigator.of(context).pushNamed(
      '/report/details',
      arguments: {'reportId': reportId},
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.d('Affichage des détails du rapport: $reportId');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails du constat'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Détails du constat',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('ID du constat: $reportId'),
            SizedBox(height: 32),
            Text('Cette page est en cours de développement'),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}
