import 'package:flutter/material.dart';
import '../../../services/compagnie_bi_service.dart';

/// 📊 Widget des statistiques d'une compagnie
class CompagnieStatsWidget extends StatefulWidget {
  final String compagnieId;
  final String compagnieName;

  const CompagnieStatsWidget({
    Key? key,
    required this.compagnieId,
    required this.compagnieName,
  }) : super(key: key);

  @override
  State<CompagnieStatsWidget> createState() => _CompagnieStatsWidgetState();
}

class _CompagnieStatsWidgetState extends State<CompagnieStatsWidget> {
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadStatistics();
    });
  }

  /// 📊 Charger les statistiques
  Future<void> _loadStatistics() async {
    try {
      setState(() => _isLoading = true);
      
      final stats = await CompagnieBIService.getCompagnieStatistics(widget.compagnieId);
      
      if (mounted) setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement statistiques: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // En-tête
          Row(
            children: [
              Expanded(
                child: Text(
                  'Statistiques ${widget.compagnieName}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              IconButton(
                onPressed: _loadStatistics,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Actualiser',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Contenu
          if (_isLoading)
            _buildLoadingState()
          else if (_statistics == null)
            _buildErrorState()
          else
            _buildStatsContent(),
        ],
      ),
    );
  }

  /// ⏳ État de chargement
  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// ❌ État d'erreur
  Widget _buildErrorState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Text(
          'Erreur de chargement des statistiques',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  /// 📊 Contenu des statistiques
  Widget _buildStatsContent() {
    final global = _statistics!['global'] as Map<String, dynamic>? ?? {};
    final agences = _statistics!['agences'] as List<dynamic>? ?? [];
    final financial = _statistics!['financial'] as Map<String, dynamic>? ?? {};

    return Column(
      children: [
        // Métriques principales
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Agences',
                agences.length.toString(),
                Icons.business_rounded,
                const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Contrats',
                (global['totalContrats'] ?? 0).toString(),
                Icons.description_rounded,
                const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Agents',
                (global['totalAgents'] ?? 0).toString(),
                Icons.people_rounded,
                const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'CA',
                '${(global['totalPrimes'] ?? 0).toStringAsFixed(0)} DT',
                Icons.monetization_on_rounded,
                const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Performance financière
        Container(
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
                      'Performance Financière',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ce mois: ${(financial['primesThisMonth'] ?? 0).toStringAsFixed(0)} DT',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
              if (financial['financialGrowthRate'] != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (financial['financialGrowthRate'] ?? 0) >= 0 
                        ? Colors.green.withOpacity(0.1) 
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        (financial['financialGrowthRate'] ?? 0) >= 0 
                            ? Icons.trending_up 
                            : Icons.trending_down,
                        size: 16,
                        color: (financial['financialGrowthRate'] ?? 0) >= 0 
                            ? Colors.green 
                            : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(financial['financialGrowthRate'] ?? 0) >= 0 ? '+' : ''}${(financial['financialGrowthRate'] ?? 0).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: (financial['financialGrowthRate'] ?? 0) >= 0 
                              ? Colors.green 
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Top 3 agences
        if (agences.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Agences',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                ...agences.take(3).map((agence) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          agence['nom'] ?? 'Agence inconnue',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '${agence['totalContrats'] ?? 0} contrats',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 📊 Carte de métrique
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

