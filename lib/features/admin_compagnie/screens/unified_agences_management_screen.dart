import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/admin_compagnie_agence_service.dart';
import '../widgets/real_time_sync_indicator.dart';
import 'create_agence_only_screen.dart';
import 'edit_agence_screen.dart';
import 'agence_details_screen.dart';

/// 🏢 Gestion Unifiée des Agences - Vue Complète et Propre
class UnifiedAgencesManagementScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const UnifiedAgencesManagementScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<UnifiedAgencesManagementScreen> createState() => _UnifiedAgencesManagementScreenState();
}

class _UnifiedAgencesManagementScreenState extends State<UnifiedAgencesManagementScreen> {
  List<Map<String, dynamic>> _agences = [];
  Map<String, Map<String, dynamic>> _agencesStats = {};
  bool _isLoading = true;
  String _searchQuery = '';
  DateTime? _lastUpdate;
  bool _isConnected = true;

  // Statistiques globales
  int _totalAgences = 0;
  int _totalAgents = 0;
  int _totalActiveAgents = 0;
  int _totalAdmins = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  /// 📊 Charger toutes les données de manière unifiée
  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('[UNIFIED_AGENCES] 🔄 Chargement données pour compagnie: ${widget.userData['compagnieId']}');

      // Récupérer toutes les agences
      final agencesQuery = await FirebaseFirestore.instance
          .collection('agences')
          .where('compagnieId', isEqualTo: widget.userData['compagnieId'])
          .get();

      List<Map<String, dynamic>> agences = [];
      Map<String, Map<String, dynamic>> stats = {};
      
      int totalAgents = 0;
      int totalActiveAgents = 0;
      int totalAdmins = 0;

      // Pour chaque agence, récupérer ses statistiques
      for (var doc in agencesQuery.docs) {
        final agenceData = doc.data();
        agenceData['id'] = doc.id;
        agences.add(agenceData);

        // Récupérer les agents de cette agence
        final agentsQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'agent')
            .where('agenceId', isEqualTo: doc.id)
            .get();

        final agenceAgents = agentsQuery.docs.length;
        final agenceActiveAgents = agentsQuery.docs.where((doc) => doc.data()['isActive'] == true).length;

        // Récupérer les admins de cette agence
        final adminsQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'admin_agence')
            .where('agenceId', isEqualTo: doc.id)
            .get();

        final agenceAdmins = adminsQuery.docs.length;

        // Statistiques de l'agence
        stats[doc.id] = {
          'totalAgents': agenceAgents,
          'activeAgents': agenceActiveAgents,
          'inactiveAgents': agenceAgents - agenceActiveAgents,
          'totalAdmins': agenceAdmins,
          'lastUpdate': DateTime.now(),
        };

        // Ajouter aux totaux
        totalAgents += agenceAgents;
        totalActiveAgents += agenceActiveAgents;
        totalAdmins += agenceAdmins;

        debugPrint('[UNIFIED_AGENCES] 🏢 ${agenceData['nom']}: $agenceAgents agents, $agenceAdmins admins');
      }

      setState(() {
        _agences = agences;
        _agencesStats = stats;
        _totalAgences = agences.length;
        _totalAgents = totalAgents;
        _totalActiveAgents = totalActiveAgents;
        _totalAdmins = totalAdmins;
        _isLoading = false;
        _lastUpdate = DateTime.now();
        _isConnected = true;
      });

      debugPrint('[UNIFIED_AGENCES] ✅ Chargement terminé: $_totalAgences agences, $_totalAgents agents');

    } catch (e) {
      debugPrint('[UNIFIED_AGENCES] ❌ Erreur chargement: $e');
      setState(() {
        _isLoading = false;
        _isConnected = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header avec synchronisation et statistiques globales
          _buildUnifiedHeader(),
          
          // Barre de recherche et actions
          _buildSearchAndActions(),
          
          // Liste des agences
          Expanded(
            child: _isLoading ? _buildLoadingScreen() : _buildAgencesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewAgence,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Nouvelle Agence'),
        backgroundColor: const Color(0xFF059669),
      ),
    );
  }

  /// 📊 Header unifié avec stats et synchronisation
  Widget _buildUnifiedHeader() {
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
        children: [
          // Titre et synchronisation
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Gestion des Agences',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              RealTimeSyncIndicator(
                isConnected: _isConnected,
                lastUpdate: _lastUpdate,
                onRefresh: _loadAllData,
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Statistiques globales
          Row(
            children: [
              Expanded(child: _buildStatCard('Agences', _totalAgences.toString(), Icons.business_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Total Agents', _totalAgents.toString(), Icons.people_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Agents Actifs', _totalActiveAgents.toString(), Icons.person_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Admins', _totalAdmins.toString(), Icons.admin_panel_settings_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  /// 📈 Carte de statistique
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 10,
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

  /// 🔍 Barre de recherche et actions
  Widget _buildSearchAndActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
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
            ),
          ),
          const SizedBox(width: 12),
          Container(
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
            child: IconButton(
              onPressed: _loadAllData,
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF667EEA)),
              tooltip: 'Actualiser',
            ),
          ),
        ],
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

  /// 📋 Liste des agences avec CRUDs intégrés
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
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _createNewAgence,
              icon: const Icon(Icons.add_business_rounded),
              label: const Text('Créer la première agence'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
              ),
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

  /// 🏢 Carte d'agence unifiée avec stats et actions
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
          // En-tête avec informations principales
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
                          Icon(Icons.info_outline, size: 18, color: Color(0xFF3B82F6)),
                          SizedBox(width: 8),
                          Text('Détails'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 18, color: Color(0xFF059669)),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'agents',
                      child: Row(
                        children: [
                          Icon(Icons.people_outline, size: 18, color: Color(0xFF8B5CF6)),
                          SizedBox(width: 8),
                          Text('Gérer agents'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Supprimer', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Statistiques en temps réel
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Agents',
                    totalAgents.toString(),
                    Icons.people_rounded,
                    const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    'Agents Actifs',
                    activeAgents.toString(),
                    Icons.person_rounded,
                    const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 12),
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
          ),
        ],
      ),
    );
  }

  /// 📊 Item de statistique dans la carte
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
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
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

  /// 🎯 Gérer les actions sur les agences
  void _handleAgenceAction(String action, Map<String, dynamic> agence) {
    switch (action) {
      case 'details':
        _viewAgenceDetails(agence);
        break;
      case 'edit':
        _editAgence(agence);
        break;
      case 'agents':
        _manageAgents(agence);
        break;
      case 'delete':
        _deleteAgence(agence);
        break;
    }
  }

  /// 👁️ Voir les détails d'une agence
  void _viewAgenceDetails(Map<String, dynamic> agence) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgenceDetailsScreen(
          agenceData: agence,
          userData: widget.userData,
        ),
      ),
    );
  }

  /// ✏️ Modifier une agence
  void _editAgence(Map<String, dynamic> agence) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAgenceScreen(
          agenceData: agence,
          userData: widget.userData,
        ),
      ),
    );

    if (result == true) {
      _loadAllData(); // Recharger les données après modification
    }
  }

  /// 👥 Gérer les agents d'une agence
  void _manageAgents(Map<String, dynamic> agence) {
    // TODO: Naviguer vers l'écran de gestion des agents
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gestion des agents pour ${agence['nom']}'),
        backgroundColor: const Color(0xFF8B5CF6),
      ),
    );
  }

  /// ➕ Créer une nouvelle agence
  void _createNewAgence() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateAgenceOnlyScreen(
          userData: widget.userData,
        ),
      ),
    );

    if (result == true) {
      _loadAllData(); // Recharger les données après création
    }
  }

  /// 🗑️ Supprimer une agence
  void _deleteAgence(Map<String, dynamic> agence) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_rounded, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Confirmer la suppression'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Êtes-vous sûr de vouloir supprimer l\'agence "${agence['nom']}" ?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cette action supprimera également tous les agents associés.',
                      style: TextStyle(fontSize: 13, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => _confirmDeleteAgence(agence),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  /// ✅ Confirmer la suppression
  void _confirmDeleteAgence(Map<String, dynamic> agence) async {
    Navigator.pop(context); // Fermer le dialog

    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Supprimer l'agence via Firestore directement
      await FirebaseFirestore.instance.collection('agences').doc(agence['id']).delete();

      Navigator.pop(context); // Fermer l'indicateur de chargement

      // Recharger les données
      await _loadAllData();

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Agence "${agence['nom']}" supprimée avec succès'),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );

    } catch (e) {
      Navigator.pop(context); // Fermer l'indicateur de chargement

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
