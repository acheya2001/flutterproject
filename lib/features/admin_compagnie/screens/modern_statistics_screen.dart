import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import '../../../services/admin_compagnie_stats_service.dart';
import '../../../services/export_service.dart';

/// 📊 Écran moderne des statistiques avec design BI
class ModernStatisticsScreen extends StatefulWidget {
  final Map<String, dynamic> compagnieData;

  const ModernStatisticsScreen({
    Key? key,
    required this.compagnieData,
  }) : super(key: key);

  @override
  State<ModernStatisticsScreen> createState() => _ModernStatisticsScreenState();
}

class _ModernStatisticsScreenState extends State<ModernStatisticsScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Variables pour le filtre par agence
  String? _selectedAgenceId;
  String _selectedAgenceName = 'Toutes les agences';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadStatistics();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 📊 Charger les statistiques
  Future<void> _loadStatistics() async {
    try {
      setState(() => _isLoading = true);

      final compagnieId = widget.compagnieData['id'] ?? '';
      final stats = await AdminCompagnieStatsService.getMyCompagnieStatistics(compagnieId);

      setState(() {
        _statistics = stats;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      debugPrint('[MODERN_STATS] ❌ Erreur: $e');
      setState(() => _isLoading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark background moderne
      body: CustomScrollView(
        slivers: [
          // AppBar moderne avec gradient
          _buildModernAppBar(),
          
          // Contenu principal
          SliverToBoxAdapter(
            child: _isLoading ? _buildModernLoadingState() : _buildModernContent(),
          ),
        ],
      ),
    );
  }

  /// 🎨 AppBar moderne avec gradient
  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1), // Indigo
              Color(0xFF8B5CF6), // Purple
              Color(0xFFEC4899), // Pink
            ],
          ),
        ),
        child: FlexibleSpaceBar(
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Analytics Dashboard',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              Text(
                widget.compagnieData['nom'] ?? 'Compagnie',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          centerTitle: false,
          titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        ),
      ),
      actions: [
        _buildActionButton(Icons.picture_as_pdf_rounded, 'PDF', _exportToPDF),
        _buildActionButton(Icons.table_chart_rounded, 'Excel', _exportToExcel),
        _buildActionButton(Icons.refresh_rounded, 'Refresh', _loadStatistics),
        const SizedBox(width: 16),
      ],
    );
  }

  /// 🎯 Bouton d'action moderne
  Widget _buildActionButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: IconButton(
        onPressed: onPressed,
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        tooltip: tooltip,
      ),
    );
  }

  /// ⏳ État de chargement moderne
  Widget _buildModernLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // KPIs skeleton
          Row(
            children: List.generate(2, (index) => 
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index == 0 ? 16 : 0),
                  child: _buildShimmerCard(height: 120),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          Row(
            children: List.generate(2, (index) => 
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index == 0 ? 16 : 0),
                  child: _buildShimmerCard(height: 120),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          
          // Chart skeleton
          _buildShimmerCard(height: 300),
          const SizedBox(height: 30),
          
          // Performance cards skeleton
          ...List.generate(3, (index) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: _buildShimmerCard(height: 80),
          )),
        ],
      ),
    );
  }

  /// ✨ Carte shimmer
  Widget _buildShimmerCard({required double height}) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1E293B),
      highlightColor: const Color(0xFF334155),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  /// 🎨 Contenu moderne
  Widget _buildModernContent() {
    if (_statistics == null) return const SizedBox();

    final overview = _statistics!['overview'] as Map<String, dynamic>? ?? {};
    final agents = _statistics!['agents'] as Map<String, dynamic>? ?? {};
    final contracts = _statistics!['contracts'] as Map<String, dynamic>? ?? {};
    final agences = _statistics!['agences'] as List<dynamic>? ?? [];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPIs modernes
            _buildModernKPIs(overview),
            const SizedBox(height: 30),
            
            // Métriques détaillées
            _buildDetailedMetrics(overview, agents, contracts),
            const SizedBox(height: 30),

            // Graphiques
            _buildChartsSection(agents, contracts),
            const SizedBox(height: 30),

            // Performance des agences
            _buildAgencesPerformance(agences),
            const SizedBox(height: 30),

            // Analyse des agents par agence
            _buildAgentsAnalysis(agents),
            const SizedBox(height: 30),

            // Insights intelligents
            _buildIntelligentInsights(overview, agents, contracts),
          ],
        ),
      ),
    );
  }

  /// 📊 KPIs modernes avec gradients
  Widget _buildModernKPIs(Map<String, dynamic> overview) {
    // Récupérer les données des autres sections
    final agents = _statistics?['agents'] as Map<String, dynamic>? ?? {};
    final contracts = _statistics?['contracts'] as Map<String, dynamic>? ?? {};

    // Debug: Afficher les données reçues
    debugPrint('[MODERN_STATS] 🔍 Overview: $overview');
    debugPrint('[MODERN_STATS] 🔍 Agents: $agents');
    debugPrint('[MODERN_STATS] 🔍 Contracts: $contracts');
    debugPrint('[MODERN_STATS] 🔍 All statistics: $_statistics');

    final kpis = [
      {
        'title': 'Total Agences',
        'value': overview['totalAgences']?.toString() ?? '0',
        'icon': Icons.business_rounded,
        'gradient': [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
        'change': '+12%',
        'isPositive': true,
      },
      {
        'title': 'Total Agents',
        'value': agents['totalAgents']?.toString() ?? '0',
        'icon': Icons.people_rounded,
        'gradient': [const Color(0xFF10B981), const Color(0xFF059669)],
        'change': '+8%',
        'isPositive': true,
      },
      {
        'title': 'Contrats Actifs',
        'value': contracts['total']?.toString() ?? '0',
        'icon': Icons.description_rounded,
        'gradient': [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        'change': '+15%',
        'isPositive': true,
      },
      {
        'title': 'Sinistres',
        'value': overview['totalSinistres']?.toString() ?? '0',
        'icon': Icons.warning_rounded,
        'gradient': [const Color(0xFFEF4444), const Color(0xFFDC2626)],
        'change': '-5%',
        'isPositive': false,
      },
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildModernKPICard(kpis[0])),
            const SizedBox(width: 16),
            Expanded(child: _buildModernKPICard(kpis[1])),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildModernKPICard(kpis[2])),
            const SizedBox(width: 16),
            Expanded(child: _buildModernKPICard(kpis[3])),
          ],
        ),
      ],
    );
  }

  /// 🎯 Carte KPI moderne
  Widget _buildModernKPICard(Map<String, dynamic> kpi) {
    return Container(
      height: 120, // Hauteur réduite pour éviter l'overflow
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: kpi['gradient'] as List<Color>,
        ),
        borderRadius: BorderRadius.circular(16), // Réduit le radius
        boxShadow: [
          BoxShadow(
            color: (kpi['gradient'] as List<Color>)[0].withOpacity(0.3),
            blurRadius: 15, // Réduit le blur
            offset: const Offset(0, 8), // Réduit l'offset
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12), // Réduit encore le padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribue l'espace
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  kpi['icon'] as IconData,
                  color: Colors.white,
                  size: 28,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        kpi['isPositive'] ? Icons.trending_up : Icons.trending_down,
                        color: Colors.white,
                        size: 12, // Réduit de 14 à 12
                      ),
                      const SizedBox(width: 2), // Réduit l'espacement
                      Text(
                        kpi['change'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10, // Réduit de 12 à 10
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              kpi['value'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24, // Réduit encore de 28 à 24
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              kpi['title'],
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12, // Réduit de 13 à 12
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📊 Métriques détaillées
  Widget _buildDetailedMetrics(
    Map<String, dynamic> overview,
    Map<String, dynamic> agents,
    Map<String, dynamic> contracts,
  ) {
    final totalAgents = agents['totalAgents'] ?? 0;
    final activeAgents = agents['activeAgents'] ?? 0;
    final totalAgences = overview['totalAgences'] ?? 0;
    final totalContrats = contracts['total'] ?? 0;

    final metrics = [
      {
        'title': 'Agents Actifs',
        'value': '$activeAgents / $totalAgents',
        'percentage': totalAgents > 0 ? (activeAgents / totalAgents * 100).toInt() : 0,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Ratio Agent/Agence',
        'value': totalAgences > 0 ? (totalAgents / totalAgences).toStringAsFixed(1) : '0',
        'percentage': totalAgences > 0 ? ((totalAgents / totalAgences) * 20).toInt().clamp(0, 100) : 0,
        'color': const Color(0xFF6366F1),
      },
      {
        'title': 'Contrats par Agent',
        'value': totalAgents > 0 ? (totalContrats / totalAgents).toStringAsFixed(1) : '0',
        'percentage': totalAgents > 0 ? ((totalContrats / totalAgents) * 10).toInt().clamp(0, 100) : 0,
        'color': const Color(0xFFF59E0B),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Métriques de Performance',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),

        ...metrics.map((metric) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      metric['value'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: (metric['percentage'] as int) / 100,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(metric['color'] as Color),
                  strokeWidth: 6,
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  /// 📈 Section des graphiques
  Widget _buildChartsSection(Map<String, dynamic> agents, Map<String, dynamic> contracts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Analytics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),

        Container(
          height: 300,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Répartition des Performances',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Row(
                    children: [
                      // Graphique en secteurs
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sections: _getPerformanceChartData(agents, contracts),
                            centerSpaceRadius: 40,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Légende
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendItem('Agents Actifs', const Color(0xFF6366F1)),
                          _buildLegendItem('Contrats', const Color(0xFF10B981)),
                          _buildLegendItem('Agences', const Color(0xFFF59E0B)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 🏷️ Item de légende
  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Données pour le graphique de performance
  List<PieChartSectionData> _getPerformanceChartData(
    Map<String, dynamic> agents,
    Map<String, dynamic> contracts
  ) {
    final totalAgents = agents['totalAgents'] ?? 0;
    final totalContracts = contracts['total'] ?? 0;
    final totalAgences = _statistics?['overview']?['totalAgences'] ?? 0;

    final total = totalAgents + totalContracts + totalAgences;
    if (total == 0) return [];

    return [
      PieChartSectionData(
        color: const Color(0xFF6366F1),
        value: totalAgents.toDouble(),
        title: '${((totalAgents / total) * 100).toInt()}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: const Color(0xFF10B981),
        value: totalContracts.toDouble(),
        title: '${((totalContracts / total) * 100).toInt()}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: const Color(0xFFF59E0B),
        value: totalAgences.toDouble(),
        title: '${((totalAgences / total) * 100).toInt()}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  /// 🏢 Performance des agences
  Widget _buildAgencesPerformance(List<dynamic> agences) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance des Agences',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),

        ...agences.take(5).map((agence) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agence['nom'] ?? 'Agence',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      agence['adresse'] ?? 'Adresse non définie',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${agence['totalAgents'] ?? 0}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Agents',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  /// 👥 Analyse des agents par agence
  Widget _buildAgentsAnalysis(Map<String, dynamic> agents) {
    final topPerformers = agents['topPerformers'] as List<dynamic>? ?? [];
    final allAgents = agents['allAgents'] as List<dynamic>? ?? [];
    final agencesList = _statistics?['agences'] as List<dynamic>? ?? [];

    // Filtrer les agents selon l'agence sélectionnée
    List<dynamic> filteredAgents = _selectedAgenceId == null
        ? topPerformers
        : topPerformers.where((agent) {
            final agentAgenceId = agent['agenceId']?.toString() ?? '';
            final selectedId = _selectedAgenceId?.toString() ?? '';
            return agentAgenceId == selectedId;
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: const Text(
                'Top Agents Performants',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: _buildAgenceSelector(agencesList),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (filteredAgents.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 48,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedAgenceId == null
                      ? 'Aucun agent trouvé'
                      : 'Aucun agent dans $_selectedAgenceName',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedAgenceId == null
                      ? 'Aucun agent n\'est enregistré dans cette compagnie'
                      : 'Cette agence n\'a pas encore d\'agents assignés',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),

              ],
            ),
          )
        else
          ...filteredAgents.take(5).map((agent) {
            final contractsCount = agent['contractsCount'] ?? 0;
            final maxContracts = filteredAgents.isNotEmpty
                ? (filteredAgents.first['contractsCount'] ?? 1)
                : 1;
            final percentage = maxContracts > 0 ? (contractsCount / maxContracts) : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.lerp(const Color(0xFF6366F1), const Color(0xFF10B981), percentage)!,
                          Color.lerp(const Color(0xFF8B5CF6), const Color(0xFF059669), percentage)!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          agent['nom'] ?? 'Agent',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          agent['agenceNom'] ?? 'Agence non définie',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$contractsCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Contrats',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color.lerp(const Color(0xFF6366F1), const Color(0xFF10B981), percentage)!,
                      ),
                      strokeWidth: 4,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  /// 🧠 Insights intelligents
  Widget _buildIntelligentInsights(
    Map<String, dynamic> overview,
    Map<String, dynamic> agents,
    Map<String, dynamic> contracts,
  ) {
    final insights = _generateInsights(overview, agents, contracts);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Insights Intelligents',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),

        ...insights.map((insight) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: insight['colors'] as List<Color>,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                insight['icon'] as IconData,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight['description'],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  /// 🎯 Générer des insights intelligents
  List<Map<String, dynamic>> _generateInsights(
    Map<String, dynamic> overview,
    Map<String, dynamic> agents,
    Map<String, dynamic> contracts,
  ) {
    final insights = <Map<String, dynamic>>[];

    final totalAgents = agents['totalAgents'] ?? 0;
    final totalAgences = overview['totalAgences'] ?? 0;
    final totalContrats = contracts['total'] ?? 0;

    // Ratio agents/agences
    if (totalAgences > 0) {
      final ratio = totalAgents / totalAgences;
      if (ratio > 2) {
        insights.add({
          'title': 'Excellente couverture',
          'description': 'Vous avez ${ratio.toStringAsFixed(1)} agents par agence en moyenne',
          'icon': Icons.trending_up_rounded,
          'colors': [const Color(0xFF10B981), const Color(0xFF059669)],
        });
      } else if (ratio < 1) {
        insights.add({
          'title': 'Opportunité de croissance',
          'description': 'Certaines agences pourraient bénéficier d\'agents supplémentaires',
          'icon': Icons.add_business_rounded,
          'colors': [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        });
      }
    }

    // Performance des contrats
    if (totalContrats > 10) {
      insights.add({
        'title': 'Portfolio solide',
        'description': 'Votre portefeuille de $totalContrats contrats montre une bonne activité',
        'icon': Icons.assessment_rounded,
        'colors': [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
      });
    }

    return insights;
  }

  /// 📄 Export PDF
  Future<void> _exportToPDF() async {
    try {
      final compagnieName = widget.compagnieData['nom'] ?? 'Compagnie';
      await ExportService.exportStatisticsPDF(_statistics ?? {}, compagnieName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ PDF exporté avec succès'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur export PDF: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  /// 📊 Export Excel (Fonctionnalité à venir)
  Future<void> _exportToExcel() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📊 Export Excel - Fonctionnalité à venir'),
          backgroundColor: Color(0xFF6366F1),
        ),
      );
    }
  }

  /// 🏢 Sélecteur d'agence pour filtrer les agents
  Widget _buildAgenceSelector(List<dynamic> agencesList) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedAgenceId,
          hint: Text(
            _selectedAgenceName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white70,
          ),
          items: [
            // Option "Toutes les agences"
            const DropdownMenuItem<String>(
              value: null,
              child: Text(
                'Toutes les agences',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            // Options pour chaque agence
            ...agencesList.map((agence) {
              return DropdownMenuItem<String>(
                value: agence['id'],
                child: Text(
                  agence['nom'] ?? 'Agence sans nom',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
          ],
          onChanged: (String? newValue) {
            setState(() {
              _selectedAgenceId = newValue;
              if (newValue == null) {
                _selectedAgenceName = 'Toutes les agences';
              } else {
                final selectedAgence = agencesList.firstWhere(
                  (agence) => agence['id'] == newValue,
                  orElse: () => {'nom': 'Agence inconnue'},
                );
                _selectedAgenceName = selectedAgence['nom'] ?? 'Agence inconnue';
              }
            });
          },
        ),
      ),
    );
  }
}
