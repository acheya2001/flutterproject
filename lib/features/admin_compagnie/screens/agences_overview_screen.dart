import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/admin_compagnie_stats_service.dart';
import '../widgets/real_time_sync_indicator.dart';

/// 🏢 Vue d'ensemble des agences pour Admin Compagnie
class AgencesOverviewScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const AgencesOverviewScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<AgencesOverviewScreen> createState() => _AgencesOverviewScreenState();
}

class _AgencesOverviewScreenState extends State<AgencesOverviewScreen> {
  List<Map<String, dynamic>> _agences = [];
  Map<String, Map<String, dynamic>> _agencesStats = {};
  bool _isLoading = true;
  String _searchQuery = '';
  DateTime? _lastUpdate;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadAgencesData();
    });
  }

  /// 📊 Charger toutes les données des agences
  Future<void> _loadAgencesData() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('[ADMIN_COMPAGNIE] 🏢 Chargement agences pour compagnie: ${widget.userData['compagnieId']}');

      // Récupérer toutes les agences de la compagnie
      final agencesQuery = await FirebaseFirestore.instance
          .collection('agences')
          .where('compagnieId', isEqualTo: widget.userData['compagnieId'])
          .get();

      List<Map<String, dynamic>> agences = [];
      Map<String, Map<String, dynamic>> stats = {};

      for (var doc in agencesQuery.docs) {
        final agenceData = doc.data();
        agenceData['id'] = doc.id;
        agences.add(agenceData);

        debugPrint('[ADMIN_COMPAGNIE] 🏢 Agence trouvée: ${agenceData['nom']} (ID: ${doc.id})');

        // Récupérer les statistiques de chaque agence
        final agenceStats = await _getAgenceStatistics(doc.id);
        stats[doc.id] = agenceStats;

        debugPrint('[ADMIN_COMPAGNIE] 📋 Agence: ${agenceData['nom']} - ${agenceStats['totalAgents']} agents');
      }

      if (mounted) setState(() {
        _agences = agences;
        _agencesStats = stats;
        _isLoading = false;
        _lastUpdate = DateTime.now();
        _isConnected = true;
      });

      debugPrint('[ADMIN_COMPAGNIE] ✅ ${agences.length} agences chargées');

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE] ❌ Erreur chargement agences: $e');
      setState(() => _isLoading = false);
    }
  }

  /// 📊 Récupérer les statistiques d'une agence
  Future<Map<String, dynamic>> _getAgenceStatistics(String agenceId) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE] 🔍 Recherche agents pour agenceId: $agenceId');

      // Compter les agents de l'agence
      final agentsQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('agenceId', isEqualTo: agenceId)
          .get();

      debugPrint('[ADMIN_COMPAGNIE] 📊 Agents trouvés: ${agentsQuery.docs.length}');

      // Afficher les détails de chaque agent trouvé
      for (var doc in agentsQuery.docs) {
        final data = doc.data();
        debugPrint('[ADMIN_COMPAGNIE] 👤 Agent: ${data['email']} - AgenceId: ${data['agenceId']} - CompagnieId: ${data['compagnieId']}');
      }

      final totalAgents = agentsQuery.docs.length;
      final activeAgents = agentsQuery.docs.where((doc) => doc.data()['isActive'] == true).length;

      // Vérification alternative : chercher par compagnieId
      final alternativeQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('compagnieId', isEqualTo: widget.userData['compagnieId'])
          .get();

      debugPrint('[ADMIN_COMPAGNIE] 🔍 Agents par compagnieId: ${alternativeQuery.docs.length}');

      // Compter les admins agence
      final adminsQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin_agence')
          .where('agenceId', isEqualTo: agenceId)
          .get();

      debugPrint('[ADMIN_COMPAGNIE] 📈 Stats finales pour agence $agenceId: $totalAgents agents, ${adminsQuery.docs.length} admins');

      return {
        'totalAgents': totalAgents,
        'activeAgents': activeAgents,
        'inactiveAgents': totalAgents - activeAgents,
        'totalAdmins': adminsQuery.docs.length,
        'lastUpdate': DateTime.now(),
      };
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE] ❌ Erreur stats agence $agenceId: $e');
      return {
        'totalAgents': 0,
        'activeAgents': 0,
        'inactiveAgents': 0,
        'totalAdmins': 0,
        'lastUpdate': DateTime.now(),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Indicateur de synchronisation
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                RealTimeSyncIndicator(
                  isConnected: _isConnected,
                  lastUpdate: _lastUpdate,
                  onRefresh: _loadAgencesData,
                ),
                const Spacer(),
                Text(
                  '${_agences.length} agences',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Header avec statistiques globales
          _buildGlobalStatsHeader(),

          // Barre de recherche
          _buildSearchBar(),

          // Liste des agences
          Expanded(
            child: _isLoading ? _buildLoadingScreen() : _buildAgencesList(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "diagnostic",
            onPressed: _runDiagnostic,
            backgroundColor: Colors.orange,
            child: const Icon(Icons.bug_report_rounded),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: "refresh",
            onPressed: _loadAgencesData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Actualiser'),
            backgroundColor: const Color(0xFF667EEA),
          ),
        ],
      ),
    );
  }

  /// 📊 Header avec statistiques globales
  Widget _buildGlobalStatsHeader() {
    final totalAgences = _agences.length;
    final totalAgents = _agencesStats.values.fold(0, (sum, stats) => sum + (stats['totalAgents'] as int));
    final totalActiveAgents = _agencesStats.values.fold(0, (sum, stats) => sum + (stats['activeAgents'] as int));
    final totalAdmins = _agencesStats.values.fold(0, (sum, stats) => sum + (stats['totalAdmins'] as int));

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vue d\'ensemble des Agences',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildGlobalStatCard('Agences', totalAgences.toString(), Icons.business_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _buildGlobalStatCard('Total Agents', totalAgents.toString(), Icons.people_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _buildGlobalStatCard('Agents Actifs', totalActiveAgents.toString(), Icons.person_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _buildGlobalStatCard('Admins', totalAdmins.toString(), Icons.admin_panel_settings_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  /// 📈 Carte de statistique globale
  Widget _buildGlobalStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 🔍 Barre de recherche
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: const InputDecoration(
          hintText: 'Rechercher une agence...',
          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF667EEA)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  /// 🔄 Écran de chargement
  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Chargement des agences...'),
        ],
      ),
    );
  }

  /// 📋 Liste des agences
  Widget _buildAgencesList() {
    final filteredAgences = _agences.where((agence) {
      if (_searchQuery.isEmpty) return true;
      return agence['nom'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
             agence['code'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (filteredAgences.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'Aucune agence trouvée' : 'Aucun résultat pour "$_searchQuery"',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filteredAgences.length,
      itemBuilder: (context, index) {
        final agence = filteredAgences[index];
        final stats = _agencesStats[agence['id']] ?? {};
        return _buildAgenceCard(agence, stats);
      },
    );
  }

  /// 🏢 Carte d'agence avec statistiques
  Widget _buildAgenceCard(Map<String, dynamic> agence, Map<String, dynamic> stats) {
    final totalAgents = stats['totalAgents'] ?? 0;
    final activeAgents = stats['activeAgents'] ?? 0;
    final totalAdmins = stats['totalAdmins'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête de l'agence
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667EEA).withOpacity(0.1),
                  const Color(0xFF764BA2).withOpacity(0.1),
                ],
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business_rounded,
                    color: Color(0xFF667EEA),
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Code: ${agence['code'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (agence['adresse'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          agence['adresse'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleAgenceAction(value, agence),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Détails'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'agents',
                      child: Row(
                        children: [
                          Icon(Icons.people_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Voir agents'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          Icon(Icons.refresh_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Actualiser'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Statistiques de l'agence
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Total Agents',
                        totalAgents.toString(),
                        Icons.people_rounded,
                        const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        'Agents Actifs',
                        activeAgents.toString(),
                        Icons.person_rounded,
                        const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        'Admins',
                        totalAdmins.toString(),
                        Icons.admin_panel_settings_rounded,
                        const Color(0xFF8B5CF6),
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

  /// 📊 Item de statistique
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 🎯 Gérer les actions sur une agence
  void _handleAgenceAction(String action, Map<String, dynamic> agence) {
    switch (action) {
      case 'details':
        _showAgenceDetails(agence);
        break;
      case 'agents':
        _showAgenceAgents(agence);
        break;
      case 'refresh':
        _refreshAgenceStats(agence['id']);
        break;
    }
  }

  /// 📋 Afficher les détails d'une agence
  void _showAgenceDetails(Map<String, dynamic> agence) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.business_rounded, color: Color(0xFF667EEA)),
            const SizedBox(width: 12),
            Text(agence['nom'] ?? 'Agence'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Code', agence['code']),
            _buildDetailRow('Adresse', agence['adresse']),
            _buildDetailRow('Téléphone', agence['telephone']),
            _buildDetailRow('Email', agence['email']),
            _buildDetailRow('Créée le', agence['createdAt']?.toDate().toString().split(' ')[0]),
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

  /// 📄 Ligne de détail
  Widget _buildDetailRow(String label, dynamic value) {
    if (value == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value.toString()),
          ),
        ],
      ),
    );
  }

  /// 👥 Afficher les agents d'une agence
  void _showAgenceAgents(Map<String, dynamic> agence) {
    // TODO: Implémenter la vue des agents de l'agence
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Agents de ${agence['nom']} - À implémenter'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// 🔄 Actualiser les stats d'une agence
  Future<void> _refreshAgenceStats(String agenceId) async {
    try {
      final newStats = await _getAgenceStatistics(agenceId);
      if (mounted) setState(() {
        _agencesStats[agenceId] = newStats;
        _lastUpdate = DateTime.now();
        _isConnected = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Statistiques actualisées'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) setState(() {
        _isConnected = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🐛 Diagnostic complet pour identifier le problème
  Future<void> _runDiagnostic() async {
    debugPrint('[ADMIN_COMPAGNIE] 🐛 === DIAGNOSTIC COMPLET ===');
    debugPrint('[ADMIN_COMPAGNIE] 📋 CompagnieId: ${widget.userData['compagnieId']}');

    try {
      // 1. Vérifier toutes les agences de la compagnie
      final agencesQuery = await FirebaseFirestore.instance
          .collection('agences')
          .where('compagnieId', isEqualTo: widget.userData['compagnieId'])
          .get();

      debugPrint('[ADMIN_COMPAGNIE] 🏢 Agences trouvées: ${agencesQuery.docs.length}');

      for (var doc in agencesQuery.docs) {
        final data = doc.data();
        debugPrint('[ADMIN_COMPAGNIE] 🏢 Agence: ${data['nom']} (ID: ${doc.id})');
      }

      // 2. Vérifier tous les agents de la compagnie
      final allAgentsQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('compagnieId', isEqualTo: widget.userData['compagnieId'])
          .get();

      debugPrint('[ADMIN_COMPAGNIE] 👥 Total agents dans la compagnie: ${allAgentsQuery.docs.length}');

      for (var doc in allAgentsQuery.docs) {
        final data = doc.data();
        debugPrint('[ADMIN_COMPAGNIE] 👤 Agent: ${data['email']} - AgenceId: ${data['agenceId']} - CompagnieId: ${data['compagnieId']}');
      }

      // 3. Vérifier les agents par agence
      for (var agenceDoc in agencesQuery.docs) {
        final agentsInAgence = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'agent')
            .where('agenceId', isEqualTo: agenceDoc.id)
            .get();

        debugPrint('[ADMIN_COMPAGNIE] 🔍 Agence ${agenceDoc.data()['nom']} (${agenceDoc.id}): ${agentsInAgence.docs.length} agents');
      }

      // 4. Afficher un résumé
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🐛 Diagnostic terminé: ${agencesQuery.docs.length} agences, ${allAgentsQuery.docs.length} agents total'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE] ❌ Erreur diagnostic: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur diagnostic: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

