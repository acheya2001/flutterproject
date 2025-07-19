import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// 🚗 Dashboard du conducteur
class ConducteurDashboardScreen extends StatelessWidget {
  const ConducteurDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Conducteur'),
        backgroundColor: AppTheme.primaryColor,
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
              Icons.person,
              size: 100,
              color: AppTheme.primaryColor,
            ),
            SizedBox(height: 24),
            Text(
              'Bienvenue dans votre espace conducteur !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Ici vous pourrez :\n'
              '• Déclarer vos accidents\n'
              '• Suivre vos dossiers\n'
              '• Gérer vos véhicules\n'
              '• Consulter vos constats',
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
