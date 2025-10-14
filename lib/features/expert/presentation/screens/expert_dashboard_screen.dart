import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/sinistre_expert_assignment_service.dart';
import '../../screens/missions_expert_screen.dart';
import '../../screens/mission_details_screen.dart';

/// 🔧 Dashboard de l'expert automobile
class ExpertDashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ExpertDashboardScreen({Key? key, this.userData}) : super(key: key);

  @override
  State<ExpertDashboardScreen> createState() => _ExpertDashboardScreenState();
}

class _ExpertDashboardScreenState extends State<ExpertDashboardScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _missions = [];
  Map<String, dynamic>? _expertData;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Retour à 3 onglets
    _loadExpertData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 📋 Charger les données de l'expert
  Future<void> _loadExpertData() async {
    setState(() => _isLoading = true);

    try {
      // Si les données sont déjà passées en paramètre, les utiliser
      if (widget.userData != null) {
        debugPrint('[EXPERT_DASHBOARD] 📋 Utilisation des données passées en paramètre');
        _expertData = Map<String, dynamic>.from(widget.userData!);
        _expertData!['id'] = _expertData!['uid'] ?? _expertData!['id'];

        debugPrint('[EXPERT_DASHBOARD] 👤 Nom: ${_expertData!['nom']}');
        debugPrint('[EXPERT_DASHBOARD] 👤 Prénom: ${_expertData!['prenom']}');
        debugPrint('[EXPERT_DASHBOARD] 🏷️ Rôle: ${_expertData!['role']}');
        debugPrint('[EXPERT_DASHBOARD] 📧 Email: ${_expertData!['email']}');
        debugPrint('[EXPERT_DASHBOARD] 🔧 Code Expert: ${_expertData!['codeExpert']}');
      } else {
        // Sinon, essayer de récupérer via Firebase Auth
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          debugPrint('[EXPERT_DASHBOARD] ❌ Aucun utilisateur connecté et aucune donnée passée');
          return;
        }

        debugPrint('[EXPERT_DASHBOARD] 🔍 Chargement données pour UID: ${user.uid}');

        final expertDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (expertDoc.exists) {
          _expertData = expertDoc.data()!;
          _expertData!['id'] = expertDoc.id;

          debugPrint('[EXPERT_DASHBOARD] 📋 Données récupérées via Firebase Auth:');
          debugPrint('[EXPERT_DASHBOARD] 👤 Nom: ${_expertData!['nom']}');
          debugPrint('[EXPERT_DASHBOARD] 👤 Prénom: ${_expertData!['prenom']}');
          debugPrint('[EXPERT_DASHBOARD] 🏷️ Rôle: ${_expertData!['role']}');
          debugPrint('[EXPERT_DASHBOARD] 📧 Email: ${_expertData!['email']}');
          debugPrint('[EXPERT_DASHBOARD] 🔧 Code Expert: ${_expertData!['codeExpert']}');
        } else {
          debugPrint('[EXPERT_DASHBOARD] ❌ Aucun document trouvé pour UID: ${user.uid}');
          return;
        }
      }

      // Charger les missions
      await _loadMissions();

      // Calculer les statistiques
      _calculateStats();

    } catch (e) {
      debugPrint('[EXPERT_DASHBOARD] ❌ Erreur chargement données: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 📋 Charger les missions
  Future<void> _loadMissions() async {
    try {
      String? expertId;

      // Récupérer l'ID de l'expert selon le mode de connexion
      if (_expertData != null) {
        expertId = _expertData!['id'] ?? _expertData!['uid'];
      } else {
        final user = FirebaseAuth.instance.currentUser;
        expertId = user?.uid;
      }

      if (expertId == null) {
        debugPrint('[EXPERT_DASHBOARD] ❌ Impossible de récupérer l\'ID de l\'expert');
        return;
      }

      debugPrint('[EXPERT_DASHBOARD] 🔍 Chargement missions pour expert: $expertId');
      final missions = await SinistreExpertAssignmentService.getExpertMissions(expertId);
      setState(() => _missions = missions);
      debugPrint('[EXPERT_DASHBOARD] ✅ ${missions.length} missions chargées');
    } catch (e) {
      debugPrint('[EXPERT_DASHBOARD] ❌ Erreur chargement missions: $e');
    }
  }

  /// 📊 Calculer les statistiques
  void _calculateStats() {
    final totalMissions = _missions.length;
    final missionsAssignees = _missions.where((m) => m['statut'] == 'assignee').length;
    final missionsEnCours = _missions.where((m) => m['statut'] == 'en_cours').length;
    final missionsTerminees = _missions.where((m) => m['statut'] == 'terminee').length;
    final missionsAnnulees = _missions.where((m) => m['statut'] == 'annulee').length;

    setState(() {
      _stats = {
        'totalMissions': totalMissions,
        'missionsAssignees': missionsAssignees,
        'missionsEnCours': missionsEnCours,
        'missionsTerminees': missionsTerminees,
        'missionsAnnulees': missionsAnnulees,
        'tauxCompletion': totalMissions > 0 ? (missionsTerminees / totalMissions * 100).round() : 0,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDashboardTab(),
                      _buildMissionsTab(),
                      _buildProfileTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// 📱 AppBar moderne
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.engineering,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Expert Dashboard',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${_expertData?['prenom'] ?? ''} ${_expertData?['nom'] ?? ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF667EEA),
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implémenter les notifications
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/user-type-selection',
                (route) => false,
              );
            },
          ),
        ),
      ],
    );
  }

  /// 📑 Barre d'onglets
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF667EEA),
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: const Color(0xFF667EEA),
        tabs: const [
          Tab(
            icon: Icon(Icons.dashboard),
            text: 'Tableau de Bord',
          ),
          Tab(
            icon: Icon(Icons.assignment),
            text: 'Missions',
          ),
          Tab(
            icon: Icon(Icons.person),
            text: 'Profil',
          ),
        ],
      ),
    );
  }

  /// 📊 Onglet tableau de bord
  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 20),
          _buildStatsGrid(),
          const SizedBox(height: 20),
          _buildRecentMissions(),
        ],
      ),
    );
  }

  /// 👋 Carte de bienvenue moderne
  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.engineering,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _expertData?['isDisponible'] == true
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _expertData?['isDisponible'] == true
                        ? Colors.green.withOpacity(0.3)
                        : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _expertData?['isDisponible'] == true
                            ? Colors.green
                            : Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _expertData?['isDisponible'] == true ? 'Disponible' : 'Occupé',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Bienvenue Expert !',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_expertData?['prenom'] ?? ''} ${_expertData?['nom'] ?? ''}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.badge_outlined,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Code: ${_expertData?['codeExpert'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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

  /// 📊 Grille de statistiques moderne
  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildModernStatCard(
                'Total Missions',
                '${_stats['totalMissions'] ?? 0}',
                Icons.assignment_outlined,
                const Color(0xFF667EEA),
                const Color(0xFF764BA2),
              ),
            ),
            const SizedBox(width: 8), // Réduit de 12 à 8
            Expanded(
              child: _buildModernStatCard(
                'En Cours',
                '${_stats['missionsEnCours'] ?? 0}',
                Icons.pending_actions_outlined,
                const Color(0xFFFF6B6B),
                const Color(0xFFFFE66D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8), // Réduit de 12 à 8
        Row(
          children: [
            Expanded(
              child: _buildModernStatCard(
                'Terminées',
                '${_stats['missionsTerminees'] ?? 0}',
                Icons.check_circle_outline,
                const Color(0xFF4ECDC4),
                const Color(0xFF44A08D),
              ),
            ),
            const SizedBox(width: 8), // Réduit de 12 à 8
            Expanded(
              child: _buildModernStatCard(
                'Taux Réussite',
                '${_stats['tauxCompletion'] ?? 0}%',
                Icons.trending_up_outlined,
                const Color(0xFF9B59B6),
                const Color(0xFF8E44AD),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 📊 Carte de statistique moderne
  Widget _buildModernStatCard(String title, String value, IconData icon, Color startColor, Color endColor) {
    return Container(
      height: 85, // Réduit de 100 à 85
      padding: const EdgeInsets.all(12), // Réduit de 16 à 12
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12), // Réduit de 16 à 12
        boxShadow: [
          BoxShadow(
            color: startColor.withOpacity(0.15), // Réduit l'opacité
            blurRadius: 8, // Réduit de 10 à 8
            offset: const Offset(0, 3), // Réduit de 4 à 3
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: Colors.white.withOpacity(0.9),
                size: 20, // Réduit de 24 à 20
              ),
              Container(
                padding: const EdgeInsets.all(3), // Réduit de 4 à 3
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4), // Réduit de 6 à 4
                ),
                child: Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 12, // Réduit de 14 à 12
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18, // Réduit de 20 à 18
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 9, // Réduit de 10 à 9
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📋 Missions récentes
  Widget _buildRecentMissions() {
    final recentMissions = _missions.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Missions Récentes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        if (recentMissions.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Aucune mission récente',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
          )
        else
          ...recentMissions.map((mission) => _buildMissionCard(mission, isCompact: true)),
      ],
    );
  }

  /// 📋 Onglet missions
  Widget _buildMissionsTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Carte de résumé des missions
          Container(
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
              children: [
                const Text(
                  'Mes Missions',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible(
                      child: _buildMissionSummaryItem('Total', '${_missions.length}', Icons.assignment),
                    ),
                    Flexible(
                      child: _buildMissionSummaryItem('En cours', '${_missions.where((m) => m['statut'] == 'en_cours').length}', Icons.work),
                    ),
                    Flexible(
                      child: _buildMissionSummaryItem('Terminées', '${_missions.where((m) => m['statut'] == 'terminee').length}', Icons.check_circle),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Bouton pour accéder à la liste complète
          ElevatedButton.icon(
            onPressed: _openMissionsScreen,
            icon: const Icon(Icons.list),
            label: const Text('Voir toutes mes missions'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Missions récentes
          if (_missions.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Missions récentes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _missions.take(3).length, // Afficher seulement les 3 premières
                itemBuilder: (context, index) {
                  final mission = _missions[index];
                  return _buildMissionPreviewCard(mission);
                },
              ),
            ),
          ] else
            Expanded(child: _buildEmptyMissions()),
        ],
      ),
    );
  }

  /// 🔍 Filtre des missions
  Widget _buildMissionsFilter() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Filtrer par statut',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Toutes les missions')),
                DropdownMenuItem(value: 'assignee', child: Text('Assignées')),
                DropdownMenuItem(value: 'en_cours', child: Text('En cours')),
                DropdownMenuItem(value: 'terminee', child: Text('Terminées')),
                DropdownMenuItem(value: 'annulee', child: Text('Annulées')),
              ],
              onChanged: (value) {
                // TODO: Implémenter le filtrage
              },
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _loadMissions,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Actualiser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Carte de mission
  Widget _buildMissionCard(Map<String, dynamic> mission, {bool isCompact = false}) {
    final statut = mission['statut'] ?? 'assignee';
    Color statutColor;

    switch (statut) {
      case 'assignee':
        statutColor = Colors.orange;
        break;
      case 'en_cours':
        statutColor = Colors.blue;
        break;
      case 'terminee':
        statutColor = Colors.green;
        break;
      case 'annulee':
        statutColor = Colors.red;
        break;
      default:
        statutColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statutColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.assignment,
                    color: statutColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mission ${mission['id']?.substring(0, 8) ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        mission['sinistreInfo']?['numeroSinistre'] ?? 'Sinistre N/A',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statutColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getMissionStatusText(statut),
                    style: TextStyle(
                      color: statutColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 📝 Information de mission
  Widget _buildMissionInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  /// 📭 État vide missions
  Widget _buildEmptyMissions() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 16),
          Text(
            'Aucune mission assignée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Les nouvelles missions apparaîtront ici',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  /// 👤 Onglet profil
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileCard(),
          const SizedBox(height: 20),
          _buildSpecialitiesCard(),
          const SizedBox(height: 20),
          _buildZonesCard(),
        ],
      ),
    );
  }

  /// 👤 Carte profil
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations Personnelles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          _buildProfileRow('Nom complet', '${_expertData?['prenom'] ?? ''} ${_expertData?['nom'] ?? ''}'),
          _buildProfileRow('Code Expert', _expertData?['codeExpert'] ?? 'N/A'),
          _buildProfileRow('Email', _expertData?['email'] ?? 'N/A'),
          _buildProfileRow('Téléphone', _expertData?['telephone'] ?? 'N/A'),
          _buildProfileRow('Licence', _expertData?['numeroLicence'] ?? 'N/A'),
          _buildProfileRow('Agence', _expertData?['agenceNom'] ?? 'N/A'),
          _buildProfileRow('Compagnie', _expertData?['compagnieNom'] ?? 'N/A'),
        ],
      ),
    );
  }

  /// 🔧 Carte spécialités
  Widget _buildSpecialitiesCard() {
    final specialites = List<String>.from(_expertData?['specialites'] ?? []);

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spécialités',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          if (specialites.isEmpty)
            const Text(
              'Aucune spécialité définie',
              style: TextStyle(color: Color(0xFF64748B)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: specialites.map((specialite) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  specialite,
                  style: const TextStyle(
                    color: Color(0xFF667EEA),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }

  /// 🗺️ Carte zones d'intervention
  Widget _buildZonesCard() {
    final zones = List<String>.from(_expertData?['gouvernoratsIntervention'] ?? []);

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Zones d\'Intervention',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          if (zones.isEmpty)
            const Text(
              'Aucune zone définie',
              style: TextStyle(color: Color(0xFF64748B)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: zones.map((zone) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  zone,
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }

  /// 📝 Ligne de profil
  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📅 Formater la date
  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';

    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is String) {
      dateTime = DateTime.tryParse(date) ?? DateTime.now();
    } else {
      return 'N/A';
    }

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  /// 📋 Obtenir le texte du statut de mission
  String _getMissionStatusText(String? statut) {
    switch (statut) {
      case 'assignee':
        return 'Assignée';
      case 'en_cours':
        return 'En cours';
      case 'terminee':
        return 'Terminée';
      case 'annulee':
        return 'Annulée';
      default:
        return 'Inconnu';
    }
  }

  /// ▶️ Commencer une mission
  void _startMission(Map<String, dynamic> mission) async {
    try {
      await FirebaseFirestore.instance
          .collection('missions_expertise')
          .doc(mission['id'])
          .update({
        'statut': 'en_cours',
        'dateIntervention': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _loadMissions();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mission commencée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors du démarrage de la mission'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 📝 Mettre à jour le progrès de la mission
  void _updateMissionProgress(Map<String, dynamic> mission) {
    // TODO: Implémenter l'interface de mise à jour du progrès
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mise à jour du progrès - À implémenter'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// ✅ Terminer une mission
  void _completeMission(Map<String, dynamic> mission) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer la mission'),
        content: const Text('Êtes-vous sûr de vouloir marquer cette mission comme terminée ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('missions_expertise')
            .doc(mission['id'])
            .update({
          'statut': 'terminee',
          'dateCompletion': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Libérer l'expert
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'isDisponible': true,
            'expertisesEnCours': FieldValue.increment(-1),
            'nombreExpertises': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          await FirebaseFirestore.instance
              .collection('experts')
              .doc(user.uid)
              .update({
            'isDisponible': true,
            'expertisesEnCours': FieldValue.increment(-1),
            'nombreExpertises': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        _loadExpertData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mission terminée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la finalisation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 👁️ Afficher les détails de la mission
  void _showMissionDetails(Map<String, dynamic> mission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails Mission ${mission['id']?.substring(0, 8) ?? 'N/A'}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Statut', _getMissionStatusText(mission['statut'])),
              _buildDetailRow('Date assignation', _formatDate(mission['dateAssignation'])),
              _buildDetailRow('Échéance', _formatDate(mission['dateEcheance'])),
              if (mission['dateIntervention'] != null)
                _buildDetailRow('Date intervention', _formatDate(mission['dateIntervention'])),
              if (mission['sinistreInfo'] != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Informations Sinistre:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                _buildDetailRow('Numéro', mission['sinistreInfo']['numeroSinistre'] ?? 'N/A'),
                _buildDetailRow('Type', mission['sinistreInfo']['typeAccident'] ?? 'N/A'),
                _buildDetailRow('Lieu', mission['sinistreInfo']['lieuAccident'] ?? 'N/A'),
                _buildDetailRow('Date accident', _formatDate(mission['sinistreInfo']['dateAccident'])),
              ],
              if (mission['commentaireAssignation'] != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Commentaire', mission['commentaireAssignation']),
              ],
            ],
          ),
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

  /// 📝 Ligne de détail
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  /// 📋 Élément de résumé de mission
  Widget _buildMissionSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  /// 📄 Carte de prévisualisation de mission
  Widget _buildMissionPreviewCard(Map<String, dynamic> mission) {
    final statut = mission['statut'] ?? 'assignee';
    final numeroConstat = mission['numeroConstat'] ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(statut).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(statut),
              color: _getStatusColor(statut),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Constat N° $numeroConstat',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusLabel(statut),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(statut),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: () => _openMissionDetails(mission),
          ),
        ],
      ),
    );
  }

  /// 🎨 Couleur du statut
  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'assignee':
        return const Color(0xFFF59E0B);
      case 'en_cours':
        return const Color(0xFF3B82F6);
      case 'terminee':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  /// 🎨 Icône du statut
  IconData _getStatusIcon(String statut) {
    switch (statut) {
      case 'assignee':
        return Icons.schedule;
      case 'en_cours':
        return Icons.work;
      case 'terminee':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  /// 🏷️ Label du statut
  String _getStatusLabel(String statut) {
    switch (statut) {
      case 'assignee':
        return 'En attente';
      case 'en_cours':
        return 'En cours';
      case 'terminee':
        return 'Terminée';
      default:
        return 'Inconnu';
    }
  }

  /// 📋 Ouvrir l'écran des missions
  void _openMissionsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MissionsExpertScreen(
          expertId: _expertData?['id'] ?? _expertData?['uid'] ?? '',
          expertData: _expertData,
        ),
      ),
    );
  }

  /// 📋 Ouvrir les détails de la mission
  void _openMissionDetails(Map<String, dynamic> mission) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MissionDetailsScreen(
          mission: mission,
          expertData: _expertData,
        ),
      ),
    );
  }
}
