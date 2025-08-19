import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../conducteur/models/conducteur_vehicle_model.dart';
import '../../conducteur/services/conducteur_auth_service.dart';
import '../../../core/widgets/custom_button.dart';
import 'constat_officiel_screen.dart';

/// 🚗 Écran de sélection des véhicules pour démarrer un constat officiel
class ConstatSelectionScreen extends StatefulWidget {
  const ConstatSelectionScreen({super.key});

  @override
  State<ConstatSelectionScreen> createState() => _ConstatSelectionScreenState();
}

class _ConstatSelectionScreenState extends State<ConstatSelectionScreen> {
  final ConducteurAuthService _authService = ConducteurAuthService();
  
  List<ConducteurVehicleModel> _vehicles = [];
  List<String> _selectedVehicleIds = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    if (_currentUserId == null) return;

    try {
      final vehicles = await ConducteurAuthService.getConducteurVehicles(_currentUserId!);
      setState(() {
        _vehicles = vehicles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Erreur lors du chargement des véhicules: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Constat Amiable'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Instructions
        _buildInstructions(),
        
        // Liste des véhicules
        Expanded(
          child: _vehicles.isEmpty
              ? _buildEmptyState()
              : _buildVehiclesList(),
        ),
        
        // Actions
        _buildActionBar(),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text(
                'Sélection des véhicules',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Sélectionnez les véhicules impliqués dans l\'accident. '
            'Vous pouvez choisir plusieurs véhicules si nécessaire.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Minimum: 2 véhicules\n'
            '• Maximum: 5 véhicules\n'
            '• Chaque véhicule aura sa propre section (A, B, C...)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun véhicule enregistré',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez vos véhicules depuis votre dashboard',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Ajouter un véhicule',
            onPressed: () {
              Navigator.of(context).pushNamed('/conducteur/add-vehicle');
            },
            icon: Icons.add,
          ),
        ],
      ),
    );
  }

  Widget _buildVehiclesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = _vehicles[index];
        final isSelected = _selectedVehicleIds.contains(vehicle.vehicleId);
        
        return _buildVehicleCard(vehicle, isSelected);
      },
    );
  }

  Widget _buildVehicleCard(ConducteurVehicleModel vehicle, bool isSelected) {
    final hasValidInsurance = vehicle.hasValidInsurance;
    final partieId = _getPartieId(_selectedVehicleIds.indexOf(vehicle.vehicleId));
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _toggleVehicleSelection(vehicle.vehicleId),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: Colors.green[600]!, width: 2)
                : null,
          ),
          child: Row(
            children: [
              // Indicateur de sélection
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green[600] : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isSelected
                      ? Text(
                          partieId,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : Icon(
                          Icons.directions_car,
                          color: Colors.grey[600],
                        ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Informations du véhicule
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.plate,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicle.fullName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Statut d'assurance
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: hasValidInsurance
                            ? Colors.green[100]
                            : Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        hasValidInsurance
                            ? 'Assuré - ${vehicle.activeContract?.companyName ?? 'N/A'}'
                            : 'Assurance expirée',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: hasValidInsurance
                              ? Colors.green[700]
                              : Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Icône de sélection
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? Colors.green[600] : Colors.grey[400],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    final canProceed = _selectedVehicleIds.length >= 2;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Résumé de la sélection
          if (_selectedVehicleIds.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                '${_selectedVehicleIds.length} véhicule(s) sélectionné(s)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Annuler',
                  onPressed: () => Navigator.of(context).pop(),
                  backgroundColor: Colors.grey[300],
                  textColor: Colors.black87,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  text: 'Créer le constat',
                  onPressed: canProceed ? _createConstat : null,
                  icon: Icons.description,
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPartieId(int index) {
    if (index < 0) return '';
    return String.fromCharCode(65 + index); // A, B, C, D, E
  }

  void _toggleVehicleSelection(String vehicleId) {
    setState(() {
      if (_selectedVehicleIds.contains(vehicleId)) {
        _selectedVehicleIds.remove(vehicleId);
      } else {
        if (_selectedVehicleIds.length < 5) {
          _selectedVehicleIds.add(vehicleId);
        } else {
          _showError('Maximum 5 véhicules autorisés');
        }
      }
    });
  }

  void _createConstat() {
    if (_selectedVehicleIds.length < 2) {
      _showError('Sélectionnez au moins 2 véhicules');
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ConstatOfficielScreen(
          vehicleIds: _selectedVehicleIds,
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
