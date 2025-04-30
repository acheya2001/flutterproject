import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class ReportListScreen extends StatelessWidget {
  final Logger _logger = Logger();
  
  ReportListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    _logger.d('Affichage de la liste des constats');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes constats'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Liste des constats',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Cette page est en cours de développement'),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Retour au tableau de bord'),
            ),
          ],
        ),
      ),
    );
  }
}
