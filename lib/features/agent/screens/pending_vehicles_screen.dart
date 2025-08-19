import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../insurance/models/insurance_structure_model.dart';
import '../../insurance/services/insurance_structure_service.dart';
import '../../../core/widgets/custom_button.dart';
import 'vehicle_validation_screen.dart';

/// 🚗 Écran de gestion des véhicules en attente pour les agents
class PendingVehiclesScreen extends StatefulWidget {
  final String? agencyId;

  const PendingVehiclesScreen({
    super.key,
    this.agencyId,
  });

  @override
  State<PendingVehiclesScreen> createState() => _PendingVehiclesScreenState();
}

class _PendingVehiclesScreenState extends State<PendingVehiclesScreen> {
  String? _currentAgentId;
  String? _currentAgencyId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentAgentId = FirebaseAuth.instance.currentUser?.uid;
    _currentAgencyId = widget.agencyId;
    _loadAgencyInfo();
  }

  Future<void> _loadAgencyInfo() async {
    // TODO: Récupérer l'agence de l'agent connecté si pas fournie
    if (_currentAgencyId == null) {
      // Logique pour récupérer l'agence de l'agent
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Véhicules en attente'),
          backgroundColor: Colors.orange[600],
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Véhicules en attente'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: _currentAgencyId != null
          ? _buildPendingVehiclesList()
          : _buildNoAgencyMessage(),
    );
  }

  Widget _buildPendingVehiclesList() {
    return StreamBuilder<List<PendingVehicle>>(
      stream: InsuranceStructureService.streamPendingVehiclesByAgency(_currentAgencyId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Erreur: ${snapshot.error}'),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Réessayer',
                  onPressed: () => setState(() {}),
                ),
              ],
            ),
          );
        }

        final pendingVehicles = snapshot.data ?? [];

        if (pendingVehicles.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            // Statistiques
            _buildStatsHeader(pendingVehicles.length),
            
            // Liste des véhicules
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: pendingVehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = pendingVehicles[index];
                  return _buildVehicleCard(vehicle);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsHeader(int pendingCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.pending_actions, color: Colors.orange[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Véhicules en attente',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
                Text(
                  '$pendingCount véhicule(s) nécessitent votre validation',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange[600],
                  ),
                ),
              ],
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
            Icons.check_circle_outline,
            size: 64,
            color: Colors.green[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun véhicule en attente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tous les véhicules ont été traités',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(PendingVehicle vehicle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _openVehicleValidation(vehicle),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du véhicule
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.directions_car,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        vehicle.plate,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: vehicle.status.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        vehicle.status.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: vehicle.status.color.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Informations détaillées
            _buildInfoRow('Conducteur', vehicle.conducteurFullName),
            _buildInfoRow('Téléphone', vehicle.conducteurTelephone),
            _buildInfoRow('Année', vehicle.year.toString()),
            _buildInfoRow('Couleur', vehicle.color),
            if (vehicle.vin != null)
              _buildInfoRow('N° Carte grise', vehicle.vin!),
            _buildInfoRow('Soumis le', _formatDate(vehicle.submittedAt)),
            
            const SizedBox(height: 16),
            
            // Documents
            if (vehicle.documents.isNotEmpty) ...[
              const Text(
                'Documents fournis:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: vehicle.documents.map((doc) {
                  return Chip(
                    label: Text('Document ${vehicle.documents.indexOf(doc) + 1}'),
                    backgroundColor: Colors.blue[50],
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Indication cliquable
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.touch_app,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cliquez pour voir les détails et valider/rejeter',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.blue.shade600,
                    size: 20,
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

  /// 🔍 Ouvrir l'écran de validation détaillée
  void _openVehicleValidation(PendingVehicle vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleValidationScreen(vehicle: vehicle),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAgencyMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Agence non configurée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contactez votre administrateur',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }



  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
