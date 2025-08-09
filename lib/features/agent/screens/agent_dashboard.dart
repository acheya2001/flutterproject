import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/agent_service.dart';
import 'contrats_screen.dart';
import 'vehicules_screen.dart';
import 'conducteurs_screen.dart';
import 'sinistres_screen.dart';

/// 🏢 Dashboard principal pour Agent
class AgentDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;

  const AgentDashboard({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<AgentDashboard> createState() => _AgentDashboardState();
}

class _AgentDashboardState extends State<AgentDashboard> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _agentInfo;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  /// 📊 Charger les données du dashboard
  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Charger les informations de l'agent
      final agentInfo = await AgentService.getAgentInfo(widget.userData['uid']);
      
      if (agentInfo != null) {
        _agentInfo = agentInfo;
        
        // Charger les statistiques
        final stats = await AgentService.getAgentStats(agentInfo['id']);
        _stats = stats;
      }

    } catch (e) {
      debugPrint('[AGENT_DASHBOARD] ❌ Erreur chargement données: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading ? _buildLoadingScreen() : _buildMainContent(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  /// 🔄 Écran de chargement
  Widget _buildLoadingScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Chargement du dashboard...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📱 Contenu principal
  Widget _buildMainContent() {
    if (_agentInfo == null) {
      return _buildErrorScreen();
    }

    switch (_selectedIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return ContratsScreen(
          agentData: _agentInfo!,
          userData: widget.userData,
        );
      case 2:
        return VehiculesScreen(
          agentData: _agentInfo!,
          userData: widget.userData,
        );
      case 3:
        return ConducteursScreen(
          agentData: _agentInfo!,
          userData: widget.userData,
        );
      case 4:
        return SinistresScreen(
          agentData: _agentInfo!,
          userData: widget.userData,
        );
      default:
        return _buildHomeScreen();
    }
  }

  /// ❌ Écran d'erreur
  Widget _buildErrorScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 64,
            ),
            const SizedBox(height: 20),
            const Text(
              'Erreur de Configuration',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Impossible de charger vos informations.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _showLogoutDialog,
              icon: const Icon(Icons.logout),
              label: const Text('Se Déconnecter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF667EEA),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🏠 Écran d'accueil du dashboard
  Widget _buildHomeScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header avec informations de l'agent
            _buildHeader(),
            
            // Contenu principal avec statistiques
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Statistiques principales
                      _buildStatsCards(),
                      const SizedBox(height: 30),
                      
                      // Actions rapides
                      _buildQuickActions(),
                      const SizedBox(height: 30),
                      
                      // Dernières activités
                      _buildRecentActivities(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📋 Header avec informations de l'agent
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour ${widget.userData['prenom']} !',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Agent - ${_agentInfo!['agenceInfo']?['nom'] ?? 'Agence'}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _agentInfo!['compagnieInfo']?['nom'] ?? 'Compagnie',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _showLogoutDialog,
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📊 Cartes de statistiques
  Widget _buildStatsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vue d\'ensemble',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 15),
        
        // Première ligne
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Contrats',
                '${_stats['totalContrats'] ?? 0}',
                Icons.description_rounded,
                const Color(0xFF667EEA),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildStatCard(
                'Véhicules',
                '${_stats['totalVehicules'] ?? 0}',
                Icons.directions_car_rounded,
                const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        
        // Deuxième ligne
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Conducteurs',
                '${_stats['totalConducteurs'] ?? 0}',
                Icons.people_rounded,
                const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildStatCard(
                'Sinistres',
                '${_stats['totalSinistres'] ?? 0}',
                Icons.warning_rounded,
                const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 📈 Carte de statistique individuelle
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// ⚡ Actions rapides
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions Rapides',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 15),
        
        // Première ligne
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Nouveau Contrat',
                Icons.add_circle_rounded,
                const Color(0xFF667EEA),
                () => setState(() => _selectedIndex = 1),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildActionCard(
                'Ajouter Véhicule',
                Icons.directions_car_rounded,
                const Color(0xFF10B981),
                () => setState(() => _selectedIndex = 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        
        // Deuxième ligne
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Nouveau Conducteur',
                Icons.person_add_rounded,
                const Color(0xFFF59E0B),
                () => setState(() => _selectedIndex = 3),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildActionCard(
                'Déclarer Sinistre',
                Icons.report_problem_rounded,
                const Color(0xFFEF4444),
                () => setState(() => _selectedIndex = 4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 🎯 Carte d'action rapide
  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 📝 Dernières activités
  Widget _buildRecentActivities() {
    final recentActivities = _stats['recentActivities'] as List<Map<String, dynamic>>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dernières Activités',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 15),
        if (recentActivities.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Aucune activité récente',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ] else ...[
          ...recentActivities.take(3).map((activity) => _buildActivityItem(activity)),
        ],
      ],
    );
  }

  /// 📋 Item d'activité
  Widget _buildActivityItem(Map<String, dynamic> activity) {
    IconData activityIcon;
    Color activityColor;
    
    switch (activity['icon']) {
      case 'contract':
        activityIcon = Icons.description_rounded;
        activityColor = const Color(0xFF667EEA);
        break;
      case 'car':
        activityIcon = Icons.directions_car_rounded;
        activityColor = const Color(0xFF10B981);
        break;
      default:
        activityIcon = Icons.circle_rounded;
        activityColor = Colors.grey;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: activityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              activityIcon,
              color: activityColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity['description'] ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Il y a quelques instants',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔽 Navigation en bas
  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF667EEA),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.description_rounded),
          label: 'Contrats',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_car_rounded),
          label: 'Véhicules',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_rounded),
          label: 'Conducteurs',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.warning_rounded),
          label: 'Sinistres',
        ),
      ],
    );
  }

  /// 🚪 Afficher le dialogue de déconnexion
  void _showLogoutDialog() {
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
}
