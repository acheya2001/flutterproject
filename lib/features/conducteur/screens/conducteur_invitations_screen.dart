import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_routes.dart';
import '../../../core/widgets/custom_app_bar.dart';

class ConducteurInvitationsScreen extends ConsumerWidget {
  const ConducteurInvitationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Mes Invitations'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Gérez vos invitations de constat',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fonctionnalité temporairement indisponible'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              child: Text('Rejoindre une Session'),
            ),
            // Liste des invitations (à implémenter)
            Expanded(
              child: ListView.builder(
                itemCount: 0, // Remplacer par le nombre d'invitations
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Invitation $index'), // Remplacer par les détails de l'invitation
                    subtitle: Text('Détails de l\'invitation $index'), // Remplacer par les détails
                    trailing: IconButton(
                      icon: Icon(Icons.check),
                      onPressed: () {
                        // Logique pour accepter l'invitation
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
