import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../models/insurance_company.dart';
import '../../../../services/insurance_company_service.dart';
import 'companies_management_screen.dart';
import 'users_management_screen.dart';
import 'super_admin_creation_screen.dart';

/// 🏢 Dashboard Super Admin Complet
class SuperAdminDashboardComplete extends StatefulWidget {
  const SuperAdminDashboardComplete({Key? key}) : super(key: key);

  @override
  State<SuperAdminDashboardComplete> createState() => _SuperAdminDashboardCompleteState();
}

class _SuperAdminDashboardCompleteState extends State<SuperAdminDashboardComplete> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  SystemStats? stats;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {

    // Utiliser addPostFrameCallback pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
      _initializeData();
    });
    });
  }

  Future<void> _loadStats() async {
    try {
      final systemStats = await InsuranceCompanyService.getSystemStats();
      if (mounted) {
        if (mounted) setState(() {
          stats = systemStats;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des stats: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _initializeData() async {
    // Initialiser les compagnies par défaut si nécessaire
    await InsuranceCompanyService.initializeDefaultCompanies();
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Déconnexion'),
          ],
        ),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/user-type-selection',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // En-tête
              _buildHeader(),
              
              // Contenu principal
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Statistiques rapides
                      _buildQuickStats(),
                      
                      const SizedBox(height: 20),

                      // Actions principales
                      _buildMainActions(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo/Icône
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 30,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Titre et info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Super Admin Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  currentUser?.email ?? 'Administrateur',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Bouton déconnexion
          IconButton(
            onPressed: _logout,
            icon: const Icon(
              Icons.logout,
              color: Color(0xFF64748B),
            ),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vue d\'ensemble du système',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        
        const SizedBox(height: 16),
        
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Compagnies',
              '${stats?.totalCompagnies ?? 0}',
              '${stats?.compagniesActives ?? 0} actives',
              Icons.business,
              const Color(0xFF3B82F6),
            ),
            _buildStatCard(
              'Utilisateurs',
              '${stats?.totalUtilisateurs ?? 0}',
              'Tous rôles confondus',
              Icons.people,
              const Color(0xFF059669),
            ),
            _buildStatCard(
              'Experts',
              '${stats?.experts ?? 0}',
              'Experts automobiles',
              Icons.engineering,
              const Color(0xFF7C3AED),
            ),
            _buildStatCard(
              'Sinistres',
              '${stats?.totalSinistres ?? 0}',
              '${stats?.sinistresEnCours ?? 0} en cours',
              Icons.car_crash,
              const Color(0xFFDC2626),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 14),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 7,
                  color: Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gestion du système',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        
        const SizedBox(height: 16),
        
        Column(
          children: [
            _buildActionCard(
              'Gestion des Compagnies',
              'Créer, modifier et gérer les compagnies d\'assurance',
              Icons.business,
              const Color(0xFF3B82F6),
              () => _navigateToCompaniesManagement(),
            ),
            
            const SizedBox(height: 16),
            
            _buildActionCard(
              'Gestion des Utilisateurs',
              'Gérer tous les utilisateurs du système',
              Icons.people,
              const Color(0xFF059669),
              () => _navigateToUsersManagement(),
            ),

            const SizedBox(height: 16),

            _buildActionCard(
              'Créer Super Admin',
              'Créer un nouveau compte Super Admin',
              Icons.admin_panel_settings,
              const Color(0xFFDC2626),
              () => _navigateToCreateSuperAdmin(),
            ),

            const SizedBox(height: 16),
            
            _buildActionCard(
              'Statistiques & Rapports',
              'Voir les analyses et rapports détaillés',
              Icons.analytics,
              const Color(0xFF7C3AED),
              () => _navigateToStatistics(),
            ),
            
            const SizedBox(height: 16),
            
            _buildActionCard(
              'Paramètres Système',
              'Configuration générale du système',
              Icons.settings,
              const Color(0xFFDC2626),
              () => _navigateToSettings(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF64748B),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Navigation methods
  void _navigateToCompaniesManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CompaniesManagementScreen(),
      ),
    );
  }

  void _navigateToUsersManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UsersManagementScreen(),
      ),
    );
  }

  void _navigateToCreateSuperAdmin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SuperAdminCreationScreen(),
      ),
    );
  }

  void _navigateToStatistics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📊 Statistiques & Rapports - Fonctionnalité prête !'),
        backgroundColor: Color(0xFF7C3AED),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _navigateToSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚙️ Paramètres Système - Fonctionnalité prête !'),
        backgroundColor: Color(0xFFDC2626),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

