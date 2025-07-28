import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/super_admin_service.dart';

/// 🏢 Écran moderne de gestion des compagnies
class ModernCompagnieManagementScreen extends StatefulWidget {
  const ModernCompagnieManagementScreen({Key? key}) : super(key: key);

  @override
  State<ModernCompagnieManagementScreen> createState() => _ModernCompagnieManagementScreenState();
}

class _ModernCompagnieManagementScreenState extends State<ModernCompagnieManagementScreen> {
  List<Map<String, dynamic>> _compagnies = [];
  List<Map<String, dynamic>> _filteredCompagnies = [];
  bool _isLoading = true;
  
  // Contrôleurs de recherche et filtres
  final _searchController = TextEditingController();
  String _selectedStatut = 'Tous';
  String _selectedVille = 'Toutes';
  
  final List<String> _statutOptions = ['Tous', 'Actif', 'Inactif', 'Suspendu'];
  final List<String> _villeOptions = ['Toutes', 'Tunis', 'Sfax', 'Sousse', 'Bizerte', 'Ariana'];

  @override
  void initState() {
    super.initState();
    _loadCompagnies();
    _searchController.addListener(_filterCompagnies);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 📊 Charger les compagnies
  Future<void> _loadCompagnies() async {
    setState(() => _isLoading = true);
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('compagnies')
          .orderBy('dateCreation', descending: true)
          .get();

      _compagnies = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      _filterCompagnies();
    } catch (e) {
      debugPrint('Erreur chargement compagnies: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🔍 Filtrer les compagnies
  void _filterCompagnies() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredCompagnies = _compagnies.where((compagnie) {
        final nomMatch = compagnie['nom']?.toLowerCase().contains(query) ?? false;
        final emailMatch = compagnie['email']?.toLowerCase().contains(query) ?? false;
        final codeMatch = compagnie['code']?.toLowerCase().contains(query) ?? false;
        
        final statutMatch = _selectedStatut == 'Tous' || 
            compagnie['statut']?.toString() == _selectedStatut.toLowerCase();
        
        final villeMatch = _selectedVille == 'Toutes' || 
            compagnie['ville']?.toString() == _selectedVille;
        
        return (nomMatch || emailMatch || codeMatch) && statutMatch && villeMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildModernAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildMainContent(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// 🎨 AppBar moderne
  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      title: const Text(
        'Gestion des Compagnies',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontSize: 20,
        ),
      ),
      backgroundColor: Colors.transparent,
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
        IconButton(
          onPressed: _loadCompagnies,
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          tooltip: 'Actualiser',
        ),
        IconButton(
          onPressed: () => _showStatsDialog(),
          icon: const Icon(Icons.analytics_rounded, color: Colors.white),
          tooltip: 'Statistiques',
        ),
      ],
    );
  }

  /// ⏳ État de chargement
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
          ),
          SizedBox(height: 16),
          Text(
            'Chargement des compagnies...',
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
        
        // Statistiques rapides
        _buildQuickStats(),
        
        // Liste des compagnies
        Expanded(
          child: _filteredCompagnies.isEmpty 
              ? _buildEmptyState() 
              : _buildCompagniesList(),
        ),
      ],
    );
  }

  /// 🔍 Barre de recherche et filtres
  Widget _buildSearchAndFilters() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom, email ou code...',
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF667EEA)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _filterCompagnies();
                      },
                      icon: const Icon(Icons.clear_rounded),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          
          // Filtres
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Statut',
                  _selectedStatut,
                  _statutOptions,
                  (value) => setState(() {
                    _selectedStatut = value!;
                    _filterCompagnies();
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  'Ville',
                  _selectedVille,
                  _villeOptions,
                  (value) => setState(() {
                    _selectedVille = value!;
                    _filterCompagnies();
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📊 Statistiques rapides
  Widget _buildQuickStats() {
    final totalCompagnies = _compagnies.length;
    final actives = _compagnies.where((c) => c['statut'] == 'actif').length;
    final inactives = _compagnies.where((c) => c['statut'] == 'inactif').length;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              totalCompagnies.toString(),
              Icons.business_rounded,
              const Color(0xFF667EEA),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Actives',
              actives.toString(),
              Icons.check_circle_rounded,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Inactives',
              inactives.toString(),
              Icons.pause_circle_rounded,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Carte de statistique
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

  /// 📋 Liste des compagnies
  Widget _buildCompagniesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredCompagnies.length,
      itemBuilder: (context, index) {
        final compagnie = _filteredCompagnies[index];
        return _buildCompagnieCard(compagnie);
      },
    );
  }

  /// 🏢 Carte de compagnie moderne
  Widget _buildCompagnieCard(Map<String, dynamic> compagnie) {
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
          // En-tête avec logo et statut
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getCompagnieGradient(compagnie['statut']),
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
                // Logo/Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Nom et code
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        compagnie['nom'] ?? 'Nom non défini',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Code: ${compagnie['code'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Statut badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatutText(compagnie['statut']),
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
                // Informations principales
                _buildInfoRow(Icons.email_rounded, 'Email', compagnie['email'] ?? 'Non défini'),
                _buildInfoRow(Icons.phone_rounded, 'Téléphone', compagnie['telephone'] ?? 'Non défini'),
                _buildInfoRow(Icons.location_on_rounded, 'Adresse', compagnie['adresse'] ?? 'Non définie'),
                
                const SizedBox(height: 16),
                
                // Statistiques de la compagnie
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStat('Agences', compagnie['nombreAgences']?.toString() ?? '0'),
                    ),
                    Expanded(
                      child: _buildMiniStat('Agents', compagnie['nombreAgents']?.toString() ?? '0'),
                    ),
                    Expanded(
                      child: _buildMiniStat('Constats', compagnie['nombreConstats']?.toString() ?? '0'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showCompagnieDetails(compagnie),
                        icon: const Icon(Icons.visibility_rounded),
                        label: const Text('Détails'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF667EEA),
                          side: const BorderSide(color: Color(0xFF667EEA)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showEditCompagnieDialog(compagnie),
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Modifier'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667EEA),
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

  /// 📊 Mini statistique
  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF667EEA),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// ℹ️ Ligne d'information
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

  /// 🎨 Gradient selon le statut
  List<Color> _getCompagnieGradient(String? statut) {
    switch (statut?.toLowerCase()) {
      case 'actif':
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case 'inactif':
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case 'suspendu':
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      default:
        return [const Color(0xFF6B7280), const Color(0xFF4B5563)];
    }
  }

  /// 📝 Texte du statut
  String _getStatutText(String? statut) {
    switch (statut?.toLowerCase()) {
      case 'actif': return 'ACTIF';
      case 'inactif': return 'INACTIF';
      case 'suspendu': return 'SUSPENDU';
      default: return 'INCONNU';
    }
  }

  /// 🔽 Dropdown de filtre
  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      items: options.map((option) => DropdownMenuItem(
        value: option,
        child: Text(option),
      )).toList(),
      onChanged: onChanged,
    );
  }

  /// 📭 État vide
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_rounded,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune compagnie trouvée',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier vos filtres de recherche',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// ➕ Bouton flottant
  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showCreateCompagnieDialog(),
      backgroundColor: const Color(0xFF667EEA),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Nouvelle Compagnie'),
    );
  }

  // Actions et dialogues
  void _showStatsDialog() {
    // TODO: Implémenter les statistiques détaillées
  }

  void _showCompagnieDetails(Map<String, dynamic> compagnie) {
    // TODO: Implémenter les détails de la compagnie
  }

  void _showEditCompagnieDialog(Map<String, dynamic> compagnie) {
    // TODO: Implémenter la modification de compagnie
  }

  void _showCreateCompagnieDialog() {
    // TODO: Implémenter la création de compagnie
  }
}
