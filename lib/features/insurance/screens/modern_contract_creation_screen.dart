import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/contrat_vehicule_service.dart';

/// 🎨 Interface moderne pour créer des contrats d'assurance
class ModernContractCreationScreen extends StatefulWidget {
  final String agentId;
  final String compagnieId;
  final String agenceId;

  const ModernContractCreationScreen({
    Key? key,
    required this.agentId,
    required this.compagnieId,
    required this.agenceId,
  }) : super(key: key);

  @override
  State<ModernContractCreationScreen> createState() => _ModernContractCreationScreenState();
}

class _ModernContractCreationScreenState extends State<ModernContractCreationScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Contrôleurs
  final _conducteurEmailController = TextEditingController();
  final _immatriculationController = TextEditingController();
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _anneeController = TextEditingController();
  final _couleurController = TextEditingController();
  final _numeroSerieController = TextEditingController();
  final _primeAnnuelleController = TextEditingController();
  final _primeMensuelleController = TextEditingController();

  // État
  int _currentPage = 0;
  bool _isLoading = false;
  String? _errorMessage;
  String? _conducteurId;
  String? _vehiculeId;

  // Sélections
  String _typeContrat = 'responsabilite_civile';
  String _typeVehicule = 'voiture';
  String _carburant = 'essence';
  DateTime _dateDebut = DateTime.now();
  DateTime _dateFin = DateTime.now().add(const Duration(days: 365));
  List<String> _couverturesSelectionnees = ['responsabilite_civile'];

  // Options
  final List<String> _typesContrat = [
    'responsabilite_civile',
    'tous_risques',
    'tiers_collision',
    'vol_incendie',
  ];

  final List<String> _typesVehicule = [
    'voiture',
    'moto',
    'camion',
    'utilitaire',
    'autocar',
  ];

  final List<String> _carburants = [
    'essence',
    'diesel',
    'electrique',
    'hybride',
    'gpl',
  ];

  final List<String> _couverturesDisponibles = [
    'responsabilite_civile',
    'dommages_collision',
    'vol',
    'incendie',
    'bris_de_glace',
    'catastrophes_naturelles',
    'assistance_depannage',
    'protection_juridique',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _conducteurEmailController.dispose();
    _immatriculationController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _anneeController.dispose();
    _couleurController.dispose();
    _numeroSerieController.dispose();
    _primeAnnuelleController.dispose();
    _primeMensuelleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Nouveau Contrat'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Indicateur de progression
            _buildProgressIndicator(),

            // Contenu principal
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildConducteurPage(),
                  _buildVehiculePage(),
                  _buildContratPage(),
                  _buildRecapitulatifPage(),
                ],
              ),
            ),

            // Boutons de navigation
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentPage;
          final isCompleted = index < _currentPage;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.blue[600] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < 3) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildConducteurPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            '👤 Rechercher le Conducteur',
            'Saisissez l\'email du conducteur pour créer le contrat',
          ),
          const SizedBox(height: 32),

          _buildTextField(
            controller: _conducteurEmailController,
            label: 'Email du conducteur',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: _rechercherConducteur,
            ),
          ),

          if (_conducteurId != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600]),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Conducteur trouvé ! Vous pouvez continuer.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVehiculePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            '🚗 Informations du Véhicule',
            'Saisissez les détails du véhicule à assurer',
          ),
          const SizedBox(height: 32),

          _buildTextField(
            controller: _immatriculationController,
            label: 'Immatriculation',
            icon: Icons.confirmation_number,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _marqueController,
                  label: 'Marque',
                  icon: Icons.directions_car,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _modeleController,
                  label: 'Modèle',
                  icon: Icons.car_rental,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _anneeController,
                  label: 'Année',
                  icon: Icons.calendar_today,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _couleurController,
                  label: 'Couleur',
                  icon: Icons.palette,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildDropdown(
            value: _typeVehicule,
            label: 'Type de véhicule',
            icon: Icons.category,
            items: _typesVehicule,
            onChanged: (value) => setState(() => _typeVehicule = value!),
          ),
          const SizedBox(height: 16),

          _buildDropdown(
            value: _carburant,
            label: 'Carburant',
            icon: Icons.local_gas_station,
            items: _carburants,
            onChanged: (value) => setState(() => _carburant = value!),
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _numeroSerieController,
            label: 'Numéro de série/châssis',
            icon: Icons.qr_code,
          ),
        ],
      ),
    );
  }

  Widget _buildContratPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            '📄 Détails du Contrat',
            'Configurez les conditions du contrat d\'assurance',
          ),
          const SizedBox(height: 32),

          _buildDropdown(
            value: _typeContrat,
            label: 'Type de contrat',
            icon: Icons.description,
            items: _typesContrat,
            onChanged: (value) => setState(() => _typeContrat = value!),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Date de début',
                  date: _dateDebut,
                  onChanged: (date) => setState(() => _dateDebut = date),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateField(
                  label: 'Date de fin',
                  date: _dateFin,
                  onChanged: (date) => setState(() => _dateFin = date),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _primeAnnuelleController,
                  label: 'Prime annuelle (TND)',
                  icon: Icons.monetization_on,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _primeMensuelleController,
                  label: 'Prime mensuelle (TND)',
                  icon: Icons.payment,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            'Couvertures incluses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 16),

          ..._couverturesDisponibles.map((couverture) {
            return CheckboxListTile(
              title: Text(_formatCouverture(couverture)),
              value: _couverturesSelectionnees.contains(couverture),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _couverturesSelectionnees.add(couverture);
                  } else {
                    _couverturesSelectionnees.remove(couverture);
                  }
                });
              },
              activeColor: Colors.blue[600],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecapitulatifPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            '📋 Récapitulatif',
            'Vérifiez les informations avant de créer le contrat',
          ),
          const SizedBox(height: 32),

          _buildRecapSection('Conducteur', [
            'Email: ${_conducteurEmailController.text}',
          ]),

          _buildRecapSection('Véhicule', [
            'Immatriculation: ${_immatriculationController.text}',
            'Marque: ${_marqueController.text}',
            'Modèle: ${_modeleController.text}',
            'Année: ${_anneeController.text}',
            'Type: $_typeVehicule',
            'Carburant: $_carburant',
          ]),

          _buildRecapSection('Contrat', [
            'Type: $_typeContrat',
            'Période: ${_formatDate(_dateDebut)} - ${_formatDate(_dateFin)}',
            'Prime annuelle: ${_primeAnnuelleController.text} TND',
            'Prime mensuelle: ${_primeMensuelleController.text} TND',
            'Couvertures: ${_couverturesSelectionnees.length} sélectionnées',
          ]),

          if (_isLoading) ...[
            const SizedBox(height: 32),
            const Center(
              child: CircularProgressIndicator(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPageHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[600]),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(_formatOption(item)),
        );
      }).toList(),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required void Function(DateTime) onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final newDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 3650)),
        );
        if (newDate != null) {
          onChanged(newDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.blue[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    _formatDate(date),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecapSection(String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(item),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentPage > 0) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _previousPage,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Précédent'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: _currentPage == 0 ? 1 : 1,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : (_currentPage == 3 ? _creerContrat : _nextPage),
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_currentPage == 3 ? Icons.save : Icons.arrow_forward),
              label: Text(_currentPage == 3 ? 'Créer le contrat' : 'Suivant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < 3) {
      if (_validateCurrentPage()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentPage() {
    setState(() => _errorMessage = null);

    switch (_currentPage) {
      case 0:
        if (_conducteurId == null) {
          setState(() => _errorMessage = 'Veuillez rechercher et sélectionner un conducteur');
          return false;
        }
        break;
      case 1:
        if (_immatriculationController.text.isEmpty ||
            _marqueController.text.isEmpty ||
            _modeleController.text.isEmpty ||
            _anneeController.text.isEmpty) {
          setState(() => _errorMessage = 'Veuillez remplir tous les champs obligatoires');
          return false;
        }
        break;
      case 2:
        if (_primeAnnuelleController.text.isEmpty ||
            _primeMensuelleController.text.isEmpty) {
          setState(() => _errorMessage = 'Veuillez saisir les montants des primes');
          return false;
        }
        if (_couverturesSelectionnees.isEmpty) {
          setState(() => _errorMessage = 'Veuillez sélectionner au moins une couverture');
          return false;
        }
        break;
    }
    return true;
  }

  Future<void> _rechercherConducteur() async {
    final email = _conducteurEmailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final query = await FirebaseFirestore.instance
          .collection('conducteurs')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        setState(() {
          _conducteurId = query.docs.first.id;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _conducteurId = null;
          _errorMessage = 'Aucun conducteur trouvé avec cet email';
        });
      }
    } catch (e) {
      setState(() {
        _conducteurId = null;
        _errorMessage = 'Erreur lors de la recherche: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _creerContrat() async {
    if (!_validateCurrentPage()) return;

    setState(() => _isLoading = true);

    try {
      // Créer d'abord le véhicule
      final vehiculeId = await ContratVehiculeService.creerVehicule(
        conducteurId: _conducteurId!,
        immatriculation: _immatriculationController.text.trim(),
        marque: _marqueController.text.trim(),
        modele: _modeleController.text.trim(),
        annee: int.parse(_anneeController.text),
        couleur: _couleurController.text.trim(),
        numeroSerie: _numeroSerieController.text.trim(),
        typeVehicule: _typeVehicule,
        carburant: _carburant,
      );

      if (vehiculeId == null) {
        throw Exception('Erreur lors de la création du véhicule');
      }

      // Créer le contrat
      final contratId = await ContratVehiculeService.creerContrat(
        compagnieId: widget.compagnieId,
        agenceId: widget.agenceId,
        agentId: widget.agentId,
        conducteurId: _conducteurId!,
        vehiculeId: vehiculeId,
        typeContrat: _typeContrat,
        dateDebut: _dateDebut,
        dateFin: _dateFin,
        prime: {
          'montantAnnuel': double.parse(_primeAnnuelleController.text),
          'montantMensuel': double.parse(_primeMensuelleController.text),
          'devise': 'TND',
        },
        couvertures: _couverturesSelectionnees,
      );

      if (contratId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Contrat créé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Erreur lors de la création du contrat');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatOption(String option) {
    return option.replaceAll('_', ' ').split(' ').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  String _formatCouverture(String couverture) {
    final Map<String, String> labels = {
      'responsabilite_civile': 'Responsabilité civile',
      'dommages_collision': 'Dommages collision',
      'vol': 'Vol',
      'incendie': 'Incendie',
      'bris_de_glace': 'Bris de glace',
      'catastrophes_naturelles': 'Catastrophes naturelles',
      'assistance_depannage': 'Assistance dépannage',
      'protection_juridique': 'Protection juridique',
    };
    return labels[couverture] ?? _formatOption(couverture);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}