import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/modern_theme.dart';
import '../providers/super_admin_provider.dart';
import '../providers/dashboard_data_provider.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/stats_card.dart';
import '../widgets/recent_activity_card.dart';
// import 'professional_requests_screen.dart'; // Import inutilisé
import 'professional_requests_management_screen.dart';
// import 'test_requests_screen.dart'; // Gardé en commentaire au cas où

/// 🏠 Dashboard Super Admin - Interface principale
class SuperAdminDashboardScreen extends ConsumerStatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  ConsumerState<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends ConsumerState<SuperAdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      backgroundColor: ModernTheme.backgroundColor,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  /// 🔝 Barre d'application moderne
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Dashboard Super Admin',
        style: ModernTheme.headingSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: ModernTheme.primaryColor,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: ModernTheme.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        // Notifications
        IconButton(
          icon: const Badge(
            label: Text('3'),
            child: Icon(Icons.notifications, color: Colors.white),
          ),
          onPressed: () => _showNotifications(),
        ),
        // Profil
        PopupMenuButton<String>(
          icon: const CircleAvatar(
            backgroundColor: Colors.white,
            radius: 16, // Taille réduite
            child: Icon(Icons.admin_panel_settings, color: AppTheme.primaryColor, size: 20),
          ),
          offset: const Offset(-120, 0), // Décalage vers la gauche pour éviter l'overflow
          constraints: const BoxConstraints(
            maxWidth: 200, // Largeur maximale du menu
          ),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: SizedBox(
                width: 180, // Largeur fixe pour éviter l'overflow
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Profil',
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: SizedBox(
                width: 180,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.settings, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Paramètres',
                        style: TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: SizedBox(
                width: 180,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Déconnexion',
                        style: TextStyle(color: Colors.red, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 📱 Menu latéral
  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          // En-tête du drawer
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.primaryColor, Color(0xFF1565C0)],
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 40,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Super Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Administrateur Système',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Tableau de bord',
                  index: 0,
                ),
                _buildDrawerItem(
                  icon: Icons.people,
                  title: 'Gestion Utilisateurs',
                  index: 1,
                ),
                _buildDrawerItem(
                  icon: Icons.pending_actions,
                  title: 'Demandes en attente',
                  index: 2,
                  badge: '5',
                ),
                _buildDrawerItem(
                  icon: Icons.business,
                  title: 'Gestion Agences',
                  index: 3,
                ),
                _buildDrawerItem(
                  icon: Icons.car_crash,
                  title: 'Sinistres',
                  index: 4,
                ),
                _buildDrawerItem(
                  icon: Icons.analytics,
                  title: 'Statistiques',
                  index: 5,
                ),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Paramètres',
                  index: 6,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.help, color: AppTheme.primaryColor),
                  title: const Text('Aide'),
                  onTap: () => _showHelp(),
                ),
                ListTile(
                  leading: const Icon(Icons.info, color: AppTheme.primaryColor),
                  title: const Text('À propos'),
                  onTap: () => _showAbout(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Item du menu latéral
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
    String? badge,
  }) {
    final isSelected = _selectedIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: badge != null
            ? Badge(
                label: Text(badge),
                backgroundColor: AppTheme.errorColor,
              )
            : null,
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  /// 📱 Corps principal
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardHome();
      case 1:
        return _buildUsersManagement();
      case 2:
        return _buildPendingRequests();
      case 3:
        return _buildAgenciesManagement();
      case 4:
        return _buildClaimsManagement();
      case 5:
        return _buildStatistics();
      case 6:
        return _buildSettings();
      default:
        return _buildDashboardHome();
    }
  }

  /// 🏠 Accueil du dashboard
  Widget _buildDashboardHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        ModernTheme.spacingM,
        ModernTheme.spacingM,
        ModernTheme.spacingM,
        80, // Padding réduit en bas
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête moderne
          _buildModernHeader(),

          const SizedBox(height: 12), // Espacement ultra-réduit

          // Statistiques rapides
          _buildQuickStats(),

          const SizedBox(height: 12), // Espacement ultra-réduit

          // Activité récente
          _buildRecentActivity(),

          const SizedBox(height: 12), // Espacement ultra-réduit

          // Actions rapides
          _buildQuickActions(),
        ],
      ),
    );
  }

  /// 🎨 En-tête moderne
  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.all(ModernTheme.spacingL),
      decoration: ModernTheme.gradientDecoration(
        colors: ModernTheme.primaryGradient,
        borderRadius: ModernTheme.radiusLarge,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue, Super Admin',
                  style: ModernTheme.headingMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: ModernTheme.spacingS),
                Text(
                  'Gérez votre système d\'assurance avec élégance',
                  style: ModernTheme.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Statistiques rapides
  Widget _buildQuickStats() {
    final stats = ref.watch(dashboardStatsProvider);
    final trends = ref.watch(statsTrendsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistiques Générales',
          style: TextStyle(
            fontSize: 14, // Taille absolu minimale
            fontWeight: FontWeight.bold,
            height: 1.0, // Hauteur de ligne minimale
          ),
        ),
        const SizedBox(height: 4), // Espacement absolu minimal
        stats.when(
          data: (data) => GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 4, // Espacement absolu minimal
            mainAxisSpacing: 4, // Espacement absolu minimal
            childAspectRatio: 2.3, // Ratio maximal
            children: [
              StatsCard(
                title: 'Utilisateurs',
                value: (data['total_users'] ?? 0) +
                       (data['total_agents'] ?? 0) +
                       (data['total_experts'] ?? 0) +
                       (data['total_conducteurs'] ?? 0),
                icon: Icons.people_rounded,
                color: ModernTheme.primaryColor,
                trend: trends['users'],
              ),
              StatsCard(
                title: 'Agences',
                value: data['total_agencies'] ?? 0,
                icon: Icons.business_rounded,
                color: ModernTheme.successColor,
                trend: trends['agencies'],
              ),
              StatsCard(
                title: 'Sinistres',
                value: data['total_claims'] ?? 0,
                icon: Icons.car_crash_rounded,
                color: ModernTheme.warningColor,
                trend: trends['claims'],
              ),
              StatsCard(
                title: 'En attente',
                value: data['pending_requests'] ?? 0,
                icon: Icons.pending_actions_rounded,
                color: ModernTheme.errorColor,
                trend: trends['pending'],
              ),
            ],
          ),
          loading: () => GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 2.3,
            children: const [
              StatsCard(
                title: 'Utilisateurs',
                value: '...',
                icon: Icons.people_rounded,
                color: ModernTheme.primaryColor,
                isLoading: true,
              ),
              StatsCard(
                title: 'Agences',
                value: '...',
                icon: Icons.business_rounded,
                color: ModernTheme.successColor,
                isLoading: true,
              ),
              StatsCard(
                title: 'Sinistres',
                value: '...',
                icon: Icons.car_crash_rounded,
                color: ModernTheme.warningColor,
                isLoading: true,
              ),
              StatsCard(
                title: 'En attente',
                value: '...',
                icon: Icons.pending_actions_rounded,
                color: ModernTheme.errorColor,
                isLoading: true,
              ),
            ],
          ),
          error: (error, stack) => Center(
            child: Column(
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
                const SizedBox(height: 8),
                Text(
                  'Erreur: ${error.toString()}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.refresh(dashboardStatsProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 🕒 Activité récente
  Widget _buildRecentActivity() {
    return const RecentActivityCard();
  }

  /// ⚡ Actions rapides
  Widget _buildQuickActions() {
    final quickActions = ref.watch(quickActionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions Rapides',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: ModernTheme.spacingM,
          mainAxisSpacing: ModernTheme.spacingM,
          childAspectRatio: 2.5, // Augmenté pour éviter l'overflow
          children: quickActions.map((action) {
            return DashboardCard(
              title: action['title'] as String,
              icon: action['icon'] as IconData,
              color: action['color'] as Color,
              badge: action['count']?.toString(),
              onTap: () => _handleQuickAction(action['title'] as String),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 🎯 Gérer les actions rapides
  void _handleQuickAction(String actionTitle) {
    switch (actionTitle) {
      case 'Nouvelle Agence':
        _createNewAgency();
        break;
      case 'Valider Demandes':
        _validateRequests();
        break;
      case 'Voir Rapports':
        _viewReports();
        break;
      case 'Paramètres':
        _openSettings();
        break;
    }
  }

  /// 👥 Gestion des utilisateurs
  Widget _buildUsersManagement() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        ModernTheme.spacingM,
        ModernTheme.spacingM,
        ModernTheme.spacingM,
        80, // Padding réduit
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_rounded, size: 64, color: ModernTheme.primaryColor),
            SizedBox(height: ModernTheme.spacingM),
            Text(
              'Gestion des Utilisateurs',
              style: ModernTheme.headingMedium,
            ),
            SizedBox(height: ModernTheme.spacingS),
            Text(
              'Interface de gestion des agents, experts et conducteurs',
              style: ModernTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 📝 Demandes en attente
  Widget _buildPendingRequests() {
    // Interface complète - Règles Firestore simplifiées déployées
    return const ProfessionalRequestsManagementScreen();
    // Écran de test (gardé en commentaire au cas où)
    // return const TestRequestsScreen();
  }

  /// 🏢 Gestion des agences
  Widget _buildAgenciesManagement() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business, size: 64, color: AppTheme.successColor),
          SizedBox(height: 16),
          Text(
            'Gestion des Agences',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Création et gestion des agences d\'assurance'),
        ],
      ),
    );
  }

  /// 🚗 Gestion des sinistres
  Widget _buildClaimsManagement() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.car_crash, size: 64, color: AppTheme.errorColor),
          SizedBox(height: 16),
          Text(
            'Gestion des Sinistres',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Suivi de tous les sinistres déclarés'),
        ],
      ),
    );
  }

  /// 📊 Statistiques
  Widget _buildStatistics() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: AppTheme.primaryColor),
          SizedBox(height: 16),
          Text(
            'Statistiques',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Rapports et analyses détaillées'),
        ],
      ),
    );
  }

  /// ⚙️ Paramètres
  Widget _buildSettings() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Paramètres',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Configuration du système'),
        ],
      ),
    );
  }

  /// 📱 Navigation inférieure moderne
  Widget _buildBottomNavigation() {
    final pendingRequests = ref.watch(dashboardStatsProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false, // Pas de padding en haut
        child: Container(
          height: 56, // Hauteur réduite
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.dashboard_rounded,
                label: 'Accueil',
                index: 0,
                isSelected: _selectedIndex == 0,
              ),
              _buildNavItem(
                icon: Icons.people_rounded,
                label: 'Utilisateurs',
                index: 1,
                isSelected: _selectedIndex == 1,
              ),
              _buildNavItemWithBadge(
                icon: Icons.pending_actions_rounded,
                label: 'Demandes',
                index: 2,
                isSelected: _selectedIndex == 2,
                badgeCount: pendingRequests.when(
                  data: (data) => data['pending_requests'] ?? 0,
                  loading: () => 0,
                  error: (_, __) => 0,
                ),
              ),
              _buildNavItem(
                icon: Icons.more_horiz_rounded,
                label: 'Plus',
                index: 3,
                isSelected: _selectedIndex == 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎯 Item de navigation simple
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? ModernTheme.primaryColor : ModernTheme.textLight,
                size: 20, // Taille réduite
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: ModernTheme.bodySmall.copyWith(
                  color: isSelected ? ModernTheme.primaryColor : ModernTheme.textLight,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 10, // Taille de police réduite
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎯 Item de navigation avec badge
  Widget _buildNavItemWithBadge({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
    required int badgeCount,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? ModernTheme.primaryColor : ModernTheme.textLight,
                    size: 20, // Taille réduite
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: const BoxDecoration(
                          color: ModernTheme.errorColor,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          badgeCount > 9 ? '9+' : badgeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8, // Taille réduite
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: ModernTheme.bodySmall.copyWith(
                  color: isSelected ? ModernTheme.primaryColor : ModernTheme.textLight,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 10, // Taille de police réduite
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // === MÉTHODES D'ACTION ===

  void _handleMenuAction(String action) {
    switch (action) {
      case 'profile':
        _showProfile();
        break;
      case 'settings':
        setState(() {
          _selectedIndex = 6;
        });
        break;
      case 'logout':
        _logout();
        break;
    }
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.info, color: AppTheme.primaryColor),
              title: Text('Nouvelle demande d\'agent'),
              subtitle: Text('Il y a 2 heures'),
            ),
            ListTile(
              leading: Icon(Icons.warning, color: AppTheme.warningColor),
              title: Text('Sinistre en attente'),
              subtitle: Text('Il y a 4 heures'),
            ),
            ListTile(
              leading: Icon(Icons.check, color: AppTheme.successColor),
              title: Text('Agence créée avec succès'),
              subtitle: Text('Hier'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showProfile() {
    final superAdminState = ref.read(superAdminProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil Super Admin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${superAdminState.adminData?['email'] ?? 'N/A'}'),
            Text('Nom: ${superAdminState.adminData?['firstName']} ${superAdminState.adminData?['lastName']}'),
            Text('Rôle: ${superAdminState.adminData?['role'] ?? 'N/A'}'),
            Text('Statut: ${superAdminState.adminData?['status'] ?? 'N/A'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(superAdminProvider.notifier).signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aide'),
        content: const Text(
          'Dashboard Super Admin\n\n'
          '• Gérez tous les utilisateurs du système\n'
          '• Validez les demandes de comptes professionnels\n'
          '• Supervisez les agences et sinistres\n'
          '• Consultez les statistiques détaillées\n\n'
          'Pour plus d\'aide, contactez le support technique.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => const AboutDialog(
        applicationName: 'Constat Tunisie',
        applicationVersion: '1.0.0',
        applicationLegalese: '© 2024 Constat Tunisie. Tous droits réservés.',
        children: [
          Text('Application de gestion des sinistres automobiles en Tunisie.'),
        ],
      ),
    );
  }

  // Actions rapides
  void _createNewAgency() {
    setState(() {
      _selectedIndex = 3;
    });
  }

  void _validateRequests() {
    setState(() {
      _selectedIndex = 2;
    });
  }

  void _viewReports() {
    setState(() {
      _selectedIndex = 5;
    });
  }

  void _openSettings() {
    setState(() {
      _selectedIndex = 6;
    });
  }
}
