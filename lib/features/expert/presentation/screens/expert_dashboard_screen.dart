import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// 🔧 Dashboard de l'expert automobile
class ExpertDashboardScreen extends StatelessWidget {
  const ExpertDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Expert Automobile'),
        backgroundColor: AppTheme.accentColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context, 
                '/user-type-selection', 
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.engineering,
              size: 100,
              color: AppTheme.accentColor,
            ),
            SizedBox(height: 24),
            Text(
              'Bienvenue dans votre espace expert !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Ici vous pourrez :\n'
              '• Effectuer les expertises\n'
              '• Rédiger les rapports\n'
              '• Prendre des photos\n'
              '• Valider les dommages',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
