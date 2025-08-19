import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../models/conducteur_vehicle_model.dart';
import '../services/conducteur_auth_service.dart';

/// 🚗 Écran de gestion des véhicules du conducteur
class ConducteurVehiculesScreen extends StatefulWidget {
  const ConducteurVehiculesScreen({super.key});

  @override
  State<ConducteurVehiculesScreen> createState() => _ConducteurVehiculesScreenState();
}

class _ConducteurVehiculesScreenState extends State<ConducteurVehiculesScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  List<ConducteurVehicleModel> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final vehicles = await ConducteurAuthService.getConducteurVehicles(_currentUser!.uid);
      setState(() {
        _vehicles = vehicles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des véhicules: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Mes Véhicules',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
              ? _buildEmptyState()
              : _buildVehiclesList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/conducteur/add-vehicle');
          if (result == true) {
            _loadVehicles(); // Recharger la liste
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
        backgroundColor: const Color(0xFF3B82F6),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun véhicule',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ajoutez votre premier véhicule pour commencer à créer des constats d\'accident',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Ajouter mon premier véhicule',
              onPressed: () async {
                final result = await Navigator.pushNamed(context, '/conducteur/add-vehicle');
                if (result == true) {
                  _loadVehicles();
                }
              },
              icon: Icons.add,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehiclesList() {
    return RefreshIndicator(
      onRefresh: _loadVehicles,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _vehicles.length,
        itemBuilder: (context, index) {
          final vehicle = _vehicles[index];
          return _buildVehicleCard(vehicle);
        },
      ),
    );
  }

  Widget _buildVehicleCard(ConducteurVehicleModel vehicle) {
    final hasValidInsurance = vehicle.hasValidInsurance;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec marque/modèle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasValidInsurance ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.directions_car,
                  color: hasValidInsurance ? Colors.green : Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle.brand} ${vehicle.model}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      vehicle.plate,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(vehicle),
            ],
          ),

          const SizedBox(height: 16),

          // Informations détaillées
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Année', vehicle.year.toString()),
              ),
              Expanded(
                child: _buildInfoItem('Couleur', vehicle.color),
              ),
              Expanded(
                child: _buildInfoItem('Carburant', _getFuelTypeLabel(vehicle.fuelType)),
              ),
            ],
          ),

          if (hasValidInsurance) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.green[700], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Assurance active',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewVehicleDetails(vehicle),
                  icon: const Icon(Icons.visibility),
                  label: const Text('Détails'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasValidInsurance
                      ? () => _createConstat(vehicle)
                      : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Constat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ConducteurVehicleModel vehicle) {
    final hasValidInsurance = vehicle.hasValidInsurance;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: hasValidInsurance ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        hasValidInsurance ? 'Validé' : 'En attente',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getFuelTypeLabel(String fuelType) {
    switch (fuelType.toLowerCase()) {
      case 'essence':
        return 'Essence';
      case 'diesel':
        return 'Diesel';
      case 'hybride':
        return 'Hybride';
      case 'electrique':
        return 'Électrique';
      case 'gpl':
        return 'GPL';
      default:
        return fuelType.toUpperCase();
    }
  }

  void _viewVehicleDetails(ConducteurVehicleModel vehicle) {
    // TODO: Naviguer vers la page de détails du véhicule
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Détails du véhicule - À implémenter'),
      ),
    );
  }

  void _createConstat(ConducteurVehicleModel vehicle) {
    Navigator.pushNamed(
      context,
      '/constat/selection',
      arguments: {'preselectedVehicle': vehicle},
    );
  }
}
