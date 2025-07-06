import 'package:flutter/material.dart';

/// ⚡ Widget actions rapides pour le dashboard assureur
class QuickActionsWidget extends StatelessWidget {
  final String compagnieId;

  const QuickActionsWidget({
    super.key,
    required this.compagnieId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                const Icon(Icons.flash_on, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Actions Rapides',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Actions
            _buildActionItem(
              icon: Icons.add_circle,
              title: 'Nouveau Contrat',
              subtitle: 'Créer un contrat d\'assurance',
              color: Colors.green,
              onTap: () => _handleAction(context, 'nouveau_contrat'),
            ),
            
            const SizedBox(height: 12),
            
            _buildActionItem(
              icon: Icons.assignment_add,
              title: 'Déclarer Sinistre',
              subtitle: 'Nouvelle déclaration',
              color: Colors.orange,
              onTap: () => _handleAction(context, 'declarer_sinistre'),
            ),
            
            const SizedBox(height: 12),
            
            _buildActionItem(
              icon: Icons.search,
              title: 'Rechercher',
              subtitle: 'Client ou contrat',
              color: Colors.blue,
              onTap: () => _handleAction(context, 'rechercher'),
            ),
            
            const SizedBox(height: 12),
            
            _buildActionItem(
              icon: Icons.analytics,
              title: 'Rapports',
              subtitle: 'Analytics et statistiques',
              color: Colors.indigo,
              onTap: () => _handleAction(context, 'rapports'),
            ),
            
            const SizedBox(height: 12),
            
            _buildActionItem(
              icon: Icons.people,
              title: 'Clients',
              subtitle: 'Gestion des clients',
              color: Colors.teal,
              onTap: () => _handleAction(context, 'clients'),
            ),
            
            const SizedBox(height: 12),
            
            _buildActionItem(
              icon: Icons.settings,
              title: 'Paramètres',
              subtitle: 'Configuration',
              color: Colors.grey,
              onTap: () => _handleAction(context, 'parametres'),
            ),
          ],
        ),
      ),
    );
  }

  /// 🎯 Item d'action
  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  /// 🎬 Gérer les actions
  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'nouveau_contrat':
        _showNewContractDialog(context);
        break;
      case 'declarer_sinistre':
        _showNewClaimDialog(context);
        break;
      case 'rechercher':
        _showSearchDialog(context);
        break;
      case 'rapports':
        _showReportsDialog(context);
        break;
      case 'clients':
        _showClientsDialog(context);
        break;
      case 'parametres':
        _showSettingsDialog(context);
        break;
    }
  }

  /// 📝 Dialog nouveau contrat
  void _showNewContractDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Nouveau Contrat'),
          ],
        ),
        content: const Text(
          'Fonctionnalité en développement.\n\n'
          'Cette section permettra de créer de nouveaux contrats d\'assurance '
          'avec toutes les informations nécessaires.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🚧 Fonctionnalité en développement'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  /// 📋 Dialog déclaration sinistre
  void _showNewClaimDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.assignment_add, color: Colors.orange),
            SizedBox(width: 8),
            Text('Déclarer Sinistre'),
          ],
        ),
        content: const Text(
          'Créer une nouvelle déclaration de sinistre.\n\n'
          'Cette fonctionnalité permettra aux assureurs de créer '
          'et gérer les déclarations de sinistres.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📋 Redirection vers déclaration sinistre'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  /// 🔍 Dialog recherche
  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.search, color: Colors.blue),
            SizedBox(width: 8),
            Text('Recherche'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Que souhaitez-vous rechercher ?'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Client'),
              subtitle: const Text('Rechercher par nom, CIN, téléphone'),
              onTap: () {
                Navigator.of(context).pop();
                _showMessage(context, '🔍 Recherche de client');
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Contrat'),
              subtitle: const Text('Rechercher par numéro de contrat'),
              onTap: () {
                Navigator.of(context).pop();
                _showMessage(context, '📄 Recherche de contrat');
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_car),
              title: const Text('Véhicule'),
              subtitle: const Text('Rechercher par immatriculation'),
              onTap: () {
                Navigator.of(context).pop();
                _showMessage(context, '🚗 Recherche de véhicule');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// 📊 Dialog rapports
  void _showReportsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Rapports & Analytics'),
          ],
        ),
        content: const Text(
          'Accès aux rapports et analytics avancés.\n\n'
          '• Statistiques de sinistralité\n'
          '• Évolution du portefeuille\n'
          '• Analyses prédictives\n'
          '• Rapports personnalisés',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showMessage(context, '📊 Accès aux rapports');
            },
            child: const Text('Accéder'),
          ),
        ],
      ),
    );
  }

  /// 👥 Dialog clients
  void _showClientsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.people, color: Colors.teal),
            SizedBox(width: 8),
            Text('Gestion Clients'),
          ],
        ),
        content: const Text(
          'Gestion complète de votre portefeuille clients.\n\n'
          '• Liste des clients\n'
          '• Historique des contrats\n'
          '• Suivi des sinistres\n'
          '• Communication client',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showMessage(context, '👥 Gestion des clients');
            },
            child: const Text('Accéder'),
          ),
        ],
      ),
    );
  }

  /// ⚙️ Dialog paramètres
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings, color: Colors.grey),
            SizedBox(width: 8),
            Text('Paramètres'),
          ],
        ),
        content: const Text(
          'Configuration de votre espace assureur.\n\n'
          '• Profil utilisateur\n'
          '• Préférences d\'affichage\n'
          '• Notifications\n'
          '• Sécurité',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showMessage(context, '⚙️ Configuration');
            },
            child: const Text('Configurer'),
          ),
        ],
      ),
    );
  }

  /// 💬 Afficher un message
  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
