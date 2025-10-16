import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../../../services/admin_compagnie_agence_service.dart';
import 'admin_agence_credentials_display.dart';
import 'create_agence_only_screen.dart';
import 'create_admin_agence_screen.dart';
import 'unified_agences_management_screen.dart';
import 'agents_by_agence_screen.dart';
import 'compagnies_overview_screen.dart';
import 'modern_statistics_screen.dart';

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

class _AdminCompagnieDashboardState extends State<AdminCompagnieDashboard>with SingleTickerProviderStateMixin  {
  Map<String, dynamic>? _compagnieData;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _agences = [];
  List<Map<String, dynamic>> _constats = [];
  List<Map<String, dynamic>> _experts = [];
  List<Map<String, dynamic>> _adminsAgence = [];
  List<Map<String, dynamic>> _agents = [];
  bool _isLoading = true;

  late TabController _tabController;
  int _selectedIndex = 0;

  // Variables pour le formulaire de modification du profil
  bool _isEditMode = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _emailController;
  late TextEditingController _telephoneController;
  late TextEditingController _adresseController;

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tabController = TabController(length: 5, vsync: this);
      _loadAllData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (_isEditMode) {
      _nomController.dispose();
      _emailController.dispose();
      _telephoneController.dispose();
      _adresseController.dispose();
    }
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
      _loadAgents(),
    ]);

    setState(() => _isLoading = false);
  }

  /// 🔄 Rafraîchir les données
  Future<void> _refreshData() async {
    await _loadAllData();
  }

  /// 📊 Obtenir le nombre d'agents pour une agence
  int _getAgentsCountForAgence(String agenceId) {
    return _agents.where((agent) => agent['agenceId'] == agenceId).length;
  }

  /// 📊 Obtenir le nombre de constats pour une agence
  int _getConstatsCountForAgence(String agenceId) {
    return _constats.where((constat) => constat['agenceId'] == agenceId).length;
  }

  /// 📊 Obtenir le nombre d'experts pour une agence
  int _getExpertsCountForAgence(String agenceId) {
    return _experts.where((expert) => expert['agenceId'] == agenceId).length;
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
          _compagnieData!['id'] = compagnieDoc.id; // Ajouter l'ID du document
          debugPrint('[ADMIN_COMPAGNIE_DASHBOARD] 🔍 CompagnieData chargé avec ID: ${compagnieDoc.id}');
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
      int agences = 0;
      int agents = 0;
      int experts = 0;
      int contrats = 0;
      int sinistres = 0;
      int sinistresEnAttente = 0;
      int sinistresValides = 0;

      if (compagnieId != null) {
        debugPrint('[ADMIN_COMPAGNIE_DASHBOARD] 🔍 Recherche pour compagnieId: $compagnieId');

        // Compter les agences (essayer les deux structures)
        var agencesQuery = await FirebaseFirestore.instance
            .collection('agences')
            .where('compagnieId', isEqualTo: compagnieId)
            .where('isActive', isEqualTo: true)
            .get();

        if (agencesQuery.docs.isEmpty) {
          // Essayer avec la sous-collection
          agencesQuery = await FirebaseFirestore.instance
              .collection('compagnies_assurance')
              .doc(compagnieId)
              .collection('agences')
              .where('isActive', isEqualTo: true)
              .get();
          debugPrint('[ADMIN_COMPAGNIE_DASHBOARD] 🔍 Agences via sous-collection: ${agencesQuery.docs.length}');
        } else {
          debugPrint('[ADMIN_COMPAGNIE_DASHBOARD] 🔍 Agences via collection principale: ${agencesQuery.docs.length}');
        }

        agences = agencesQuery.docs.length;

        // Compter les agents
        final agentsQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('role', whereIn: ['agent', 'agent_agence', 'agent_assurance'])
            .where('compagnieId', isEqualTo: compagnieId)
            .where('isActive', isEqualTo: true)
            .get();
        agents = agentsQuery.docs.length;

        // Compter les experts
        final expertsQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('role', whereIn: ['expert', 'expert_auto', 'expert_automobile'])
            .where('compagnieId', isEqualTo: compagnieId)
            .where('isActive', isEqualTo: true)
            .get();
        experts = expertsQuery.docs.length;

        // Compter les contrats (essayer plusieurs collections)
        var contratsQuery = await FirebaseFirestore.instance
            .collection('contrats')
            .where('compagnieId', isEqualTo: compagnieId)
            .get();

        if (contratsQuery.docs.isEmpty) {
          // Essayer avec contrats_assurance
          contratsQuery = await FirebaseFirestore.instance
              .collection('contrats_assurance')
              .where('compagnieId', isEqualTo: compagnieId)
              .get();
          debugPrint('[ADMIN_COMPAGNIE_DASHBOARD] 🔍 Contrats via contrats_assurance: ${contratsQuery.docs.length}');
        } else {
          debugPrint('[ADMIN_COMPAGNIE_DASHBOARD] 🔍 Contrats via contrats: ${contratsQuery.docs.length}');
        }
        contrats = contratsQuery.docs.length;

        // Compter les sinistres
        final sinistresQuery = await FirebaseFirestore.instance
            .collection('sinistres')
            .where('compagnieId', isEqualTo: compagnieId)
            .get();
        sinistres = sinistresQuery.docs.length;
        debugPrint('[ADMIN_COMPAGNIE_DASHBOARD] 🔍 Sinistres trouvés: $sinistres');

        // Compter les sinistres par statut
        for (final doc in sinistresQuery.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final statut = data['status'] ?? data['statut'] ?? '';

          if (statut == 'en_attente' || statut == 'nouveau' || statut == 'ouvert') {
            sinistresEnAttente++;
          } else if (statut == 'valide' || statut == 'traite' || statut == 'clos') {
            sinistresValides++;
          }
        }
      }

      _stats = {
        'agences': agences,
        'agents': agents,
        'experts': experts,
        'contrats': contrats,
        'sinistres': sinistres,
        'sinistresEnAttente': sinistresEnAttente,
        'sinistresValides': sinistresValides,
      };

      debugPrint('[ADMIN_COMPAGNIE_DASHBOARD] 📊 Stats chargées: $_stats');
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_DASHBOARD] ❌ Erreur stats: $e');
      _stats = {
        'agences': 0,
        'agents': 0,
        'experts': 0,
        'contrats': 0,
        'sinistres': 0,
        'sinistresEnAttente': 0,
        'sinistresValides': 0,
      };
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

      // Essayer plusieurs collections possibles pour les constats/sinistres
      var constatsQuery = await FirebaseFirestore.instance
          .collection('sinistres')
          .where('compagnieId', isEqualTo: compagnieId)
          .limit(50)
          .get();

      if (constatsQuery.docs.isEmpty) {
        // Essayer avec la collection constats
        constatsQuery = await FirebaseFirestore.instance
            .collection('constats')
            .where('compagnieId', isEqualTo: compagnieId)
            .limit(50)
            .get();
        debugPrint('[ADMIN_COMPAGNIE_DASHBOARD] 🔍 Constats via collection constats: ${constatsQuery.docs.length}');
      } else {
        debugPrint('[ADMIN_COMPAGNIE_DASHBOARD] 🔍 Constats via collection sinistres: ${constatsQuery.docs.length}');
      }

      _constats = constatsQuery.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      debugPrint('[ADMIN_COMPAGNIE_DASHBOARD] ✅ ${_constats.length} constats/sinistres chargés');
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

      // Essayer plusieurs stratégies pour trouver les experts
      var expertsQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['expert', 'expert_auto', 'expert_automobile'])
          .where('compagnieId', isEqualTo: compagnieId)
          .where('isActive', isEqualTo: true)
          .get();

      if (expertsQuery.docs.isEmpty) {
        // Essayer avec la collection experts et compagniesAssociees
        expertsQuery = await FirebaseFirestore.instance
            .collection('experts')
            .where('compagniesAssociees', arrayContains: compagnieId)
            .get();
        debugPrint('[ADMIN_COMPAGNIE_DASHBOARD] 🔍 Experts via collection experts: ${expertsQuery.docs.length}');
      } else {
        debugPrint('[ADMIN_COMPAGNIE_DASHBOARD] 🔍 Experts via collection users: ${expertsQuery.docs.length}');
      }

      _experts = expertsQuery.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
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

  /// 👥 Charger les agents de la compagnie
  Future<void> _loadAgents() async {
    try {
      final compagnieId = widget.userData?['compagnieId'];
      if (compagnieId == null) return;

      final agentsQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('compagnieId', isEqualTo: compagnieId)
          .where('isActive', isEqualTo: true)
          .get();

      _agents = agentsQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      debugPrint('[ADMIN_COMPAGNIE_DASHBOARD] ✅ ${_agents.length} agents chargés');
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_DASHBOARD] ❌ Erreur agents: $e');
      _agents = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Dashboard Admin Compagnie'),
          backgroundColor: const Color(0xFF3B82F6),
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
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
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
            Tab(icon: Icon(Icons.analytics_rounded), text: 'Ma Compagnie'),
            Tab(icon: Icon(Icons.account_circle_rounded), text: 'Profil'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTableauDeBord(),
          _buildUnifiedGestionAgences(),
          _buildGestionAdminsAgences(),
          _buildStatistiquesCompagnies(),
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

  /// 🏢 Gestion des Agences - Onglet 2 (Interface originale)
  Widget _buildUnifiedGestionAgences() {
    return _buildGestionAgences();
  }

  /// 🏢 Gestion des Agences - Interface Simple Originale
  Widget _buildGestionAgences() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.business, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Agences - testini',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF4CAF50),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _loadAgences(),
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showCreateAgenceOnlyScreen(),
            tooltip: 'Ajouter',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF4CAF50)),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),

          // Statistiques en cartes
          _buildOriginalStatsCards(),

          // Liste des agences
          Expanded(
            child: _buildOriginalAgencesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateAgenceOnlyScreen(),
        backgroundColor: Color(0xFF4CAF50),
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'Nouvelle Agence',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// 📊 Statistiques en cartes (Interface originale)
  Widget _buildOriginalStatsCards() {
    final totalAgences = _agences.length;
    final agencesActives = _agences.where((a) => a['isActive'] == true).length;

    // Calculer les agences avec admin en vérifiant dans la liste des admins agence
    final agencesAvecAdmin = _agences.where((agence) {
      final agenceId = agence['id'];
      return _adminsAgence.any((admin) =>
          admin['agenceId'] == agenceId && admin['isActive'] == true);
    }).length;

    final agencesSansAdmin = totalAgences - agencesAvecAdmin;

    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildOriginalStatCard(
              'Total',
              totalAgences.toString(),
              Icons.business,
              Color(0xFF2196F3),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _buildOriginalStatCard(
              'Actives',
              agencesActives.toString(),
              Icons.check_circle,
              Color(0xFF4CAF50),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _buildOriginalStatCard(
              'Avec Admin',
              agencesAvecAdmin.toString(),
              Icons.person,
              Color(0xFFFF9800),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _buildOriginalStatCard(
              'Sans Admin',
              agencesSansAdmin.toString(),
              Icons.person_off,
              Color(0xFFF44336),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 📋 Liste des agences (Interface originale)
  Widget _buildOriginalAgencesList() {
    if (_agences.isEmpty) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.business_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                'Aucune agence trouvée',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Commencez par créer une nouvelle agence',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _agences.length,
        itemBuilder: (context, index) {
          final agence = _agences[index];
          return _buildOriginalAgenceItem(agence);
        },
      ),
    );
  }

  Widget _buildOriginalAgenceItem(Map<String, dynamic> agence) {
    // Vérifier si l'agence a un admin en cherchant dans la liste des admins agence
    final agenceId = agence['id'];
    final adminAgence = _adminsAgence.firstWhere(
      (admin) => admin['agenceId'] == agenceId && admin['isActive'] == true,
      orElse: () => {},
    );
    final hasAdmin = adminAgence.isNotEmpty;
    final isActive = agence['isActive'] == true;

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            spreadRadius: 0,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec admin agence - Design premium
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: hasAdmin
                      ? [Color(0xFF4CAF50), Color(0xFF45A049)]
                      : [Color(0xFF9E9E9E), Color(0xFF757575)],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      hasAdmin ? Icons.admin_panel_settings : Icons.person_off,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasAdmin ? 'Admin Agence' : 'Aucun Admin',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (hasAdmin) ...[
                          SizedBox(height: 6),
                          Text(
                            '${adminAgence['prenom']} ${adminAgence['nom']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            adminAgence['email'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ] else ...[
                          SizedBox(height: 4),
                          Text(
                            'Aucun administrateur assigné',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Badge de statut
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isActive ? 'Actif' : 'Inactif',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Informations de l'agence - Design moderne
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom et localisation
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              agence['nom'] ?? 'Agence sans nom',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: Color(0xFF666666),
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${agence['gouvernorat']} • ${agence['adresse']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF666666),
                                      fontWeight: FontWeight.w500,
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

                  SizedBox(height: 24),

                  // Statistiques - Design premium
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildModernStatItem('${_getAgentsCountForAgence(agence['id'])}', 'Agents', Icons.people_outline, Color(0xFF3B82F6)),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Color(0xFFE2E8F0),
                        ),
                        Expanded(
                          child: _buildModernStatItem('${_getConstatsCountForAgence(agence['id'])}', 'Constats', Icons.description_outlined, Color(0xFFEC4899)),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Color(0xFFE2E8F0),
                        ),
                        Expanded(
                          child: _buildModernStatItem('${_getExpertsCountForAgence(agence['id'])}', 'Experts', Icons.engineering_outlined, Color(0xFFF59E0B)),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Boutons d'action - Design premium
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernActionButton(
                          onPressed: () => _showAgenceDetails(agence),
                          icon: Icons.visibility_outlined,
                          label: 'Voir',
                          isPrimary: false,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildModernActionButton(
                          onPressed: () => _showAgentsDialog(agence),
                          icon: Icons.people_outline,
                          label: 'Agents',
                          isPrimary: false,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildModernActionButton(
                          onPressed: () => hasAdmin
                              ? _showManageAgenceOptions(agence, adminAgence)
                              : _showCreateAdminAgenceDialog(agence),
                          icon: Icons.settings_outlined,
                          label: 'Gérer',
                          isPrimary: true,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📊 Widget moderne pour afficher une statistique d'agence
  Widget _buildModernStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  /// 🎨 Bouton d'action moderne
  Widget _buildModernActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
    required Color color,
  }) {
    return Container(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 18,
          color: isPrimary ? Colors.white : color,
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isPrimary ? Colors.white : color,
            letterSpacing: 0.3,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? color : color.withOpacity(0.1),
          foregroundColor: isPrimary ? Colors.white : color,
          elevation: isPrimary ? 2 : 0,
          shadowColor: color.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isPrimary ? Colors.transparent : color.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  /// ⚙️ Afficher les options de gestion d'agence - Design moderne
  void _showManageAgenceOptions(Map<String, dynamic> agence, Map<String, dynamic> adminAgence) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Gérer l\'agence',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    agence['nom'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Options
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildModernOptionTile(
                    icon: Icons.edit_outlined,
                    title: 'Modifier l\'agence',
                    subtitle: 'Modifier les informations de l\'agence',
                    color: Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.pop(context);
                      _showEditAgenceDialog(agence);
                    },
                  ),
                  SizedBox(height: 12),
                  _buildModernOptionTile(
                    icon: Icons.person_remove_outlined,
                    title: 'Retirer l\'admin',
                    subtitle: 'Supprimer l\'administrateur de cette agence',
                    color: Color(0xFFEF4444),
                    onTap: () {
                      Navigator.pop(context);
                      _removeAdminAgence(agence);
                    },
                  ),
                  SizedBox(height: 12),
                  _buildModernOptionTile(
                    icon: Icons.lock_reset_outlined,
                    title: 'Réinitialiser le mot de passe',
                    subtitle: 'Générer un nouveau mot de passe pour l\'admin',
                    color: Color(0xFF6366F1),
                    onTap: () {
                      Navigator.pop(context);
                      _resetAdminPassword(adminAgence);
                    },
                  ),
                  SizedBox(height: 12),
                  _buildModernOptionTile(
                    icon: agence['isActive'] == true ? Icons.block_outlined : Icons.check_circle_outlined,
                    title: agence['isActive'] == true ? 'Désactiver l\'agence' : 'Réactiver l\'agence',
                    subtitle: agence['isActive'] == true
                        ? 'Suspendre temporairement cette agence'
                        : 'Remettre cette agence en service',
                    color: agence['isActive'] == true ? Color(0xFFEF4444) : Color(0xFF3B82F6),
                    onTap: () {
                      Navigator.pop(context);
                      _toggleAgenceStatus(agence, !(agence['isActive'] == true));
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Cancel button
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Annuler',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🎨 Option tile moderne pour le modal
  Widget _buildModernOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Color(0xFF9CA3AF),
        ),
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
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
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
                '${_stats['agences'] ?? 0}',
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
                'Experts',
                '${_stats['experts'] ?? 0}',
                Icons.engineering_rounded,
                Colors.purple,
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
                'Contrats',
                '${_stats['contrats'] ?? 0}',
                Icons.description_rounded,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Sinistres',
                '${_stats['sinistres'] ?? 0}',
                Icons.car_crash_rounded,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'En cours',
                '${_stats['sinistresEnAttente'] ?? 0}',
                Icons.pending_rounded,
                Colors.amber,
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
    // Calculer les statistiques par mois
    final Map<String, int> sinistresParMois = {};
    final Map<String, int> contratsParMois = {};

    // Analyser les constats/sinistres par mois
    for (final constat in _constats) {
      final dateCreation = constat['dateCreation'];
      if (dateCreation != null) {
        try {
          final date = dateCreation is Timestamp
              ? dateCreation.toDate()
              : DateTime.parse(dateCreation.toString());
          final moisKey = '${date.month.toString().padLeft(2, '0')}/${date.year}';
          sinistresParMois[moisKey] = (sinistresParMois[moisKey] ?? 0) + 1;
        } catch (e) {
          // Ignorer les erreurs de date
        }
      }
    }

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
          Row(
            children: [
              Icon(Icons.trending_up_rounded, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Évolution des sinistres',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (sinistresParMois.isEmpty)
            Container(
              height: 120,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart_rounded, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Aucune donnée disponible',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              height: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: sinistresParMois.entries.take(6).map((entry) {
                  final maxValue = sinistresParMois.values.reduce((a, b) => a > b ? a : b);
                  final height = (entry.value / maxValue * 80).clamp(10.0, 80.0);

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${entry.value}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 30,
                        height: height,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.key,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  /// 🏆 Top 5 agences
  Widget _buildTopAgences() {
    // Si pas d'agences, afficher les agences disponibles
    if (_agences.isEmpty) {
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
            Row(
              children: [
                Icon(Icons.business_rounded, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Agences disponibles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Center(
              child: Column(
                children: [
                  Icon(Icons.domain_disabled_rounded, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Aucune agence disponible',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Calculer le nombre de constats par agence
    final agencesStats = <String, int>{};
    for (final constat in _constats) {
      final agenceId = constat['agenceId'] as String?;
      if (agenceId != null) {
        agencesStats[agenceId] = (agencesStats[agenceId] ?? 0) + 1;
      }
    }

    // Si pas de constats, afficher simplement les agences
    List<Map<String, dynamic>> agencesToShow;
    if (agencesStats.isEmpty) {
      agencesToShow = _agences.take(5).map((agence) => {
        'agence': agence,
        'constats': 0,
      }).toList();
    } else {
      // Trier par nombre de constats et prendre le top 5
      final sortedAgences = agencesStats.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      agencesToShow = sortedAgences.take(5).map((entry) {
        final agence = _agences.firstWhere(
          (a) => a['id'] == entry.key,
          orElse: () => {'nom': 'Agence inconnue', 'id': entry.key},
        );
        return {
          'agence': agence,
          'constats': entry.value,
        };
      }).toList();
    }

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
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  agencesStats.isEmpty ? 'Agences de la compagnie' : 'Top 5 Agences',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...agencesToShow.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            final agence = data['agence'] as Map<String, dynamic>;
            final constats = data['constats'] as int;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getTopColor(index),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          agence['nom'] ?? 'Agence inconnue',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (agence['adresse'] != null)
                          Text(
                            agence['adresse'],
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: constats > 0 ? Colors.blue.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      constats > 0 ? '$constats constats' : 'Aucun constat',
                      style: TextStyle(
                        color: constats > 0 ? Colors.blue.shade700 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
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
    // Prendre les 5 derniers constats/sinistres
    final recentConstats = _constats.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history_rounded, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Activités récentes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
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
          child: recentConstats.isEmpty
              ? const Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox_rounded, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Aucune activité récente',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: recentConstats.map((constat) {
                    final statut = constat['status'] ?? constat['statut'] ?? 'inconnu';
                    final dateCreation = constat['dateCreation'];
                    String dateStr = 'Date inconnue';

                    if (dateCreation != null) {
                      try {
                        final date = dateCreation is Timestamp
                            ? dateCreation.toDate()
                            : DateTime.parse(dateCreation.toString());
                        dateStr = '${date.day}/${date.month}/${date.year}';
                      } catch (e) {
                        // Garder la valeur par défaut
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getStatutColor(statut),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sinistre ${constat['id']?.toString().substring(0, 8) ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Statut: ${statut.toUpperCase()}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            dateStr,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
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
                Text('👥 ${_getAgentsCountForAgence(agence['id'])} agents'),
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
      case 'reset_admin':
        _resetAdminAgence(agence);
        break;
      case 'remove_admin':
        _removeAdminAgence(agence);
        break;
    }
  }

  /// 🔄 Reset admin agence
  void _resetAdminAgence(Map<String, dynamic> agence) {
    final agenceId = agence['id'];
    final admin = _adminsAgence.firstWhere(
      (admin) => admin['agenceId'] == agenceId && admin['isActive'] == true,
      orElse: () => {},
    );

    if (admin.isNotEmpty) {
      _showResetPasswordDialog(admin);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aucun admin trouvé pour cette agence'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🔐 Réinitialiser le mot de passe d'un admin agence
  void _resetAdminPassword(Map<String, dynamic> adminAgence) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.lock_reset_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Réinitialiser le mot de passe',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${adminAgence['prenom']} ${adminAgence['nom']}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Container(
                margin: EdgeInsets.fromLTRB(24, 0, 24, 24),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFF6366F1).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFF6366F1)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Un nouveau mot de passe sera généré automatiquement et envoyé par email à l\'administrateur.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4338CA),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              'Annuler',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _performPasswordReset(adminAgence),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              'Réinitialiser',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
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
        ),
      ),
    );
  }



  /// 🔐 Générer un mot de passe aléatoire
  String _generateRandomPassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@#\$%&*';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(12, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  /// 📧 Envoyer l'email de réinitialisation
  Future<void> _sendPasswordResetEmail(Map<String, dynamic> adminAgence, String newPassword) async {
    try {
      final emailData = {
        'to': adminAgence['email'],
        'subject': 'Réinitialisation de votre mot de passe - Constat Tunisie',
        'html': '''
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <div style="background: linear-gradient(135deg, #6366F1, #4F46E5); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
              <h1 style="color: white; margin: 0;">🔐 Mot de passe réinitialisé</h1>
            </div>

            <div style="background: #f8fafc; padding: 30px; border-radius: 0 0 10px 10px;">
              <p style="font-size: 16px; color: #374151; margin-bottom: 20px;">
                Bonjour <strong>${adminAgence['prenom']} ${adminAgence['nom']}</strong>,
              </p>

              <p style="font-size: 16px; color: #374151; margin-bottom: 20px;">
                Votre mot de passe a été réinitialisé par l'administrateur de la compagnie.
              </p>

              <div style="background: white; padding: 20px; border-radius: 8px; border-left: 4px solid #6366F1; margin: 20px 0;">
                <p style="margin: 0; font-size: 14px; color: #6B7280;">Votre nouveau mot de passe :</p>
                <p style="font-family: monospace; font-size: 18px; font-weight: bold; color: #1F2937; margin: 10px 0; padding: 10px; background: #F3F4F6; border-radius: 4px;">
                  $newPassword
                </p>
              </div>

              <div style="background: #FEF3C7; border: 1px solid #F59E0B; border-radius: 8px; padding: 15px; margin: 20px 0;">
                <p style="margin: 0; font-size: 14px; color: #92400E;">
                  ⚠️ <strong>Important :</strong> Veuillez changer ce mot de passe lors de votre prochaine connexion pour des raisons de sécurité.
                </p>
              </div>

              <p style="font-size: 14px; color: #6B7280; margin-top: 30px;">
                Si vous n'avez pas demandé cette réinitialisation, veuillez contacter immédiatement l'administrateur.
              </p>

              <hr style="border: none; border-top: 1px solid #E5E7EB; margin: 30px 0;">

              <p style="font-size: 12px; color: #9CA3AF; text-align: center; margin: 0;">
                Cet email a été envoyé automatiquement par le système Constat Tunisie.
              </p>
            </div>
          </div>
        ''',
      };

      final result = await AdminCompagnieAgenceService.sendEmail(emailData);

      if (!result['success']) {
        debugPrint('[ADMIN_COMPAGNIE] Erreur envoi email: ${result['message']}');
      }
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE] Erreur envoi email réinitialisation: $e');
    }
  }

  /// ✅ Afficher un dialog de succès
  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF3B82F6).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 48,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'OK',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ❌ Afficher un dialog d'erreur
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFEF4444).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_rounded,
                        size: 48,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'OK',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🗑️ Retirer admin agence avec option de créer un nouveau
  void _removeAdminAgence(Map<String, dynamic> agence) {
    final agenceId = agence['id'];
    final admin = _adminsAgence.firstWhere(
      (admin) => admin['agenceId'] == agenceId && admin['isActive'] == true,
      orElse: () => {},
    );

    if (admin.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person_remove_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Retirer l\'administrateur',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              agence['nom'] ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Attention !',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Cette action retirera définitivement l\'administrateur "${admin['prenom']} ${admin['nom']}" de cette agence.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF7F1D1D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Après suppression, vous pourrez créer un nouvel administrateur ou assigner un administrateur existant à cette agence.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Actions
                Container(
                  padding: EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Color(0xFFE5E7EB)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Annuler',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _deleteAdminAgenceFromAgence(admin, agence);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFEF4444),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            elevation: 2,
                          ),
                          child: Text(
                            'Retirer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Aucun admin trouvé pour cette agence'),
            ],
          ),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showAgenceDetails(Map<String, dynamic> agence) {
    final agenceId = agence['id'];
    final adminAgence = _adminsAgence.firstWhere(
      (admin) => admin['agenceId'] == agenceId && admin['isActive'] == true,
      orElse: () => {},
    );
    final hasAdmin = adminAgence.isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.business_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Détails de l\'agence',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            agence['nom'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Informations générales
                      _buildDetailSection(
                        title: 'Informations générales',
                        icon: Icons.info_outline,
                        color: Color(0xFF3B82F6),
                        children: [
                          _buildDetailItem('Nom', agence['nom'] ?? 'N/A'),
                          _buildDetailItem('Gouvernorat', agence['gouvernorat'] ?? 'N/A'),
                          _buildDetailItem('Adresse', agence['adresse'] ?? 'N/A'),
                          _buildDetailItem('Téléphone', agence['telephone'] ?? 'N/A'),
                          _buildDetailItem('Email', agence['emailContact'] ?? 'N/A'),
                          _buildDetailItem(
                            'Statut',
                            agence['isActive'] == true ? 'Active' : 'Inactive',
                            valueColor: agence['isActive'] == true ? Color(0xFF3B82F6) : Color(0xFFEF4444),
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Admin agence
                      _buildDetailSection(
                        title: 'Administrateur',
                        icon: Icons.admin_panel_settings_outlined,
                        color: hasAdmin ? Color(0xFF8B5CF6) : Color(0xFF9CA3AF),
                        children: hasAdmin ? [
                          _buildDetailItem('Nom complet', '${adminAgence['prenom']} ${adminAgence['nom']}'),
                          _buildDetailItem('Email', adminAgence['email'] ?? 'N/A'),
                          _buildDetailItem('Téléphone', adminAgence['telephone'] ?? 'N/A'),
                          _buildDetailItem(
                            'Statut',
                            adminAgence['isActive'] == true ? 'Actif' : 'Inactif',
                            valueColor: adminAgence['isActive'] == true ? Color(0xFF3B82F6) : Color(0xFFEF4444),
                          ),
                        ] : [
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.person_off, color: Color(0xFF9CA3AF)),
                                SizedBox(width: 12),
                                Text(
                                  'Aucun administrateur assigné',
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Statistiques
                      _buildDetailSection(
                        title: 'Statistiques',
                        icon: Icons.analytics_outlined,
                        color: Color(0xFFF59E0B),
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildStatCard('Agents', '${_getAgentsCountForAgence(agence['id'])}', Icons.people_outline, Color(0xFF3B82F6))),
                              SizedBox(width: 12),
                              Expanded(child: _buildStatCard('Constats', '${_getConstatsCountForAgence(agence['id'])}', Icons.description_outlined, Color(0xFFEC4899))),
                              SizedBox(width: 12),
                              Expanded(child: _buildStatCard('Experts', '${_getExpertsCountForAgence(agence['id'])}', Icons.engineering_outlined, Color(0xFFF59E0B))),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Actions
              Container(
                padding: EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Fermer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditAgenceDialog(Map<String, dynamic> agence) {
    final _formKey = GlobalKey<FormState>();
    final _nomController = TextEditingController(text: agence['nom']);
    final _adresseController = TextEditingController(text: agence['adresse']);
    final _telephoneController = TextEditingController(text: agence['telephone']);
    final _emailController = TextEditingController(text: agence['email']);
    String _selectedGouvernorat = agence['gouvernorat'] ?? '';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Modifier l\'agence',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            agence['nom'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Form
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildModernTextField(
                          controller: _nomController,
                          label: 'Nom de l\'agence',
                          icon: Icons.business_outlined,
                          validator: (value) => value?.isEmpty == true ? 'Nom requis' : null,
                        ),
                        SizedBox(height: 20),
                        _buildModernDropdown(
                          value: _selectedGouvernorat,
                          label: 'Gouvernorat',
                          icon: Icons.location_on_outlined,
                          items: [
                            'Tunis', 'Ariana', 'Ben Arous', 'Manouba', 'Nabeul', 'Zaghouan',
                            'Bizerte', 'Béja', 'Jendouba', 'Kef', 'Siliana', 'Sousse',
                            'Monastir', 'Mahdia', 'Sfax', 'Kairouan', 'Kasserine', 'Sidi Bouzid',
                            'Gabès', 'Médenine', 'Tataouine', 'Gafsa', 'Tozeur', 'Kébili'
                          ],
                          onChanged: (value) => _selectedGouvernorat = value ?? '',
                        ),
                        SizedBox(height: 20),
                        _buildModernTextField(
                          controller: _adresseController,
                          label: 'Adresse',
                          icon: Icons.location_city_outlined,
                          validator: (value) => value?.isEmpty == true ? 'Adresse requise' : null,
                        ),
                        SizedBox(height: 20),
                        _buildModernTextField(
                          controller: _telephoneController,
                          label: 'Téléphone',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        SizedBox(height: 20),
                        _buildModernTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Actions
              Container(
                padding: EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Annuler',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState?.validate() == true) {
                            await _updateAgence(
                              agenceId: agence['id'],
                              nom: _nomController.text,
                              gouvernorat: _selectedGouvernorat,
                              adresse: _adresseController.text,
                              telephone: _telephoneController.text,
                              emailContact: _emailController.text,
                            );
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFF59E0B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          elevation: 2,
                        ),
                        child: Text(
                          'Modifier',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📋 Section de détails
  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  /// 📝 Item de détail
  Widget _buildDetailItem(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? Color(0xFF1F2937),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎨 Champ de texte moderne
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Color(0xFF6B7280)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFFEF4444)),
            ),
            filled: true,
            fillColor: Color(0xFFF9FAFB),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  /// 🎨 Dropdown moderne
  Widget _buildModernDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value.isEmpty ? null : value,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Color(0xFF6B7280)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            filled: true,
            fillColor: Color(0xFFF9FAFB),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 📝 Mettre à jour une agence
  Future<void> _updateAgence({
    required String agenceId,
    required String nom,
    required String gouvernorat,
    required String adresse,
    required String telephone,
    required String emailContact,
  }) async {
    try {
      final result = await AdminCompagnieAgenceService.updateAgence(
        agenceId: agenceId,
        nom: nom,
        gouvernorat: gouvernorat,
        adresse: adresse,
        telephone: telephone,
        emailContact: emailContact,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(result['message']),
              ],
            ),
            backgroundColor: Color(0xFF3B82F6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        await _loadAllData();
        if (mounted) setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text(result['error']),
              ],
            ),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Erreur: $e'),
            ],
          ),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  /// 🔄 Changer le statut d'une agence
  Future<void> _toggleAgenceStatus(Map<String, dynamic> agence, bool newStatus) async {
    try {
      final result = await AdminCompagnieAgenceService.toggleAgenceStatus(
        agence['id'],
        newStatus,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(result['message']),
              ],
            ),
            backgroundColor: Color(0xFF8B5CF6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        await _loadAllData();
        if (mounted) setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text(result['error']),
              ],
            ),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Erreur: $e'),
            ],
          ),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
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
        if (mounted) setState(() {}); // Forcer la mise à jour de l'interface
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
    // Récupérer les admins disponibles (non assignés à une agence)
    final availableAdmins = _adminsAgence.where((admin) {
      return admin['agenceId'] == null || admin['agenceId'].isEmpty;
    }).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person_search, color: Color(0xFF6366F1)),
            SizedBox(width: 8),
            Expanded(
              child: Text('Assigner Admin - ${agence['nom']}'),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Assigner un admin existant
              Card(
                child: ListTile(
                  leading: Icon(Icons.person_search, color: Color(0xFF6366F1)),
                  title: Text('Assigner un admin existant'),
                  subtitle: Text('${availableAdmins.length} admin(s) disponible(s)'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  enabled: availableAdmins.isNotEmpty,
                  onTap: availableAdmins.isNotEmpty ? () {
                    Navigator.pop(context);
                    _showAssignExistingAdminDialog(agence);
                  } : null,
                ),
              ),

              // Message si aucun admin disponible
              if (availableAdmins.isEmpty)
                Container(
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Aucun administrateur disponible. Tous les admins sont déjà assignés à des agences.',
                          style: TextStyle(color: Colors.orange[800]),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
        ],
      ),
    );
  }

  /// 🎨 Widget pour les options d'admin
  Widget _buildAdminOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;

    return Container(
      decoration: BoxDecoration(
        color: isEnabled ? color.withOpacity(0.05) : Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled ? color.withOpacity(0.2) : Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.all(20),
        leading: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isEnabled ? color.withOpacity(0.1) : Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isEnabled ? color : Color(0xFF9CA3AF),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isEnabled ? Color(0xFF1A1A1A) : Color(0xFF9CA3AF),
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: isEnabled ? Color(0xFF666666) : Color(0xFF9CA3AF),
            ),
          ),
        ),
        trailing: isEnabled ? Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: color,
        ) : null,
      ),
    );
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

  /// 🗑️ Supprimer admin agence avec proposition de créer un nouveau
  Future<void> _deleteAdminAgenceFromAgence(Map<String, dynamic> admin, [Map<String, dynamic>? agence]) async {
    try {
      final result = await AdminCompagnieAgenceService.deleteAdminAgence(
        admin['id'],
        admin['agenceId'],
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(result['message']),
              ],
            ),
            backgroundColor: Color(0xFFEC4899),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        // Recharger les données
        await _loadAllData();
        if (mounted) setState(() {});

        // Proposer de créer un nouvel admin seulement si l'agence est fournie
        if (agence != null) {
          _showCreateAdminAfterRemoval(agence);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text(result['error']),
              ],
            ),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Erreur: $e'),
            ],
          ),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  /// 🆕 Proposer de créer un admin après suppression
  void _showCreateAdminAfterRemoval(Map<String, dynamic> agence) {
    Future.delayed(Duration(milliseconds: 500), () {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person_add_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Créer un nouvel admin ?',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Pour l\'agence ${agence['nom']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFF3B82F6)),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'L\'agence "${agence['nom']}" n\'a plus d\'administrateur. Voulez-vous créer un nouvel administrateur ou assigner un administrateur existant ?',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF166534),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                Container(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showCreateAdminAgenceDialog(agence);
                          },
                          icon: Icon(Icons.person_add, color: Colors.white),
                          label: Text(
                            'Créer un nouvel admin',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFEC4899),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showAssignExistingAdminDialog(agence);
                          },
                          icon: Icon(Icons.person_search, color: Color(0xFF3B82F6)),
                          label: Text(
                            'Assigner un admin existant',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Color(0xFF3B82F6)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Plus tard',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// 👤 Assigner un admin existant à une agence
  void _showAssignExistingAdminDialog(Map<String, dynamic> agence) {
    // Récupérer les admins qui ne sont pas encore assignés à une agence
    final availableAdmins = _adminsAgence.where((admin) {
      return admin['agenceId'] == null || admin['agenceId'].isEmpty;
    }).toList();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_search_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assigner un admin existant',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'À l\'agence ${agence['nom']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: availableAdmins.isEmpty
                    ? Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.person_off_outlined,
                                    size: 48,
                                    color: Color(0xFFF59E0B),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Aucun admin disponible',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tous les administrateurs existants sont déjà assignés à des agences. Vous devez créer un nouvel administrateur.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF92400E),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showCreateAdminAgenceDialog(agence);
                                },
                                icon: Icon(Icons.person_add, color: Colors.white),
                                label: Text(
                                  'Créer un nouvel admin',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF8B5CF6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sélectionnez un administrateur disponible :',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151),
                              ),
                            ),
                            SizedBox(height: 16),
                            ...availableAdmins.map((admin) => _buildAvailableAdminItem(admin, agence)),
                          ],
                        ),
                      ),
              ),

              // Cancel button
              if (availableAdmins.isNotEmpty)
                Padding(
                  padding: EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Annuler',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 👤 Widget pour afficher un admin disponible
  Widget _buildAvailableAdminItem(Map<String, dynamic> admin, Map<String, dynamic> agence) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.person,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          '${admin['prenom']} ${admin['nom']}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              admin['email'] ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Disponible',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await _assignAdminToAgence(admin, agence);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF3B82F6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(
            'Assigner',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  /// 🔗 Assigner un admin existant à une agence
  Future<void> _assignAdminToAgence(Map<String, dynamic> admin, Map<String, dynamic> agence) async {
    try {
      final result = await AdminCompagnieAgenceService.assignAdminToAgence(
        admin['id'],
        agence['id'],
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Admin assigné avec succès à l\'agence'),
              ],
            ),
            backgroundColor: Color(0xFF3B82F6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        // Recharger les données
        await _loadAllData();
        if (mounted) setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text(result['error'] ?? 'Erreur lors de l\'assignation'),
              ],
            ),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Erreur: $e'),
            ],
          ),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
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
        if (mounted) setState(() {}); // Forcer la mise à jour
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
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.shade50],
            ),
          ),
          child: Column(
            children: [
              // En-tête moderne
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${admin['adminPrenom'] ?? ''} ${admin['adminNom'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Admin Agence',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: admin['adminIsActive'] == true ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        admin['adminIsActive'] == true ? 'ACTIF' : 'INACTIF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Contenu
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Informations personnelles
                      _buildAdminDetailSection(
                        'Informations Personnelles',
                        Icons.person_rounded,
                        Colors.blue,
                        [
                          _buildAdminDetailRow('Prénom', admin['adminPrenom'] ?? 'Non défini'),
                          _buildAdminDetailRow('Nom', admin['adminNom'] ?? 'Non défini'),
                          _buildAdminDetailRow('Email', admin['adminEmail'] ?? 'Non défini'),
                          _buildAdminDetailRow('Téléphone', admin['adminTelephone'] ?? 'Non défini'),
                          _buildAdminDetailRow('CIN', admin['adminCin'] ?? 'Non défini'),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Informations agence
                      _buildAdminDetailSection(
                        'Agence Assignée',
                        Icons.store_rounded,
                        Colors.green,
                        [
                          _buildAdminDetailRow('Nom de l\'agence', admin['agenceNom'] ?? 'Non défini'),
                          _buildAdminDetailRow('Code agence', admin['agenceCode'] ?? 'Non défini'),
                          _buildAdminDetailRow('Adresse', admin['agenceAdresse'] ?? 'Non définie'),
                          _buildAdminDetailRow('Gouvernorat', admin['agenceGouvernorat'] ?? 'Non défini'),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Statut et dates
                      _buildAdminDetailSection(
                        'Statut et Historique',
                        Icons.history_rounded,
                        Colors.orange,
                        [
                          _buildAdminDetailRow('Statut', admin['adminIsActive'] == true ? 'Actif' : 'Inactif'),
                          _buildAdminDetailRow('Date de création', admin['adminCreatedAt'] != null
                              ? _formatDate(admin['adminCreatedAt'])
                              : 'Non définie'),
                          if (admin['adminDeactivatedAt'] != null)
                            _buildAdminDetailRow('Date de désactivation', _formatDate(admin['adminDeactivatedAt'])),
                          if (admin['adminDeactivationReason'] != null)
                            _buildAdminDetailRow('Raison désactivation', admin['adminDeactivationReason']),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Actions en bas
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showResetPasswordDialog(admin);
                        },
                        icon: const Icon(Icons.lock_reset_rounded),
                        label: const Text('Réinitialiser mot de passe'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _toggleAdminAgenceStatus(admin, !(admin['adminIsActive'] == true));
                        },
                        icon: Icon(admin['adminIsActive'] == true ? Icons.block_rounded : Icons.check_circle_rounded),
                        label: Text(admin['adminIsActive'] == true ? 'Désactiver' : 'Activer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: admin['adminIsActive'] == true ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📋 Section de détails admin
  Widget _buildAdminDetailSection(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  /// 📄 Ligne de détail admin
  Widget _buildAdminDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔐 Afficher la boîte de dialogue de réinitialisation avec mot de passe visible
  void _showResetPasswordDialog(Map<String, dynamic> admin) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.lock_reset_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Réinitialiser le mot de passe',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${admin['adminPrenom'] ?? admin['prenom'] ?? ''} ${admin['adminNom'] ?? admin['nom'] ?? ''}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 48,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Êtes-vous sûr de vouloir réinitialiser le mot de passe ?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Un nouveau mot de passe sera généré et affiché ici.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Boutons d'action
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              side: BorderSide(color: Colors.grey[300]!),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _performPasswordReset(admin),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Réinitialiser'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔐 Effectuer la réinitialisation du mot de passe avec affichage
  Future<void> _performPasswordReset(Map<String, dynamic> admin) async {
    try {
      // Fermer la boîte de dialogue de confirmation
      Navigator.pop(context);

      // Afficher l'indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );

      // Générer un nouveau mot de passe
      final newPassword = _generateRandomPassword();

      // Simuler la mise à jour (remplacer par votre logique Firebase)
      await Future.delayed(const Duration(seconds: 2));

      // Fermer l'indicateur de chargement
      Navigator.pop(context);

      // Afficher le nouveau mot de passe
      _showPasswordDisplayDialog(admin, newPassword);

    } catch (e) {
      // Fermer l'indicateur de chargement si ouvert
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      _showErrorDialog(
        'Erreur',
        'Impossible de réinitialiser le mot de passe: $e',
      );
    }
  }

  /// 👁️ Afficher le nouveau mot de passe généré
  void _showPasswordDisplayDialog(Map<String, dynamic> admin, String newPassword) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Mot de passe réinitialisé',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${admin['adminPrenom'] ?? admin['prenom'] ?? ''} ${admin['adminNom'] ?? admin['nom'] ?? ''}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.password_rounded,
                      size: 48,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nouveau mot de passe généré',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Affichage du mot de passe
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF10B981), width: 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.key_rounded,
                            color: Color(0xFF10B981),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SelectableText(
                              newPassword,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF374151),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: newPassword));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Mot de passe copié dans le presse-papiers'),
                                  backgroundColor: Color(0xFF10B981),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.copy_rounded,
                              color: Color(0xFF10B981),
                            ),
                            tooltip: 'Copier le mot de passe',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text(
                      'Veuillez noter ce mot de passe et le communiquer à l\'utilisateur de manière sécurisée.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Bouton de fermeture
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Fermer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  /// 📊 Statistiques de ma compagnie - Onglet 4
  Widget _buildStatistiquesCompagnies() {
    if (_compagnieData == null) {
      return const Center(
        child: Text(
          'Données de compagnie non disponibles',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ModernStatisticsScreen(compagnieData: _compagnieData!);
  }

  /// 👤 Profil de la compagnie - Onglet 5 (Version Simplifiée)
  Widget _buildParametresCompagnie() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du profil
          _buildProfilHeader(),
          const SizedBox(height: 24),

          // Informations de la compagnie (éditable)
          _buildCompanyProfileCard(),
        ],
      ),
    );
  }

  /// 👤 En-tête du profil de la compagnie
  Widget _buildProfilHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 12,
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
              Icons.business_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profil de la Compagnie',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Consultez et modifiez les informations de ${_compagnieData?['nom'] ?? 'votre compagnie'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 👤 Carte de profil de la compagnie avec formulaire de modification
  Widget _buildCompanyProfileCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la carte
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: Color(0xFF3B82F6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Informations de la Compagnie',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              Switch(
                value: _isEditMode,
                onChanged: (value) {
                  setState(() {
                    _isEditMode = value;
                    if (_isEditMode) {
                      _initializeEditControllers();
                    }
                  });
                },
                activeColor: const Color(0xFF10B981),
              ),
              const SizedBox(width: 8),
              Text(
                _isEditMode ? 'Modifier' : 'Consulter',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _isEditMode ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Formulaire ou affichage selon le mode
          if (_isEditMode) ...[
            _buildEditForm(),
          ] else ...[
            _buildDisplayInfo(),
          ],
        ],
      ),
    );
  }

  /// 📝 Initialiser les contrôleurs de modification
  void _initializeEditControllers() {
    final compagnieData = _compagnieData ?? {};
    _nomController = TextEditingController(text: compagnieData['nom'] ?? '');
    _emailController = TextEditingController(text: compagnieData['email'] ?? '');
    _telephoneController = TextEditingController(text: compagnieData['telephone'] ?? '');
    _adresseController = TextEditingController(text: compagnieData['adresse'] ?? '');
  }

  /// 📋 Affichage des informations (mode consultation)
  Widget _buildDisplayInfo() {
    final compagnieData = _compagnieData ?? {};

    return Column(
      children: [
        _buildInfoRow(Icons.business_rounded, 'Nom de la compagnie', compagnieData['nom'] ?? 'Non défini'),
        const SizedBox(height: 16),
        _buildInfoRow(Icons.code_rounded, 'Code compagnie', compagnieData['code'] ?? 'Non défini'),
        const SizedBox(height: 16),
        _buildInfoRow(Icons.email_rounded, 'Email', compagnieData['email'] ?? 'Non défini'),
        const SizedBox(height: 16),
        _buildInfoRow(Icons.phone_rounded, 'Téléphone', compagnieData['telephone'] ?? 'Non défini'),
        const SizedBox(height: 16),
        _buildInfoRow(Icons.location_on_rounded, 'Adresse', compagnieData['adresse'] ?? 'Non défini'),
        const SizedBox(height: 16),
        _buildInfoRow(Icons.calendar_today_rounded, 'Date de création',
          compagnieData['dateCreation'] != null
            ? _formatDate(compagnieData['dateCreation'].toDate())
            : 'Non définie'),
      ],
    );
  }

  /// ✏️ Formulaire de modification
  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Nom de la compagnie
          _buildEditField(
            controller: _nomController,
            label: 'Nom de la compagnie',
            icon: Icons.business_rounded,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le nom de la compagnie est requis';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Email
          _buildEditField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'L\'email est requis';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Format d\'email invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Téléphone
          _buildEditField(
            controller: _telephoneController,
            label: 'Téléphone',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le téléphone est requis';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Adresse
          _buildEditField(
            controller: _adresseController,
            label: 'Adresse',
            icon: Icons.location_on_rounded,
            maxLines: 2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'L\'adresse est requise';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _cancelEdit,
                  icon: const Icon(Icons.cancel_rounded),
                  label: const Text('Annuler'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Color(0xFF6B7280)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveChanges,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Sauvegarder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📝 Champ de modification
  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF3B82F6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  /// ❌ Annuler la modification
  void _cancelEdit() {
    setState(() {
      _isEditMode = false;
    });
    // Nettoyer les contrôleurs
    _nomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
  }

  /// 💾 Sauvegarder les modifications
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final userData = widget.userData;
      if (userData == null) return;

      final compagnieId = userData['compagnieId'];
      if (compagnieId == null) return;

      // Mettre à jour dans Firestore
      await FirebaseFirestore.instance
          .collection('compagnies_assurance')
          .doc(compagnieId)
          .update({
        'nom': _nomController.text.trim(),
        'email': _emailController.text.trim(),
        'telephone': _telephoneController.text.trim(),
        'adresse': _adresseController.text.trim(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Recharger les données
      await _loadCompagnieData();

      // Fermer le dialog de chargement
      if (mounted) Navigator.of(context).pop();

      // Sortir du mode édition
      setState(() {
        _isEditMode = false;
      });

      // Nettoyer les contrôleurs
      _nomController.dispose();
      _emailController.dispose();
      _telephoneController.dispose();
      _adresseController.dispose();

      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Informations mises à jour avec succès'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      // Fermer le dialog de chargement
      if (mounted) Navigator.of(context).pop();

      // Afficher un message d'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de la mise à jour: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
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
              Icon(Icons.settings_rounded, color: Color(0xFF8B5CF6)),
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
              Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFEC4899)),
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
                backgroundColor: const Color(0xFFEC4899),
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
                foregroundColor: const Color(0xFFEC4899),
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
      await _deleteAdminAgenceFromAgence(admin);
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
                    ? [const Color(0xFF3B82F6), const Color(0xFF2563EB)]
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
                Column(
                  children: [
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isActive ? () => _resetAdminPassword(admin) : null,
                            icon: const Icon(Icons.lock_reset_outlined),
                            label: const Text('Reset MDP'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isActive ? const Color(0xFF6366F1) : Colors.grey,
                              side: BorderSide(color: isActive ? const Color(0xFF6366F1) : Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
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

  /// 👥 Afficher les agents d'une agence
  void _showAgentsDialog(Map<String, dynamic> agence) {
    final agenceId = agence['id'];
    final agentsOfAgence = _agents.where((agent) => agent['agenceId'] == agenceId).toList();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Agents de l\'agence',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      agence['nom'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: Container(
                  margin: EdgeInsets.fromLTRB(24, 0, 24, 24),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: agentsOfAgence.isEmpty
                      ? _buildEmptyAgentsState()
                      : _buildAgentsList(agentsOfAgence),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📋 Liste des agents
  Widget _buildAgentsList(List<Map<String, dynamic>> agents) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${agents.length} agent(s) trouvé(s)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        SizedBox(height: 16),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: agents.length,
            itemBuilder: (context, index) {
              final agent = agents[index];
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Color(0xFF8B5CF6).withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${agent['prenom'] ?? ''} ${agent['nom'] ?? ''}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            agent['email'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                          ),
                          if (agent['telephone'] != null) ...[
                            SizedBox(height: 2),
                            Text(
                              agent['telephone'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: agent['isActive'] == true
                            ? Color(0xFF3B82F6).withOpacity(0.1)
                            : Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: agent['isActive'] == true
                              ? Color(0xFF3B82F6)
                              : Color(0xFFEF4444),
                        ),
                      ),
                      child: Text(
                        agent['isActive'] == true ? 'Actif' : 'Inactif',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: agent['isActive'] == true
                              ? Color(0xFF3B82F6)
                              : Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 🚫 État vide pour les agents
  Widget _buildEmptyAgentsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Color(0xFF9CA3AF),
          ),
          SizedBox(height: 16),
          Text(
            'Aucun agent trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Cette agence n\'a pas encore d\'agents assignés.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


}

