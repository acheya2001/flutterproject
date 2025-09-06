import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../features/insurance/models/digital_contract_model.dart';
import '../../../features/insurance/models/insurance_structure_model.dart';
import '../../../services/digital_contract_service.dart';
// import '../../../common/widgets/custom_app_bar.dart';
// import '../../../common/widgets/loading_overlay.dart';

/// 👨‍💼 Écran de création de contrat par l'agent
class ContractCreationScreen extends StatefulWidget {
  final String vehicleId;
  final Map<String, dynamic> vehicleData;

  const ContractCreationScreen({
    Key? key,
    required this.vehicleId,
    required this.vehicleData,
  }) : super(key: key);

  @override
  State<ContractCreationScreen> createState() => _ContractCreationScreenState();
}

class _ContractCreationScreenState extends State<ContractCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  ContractType _selectedContractType = ContractType.responsabiliteCivile;
  PaymentFrequency _selectedPaymentFrequency = PaymentFrequency.annuel;

  // Garanties disponibles
  final Map<String, Garantie> _availableGaranties = {
    'rc': const Garantie(
      nom: 'Responsabilité Civile',
      description: 'Couverture obligatoire des dommages causés aux tiers',
      incluse: true,
      montant: 50000,
    ),
    'vol': const Garantie(
      nom: 'Vol',
      description: 'Protection contre le vol du véhicule',
      incluse: false,
      montant: 20000,
    ),
    'incendie': const Garantie(
      nom: 'Incendie',
      description: 'Protection contre les dommages d\'incendie',
      incluse: false,
      montant: 15000,
    ),
    'bris_glace': const Garantie(
      nom: 'Bris de Glace',
      description: 'Remplacement des vitres endommagées',
      incluse: false,
      montant: 5000,
      franchise: 100,
    ),
    'tous_risques': const Garantie(
      nom: 'Tous Risques',
      description: 'Couverture complète tous dommages',
      incluse: false,
      montant: 100000,
      franchise: 500,
    ),
  };

  Map<String, bool> _selectedGaranties = {};
  double _calculatedPrime = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeGaranties();
    _calculatePrime();
  }

  void _initializeGaranties() {
    // RC toujours incluse
    _selectedGaranties['rc'] = true;

    // Initialiser selon le type de contrat
    _updateGarantiesForContractType();
  }

  void _updateGarantiesForContractType() {
    switch (_selectedContractType) {
      case ContractType.responsabiliteCivile:
        _selectedGaranties = {'rc': true};
        break;
      case ContractType.tiersPlusVol:
        _selectedGaranties = {
          'rc': true,
          'vol': true,
          'incendie': true,
          'bris_glace': true,
        };
        break;
      case ContractType.tousRisques:
        _selectedGaranties = Map.fromEntries(
          _availableGaranties.keys.map((key) => MapEntry(key, true))
        );
        break;
      case ContractType.temporaire:
        _selectedGaranties = {'rc': true};
        break;
    }
    _calculatePrime();
  }

  void _calculatePrime() {
    double basePrime = _selectedContractType.basePrime;

    // Ajuster selon l'âge du véhicule
    final vehicleAge = DateTime.now().year - (widget.vehicleData['annee'] ?? DateTime.now().year);
    if (vehicleAge > 10) {
      basePrime *= 0.8; // Réduction pour véhicules anciens
    } else if (vehicleAge < 3) {
      basePrime *= 1.2; // Majoration pour véhicules récents
    }

    // Ajuster selon le type de véhicule
    final vehicleType = widget.vehicleData['typeVehicule'] ?? 'VP';
    switch (vehicleType) {
      case 'TAXI':
        basePrime *= 1.5;
        break;
      case 'VU':
        basePrime *= 1.3;
        break;
      case 'MOTO':
        basePrime *= 1.1;
        break;
    }

    setState(() {
      _calculatedPrime = basePrime;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Création de Contrat'),
            Text(
              '${widget.vehicleData['marque']} ${widget.vehicleData['modele']}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVehicleInfoCard(),
                const SizedBox(height: 20),
                _buildContractTypeSection(),
                const SizedBox(height: 20),
                _buildGarantiesSection(),
                const SizedBox(height: 20),
                _buildPaymentSection(),
                const SizedBox(height: 20),
                _buildPrimeCalculationCard(),
                const SizedBox(height: 30),
                _buildActionButtons(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildVehicleInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🚗 Informations du Véhicule',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Véhicule', '${widget.vehicleData['marque']} ${widget.vehicleData['modele']}'),
            _buildInfoRow('Immatriculation', widget.vehicleData['numeroImmatriculation'] ?? ''),
            _buildInfoRow('Année', '${widget.vehicleData['annee'] ?? ''}'),
            _buildInfoRow('Type', widget.vehicleData['typeVehicule'] ?? ''),
            _buildInfoRow('Conducteur', '${widget.vehicleData['conducteurPrenom']} ${widget.vehicleData['conducteurNom']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📋 Type de Contrat',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...ContractType.values.map((type) => RadioListTile<ContractType>(
              title: Text(type.displayName),
              subtitle: Text('Prime de base: ${type.basePrime.toStringAsFixed(0)} DT'),
              value: type,
              groupValue: _selectedContractType,
              onChanged: (value) {
                setState(() {
                  _selectedContractType = value!;
                  _updateGarantiesForContractType();
                });
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildGarantiesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🛡️ Garanties',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._availableGaranties.entries.map((entry) {
              final key = entry.key;
              final garantie = entry.value;
              final isSelected = _selectedGaranties[key] ?? false;
              final isRC = key == 'rc';

              return CheckboxListTile(
                title: Text(garantie.nom),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(garantie.description),
                    Text(
                      'Montant: ${garantie.montant.toStringAsFixed(0)} DT'
                      '${garantie.franchise > 0 ? ' - Franchise: ${garantie.franchise.toStringAsFixed(0)} DT' : ''}',
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ],
                ),
                value: isSelected,
                onChanged: isRC ? null : (value) {
                  setState(() {
                    _selectedGaranties[key] = value ?? false;
                    _calculatePrime();
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💳 Modalités de Paiement',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PaymentFrequency>(
              value: _selectedPaymentFrequency,
              decoration: const InputDecoration(
                labelText: 'Fréquence de paiement',
                border: OutlineInputBorder(),
              ),
              items: PaymentFrequency.values.map((freq) {
                return DropdownMenuItem(
                  value: freq,
                  child: Text('${freq.displayName} (${freq.installmentCount} versement${freq.installmentCount > 1 ? 's' : ''})'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPaymentFrequency = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimeCalculationCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💰 Calcul de la Prime',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Prime annuelle:'),
                Text(
                  '${_calculatedPrime.toStringAsFixed(2)} DT',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            if (_selectedPaymentFrequency != PaymentFrequency.annuel) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Par ${_selectedPaymentFrequency.displayName.toLowerCase()}:'),
                  Text(
                    '${(_calculatedPrime / _selectedPaymentFrequency.installmentCount).toStringAsFixed(2)} DT',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _saveAsDraft,
            icon: const Icon(Icons.save),
            label: const Text('Sauvegarder en brouillon'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _proposeContract,
            icon: const Icon(Icons.send),
            label: const Text('Proposer au conducteur'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveAsDraft() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final selectedGarantiesList = _selectedGaranties.entries
          .where((entry) => entry.value)
          .map((entry) => _availableGaranties[entry.key]!)
          .toList();

      final contractId = await DigitalContractService.startContractCreation(
        vehicleId: widget.vehicleId,
        agentId: user.uid,
        contractType: _selectedContractType,
        garanties: selectedGarantiesList,
        primeAnnuelle: _calculatedPrime,
        paymentFrequency: _selectedPaymentFrequency,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Contrat sauvegardé en brouillon'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }

    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sauvegarde: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _proposeContract() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // D'abord créer le contrat
      final selectedGarantiesList = _selectedGaranties.entries
          .where((entry) => entry.value)
          .map((entry) => _availableGaranties[entry.key]!)
          .toList();

      final contractId = await DigitalContractService.startContractCreation(
        vehicleId: widget.vehicleId,
        agentId: user.uid,
        contractType: _selectedContractType,
        garanties: selectedGarantiesList,
        primeAnnuelle: _calculatedPrime,
        paymentFrequency: _selectedPaymentFrequency,
      );

      // Puis le proposer au conducteur
      await DigitalContractService.proposeContractToConducteur(
        contractId: contractId,
        agentId: user.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Contrat proposé au conducteur avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pop();
      }

    } catch (e) {
      _showErrorSnackBar('Erreur lors de la proposition: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
