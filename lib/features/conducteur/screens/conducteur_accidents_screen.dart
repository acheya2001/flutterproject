import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_routes.dart';
import '../../../core/widgets/custom_app_bar.dart';

class ConducteurAccidentsScreen extends ConsumerWidget {
  const ConducteurAccidentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Mes Sinistres'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Historique de vos sinistres',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.declarationEntryPoint);
              },
              child: Text('Déclarer un Nouveau Sinistre'),
            ),
            // Liste des sinistres (à implémenter)
            Expanded(
              child: ListView.builder(
                itemCount: 0, // Remplacer par le nombre de sinistres
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Sinistre $index'), // Remplacer par les détails du sinistre
                    subtitle: Text('Détails du sinistre $index'), // Remplacer par les détails
                    trailing: IconButton(
                      icon: Icon(Icons.visibility),
                      onPressed: () {
                        // Logique pour voir les détails du sinistre
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
