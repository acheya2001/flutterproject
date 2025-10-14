import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../services/sinistre_expert_assignment_service.dart';
import '../../../core/theme/app_theme.dart';

/// 📋 Écran de gestion des missions pour l'expert
class MissionsExpertScreen extends StatefulWidget {
  final String expertId;
  final Map<String, dynamic>? expertData;

  const MissionsExpertScreen({
    Key? key,
    required this.expertId,
    this.expertData,
  }) : super(key: key);

  @override
  State<MissionsExpertScreen> createState() => _MissionsExpertScreenState();
}

class _MissionsExpertScreenState extends State<MissionsExpertScreen> {
  List<Map<String, dynamic>> _missions = [];
  bool _isLoading = true;
  String _selectedFilter = 'toutes';

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  /// 📋 Charger les missions
  Future<void> _loadMissions() async {
    setState(() => _isLoading = true);
    try {
      final missions = await SinistreExpertAssignmentService.getExpertMissions(widget.expertId);
      setState(() => _missions = missions);
    } catch (e) {
      debugPrint('[MISSIONS_EXPERT] ❌ Erreur chargement missions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🔍 Filtrer les missions
  List<Map<String, dynamic>> get _filteredMissions {
    switch (_selectedFilter) {
      case 'en_cours':
        return _missions.where((m) => m['statut'] == 'en_cours').toList();
      case 'terminees':
        return _missions.where((m) => m['statut'] == 'terminee').toList();
      case 'en_attente':
        return _missions.where((m) => m['statut'] == 'assignee').toList();
      default:
        return _missions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingWidget() : _buildBody(),
    );
  }

  /// 📱 AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Mes Missions'),
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
    );
  }

  /// ⏳ Widget de chargement
  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
      ),
    );
  }

  /// 📱 Corps principal
  Widget _buildBody() {
    return Column(
      children: [
        _buildFilterTabs(),
        Expanded(
          child: _filteredMissions.isEmpty
              ? _buildEmptyState()
              : _buildMissionsList(),
        ),
      ],
    );
  }

  /// 🏷️ Onglets de filtrage
  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildFilterChip('toutes', 'Toutes', Icons.list),
          const SizedBox(width: 8),
          _buildFilterChip('en_attente', 'En attente', Icons.schedule),
          const SizedBox(width: 8),
          _buildFilterChip('en_cours', 'En cours', Icons.work),
          const SizedBox(width: 8),
          _buildFilterChip('terminees', 'Terminées', Icons.check_circle),
        ],
      ),
    );
  }

  /// 🏷️ Chip de filtre
  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF667EEA) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📋 Liste des missions
  Widget _buildMissionsList() {
    return RefreshIndicator(
      onRefresh: _loadMissions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredMissions.length,
        itemBuilder: (context, index) {
          final mission = _filteredMissions[index];
          return _buildMissionCard(mission);
        },
      ),
    );
  }

  /// 📄 Carte de mission
  Widget _buildMissionCard(Map<String, dynamic> mission) {
    final statut = mission['statut'] ?? 'assignee';
    final dateAssignation = mission['dateAssignation'] as Timestamp?;
    final numeroConstat = mission['numeroConstat'] ?? 'N/A';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(statut).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusLabel(statut),
                  style: TextStyle(
                    color: _getStatusColor(statut),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: () => _openMissionDetails(mission),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Constat N° $numeroConstat',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          if (dateAssignation != null)
            Text(
              'Assigné le ${DateFormat('dd/MM/yyyy à HH:mm').format(dateAssignation.toDate())}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildActionButton(
                'Voir Détails',
                Icons.visibility,
                const Color(0xFF3B82F6),
                () => _openMissionDetails(mission),
              ),
              const SizedBox(width: 12),
              if (statut == 'assignee' || statut == 'en_cours')
                _buildActionButton(
                  'Commencer',
                  Icons.play_arrow,
                  const Color(0xFF10B981),
                  () => _startMission(mission),
                ),
            ],
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

  /// 🔘 Bouton d'action
  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// 📄 État vide
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune mission trouvée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les nouvelles missions apparaîtront ici',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Ouvrir les détails de la mission
  void _openMissionDetails(Map<String, dynamic> mission) {
    Navigator.pushNamed(
      context,
      '/expert-mission-details',
      arguments: {
        'mission': mission,
        'expertData': widget.expertData,
      },
    );
  }

  /// ▶️ Commencer une mission
  void _startMission(Map<String, dynamic> mission) {
    // TODO: Implémenter le démarrage de mission
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité en cours de développement'),
        backgroundColor: Color(0xFF667EEA),
      ),
    );
  }
}
