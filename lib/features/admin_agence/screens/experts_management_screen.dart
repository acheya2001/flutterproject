import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/admin_agence_expert_service.dart';
import 'create_expert_screen.dart';

/// 🔧 Écran de gestion des experts pour Admin Agence
class ExpertsManagementScreen extends StatefulWidget {
  final Map<String, dynamic> agenceData;
  final Map<String, dynamic> userData;
  final VoidCallback? onExpertUpdated;

  const ExpertsManagementScreen({
    Key? key,
    required this.agenceData,
    required this.userData,
    this.onExpertUpdated,
  }) : super(key: key);

  @override
  State<ExpertsManagementScreen> createState() => _ExpertsManagementScreenState();
}

class _ExpertsManagementScreenState extends State<ExpertsManagementScreen> {
  List<Map<String, dynamic>> _experts = [];
  List<Map<String, dynamic>> _filteredExperts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _specialiteFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadExperts();
  }

  /// 📋 Charger les experts
  Future<void> _loadExperts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final experts = await AdminAgenceExpertService.getAgenceExperts(widget.agenceData['id']);
      if (!mounted) return;
      setState(() {
        _experts = experts;
        _filteredExperts = experts;
      });
    } catch (e) {
      debugPrint('[EXPERTS_MANAGEMENT] ❌ Erreur chargement experts: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  /// 🔍 Filtrer les experts
  void _filterExperts() {
    setState(() {
      _filteredExperts = _experts.where((expert) {
        // Filtre par recherche
        final searchMatch = _searchQuery.isEmpty ||
            expert['prenom'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
            expert['nom'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
            expert['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
            expert['codeExpert'].toString().toLowerCase().contains(_searchQuery.toLowerCase());

        // Filtre par statut
        final statusMatch = _statusFilter == 'all' ||
            (_statusFilter == 'actif' && expert['isActive'] == true) ||
            (_statusFilter == 'inactif' && expert['isActive'] == false) ||
            (_statusFilter == 'disponible' && expert['isDisponible'] == true) ||
            (_statusFilter == 'occupe' && expert['isDisponible'] == false);

        // Filtre par spécialité
        final specialiteMatch = _specialiteFilter == 'all' ||
            (expert['specialites'] as List<dynamic>?)?.contains(_specialiteFilter) == true;

        return searchMatch && statusMatch && specialiteMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredExperts.isEmpty
                    ? _buildEmptyState()
                    : _buildExpertsList(),
          ),
        ],
      ),
    );
  }

  /// 📋 En-tête
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestion des Experts',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_filteredExperts.length} expert(s) • ${widget.agenceData['nom']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _createNewExpert,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Nouvel Expert'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔍 Filtres
  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            onChanged: (value) {
              _searchQuery = value;
              _filterExperts();
            },
            decoration: InputDecoration(
              hintText: 'Rechercher un expert...',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF667EEA)),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
          ),
          const SizedBox(height: 16),
          // Filtres par statut et spécialité
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _statusFilter,
                  decoration: InputDecoration(
                    labelText: 'Statut',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    isDense: true,
                  ),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tous', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: 'actif', child: Text('Actifs', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: 'inactif', child: Text('Inactifs', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: 'disponible', child: Text('Disponibles', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: 'occupe', child: Text('Occupés', style: TextStyle(fontSize: 13))),
                  ],
                  onChanged: (value) {
                    setState(() => _statusFilter = value!);
                    _filterExperts();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _specialiteFilter,
                  decoration: InputDecoration(
                    labelText: 'Spécialité',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    isDense: true,
                  ),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Toutes', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: 'automobile', child: Text('Auto', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: 'incendie', child: Text('Incendie', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: 'vol', child: Text('Vol', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: 'degats_eaux', child: Text('Dégâts eaux', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: 'bris_glace', child: Text('Bris glace', style: TextStyle(fontSize: 13))),
                  ],
                  onChanged: (value) {
                    setState(() => _specialiteFilter = value!);
                    _filterExperts();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📋 Liste des experts
  Widget _buildExpertsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredExperts.length,
      itemBuilder: (context, index) {
        final expert = _filteredExperts[index];
        return _buildExpertCard(expert);
      },
    );
  }

  /// 🎴 Carte d'expert
  Widget _buildExpertCard(Map<String, dynamic> expert) {
    final isActive = expert['isActive'] ?? false;
    final isDisponible = expert['isDisponible'] ?? false;
    final specialites = List<String>.from(expert['specialites'] ?? []);
    final nombreExpertises = expert['nombreExpertises'] ?? 0;
    final expertisesEnCours = expert['expertisesEnCours'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF667EEA),
                  child: Text(
                    '${expert['prenom']?[0] ?? ''}${expert['nom']?[0] ?? ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Informations principales
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${expert['prenom']} ${expert['nom']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        expert['codeExpert'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Statuts
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.shade100 : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isActive ? 'Actif' : 'Inactif',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDisponible ? Colors.blue.shade100 : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isDisponible ? 'Disponible' : 'Occupé',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isDisponible ? Colors.blue.shade700 : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Spécialités
            if (specialites.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: specialites.map((specialite) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    specialite,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF667EEA),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 12),
            ],
            // Statistiques et actions
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.assignment_turned_in, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 2),
                          Text(
                            '$nombreExpertises',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pending_actions, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 2),
                          Text(
                            '$expertisesEnCours',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleExpertAction(value, expert),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: isDisponible ? 'set_busy' : 'set_available',
                      child: Row(
                        children: [
                          Icon(isDisponible ? Icons.block : Icons.check_circle, size: 16),
                          const SizedBox(width: 8),
                          Text(isDisponible ? 'Marquer occupé' : 'Marquer disponible'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Supprimer', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 📭 État vide
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.engineering_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _statusFilter != 'all' || _specialiteFilter != 'all'
                ? 'Aucun expert trouvé'
                : 'Aucun expert créé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _statusFilter != 'all' || _specialiteFilter != 'all'
                ? 'Essayez de modifier vos critères de recherche'
                : 'Utilisez le bouton ci-dessus pour créer votre premier expert',
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

  /// ➕ Créer un nouvel expert
  void _createNewExpert() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateExpertScreen(
          agenceData: widget.agenceData,
        ),
      ),
    );

    if (result == true) {
      _loadExperts(); // Recharger la liste
      widget.onExpertUpdated?.call(); // Rafraîchir le dashboard
    }
  }

  /// ⚡ Gérer les actions sur un expert
  void _handleExpertAction(String action, Map<String, dynamic> expert) async {
    switch (action) {
      case 'edit':
        // TODO: Implémenter l'édition d'expert
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Édition d\'expert - À implémenter')),
        );
        break;
      case 'set_available':
        await _updateExpertAvailability(expert['id'], true);
        break;
      case 'set_busy':
        await _updateExpertAvailability(expert['id'], false);
        break;
      case 'delete':
        await _deleteExpert(expert);
        break;
    }
  }

  /// 🔄 Mettre à jour la disponibilité d'un expert
  Future<void> _updateExpertAvailability(String expertId, bool isDisponible) async {
    try {
      await AdminAgenceExpertService.updateExpert(
        expertId: expertId,
        updateData: {'isDisponible': isDisponible},
      );
      _loadExperts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Expert ${isDisponible ? 'disponible' : 'occupé'}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la mise à jour'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🗑️ Supprimer un expert
  Future<void> _deleteExpert(Map<String, dynamic> expert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer l\'expert ${expert['prenom']} ${expert['nom']} ?'),
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
      try {
        await AdminAgenceExpertService.deleteExpert(expert['id'], widget.agenceData['id']);
        _loadExperts();
        widget.onExpertUpdated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expert supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la suppression'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
