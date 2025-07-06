import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../vehicules/models/vehicule_assure_model.dart';
import '../../vehicules/services/vehicule_assure_service.dart';
import '../../vehicules/widgets/contract_verification_dialog.dart';
import '../../vehicules/widgets/vehicle_card.dart';

/// 🏢 Écran de vérification des véhicules pour assureur
class AssureurVehicleVerificationScreen extends ConsumerStatefulWidget {
  const AssureurVehicleVerificationScreen({super.key});

  @override
  ConsumerState<AssureurVehicleVerificationScreen> createState() => _AssureurVehicleVerificationScreenState();
}

class _AssureurVehicleVerificationScreenState extends ConsumerState<AssureurVehicleVerificationScreen> {
  final VehiculeAssureService _vehiculeService = VehiculeAssureService();
  final TextEditingController _searchController = TextEditingController();
  
  List<VehiculeAssureModel> _allVehicles = [];
  List<VehiculeAssureModel> _filteredVehicles = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAllVehicles();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterVehicles();
    });
  }

  void _filterVehicles() {
    if (_searchQuery.isEmpty) {
      _filteredVehicles = List.from(_allVehicles);
    } else {
      _filteredVehicles = _allVehicles.where((vehicle) {
        return vehicle.vehicule.immatriculation.toLowerCase().contains(_searchQuery) ||
               vehicle.numeroContrat.toLowerCase().contains(_searchQuery) ||
               vehicle.vehicule.marque.toLowerCase().contains(_searchQuery) ||
               vehicle.vehicule.modele.toLowerCase().contains(_searchQuery) ||
               vehicle.proprietaire.nom.toLowerCase().contains(_searchQuery) ||
               vehicle.proprietaire.prenom.toLowerCase().contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _loadAllVehicles() async {
    try {
      setState(() => _isLoading = true);
      
      // Pour les assureurs, on charge tous les véhicules
      final vehicles = await _vehiculeService.getAllVehicles();
      
      setState(() {
        _allVehicles = vehicles;
        _filteredVehicles = List.from(vehicles);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Vérification Véhicules',
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showVerificationDialog,
            tooltip: 'Vérifier un contrat',
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête assureur
          _buildAssureurHeader(user),

          // Barre de recherche
          _buildSearchBar(),

          // Statistiques
          _buildStatsRow(),

          // Liste des véhicules
          Expanded(
            child: _isLoading ? _buildLoadingWidget() : _buildVehiclesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showVerificationDialog,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.search),
        label: const Text('Vérifier'),
      ),
    );
  }

  /// 🏢 En-tête assureur
  Widget _buildAssureurHeader(user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.green[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.business, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assureur: ${user?.prenom} ${user?.nom}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vérification et gestion des contrats',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🔍 Barre de recherche
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher par immatriculation, contrat, marque...',
          prefixIcon: Icon(Icons.search, color: Colors.green[600]),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  /// 📊 Statistiques
  Widget _buildStatsRow() {
    final totalVehicles = _allVehicles.length;
    final activeContracts = _allVehicles.where((v) => v.isContratActif).length;
    final expiredContracts = totalVehicles - activeContracts;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Total', totalVehicles.toString(), Colors.blue)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Actifs', activeContracts.toString(), Colors.green)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Expirés', expiredContracts.toString(), Colors.red)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Liste des véhicules
  Widget _buildVehiclesList() {
    if (_filteredVehicles.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredVehicles.length,
      itemBuilder: (context, index) {
        final vehicle = _filteredVehicles[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: VehicleCard(
            vehicule: vehicle,
            onTap: () => _showVehicleDetails(vehicle),
            showOwnerInfo: true, // Pour les assureurs, on affiche les infos propriétaire
          ),
        );
      },
    );
  }

  /// 📱 État vide
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.directions_car_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty 
                ? 'Aucun véhicule trouvé'
                : 'Aucun véhicule enregistré',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty 
                ? 'Essayez avec d\'autres termes de recherche'
                : 'Les véhicules assurés apparaîtront ici',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  /// ⏳ Widget de chargement
  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.green),
          SizedBox(height: 16),
          Text(
            'Chargement des véhicules...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔍 Afficher le dialog de vérification
  void _showVerificationDialog() async {
    final result = await showDialog<VehiculeAssureModel>(
      context: context,
      builder: (context) => const ContractVerificationDialog(),
    );

    if (result != null) {
      _showVehicleDetails(result);
    }
  }

  /// 📋 Afficher les détails du véhicule
  void _showVehicleDetails(VehiculeAssureModel vehicle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VehicleDetailsSheet(vehicle: vehicle),
    );
  }
}

/// 📋 Feuille de détails du véhicule
class _VehicleDetailsSheet extends StatelessWidget {
  final VehiculeAssureModel vehicle;

  const _VehicleDetailsSheet({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Contenu
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.directions_car, color: Colors.green[700], size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${vehicle.vehicule.marque} ${vehicle.vehicule.modele}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              vehicle.vehicule.immatriculation,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: vehicle.isContratActif ? Colors.green[100] : Colors.red[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          vehicle.isContratActif ? 'Actif' : 'Expiré',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: vehicle.isContratActif ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Informations détaillées
                  _buildDetailSection('Contrat d\'assurance', [
                    _buildDetailRow('Numéro', vehicle.numeroContrat),
                    _buildDetailRow('Assureur', _getAssureurName(vehicle.assureurId)),
                    _buildDetailRow('Type', vehicle.contrat.typeCouverture),
                    _buildDetailRow('Début', _formatDate(vehicle.contrat.dateDebut)),
                    _buildDetailRow('Fin', _formatDate(vehicle.contrat.dateFin)),
                    _buildDetailRow('Prime annuelle', '${vehicle.contrat.primeAnnuelle.toStringAsFixed(0)} TND'),
                  ]),
                  
                  const SizedBox(height: 20),
                  
                  _buildDetailSection('Propriétaire', [
                    _buildDetailRow('Nom', '${vehicle.proprietaire.prenom} ${vehicle.proprietaire.nom}'),
                    _buildDetailRow('CIN', vehicle.proprietaire.cin),
                    _buildDetailRow('Téléphone', vehicle.proprietaire.telephone),
                  ]),
                  
                  const SizedBox(height: 20),
                  
                  _buildDetailSection('Véhicule', [
                    _buildDetailRow('Marque', vehicle.vehicule.marque),
                    _buildDetailRow('Modèle', vehicle.vehicule.modele),
                    _buildDetailRow('Année', vehicle.vehicule.annee.toString()),
                    _buildDetailRow('Couleur', vehicle.vehicule.couleur),
                    _buildDetailRow('Châssis', vehicle.vehicule.numeroChassis),
                    _buildDetailRow('Puissance', '${vehicle.vehicule.puissanceFiscale} CV'),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: Color(0xFF6B7280))),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAssureurName(String assureurId) {
    switch (assureurId.toUpperCase()) {
      case 'STAR':
        return 'STAR Assurances';
      case 'MAGHREBIA':
        return 'Maghrebia Assurances';
      case 'GAT':
        return 'GAT Assurances';
      case 'LLOYD':
        return 'Lloyd Tunisien';
      case 'AST':
        return 'Assurances Salim';
      default:
        return assureurId;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
