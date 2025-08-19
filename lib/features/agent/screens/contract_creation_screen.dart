import 'package:flutter/material.dart';
import '../../insurance/models/insurance_structure_model.dart';

/// 📋 Écran de création de contrat (placeholder)
class ContractCreationScreen extends StatelessWidget {
  final PendingVehicle vehicle;

  const ContractCreationScreen({
    Key? key,
    required this.vehicle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Création de Contrat'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Écran de création de contrat\n(À implémenter dans la prochaine tâche)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
