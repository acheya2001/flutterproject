import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import '../../../services/admin_compagnie_stats_service.dart';
import '../../../services/export_service.dart';

/// 📊 Écran des statistiques détaillées de la compagnie
class CompagnieStatisticsScreen extends StatefulWidget {
  final Map<String, dynamic> compagnieData;

  const CompagnieStatisticsScreen({
    Key? key,
    required this.compagnieData,
  }) : super(key: key);

  @override
  State<CompagnieStatisticsScreen> createState() => _CompagnieStatisticsScreenState();
}

class _CompagnieStatisticsScreenState extends State<CompagnieStatisticsScreen> {
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
      setState(() => _isLoading = true);

      final compagnieId = widget.compagnieData['id'] ?? '';
      debugPrint('[COMPAGNIE_STATS_SCREEN] 🔍 CompagnieId reçu: $compagnieId');
      debugPrint('[COMPAGNIE_STATS_SCREEN] 🔍 CompagnieData: ${widget.compagnieData}');

      final stats = await AdminCompagnieStatsService.getMyCompagnieStatistics(compagnieId);

      debugPrint('[COMPAGNIE_STATS_SCREEN] 📊 Stats reçues: $stats');

      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[COMPAGNIE_STATS_SCREEN] ❌ Erreur chargement statistiques: $e');
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
          Text(
            'Statistiques ${widget.compagnieData['nom'] ?? 'Compagnie'}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'Vue d\'ensemble et analytics',
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
      return const Center(
        child: Text(
          'Aucune donnée disponible',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final overview = _statistics!['overview'] as Map<String, dynamic>? ?? {};
    final agences = _statistics!['agences'] as List<dynamic>? ?? [];
    final financial = _statistics!['financial'] as Map<String, dynamic>? ?? {};
    final agents = _statistics!['agents'] as Map<String, dynamic>? ?? {};
    final contracts = _statistics!['contracts'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Métriques globales
          _buildGlobalMetrics(overview),
          const SizedBox(height: 30),

          // Performance financière
          _buildFinancialSection(financial),
          const SizedBox(height: 30),

          // Agences
          _buildAgencesSection(agences),
          const SizedBox(height: 30),

          // Agents et Contrats
          _buildAgentsAndContractsSection(agents, contracts),
        ],
      ),
    );
  }

  /// 📊 Métriques globales
  Widget _buildGlobalMetrics(Map<String, dynamic> overview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vue d\'ensemble',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 20),
        
        // Grille de métriques
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8, // Augmenté pour plus d'espace vertical
          children: [
            _buildMetricCard(
              'Total Agences',
              overview['totalAgences']?.toString() ?? '0',
              Icons.business_rounded,
              const Color(0xFF3B82F6),
            ),
            _buildMetricCard(
              'Total Contrats',
              overview['totalContrats']?.toString() ?? '0',
              Icons.description_rounded,
              const Color(0xFF10B981),
            ),
            _buildMetricCard(
              'Total Agents',
              overview['totalAgents']?.toString() ?? '0',
              Icons.people_rounded,
              const Color(0xFF8B5CF6),
            ),
            _buildMetricCard(
              'Total Sinistres',
              overview['totalSinistres']?.toString() ?? '0',
              Icons.warning_rounded,
              const Color(0xFFF59E0B),
            ),
          ],
        ),
      ],
    );
  }

  /// 💰 Section financière
  Widget _buildFinancialSection(Map<String, dynamic> financial) {
    return Container(
      padding: const EdgeInsets.all(24),
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
            'Performance Financière',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildFinancialMetric(
                  'Ce mois',
                  '${(financial['primesThisMonth'] ?? 0).toStringAsFixed(0)} DT',
                  financial['financialGrowthRate']?.toDouble(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFinancialMetric(
                  'Cette année',
                  '${(financial['primesThisYear'] ?? 0).toStringAsFixed(0)} DT',
                  null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🏢 Section agences
  Widget _buildAgencesSection(List<dynamic> agences) {
    return Container(
      padding: const EdgeInsets.all(24),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Performance des Agences',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              Text(
                '${agences.length} agences',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Liste des agences
          ...agences.take(5).map((agence) => _buildAgenceItem(agence)).toList(),
          
          if (agences.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: Naviguer vers la liste complète
                  },
                  child: Text('Voir toutes les agences (${agences.length})'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 👥📄 Section agents et contrats
  Widget _buildAgentsAndContractsSection(Map<String, dynamic> agents, Map<String, dynamic> contracts) {
    return Container(
      padding: const EdgeInsets.all(24),
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
            'Agents et Contrats',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),

          // Métriques agents et contrats
          Row(
            children: [
              Expanded(
                child: _buildAgentsMetrics(agents),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildContractsMetrics(contracts),
              ),
            ],
          ),

          // Top performers
          if (agents['topPerformers'] != null && (agents['topPerformers'] as List).isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Top Agents Performants',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            ...((agents['topPerformers'] as List).take(3).map((agent) =>
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        agent['nom'] ?? 'Agent inconnu',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
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
              )
            ).toList()),
          ],
        ],
      ),
    );
  }

  /// 👥 Métriques des agents
  Widget _buildAgentsMetrics(Map<String, dynamic> agents) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agents',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${agents['totalAgents'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                    const Text(
                      'Total',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${agents['activeAgents'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const Text(
                      'Actifs',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📄 Métriques des contrats
  Widget _buildContractsMetrics(Map<String, dynamic> contracts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contrats',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${contracts['total'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    const Text(
                      'Total',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${contracts['actifs'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const Text(
                      'Actifs',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📊 Carte de métrique
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16), // Réduit de 20 à 16
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
        mainAxisSize: MainAxisSize.min, // Ajouté pour éviter l'overflow
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // Réduit de 8 à 6
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18), // Réduit de 20 à 18
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8), // Réduit de 12 à 8
          Flexible( // Ajouté pour éviter l'overflow
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 22, // Réduit de 24 à 22
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2), // Réduit de 4 à 2
          Flexible( // Ajouté pour éviter l'overflow
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12, // Réduit de 14 à 12
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  /// 💰 Métrique financière
  Widget _buildFinancialMetric(String title, String value, double? growthRate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          if (growthRate != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  growthRate >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: growthRate >= 0 ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  '${growthRate >= 0 ? '+' : ''}${growthRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: growthRate >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 🏢 Item d'agence
  Widget _buildAgenceItem(Map<String, dynamic> agence) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agence['nom'] ?? 'Agence inconnue',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  agence['ville'] ?? 'Ville inconnue',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${agence['totalContrats'] ?? 0} contrats',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(agence['totalPrimes'] ?? 0).toStringAsFixed(0)} DT',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  /// 📄 Exporter vers PDF
  void _exportToPDF() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final testStatistics = ExportService.generateTestStatistics();
      await ExportService.exportStatisticsPDF(testStatistics, widget.compagnieData['nom'] ?? 'Compagnie');

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📄 Rapport PDF généré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 📊 Exporter vers Excel
  void _exportToExcel() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final testContracts = ExportService.generateTestContracts();
      await ExportService.exportContractsToExcel(testContracts, widget.compagnieData['nom'] ?? 'Compagnie');

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📊 Export Excel réalisé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
