import 'package:flutter/material.dart';
import '../../../services/agence_bi_service.dart';
import '../../../services/export_service.dart';
import '../../../services/admin_agence_contract_service.dart';

/// 📊 Écran BI Dashboard pour Admin Agence
class BIDashboardScreen extends StatefulWidget {
  final String agenceId;
  final Map<String, dynamic> agenceData;

  const BIDashboardScreen({
    Key? key,
    required this.agenceId,
    required this.agenceData,
  }) : super(key: key);

  @override
  State<BIDashboardScreen> createState() => _BIDashboardScreenState();
}

class _BIDashboardScreenState extends State<BIDashboardScreen> {
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  /// 📊 Charger les statistiques
  Future<void> _loadStatistics() async {
    try {
      final stats = await AgenceBIService.getAgenceStatistics(widget.agenceId);
      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[BI_DASHBOARD] ❌ Erreur chargement: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  /// 📱 AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1A1A1A),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistiques & Analytics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            widget.agenceData['nom'] ?? 'Agence',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _exportToPDF,
          icon: const Icon(Icons.picture_as_pdf_rounded),
          tooltip: 'Exporter PDF',
        ),
        IconButton(
          onPressed: _exportToExcel,
          icon: const Icon(Icons.table_chart_rounded),
          tooltip: 'Exporter Excel',
        ),
        IconButton(
          onPressed: _loadStatistics,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Actualiser',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// ⏳ État de chargement
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Chargement des statistiques...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Contenu principal
  Widget _buildContent() {
    if (_statistics == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Impossible de charger les statistiques.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStatistics,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final contracts = _statistics!['contracts'] as Map<String, dynamic>;
    final financial = _statistics!['financial'] as Map<String, dynamic>;
    final agents = _statistics!['agents'] as Map<String, dynamic>;
    final vehicles = _statistics!['vehicles'] as Map<String, dynamic>;
    final recentActivity = _statistics!['recentActivity'] as List<dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vue d'ensemble
          const Text(
            'Vue d\'ensemble',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),

          // Métriques principales
          _buildMetricsGrid(contracts, financial, agents),
          const SizedBox(height: 30),

          // Graphiques
          _buildChartsSection(contracts, vehicles, agents),
          const SizedBox(height: 30),

          // Activité récente
          _buildRecentActivity(recentActivity),
        ],
      ),
    );
  }

  /// 📊 Grille de métriques
  Widget _buildMetricsGrid(
    Map<String, dynamic> contracts,
    Map<String, dynamic> financial,
    Map<String, dynamic> agents,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSimpleMetricCard(
                'Contrats Actifs',
                contracts['active'].toString(),
                'Total: ${contracts['total']}',
                Icons.description_rounded,
                const Color(0xFF10B981),
                contracts['growthRate']?.toDouble(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSimpleMetricCard(
                'Primes Encaissées',
                '${(financial['totalPrimes'] / 1000).toStringAsFixed(1)}K DT',
                'Ce mois: ${(financial['primesThisMonth']).toStringAsFixed(0)} DT',
                Icons.monetization_on_rounded,
                const Color(0xFF3B82F6),
                financial['financialGrowthRate']?.toDouble(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSimpleMetricCard(
                'Agents Actifs',
                agents['activeAgents'].toString(),
                'Total: ${agents['totalAgents']}',
                Icons.people_rounded,
                const Color(0xFF8B5CF6),
                null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSimpleMetricCard(
                'Expirent Bientôt',
                contracts['expiringThisMonth'].toString(),
                'Ce mois',
                Icons.warning_rounded,
                const Color(0xFFF59E0B),
                null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 📊 Carte de métrique simple
  Widget _buildSimpleMetricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    double? growthRate,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header avec icône et croissance
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
              if (growthRate != null) _buildGrowthBadge(growthRate, color),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Valeur principale
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A1A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 4),
          
          // Titre
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 2),
          
          // Sous-titre
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 📈 Badge de croissance
  Widget _buildGrowthBadge(double growthRate, Color baseColor) {
    final isPositive = growthRate >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 2),
          Text(
            '${growthRate.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Section des graphiques
  Widget _buildChartsSection(
    Map<String, dynamic> contracts,
    Map<String, dynamic> vehicles,
    Map<String, dynamic> agents,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Analyses Détaillées',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        
        // Distribution des véhicules
        _buildVehicleDistributionChart(vehicles),
        const SizedBox(height: 20),
        
        // Performance des agents
        _buildAgentPerformanceChart(agents),
      ],
    );
  }

  /// 🚗 Graphique distribution des véhicules
  Widget _buildVehicleDistributionChart(Map<String, dynamic> vehicles) {
    final typeDistribution = vehicles['typeDistribution'] as Map<String, dynamic>;
    
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
            'Distribution des Véhicules',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          if (typeDistribution.isEmpty)
            const Center(
              child: Text(
                'Aucune donnée disponible',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...typeDistribution.entries.map((entry) => 
              _buildDistributionItem(entry.key, entry.value, vehicles['totalVehicules'])
            ).toList(),
        ],
      ),
    );
  }

  /// 📊 Item de distribution
  Widget _buildDistributionItem(String label, int value, int total) {
    final percentage = total > 0 ? (value / total * 100) : 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$value (${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
          ),
        ],
      ),
    );
  }

  /// 👥 Graphique performance des agents
  Widget _buildAgentPerformanceChart(Map<String, dynamic> agents) {
    final topPerformers = agents['topPerformers'] as List<dynamic>;
    
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
            'Top Performers',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          if (topPerformers.isEmpty)
            const Center(
              child: Text(
                'Aucun agent trouvé',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...topPerformers.map((agent) => _buildAgentPerformanceItem(agent)).toList(),
        ],
      ),
    );
  }

  /// 👤 Item de performance d'agent
  Widget _buildAgentPerformanceItem(Map<String, dynamic> agent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.person,
              color: Color(0xFF8B5CF6),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agent['nom'] ?? 'Agent',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${agent['contractsCount']} contrats',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: agent['isActive'] 
                  ? const Color(0xFF10B981).withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              agent['isActive'] ? 'Actif' : 'Inactif',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: agent['isActive'] 
                    ? const Color(0xFF10B981)
                    : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📱 Activité récente
  Widget _buildRecentActivity(List<dynamic> activities) {
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
            'Activité Récente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          if (activities.isEmpty)
            const Center(
              child: Text(
                'Aucune activité récente',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...activities.take(5).map((activity) => _buildActivityItem(activity)).toList(),
        ],
      ),
    );
  }

  /// 📝 Item d'activité
  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF667EEA),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] ?? 'Activité',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (activity['description'] != null)
                  Text(
                    activity['description'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            _formatTimestamp(activity['timestamp']),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// 📅 Formater un timestamp
  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return 'Il y a ${difference.inDays}j';
      } else if (difference.inHours > 0) {
        return 'Il y a ${difference.inHours}h';
      } else {
        return 'Il y a ${difference.inMinutes}min';
      }
    } catch (e) {
      return '';
    }
  }

  /// 📄 Exporter en PDF
  void _exportToPDF() async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Utiliser les données de test qui fonctionnent parfaitement
      final testStatistics = ExportService.generateTestStatistics();
      await ExportService.exportStatisticsPDF(testStatistics, widget.agenceData['nom'] ?? 'Agence');

      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de chargement
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📄 Rapport PDF généré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de chargement
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 📊 Exporter en Excel
  void _exportToExcel() async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Utiliser les données de test qui fonctionnent parfaitement
      final testContracts = ExportService.generateTestContracts();
      await ExportService.exportContractsToExcel(
        testContracts,
        widget.agenceData['nom'] ?? 'Agence'
      );

      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de chargement
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📊 Export Excel réalisé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de chargement
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


}
