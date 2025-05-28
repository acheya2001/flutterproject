import 'package:flutter/material.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/config/app_routes.dart'; // Ajout de l'import manquant

class ConducteurAccidentsScreen extends StatelessWidget {
  const ConducteurAccidentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Historique des constats',
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucun constat enregistré',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Vos constats apparaîtront ici',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Naviguer vers l'écran de création de constat
                Navigator.pushNamed(context, AppRoutes.conducteurDeclaration);
              },
              icon: const Icon(Icons.add),
              label: const Text('Créer un constat'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}