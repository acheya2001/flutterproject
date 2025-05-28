import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../../../features/auth/providers/auth_provider.dart';

class ConducteurProfileScreen extends StatelessWidget {
  const ConducteurProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Mon profil',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du profil
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      // Correction de la vérification des valeurs nullables
                      (user?.prenom != null && user!.prenom.isNotEmpty && 
                       user.nom != null && user.nom.isNotEmpty)
                          ? '${user.prenom[0]}${user.nom[0]}'
                          : 'U',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${user?.prenom ?? ''} ${user?.nom ?? ''}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Conducteur',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Informations personnelles
            const Text(
              'Informations personnelles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoItem(Icons.email, 'Email', user?.email ?? 'Non renseigné'),
            _buildInfoItem(Icons.phone, 'Téléphone', user?.telephone ?? 'Non renseigné'),
            _buildInfoItem(Icons.location_on, 'Adresse', user?.adresse ?? 'Non renseignée'),
            
            const SizedBox(height: 32),
            
            // Boutons d'action
            ElevatedButton(
              onPressed: () {
                // Naviguer vers l'écran de modification du profil
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Modification du profil à venir')),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Modifier mon profil'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                // Naviguer vers l'écran de modification du mot de passe
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Modification du mot de passe à venir')),
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Changer mon mot de passe'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.blue,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}