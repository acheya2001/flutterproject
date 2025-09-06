import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_routes.dart';
import '../../../core/widgets/custom_app_bar.dart';

class ConducteurVehiculesScreen extends ConsumerWidget {
  const ConducteurVehiculesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Mes Véhicules'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Gérez vos véhicules assurés',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.conducteurAddVehicle);
              },
              child: Text('Ajouter un Véhicule'),
            ),
            // Liste des véhicules assurés (à implémenter)
            Expanded(
              child: ListView.builder(
                itemCount: 0, // Remplacer par le nombre de véhicules
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Véhicule $index'), // Remplacer par les détails du véhicule
                    subtitle: Text('Détails du véhicule $index'), // Remplacer par les détails
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        // Logique pour supprimer le véhicule
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
