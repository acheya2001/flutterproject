import 'package:flutter/material.dart';
import '../../../features/admin/services/global_admin_setup.dart';
import 'admin_login_screen.dart';

/// 🎯 Écran de sélection du type d'admin
class AdminTypeSelectionScreen extends StatelessWidget {
  const AdminTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('🎯 Administration'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.deepPurple.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 64,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Choisissez votre type d\'administration',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sélectionnez le niveau d\'accès approprié',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Types d'admin
            _buildAdminTypeCard(
              context,
              title: '👑 Super Administrateur',
              subtitle: 'Gestion globale du système',
              description: 'Accès complet à toutes les compagnies, agences et fonctionnalités',
              color: Colors.red,
              adminType: 'super_admin',
              features: [
                'Toutes les compagnies d\'assurance',
                'Toutes les agences',
                'Approbation de toutes les demandes',
                'Statistiques globales',
                'Gestion des admins',
              ],
            ),

            const SizedBox(height: 20),

            _buildAdminTypeCard(
              context,
              title: '🏢 Admin Compagnie',
              subtitle: 'Gestion d\'une compagnie d\'assurance',
              description: 'Accès limité à votre compagnie et ses agences',
              color: Colors.blue,
              adminType: 'admin_compagnie',
              features: [
                'Votre compagnie uniquement',
                'Toutes vos agences',
                'Demandes de votre compagnie',
                'Statistiques de votre compagnie',
                'Gestion de vos agents',
              ],
            ),

            const SizedBox(height: 20),

            _buildAdminTypeCard(
              context,
              title: '🏪 Admin Agence',
              subtitle: 'Gestion d\'une agence spécifique',
              description: 'Accès limité à votre agence uniquement',
              color: Colors.green,
              adminType: 'admin_agence',
              features: [
                'Votre agence uniquement',
                'Demandes de votre agence',
                'Statistiques de votre agence',
                'Gestion de vos agents',
                'Approbation locale',
              ],
            ),

            const SizedBox(height: 32),

            // Bouton d'initialisation
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Première utilisation ?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Initialisez d\'abord le système pour créer tous les comptes admin.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _initializeSystem(context),
                      icon: const Icon(Icons.rocket_launch),
                      label: const Text('Initialiser le Système'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminTypeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required Color color,
    required String adminType,
    required List<String> features,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToLogin(context, adminType),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconForType(adminType),
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: color,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: features.map((feature) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    feature,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String adminType) {
    switch (adminType) {
      case 'super_admin':
        return Icons.admin_panel_settings;
      case 'admin_compagnie':
        return Icons.business;
      case 'admin_agence':
        return Icons.store;
      default:
        return Icons.person;
    }
  }

  void _navigateToLogin(BuildContext context, String adminType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminLoginScreen(adminType: adminType),
      ),
    );
  }

  Future<void> _initializeSystem(BuildContext context) async {
    // Afficher un dialog de confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚀 Initialiser le Système'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cette action va créer :'),
            SizedBox(height: 8),
            Text('• Toutes les compagnies d\'assurance'),
            Text('• Toutes les agences'),
            Text('• Tous les comptes admin'),
            Text('• Données de test'),
            SizedBox(height: 16),
            Text(
              'Cette opération peut prendre quelques minutes.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Initialiser'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Afficher un dialog de progression
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initialisation en cours...'),
          ],
        ),
      ),
    );

    try {
      final success = await GlobalAdminSetup.initializeCompleteSystem();
      
      if (context.mounted) {
        Navigator.pop(context); // Fermer le dialog de progression
        
        if (success) {
          // Afficher les emails créés
          _showAdminEmails(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Erreur lors de l\'initialisation'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAdminEmails(BuildContext context) {
    final emails = GlobalAdminSetup.getAllAdminEmails();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Système Initialisé !'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comptes admin créés avec succès :',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...emails.entries.map((entry) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...entry.value.map((email) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Text(
                        email,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    )),
                    const SizedBox(height: 12),
                  ],
                )),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Parfait !'),
          ),
        ],
      ),
    );
  }
}
