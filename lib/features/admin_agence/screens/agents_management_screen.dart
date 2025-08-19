import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/admin_agence_service.dart';
import 'create_agent_screen.dart';
import 'edit_agent_screen.dart';
import 'agent_details_screen.dart';

/// 👥 Écran de gestion des agents
class AgentsManagementScreen extends StatefulWidget {
  final Map<String, dynamic> agenceData;
  final Map<String, dynamic> userData;
  final VoidCallback? onAgentUpdated;

  const AgentsManagementScreen({
    Key? key,
    required this.agenceData,
    required this.userData,
    this.onAgentUpdated,
  }) : super(key: key);

  @override
  State<AgentsManagementScreen> createState() => _AgentsManagementScreenState();
}

class _AgentsManagementScreenState extends State<AgentsManagementScreen> {
  List<Map<String, dynamic>> _agents = [];
  List<Map<String, dynamic>> _filteredAgents = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, active, inactive

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  /// 👥 Charger les agents
  Future<void> _loadAgents() async {
    setState(() => _isLoading = true);

    try {
      final agents = await AdminAgenceService.getAgentsOfAgence(widget.agenceData['id']);
      setState(() {
        _agents = agents;
        _applyFilters();
      });
    } catch (e) {
      debugPrint('[AGENTS_MANAGEMENT] ❌ Erreur chargement agents: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🔍 Appliquer les filtres
  void _applyFilters() {
    _filteredAgents = _agents.where((agent) {
      // Filtre par recherche
      final matchesSearch = _searchQuery.isEmpty ||
          agent['nom'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          agent['prenom'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          agent['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase());

      // Filtre par statut
      final matchesStatus = _statusFilter == 'all' ||
          (_statusFilter == 'active' && agent['isActive'] == true) ||
          (_statusFilter == 'inactive' && agent['isActive'] != true);

      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Contenu principal
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _isLoading ? _buildLoadingContent() : _buildMainContent(),
                ),
              ),
            ],
          ),
        ),
      ),

    );
  }

  /// 📋 Header
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.people_rounded,
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
                  'Gestion des Agents',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_agents.length} agent(s) dans votre agence',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔄 Contenu de chargement
  Widget _buildLoadingContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF10B981)),
          SizedBox(height: 20),
          Text(
            'Chargement des agents...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 📱 Contenu principal
  Widget _buildMainContent() {
    return Column(
      children: [
        // Barre de recherche et filtres
        _buildSearchAndFilters(),

        // Bouton de création d'agent - toujours visible
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: ElevatedButton.icon(
            onPressed: _createNewAgent,
            icon: const Icon(Icons.person_add_rounded, size: 20),
            label: const Text(
              'Créer un Nouvel Agent',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Liste des agents
        Expanded(
          child: _filteredAgents.isEmpty ? _buildEmptyStateSimple() : _buildAgentsList(),
        ),
      ],
    );
  }

  /// 🔍 Barre de recherche et filtres
  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
            decoration: InputDecoration(
              hintText: 'Rechercher un agent...',
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF10B981)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 16),
          
          // Filtres par statut
          Row(
            children: [
              const Text(
                'Statut:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tous', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Actifs', 'active'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Inactifs', 'inactive'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🏷️ Chip de filtre
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _statusFilter = value;
          _applyFilters();
        });
      },
      selectedColor: const Color(0xFF10B981).withOpacity(0.2),
      checkmarkColor: const Color(0xFF10B981),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  /// 📋 Liste des agents
  Widget _buildAgentsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredAgents.length,
      itemBuilder: (context, index) {
        final agent = _filteredAgents[index];
        return _buildAgentCard(agent);
      },
    );
  }

  /// 👤 Carte d'agent
  Widget _buildAgentCard(Map<String, dynamic> agent) {
    final isActive = agent['isActive'] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showAgentDetails(agent),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isActive 
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  child: Text(
                    '${agent['prenom']?[0] ?? ''}${agent['nom']?[0] ?? ''}',
                    style: TextStyle(
                      color: isActive ? const Color(0xFF10B981) : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Informations
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${agent['prenom']} ${agent['nom']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        agent['email'] ?? 'Email non défini',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        agent['telephone'] ?? 'Téléphone non défini',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Statut et actions
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive 
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isActive ? 'Actif' : 'Inactif',
                        style: TextStyle(
                          color: isActive ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleAgentAction(value, agent),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'details',
                          child: Row(
                            children: [
                              Icon(Icons.visibility_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Voir détails'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Modifier'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'reset_password',
                          child: Row(
                            children: [
                              Icon(Icons.lock_reset_rounded, size: 18, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Réinitialiser mot de passe', style: TextStyle(color: Colors.orange)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: isActive ? 'deactivate' : 'activate',
                          child: Row(
                            children: [
                              Icon(
                                isActive ? Icons.block_rounded : Icons.check_circle_rounded,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(isActive ? 'Désactiver' : 'Activer'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Supprimer', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      child: const Icon(
                        Icons.more_vert_rounded,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  /// 📭 État vide simplifié (sans bouton)
  Widget _buildEmptyStateSimple() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isNotEmpty || _statusFilter != 'all'
                ? 'Aucun agent trouvé'
                : 'Aucun agent dans votre agence',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _statusFilter != 'all'
                ? 'Essayez de modifier vos critères de recherche'
                : 'Utilisez le bouton ci-dessus pour créer votre premier agent',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// ➕ Créer un nouvel agent
  void _createNewAgent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateAgentScreen(
          agenceData: widget.agenceData,
        ),
      ),
    );

    if (result == true) {
      _loadAgents(); // Recharger la liste
      widget.onAgentUpdated?.call(); // Rafraîchir le dashboard
    }
  }

  /// 👁️ Afficher les détails d'un agent
  void _showAgentDetails(Map<String, dynamic> agent) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgentDetailsScreen(
          agentData: agent,
          agenceData: widget.agenceData,
        ),
      ),
    );

    if (result == true) {
      _loadAgents(); // Recharger la liste si des modifications ont été faites
    }
  }

  /// 🎯 Gérer les actions sur un agent
  void _handleAgentAction(String action, Map<String, dynamic> agent) {
    switch (action) {
      case 'details':
        _showAgentDetails(agent);
        break;
      case 'edit':
        _editAgent(agent);
        break;
      case 'reset_password':
        _resetAgentPassword(agent);
        break;
      case 'activate':
      case 'deactivate':
        _toggleAgentStatus(agent);
        break;
      case 'delete':
        _deleteAgent(agent);
        break;
    }
  }

  /// ✏️ Modifier un agent
  void _editAgent(Map<String, dynamic> agent) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAgentScreen(agentData: agent),
      ),
    );

    if (result == true) {
      _loadAgents(); // Recharger la liste
      widget.onAgentUpdated?.call(); // Rafraîchir le dashboard
    }
  }

  /// 🔑 Réinitialiser le mot de passe d'un agent
  void _resetAgentPassword(Map<String, dynamic> agent) async {
    // Dialogue de confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Réinitialiser mot de passe'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voulez-vous réinitialiser le mot de passe de :'),
            const SizedBox(height: 8),
            Text(
              '${agent['prenom']} ${agent['nom']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              agent['email'],
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Un nouveau mot de passe sera généré et envoyé par email.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Réinitialiser', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _performPasswordReset(agent);
    }
  }

  /// 🔄 Effectuer la réinitialisation du mot de passe
  Future<void> _performPasswordReset(Map<String, dynamic> agent) async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Réinitialisation en cours...'),
            ],
          ),
        ),
      );

      // Générer un nouveau mot de passe
      final newPassword = _generatePassword();

      // Mettre à jour dans Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(agent['uid'])
          .update({
        'password': newPassword,
        'updatedAt': FieldValue.serverTimestamp(),
        'passwordResetAt': FieldValue.serverTimestamp(),
        'passwordResetBy': widget.userData['email'],
      });

      // Fermer le dialogue de chargement
      if (mounted) Navigator.pop(context);

      // Afficher le nouveau mot de passe
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Text('Mot de passe réinitialisé'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nouveau mot de passe généré :'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          newPassword,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // TODO: Copier dans le presse-papiers
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Mot de passe copié')),
                          );
                        },
                        icon: const Icon(Icons.copy),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Communiquez ce mot de passe à l\'agent de manière sécurisée.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      }

      // Recharger la liste
      _loadAgents();
      widget.onAgentUpdated?.call();

    } catch (e) {
      // Fermer le dialogue de chargement si ouvert
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la réinitialisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🔑 Générer un mot de passe aléatoire
  String _generatePassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return String.fromCharCodes(Iterable.generate(8, (_) => chars.codeUnitAt(random % chars.length)));
  }

  /// 🔄 Changer le statut d'un agent
  void _toggleAgentStatus(Map<String, dynamic> agent) async {
    final isActive = agent['isActive'] == true;
    final newStatus = !isActive;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${newStatus ? 'Activer' : 'Désactiver'} l\'agent'),
        content: Text(
          'Voulez-vous vraiment ${newStatus ? 'activer' : 'désactiver'} l\'agent ${agent['prenom']} ${agent['nom']} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? Colors.green : Colors.red,
            ),
            child: Text(newStatus ? 'Activer' : 'Désactiver'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await AdminAgenceService.toggleAgentStatus(
        agentId: agent['id'],
        newStatus: newStatus,
        reason: newStatus ? 'Réactivation par admin agence' : 'Désactivation par admin agence',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );

      if (result['success']) {
        _loadAgents(); // Recharger la liste
      }
    }
  }

  /// 🗑️ Supprimer un agent
  void _deleteAgent(Map<String, dynamic> agent) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'agent'),
        content: Text(
          'Voulez-vous vraiment supprimer l\'agent ${agent['prenom']} ${agent['nom']} ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await AdminAgenceService.deleteAgent(agent['id']);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );

      if (result['success']) {
        _loadAgents(); // Recharger la liste
      }
    }
  }
}
