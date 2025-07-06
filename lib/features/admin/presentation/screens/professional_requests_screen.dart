import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/modern_theme.dart';
import '../../models/professional_request_model_final.dart';
import '../../services/professional_request_service.dart';
import '../widgets/request_card.dart';
import '../widgets/request_filters.dart';
import '../widgets/request_stats_header.dart';
import '../widgets/request_validation_dialogs.dart';
import '../providers/professional_requests_provider.dart';

/// 📝 Écran de gestion des demandes de comptes professionnels
class ProfessionalRequestsScreen extends ConsumerStatefulWidget {
  const ProfessionalRequestsScreen({super.key});

  @override
  ConsumerState<ProfessionalRequestsScreen> createState() => _ProfessionalRequestsScreenState();
}

class _ProfessionalRequestsScreenState extends ConsumerState<ProfessionalRequestsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'tous';
  String _selectedType = 'tous';
  List<ProfessionalRequestModel> _allRequests = [];
  List<ProfessionalRequestModel> _filteredRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 📋 Charger les demandes
  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    
    try {
      final requests = await ProfessionalRequestService.getAllRequests();
      setState(() {
        _allRequests = requests;
        _filteredRequests = requests;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: ModernTheme.errorColor,
          ),
        );
      }
    }
  }

  /// 🔍 Recherche en temps réel
  void _onSearchChanged() {
    _applyFilters();
  }

  /// 🎯 Appliquer les filtres
  void _applyFilters() {
    setState(() {
      _filteredRequests = _allRequests.where((request) {
        // Filtre par recherche
        final searchTerm = _searchController.text.toLowerCase();
        final matchesSearch = searchTerm.isEmpty ||
            request.nom.toLowerCase().contains(searchTerm) ||
            request.prenom.toLowerCase().contains(searchTerm) ||
            request.email.toLowerCase().contains(searchTerm) ||
            request.telephone.contains(searchTerm);

        // Filtre par statut
        final matchesStatus = _selectedFilter == 'tous' || request.statut == _selectedFilter;

        // Filtre par type
        final matchesType = _selectedType == 'tous' || request.typeCompte == _selectedType;

        return matchesSearch && matchesStatus && matchesType;
      }).toList();
    });
  }

  /// 🔄 Rafraîchir
  Future<void> _onRefresh() async {
    await _loadRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  /// 🔝 Barre d'application
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Demandes Professionnelles',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: ModernTheme.primaryColor,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: ModernTheme.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _onRefresh,
        ),
        IconButton(
          icon: const Icon(Icons.filter_list, color: Colors.white),
          onPressed: _showFiltersDialog,
        ),
      ],
    );
  }

  /// 📱 Corps principal
  Widget _buildBody() {
    return Column(
      children: [
        // En-tête avec statistiques
        RequestStatsHeader(requests: _allRequests),
        
        // Barre de recherche
        _buildSearchBar(),
        
        // Filtres rapides
        RequestFilters(
          selectedFilter: _selectedFilter,
          selectedType: _selectedType,
          onFilterChanged: (filter) {
            setState(() => _selectedFilter = filter);
            _applyFilters();
          },
          onTypeChanged: (type) {
            setState(() => _selectedType = type);
            _applyFilters();
          },
        ),
        
        // Liste des demandes
        Expanded(
          child: _buildRequestsList(),
        ),
      ],
    );
  }

  /// 🔍 Barre de recherche
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(ModernTheme.spacingM),
      decoration: ModernTheme.cardDecoration(),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher par nom, email, téléphone...',
          prefixIcon: const Icon(Icons.search, color: ModernTheme.textLight),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: ModernTheme.textLight),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(ModernTheme.spacingM),
        ),
      ),
    );
  }

  /// 📋 Liste des demandes
  Widget _buildRequestsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(ModernTheme.primaryColor),
        ),
      );
    }

    if (_filteredRequests.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: ModernTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(ModernTheme.spacingM),
        itemCount: _filteredRequests.length,
        itemBuilder: (context, index) {
          final request = _filteredRequests[index];
          return RequestCard(
            request: request,
            onApprove: () => _handleApprove(request),
            onReject: () => _handleReject(request),
            onTap: () => _showRequestDetails(request),
          );
        },
      ),
    );
  }

  /// 🚫 État vide
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchController.text.isNotEmpty ? Icons.search_off : Icons.inbox,
            size: 64,
            color: ModernTheme.textLight,
          ),
          const SizedBox(height: ModernTheme.spacingM),
          Text(
            _searchController.text.isNotEmpty
                ? 'Aucun résultat trouvé'
                : 'Aucune demande trouvée',
            style: ModernTheme.headingSmall.copyWith(
              color: ModernTheme.textLight,
            ),
          ),
          const SizedBox(height: ModernTheme.spacingS),
          Text(
            _searchController.text.isNotEmpty
                ? 'Essayez avec d\'autres termes de recherche'
                : 'Les nouvelles demandes apparaîtront ici',
            style: ModernTheme.bodyMedium.copyWith(
              color: ModernTheme.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// ✅ Gérer l'approbation
  void _handleApprove(ProfessionalRequestModel request) {
    showDialog(
      context: context,
      builder: (context) => ApprovalDialog(
        request: request,
        adminId: 'super_admin', // TODO: Récupérer l'ID de l'admin connecté
      ),
    ).then((approved) {
      if (approved == true) {
        _loadRequests(); // Recharger la liste
      }
    });
  }

  /// ❌ Gérer le rejet
  void _handleReject(ProfessionalRequestModel request) {
    showDialog(
      context: context,
      builder: (context) => RejectionDialog(
        request: request,
        adminId: 'super_admin', // TODO: Récupérer l'ID de l'admin connecté
      ),
    ).then((rejected) {
      if (rejected == true) {
        _loadRequests(); // Recharger la liste
      }
    });
  }

  /// 👁️ Afficher les détails
  void _showRequestDetails(ProfessionalRequestModel request) {
    // TODO: Implémenter l'écran de détails
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails - ${request.nomComplet}'),
        content: Text('Email: ${request.email}\nType: ${request.typeCompteFormate}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// 🎯 Afficher les filtres
  void _showFiltersDialog() {
    // TODO: Implémenter la boîte de dialogue des filtres avancés
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtres avancés'),
        content: const Text('Filtres avancés à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
