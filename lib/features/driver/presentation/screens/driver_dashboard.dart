import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/driver_stats_card.dart';

/// 🚗 Dashboard du conducteur moderne
class DriverDashboard extends ConsumerStatefulWidget {
  const DriverDashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends ConsumerState<DriverDashboard> {
  int _selectedIndex = 0;

  void _showFeatureSnackBar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Fonctionnalité en cours de développement'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar moderne avec gradient
          _buildSliverAppBar(context, 'Conducteur'),

          // Contenu principal
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Message de bienvenue
                _buildWelcomeCard(context, 'Conducteur'),

                const SizedBox(height: 16),

                // Statistiques rapides
                _buildStatsSection(context),

                const SizedBox(height: 24),

                // Actions rapides
                _buildQuickActionsSection(context),

                const SizedBox(height: 24),

                // Activités récentes
                _buildRecentActivitySection(context),

                const SizedBox(height: 24),

                // Informations utiles
                _buildInfoSection(context),

                const SizedBox(height: 100), // Espace pour la bottom nav
              ]),
            ),
          ),
        ],
      ),

      // Bottom Navigation
      bottomNavigationBar: _buildBottomNavigation(context),

      // FAB pour déclaration rapide
      floatingActionButton: _buildFloatingActionButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// 📱 AppBar avec gradient
  Widget _buildSliverAppBar(BuildContext context, String userName) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.driverColor,
                Color(0xFF388E3C),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Bonjour, $userName',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gérez vos assurances en toute simplicité',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _showFeatureSnackBar('Notifications'),
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: ListTile(
                leading: Icon(Icons.person_outline),
                title: Text('Mon profil'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings_outlined),
                title: Text('Paramètres'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'help',
              child: ListTile(
                leading: Icon(Icons.help_outline),
                title: Text('Aide'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: ListTile(
                leading: Icon(Icons.logout, color: AppTheme.errorColor),
                title: Text('Déconnexion', style: TextStyle(color: AppTheme.errorColor)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 👋 Carte de bienvenue
  Widget _buildWelcomeCard(BuildContext context, String firstName) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppTheme.driverColor.withValues(alpha: 0.1),
              AppTheme.driverColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.driverColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.directions_car,
                size: 30,
                color: AppTheme.driverColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenue, $firstName !',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.driverColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Votre espace personnel pour gérer vos assurances',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
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

  /// 📊 Section des statistiques
  Widget _buildStatsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mes statistiques',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DriverStatsCard(
                title: 'Véhicules',
                value: '2',
                icon: Icons.directions_car,
                color: AppTheme.driverColor,
                onTap: () {
                  // Navigation vers véhicules
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navigation vers véhicules')),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DriverStatsCard(
                title: 'Contrats',
                value: '2',
                icon: Icons.description,
                color: AppTheme.primaryColor,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navigation vers contrats')),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DriverStatsCard(
                title: 'Sinistres',
                value: '0',
                icon: Icons.warning,
                color: AppTheme.warningColor,
                onTap: () => _showFeatureSnackBar('Sinistres'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DriverStatsCard(
                title: 'Années sans sinistre',
                value: '3',
                icon: Icons.shield,
                color: AppTheme.accentColor,
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// ⚡ Section des actions rapides
  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            QuickActionCard(
              title: 'Déclarer un sinistre',
              icon: Icons.report_problem,
              color: AppTheme.errorColor,
              onTap: () => _showFeatureSnackBar('Déclarer un sinistre'),
            ),
            QuickActionCard(
              title: 'Mes documents',
              icon: Icons.folder,
              color: AppTheme.primaryColor,
              onTap: () => _showFeatureSnackBar('Mes documents'),
            ),
            QuickActionCard(
              title: 'Trouver une agence',
              icon: Icons.location_on,
              color: AppTheme.accentColor,
              onTap: () => _showFeatureSnackBar('Trouver une agence'),
            ),
            QuickActionCard(
              title: 'Assistance',
              icon: Icons.support_agent,
              color: AppTheme.warningColor,
              onTap: () => _showAssistanceDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  /// 📈 Section des activités récentes
  Widget _buildRecentActivitySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Activités récentes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _showFeatureSnackBar('Activités'),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const RecentActivityCard(
          title: 'Contrat renouvelé',
          subtitle: 'Votre contrat pour la Peugeot 208 a été renouvelé',
          time: 'Il y a 2 jours',
          icon: Icons.refresh,
          color: AppTheme.accentColor,
        ),
        const SizedBox(height: 8),
        const RecentActivityCard(
          title: 'Attestation générée',
          subtitle: 'Nouvelle attestation disponible pour téléchargement',
          time: 'Il y a 1 semaine',
          icon: Icons.file_download,
          color: AppTheme.primaryColor,
        ),
      ],
    );
  }

  /// ℹ️ Section d'informations
  Widget _buildInfoSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Informations utiles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• En cas d\'accident, déclarez le sinistre dans les 5 jours\n'
              '• Vos attestations sont disponibles 24h/24\n'
              '• Contactez votre agent pour toute question',
            ),
          ],
        ),
      ),
    );
  }

  /// 🧭 Bottom Navigation
  Widget _buildBottomNavigation(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, Icons.home, 'Accueil', 0),
          _buildNavItem(context, Icons.directions_car, 'Véhicules', 1),
          const SizedBox(width: 40), // Espace pour le FAB
          _buildNavItem(context, Icons.description, 'Contrats', 2),
          _buildNavItem(context, Icons.person, 'Profil', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onNavItemTapped(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.driverColor : AppTheme.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected ? AppTheme.driverColor : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🎯 FAB pour déclaration rapide
  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showFeatureSnackBar('Déclarer un sinistre'),
      backgroundColor: AppTheme.errorColor,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  /// 🎭 Gestion des actions du menu
  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'profile':
        _showFeatureSnackBar('Mon profil');
        break;
      case 'settings':
        _showFeatureSnackBar('Paramètres');
        break;
      case 'help':
        _showHelpDialog(context);
        break;
      case 'logout':
        _showLogoutDialog(context);
        break;
    }
  }

  /// 🧭 Navigation entre les onglets
  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Déjà sur l'accueil
        break;
      case 1:
        _showFeatureSnackBar('Véhicules');
        break;
      case 2:
        _showFeatureSnackBar('Contrats');
        break;
      case 3:
        _showFeatureSnackBar('Profil');
        break;
    }
  }

  /// 🆘 Dialog d'assistance
  void _showAssistanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assistance'),
        content: const Text(
          'Besoin d\'aide ?\n\n'
          '📞 Urgence 24h/24 : 71 123 456\n'
          '📧 Email : assistance@constat-tunisie.tn\n'
          '💬 Chat en ligne disponible',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Ouvrir le chat ou appeler
            },
            child: const Text('Contacter'),
          ),
        ],
      ),
    );
  }

  /// ❓ Dialog d'aide
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aide'),
        content: const Text(
          'Comment utiliser l\'application :\n\n'
          '1. Consultez vos véhicules et contrats\n'
          '2. Déclarez un sinistre en cas d\'accident\n'
          '3. Téléchargez vos attestations\n'
          '4. Trouvez l\'agence la plus proche',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  /// 🚪 Dialog de déconnexion
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}
