import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/admin_agence_agent_service.dart';

/// 🏪 Dashboard Admin Agence
class AdminAgenceDashboard extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  const AdminAgenceDashboard({
    Key? key,
    this.userData,
  }) : super(key: key);

  @override
  State<AdminAgenceDashboard> createState() => _AdminAgenceDashboardState();
}

class _AdminAgenceDashboardState extends State<AdminAgenceDashboard> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _agenceData;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _agents = [];
  List<Map<String, dynamic>> _constats = [];
  bool _isLoading = true;
  
  late TabController _tabController;

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
    await Future.wait([
      _loadAgenceData(),
      _loadAgents(),
      _loadConstats(),
      _loadStats(),
    ]);
    setState(() => _isLoading = false);
  }

  /// 🏪 Charger les données de l'agence
  Future<void> _loadAgenceData() async {
    try {
      final agenceId = widget.userData?['agenceId'];
      if (agenceId == null) return;

      final agenceDoc = await FirebaseFirestore.instance
          .collection('agences')
          .doc(agenceId)
          .get();

      if (agenceDoc.exists) {
        _agenceData = agenceDoc.data();
      }

      debugPrint('[ADMIN_AGENCE_DASHBOARD] ✅ Données agence chargées');
    } catch (e) {
      debugPrint('[ADMIN_AGENCE_DASHBOARD] ❌ Erreur agence: $e');
    }
  }

  /// 👥 Charger les agents de l'agence
  Future<void> _loadAgents() async {
    try {
      final agenceId = widget.userData?['agenceId'];
      if (agenceId == null) return;

      _agents = await AdminAgenceAgentService.getAgentsByAgence(agenceId);

      debugPrint('[ADMIN_AGENCE_DASHBOARD] ✅ ${_agents.length} agents chargés');
    } catch (e) {
      debugPrint('[ADMIN_AGENCE_DASHBOARD] ❌ Erreur agents: $e');
      _agents = [];
    }
  }

  /// 📋 Charger les constats de l'agence
  Future<void> _loadConstats() async {
    try {
      final agenceId = widget.userData?['agenceId'];
      if (agenceId == null) return;

      final constatsQuery = await FirebaseFirestore.instance
          .collection('constats')
          .where('agenceId', isEqualTo: agenceId)
          .orderBy('dateCreation', descending: true)
          .limit(50)
          .get();

      _constats = constatsQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      debugPrint('[ADMIN_AGENCE_DASHBOARD] ✅ ${_constats.length} constats chargés');
    } catch (e) {
      debugPrint('[ADMIN_AGENCE_DASHBOARD] ❌ Erreur constats: $e');
      _constats = [];
    }
  }

  /// 📊 Charger les statistiques
  Future<void> _loadStats() async {
    try {
      final agenceId = widget.userData?['agenceId'];
      if (agenceId == null) return;

      _stats = await AdminAgenceAgentService.getAgenceStats(agenceId);

      debugPrint('[ADMIN_AGENCE_DASHBOARD] ✅ Stats chargées');
    } catch (e) {
      debugPrint('[ADMIN_AGENCE_DASHBOARD] ❌ Erreur stats: $e');
      _stats = {};
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Dashboard Admin Agence'),
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
          _agenceData?['nom'] ?? widget.userData?['agenceNom'] ?? 'Dashboard Admin Agence',
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
            Tab(icon: Icon(Icons.dashboard_rounded), text: 'Vue Globale'),
            Tab(icon: Icon(Icons.people_rounded), text: 'Agents'),
            Tab(icon: Icon(Icons.description_rounded), text: 'Constats'),
            Tab(icon: Icon(Icons.analytics_rounded), text: 'Rapports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVueGlobale(),
          _buildGestionAgents(),
          _buildVueConstats(),
          _buildRapports(),
        ],
      ),
    );
  }

  /// 📊 Vue Globale - Onglet 1
  Widget _buildVueGlobale() {
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
          
          // Agents récents
          _buildRecentAgents(),
          const SizedBox(height: 24),
          
          // Constats récents
          _buildRecentConstats(),
        ],
      ),
    );
  }

  /// 👥 Gestion des Agents - Onglet 2
  Widget _buildGestionAgents() {
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
                'Gestion des Agents',
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
                  onPressed: () => _showAddAgentDialog(),
                  icon: const Icon(Icons.person_add_rounded),
                  label: const Text('Créer Nouvel Agent'),
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
          _buildAgentsFilters(),
          const SizedBox(height: 20),
          
          // Liste des agents
          _buildAgentsList(),
        ],
      ),
    );
  }

  /// 📋 Vue des Constats - Onglet 3
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

  /// 📊 Rapports - Onglet 4
  Widget _buildRapports() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rapports & Statistiques',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
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
            Icons.store_rounded,
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
                  _agenceData?['nom'] ?? widget.userData?['agenceNom'] ?? 'Votre agence',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  widget.userData?['compagnieNom'] ?? 'Compagnie',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
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
                'Agents',
                '${_stats['totalAgents'] ?? 0}',
                Icons.people_rounded,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Actifs',
                '${_stats['agentsActifs'] ?? 0}',
                Icons.check_circle_rounded,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Inactifs',
                '${_stats['agentsInactifs'] ?? 0}',
                Icons.block_rounded,
                Colors.red,
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
                'Constats',
                '${_stats['totalConstats'] ?? 0}',
                Icons.description_rounded,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'En attente',
                '${_stats['constatsEnAttente'] ?? 0}',
                Icons.pending_rounded,
                Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Validés',
                '${_stats['constatsValides'] ?? 0}',
                Icons.verified_rounded,
                Colors.teal,
              ),
            ),
          ],
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

  Widget _buildRecentAgents() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text('Agents récents - À implémenter'),
      ),
    );
  }

  Widget _buildRecentConstats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text('Constats récents - À implémenter'),
      ),
    );
  }

  // Méthodes utilitaires pour les constats
  Color _getStatutColor(String? statut) {
    switch (statut) {
      case 'en_attente': return Colors.orange;
      case 'en_cours': return Colors.blue;
      case 'valide': return Colors.green;
      case 'rejete': return Colors.red;
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

  String _getStatutText(String? statut) {
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
    return date.toString().substring(0, 10);
  }

  // Méthodes pour les autres sections
  Widget _buildAgentsFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text('Filtres des agents - À implémenter'),
    );
  }

  Widget _buildAgentsList() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text('Liste des agents - À implémenter'),
      ),
    );
  }

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

  Widget _buildConstatsList() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text('Liste des constats - À implémenter'),
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

  void _showAddAgentDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Création d\'agent - À implémenter'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications - À implémenter'),
        backgroundColor: Colors.blue,
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
}
