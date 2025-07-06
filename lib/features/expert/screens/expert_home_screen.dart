// lib/features/expert/screens/expert_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_routes.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../features/auth/providers/auth_provider.dart';

class ExpertHomeScreen extends ConsumerWidget {
  const ExpertHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authProviderInstance = ref.watch(authProvider);
    final user = authProviderInstance.currentUser;
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Tableau de bord',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProviderInstance.signOut();
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
              Icons.engineering,
              size: 80,
              color: Colors.purple,
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
              'Écran d\'accueil expert',
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