import 'package:flutter/material.dart';
import '../../models/professional_request_model_final.dart';
import '../../services/professional_request_management_service.dart';
import '../widgets/professional_request_card.dart';
import '../widgets/request_details_modal.dart';
import '../../../../core/theme/modern_theme.dart';

/// 📋 Écran de gestion des demandes professionnelles pour Super Admin
class ProfessionalRequestsManagementScreen extends StatefulWidget {
  const ProfessionalRequestsManagementScreen({super.key});

  @override
  State<ProfessionalRequestsManagementScreen> createState() => _ProfessionalRequestsManagementScreenState();
}

class _ProfessionalRequestsManagementScreenState extends State<ProfessionalRequestsManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Barre de recherche
          _buildSearchBar(),
          
          // Onglets
          _buildTabBar(),
          
          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsList('en_attente'),
                _buildRequestsList('acceptee'),
                _buildRequestsList('rejetee'),
                _buildRequestsList(null), // Toutes les demandes
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildStatsButton(),
    );
  }

  /// 🔝 AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Gestion des Demandes',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: ModernTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: _showFilterDialog,
          icon: const Icon(Icons.filter_list),
          tooltip: 'Filtres',
        ),
        IconButton(
          onPressed: _refreshData,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualiser',
        ),
      ],
    );
  }

  /// 🔍 Barre de recherche
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher par nom, email, CIN...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ModernTheme.primaryColor, width: 2),
          ),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  /// 📑 Barre d'onglets
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: ModernTheme.primaryColor,
        unselectedLabelColor: ModernTheme.textLight,
        indicatorColor: ModernTheme.primaryColor,
        tabs: const [
          Tab(
            icon: Icon(Icons.pending),
            text: 'En attente',
          ),
          Tab(
            icon: Icon(Icons.check_circle),
            text: 'Approuvées',
          ),
          Tab(
            icon: Icon(Icons.cancel),
            text: 'Rejetées',
          ),
          Tab(
            icon: Icon(Icons.list),
            text: 'Toutes',
          ),
        ],
      ),
    );
  }

  /// 📋 Liste des demandes
  Widget _buildRequestsList(String? status) {
    return StreamBuilder<List<ProfessionalRequestModel>>(
      stream: ProfessionalRequestManagementService.getAllRequests(status: status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          // Debug: Afficher l'erreur complète
          debugPrint('Erreur Firestore: ${snapshot.error}');
          debugPrint('StackTrace: ${snapshot.stackTrace}');

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: ModernTheme.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur lors du chargement',
                  style: TextStyle(
                    fontSize: 18,
                    color: ModernTheme.errorColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ModernTheme.textLight,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _refreshData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data ?? [];
        
        // Filtrer par recherche si nécessaire
        final filteredRequests = _searchQuery.isEmpty
            ? requests
            : requests.where((request) {
                final query = _searchQuery.toLowerCase();
                return request.nomComplet.toLowerCase().contains(query) ||
                       request.email.toLowerCase().contains(query) ||
                       request.tel.contains(query) ||
                       request.cin.contains(query) ||
                       request.roleFormate.toLowerCase().contains(query);
              }).toList();

        if (filteredRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _searchQuery.isNotEmpty ? Icons.search_off : Icons.inbox,
                  size: 64,
                  color: ModernTheme.textLight,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty 
                      ? 'Aucun résultat trouvé'
                      : 'Aucune demande',
                  style: TextStyle(
                    fontSize: 18,
                    color: ModernTheme.textLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Essayez avec d\'autres mots-clés',
                    style: TextStyle(color: ModernTheme.textLight),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filteredRequests.length,
          itemBuilder: (context, index) {
            final request = filteredRequests[index];
            return ProfessionalRequestCard(
              request: request,
              onApprove: request.status == 'en_attente'
                  ? () => _approveRequest(request)
                  : null,
              onReject: request.status == 'en_attente'
                  ? () => _rejectRequest(request)
                  : null,
              onViewDetails: () => _viewRequestDetails(request),
            );
          },
        );
      },
    );
  }

  /// 📊 Bouton des statistiques
  Widget _buildStatsButton() {
    return FloatingActionButton.extended(
      onPressed: _showStatsDialog,
      backgroundColor: ModernTheme.primaryColor,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.analytics),
      label: const Text('Statistiques'),
    );
  }

  /// ✅ Approuver une demande
  Future<void> _approveRequest(ProfessionalRequestModel request) async {
    final confirmed = await _showApprovalDialog(request);
    if (!confirmed) return;

    try {
      final success = await ProfessionalRequestManagementService.approveRequest(
        requestId: request.id,
        adminId: 'super_admin', // TODO: Récupérer l'ID de l'admin connecté
        commentaire: 'Demande approuvée par le Super Admin',
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Demande de ${request.nomComplet} approuvée avec succès'),
            backgroundColor: ModernTheme.successColor,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      } else if (mounted) {
        throw Exception('Erreur lors de l\'approbation');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: ModernTheme.errorColor,
          ),
        );
      }
    } finally {
      // Nettoyage si nécessaire
    }
  }

  /// ❌ Rejeter une demande
  Future<void> _rejectRequest(ProfessionalRequestModel request) async {
    final result = await _showRejectionDialog(request);
    if (result == null) return;

    try {
      final success = await ProfessionalRequestManagementService.rejectRequest(
        requestId: request.id,
        adminId: 'super_admin', // TODO: Récupérer l'ID de l'admin connecté
        motifRejet: result['motif']!,
        commentaire: result['commentaire'],
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Demande de ${request.nomComplet} rejetée'),
            backgroundColor: ModernTheme.errorColor,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      } else if (mounted) {
        throw Exception('Erreur lors du rejet');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: ModernTheme.errorColor,
          ),
        );
      }
    } finally {
      // Nettoyage si nécessaire
    }
  }

  /// 👁️ Voir les détails d'une demande
  void _viewRequestDetails(ProfessionalRequestModel request) {
    showDialog(
      context: context,
      builder: (context) => RequestDetailsModal(
        request: request,
        onRequestUpdated: () {
          setState(() {}); // Rafraîchir la liste
        },
      ),
    );
  }

  /// 💬 Dialog d'approbation
  Future<bool> _showApprovalDialog(ProfessionalRequestModel request) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approuver la demande'),
        content: Text(
          'Êtes-vous sûr de vouloir approuver la demande de ${request.nomComplet} ?\n\n'
          'Un compte sera créé et un email de confirmation sera envoyé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ModernTheme.successColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approuver'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// 💬 Dialog de rejet
  Future<Map<String, String>?> _showRejectionDialog(ProfessionalRequestModel request) async {
    final motifController = TextEditingController();
    final commentaireController = TextEditingController();

    return await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter la demande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rejeter la demande de ${request.nomComplet}'),
            const SizedBox(height: 16),
            TextField(
              controller: motifController,
              decoration: const InputDecoration(
                labelText: 'Motif du rejet *',
                hintText: 'Ex: Documents incomplets',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentaireController,
              decoration: const InputDecoration(
                labelText: 'Commentaire (optionnel)',
                hintText: 'Commentaire interne...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (motifController.text.trim().isNotEmpty) {
                Navigator.pop(context, {
                  'motif': motifController.text.trim(),
                  'commentaire': commentaireController.text.trim(),
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ModernTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }

  /// 🔄 Actualiser les données
  void _refreshData() {
    setState(() {});
  }

  /// 🔍 Dialog de filtres
  void _showFilterDialog() {
    // TODO: Implémenter les filtres avancés
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtres'),
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

  /// 📊 Dialog des statistiques
  void _showStatsDialog() {
    // TODO: Implémenter les statistiques
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques'),
        content: const Text('Statistiques à implémenter'),
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
