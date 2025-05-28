// lib/features/assureur/screens/assureur_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_routes.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../features/auth/providers/auth_provider.dart';

class AssureurHomeScreen extends StatelessWidget {
  const AssureurHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Tableau de bord',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.business,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            Text(
              'Bienvenue, ${user?.prenom} ${user?.nom}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Écran d\'accueil assureur',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Cette partie sera implémentée dans les prochaines étapes',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}