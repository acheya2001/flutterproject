import 'package:flutter/material.dart';
import '../../../core/config/app_routes.dart';
// Pas besoin d'importer VehiculeModel ici car on ne le manipule pas directement

enum DeclarationStep { selectVehicleCount, selectOwnership }

class DeclarationEntryPointScreen extends StatefulWidget {
  const DeclarationEntryPointScreen({Key? key}) : super(key: key);

  @override
  _DeclarationEntryPointScreenState createState() => _DeclarationEntryPointScreenState();
}

class _DeclarationEntryPointScreenState extends State<DeclarationEntryPointScreen> {
  DeclarationStep _currentStep = DeclarationStep.selectVehicleCount;
  int _vehicleCount = 1; // 1 pour "1 Véhicule", 2 pour "2+ Véhicules"
  bool? _isOwner;

  void _nextStep() {
    if (_currentStep == DeclarationStep.selectVehicleCount) {
      setState(() {
        _currentStep = DeclarationStep.selectOwnership;
      });
    } else if (_currentStep == DeclarationStep.selectOwnership) {
      _navigateBasedOnSelection();
    }
  }

  void _navigateBasedOnSelection() {
    if (!mounted) return;

    if (_vehicleCount == 1) { // Cas "1 Véhicule"
      if (_isOwner == true) {
        Navigator.pushNamed(
          context, 
          AppRoutes.conducteurVehicules, 
          arguments: {'selectionMode': true} // conducteurId est géré par AppRoutes
        );
      } else {
        Navigator.pushNamed(
          context,
          AppRoutes.conducteurDeclaration,
          arguments: {
            'conducteurPosition': 'A', // Solo, donc 'A'
            'selectedVehicule': null, 
            'isCollaborative': false, // Ce n'est pas collaboratif
          },
        );
      }
    } else { // Cas "2+ Véhicules"
        Navigator.pushNamed(
           context, 
           AppRoutes.sessionCreation,
           arguments: {
             'initiatingVehicleCount': _vehicleCount, // Ici, on passe le nombre exact (ex: 2 si "2+ Véhicules" est sélectionné)
             'isOwnerOfInitiatingVehicle': _isOwner,
           }
        );
    }
  }

  Widget _buildVehicleCountSelector() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Combien de véhicules sont impliqués dans l\'accident ?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: const Color(0xFF0F172A)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildChoiceChip(label: '1 Véhicule', value: 1, groupValue: _vehicleCount, onChanged: (val) => setState(() => _vehicleCount = val)),
            _buildChoiceChip(label: '2+ Véhicules', value: 2, groupValue: _vehicleCount, onChanged: (val) => setState(() => _vehicleCount = val)),
          ],
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _nextStep,
          child: const Text('Suivant'),
        ),
      ],
    );
  }

  Widget _buildOwnershipSelector() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Êtes-vous propriétaire du véhicule que vous conduisiez ?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: const Color(0xFF0F172A)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildChoiceChip(label: 'Oui', value: true, groupValue: _isOwner, onChanged: (val) => setState(() => _isOwner = val)),
            _buildChoiceChip(label: 'Non', value: false, groupValue: _isOwner, onChanged: (val) => setState(() => _isOwner = val)),
          ],
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _isOwner != null ? _nextStep : null,
          child: const Text('Terminer et Continuer'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _currentStep = DeclarationStep.selectVehicleCount),
          child: const Text('Précédent'),
        ),
      ],
    );
  }

  Widget _buildChoiceChip<T>({required String label, required T value, required T? groupValue, required ValueChanged<T> onChanged}) {
    final bool isSelected = value == groupValue;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary, fontSize: 16, fontWeight: FontWeight.w600)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onChanged(value);
        }
      },
      backgroundColor: Colors.white,
      selectedColor: Theme.of(context).colorScheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Constat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep == DeclarationStep.selectOwnership) {
              setState(() {
                _currentStep = DeclarationStep.selectVehicleCount;
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _currentStep == DeclarationStep.selectVehicleCount
                ? _buildVehicleCountSelector()
                : _buildOwnershipSelector(),
          ),
        ),
      ),
    );
  }
}