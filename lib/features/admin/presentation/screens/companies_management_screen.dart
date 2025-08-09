import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/insurance_company.dart';
import '../../../../services/insurance_company_service.dart';
import '../../../../services/direct_admin_sync_service.dart';
import '../../../../services/super_admin_hierarchy_service.dart';
import 'company_form_screen.dart';
import 'company_details_screen.dart';
import 'super_admin_company_form.dart';
import 'admin_compagnie_creation_screen.dart';
import '../widgets/delete_confirmation_dialog.dart';

/// 🏢 Écran de gestion des compagnies d'assurance
class CompaniesManagementScreen extends StatefulWidget {
  const CompaniesManagementScreen({Key? key}) : super(key: key);

  @override
  State<CompaniesManagementScreen> createState() => _CompaniesManagementScreenState();
}

class _CompaniesManagementScreenState extends State<CompaniesManagementScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, active, inactive
  List<Map<String, dynamic>> _companiesWithAgencies = []; // Données hiérarchiques
  bool _isLoading = true;
  Set<String> _expandedCompanies = {}; // Pour gérer l'expansion des compagnies

  // 🎨 Palette de couleurs modernes et élégantes
  final List<List<Color>> _colorPalettes = [
    [const Color(0xFF6366F1), const Color(0xFF4F46E5)], // Indigo
    [const Color(0xFF10B981), const Color(0xFF059669)], // Emerald
    [const Color(0xFFF59E0B), const Color(0xFFD97706)], // Amber
    [const Color(0xFFEF4444), const Color(0xFFDC2626)], // Red
    [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)], // Violet
    [const Color(0xFF06B6D4), const Color(0xFF0891B2)], // Cyan
    [const Color(0xFFF97316), const Color(0xFFEA580C)], // Orange
    [const Color(0xFFEC4899), const Color(0xFFDB2777)], // Pink
    [const Color(0xFF84CC16), const Color(0xFF65A30D)], // Lime
    [const Color(0xFF6B7280), const Color(0xFF4B5563)], // Gray
  ];

  @override
  void initState() {
    super.initState();
    _loadCompaniesWithAgencies();
  }

  /// 🎨 Obtenir la couleur unique d'une compagnie
  List<Color> _getCompanyColors(String companyId) {
    // Utiliser le hash du companyId pour obtenir un index stable
    final hash = companyId.hashCode.abs();
    final index = hash % _colorPalettes.length;
    return _colorPalettes[index];
  }

  /// 📊 Charger les compagnies avec leurs agences
  Future<void> _loadCompaniesWithAgencies() async {
    setState(() => _isLoading = true);

    try {
      final hierarchy = await SuperAdminHierarchyService.getCompleteHierarchy();
      setState(() {
        _companiesWithAgencies = hierarchy;
      });

      debugPrint('🏢 Compagnies avec agences chargées: ${_companiesWithAgencies.length}');
      for (var compagnie in _companiesWithAgencies) {
        final agences = compagnie['agences'] as List<Map<String, dynamic>>? ?? [];
        debugPrint('  - ${compagnie['nom']}: ${agences.length} agences');
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement compagnies: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Gestion des Compagnies',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'add_codes') {
                _addCodesToExistingCompanies();
              } else if (value == 'add_company') {
                _showAddCompanyDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_company',
                child: Row(
                  children: [
                    Icon(Icons.add_business, size: 18, color: Color(0xFF3B82F6)),
                    SizedBox(width: 8),
                    Text('Ajouter une compagnie'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'add_codes',
                child: Row(
                  children: [
                    Icon(Icons.qr_code, size: 18, color: Color(0xFFF59E0B)),
                    SizedBox(width: 8),
                    Text('Ajouter codes aux existantes'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres et recherche
          _buildFiltersSection(),
          
          // Liste des compagnies
          Expanded(
            child: _buildCompaniesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Rechercher une compagnie...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Filtres de statut
          Row(
            children: [
              const Text(
                'Statut:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Toutes', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Actives', 'active'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Inactives', 'inactive'),
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

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => setState(() => _statusFilter = value),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF3B82F6).withOpacity(0.1),
      checkmarkColor: const Color(0xFF3B82F6),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildCompaniesList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            ),
            SizedBox(height: 16),
            Text('Chargement des compagnies et agences...'),
          ],
        ),
      );
    }

    if (_companiesWithAgencies.isEmpty) {
      return _buildEmptyState();
    }

    // 🔍 Appliquer le filtrage par statut et recherche
    final filteredCompanies = _companiesWithAgencies.where((compagnie) {
      final isActive = compagnie['isActive'] ?? true;
      final nom = (compagnie['nom'] ?? '').toLowerCase();
      final code = (compagnie['code'] ?? '').toLowerCase();
      final email = (compagnie['email'] ?? '').toLowerCase();

      // Filtrage par statut
      bool matchesStatus = true;
      if (_statusFilter == 'active') {
        matchesStatus = isActive;
      } else if (_statusFilter == 'inactive') {
        matchesStatus = !isActive;
      }

      // Filtrage par recherche
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        matchesSearch = nom.contains(query) ||
                      code.contains(query) ||
                      email.contains(query);
      }

      return matchesStatus && matchesSearch;
    }).toList();

    if (filteredCompanies.isEmpty) {
      return _buildNoResultsState();
    }

    return RefreshIndicator(
      onRefresh: _loadCompaniesWithAgencies,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredCompanies.length,
        itemBuilder: (context, index) {
          final compagnie = filteredCompanies[index];
          return _buildCompagnieCardWithAgencies(compagnie);
        },
      ),
    );
  }

  /// 📭 État vide
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.business_outlined,
            size: 64,
            color: Color(0xFF64748B),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune compagnie trouvée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez votre première compagnie',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddCompanyDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une compagnie'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔍 État aucun résultat de filtrage
  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Color(0xFF64748B),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun résultat trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _statusFilter == 'active'
                ? 'Aucune compagnie active trouvée'
                : _statusFilter == 'inactive'
                    ? 'Aucune compagnie inactive trouvée'
                    : 'Aucune compagnie ne correspond à votre recherche',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _statusFilter = 'all';
              });
            },
            icon: const Icon(Icons.clear_all_rounded),
            label: const Text('Effacer les filtres'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B7280),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 🏢 Carte de compagnie moderne avec ses agences
  Widget _buildCompagnieCardWithAgencies(Map<String, dynamic> compagnie) {
    final compagnieId = compagnie['id'];
    final isExpanded = _expandedCompanies.contains(compagnieId);
    final agences = compagnie['agences'] as List<Map<String, dynamic>>? ?? [];
    final stats = compagnie['stats'] as Map<String, dynamic>? ?? {};
    final isActive = compagnie['isActive'] ?? true;
    final companyColors = _getCompanyColors(compagnieId); // Couleurs uniques

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
            color: companyColors[0].withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête moderne de la compagnie
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: companyColors,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Première ligne : Nom + Statut
                Row(
                  children: [
                    // Icône et nom
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.business_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Nom de la compagnie (plus visible)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            compagnie['nom'] ?? 'Nom non défini',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Code: ${compagnie['code'] ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Statut à l'extrémité droite
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: (isActive ? Colors.green : Colors.red).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isActive ? 'ACTIF' : 'INACTIF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Actions modernes (deuxième ligne)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Voir détails
                    _buildActionButton(
                      icon: Icons.visibility_rounded,
                      color: Colors.blue,
                      onPressed: () => _showCompagnieDetails(compagnie),
                      tooltip: 'Voir détails',
                    ),
                    const SizedBox(width: 12),

                    // Modifier
                    _buildActionButton(
                      icon: Icons.edit_rounded,
                      color: Colors.orange,
                      onPressed: () => _editCompagnie(compagnie),
                      tooltip: 'Modifier',
                    ),
                    const SizedBox(width: 12),

                    // Activer/Désactiver
                    _buildActionButton(
                      icon: isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                      color: isActive ? Colors.green : Colors.grey,
                      onPressed: () => _toggleCompagnieStatus(compagnie),
                      tooltip: isActive ? 'Désactiver' : 'Activer',
                    ),
                    const SizedBox(width: 12),

                    // Supprimer
                    _buildActionButton(
                      icon: Icons.delete_rounded,
                      color: Colors.red,
                      onPressed: () => _deleteCompagnie(compagnie),
                      tooltip: 'Supprimer',
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Statistiques modernes
                Row(
                  children: [
                    Expanded(
                      child: _buildModernStat(
                        'Agences',
                        stats['totalAgences']?.toString() ?? '0',
                        Icons.store_rounded,
                        Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModernStat(
                        'Avec Admin',
                        stats['agencesAvecAdmin']?.toString() ?? '0',
                        Icons.admin_panel_settings_rounded,
                        Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModernStat(
                        'Agents',
                        stats['totalAgents']?.toString() ?? '0',
                        Icons.people_rounded,
                        Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Bouton Voir agences moderne
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedCompanies.remove(compagnieId);
                        } else {
                          _expandedCompanies.add(compagnieId);
                        }
                      });
                    },
                    icon: Icon(
                      isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      size: 20,
                    ),
                    label: Text(
                      isExpanded ? 'Masquer les agences' : 'Voir les agences (${agences.length})',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: companyColors[0],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Section des agences moderne (expandable)
          if (isExpanded) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête moderne des agences
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF059669).withOpacity(0.1),
                          const Color(0xFF10B981).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF059669).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.store_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Agences de ${compagnie['nom']}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF059669),
                                ),
                              ),
                              Text(
                                '${agences.length} agence${agences.length > 1 ? 's' : ''} trouvée${agences.length > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (agences.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${agences.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (agences.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Aucune agence créée pour cette compagnie',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ...agences.map((agence) => _buildAgenceItem(agence)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 🎯 Bouton d'action moderne
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  /// 📊 Statistique moderne
  Widget _buildModernStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 🏪 Item d'agence avec admin
  Widget _buildAgenceItem(Map<String, dynamic> agence) {
    final adminAgence = agence['adminAgence'] as Map<String, dynamic>?;
    final hasAdmin = adminAgence != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête agence
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasAdmin ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.store_rounded,
                  color: hasAdmin ? Colors.green : Colors.orange,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agence['nom'] ?? 'Nom non défini',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'Code: ${agence['code'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasAdmin ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasAdmin ? 'AVEC ADMIN' : 'SANS ADMIN',
                  style: TextStyle(
                    color: hasAdmin ? Colors.green : Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Informations de l'agence
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAgenceInfo('📍 Adresse', agence['adresse'] ?? 'Non définie'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAgenceInfo('📧 Email', agence['emailContact'] ?? 'Non défini'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildAgenceInfo('📞 Téléphone', agence['telephone'] ?? 'Non défini'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAgenceInfo('🗺️ Gouvernorat', agence['gouvernorat'] ?? 'Non défini'),
              ),
            ],
          ),

          // Admin agence si présent
          if (hasAdmin) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.admin_panel_settings_rounded, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Admin Agence Affecté',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.green.withOpacity(0.1),
                        child: Text(
                          '${adminAgence!['prenom']?[0] ?? ''}${adminAgence['nom']?[0] ?? ''}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${adminAgence['prenom'] ?? ''} ${adminAgence['nom'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              adminAgence['email'] ?? 'Email non défini',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (adminAgence['telephone'] != null)
                              Text(
                                adminAgence['telephone'],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        adminAgence['isActive'] == true ? Icons.check_circle : Icons.cancel,
                        color: adminAgence['isActive'] == true ? Colors.green : Colors.red,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 📋 Information d'agence
  Widget _buildAgenceInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF1F2937),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildCompanyCard(InsuranceCompany company) {
    final isActive = company.status == 'active';

    // Couleurs dynamiques selon le type et statut
    final Color primaryColor = _getCompanyColor(company.nom);
    final Color backgroundColor = isActive
        ? primaryColor.withOpacity(0.05)
        : Colors.grey.withOpacity(0.05);
    final Color borderColor = isActive
        ? primaryColor.withOpacity(0.2)
        : Colors.grey.withOpacity(0.2);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToCompanyDetails(company),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Logo/Icône amélioré
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor,
                            primaryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.business_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Nom et informations
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.nom,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isActive ? const Color(0xFF1E293B) : Colors.grey.shade600,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              // Statut avec design amélioré
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isActive ? 'Active' : 'Inactive',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Type avec design amélioré
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: company.type == 'Takaful'
                                      ? const Color(0xFF8B5CF6)
                                      : const Color(0xFF3B82F6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  company.type,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Menu actions moderne
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: PopupMenuButton<String>(
                        onSelected: (value) => _handleCompanyAction(value, company),
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: primaryColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility_rounded, size: 18, color: primaryColor),
                                const SizedBox(width: 12),
                                const Text('Voir détails', style: TextStyle(fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, size: 18, color: Colors.orange.shade600),
                                const SizedBox(width: 12),
                                const Text('Modifier', style: TextStyle(fontWeight: FontWeight.w500)),
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
                                  color: isActive ? Colors.red.shade600 : Colors.green.shade600,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  isActive ? 'Désactiver' : 'Activer',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_rounded, size: 18, color: Colors.red.shade600),
                                const SizedBox(width: 12),
                                Text(
                                  'Supprimer',
                                  style: TextStyle(
                                    color: Colors.red.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Informations de contact avec design amélioré
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(Icons.email_rounded, company.email, primaryColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInfoItem(Icons.phone_rounded, company.telephone, primaryColor),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(Icons.location_on_rounded, company.adresse, primaryColor),
                          ),
                          if (company.code != null) ...[
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryColor, primaryColor.withOpacity(0.8)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Code: ${company.code}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Admin assigné avec design amélioré
                      if (company.adminCompagnieNom != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person_rounded, color: Colors.green.shade600, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Admin: ${company.adminCompagnieNom}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🎨 Obtenir une couleur unique pour chaque compagnie
  Color _getCompanyColor(String companyName) {
    final colors = [
      const Color(0xFF3B82F6), // Bleu
      const Color(0xFF10B981), // Vert
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFF59E0B), // Orange
      const Color(0xFFEF4444), // Rouge
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF84CC16), // Lime
      const Color(0xFFEC4899), // Rose
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF14B8A6), // Teal
    ];

    final hash = companyName.hashCode;
    return colors[hash.abs() % colors.length];
  }

  /// 🔄 Actualiser les données
  void _refreshData() {
    setState(() {
      // Déclencher une reconstruction pour recharger les données
    });
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 14,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showAddCompanyDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SuperAdminCompanyForm(),
      ),
    );

    // Si une compagnie a été ajoutée, proposer d'affecter un admin
    if (result != null && result['success'] == true) {
      _showAssignAdminDialog(result);
    }
  }

  /// 👤 Proposer d'affecter un admin après ajout de compagnie
  void _showAssignAdminDialog(Map<String, dynamic> companyResult) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF059669)),
            SizedBox(width: 12),
            Text('Affecter un admin ?'),
          ],
        ),
        content: Text(
          'Compagnie "${companyResult['companyName']}" créée avec succès !\n\n'
          'Voulez-vous maintenant créer et affecter un administrateur '
          'à cette compagnie ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToAdminCreation(companyResult);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: const Text('Créer Admin'),
          ),
        ],
      ),
    );
  }

  /// 🔄 Naviguer vers la création d'admin compagnie
  void _navigateToAdminCreation(Map<String, dynamic> companyResult) {
    // Créer un objet InsuranceCompany pour pré-sélection
    final preSelectedCompany = InsuranceCompany(
      id: companyResult['companyId'],
      nom: companyResult['companyName'],
      code: companyResult['companyData']['numeroAgrement'] ?? '',
      type: companyResult['companyData']['type'] ?? 'Classique',
      email: companyResult['companyData']['email'] ?? '',
      telephone: companyResult['companyData']['telephone'] ?? '',
      adresse: companyResult['companyData']['adresse'] ?? '',
      siteWeb: companyResult['companyData']['siteWeb'],
      status: companyResult['companyData']['status'] ?? 'actif',
      adminCompagnieId: null,
      adminCompagnieNom: null,
      adminCompagnieEmail: null,
      createdAt: DateTime.now(),
      hasAdmin: false,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminCompagnieCreationScreen(
          preSelectedCompany: preSelectedCompany,
        ),
      ),
    );
  }

  void _navigateToCompanyDetails(InsuranceCompany company) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyDetailsScreen(company: company),
      ),
    );
  }

  void _handleCompanyAction(String action, InsuranceCompany company) {
    switch (action) {
      case 'view':
        _navigateToCompanyDetails(company);
        break;
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CompanyFormScreen(company: company),
          ),
        );
        break;
      case 'activate':
      case 'deactivate':
        _toggleCompanyStatus(company);
        break;
      case 'delete':
        _confirmDeleteCompany(company);
        break;
    }
  }

  void _toggleCompanyStatus(InsuranceCompany company) {
    final newStatus = company.status == 'active' ? 'inactive' : 'active';
    final actionText = newStatus == 'active' ? 'activer' : 'désactiver';

    showDialog(
      context: context,
      builder: (context) => StatusChangeDialog(
        title: '${actionText.capitalize()} la compagnie',
        content: 'Êtes-vous sûr de vouloir $actionText cette compagnie ?\n\n'
            '${newStatus == 'inactive'
                ? 'Tous les utilisateurs liés seront également désactivés.'
                : 'Les utilisateurs précédemment désactivés seront réactivés.'}',
        itemName: company.nom,
        newStatus: newStatus,
        onConfirm: () async {
          Navigator.pop(context);
          try {
            await InsuranceCompanyService.toggleCompanyStatus(
              company.id,
              newStatus,
            );

            // 🔄 SYNCHRONISATION AUTOMATIQUE ADMIN
            debugPrint('');
            debugPrint('🔄 ========== SYNCHRONISATION AUTOMATIQUE ==========');
            debugPrint('🏢 Compagnie: ${company.nom}');
            debugPrint('🆔 CompagnieId: ${company.id}');
            debugPrint('📊 Nouveau statut: $newStatus');
            debugPrint('🔄 Appel synchronisation directe...');

            try {
              final syncResult = await DirectAdminSyncService.syncCompanyToAdmin(
                compagnieId: company.id,
                newStatus: newStatus == 'active',
              );

              debugPrint('📊 RÉSULTAT SYNCHRONISATION:');
              debugPrint('✅ Success: ${syncResult['success']}');
              debugPrint('👥 Admins synchronisés: ${syncResult['adminsUpdated']}');
              debugPrint('📝 Message: ${syncResult['message']}');
              debugPrint('🔄 ========== FIN SYNCHRONISATION ==========');
              debugPrint('');

            } catch (syncError) {
              debugPrint('❌ ERREUR SYNCHRONISATION: $syncError');
            }

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Compagnie ${actionText}e avec succès + Admin synchronisé'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            debugPrint('❌ Erreur toggle company status: $e');
            // Vérifier si le widget est encore monté ET si le context est valide
            if (mounted && context.mounted) {
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (scaffoldError) {
                debugPrint('❌ Erreur ScaffoldMessenger: $scaffoldError');
              }
            }
          }
        },
      ),
    );
  }

  void _confirmDeleteCompany(InsuranceCompany company) {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        title: 'Supprimer la compagnie',
        content: 'Êtes-vous sûr de vouloir supprimer cette compagnie ?',
        itemName: company.nom,
        onConfirm: () async {
          Navigator.pop(context);
          try {
            await InsuranceCompanyService.deleteCompany(company.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Compagnie supprimée avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  /// 🔢 Ajouter des codes aux compagnies existantes
  Future<void> _addCodesToExistingCompanies() async {
    try {
      // Afficher un dialog de confirmation
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.qr_code, color: Color(0xFFF59E0B)),
              SizedBox(width: 8),
              Text('Ajouter des codes'),
            ],
          ),
          content: const Text(
            'Cette action va ajouter automatiquement des codes uniques aux compagnies qui n\'en ont pas encore.\n\nContinuer ?',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Ajout des codes en cours...'),
            ],
          ),
        ),
      );

      // Appeler le service
      await InsuranceCompanyService.addCodesToExistingCompanies();

      // Fermer le dialog de chargement
      Navigator.pop(context);

      // Actualiser les données
      _refreshData();

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Codes ajoutés avec succès !'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      // Fermer le dialog de chargement si ouvert
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 👁️ Afficher les détails d'une compagnie
  void _showCompagnieDetails(Map<String, dynamic> compagnie) {
    final agences = compagnie['agences'] as List<Map<String, dynamic>>? ?? [];
    final stats = compagnie['stats'] as Map<String, dynamic>? ?? {};
    final isActive = compagnie['isActive'] ?? true;
    final companyColors = _getCompanyColors(compagnie['id']);

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
                    colors: companyColors,
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
                      child: const Icon(Icons.business_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            compagnie['nom'] ?? 'Nom non défini',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Code: ${compagnie['code'] ?? 'N/A'}',
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
                        color: isActive ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? 'ACTIF' : 'INACTIF',
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
                      // Statistiques
                      _buildDetailSection(
                        'Statistiques',
                        Icons.analytics_rounded,
                        Colors.blue,
                        [
                          _buildDetailRow('Nombre d\'agences', stats['totalAgences']?.toString() ?? '0'),
                          _buildDetailRow('Agences avec admin', stats['agencesAvecAdmin']?.toString() ?? '0'),
                          _buildDetailRow('Total agents', stats['totalAgents']?.toString() ?? '0'),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Informations de la compagnie
                      _buildDetailSection(
                        'Informations',
                        Icons.info_rounded,
                        Colors.green,
                        [
                          _buildDetailRow('Email', compagnie['email'] ?? 'Non défini'),
                          _buildDetailRow('Téléphone', compagnie['telephone'] ?? 'Non défini'),
                          _buildDetailRow('Adresse', compagnie['adresse'] ?? 'Non définie'),
                          _buildDetailRow('Description', compagnie['description'] ?? 'Non définie'),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Liste des agences
                      _buildDetailSection(
                        'Agences (${agences.length})',
                        Icons.store_rounded,
                        Colors.orange,
                        agences.isEmpty
                            ? [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text('Aucune agence créée'),
                                ),
                              ]
                            : agences.map((agence) => _buildAgenceDetailCard(agence)).toList(),
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
                          _editCompagnie(compagnie);
                        },
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Modifier'),
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
                          _toggleCompagnieStatus(compagnie);
                        },
                        icon: Icon(isActive ? Icons.toggle_off_rounded : Icons.toggle_on_rounded),
                        label: Text(isActive ? 'Désactiver' : 'Activer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isActive ? Colors.grey : Colors.green,
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

  /// 📋 Section de détails
  Widget _buildDetailSection(String title, IconData icon, Color color, List<Widget> children) {
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
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
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

  /// 📄 Ligne de détail
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  /// 🏪 Carte d'agence dans les détails
  Widget _buildAgenceDetailCard(Map<String, dynamic> agence) {
    final adminAgence = agence['adminAgence'] as Map<String, dynamic>?;
    final hasAdmin = adminAgence != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.store_rounded,
                color: hasAdmin ? Colors.green : Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  agence['nom'] ?? 'Nom non défini',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasAdmin ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasAdmin ? 'AVEC ADMIN' : 'SANS ADMIN',
                  style: TextStyle(
                    color: hasAdmin ? Colors.green : Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Code: ${agence['code'] ?? 'N/A'} • ${agence['gouvernorat'] ?? 'Gouvernorat non défini'}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          if (hasAdmin) ...[
            const SizedBox(height: 8),
            Text(
              'Admin: ${adminAgence!['prenom'] ?? ''} ${adminAgence['nom'] ?? ''}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ✏️ Modifier une compagnie avec interface moderne
  void _editCompagnie(Map<String, dynamic> compagnie) {
    final nomController = TextEditingController(text: compagnie['nom']);
    final emailController = TextEditingController(text: compagnie['email']);
    final telephoneController = TextEditingController(text: compagnie['telephone']);
    final adresseController = TextEditingController(text: compagnie['adresse']);
    final descriptionController = TextEditingController(text: compagnie['description']);
    final codeController = TextEditingController(text: compagnie['code']);

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
              // En-tête
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
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
                      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Modifier la compagnie',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Formulaire
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildModernTextField('Nom de la compagnie', Icons.business_rounded, nomController),
                      const SizedBox(height: 16),
                      _buildModernTextField('Code', Icons.tag_rounded, codeController),
                      const SizedBox(height: 16),
                      _buildModernTextField('Email', Icons.email_rounded, emailController),
                      const SizedBox(height: 16),
                      _buildModernTextField('Téléphone', Icons.phone_rounded, telephoneController),
                      const SizedBox(height: 16),
                      _buildModernTextField('Adresse', Icons.location_on_rounded, adresseController),
                      const SizedBox(height: 16),
                      _buildModernTextField('Description', Icons.description_rounded, descriptionController, maxLines: 3),
                    ],
                  ),
                ),
              ),

              // Actions
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
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await FirebaseFirestore.instance
                                .collection('compagnies')
                                .doc(compagnie['id'])
                                .update({
                              'nom': nomController.text,
                              'code': codeController.text,
                              'email': emailController.text,
                              'telephone': telephoneController.text,
                              'adresse': adresseController.text,
                              'description': descriptionController.text,
                              'updatedAt': FieldValue.serverTimestamp(),
                            });

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Compagnie modifiée avec succès'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _loadCompaniesWithAgencies(); // Recharger
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Erreur: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Sauvegarder'),
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

  /// 📝 Champ de texte moderne
  Widget _buildModernTextField(String label, IconData icon, TextEditingController controller, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          labelStyle: TextStyle(color: Colors.grey.shade600),
        ),
      ),
    );
  }

  /// 🔄 Activer/Désactiver une compagnie ET son admin compagnie
  void _toggleCompagnieStatus(Map<String, dynamic> compagnie) async {
    final isActive = compagnie['isActive'] ?? true;
    final newStatus = !isActive;
    final compagnieId = compagnie['id'];

    try {
      debugPrint('🔄 Toggle compagnie: ${compagnie['nom']} ($compagnieId) -> $newStatus');

      // 1. Mettre à jour le statut de la compagnie
      await FirebaseFirestore.instance
          .collection('compagnies')
          .doc(compagnieId)
          .update({
        'isActive': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Compagnie mise à jour');

      // 2. Trouver et mettre à jour l'admin compagnie associé
      debugPrint('🔍 Recherche admin compagnie pour compagnieId: $compagnieId');
      final adminCompagnieQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin_compagnie')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      debugPrint('📊 ${adminCompagnieQuery.docs.length} admin(s) compagnie trouvé(s)');

      if (adminCompagnieQuery.docs.isNotEmpty) {
        // Mettre à jour tous les admins compagnie de cette compagnie
        final batch = FirebaseFirestore.instance.batch();

        for (var adminDoc in adminCompagnieQuery.docs) {
          batch.update(adminDoc.reference, {
            'isActive': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();

        debugPrint('✅ ${adminCompagnieQuery.docs.length} admin(s) compagnie mis à jour');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? '✅ Compagnie et admin(s) activés'
                : '⚠️ Compagnie et admin(s) désactivés'
          ),
          backgroundColor: newStatus ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );

      _loadCompaniesWithAgencies(); // Recharger
    } catch (e) {
      debugPrint('❌ Erreur toggle compagnie: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🗑️ Supprimer une compagnie ET ses admins compagnie
  void _deleteCompagnie(Map<String, dynamic> compagnie) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Supprimer la compagnie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Êtes-vous sûr de vouloir supprimer "${compagnie['nom']}" ?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ ATTENTION:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• La compagnie sera supprimée définitivement\n'
                    '• Tous les admins compagnie associés seront supprimés\n'
                    '• Toutes les agences seront supprimées\n'
                    '• Cette action est irréversible',
                    style: TextStyle(fontSize: 12),
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
            onPressed: () async {
              Navigator.pop(context);

              // Afficher un indicateur de chargement
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Suppression en cours...'),
                    ],
                  ),
                ),
              );

              try {
                final compagnieId = compagnie['id'];

                // 1. Supprimer tous les admins compagnie associés
                final adminCompagnieQuery = await FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'admin_compagnie')
                    .where('compagnieId', isEqualTo: compagnieId)
                    .get();

                final batch = FirebaseFirestore.instance.batch();

                for (var adminDoc in adminCompagnieQuery.docs) {
                  batch.delete(adminDoc.reference);
                }

                // 2. Supprimer toutes les agences de cette compagnie
                final agencesQuery = await FirebaseFirestore.instance
                    .collection('agences')
                    .where('compagnieId', isEqualTo: compagnieId)
                    .get();

                for (var agenceDoc in agencesQuery.docs) {
                  batch.delete(agenceDoc.reference);
                }

                // 3. Supprimer la compagnie
                batch.delete(
                  FirebaseFirestore.instance.collection('compagnies').doc(compagnieId)
                );

                await batch.commit();

                Navigator.pop(context); // Fermer le dialog de chargement

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '✅ Compagnie "${compagnie['nom']}" supprimée avec succès\n'
                      '${adminCompagnieQuery.docs.length} admin(s) et ${agencesQuery.docs.length} agence(s) supprimé(s)'
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 4),
                  ),
                );

                _loadCompaniesWithAgencies(); // Recharger
              } catch (e) {
                Navigator.pop(context); // Fermer le dialog de chargement
                debugPrint('❌ Erreur suppression compagnie: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Erreur: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer définitivement', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
