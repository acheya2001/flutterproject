import 'package:flutter/material.dart';
import '../services/auto_fill_service.dart';

/// 🚗 Widget de sélection de véhicule avec auto-remplissage
/// S'intègre parfaitement à votre système existant
class VehicleSelectorWithAutoFill extends StatefulWidget {
  final Function(Map<String, dynamic>) onVehicleSelected;
  final Function(Map<String, dynamic>) onAutoFillComplete;
  final String? selectedVehicleId;

  const VehicleSelectorWithAutoFill({
    Key? key,
    required this.onVehicleSelected,
    required this.onAutoFillComplete,
    this.selectedVehicleId,
  }) : super(key: key);

  @override
  State<VehicleSelectorWithAutoFill> createState() => _VehicleSelectorWithAutoFillState();
}

class _VehicleSelectorWithAutoFillState extends State<VehicleSelectorWithAutoFill> {
  List<Map<String, dynamic>> _vehicles = [];
  Map<String, dynamic>? _selectedVehicle;
  bool _isLoading = true;
  bool _isAutoFilling = false;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  /// 📋 Charger les véhicules du conducteur
  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    
    try {
      final vehicles = await AutoFillService.getConducteurVehicles();
      setState(() {
        _vehicles = vehicles;
        _isLoading = false;
        
        // Sélectionner automatiquement le véhicule si spécifié
        if (widget.selectedVehicleId != null) {
          _selectedVehicle = vehicles.firstWhere(
            (v) => v['id'] == widget.selectedVehicleId,
            orElse: () => {},
          );
          if (_selectedVehicle!.isNotEmpty) {
            _performAutoFill(_selectedVehicle!['id']);
          }
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur lors du chargement des véhicules: $e');
    }
  }

  /// 🔄 Effectuer l'auto-remplissage
  Future<void> _performAutoFill(String vehicleId) async {
    setState(() => _isAutoFilling = true);
    
    try {
      final result = await AutoFillService.autoFillAccidentForm(vehicleId: vehicleId);
      
      if (result['success']) {
        widget.onAutoFillComplete(result['data']);
        _showSuccess('Formulaire pré-rempli automatiquement !');
      } else {
        _showError('Erreur auto-remplissage: ${result['error']}');
      }
    } catch (e) {
      _showError('Erreur auto-remplissage: $e');
    } finally {
      setState(() => _isAutoFilling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 16),
            if (_isLoading) _buildLoadingState(),
            if (!_isLoading && _vehicles.isEmpty) _buildEmptyState(),
            if (!_isLoading && _vehicles.isNotEmpty) _buildVehicleList(),
            if (_isAutoFilling) _buildAutoFillProgress(),
          ],
        ),
      ),
    );
  }

  /// 📱 En-tête du widget
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.directions_car, color: Colors.blue[600], size: 24),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sélectionnez votre véhicule',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                'Le formulaire sera pré-rempli automatiquement',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        if (_selectedVehicle != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                SizedBox(width: 4),
                Text(
                  'Sélectionné',
                  style: TextStyle(
                    color: Colors.green[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// ⏳ État de chargement
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        children: [
          CircularProgressIndicator(color: Colors.blue[600]),
          SizedBox(height: 16),
          Text('Chargement de vos véhicules...'),
        ],
      ),
    );
  }

  /// 📭 État vide
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Aucun véhicule trouvé',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Ajoutez un véhicule pour continuer',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/conducteur/add-vehicle'),
            icon: Icon(Icons.add),
            label: Text('Ajouter un véhicule'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 🚗 Liste des véhicules
  Widget _buildVehicleList() {
    return Column(
      children: _vehicles.map((vehicle) => _buildVehicleCard(vehicle)).toList(),
    );
  }

  /// 🎴 Carte de véhicule
  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    final isSelected = _selectedVehicle?['id'] == vehicle['id'];
    final hasValidInsurance = vehicle['hasValidInsurance'] ?? false;
    final insuranceStatus = vehicle['insuranceStatus'] ?? 'Inconnu';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? Colors.blue[50] : Colors.white,
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: hasValidInsurance ? Colors.green[100] : Colors.orange[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.directions_car,
            color: hasValidInsurance ? Colors.green[600] : Colors.orange[600],
          ),
        ),
        title: Text(
          '${vehicle['marque']} ${vehicle['modele']}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.blue[800] : Colors.grey[800],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${vehicle['numeroImmatriculation']} • ${vehicle['annee']}'),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: hasValidInsurance ? Colors.green[100] : Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                insuranceStatus,
                style: TextStyle(
                  fontSize: 11,
                  color: hasValidInsurance ? Colors.green[700] : Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: Colors.blue[600])
            : Icon(Icons.radio_button_unchecked, color: Colors.grey[400]),
        onTap: () => _selectVehicle(vehicle),
      ),
    );
  }

  /// 🔄 Indicateur de progression auto-remplissage
  Widget _buildAutoFillProgress() {
    return Container(
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Auto-remplissage en cours...',
            style: TextStyle(
              color: Colors.blue[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Sélectionner un véhicule
  void _selectVehicle(Map<String, dynamic> vehicle) {
    setState(() => _selectedVehicle = vehicle);
    widget.onVehicleSelected(vehicle);
    _performAutoFill(vehicle['id']);
  }

  /// ✅ Afficher un message de succès
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// ❌ Afficher un message d'erreur
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
