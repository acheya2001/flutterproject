import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../insurance/models/insurance_structure_model.dart';
import '../../insurance/services/insurance_structure_service.dart';
import '../../../core/widgets/custom_button.dart';
import 'contract_creation_screen.dart';

/// 🔍 Écran de validation détaillée d'un véhicule
class VehicleValidationScreen extends StatefulWidget {
  final PendingVehicle vehicle;

  const VehicleValidationScreen({
    Key? key,
    required this.vehicle,
  }) : super(key: key);

  @override
  State<VehicleValidationScreen> createState() => _VehicleValidationScreenState();
}

class _VehicleValidationScreenState extends State<VehicleValidationScreen> {
  final TextEditingController _rejectionReasonController = TextEditingController();
  bool _isLoading = false;
  String? _currentAgentId;

  @override
  void initState() {
    super.initState();
    _currentAgentId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation Véhicule'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du véhicule
            _buildVehicleHeader(),
            
            const SizedBox(height: 24),
            
            // Informations du conducteur
            _buildConducteurDetails(),
            
            const SizedBox(height: 24),
            
            // Détails du véhicule
            _buildVehicleDetails(),
            
            const SizedBox(height: 24),
            
            // Documents
            _buildDocumentsSection(),
            
            const SizedBox(height: 24),
            
            // Informations d'assurance
            _buildInsuranceInfo(),
            
            const SizedBox(height: 32),
            
            // Actions de validation
            _buildValidationActions(),
          ],
        ),
      ),
    );
  }

  /// 🚗 En-tête du véhicule
  Widget _buildVehicleHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.directions_car,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            widget.vehicle.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.vehicle.plate,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.vehicle.status.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              widget.vehicle.status.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }



  /// 🚗 Détails du véhicule
  Widget _buildVehicleDetails() {
    return _buildSection(
      title: 'Détails du Véhicule',
      icon: Icons.directions_car,
      color: Colors.blue,
      child: Column(
        children: [
          _buildInfoRow('Marque', widget.vehicle.brand),
          _buildInfoRow('Modèle', widget.vehicle.model),
          _buildInfoRow('Année', widget.vehicle.year.toString()),
          _buildInfoRow('Immatriculation', widget.vehicle.plate),
          _buildInfoRow('Couleur', widget.vehicle.color),
          _buildInfoRow('Type de carburant', _getFuelTypeLabel(widget.vehicle.fuelType)),
          _buildInfoRow('N° Carte Grise', widget.vehicle.carteGriseNumber),
          if (widget.vehicle.vin != null && widget.vehicle.vin!.isNotEmpty)
            _buildInfoRow('VIN (Châssis)', widget.vehicle.vin!),
          if (widget.vehicle.firstRegistrationDate != null)
            _buildInfoRow('1ère mise en circulation', _formatDate(widget.vehicle.firstRegistrationDate!)),
          _buildInfoRow('Soumis le', _formatDate(widget.vehicle.submittedAt)),
        ],
      ),
    );
  }

  /// 📄 Section documents
  Widget _buildDocumentsSection() {
    return _buildSection(
      title: 'Documents Fournis',
      icon: Icons.description,
      color: Colors.orange,
      child: widget.vehicle.documents.isEmpty
          ? const Text(
              'Aucun document fourni',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            )
          : Column(
              children: widget.vehicle.documents.map((doc) => 
                _buildDocumentItem(doc)
              ).toList(),
            ),
    );
  }

  /// 👤 Informations du conducteur
  Widget _buildConducteurDetails() {
    return _buildSection(
      title: 'Informations du Conducteur',
      icon: Icons.person,
      color: Colors.green,
      child: Column(
        children: [
          _buildInfoRow('Nom complet', '${widget.vehicle.conducteurPrenom} ${widget.vehicle.conducteurNom}'),
          _buildInfoRow('Téléphone', widget.vehicle.conducteurTelephone),
          _buildInfoRow('Email', widget.vehicle.conducteurEmail),
          _buildInfoRow('Adresse', widget.vehicle.conducteurAddress),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Permis de conduire',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.green.shade700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('N° Permis', widget.vehicle.permisNumber),
          if (widget.vehicle.permisDeliveryDate != null)
            _buildInfoRow('Date de délivrance', _formatDate(widget.vehicle.permisDeliveryDate!)),
        ],
      ),
    );
  }

  /// 🏢 Informations d'assurance
  Widget _buildInsuranceInfo() {
    return _buildSection(
      title: 'Informations d\'Assurance',
      icon: Icons.security,
      color: Colors.purple,
      child: Column(
        children: [
          _buildInfoRow('Compagnie', widget.vehicle.companyName),
          _buildInfoRow('Agence', widget.vehicle.agencyName),
        ],
      ),
    );
  }

  /// 📋 Section générique
  Widget _buildSection({
    required String title,
    required IconData icon,
    required MaterialColor color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: color.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  /// 📄 Item de document
  Widget _buildDocumentItem(String documentUrl) {
    final fileName = documentUrl.split('/').last;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.description, color: Colors.orange.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fileName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            onPressed: () => _viewDocument(documentUrl),
            icon: Icon(Icons.visibility, color: Colors.blue.shade600),
          ),
        ],
      ),
    );
  }

  /// ℹ️ Ligne d'information
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Actions de validation
  Widget _buildValidationActions() {
    return Column(
      children: [
        // Bouton Valider
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: 'Valider le Véhicule',
            onPressed: _isLoading ? null : _validateVehicle,
            backgroundColor: Colors.green.shade600,
            icon: Icons.check_circle,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Bouton Rejeter
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: 'Rejeter le Véhicule',
            onPressed: _isLoading ? null : _showRejectDialog,
            backgroundColor: Colors.red.shade600,
            icon: Icons.cancel,
          ),
        ),
      ],
    );
  }

  /// ✅ Valider le véhicule
  void _validateVehicle() async {
    if (_currentAgentId == null) return;

    setState(() => _isLoading = true);

    try {
      await InsuranceStructureService.validateVehicle(
        widget.vehicle.vehicleId,
        _currentAgentId!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Véhicule validé avec succès'),
            backgroundColor: Colors.green,
          ),
        );

        // Naviguer vers la création de contrat
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ContractCreationScreen(
              vehicle: widget.vehicle.copyWith(
                status: VehicleStatus.valide,
                validatedBy: _currentAgentId,
                validatedAt: DateTime.now(),
              ),
            ),
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// ❌ Afficher le dialog de rejet
  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter le véhicule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez indiquer la raison du rejet:'),
            const SizedBox(height: 16),
            TextField(
              controller: _rejectionReasonController,
              decoration: const InputDecoration(
                hintText: 'Raison du rejet...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: _rejectVehicle,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }

  /// ❌ Rejeter le véhicule
  void _rejectVehicle() async {
    if (_rejectionReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez indiquer une raison'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pop(context); // Fermer le dialog
    setState(() => _isLoading = true);

    try {
      await InsuranceStructureService.rejectVehicle(
        widget.vehicle.vehicleId,
        _currentAgentId!,
        _rejectionReasonController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Véhicule rejeté'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 👁️ Voir un document
  void _viewDocument(String documentUrl) {
    // TODO: Implémenter la visualisation de document
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Visualisation de document - À implémenter'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// 🔧 Obtenir le libellé du type de carburant
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

  /// 📅 Formater une date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Extension pour copier un PendingVehicle avec modifications
extension PendingVehicleCopyWith on PendingVehicle {
  PendingVehicle copyWith({
    VehicleStatus? status,
    String? validatedBy,
    DateTime? validatedAt,
    String? rejectionReason,
    String? contractId,
  }) {
    return PendingVehicle(
      vehicleId: this.vehicleId,
      conducteurId: this.conducteurId,
      conducteurNom: this.conducteurNom,
      conducteurPrenom: this.conducteurPrenom,
      conducteurTelephone: this.conducteurTelephone,
      // Informations conducteur enrichies
      conducteurAddress: this.conducteurAddress,
      conducteurEmail: this.conducteurEmail,
      permisNumber: this.permisNumber,
      permisDeliveryDate: this.permisDeliveryDate,
      // Informations compagnie/agence
      companyId: this.companyId,
      companyName: this.companyName,
      agencyId: this.agencyId,
      agencyName: this.agencyName,
      // Informations véhicule enrichies
      brand: this.brand,
      model: this.model,
      plate: this.plate,
      year: this.year,
      vin: this.vin,
      color: this.color,
      carteGriseNumber: this.carteGriseNumber,
      fuelType: this.fuelType,
      firstRegistrationDate: this.firstRegistrationDate,
      // Documents et validation
      documents: this.documents,
      status: status ?? this.status,
      submittedAt: this.submittedAt,
      validatedBy: validatedBy ?? this.validatedBy,
      validatedAt: validatedAt ?? this.validatedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      contractId: contractId ?? this.contractId,
    );
  }
}
