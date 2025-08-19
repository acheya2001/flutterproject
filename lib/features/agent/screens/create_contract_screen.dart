import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/contract_service.dart';
import '../widgets/contract_number_widget.dart';

/// 📝 Écran de création de contrat d'assurance
class CreateContractScreen extends StatefulWidget {
  final String vehiculeId;
  final Map<String, dynamic> vehiculeData;
  final String agenceId;

  const CreateContractScreen({
    Key? key,
    required this.vehiculeId,
    required this.vehiculeData,
    required this.agenceId,
  }) : super(key: key);

  @override
  State<CreateContractScreen> createState() => _CreateContractScreenState();
}

class _CreateContractScreenState extends State<CreateContractScreen> {
  final _formKey = GlobalKey<FormState>();
  final _primeController = TextEditingController();
  
  String _typeCouverture = 'responsabilite_civile';
  DateTime _dateDebut = DateTime.now();
  DateTime _dateFin = DateTime.now().add(const Duration(days: 365));
  String? _compagnieId;
  String? _numeroContrat;
  bool _isLoading = false;

  final List<Map<String, String>> _typesCouverture = [
    {'value': 'responsabilite_civile', 'label': 'Responsabilité Civile'},
    {'value': 'tous_risques', 'label': 'Tous Risques'},
    {'value': 'vol_incendie', 'label': 'Vol + Incendie'},
    {'value': 'tiers_collision', 'label': 'Tiers + Collision'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCompagnieInfo();
  }

  Future<void> _loadCompagnieInfo() async {
    try {
      final agenceDoc = await FirebaseFirestore.instance
          .collection('agences')
          .doc(widget.agenceId)
          .get();
      
      if (agenceDoc.exists) {
        setState(() {
          _compagnieId = agenceDoc.data()!['compagnieId'];
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement compagnie: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un contrat'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Infos véhicule
              _buildVehiculeInfo(),

              const SizedBox(height: 24),

              // Numéro de contrat automatique
              if (_compagnieId != null)
                ContractNumberWidget(
                  compagnieId: _compagnieId!,
                  agenceId: widget.agenceId,
                  typeContrat: _typeCouverture,
                  onNumberGenerated: (numero) {
                    setState(() => _numeroContrat = numero);
                  },
                ),

              const SizedBox(height: 24),

              // Formulaire contrat
              _buildContractForm(),
              
              const SizedBox(height: 32),
              
              // Bouton de création
              _buildCreateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehiculeInfo() {
    final marque = widget.vehiculeData['marque'] ?? '';
    final modele = widget.vehiculeData['modele'] ?? '';
    final immatriculation = widget.vehiculeData['immatriculation'] ?? '';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_car,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Véhicule à assurer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$marque $modele',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Immatriculation: $immatriculation',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Détails du contrat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Type de couverture
            DropdownButtonFormField<String>(
              value: _typeCouverture,
              decoration: const InputDecoration(
                labelText: 'Type de couverture',
                border: OutlineInputBorder(),
              ),
              items: _typesCouverture.map((type) {
                return DropdownMenuItem(
                  value: type['value'],
                  child: Text(type['label']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _typeCouverture = value!;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Prime d'assurance
            TextFormField(
              controller: _primeController,
              decoration: const InputDecoration(
                labelText: 'Prime d\'assurance (TND)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir la prime d\'assurance';
                }
                final prime = double.tryParse(value);
                if (prime == null || prime <= 0) {
                  return 'Veuillez saisir un montant valide';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Dates
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date de début',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        '${_dateDebut.day}/${_dateDebut.month}/${_dateDebut.year}',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date de fin',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event),
                      ),
                      child: Text(
                        '${_dateFin.day}/${_dateFin.month}/${_dateFin.year}',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _createContract,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.assignment_add),
        label: Text(_isLoading ? 'Création en cours...' : 'Créer le contrat'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _dateDebut : _dateFin,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1095)), // 3 ans
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _dateDebut = picked;
          // Ajuster la date de fin si nécessaire
          if (_dateFin.isBefore(_dateDebut)) {
            _dateFin = _dateDebut.add(const Duration(days: 365));
          }
        } else {
          _dateFin = picked;
        }
      });
    }
  }

  Future<void> _createContract() async {
    if (!_formKey.currentState!.validate()) return;
    if (_compagnieId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: Compagnie non trouvée')),
      );
      return;
    }
    if (_numeroContrat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: Numéro de contrat non généré')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prime = double.parse(_primeController.text);
      final conducteurId = widget.vehiculeData['conducteurId'];

      final contractId = await ContractService.createContract(
        vehiculeId: widget.vehiculeId,
        conducteurId: conducteurId,
        agenceId: widget.agenceId,
        compagnieId: _compagnieId!,
        typeCouverture: _typeCouverture,
        primeAssurance: prime,
        dateDebut: _dateDebut,
        dateFin: _dateFin,
      );

      if (contractId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Contrat créé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Échec de création du contrat');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _primeController.dispose();
    super.dispose();
  }
}
