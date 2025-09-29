import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/collaborative_session_model.dart';
import '../../../models/guest_participant_model.dart';
import '../../../services/collaborative_session_service.dart';
import '../../../services/guest_participant_service.dart';

/// 📝 Formulaire de constat complet pour conducteur invité (non inscrit)
/// Structure similaire au formulaire principal mais adapté pour les non-inscrits
class GuestAccidentFormScreen extends StatefulWidget {
  final CollaborativeSession session;

  const GuestAccidentFormScreen({
    Key? key,
    required this.session,
  }) : super(key: key);

  @override
  State<GuestAccidentFormScreen> createState() => _GuestAccidentFormScreenState();
}

class _GuestAccidentFormScreenState extends State<GuestAccidentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  int _currentStep = 0;
  final int _totalSteps = 8; // 8 étapes comme le formulaire principal

  // === CONTRÔLEURS POUR TOUTES LES ÉTAPES ===

  // 1. Informations personnelles du conducteur
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _cinController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _adresseController = TextEditingController();
  final _villeController = TextEditingController();
  final _codePostalController = TextEditingController();
  final _professionController = TextEditingController();
  final _numeroPermisController = TextEditingController();
  final _categoriePermisController = TextEditingController();
  DateTime? _dateNaissance;
  DateTime? _dateDelivrancePermis;

  // 2. Informations véhicule
  final _immatriculationController = TextEditingController();
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _couleurController = TextEditingController();
  final _numeroSerieController = TextEditingController();
  final _puissanceFiscaleController = TextEditingController();
  final _nombrePlacesController = TextEditingController();
  String _typeCarburant = 'Essence';
  String _usageVehicule = 'Personnel';
  int? _anneeConstruction;

  // 3. Informations assurance
  final _compagnieController = TextEditingController();
  final _agenceController = TextEditingController();
  final _numeroContratController = TextEditingController();
  final _numeroAttestationController = TextEditingController();
  final _typeContratController = TextEditingController();
  DateTime? _dateDebutContrat;
  DateTime? _dateFinContrat;
  bool _assuranceValide = true;

  // 4. Informations assuré (si différent du conducteur)
  bool _conducteurEstAssure = true;
  final _assureNomController = TextEditingController();
  final _assurePrenomController = TextEditingController();
  final _assureCinController = TextEditingController();
  final _assureAdresseController = TextEditingController();
  final _assureTelephoneController = TextEditingController();

  // 5. Points de choc et dégâts
  List<String> _pointsChocSelectionnes = [];
  List<String> _degatsApparents = [];
  final _descriptionDegatsController = TextEditingController();

  // 6. Circonstances de l'accident
  List<String> _circonstancesSelectionnees = [];
  final _observationsController = TextEditingController();

  // 7. Témoins
  List<Map<String, String>> _temoins = [];

  // 8. Photos et documents
  List<String> _photosUrls = [];

  // Variables d'état
  String _roleVehicule = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _determinerRoleVehicule();
  }

  @override
  void dispose() {
    // Dispose de tous les contrôleurs
    _nomController.dispose();
    _prenomController.dispose();
    _cinController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    _villeController.dispose();
    _codePostalController.dispose();
    _professionController.dispose();
    _numeroPermisController.dispose();
    _categoriePermisController.dispose();
    _immatriculationController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _couleurController.dispose();
    _numeroSerieController.dispose();
    _puissanceFiscaleController.dispose();
    _nombrePlacesController.dispose();
    _compagnieController.dispose();
    _agenceController.dispose();
    _numeroContratController.dispose();
    _numeroAttestationController.dispose();
    _typeContratController.dispose();
    _assureNomController.dispose();
    _assurePrenomController.dispose();
    _assureCinController.dispose();
    _assureAdresseController.dispose();
    _assureTelephoneController.dispose();
    _descriptionDegatsController.dispose();
    _observationsController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// 🎯 Déterminer le rôle du véhicule automatiquement
  void _determinerRoleVehicule() {
    final roles = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'];
    final rolesUtilises = widget.session.participants.map((p) => p.roleVehicule).toSet();
    
    for (final role in roles) {
      if (!rolesUtilises.contains(role)) {
        _roleVehicule = role;
        break;
      }
    }
    
    if (_roleVehicule.isEmpty) {
      _roleVehicule = 'Z'; // Fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Formulaire Invité - Véhicule $_roleVehicule',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green[600],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Indicateur de progression
          _buildProgressIndicator(),
          
          // Contenu du formulaire
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              children: [
                _buildStep1PersonalInfo(),      // 1. Informations personnelles
                _buildStep2VehicleInfo(),       // 2. Informations véhicule
                _buildStep3InsuranceInfo(),     // 3. Informations assurance
                _buildStep4AssuredInfo(),       // 4. Informations assuré
                _buildStep5DamageInfo(),        // 5. Points de choc et dégâts
                _buildStep6Circumstances(),     // 6. Circonstances
                _buildStep7Witnesses(),         // 7. Témoins
                _buildStep8PhotosDocuments(),   // 8. Photos et documents
              ],
            ),
          ),
          
          // Boutons de navigation
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  /// 📊 Indicateur de progression
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps, (index) {
              final isActive = index <= _currentStep;
              final isCompleted = index < _currentStep;
              
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    right: index < _totalSteps - 1 ? 8 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green[600] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'Étape ${_currentStep + 1} sur $_totalSteps - ${_getStepTitle()}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 👤 ÉTAPE 1: Informations personnelles du conducteur
  Widget _buildStep1PersonalInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              'Informations Personnelles du Conducteur',
              'Renseignez vos informations personnelles complètes',
              Icons.person,
            ),

            const SizedBox(height: 24),

            // Nom et Prénom
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _nomController,
                    label: 'Nom *',
                    validator: (value) => value?.isEmpty == true ? 'Nom requis' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _prenomController,
                    label: 'Prénom *',
                    validator: (value) => value?.isEmpty == true ? 'Prénom requis' : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // CIN et Date de naissance
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _cinController,
                    label: 'Numéro CIN *',
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.isEmpty == true ? 'CIN requis' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(
                    label: 'Date de naissance',
                    selectedDate: _dateNaissance,
                    onDateSelected: (date) => setState(() => _dateNaissance = date),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Téléphone et Email
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _telephoneController,
                    label: 'Téléphone *',
                    keyboardType: TextInputType.phone,
                    validator: (value) => value?.isEmpty == true ? 'Téléphone requis' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Adresse complète
            _buildTextField(
              controller: _adresseController,
              label: 'Adresse complète *',
              validator: (value) => value?.isEmpty == true ? 'Adresse requise' : null,
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            // Ville et Code postal
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _villeController,
                    label: 'Ville *',
                    validator: (value) => value?.isEmpty == true ? 'Ville requise' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _codePostalController,
                    label: 'Code Postal',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Profession
            _buildTextField(
              controller: _professionController,
              label: 'Profession',
            ),

            const SizedBox(height: 24),

            // Section Permis de conduire
            _buildSectionTitle('Permis de Conduire'),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _numeroPermisController,
                    label: 'Numéro de permis *',
                    validator: (value) => value?.isEmpty == true ? 'Numéro de permis requis' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _categoriePermisController,
                    label: 'Catégorie *',
                    validator: (value) => value?.isEmpty == true ? 'Catégorie requise' : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildDateField(
              label: 'Date de délivrance du permis *',
              selectedDate: _dateDelivrancePermis,
              onDateSelected: (date) => setState(() => _dateDelivrancePermis = date),
              validator: () => _dateDelivrancePermis == null ? 'Date de délivrance requise' : null,
            ),
          ],
        ),
      ),
    );
  }

  /// 🚗 ÉTAPE 2: Informations véhicule complètes
  Widget _buildStep2VehicleInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Informations du Véhicule',
            'Renseignez toutes les informations de votre véhicule',
            Icons.directions_car,
          ),

          const SizedBox(height: 24),

          // Immatriculation et Pays
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                  controller: _immatriculationController,
                  label: 'Numéro d\'immatriculation *',
                  validator: (value) => value?.isEmpty == true ? 'Immatriculation requise' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: TextEditingController(text: 'Tunisie'),
                  label: 'Pays',
                  enabled: false,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Marque et Modèle
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _marqueController,
                  label: 'Marque *',
                  validator: (value) => value?.isEmpty == true ? 'Marque requise' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _modeleController,
                  label: 'Modèle *',
                  validator: (value) => value?.isEmpty == true ? 'Modèle requis' : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Couleur et Année
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _couleurController,
                  label: 'Couleur *',
                  validator: (value) => value?.isEmpty == true ? 'Couleur requise' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: TextEditingController(
                    text: _anneeConstruction?.toString() ?? ''
                  ),
                  label: 'Année de construction',
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _anneeConstruction = int.tryParse(value);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Numéro de série (VIN)
          _buildTextField(
            controller: _numeroSerieController,
            label: 'Numéro de série (VIN)',
          ),

          const SizedBox(height: 16),

          // Type de carburant
          _buildDropdownField(
            label: 'Type de carburant *',
            value: _typeCarburant,
            items: ['Essence', 'Diesel', 'GPL', 'Hybride', 'Électrique'],
            onChanged: (value) => setState(() => _typeCarburant = value!),
          ),

          const SizedBox(height: 16),

          // Puissance fiscale et Nombre de places
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _puissanceFiscaleController,
                  label: 'Puissance fiscale (CV)',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _nombrePlacesController,
                  label: 'Nombre de places',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Usage du véhicule
          _buildDropdownField(
            label: 'Usage du véhicule *',
            value: _usageVehicule,
            items: ['Personnel', 'Professionnel', 'Mixte', 'Location'],
            onChanged: (value) => setState(() => _usageVehicule = value!),
          ),
        ],
      ),
    );
  }

  /// 🏢 ÉTAPE 3: Informations d'assurance complètes
  Widget _buildStep3InsuranceInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Informations d\'Assurance',
            'Renseignez toutes les informations de votre contrat d\'assurance',
            Icons.security,
          ),

          const SizedBox(height: 24),

          // Compagnie d'assurance et Agence
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _compagnieController,
                  label: 'Compagnie d\'assurance *',
                  validator: (value) => value?.isEmpty == true ? 'Compagnie requise' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _agenceController,
                  label: 'Agence *',
                  validator: (value) => value?.isEmpty == true ? 'Agence requise' : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Numéro de contrat et Numéro d'attestation
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _numeroContratController,
                  label: 'Numéro de contrat *',
                  validator: (value) => value?.isEmpty == true ? 'Numéro de contrat requis' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _numeroAttestationController,
                  label: 'Numéro d\'attestation',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Type de contrat
          _buildTextField(
            controller: _typeContratController,
            label: 'Type de contrat *',
            validator: (value) => value?.isEmpty == true ? 'Type de contrat requis' : null,
          ),

          const SizedBox(height: 16),

          // Dates de validité du contrat
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Date début contrat *',
                  selectedDate: _dateDebutContrat,
                  onDateSelected: (date) => setState(() => _dateDebutContrat = date),
                  validator: () => _dateDebutContrat == null ? 'Date début requise' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateField(
                  label: 'Date fin contrat *',
                  selectedDate: _dateFinContrat,
                  onDateSelected: (date) => setState(() => _dateFinContrat = date),
                  validator: () => _dateFinContrat == null ? 'Date fin requise' : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Validité de l'assurance
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user, color: Colors.blue[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Validité de l\'assurance',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Radio<bool>(
                            value: true,
                            groupValue: _assuranceValide,
                            onChanged: (value) => setState(() => _assuranceValide = value!),
                          ),
                          const Text('Assurance valide'),
                          const SizedBox(width: 20),
                          Radio<bool>(
                            value: false,
                            groupValue: _assuranceValide,
                            onChanged: (value) => setState(() => _assuranceValide = value!),
                          ),
                          const Text('Assurance expirée'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 👤 ÉTAPE 4: Informations de l'assuré (si différent du conducteur)
  Widget _buildStep4AssuredInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Informations de l\'Assuré',
            'Si l\'assuré est différent du conducteur',
            Icons.person_outline,
          ),

          const SizedBox(height: 24),

          // Question : Le conducteur est-il l'assuré ?
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Le conducteur est-il l\'assuré du véhicule ?',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: _conducteurEstAssure,
                      onChanged: (value) => setState(() => _conducteurEstAssure = value!),
                    ),
                    const Text('Oui, je suis l\'assuré'),
                    const SizedBox(width: 20),
                    Radio<bool>(
                      value: false,
                      groupValue: _conducteurEstAssure,
                      onChanged: (value) => setState(() => _conducteurEstAssure = value!),
                    ),
                    const Text('Non, l\'assuré est différent'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Si l'assuré est différent, afficher les champs
          if (!_conducteurEstAssure) ...[
            _buildSectionTitle('Informations de l\'Assuré'),
            const SizedBox(height: 16),

            // Nom et Prénom de l'assuré
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _assureNomController,
                    label: 'Nom de l\'assuré *',
                    validator: (value) => !_conducteurEstAssure && (value?.isEmpty == true)
                        ? 'Nom de l\'assuré requis' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _assurePrenomController,
                    label: 'Prénom de l\'assuré *',
                    validator: (value) => !_conducteurEstAssure && (value?.isEmpty == true)
                        ? 'Prénom de l\'assuré requis' : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // CIN de l'assuré
            _buildTextField(
              controller: _assureCinController,
              label: 'CIN de l\'assuré *',
              keyboardType: TextInputType.number,
              validator: (value) => !_conducteurEstAssure && (value?.isEmpty == true)
                  ? 'CIN de l\'assuré requis' : null,
            ),

            const SizedBox(height: 16),

            // Adresse de l'assuré
            _buildTextField(
              controller: _assureAdresseController,
              label: 'Adresse de l\'assuré *',
              maxLines: 2,
              validator: (value) => !_conducteurEstAssure && (value?.isEmpty == true)
                  ? 'Adresse de l\'assuré requise' : null,
            ),

            const SizedBox(height: 16),

            // Téléphone de l'assuré
            _buildTextField(
              controller: _assureTelephoneController,
              label: 'Téléphone de l\'assuré',
              keyboardType: TextInputType.phone,
            ),
          ] else ...[
            // Message informatif si le conducteur est l'assuré
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600]),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Les informations de l\'assuré sont identiques à celles du conducteur renseignées à l\'étape 1.',
                      style: TextStyle(fontSize: 14),
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

  /// 💥 ÉTAPE 5: Points de choc et dégâts
  Widget _buildStep5DamageInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Points de Choc et Dégâts',
            'Indiquez les zones endommagées de votre véhicule',
            Icons.car_crash,
          ),

          const SizedBox(height: 24),

          // Points de choc
          _buildSectionTitle('Points de Choc'),
          const SizedBox(height: 16),

          _buildDamageSelector('Points de choc', _pointsChocSelectionnes, [
            'Avant gauche', 'Avant centre', 'Avant droit',
            'Côté gauche', 'Côté droit',
            'Arrière gauche', 'Arrière centre', 'Arrière droit',
            'Toit', 'Dessous'
          ]),

          const SizedBox(height: 24),

          // Dégâts apparents
          _buildSectionTitle('Dégâts Apparents'),
          const SizedBox(height: 16),

          _buildDamageSelector('Dégâts apparents', _degatsApparents, [
            'Rayures', 'Bosses', 'Éclats de peinture',
            'Phare cassé', 'Pare-brise fissuré', 'Rétroviseur cassé',
            'Pare-chocs endommagé', 'Portière enfoncée', 'Capot déformé',
            'Pneu crevé', 'Jante voilée'
          ]),

          const SizedBox(height: 24),

          // Description détaillée des dégâts
          _buildSectionTitle('Description Détaillée'),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _descriptionDegatsController,
            label: 'Description précise des dégâts',
            maxLines: 4,
            hintText: 'Décrivez en détail l\'état de votre véhicule après l\'accident...',
          ),
        ],
      ),
    );
  }

  /// 📋 ÉTAPE 6: Circonstances de l'accident
  Widget _buildStep6Circumstances() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Circonstances de l\'Accident',
            'Sélectionnez les circonstances qui s\'appliquent à votre situation',
            Icons.assignment,
          ),

          const SizedBox(height: 24),

          // Circonstances officielles du constat
          _buildSectionTitle('Circonstances (cochez les cases qui s\'appliquent)'),
          const SizedBox(height: 16),

          _buildCircumstancesGrid(),

          const SizedBox(height: 24),

          // Observations personnelles
          _buildSectionTitle('Observations et Remarques'),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _observationsController,
            label: 'Vos observations sur l\'accident',
            maxLines: 5,
            hintText: 'Décrivez ce qui s\'est passé selon votre point de vue...',
          ),
        ],
      ),
    );
  }

  /// 👥 ÉTAPE 7: Témoins
  Widget _buildStep7Witnesses() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Témoins de l\'Accident',
            'Ajoutez les informations des témoins présents',
            Icons.people,
          ),

          const SizedBox(height: 24),

          // Liste des témoins
          if (_temoins.isNotEmpty) ...[
            _buildSectionTitle('Témoins ajoutés (${_temoins.length})'),
            const SizedBox(height: 16),

            ..._temoins.asMap().entries.map((entry) {
              final index = entry.key;
              final temoin = entry.value;
              return _buildWitnessCard(index, temoin);
            }).toList(),

            const SizedBox(height: 24),
          ],

          // Bouton ajouter témoin
          _buildAddWitnessButton(),

          const SizedBox(height: 24),

          // Information
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600]),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Les témoins peuvent être très utiles pour établir les responsabilités. '
                    'N\'hésitez pas à demander leurs coordonnées si des personnes ont assisté à l\'accident.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📸 ÉTAPE 8: Photos et documents
  Widget _buildStep8PhotosDocuments() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Photos et Documents',
            'Ajoutez des photos de l\'accident et des véhicules',
            Icons.camera_alt,
          ),

          const SizedBox(height: 24),

          // Section photos
          _buildSectionTitle('Photos de l\'Accident'),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.camera_alt, size: 48, color: Colors.orange[600]),
                const SizedBox(height: 12),
                const Text(
                  'Fonctionnalité Photos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'La fonctionnalité d\'ajout de photos sera disponible dans une prochaine version. '
                  'Pour l\'instant, vous pouvez continuer sans photos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Résumé final
          _buildSectionTitle('Résumé de votre Déclaration'),
          const SizedBox(height: 16),

          _buildFinalSummary(),
        ],
      ),
    );
  }

  /// 📝 En-tête d'étape
  Widget _buildStepHeader(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.green[600],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📝 Champ de texte personnalisé
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? hintText,
    bool enabled = true,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
      ),
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      enabled: enabled,
      onChanged: onChanged,
    );
  }

  /// 📅 Champ de date
  Widget _buildDateField({
    required String label,
    required DateTime? selectedDate,
    required void Function(DateTime) onDateSelected,
    String? Function()? validator,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          onDateSelected(date);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.grey[600]),
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
                  const SizedBox(height: 4),
                  Text(
                    selectedDate != null
                        ? '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}'
                        : 'Sélectionner une date',
                    style: TextStyle(
                      fontSize: 16,
                      color: selectedDate != null ? Colors.black87 : Colors.grey[500],
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

  /// 📋 Dropdown personnalisé
  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(item),
      )).toList(),
      onChanged: onChanged,
    );
  }

  /// 📑 Titre de section
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1E293B),
      ),
    );
  }

  /// 💥 Sélecteur de dégâts
  Widget _buildDamageSelector(String title, List<String> selectedItems, List<String> allItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allItems.map((item) {
            final isSelected = selectedItems.contains(item);
            return FilterChip(
              label: Text(item),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedItems.add(item);
                  } else {
                    selectedItems.remove(item);
                  }
                });
              },
              selectedColor: Colors.green[100],
              checkmarkColor: Colors.green[600],
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 📋 Grille de circonstances
  Widget _buildCircumstancesGrid() {
    final circumstances = [
      'Stationnement / Arrêt',
      'Sortie de parking, lieu privé, chemin de terre',
      'Engagement dans une circulation',
      'Ouverture de portière',
      'Descente de véhicule à l\'arrêt',
      'Changement de file',
      'Dépassement',
      'Virage à droite',
      'Virage à gauche',
      'Marche arrière',
      'Empiétement sur une file de circulation réservée à la circulation en sens inverse',
      'Circulation sur une file de circulation réservée à la circulation en sens inverse',
      'Non-respect de la priorité de passage',
      'Non-respect d\'un signal d\'arrêt',
      'Autre circonstance',
    ];

    return Column(
      children: circumstances.asMap().entries.map((entry) {
        final index = entry.key;
        final circumstance = entry.value;
        final isSelected = _circonstancesSelectionnees.contains(index.toString());

        return CheckboxListTile(
          title: Text(
            '${index + 1}. $circumstance',
            style: const TextStyle(fontSize: 14),
          ),
          value: isSelected,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _circonstancesSelectionnees.add(index.toString());
              } else {
                _circonstancesSelectionnees.remove(index.toString());
              }
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
        );
      }).toList(),
    );
  }

  /// 👥 Carte de témoin
  Widget _buildWitnessCard(int index, Map<String, String> witness) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Témoin ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _temoins.removeAt(index);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Nom: ${witness['nom'] ?? 'N/A'}'),
            Text('Téléphone: ${witness['telephone'] ?? 'N/A'}'),
            Text('Adresse: ${witness['adresse'] ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }

  /// ➕ Bouton ajouter témoin
  Widget _buildAddWitnessButton() {
    return OutlinedButton.icon(
      onPressed: _showAddWitnessDialog,
      icon: const Icon(Icons.add),
      label: const Text('Ajouter un témoin'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        side: BorderSide(color: Colors.green[600]!),
        foregroundColor: Colors.green[600],
      ),
    );
  }

  /// 📋 Résumé final
  Widget _buildFinalSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600]),
              const SizedBox(width: 8),
              const Text(
                'Votre déclaration est prête',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Conducteur: ${_prenomController.text} ${_nomController.text}'),
          Text('Véhicule: ${_marqueController.text} ${_modeleController.text}'),
          Text('Immatriculation: ${_immatriculationController.text}'),
          Text('Assurance: ${_compagnieController.text}'),
          Text('Circonstances sélectionnées: ${_circonstancesSelectionnees.length}'),
          Text('Témoins: ${_temoins.length}'),
        ],
      ),
    );
  }

  /// 🔄 Boutons de navigation
  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
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
                child: const Text('Précédent'),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 16),

          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleNextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_currentStep == _totalSteps - 1 ? 'Terminer' : 'Suivant'),
            ),
          ),
        ],
      ),
    );
  }

  /// 👥 Afficher dialog d'ajout de témoin
  void _showAddWitnessDialog() {
    final nomController = TextEditingController();
    final telephoneController = TextEditingController();
    final adresseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un témoin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              decoration: const InputDecoration(
                labelText: 'Nom complet *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: telephoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: adresseController,
              decoration: const InputDecoration(
                labelText: 'Adresse',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nomController.text.isNotEmpty && telephoneController.text.isNotEmpty) {
                setState(() {
                  _temoins.add({
                    'nom': nomController.text,
                    'telephone': telephoneController.text,
                    'adresse': adresseController.text,
                  });
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  /// ➡️ Gérer l'étape suivante
  Future<void> _handleNextStep() async {
    // Validation selon l'étape actuelle
    if (!_validateCurrentStep()) {
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Dernière étape - soumettre le formulaire
      await _soumettreFormulaire();
    }
  }

  /// ✅ Valider l'étape actuelle
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Informations personnelles
        return _formKey.currentState?.validate() ?? false;
      case 1: // Véhicule
        return _immatriculationController.text.isNotEmpty &&
               _marqueController.text.isNotEmpty &&
               _modeleController.text.isNotEmpty &&
               _couleurController.text.isNotEmpty;
      case 2: // Assurance
        return _compagnieController.text.isNotEmpty &&
               _agenceController.text.isNotEmpty &&
               _numeroContratController.text.isNotEmpty &&
               _dateDebutContrat != null &&
               _dateFinContrat != null;
      case 3: // Assuré
        if (!_conducteurEstAssure) {
          return _assureNomController.text.isNotEmpty &&
                 _assurePrenomController.text.isNotEmpty &&
                 _assureCinController.text.isNotEmpty &&
                 _assureAdresseController.text.isNotEmpty;
        }
        return true;
      case 4: // Dégâts
      case 5: // Circonstances
      case 6: // Témoins
      case 7: // Photos
        return true; // Pas de validation obligatoire
      default:
        return true;
    }
  }

  /// 📤 Soumettre le formulaire complet
  Future<void> _soumettreFormulaire() async {
    setState(() => _isLoading = true);

    try {
      // Créer le participant invité avec toutes les informations
      final guestParticipant = GuestParticipant(
        sessionId: widget.session.id,
        participantId: DateTime.now().millisecondsSinceEpoch.toString(),
        roleVehicule: _roleVehicule,
        infosPersonnelles: PersonalInfo(
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          cin: _cinController.text.trim(),
          telephone: _telephoneController.text.trim(),
          email: _emailController.text.trim(),
          adresse: _adresseController.text.trim(),
          ville: _villeController.text.trim(),
          codePostal: _codePostalController.text.trim(),
          dateNaissance: _dateNaissance,
          profession: _professionController.text.trim(),
          numeroPermis: _numeroPermisController.text.trim(),
          categoriePermis: _categoriePermisController.text.trim(),
          dateDelivrancePermis: _dateDelivrancePermis,
        ),
        infosVehicule: VehicleInfo(
          immatriculation: _immatriculationController.text.trim(),
          marque: _marqueController.text.trim(),
          modele: _modeleController.text.trim(),
          couleur: _couleurController.text.trim(),
          anneeConstruction: _anneeConstruction,
          numeroSerie: _numeroSerieController.text.trim(),
          typeCarburant: _typeCarburant,
          puissanceFiscale: int.tryParse(_puissanceFiscaleController.text),
          nombrePlaces: int.tryParse(_nombrePlacesController.text),
          usage: _usageVehicule,
          pointsChoc: _pointsChocSelectionnes,
          degatsApparents: _degatsApparents,
          descriptionDegats: _descriptionDegatsController.text.trim(),
        ),
        infosAssurance: InsuranceInfo(
          compagnieId: '', // Pas d'ID pour les invités
          compagnieNom: _compagnieController.text.trim(),
          agenceId: '', // Pas d'ID pour les invités
          agenceNom: _agenceController.text.trim(),
          numeroContrat: _numeroContratController.text.trim(),
          dateDebutContrat: _dateDebutContrat,
          dateFinContrat: _dateFinContrat,
          typeContrat: _typeContratController.text.trim(),
          numeroAttestation: _numeroAttestationController.text.trim(),
          assuranceValide: _assuranceValide,
        ),
        circonstances: _circonstancesSelectionnees,
        observationsPersonnelles: _observationsController.text.trim(),
        photosUrls: _photosUrls,
        dateCreation: DateTime.now(),
        formulaireComplete: true,
      );

      // Sauvegarder le participant invité
      await GuestParticipantService.ajouterParticipantInvite(guestParticipant);

      // Afficher message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Votre déclaration a été enregistrée avec succès !',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 3),
          ),
        );

        // Retourner à l'écran principal
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

    } catch (e) {
      print('❌ Erreur lors de la soumission: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Erreur lors de l\'enregistrement. Veuillez réessayer.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 📋 Obtenir le titre de l'étape actuelle
  String _getStepTitle() {
    switch (_currentStep) {
      case 0: return 'Informations personnelles';
      case 1: return 'Véhicule';
      case 2: return 'Assurance';
      case 3: return 'Assuré';
      case 4: return 'Dégâts';
      case 5: return 'Circonstances';
      case 6: return 'Témoins';
      case 7: return 'Photos & Finalisation';
      default: return 'Étape inconnue';
    }
  }
}
