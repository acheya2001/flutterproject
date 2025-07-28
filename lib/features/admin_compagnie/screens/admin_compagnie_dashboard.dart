import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/admin_compagnie_agence_service.dart';
import 'admin_agence_credentials_display.dart';
import 'create_agence_only_screen.dart';
import 'create_admin_agence_screen.dart';
import 'modern_agence_management_screen.dart';

/// 🏢 Dashboard Admin Compagnie
class AdminCompagnieDashboard extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const AdminCompagnieDashboard({
    Key? key,
    this.userData,
  }) : super(key: key);

  @override
  State<AdminCompagnieDashboard> createState() => _AdminCompagnieDashboardState();
}

class _AdminCompagnieDashboardState extends State<AdminCompagnieDashboard> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _compagnieData;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _agences = [];
  List<Map<String, dynamic>> _constats = [];
  List<Map<String, dynamic>> _experts = [];
  List<Map<String, dynamic>> _adminsAgence = [];
  bool _isLoading = true;

  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  /// 📊 Charger toutes les données
  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    await Future.wait([
      _loadCompagnieData(),
      _loadAgences(),
      _loadConstats(),
      _loadExperts(),
      _loadAdminsAgence(),
    ]);

    setState(() => _isLoading = false);
  }

  /// 🔄 Rafraîchir les données
  Future<void> _refreshData() async {
    await _loadAllData();
  }

  /// 📊 Charger les données de la compagnie
  Future<void> _loadCompagnieData() async {
    try {
      final userData = widget.userData;
      if (userData == null) {
        setState(() => _isLoading = false);
        return;
      }

      final compagnieId = userData['compagnieId'];
      final compagnieNom = userData['compagnieNom'];

      // Charger les données de la compagnie
      if (compagnieId != null) {
        final compagnieDoc = await FirebaseFirestore.instance
            .collection('compagnies')
            .doc(compagnieId)
            .get();

        if (compagnieDoc.exists) {
          _compagnieData = compagnieDoc.data();
        }
      }

      // Charger les statistiques
      await _loadStats(compagnieId, compagnieNom);

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_DASHBOARD] ❌ Erreur chargement: $e');
      setState(() => _isLoading = false);
    }
  }

  /// 📈 Charger les statistiques de la compagnie
  Future<void> _loadStats(String? compagnieId, String? compagnieNom) async {
    try {
      int agents = 0;
      int contrats = 0;
      int sinistres = 0;

      if (compagnieId != null) {
        // Compter les agents
        final agentsQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'agent')
            .where('compagnieId', isEqualTo: compagnieId)
            .get();
        agents = agentsQuery.docs.length;

        // Compter les contrats
        final contratsQuery = await FirebaseFirestore.instance
            .collection('contrats')
            .where('compagnieId', isEqualTo: compagnieId)
            .get();
        contrats = contratsQuery.docs.length;

        // Compter les sinistres
        final sinistresQuery = await FirebaseFirestore.instance
            .collection('sinistres')
            .where('compagnieId', isEqualTo: compagnieId)
            .get();
        sinistres = sinistresQuery.docs.length;
      }

      _stats = {
        'agents': agents,
        'contrats': contrats,
        'sinistres': sinistres,
      };
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_DASHBOARD] ❌ Erreur stats: $e');
      _stats = {'agents': 0, 'contrats': 0, 'sinistres': 0};
    }
  }

  /// 🏢 Charger les agences de la compagnie
  Future<void> _loadAgences() async {
    try {
      final compagnieId = widget.userData?['compagnieId'];
      if (compagnieId == null) return;

      _agences = await AdminCompagnieAgenceService.getAgencesByCompagnie(compagnieId);

      debugPrint('[ADMIN_COMPAGNIE_DASHBOARD] ✅ ${_agences.length} agences chargées');
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_DASHBOARD] ❌ Erreur agences: $e');
      _agences = [];
    }
  }

  /// 📋 Charger les constats de la compagnie
  Future<void> _loadConstats() async {
    try {
      final compagnieId = widget.userData?['compagnieId'];
      if (compagnieId == null) return;

      final constatsQuery = await FirebaseFirestore.instance
          .collection('constats')
          .where('compagnieId', isEqualTo: compagnieId)
          .limit(50)
          .get();

      _constats = constatsQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      debugPrint('[ADMIN_COMPAGNIE_DASHBOARD] ✅ ${_constats.length} constats chargés');
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_DASHBOARD] ❌ Erreur constats: $e');
      _constats = [];
    }
  }

  /// 👨‍💼 Charger les experts associés
  Future<void> _loadExperts() async {
    try {
      final compagnieId = widget.userData?['compagnieId'];
      if (compagnieId == null) return;

      final expertsQuery = await FirebaseFirestore.instance
          .collection('experts')
          .where('compagniesAssociees', arrayContains: compagnieId)
          .get();

      _experts = expertsQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      debugPrint('[ADMIN_COMPAGNIE_DASHBOARD] ✅ ${_experts.length} experts chargés');
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_DASHBOARD] ❌ Erreur experts: $e');
      _experts = [];
    }
  }

  /// 👨‍💼 Charger les admins agence de la compagnie
  Future<void> _loadAdminsAgence() async {
    try {
      final compagnieId = widget.userData?['compagnieId'];
      if (compagnieId == null) return;

      _adminsAgence = await AdminCompagnieAgenceService.getAdminsAgenceByCompagnie(compagnieId);

      debugPrint('[ADMIN_COMPAGNIE_DASHBOARD] ✅ ${_adminsAgence.length} admins agence chargés');
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_DASHBOARD] ❌ Erreur admins agence: $e');
      _adminsAgence = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Dashboard Admin Compagnie'),
          backgroundColor: const Color(0xFF059669),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _compagnieData?['nom'] ?? widget.userData?['compagnieNom'] ?? 'Dashboard Admin Compagnie',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF047857)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _refreshData(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
          ),
          IconButton(
            onPressed: () => _showNotifications(),
            icon: const Icon(Icons.notifications_rounded),
            tooltip: 'Notifications',
          ),
          IconButton(
            onPressed: () => _showLogoutDialog(),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Déconnexion',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded), text: 'Tableau de bord'),
            Tab(icon: Icon(Icons.business_rounded), text: 'Agences'),
            Tab(icon: Icon(Icons.admin_panel_settings_rounded), text: 'Admins Agences'),
            Tab(icon: Icon(Icons.settings_rounded), text: 'Paramètres'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTableauDeBord(),
          _buildModernGestionAgences(),
          _buildGestionAdminsAgences(),
          _buildParametresCompagnie(),
        ],
      ),
    );
  }

  /// 📊 Tableau de bord - Onglet 1
  Widget _buildTableauDeBord() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de bienvenue
          _buildWelcomeHeader(),
          const SizedBox(height: 24),

          // Statistiques principales
          _buildMainStats(),
          const SizedBox(height: 24),

          // Graphiques et tendances
          _buildChartsSection(),
          const SizedBox(height: 24),

          // Top 5 agences
          _buildTopAgences(),
          const SizedBox(height: 24),

          // Activités récentes
          _buildRecentActivities(),
        ],
      ),
    );
  }

  /// 🏢 Gestion des Agences Moderne - Onglet 2
  Widget _buildModernGestionAgences() {
    return ModernAgenceManagementScreen(userData: widget.userData!);
  }

  /// 🏢 Gestion des Agences - Onglet 2 (Ancienne version)
  Widget _buildGestionAgences() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec bouton d'ajout
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gestion des Agences',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateAgenceOnlyScreen(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Créer une nouvelle agence'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filtres
          _buildAgencesFilters(),
          const SizedBox(height: 20),

          // Liste des agences
          _buildAgencesList(),
        ],
      ),
    );
  }

  /// 👨‍💼 Gestion des Admins Agences - Onglet 3
  Widget _buildGestionAdminsAgences() {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // En-tête moderne avec gradient
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admins Agences',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Gérez les administrateurs de vos agences',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateAdminAgenceScreen(),
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text('Créer Admin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF667EEA),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Statistiques rapides
          _buildAdminAgenceStats(),

          // Liste des admins agence
          Expanded(
            child: _buildModernAdminsAgenceList(),
          ),
        ],
      ),
    );
  }

  /// 📋 Vue des Constats - Onglet 4
  Widget _buildVueConstats() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vue des Constats',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),

          // Filtres des constats
          _buildConstatsFilters(),
          const SizedBox(height: 20),

          // Liste des constats
          _buildConstatsList(),
        ],
      ),
    );
  }

  /// 👨‍🔧 Experts Associés - Onglet 5
  Widget _buildExpertsAssocies() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Experts Associés',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),

          // Liste des experts
          _buildExpertsList(),
        ],
      ),
    );
  }

  /// 📊 Rapports & Export - Onglet 6
  Widget _buildRapportsExport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rapports & Export',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),

          // Options d'export
          _buildExportOptions(),
          const SizedBox(height: 20),

          // Rapports prédéfinis
          _buildPredefinedReports(),
        ],
      ),
    );
  }

  /// 👋 En-tête de bienvenue
  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.business_rounded,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue ${widget.userData?['prenom'] ?? 'Admin'} !',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _compagnieData?['nom'] ?? widget.userData?['compagnieNom'] ?? 'Votre compagnie assurance',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Statistiques principales
  Widget _buildMainStats() {
    return Column(
      children: [
        // Première ligne de stats
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Agences',
                '${_agences.length}',
                Icons.business_rounded,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Agents',
                '${_stats['agents'] ?? 0}',
                Icons.people_rounded,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Constats',
                '${_constats.length}',
                Icons.description_rounded,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Deuxième ligne de stats
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Experts',
                '${_experts.length}',
                Icons.engineering_rounded,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'En attente',
                '${_constats.where((c) => c['statut'] == 'en_attente').length}',
                Icons.pending_rounded,
                Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Validés',
                '${_constats.where((c) => c['statut'] == 'valide').length}',
                Icons.check_circle_rounded,
                Colors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 📊 Statistiques rapides (ancienne version)
  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Agents',
            '${_stats['agents'] ?? 0}',
            Icons.people_rounded,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Contrats',
            '${_stats['contrats'] ?? 0}',
            Icons.description_rounded,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Sinistres',
            '${_stats['sinistres'] ?? 0}',
            Icons.warning_rounded,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// 📈 Section des graphiques
  Widget _buildChartsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Évolution des sinistres',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            child: const Center(
              child: Text(
                'Graphique des sinistres par mois\n(À implémenter avec charts_flutter)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🏆 Top 5 agences
  Widget _buildTopAgences() {
    // Calculer le nombre de constats par agence
    final agencesStats = <String, int>{};
    for (final constat in _constats) {
      final agenceId = constat['agenceId'] as String?;
      if (agenceId != null) {
        agencesStats[agenceId] = (agencesStats[agenceId] ?? 0) + 1;
      }
    }

    // Trier et prendre le top 5
    final sortedAgences = agencesStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sortedAgences.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top 5 Agences (par nombre de constats)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          if (top5.isEmpty)
            const Center(
              child: Text(
                'Aucune donnée disponible',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...top5.asMap().entries.map((entry) {
              final index = entry.key;
              final agenceStats = entry.value;
              final agence = _agences.firstWhere(
                (a) => a['id'] == agenceStats.key,
                orElse: () => {'nom': 'Agence inconnue'},
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getTopColor(index),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        agence['nom'] ?? 'Agence inconnue',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '${agenceStats.value} constats',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Color _getTopColor(int index) {
    switch (index) {
      case 0: return Colors.amber;
      case 1: return Colors.grey;
      case 2: return Colors.brown;
      default: return Colors.blue;
    }
  }

  /// 🎯 Actions principales
  Widget _buildMainActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions principales',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildActionCard(
              'Gérer Agents',
              Icons.people_rounded,
              Colors.blue,
              () => _showComingSoon('Gestion des agents'),
            ),
            _buildActionCard(
              'Contrats',
              Icons.description_rounded,
              Colors.green,
              () => _showComingSoon('Gestion des contrats'),
            ),
            _buildActionCard(
              'Sinistres',
              Icons.warning_rounded,
              Colors.orange,
              () => _showComingSoon('Gestion des sinistres'),
            ),
            _buildActionCard(
              'Rapports',
              Icons.analytics_rounded,
              Colors.purple,
              () => _showComingSoon('Rapports et statistiques'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 📋 Activités récentes
  Widget _buildRecentActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activités récentes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Aucune activité récente',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 🏢 Filtres des agences
  Widget _buildAgencesFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher une agence...',
                prefixIcon: Icon(Icons.search_rounded),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                // TODO: Implémenter la recherche
              },
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            hint: const Text('Ville'),
            items: ['Tunis', 'Sfax', 'Sousse', 'Bizerte']
                .map((ville) => DropdownMenuItem(
                      value: ville,
                      child: Text(ville),
                    ))
                .toList(),
            onChanged: (value) {
              // TODO: Implémenter le filtre par ville
            },
          ),
        ],
      ),
    );
  }

  /// 📋 Liste des agences
  Widget _buildAgencesList() {
    if (_agences.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.business_rounded, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Aucune agence trouvée',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              Text(
                'Commencez par créer votre première agence',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _agences.length,
      itemBuilder: (context, index) {
        final agence = _agences[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.business_rounded, color: Colors.blue),
            ),
            title: Text(
              agence['nom'] ?? 'Agence sans nom',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📍 ${agence['gouvernorat'] ?? 'Gouvernorat non défini'}'),
                Text('👥 ${agence['nombreAgents'] ?? 0} agents'),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatutColor(agence['statut']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getStatutColor(agence['statut'])),
                      ),
                      child: Text(
                        _getStatutText(agence['statut'], agence['hasAdminAgence']),
                        style: TextStyle(
                          color: _getStatutColor(agence['statut']),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (agence['isActive'] == false) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red),
                        ),
                        child: const Text(
                          'DÉSACTIVÉ',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                if (agence['hasAdminAgence'] != true)
                  const PopupMenuItem(
                    value: 'create_admin',
                    child: Row(
                      children: [
                        Icon(Icons.person_add_rounded, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Créer Admin Agence'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility_rounded),
                      SizedBox(width: 8),
                      Text('Voir détails'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded),
                      SizedBox(width: 8),
                      Text('Modifier'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: agence['isActive'] == true ? 'disable' : 'enable',
                  child: Row(
                    children: [
                      Icon(
                        agence['isActive'] == true ? Icons.block_rounded : Icons.check_circle_rounded,
                        color: agence['isActive'] == true ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(agence['isActive'] == true ? 'Désactiver (+ admin)' : 'Réactiver (+ admin)'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'create_admin') {
                  _showCreateAdminAgenceDialog(agence);
                } else {
                  _handleAgenceAction(value, agence);
                }
              },
            ),
            onTap: () => _showAgenceDetails(agence),
          ),
        );
      },
    );
  }

  /// 📋 Liste des constats
  Widget _buildConstatsList() {
    if (_constats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.description_rounded, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Aucun constat trouvé',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _constats.length,
      itemBuilder: (context, index) {
        final constat = _constats[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatutColor(constat['statut']).withOpacity(0.2),
              child: Icon(
                _getStatutIcon(constat['statut']),
                color: _getStatutColor(constat['statut']),
              ),
            ),
            title: Text(
              'Constat #${constat['numero'] ?? constat['id']?.substring(0, 8) ?? 'N/A'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📅 ${_formatDate(constat['dateCreation'])}'),
                Text('📍 ${constat['lieu'] ?? 'Lieu non défini'}'),
                Text('📊 ${_getStatutText(constat['statut'])}'),
              ],
            ),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => _showConstatDetails(constat),
          ),
        );
      },
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Bientôt disponible'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Méthodes utilitaires pour les constats et agences
  Color _getStatutColor(String? statut) {
    switch (statut?.toLowerCase()) {
      // Statuts de constats
      case 'en_attente': return Colors.orange;
      case 'en_cours': return Colors.blue;
      case 'valide': return Colors.green;
      case 'rejete': return Colors.red;
      // Statuts d'agences
      case 'occupé': return Colors.green;
      case 'libre': return Colors.orange;
      case 'désactivé': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatutIcon(String? statut) {
    switch (statut) {
      case 'en_attente': return Icons.pending_rounded;
      case 'en_cours': return Icons.hourglass_empty_rounded;
      case 'valide': return Icons.check_circle_rounded;
      case 'rejete': return Icons.cancel_rounded;
      default: return Icons.help_rounded;
    }
  }

  String _getStatutText(String? statut, [bool? hasAdmin]) {
    // Si hasAdmin est fourni, c'est pour une agence
    if (hasAdmin != null) {
      if (hasAdmin == true) {
        return '🏢 OCCUPÉ';
      } else {
        return '🆓 LIBRE';
      }
    }

    // Sinon, c'est pour un constat
    switch (statut) {
      case 'en_attente': return 'En attente';
      case 'en_cours': return 'En cours';
      case 'valide': return 'Validé';
      case 'rejete': return 'Rejeté';
      default: return 'Statut inconnu';
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Date inconnue';
    // TODO: Implémenter le formatage de date
    return date.toString().substring(0, 10);
  }

  // Actions pour les agences
  void _handleAgenceAction(String action, Map<String, dynamic> agence) {
    switch (action) {
      case 'view':
        _showAgenceDetails(agence);
        break;
      case 'edit':
        _showEditAgenceDialog(agence);
        break;
      case 'disable':
        _toggleAgenceStatus(agence, false);
        break;
      case 'enable':
        _toggleAgenceStatus(agence, true);
        break;
    }
  }

  Future<void> _toggleAgenceStatus(Map<String, dynamic> agence, bool isActive) async {
    try {
      final result = isActive
          ? await AdminCompagnieAgenceService.enableAgence(agence['id'])
          : await AdminCompagnieAgenceService.disableAgence(agence['id']);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );

        // Recharger les données
        await _loadAllData();
        setState(() {}); // Forcer la mise à jour
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAgenceDetails(Map<String, dynamic> agence) {
    _showComingSoon('Détails de l\'agence ${agence['nom']}');
  }

  void _showEditAgenceDialog(Map<String, dynamic> agence) {
    _showComingSoon('Modification de l\'agence ${agence['nom']}');
  }

  void _showDisableAgenceDialog(Map<String, dynamic> agence) {
    _showComingSoon('Désactivation de l\'agence ${agence['nom']}');
  }

  void _showAddAgenceDialog() {
    final nomController = TextEditingController();
    final adresseController = TextEditingController();
    final telephoneController = TextEditingController();
    final emailController = TextEditingController();
    String selectedGouvernorat = 'Tunis';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.business_rounded, color: Colors.blue),
            SizedBox(width: 8),
            Text('Créer une nouvelle agence'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de l\'agence *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: adresseController,
                  decoration: const InputDecoration(
                    labelText: 'Adresse *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: telephoneController,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedGouvernorat,
                        decoration: const InputDecoration(
                          labelText: 'Gouvernorat',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'Tunis', 'Ariana', 'Ben Arous', 'Manouba', 'Nabeul', 'Zaghouan', 'Bizerte',
                          'Béja', 'Jendouba', 'Kef', 'Siliana', 'Sousse', 'Monastir', 'Mahdia',
                          'Sfax', 'Kairouan', 'Kasserine', 'Sidi Bouzid', 'Gabès', 'Médenine',
                          'Tataouine', 'Gafsa', 'Tozeur', 'Kébili'
                        ].map((gov) => DropdownMenuItem(value: gov, child: Text(gov))).toList(),
                        onChanged: (value) => selectedGouvernorat = value!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email de contact *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => _createAgence(
              context,
              nomController.text,
              adresseController.text,
              telephoneController.text,
              selectedGouvernorat,
              emailController.text,
            ),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  Future<void> _createAgence(
    BuildContext context,
    String nom,
    String adresse,
    String telephone,
    String gouvernorat,
    String email,
  ) async {
    if (nom.isEmpty || adresse.isEmpty || telephone.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Fermer le dialogue d'abord
    Navigator.pop(context);

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await AdminCompagnieAgenceService.createAgence(
        compagnieId: widget.userData!['compagnieId'],
        compagnieNom: widget.userData!['compagnieNom'],
        nom: nom,
        adresse: adresse,
        telephone: telephone,
        gouvernorat: gouvernorat,
        emailContact: email,
      );

      // Vérifier si le widget est encore monté avant d'utiliser le context
      if (!mounted) return;

      Navigator.pop(context); // Fermer le loading

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );

        // Recharger les données
        await _loadAllData();
        setState(() {}); // Forcer la mise à jour de l'interface
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Fermer le loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showConstatDetails(Map<String, dynamic> constat) {
    _showComingSoon('Détails du constat #${constat['numero'] ?? 'N/A'}');
  }

  void _showNotifications() {
    _showComingSoon('Notifications');
  }

  /// 🏢 Ouvrir l'écran de création d'agence uniquement
  Future<void> _showCreateAgenceOnlyScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateAgenceOnlyScreen(userData: widget.userData!),
      ),
    );

    if (result != null && result['success'] == true) {
      // Afficher le message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Agence créée avec succès !'),
          backgroundColor: Colors.green,
        ),
      );

      // Recharger les données
      await _refreshData();
    }
  }

  void _showCreateAdminAgenceDialog(Map<String, dynamic> agence) {
    final prenomController = TextEditingController();
    final nomController = TextEditingController();
    final telephoneController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person_add_rounded, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Créer Admin pour ${agence['nom']}'),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: prenomController,
                decoration: const InputDecoration(
                  labelText: 'Prénom *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: telephoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (optionnel - sera généré automatiquement)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ℹ️ Un email et mot de passe seront générés automatiquement pour cet admin agence.',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => _createAdminAgence(
              context,
              agence,
              prenomController.text,
              nomController.text,
              telephoneController.text,
              emailController.text.isEmpty ? null : emailController.text,
            ),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Créer Admin'),
          ),
        ],
      ),
    );
  }

  Future<void> _createAdminAgence(
    BuildContext context,
    Map<String, dynamic> agence,
    String prenom,
    String nom,
    String telephone,
    String? email,
  ) async {
    if (prenom.isEmpty || nom.isEmpty || telephone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pop(context);

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await AdminCompagnieAgenceService.createAdminAgence(
        agenceId: agence['id'],
        agenceNom: agence['nom'],
        compagnieId: widget.userData!['compagnieId'],
        compagnieNom: widget.userData!['compagnieNom'],
        prenom: prenom,
        nom: nom,
        telephone: telephone,
        email: email,
      );

      // Vérifier si le widget est encore monté
      if (!mounted) return;

      Navigator.pop(context); // Fermer le loading

      if (result['success']) {
        // Naviguer vers l'écran d'affichage des identifiants
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminAgenceCredentialsDisplay(
              email: result['email'],
              password: result['password'],
              agenceName: agence['nom'],
              adminName: result['displayName'],
              companyName: widget.userData!['compagnieNom'],
            ),
          ),
        );

        // Recharger les données
        await _loadAllData();
        setState(() {}); // Forcer la mise à jour
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Fermer le loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAdminCredentialsDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green),
            SizedBox(width: 8),
            Text('Admin Agence Créé !'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Identifiants générés :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('👤 Nom: ${result['displayName']}'),
                  const SizedBox(height: 8),
                  Text('📧 Email: ${result['email']}'),
                  const SizedBox(height: 8),
                  Text('🔑 Mot de passe: ${result['password']}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '⚠️ Transmettez ces identifiants à l\'admin agence. Il pourra se connecter immédiatement.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  // Méthodes pour les autres onglets (à implémenter)
  Widget _buildConstatsFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text('Filtres des constats - À implémenter'),
    );
  }

  Widget _buildAdminsAgenceList() {
    // Utiliser la liste des admins agence chargée directement
    final adminsAgence = _adminsAgence;

    if (adminsAgence.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.admin_panel_settings_rounded, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Aucun admin agence créé',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              Text(
                'Créez des admins pour vos agences depuis l\'onglet Agences',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: adminsAgence.length,
      itemBuilder: (context, index) {
        final admin = adminsAgence[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Icon(Icons.admin_panel_settings_rounded, color: Colors.green),
            ),
            title: Text(
              '${admin['prenom'] ?? ''} ${admin['nom'] ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📧 ${admin['email'] ?? 'Email non défini'}'),
                Text('🏢 Agence: ${admin['agenceNom'] ?? 'Agence non définie'}'),
                Text('📊 Statut: ${admin['isActive'] == true ? 'Actif' : 'Inactif'}'),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility_rounded),
                      SizedBox(width: 8),
                      Text('Voir détails'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reset_password',
                  child: Row(
                    children: [
                      Icon(Icons.lock_reset_rounded),
                      SizedBox(width: 8),
                      Text('Réinitialiser mot de passe'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: admin['isActive'] == true ? 'disable' : 'enable',
                  child: Row(
                    children: [
                      Icon(
                        admin['isActive'] == true ? Icons.block_rounded : Icons.check_circle_rounded,
                        color: admin['isActive'] == true ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(admin['isActive'] == true ? 'Désactiver' : 'Activer'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer (libère agence)', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) => _handleAdminAgenceAction(value, admin),
            ),
          ),
        );
      },
    );
  }

  void _handleAdminAgenceAction(String action, Map<String, dynamic> admin) {
    switch (action) {
      case 'view':
        _showAdminAgenceDetails(admin);
        break;
      case 'reset_password':
        _showResetPasswordDialog(admin);
        break;
      case 'disable':
        _toggleAdminAgenceStatus(admin, false);
        break;
      case 'enable':
        _toggleAdminAgenceStatus(admin, true);
        break;
      case 'delete':
        _showDeleteAdminConfirmation(admin);
        break;
      default:
        _showComingSoon('Action: $action');
    }
  }

  Future<void> _toggleAdminAgenceStatus(Map<String, dynamic> admin, bool isActive) async {
    try {
      final result = await AdminCompagnieAgenceService.toggleAdminAgenceStatus(
        admin['uid'] ?? admin['id'],
        isActive,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );

        // Recharger les données
        await _loadAllData();
        setState(() {}); // Forcer la mise à jour
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAdminAgenceDetails(Map<String, dynamic> admin) {
    _showComingSoon('Détails de l\'admin agence ${admin['adminEmail']}');
  }

  void _showResetPasswordDialog(Map<String, dynamic> admin) {
    _showComingSoon('Réinitialisation du mot de passe pour ${admin['adminEmail']}');
  }

  Widget _buildExpertsList() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text('Liste des experts - À implémenter'),
      ),
    );
  }

  Widget _buildExportOptions() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text('Options d\'export - À implémenter'),
      ),
    );
  }

  Widget _buildPredefinedReports() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text('Rapports prédéfinis - À implémenter'),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  /// 👨‍💼 Ouvrir l'écran de création d'admin agence
  Future<void> _showCreateAdminAgenceScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateAdminAgenceScreen(userData: widget.userData!),
      ),
    );

    if (result != null) {
      // Recharger les données après création
      await _refreshData();
    }
  }

  /// ⚙️ Paramètres de la compagnie - Onglet 4
  Widget _buildParametresCompagnie() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paramètres de la Compagnie',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),

          // Informations de la compagnie
          _buildCompanyInfoCard(),
          const SizedBox(height: 20),

          // Paramètres généraux
          _buildGeneralSettingsCard(),
          const SizedBox(height: 20),

          // Actions administratives
          _buildAdminActionsCard(),
        ],
      ),
    );
  }

  Widget _buildCompanyInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.business_rounded, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text(
                'Informations de la Compagnie',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.business_rounded, 'Nom', _compagnieData?['nom'] ?? 'Non défini'),
          _buildInfoRow(Icons.code_rounded, 'Code', _compagnieData?['code'] ?? 'Non défini'),
          _buildInfoRow(Icons.email_rounded, 'Email', _compagnieData?['email'] ?? 'Non défini'),
          _buildInfoRow(Icons.phone_rounded, 'Téléphone', _compagnieData?['telephone'] ?? 'Non défini'),
          _buildInfoRow(Icons.location_on_rounded, 'Adresse', _compagnieData?['adresse'] ?? 'Non défini'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showComingSoon('Modification des informations'),
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Modifier les informations'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF059669),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.settings_rounded, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text(
                'Paramètres Généraux',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.notifications_rounded),
            title: const Text('Notifications'),
            subtitle: const Text('Gérer les notifications par email'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded),
            onTap: () => _showComingSoon('Paramètres de notifications'),
          ),
          ListTile(
            leading: const Icon(Icons.security_rounded),
            title: const Text('Sécurité'),
            subtitle: const Text('Paramètres de sécurité et accès'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded),
            onTap: () => _showComingSoon('Paramètres de sécurité'),
          ),
          ListTile(
            leading: const Icon(Icons.backup_rounded),
            title: const Text('Sauvegarde'),
            subtitle: const Text('Exporter les données'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded),
            onTap: () => _showComingSoon('Sauvegarde des données'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text(
                'Actions Administratives',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _refreshData(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Actualiser les données'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showComingSoon('Export des rapports'),
              icon: const Icon(Icons.download_rounded),
              label: const Text('Exporter les rapports'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF059669),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🗑️ Afficher la confirmation de suppression d'admin agence
  Future<void> _showDeleteAdminConfirmation(Map<String, dynamic> admin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirmer la suppression'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Êtes-vous sûr de vouloir supprimer cet admin agence ?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin: ${admin['prenom']} ${admin['nom']}'),
                  Text('Email: ${admin['email']}'),
                  Text('Agence: ${admin['agenceNom'] ?? 'Non affectée'}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Text(
                '⚠️ Cette action est irréversible !\n'
                '• L\'admin sera définitivement supprimé\n'
                '• Son agence sera libérée et disponible pour un nouvel admin\n'
                '• Tous ses accès seront révoqués',
                style: TextStyle(fontSize: 12),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAdminAgence(admin);
    }
  }

  /// 🗑️ Supprimer un admin agence et libérer son agence
  Future<void> _deleteAdminAgence(Map<String, dynamic> admin) async {
    try {
      final result = await AdminCompagnieAgenceService.deleteAdminAgence(
        admin['id'],
        admin['agenceId'],
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        await _refreshData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 📊 Statistiques des admins agences
  Widget _buildAdminAgenceStats() {
    final totalAdmins = _adminsAgence.length;
    final actifs = _adminsAgence.where((a) => a['isActive'] == true).length;
    final inactifs = _adminsAgence.where((a) => a['isActive'] != true).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Admins',
              totalAdmins.toString(),
              Icons.admin_panel_settings_rounded,
              const Color(0xFF667EEA),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Actifs',
              actifs.toString(),
              Icons.check_circle_rounded,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Inactifs',
              inactifs.toString(),
              Icons.pause_circle_rounded,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Liste moderne des admins agences
  Widget _buildModernAdminsAgenceList() {
    if (_adminsAgence.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings_rounded,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun admin agence',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez votre premier admin agence',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _adminsAgence.length,
      itemBuilder: (context, index) {
        final admin = _adminsAgence[index];
        return _buildModernAdminAgenceCard(admin);
      },
    );
  }

  /// 👨‍💼 Carte moderne d'admin agence
  Widget _buildModernAdminAgenceCard(Map<String, dynamic> admin) {
    final isActive = admin['isActive'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête avec avatar et statut
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isActive
                    ? [const Color(0xFF10B981), const Color(0xFF059669)]
                    : [const Color(0xFF6B7280), const Color(0xFF4B5563)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),

                // Nom et agence
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${admin['prenom']} ${admin['nom']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        admin['agenceNom'] ?? 'Agence non définie',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                // Badge de statut
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'ACTIF' : 'INACTIF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenu principal
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Informations de contact
                _buildInfoRow(Icons.email_rounded, 'Email', admin['email'] ?? 'Non défini'),
                _buildInfoRow(Icons.phone_rounded, 'Téléphone', admin['telephone'] ?? 'Non défini'),
                if (admin['cin'] != null)
                  _buildInfoRow(Icons.credit_card_rounded, 'CIN', admin['cin']),

                const SizedBox(height: 16),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showAdminAgenceDetails(admin),
                        icon: const Icon(Icons.visibility_rounded),
                        label: const Text('Détails'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF667EEA),
                          side: const BorderSide(color: Color(0xFF667EEA)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _toggleAdminAgenceStatus(admin, !isActive),
                        icon: Icon(isActive ? Icons.block_rounded : Icons.check_circle_rounded),
                        label: Text(isActive ? 'Désactiver' : 'Activer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isActive ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }





}
