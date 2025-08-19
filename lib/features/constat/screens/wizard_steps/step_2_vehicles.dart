import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../models/sinistre_model.dart';
import '../declaration_wizard_screen.dart';
import '../../../conducteur/models/conducteur_vehicle_model.dart';
import '../../../conducteur/services/conducteur_auth_service.dart';

/// 🚗 Étape 2: Gestion des véhicules impliqués
class Step2Vehicles extends StatefulWidget {
  final WizardData wizardData;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const Step2Vehicles({
    super.key,
    required this.wizardData,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<Step2Vehicles> createState() => _Step2VehiclesState();
}

class _Step2VehiclesState extends State<Step2Vehicles> {
  List<ConducteurVehicleModel> _conducteurVehicles = [];
  bool _isLoadingVehicles = false;

  @override
  void initState() {
    super.initState();
    _loadConducteurVehicles();
  }

  Future<void> _loadConducteurVehicles() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLoadingVehicles = true;
    });

    try {
      final vehicles = await ConducteurAuthService.getConducteurVehicles(currentUser.uid);
      setState(() {
        _conducteurVehicles = vehicles;
        _isLoadingVehicles = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingVehicles = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de l'étape
          const Text(
            'Véhicules impliqués',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajoutez tous les véhicules impliqués dans l\'accident',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),

          // Liste des véhicules
          Expanded(
            child: widget.wizardData.vehicles.isEmpty
                ? _buildEmptyState()
                : _buildVehiclesList(),
          ),

          // Boutons d'action
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_isLoadingVehicles) {
      return const Center(child: CircularProgressIndicator());
    }

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
            'Aucun véhicule ajouté',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _conducteurVehicles.isEmpty
                ? 'Sélectionnez un de vos véhicules ou ajoutez-en un nouveau'
                : 'Ajoutez votre véhicule pour commencer',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          if (_conducteurVehicles.isNotEmpty) ...[
            CustomButton(
              text: 'Sélectionner un de mes véhicules',
              onPressed: () => _showMyVehiclesDialog(),
              icon: Icons.directions_car,
              backgroundColor: Colors.blue,
            ),
            const SizedBox(height: 12),
          ],

          CustomButton(
            text: 'Ajouter un autre véhicule',
            onPressed: () => _showAddVehicleDialog(isOwner: true),
            icon: Icons.add,
            backgroundColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildVehiclesList() {
    return Column(
      children: [
        // En-tête avec bouton d'ajout
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.wizardData.vehicles.length} véhicule(s)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddVehicleDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Liste des véhicules
        Expanded(
          child: ListView.builder(
            itemCount: widget.wizardData.vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = widget.wizardData.vehicles[index];
              return _buildVehicleCard(vehicle, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleCard(SinistreVehicleRef vehicle, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: vehicle.isOwnerBoolean ? Colors.blue[100] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.directions_car,
                        color: vehicle.isOwnerBoolean ? Colors.blue : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.plate ?? 'Immatriculation non renseignée',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${vehicle.brand ?? ''} ${vehicle.model ?? ''}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Supprimer', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditVehicleDialog(vehicle, index);
                    } else if (value == 'delete') {
                      _removeVehicle(index);
                    }
                  },
                ),
              ],
            ),
            
            if (vehicle.isOwnerBoolean) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: const Text(
                  'Mon véhicule',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'Précédent',
            onPressed: widget.onPrevious,
            backgroundColor: Colors.grey[300],
            textColor: Colors.black87,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomButton(
            text: 'Suivant',
            onPressed: widget.wizardData.vehicles.isNotEmpty ? widget.onNext : null,
            icon: Icons.arrow_forward,
          ),
        ),
      ],
    );
  }

  void _showMyVehiclesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner un véhicule'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _conducteurVehicles.length,
            itemBuilder: (context, index) {
              final vehicle = _conducteurVehicles[index];
              return _buildMyVehicleListTile(vehicle);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Widget _buildMyVehicleListTile(ConducteurVehicleModel vehicle) {
    final hasValidInsurance = vehicle.hasValidInsurance;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: hasValidInsurance ? Colors.green[100] : Colors.orange[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.directions_car,
          color: hasValidInsurance ? Colors.green[700] : Colors.orange[700],
        ),
      ),
      title: Text(vehicle.plate),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(vehicle.fullName),
          if (hasValidInsurance)
            Text(
              'Assuré - ${vehicle.activeContract!.companyName}',
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Text(
              'Assurance expirée ou manquante',
              style: TextStyle(
                color: Colors.orange[700],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
      trailing: const Icon(Icons.add),
      onTap: () {
        _addVehicleFromConducteur(vehicle);
        Navigator.of(context).pop();
      },
    );
  }

  void _addVehicleFromConducteur(ConducteurVehicleModel conducteurVehicle) {
    final sinistreVehicle = SinistreVehicleRef(
      vehicleId: conducteurVehicle.vehicleId,
      ownerUid: FirebaseAuth.instance.currentUser?.uid,
      isOwnerBoolean: conducteurVehicle.isConducteurOwner,
      plate: conducteurVehicle.plate,
      brand: conducteurVehicle.brand,
      model: conducteurVehicle.model,
    );

    setState(() {
      widget.wizardData.vehicles.add(sinistreVehicle);
    });

    // Afficher un message de confirmation avec les infos d'assurance
    if (conducteurVehicle.hasValidInsurance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Véhicule ajouté avec liaison automatique au contrat ${conducteurVehicle.activeContract!.contractNumber}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Véhicule ajouté - Attention: aucune assurance valide détectée',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showAddVehicleDialog({bool isOwner = false}) {
    showDialog(
      context: context,
      builder: (context) => _VehicleDialog(
        isOwner: isOwner,
        onSave: (vehicle) {
          setState(() {
            widget.wizardData.vehicles.add(vehicle);
          });
        },
      ),
    );
  }

  void _showEditVehicleDialog(SinistreVehicleRef vehicle, int index) {
    showDialog(
      context: context,
      builder: (context) => _VehicleDialog(
        vehicle: vehicle,
        isOwner: vehicle.isOwnerBoolean,
        onSave: (updatedVehicle) {
          setState(() {
            widget.wizardData.vehicles[index] = updatedVehicle;
          });
        },
      ),
    );
  }

  void _removeVehicle(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le véhicule'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce véhicule ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                widget.wizardData.vehicles.removeAt(index);
              });
              Navigator.of(context).pop();
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// 🚗 Dialog pour ajouter/modifier un véhicule
class _VehicleDialog extends StatefulWidget {
  final SinistreVehicleRef? vehicle;
  final bool isOwner;
  final Function(SinistreVehicleRef) onSave;

  const _VehicleDialog({
    this.vehicle,
    required this.isOwner,
    required this.onSave,
  });

  @override
  State<_VehicleDialog> createState() => _VehicleDialogState();
}

class _VehicleDialogState extends State<_VehicleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.vehicle != null) {
      _plateController.text = widget.vehicle!.plate ?? '';
      _brandController.text = widget.vehicle!.brand ?? '';
      _modelController.text = widget.vehicle!.model ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.vehicle == null ? 'Ajouter un véhicule' : 'Modifier le véhicule'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _plateController,
              decoration: const InputDecoration(
                labelText: 'Immatriculation *',
                hintText: 'Ex: 123 TUN 456',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir l\'immatriculation';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Marque',
                hintText: 'Ex: Peugeot',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Modèle',
                hintText: 'Ex: 208',
              ),
            ),
            if (widget.isOwner) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ce véhicule sera marqué comme le vôtre',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saveVehicle,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  void _saveVehicle() {
    if (_formKey.currentState!.validate()) {
      final vehicle = SinistreVehicleRef(
        vehicleId: widget.vehicle?.vehicleId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        ownerUid: widget.isOwner ? 'current_user' : null, // TODO: Récupérer l'UID réel
        isOwnerBoolean: widget.isOwner,
        plate: _plateController.text,
        brand: _brandController.text.isEmpty ? null : _brandController.text,
        model: _modelController.text.isEmpty ? null : _modelController.text,
      );

      widget.onSave(vehicle);
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _plateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    super.dispose();
  }
}
