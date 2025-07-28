import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/dashboard_stats_widget.dart';
import '../widgets/agences_section_widget.dart';
import '../widgets/admins_agence_section_widget.dart';
import '../widgets/agents_section_widget.dart';
import '../widgets/experts_section_widget.dart';
import '../widgets/sinistres_section_widget.dart';
import '../widgets/parametres_section_widget.dart';
import '../../../../services/admin_compagnie_service.dart';

class AdminCompagnieDashboard extends StatefulWidget {
  const AdminCompagnieDashboard({Key? key}) : super(key: key);

  @override
  State<AdminCompagnieDashboard> createState() => _AdminCompagnieDashboardState();
}

class _AdminCompagnieDashboardState extends State<AdminCompagnieDashboard>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  Map<String, dynamic>? _compagnieData;
  Map<String, dynamic>? _adminData;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadAdminCompagnieData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 📊 Charger les données de l'Admin Compagnie
  Future<void> _loadAdminCompagnieData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer les données de l'admin
      final adminDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!adminDoc.exists) {
        throw Exception('Données admin non trouvées');
      }

      _adminData = adminDoc.data()!;
      final compagnieId = _adminData!['compagnieId'] as String?;

      if (compagnieId == null || compagnieId.isEmpty) {
        throw Exception('Compagnie non assignée à cet admin');
      }

      // Récupérer les données de la compagnie
      final compagnieDoc = await FirebaseFirestore.instance
          .collection('compagnies')
          .doc(compagnieId)
          .get();

      if (!compagnieDoc.exists) {
        throw Exception('Compagnie non trouvée');
      }

      _compagnieData = compagnieDoc.data()!;
      _compagnieData!['id'] = compagnieId;

      // Charger les statistiques
      await _loadStats();

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 📈 Charger les statistiques
  Future<void> _loadStats() async {
    try {
      final compagnieId = _compagnieData!['id'] as String;
      _stats = await AdminCompagnieService.getCompagnieStats(compagnieId);
    } catch (e) {
      debugPrint('Erreur chargement stats: $e');
      _stats = {};
    }
  }

  /// 🔄 Rafraîchir les données
  Future<void> _refresh() async {
    await _loadAdminCompagnieData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingWidget()
          : _error != null
              ? _buildErrorWidget()
              : _buildDashboardContent(),
    );
  }

  /// 📱 AppBar personnalisée
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.blue[800],
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Admin Compagnie',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (_compagnieData != null)
            Text(
              _compagnieData!['nom'] ?? 'Compagnie',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
            ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _refresh,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Actualiser',
        ),
        IconButton(
          onPressed: () => _showProfileMenu(context),
          icon: const Icon(Icons.account_circle_rounded),
          tooltip: 'Profil',
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(icon: Icon(Icons.dashboard_rounded), text: 'Accueil'),
          Tab(icon: Icon(Icons.business_rounded), text: 'Agences'),
          Tab(icon: Icon(Icons.admin_panel_settings_rounded), text: 'Admins'),
          Tab(icon: Icon(Icons.people_rounded), text: 'Agents'),
          Tab(icon: Icon(Icons.engineering_rounded), text: 'Experts'),
          Tab(icon: Icon(Icons.assignment_rounded), text: 'Sinistres'),
        ],
      ),
    );
  }

  /// 🔄 Widget de chargement
  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement du dashboard...'),
        ],
      ),
    );
  }

  /// ❌ Widget d'erreur
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(fontSize: 18, color: Colors.red[700]),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Erreur inconnue',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refresh,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  /// 📊 Contenu principal du dashboard
  Widget _buildDashboardContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        // Onglet Accueil - Statistiques
        DashboardStatsWidget(
          compagnieData: _compagnieData!,
          adminData: _adminData!,
          stats: _stats,
          onRefresh: _refresh,
        ),
        
        // Onglet Agences
        AgencesSectionWidget(
          compagnieId: _compagnieData!['id'],
          onRefresh: _refresh,
        ),
        
        // Onglet Admins Agence
        AdminsAgenceSectionWidget(
          compagnieId: _compagnieData!['id'],
          onRefresh: _refresh,
        ),
        
        // Onglet Agents
        AgentsSectionWidget(
          compagnieId: _compagnieData!['id'],
          onRefresh: _refresh,
        ),
        
        // Onglet Experts
        ExpertsSectionWidget(
          compagnieId: _compagnieData!['id'],
          onRefresh: _refresh,
        ),
        
        // Onglet Sinistres
        SinistresSectionWidget(
          compagnieId: _compagnieData!['id'],
          onRefresh: _refresh,
        ),
      ],
    );
  }

  /// 👤 Menu profil
  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: const Text('Mon Profil'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Naviguer vers profil
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_rounded),
              title: const Text('Paramètres Compagnie'),
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(5); // Onglet paramètres
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Déconnexion'),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
