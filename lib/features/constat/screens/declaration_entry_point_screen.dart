import 'package:flutter/material.dart';

class DeclarationEntryPointScreen extends StatefulWidget {
  const DeclarationEntryPointScreen({super.key});

  @override
  State<DeclarationEntryPointScreen> createState() => _DeclarationEntryPointScreenState();
}

class _DeclarationEntryPointScreenState extends State<DeclarationEntryPointScreen> {
  int _currentStep = 0;
  int? _vehicleCount;
  bool? _isOwner;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Constat'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentStep + 1) / 3,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: _buildCurrentStep(),
            ),

            // Navigation buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  ElevatedButton(
                    onPressed: () {
                      if (mounted) setState(() {
                        _currentStep--;
                      });
                    },
                    child: const Text('Précédent'),
                  )
                else
                  const SizedBox(),

                ElevatedButton(
                  onPressed: _canProceed() ? _handleNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_currentStep == 2 ? 'Commencer' : 'Suivant'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildVehicleCountStep();
      case 1:
        return _buildOwnershipStep();
      case 2:
        return _buildSummaryStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildVehicleCountStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.directions_car,
          size: 80,
          color: Color(0xFF3B82F6),
        ),
        const SizedBox(height: 24),
        const Text(
          'Combien de véhicules sont impliqués dans l\'accident ?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: _buildChoiceCard(
                title: '1 Véhicule',
                subtitle: 'Accident simple',
                icon: Icons.directions_car,
                isSelected: _vehicleCount == 1,
                onTap: () => setState(() => _vehicleCount = 1),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChoiceCard(
                title: '2+ Véhicules',
                subtitle: 'Collision multiple',
                icon: Icons.car_crash,
                isSelected: _vehicleCount == 2,
                onTap: () => setState(() => _vehicleCount = 2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOwnershipStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.person,
          size: 80,
          color: Color(0xFF3B82F6),
        ),
        const SizedBox(height: 24),
        const Text(
          'Êtes-vous propriétaire du véhicule que vous conduisiez ?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: _buildChoiceCard(
                title: 'Oui',
                subtitle: 'Je suis propriétaire',
                icon: Icons.check_circle,
                isSelected: _isOwner == true,
                onTap: () => setState(() => _isOwner = true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChoiceCard(
                title: 'Non',
                subtitle: 'Je ne suis pas propriétaire',
                icon: Icons.cancel,
                isSelected: _isOwner == false,
                onTap: () => setState(() => _isOwner = false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.assignment_turned_in,
          size: 80,
          color: Color(0xFF10B981),
        ),
        const SizedBox(height: 24),
        const Text(
          'Récapitulatif',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSummaryRow('Véhicules impliqués', _vehicleCount == 1 ? '1 véhicule' : '2+ véhicules'),
                const Divider(),
                _buildSummaryRow('Propriétaire', _isOwner == true ? 'Oui' : 'Non'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Vous allez être redirigé vers le formulaire de constat.',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF64748B),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildChoiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.1) : Colors.white,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? const Color(0xFF3B82F6) : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF3B82F6) : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(color: Color(0xFF3B82F6)),
        ),
      ],
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _vehicleCount != null;
      case 1:
        return _isOwner != null;
      case 2:
        return true;
      default:
        return false;
    }
  }

  void _handleNext() {
    if (_currentStep < 2) {
      if (mounted) setState(() {
        _currentStep++;
      });
    } else {
      // Commencer le constat
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Redirection vers le formulaire de constat...'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      // TODO: Navigate to actual constat form
      Navigator.pop(context);
    }
  }
}
