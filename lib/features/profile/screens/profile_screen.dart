import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Profil',
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;
          
          if (user == null) {
            return const Center(
              child: Text('Utilisateur non connecté'),
            );
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Avatar et informations de base
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    '${user.prenom.substring(0, 1)}${user.nom.substring(0, 1)}'.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Text(
                  '${user.prenom} ${user.nom}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Informations détaillées
                _buildInfoCard(context, user),
                const SizedBox(height: 32),
                
                // Bouton de déconnexion
                CustomButton(
                  text: 'Se déconnecter',
                  onPressed: () async {
                    await authProvider.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/login',
                        (route) => false,
                      );
                    }
                  },
                  color: Colors.red,
                  isFullWidth: true,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations personnelles',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow('Prénom', user.prenom),
            _buildInfoRow('Nom', user.nom),
            _buildInfoRow('Email', user.email),
            _buildInfoRow('Téléphone', user.telephone ?? 'Non renseigné'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
