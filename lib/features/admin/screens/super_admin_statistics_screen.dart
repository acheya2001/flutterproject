import 'package:flutter/material.dart';
import '../../../services/super_admin_analytics_service.dart';

/// 📊 Écran de statistiques et rapports pour Super Admin
class SuperAdminStatisticsScreen extends StatefulWidget {
  const SuperAdminStatisticsScreen({Key? key}) : super(key: key);

  @override
  State<SuperAdminStatisticsScreen> createState() => _SuperAdminStatisticsScreenState();
}

class _SuperAdminStatisticsScreenState extends State<SuperAdminStatisticsScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  Map<String, dynamic> _globalStats = {};
  List<Map<String, dynamic>> _compagniesStats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final globalStats = await SuperAdminAnalyticsService.getDetailedGlobalStats();
      final compagniesStats = await SuperAdminAnalyticsService.getCompagniesDetailedStats();
      
      if (mounted) {
        setState(() {
          _globalStats = globalStats;
          _compagniesStats = compagniesStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement stats: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          '📊 Statistiques & Rapports',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E40AF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Vue Globale', icon: Icon(Icons.dashboard)),
            Tab(text: 'Compagnies', icon: Icon(Icons.business)),
            Tab(text: 'Tendances', icon: Icon(Icons.trending_up)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGlobalView(),
                _buildCompagniesView(),
                _buildTendancesView(),
              ],
            ),
    );
  }

  /// 🌍 Vue globale du système
  Widget _buildGlobalView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          _buildSectionHeader('Vue d\'ensemble du système', Icons.dashboard),
          const SizedBox(height: 20),

          // KPIs principaux
          _buildMainKPIs(),
          const SizedBox(height: 30),

          // Répartition des utilisateurs
          _buildUsersDistribution(),
          const SizedBox(height: 30),

          // Statistiques des sinistres
          _buildSinistresStats(),
          const SizedBox(height: 30),

          // Performance des agences
          _buildAgencesPerformance(),
        ],
      ),
    );
  }

  /// 🏢 Vue des compagnies
  Widget _buildCompagniesView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          _buildSectionHeader('Analyse par compagnie', Icons.business),
          const SizedBox(height: 20),

          // Résumé des compagnies
          _buildCompagniesOverview(),
          const SizedBox(height: 30),

          // Liste détaillée des compagnies
          _buildCompagniesDetailList(),
        ],
      ),
    );
  }

  /// 📈 Vue des tendances
  Widget _buildTendancesView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          _buildSectionHeader('Tendances et croissance', Icons.trending_up),
          const SizedBox(height: 20),

          // Métriques de croissance
          _buildGrowthMetrics(),
          const SizedBox(height: 30),

          // Évolution des sinistres
          _buildSinistresEvolution(),
          const SizedBox(height: 30),

          // Insights et recommandations
          _buildInsights(),
        ],
      ),
    );
  }

  /// 📋 En-tête de section
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E40AF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF1E40AF), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  /// 📊 KPIs principaux
  Widget _buildMainKPIs() {
    final compagnies = _globalStats['compagnies'] ?? {};
    final utilisateurs = _globalStats['utilisateurs'] ?? {};
    final sinistres = _globalStats['sinistres'] ?? {};
    final contrats = _globalStats['contrats'] ?? {};

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildKPICard(
              'Compagnies',
              '${compagnies['total'] ?? 0}',
              '${compagnies['actives'] ?? 0} actives',
              Icons.business,
              const Color(0xFF3B82F6),
            )),
            const SizedBox(width: 16),
            Expanded(child: _buildKPICard(
              'Utilisateurs',
              '${utilisateurs['total'] ?? 0}',
              '${utilisateurs['repartitionParStatut']?['actif'] ?? 0} actifs',
              Icons.people,
              const Color(0xFF059669),
            )),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildKPICard(
              'Sinistres',
              '${sinistres['total'] ?? 0}',
              'Total déclarés',
              Icons.car_crash,
              const Color(0xFFDC2626),
            )),
            const SizedBox(width: 16),
            Expanded(child: _buildKPICard(
              'Contrats',
              '${contrats['total'] ?? 0}',
              'Tous types',
              Icons.description,
              const Color(0xFF7C3AED),
            )),
          ],
        ),
      ],
    );
  }

  /// 📊 Carte KPI
  Widget _buildKPICard(String title, String value, String subtitle, IconData icon, Color color) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
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
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  /// 👥 Répartition des utilisateurs
  Widget _buildUsersDistribution() {
    final utilisateurs = _globalStats['utilisateurs'] ?? {};
    final repartitionParRole = utilisateurs['repartitionParRole'] ?? {};

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '👥 Répartition des utilisateurs par rôle',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          ...repartitionParRole.entries.map((entry) => 
            _buildRoleRow(entry.key, entry.value)
          ).toList(),
        ],
      ),
    );
  }

  /// 👤 Ligne de rôle
  Widget _buildRoleRow(String role, int count) {
    final total = _globalStats['utilisateurs']?['total'] ?? 1;
    final percentage = (count / total * 100).round();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _getRoleDisplayName(role),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(_getRoleColor(role)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$count ($percentage%)',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎨 Couleur par rôle
  Color _getRoleColor(String role) {
    switch (role) {
      case 'conducteur': return const Color(0xFF3B82F6);
      case 'agent': return const Color(0xFF059669);
      case 'expert': return const Color(0xFF7C3AED);
      case 'admin_agence': return const Color(0xFFF59E0B);
      case 'admin_compagnie': return const Color(0xFFDC2626);
      case 'super_admin': return const Color(0xFF1F2937);
      default: return const Color(0xFF6B7280);
    }
  }

  /// 📝 Nom d'affichage du rôle
  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'conducteur': return 'Conducteurs';
      case 'agent': return 'Agents';
      case 'expert': return 'Experts';
      case 'admin_agence': return 'Admins Agence';
      case 'admin_compagnie': return 'Admins Compagnie';
      case 'super_admin': return 'Super Admins';
      default: return role;
    }
  }

  /// 🔢 Calculer le nombre de sinistres en cours
  int _calculateSinistresEnCours(Map<String, dynamic> repartitionParStatut) {
    int total = 0;

    // Statuts considérés comme "en cours"
    const statutsEnCours = [
      'en_cours',
      'ouvert',
      'nouveau',
      'en_attente',
      'en_traitement',
      'pending',
      'open',
      'active'
    ];

    for (final statut in statutsEnCours) {
      total += (repartitionParStatut[statut] ?? 0) as int;
    }

    return total;
  }



  /// 🚗 Statistiques des sinistres
  Widget _buildSinistresStats() {
    final sinistres = _globalStats['sinistres'] ?? {};
    final repartitionParStatut = sinistres['repartitionParStatut'] ?? {};

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🚗 Analyse des sinistres',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total',
                  '${sinistres['total'] ?? 0}',
                  Icons.car_crash,
                  const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'En cours',
                  '${_calculateSinistresEnCours(sinistres['repartitionParStatut'] ?? {})}',
                  Icons.pending,
                  const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Répartition par statut:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          ...repartitionParStatut.entries.map((entry) =>
            _buildStatusRow(entry.key, entry.value)
          ).toList(),
        ],
      ),
    );
  }

  /// 📊 Ligne de statut
  Widget _buildStatusRow(String status, int count) {
    final total = _globalStats['sinistres']?['total'] ?? 1;
    final percentage = (count / total * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getStatusDisplayName(status),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
              ),
            ),
          ),
          Text(
            '$count ($percentage%)',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎨 Couleur par statut
  Color _getStatusColor(String status) {
    switch (status) {
      case 'en_cours': case 'ouvert': return const Color(0xFFF59E0B);
      case 'traite': case 'clos': return const Color(0xFF059669);
      case 'refuse': return const Color(0xFFDC2626);
      case 'en_attente': case 'nouveau': return const Color(0xFF3B82F6);
      default: return const Color(0xFF6B7280);
    }
  }

  /// 📝 Nom d'affichage du statut
  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'en_cours': return 'En cours';
      case 'ouvert': return 'Ouvert';
      case 'traite': return 'Traité';
      case 'clos': return 'Clos';
      case 'refuse': return 'Refusé';
      case 'en_attente': return 'En attente';
      case 'nouveau': return 'Nouveau';
      default: return status;
    }
  }

  /// 🏪 Performance des agences
  Widget _buildAgencesPerformance() {
    final agences = _globalStats['agences'] ?? {};

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏪 Performance des agences',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total agences',
                  '${agences['total'] ?? 0}',
                  Icons.store,
                  const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Avec admin',
                  '${agences['avecAdmin'] ?? 0}',
                  Icons.admin_panel_settings,
                  const Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: (agences['pourcentageAvecAdmin'] ?? 0) / 100,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation(Color(0xFF059669)),
          ),
          const SizedBox(height: 8),
          Text(
            '${agences['pourcentageAvecAdmin'] ?? 0}% des agences ont un administrateur',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Item de statistique
  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
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
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 🏢 Vue d'ensemble des compagnies
  Widget _buildCompagniesOverview() {
    final compagnies = _globalStats['compagnies'] ?? {};
    final repartitionParTaille = compagnies['repartitionParTaille'] ?? {};

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏢 Répartition des compagnies par taille',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildTailleCard('Petites', repartitionParTaille['petite'] ?? 0, '≤ 2 agences', const Color(0xFF3B82F6))),
              const SizedBox(width: 8),
              Expanded(child: _buildTailleCard('Moyennes', repartitionParTaille['moyenne'] ?? 0, '3-10 agences', const Color(0xFF059669))),
              const SizedBox(width: 8),
              Expanded(child: _buildTailleCard('Grandes', repartitionParTaille['grande'] ?? 0, '> 10 agences', const Color(0xFFDC2626))),
            ],
          ),
        ],
      ),
    );
  }

  /// 📏 Carte de taille
  Widget _buildTailleCard(String title, int count, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 1),
          Text(
            description,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF6B7280),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 📋 Liste détaillée des compagnies
  Widget _buildCompagniesDetailList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📋 Performance détaillée par compagnie',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        ..._compagniesStats.take(10).map((compagnie) => _buildCompagnieCard(compagnie)).toList(),
        if (_compagniesStats.length > 10) ...[
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Et ${_compagniesStats.length - 10} autres compagnies...',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 🏢 Carte de compagnie
  Widget _buildCompagnieCard(Map<String, dynamic> compagnie) {
    final stats = compagnie['stats'] ?? {};
    final isActive = compagnie['status'] == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? const Color(0xFF059669) : const Color(0xFFDC2626),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                      compagnie['nom'] ?? 'Sans nom',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Code: ${compagnie['code'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF059669) : const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildMiniStat('Agences', '${stats['agences'] ?? 0}', const Color(0xFF3B82F6))),
              const SizedBox(width: 4),
              Expanded(child: _buildMiniStat('Agents', '${stats['agents'] ?? 0}', const Color(0xFF059669))),
              const SizedBox(width: 4),
              Expanded(child: _buildMiniStat('Contrats', '${stats['contrats'] ?? 0}', const Color(0xFF7C3AED))),
              const SizedBox(width: 4),
              Expanded(child: _buildMiniStat('Sinistres', '${stats['sinistres'] ?? 0}', const Color(0xFFDC2626))),
            ],
          ),
        ],
      ),
    );
  }

  /// 📊 Mini statistique
  Widget _buildMiniStat(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF6B7280),
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 📈 Métriques de croissance
  Widget _buildGrowthMetrics() {
    final tendances = _globalStats['tendances'] ?? {};

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📈 Croissance des utilisateurs',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildGrowthCard(
                  'Ce mois',
                  '${tendances['nouveauxUsersCeMois'] ?? 0}',
                  'nouveaux utilisateurs',
                  const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGrowthCard(
                  'Mois précédent',
                  '${tendances['nouveauxUsersMoisPrecedent'] ?? 0}',
                  'nouveaux utilisateurs',
                  const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_up, color: Color(0xFF059669)),
                const SizedBox(width: 12),
                Text(
                  'Croissance: ${tendances['croissanceUsers'] ?? 0}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Carte de croissance
  Widget _buildGrowthCard(String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Évolution des sinistres
  Widget _buildSinistresEvolution() {
    final sinistres = _globalStats['sinistres'] ?? {};
    final evolutionParMois = sinistres['evolutionParMois'] ?? {};

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Évolution des sinistres par mois',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          if (evolutionParMois.isEmpty)
            const Text(
              'Aucune donnée d\'évolution disponible',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...evolutionParMois.entries.take(6).map((entry) =>
              _buildMonthRow(entry.key, entry.value)
            ).toList(),
        ],
      ),
    );
  }

  /// 📅 Ligne de mois
  Widget _buildMonthRow(String month, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              month,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 💡 Insights et recommandations
  Widget _buildInsights() {
    final compagnies = _globalStats['compagnies'] ?? {};
    final utilisateurs = _globalStats['utilisateurs'] ?? {};
    final agences = _globalStats['agences'] ?? {};

    List<Map<String, dynamic>> insights = [];

    // Générer des insights basés sur les données
    if ((compagnies['pourcentageActives'] ?? 0) < 80) {
      insights.add({
        'type': 'warning',
        'title': 'Compagnies inactives',
        'message': 'Seulement ${compagnies['pourcentageActives']}% des compagnies sont actives. Considérez contacter les compagnies inactives.',
        'icon': Icons.warning,
        'color': const Color(0xFFF59E0B),
      });
    }

    if ((agences['pourcentageAvecAdmin'] ?? 0) < 70) {
      insights.add({
        'type': 'info',
        'title': 'Agences sans admin',
        'message': '${agences['sansAdmin']} agences n\'ont pas d\'administrateur. Cela peut affecter leur efficacité.',
        'icon': Icons.info,
        'color': const Color(0xFF3B82F6),
      });
    }

    if ((utilisateurs['tauxActivation'] ?? 0) > 90) {
      insights.add({
        'type': 'success',
        'title': 'Excellent taux d\'activation',
        'message': '${utilisateurs['tauxActivation']}% des utilisateurs sont actifs. Excellente performance !',
        'icon': Icons.check_circle,
        'color': const Color(0xFF059669),
      });
    }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 Insights et recommandations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          if (insights.isEmpty)
            const Text(
              'Toutes les métriques sont dans les normes acceptables.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...insights.map((insight) => _buildInsightCard(insight)).toList(),
        ],
      ),
    );
  }

  /// 💡 Carte d'insight
  Widget _buildInsightCard(Map<String, dynamic> insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (insight['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (insight['color'] as Color).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            insight['icon'] as IconData,
            color: insight['color'] as Color,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight['title'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: insight['color'] as Color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight['message'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF374151),
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
