import 'package:flutter/material.dart';
import '../../../services/agent_service.dart';

/// ➕ Écran de création de contrat
class CreateContratScreen extends StatefulWidget {
  final Map<String, dynamic> agentData;

  const CreateContratScreen({
    Key? key,
    required this.agentData,
  }) : super(key: key);

  @override
  State<CreateContratScreen> createState() => _CreateContratScreenState();
}

class _CreateContratScreenState extends State<CreateContratScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numeroContratController = TextEditingController();
  final _nomAssureController = TextEditingController();
  final _prenomAssureController = TextEditingController();
  final _telephoneAssureController = TextEditingController();
  final _emailAssureController = TextEditingController();
  final _adresseAssureController = TextEditingController();
  final _cinAssureController = TextEditingController();
  final _montantPrimeController = TextEditingController();
  
  String _typeContrat = 'auto';
  DateTime? _dateDebut;
  DateTime? _dateFin;
  bool _isLoading = false;

  @override
  void dispose() {
    _numeroContratController.dispose();
    _nomAssureController.dispose();
    _prenomAssureController.dispose();
    _telephoneAssureController.dispose();
    _emailAssureController.dispose();
    _adresseAssureController.dispose();
    _cinAssureController.dispose();
    _montantPrimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Contenu principal
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _isLoading ? _buildLoadingContent() : _buildMainContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📋 Header
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.add_circle_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nouveau Contrat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Créer un contrat d\'assurance',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔄 Contenu de chargement
  Widget _buildLoadingContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF667EEA)),
          SizedBox(height: 20),
          Text(
            'Création du contrat en cours...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 📱 Contenu principal
  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations du contrat
            _buildContratInfoCard(),
            const SizedBox(height: 24),
            
            // Informations de l'assuré
            _buildAssureInfoCard(),
            const SizedBox(height: 30),
            
            // Boutons d'action
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  /// 📄 Carte informations du contrat
  Widget _buildContratInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.description_rounded,
                color: Color(0xFF667EEA),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Informations du Contrat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Numéro de contrat
          _buildTextField(
            controller: _numeroContratController,
            label: 'Numéro de contrat',
            icon: Icons.numbers_rounded,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le numéro de contrat est requis';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Type de contrat
          DropdownButtonFormField<String>(
            value: _typeContrat,
            decoration: InputDecoration(
              labelText: 'Type de contrat',
              prefixIcon: const Icon(Icons.category_rounded, color: Color(0xFF667EEA)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            items: const [
              DropdownMenuItem(value: 'auto', child: Text('Assurance Auto')),
              DropdownMenuItem(value: 'habitation', child: Text('Assurance Habitation')),
              DropdownMenuItem(value: 'sante', child: Text('Assurance Santé')),
              DropdownMenuItem(value: 'vie', child: Text('Assurance Vie')),
              DropdownMenuItem(value: 'autre', child: Text('Autre')),
            ],
            onChanged: (value) => setState(() => _typeContrat = value!),
          ),
          const SizedBox(height: 16),
          
          // Dates
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Date de début',
                  value: _dateDebut,
                  onTap: () => _selectDate(context, true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateField(
                  label: 'Date de fin',
                  value: _dateFin,
                  onTap: () => _selectDate(context, false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Montant de la prime
          _buildTextField(
            controller: _montantPrimeController,
            label: 'Montant de la prime (DT)',
            icon: Icons.attach_money_rounded,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le montant de la prime est requis';
              }
              if (double.tryParse(value) == null) {
                return 'Veuillez entrer un montant valide';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  /// 👤 Carte informations de l'assuré
  Widget _buildAssureInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.person_rounded,
                color: Color(0xFF667EEA),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Informations de l\'Assuré',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Nom et Prénom
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _prenomAssureController,
                  label: 'Prénom',
                  icon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le prénom est requis';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _nomAssureController,
                  label: 'Nom',
                  icon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom est requis';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // CIN
          _buildTextField(
            controller: _cinAssureController,
            label: 'CIN (optionnel)',
            icon: Icons.badge_rounded,
          ),
          const SizedBox(height: 16),
          
          // Téléphone et Email
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _telephoneAssureController,
                  label: 'Téléphone',
                  icon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le téléphone est requis';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _emailAssureController,
                  label: 'Email',
                  icon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'L\'email est requis';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Format d\'email invalide';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Adresse
          _buildTextField(
            controller: _adresseAssureController,
            label: 'Adresse (optionnel)',
            icon: Icons.location_on_rounded,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  /// 📝 Champ de texte
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF667EEA)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  /// 📅 Champ de date
  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: Color(0xFF667EEA)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value != null 
                        ? '${value.day}/${value.month}/${value.year}'
                        : 'Sélectionner',
                    style: TextStyle(
                      fontSize: 16,
                      color: value != null ? const Color(0xFF1F2937) : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🎯 Boutons d'action
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            label: const Text('Annuler'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _createContrat,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Créer le Contrat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  /// 📅 Sélectionner une date
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _dateDebut = picked;
          // Si la date de fin est antérieure à la date de début, la réinitialiser
          if (_dateFin != null && _dateFin!.isBefore(picked)) {
            _dateFin = null;
          }
        } else {
          _dateFin = picked;
        }
      });
    }
  }

  /// ➕ Créer le contrat
  Future<void> _createContrat() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_dateDebut == null || _dateFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner les dates de début et de fin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AgentService.createContrat(
        agentId: widget.agentData['id'],
        agenceId: widget.agentData['agenceId'],
        compagnieId: widget.agentData['compagnieId'],
        numeroContrat: _numeroContratController.text.trim(),
        typeContrat: _typeContrat,
        nomAssure: _nomAssureController.text.trim(),
        prenomAssure: _prenomAssureController.text.trim(),
        telephoneAssure: _telephoneAssureController.text.trim(),
        emailAssure: _emailAssureController.text.trim(),
        dateDebut: _dateDebut!,
        dateFin: _dateFin!,
        montantPrime: double.parse(_montantPrimeController.text.trim()),
        adresseAssure: _adresseAssureController.text.trim().isEmpty ? null : _adresseAssureController.text.trim(),
        cinAssure: _cinAssureController.text.trim().isEmpty ? null : _cinAssureController.text.trim(),
      );

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context, true); // Retourner avec succès
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
