import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/compagnie_bi_service.dart';
import 'modern_statistics_screen.dart';

/// 🏢 Écran de vue d'ensemble de toutes les compagnies
class CompagniesOverviewScreen extends StatefulWidget {
  const CompagniesOverviewScreen({Key? key}) : super(key: key);

  @override
  State<CompagniesOverviewScreen> createState() => _CompagniesOverviewScreenState();
}

class _CompagniesOverviewScreenState extends State<CompagniesOverviewScreen> {
  List<Map<String, dynamic>> _compagnies = [];
  Map<String, Map<String, dynamic>> _compagniesStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadCompagnies();
    });
  }

  /// 🏢 Charger toutes les compagnies
  Future<void> _loadCompagnies() async {
    try {
      setState(() => _isLoading = true);

      // Récupérer toutes les compagnies
      final compagniesSnapshot = await FirebaseFirestore.instance
          .collection('compagnies_assurance')
          .get();

      final compagnies = compagniesSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Charger les statistiques pour chaque compagnie
      final stats = <String, Map<String, dynamic>>{};
      for (final compagnie in compagnies) {
        try {
          final compagnieStats = await CompagnieBIService.getCompagnieStatistics(compagnie['id']);
          stats[compagnie['id']] = compagnieStats;
        } catch (e) {
          debugPrint('Erreur stats compagnie ${compagnie['id']}: $e');
          stats[compagnie['id']] = {};
        }
      }

      if (mounted) setState(() {
        _compagnies = compagnies;
        _compagniesStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement compagnies: $e');
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
            'Vue d\'ensemble des Compagnies',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '${_compagnies.length} compagnies d\'assurance',
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
          onPressed: _loadCompagnies,
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
            'Chargement des compagnies...',
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
    if (_compagnies.isEmpty) {
      return const Center(
        child: Text(
          'Aucune compagnie trouvée',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistiques globales
          _buildGlobalStats(),
          const SizedBox(height: 30),

          // Liste des compagnies
          const Text(
            'Compagnies d\'Assurance',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),

          // Grille des compagnies
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              childAspectRatio: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _compagnies.length,
            itemBuilder: (context, index) {
              final compagnie = _compagnies[index];
              final stats = _compagniesStats[compagnie['id']] ?? {};
              return _buildCompagnieCard(compagnie, stats);
            },
          ),
        ],
      ),
    );
  }

  /// 📊 Statistiques globales
  Widget _buildGlobalStats() {
    int totalAgences = 0;
    int totalContrats = 0;
    int totalAgents = 0;
    double totalPrimes = 0;

    for (final stats in _compagniesStats.values) {
      final global = stats['global'] as Map<String, dynamic>? ?? {};
      totalAgences += (global['totalAgences'] ?? 0) as int;
      totalContrats += (global['totalContrats'] ?? 0) as int;
      totalAgents += (global['totalAgents'] ?? 0) as int;
      totalPrimes += (global['totalPrimes'] ?? 0).toDouble();
    }

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
            'Statistiques Globales',
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
                child: _buildGlobalMetric(
                  'Compagnies',
                  _compagnies.length.toString(),
                  Icons.business_rounded,
                  const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGlobalMetric(
                  'Agences',
                  totalAgences.toString(),
                  Icons.store_rounded,
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGlobalMetric(
                  'Contrats',
                  totalContrats.toString(),
                  Icons.description_rounded,
                  const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGlobalMetric(
                  'CA Total',
                  '${totalPrimes.toStringAsFixed(0)} DT',
                  Icons.monetization_on_rounded,
                  const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📊 Métrique globale
  Widget _buildGlobalMetric(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
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

  /// 🏢 Carte de compagnie
  Widget _buildCompagnieCard(Map<String, dynamic> compagnie, Map<String, dynamic> stats) {
    final global = stats['global'] as Map<String, dynamic>? ?? {};
    final agences = stats['agences'] as List<dynamic>? ?? [];

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
      child: Row(
        children: [
          // Informations de la compagnie
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  compagnie['nom'] ?? 'Compagnie inconnue',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  compagnie['adresse'] ?? 'Adresse non renseignée',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Code: ${compagnie['code'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          
          // Statistiques
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Agences',
                    agences.length.toString(),
                    Icons.store_rounded,
                    const Color(0xFF10B981),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Contrats',
                    (global['totalContrats'] ?? 0).toString(),
                    Icons.description_rounded,
                    const Color(0xFF3B82F6),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Agents',
                    (global['totalAgents'] ?? 0).toString(),
                    Icons.people_rounded,
                    const Color(0xFF8B5CF6),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'CA',
                    '${(global['totalPrimes'] ?? 0).toStringAsFixed(0)} DT',
                    Icons.monetization_on_rounded,
                    const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ),
          
          // Bouton d'action
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () => _navigateToCompagnieDetails(compagnie),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Voir Détails'),
          ),
        ],
      ),
    );
  }

  /// 📊 Item de statistique
  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
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

  /// 🔍 Naviguer vers les détails de la compagnie
  void _navigateToCompagnieDetails(Map<String, dynamic> compagnie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModernStatisticsScreen(
          compagnieData: compagnie,
        ),
      ),
    );
  }
}

