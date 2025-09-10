import 'package:flutter/material.dart';

/// 🚧 Fichier temporaire pour remplacer conducteur_dashboard_complete.dart
/// qui a des erreurs de compilation
class ConducteurDashboardComplete extends StatefulWidget {
  const ConducteurDashboardComplete({Key? key}) : super(key: key);

  @override
  State<ConducteurDashboardComplete> createState() => _ConducteurDashboardCompleteState();
}

class _ConducteurDashboardCompleteState extends State<ConducteurDashboardComplete> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Conducteur'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Colors.orange,
            ),
            SizedBox(height: 16),
            Text(
              'Dashboard en cours de réparation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Veuillez patienter...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
