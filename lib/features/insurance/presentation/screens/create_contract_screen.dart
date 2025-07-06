import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/models/user_model.dart';
import '../../models/contrat_assurance_model.dart';
import '../../models/vehicule_assure_model.dart';
import '../../services/insurance_contract_service.dart';

/// 📋 Écran de création de contrat d'assurance
class CreateContractScreen extends StatefulWidget {
  final UserModel agent;
  
  const CreateContractScreen({
    Key? key,
    required this.agent,
  }) : super(key: key);

  @override
  State<CreateContractScreen> createState() => _CreateContractScreenState();
}

class _CreateContractScreenState extends State<CreateContractScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Contrôleurs pour les champs
  final _numeroContratController = TextEditingController();
  final _conducteurEmailController = TextEditingController();
  final _primeController = TextEditingController();
  final _franchiseController = TextEditingController();
  final _numeroQuittanceController = TextEditingController();

  // Données du contrat
  String _typeAssurance = 'tiers';
  DateTime _dateDebut = DateTime.now();
  DateTime _dateFin = DateTime.now().add(const Duration(days: 365));
  DateTime _dateQuittance = DateTime.now();
  UserModel? _selectedConducteur;
  VehiculeAssure? _selectedVehicule;

  @override
  void initState() {
    super.initState();
    _generateContractNumber();
  }

  @override
  void dispose() {
    _numeroContratController.dispose();
    _conducteurEmailController.dispose();
    _primeController.dispose();
    _franchiseController.dispose();
    _numeroQuittanceController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// Générer un numéro de contrat automatique
  void _generateContractNumber() {
    final now = DateTime.now();
    final companyCode = widget.agent.compagnieId.substring(0, 3).toUpperCase();
    final agencyCode = widget.agent.agenceId.substring(0, 2).toUpperCase();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final random = (DateTime.now().millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');
    
    _numeroContratController.text = '$companyCode-$agencyCode-$timestamp-$random';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: _buildModernAppBar(),
      body: Column(
        children: [
          // Indicateur de progression
          _buildProgressIndicator(),
          
          // Contenu principal
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                _buildStep1_ContractInfo(),
                _buildStep2_DriverSelection(),
                _buildStep3_VehicleSelection(),
                _buildStep4_Confirmation(),
              ],
            ),
          ),
          
          // Navigation
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  /// AppBar moderne
  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
      ),
      title: const Text(
        'Nouveau Contrat',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
    );
  }

  /// Indicateur de progression moderne
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                // Cercle d'étape
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          )
                        : null,
                    color: isActive ? null : Colors.grey.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : Icons.circle,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                
                // Ligne de connexion
                if (index < 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: isCompleted
                            ? const LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              )
                            : null,
                        color: isCompleted ? null : Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// Étape 1: Informations du contrat
  Widget _buildStep1_ContractInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepTitle('📋 Informations du Contrat', 'Renseignez les détails du contrat'),
            
            const SizedBox(height: 24),
            
            // Numéro de contrat
            _buildModernTextField(
              controller: _numeroContratController,
              label: 'Numéro de Contrat',
              icon: Icons.numbers,
              readOnly: true,
              suffixIcon: IconButton(
                onPressed: _generateContractNumber,
                icon: const Icon(Icons.refresh, color: Color(0xFF667EEA)),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Type d'assurance
            _buildAssuranceTypeSelector(),
            
            const SizedBox(height: 16),
            
            // Dates
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    label: 'Date de début',
                    value: _dateDebut,
                    onChanged: (date) => setState(() => _dateDebut = date),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(
                    label: 'Date de fin',
                    value: _dateFin,
                    onChanged: (date) => setState(() => _dateFin = date),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Prime et franchise
            Row(
              children: [
                Expanded(
                  child: _buildModernTextField(
                    controller: _primeController,
                    label: 'Prime (TND)',
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Champ requis';
                      if (double.tryParse(value!) == null) return 'Montant invalide';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildModernTextField(
                    controller: _franchiseController,
                    label: 'Franchise (TND)',
                    icon: Icons.money_off,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Champ requis';
                      if (double.tryParse(value!) == null) return 'Montant invalide';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Numéro de quittance et date
            Row(
              children: [
                Expanded(
                  child: _buildModernTextField(
                    controller: _numeroQuittanceController,
                    label: 'N° Quittance',
                    icon: Icons.receipt,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Champ requis';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(
                    label: 'Date quittance',
                    value: _dateQuittance,
                    onChanged: (date) => setState(() => _dateQuittance = date),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Titre d'étape moderne
  Widget _buildStepTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ).createShader(bounds),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[400],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Champ de texte moderne
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        readOnly: readOnly,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
          ),
          filled: true,
          fillColor: const Color(0xFF1A1A2E),
          labelStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500),
          floatingLabelStyle: const TextStyle(color: Color(0xFF667EEA), fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  /// Sélecteur de type d'assurance
  Widget _buildAssuranceTypeSelector() {
    final types = [
      {'value': 'tiers', 'label': 'Responsabilité Civile', 'icon': Icons.shield_outlined},
      {'value': 'tiers_vol_incendie', 'label': 'Tiers + Vol/Incendie', 'icon': Icons.security},
      {'value': 'tous_risques', 'label': 'Tous Risques', 'icon': Icons.verified_user},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type d\'assurance',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...types.map((type) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _typeAssurance == type['value']
                  ? const Color(0xFF667EEA)
                  : Colors.grey.withValues(alpha: 0.3),
              width: _typeAssurance == type['value'] ? 2 : 1,
            ),
            color: _typeAssurance == type['value']
                ? const Color(0xFF667EEA).withValues(alpha: 0.1)
                : const Color(0xFF1A1A2E),
          ),
          child: RadioListTile<String>(
            value: type['value'] as String,
            groupValue: _typeAssurance,
            onChanged: (value) => setState(() => _typeAssurance = value!),
            title: Row(
              children: [
                Icon(
                  type['icon'] as IconData,
                  color: _typeAssurance == type['value']
                      ? const Color(0xFF667EEA)
                      : Colors.grey[400],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  type['label'] as String,
                  style: TextStyle(
                    color: _typeAssurance == type['value']
                        ? const Color(0xFF667EEA)
                        : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            activeColor: const Color(0xFF667EEA),
          ),
        )),
      ],
    );
  }

  /// Champ de date
  Widget _buildDateField({
    required String label,
    required DateTime value,
    required Function(DateTime) onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        );
        if (date != null) onChanged(date);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          color: const Color(0xFF1A1A2E),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Étape 2: Sélection du conducteur (placeholder)
  Widget _buildStep2_DriverSelection() {
    return const Center(
      child: Text(
        'Sélection du conducteur\n(À implémenter)',
        style: TextStyle(color: Colors.white, fontSize: 18),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Étape 3: Sélection du véhicule (placeholder)
  Widget _buildStep3_VehicleSelection() {
    return const Center(
      child: Text(
        'Sélection du véhicule\n(À implémenter)',
        style: TextStyle(color: Colors.white, fontSize: 18),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Étape 4: Confirmation (placeholder)
  Widget _buildStep4_Confirmation() {
    return const Center(
      child: Text(
        'Confirmation du contrat\n(À implémenter)',
        style: TextStyle(color: Colors.white, fontSize: 18),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Boutons de navigation
  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF667EEA), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Précédent',
                  style: TextStyle(
                    color: Color(0xFF667EEA),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          
          if (_currentStep > 0) const SizedBox(width: 16),
          
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleNextStep,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF667EEA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _currentStep == 3 ? 'Créer le Contrat' : 'Suivant',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Gérer l'étape suivante
  void _handleNextStep() {
    if (_currentStep == 0) {
      if (_formKey.currentState?.validate() ?? false) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _createContract();
    }
  }

  /// Créer le contrat
  Future<void> _createContract() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Implémenter la création du contrat
      await Future.delayed(const Duration(seconds: 2)); // Simulation
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contrat créé avec succès!'),
            backgroundColor: Colors.green,
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
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
