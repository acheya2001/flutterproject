import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../services/cloudinary_storage_service.dart';
import '../../../services/complete_insurance_workflow_service.dart';
import '../services/insurance_data_service.dart';
import '../../../features/insurance/widgets/company_agency_selector.dart';
import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/services/logging_service.dart';

/// 🚗 Écran complet de demande d'assurance avec tous les champs nécessaires
/// Combine les fonctionnalités d'ajout de véhicule et de demande d'assurance
class CompleteInsuranceRequestScreen extends StatefulWidget {
  const CompleteInsuranceRequestScreen({super.key});

  @override
  State<CompleteInsuranceRequestScreen> createState() => _CompleteInsuranceRequestScreenState();
}

class _CompleteInsuranceRequestScreenState extends State<CompleteInsuranceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Contrôleurs de formulaire - Véhicule
  final _plateController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _carteGriseNumberController = TextEditingController();
  final _vinController = TextEditingController();
  String _fuelType = 'essence'; // essence, diesel, hybride, electrique, gpl
  DateTime? _firstRegistrationDate;

  // Contrôleurs de formulaire - Conducteur
  final _conducteurNameController = TextEditingController();
  final _conducteurPrenomController = TextEditingController();
  final _conducteurAddressController = TextEditingController();
  final _conducteurPhoneController = TextEditingController();
  final _conducteurEmailController = TextEditingController();
  final _permisNumberController = TextEditingController();
  DateTime? _permisDeliveryDate;

  // Propriétaire
  bool _isConducteurOwner = true;
  final _ownerNameController = TextEditingController();
  final _ownerCinController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  String _relationToConducteur = 'parent';

  // Assurance - Sélection compagnie/agence
  String? _selectedCompanyId;
  String? _selectedAgencyId;

  // Documents
  File? _carteGriseFile;
  File? _permisFile;
  File? _carteIdentiteFile;
  List<File> _vehiclePhotos = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _yearController.text = DateTime.now().year.toString();
    _loadCompagnies();
    _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      
      if (mounted) setState(() {
        _conducteurNameController.text = userData['nom'] ?? '';
        _conducteurPrenomController.text = userData['prenom'] ?? '';
        _conducteurPhoneController.text = userData['telephone'] ?? '';
        _conducteurEmailController.text = userData['email'] ?? user.email ?? '';
        _conducteurAddressController.text = userData['adresse'] ?? '';
      });
    }
  }

  Future<void> _loadCompagnies() async {
    try {
      // Charger les compagnies mais ne pas stocker les données inutilisées
      await InsuranceDataService.getCompagnies();
    } catch (e) {
      LoggingService.error('CompleteInsuranceRequest', 'Erreur chargement compagnies', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Demande d\'Assurance Complète',
      ),
      body: Column(
        children: [
          // Indicateur de progression
          _buildProgressIndicator(),
          
          // Contenu des étapes
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1VehicleInfo(),
                _buildStep2OwnerInfo(),
                _buildStep3InsuranceInfo(),
                _buildStep4Documents(),
              ],
            ),
          ),
          
          // Boutons de navigation
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
              child: Column(
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF3B82F6) : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isCompleted 
                          ? Colors.green 
                          : isActive 
                              ? const Color(0xFF3B82F6) 
                              : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : Icons.circle,
                      size: 12,
                      color: isActive || isCompleted ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1VehicleInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informations du véhicule',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),

              // Immatriculation
              TextFormField(
                controller: _plateController,
                decoration: const InputDecoration(
                  labelText: 'Numéro d\'immatriculation *',
                  hintText: 'Ex: 123 TUN 456',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty == true ? 'Requis' : null,
              ),
              const SizedBox(height: 16),

              // Marque et modèle
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _brandController,
                      decoration: const InputDecoration(
                        labelText: 'Marque *',
                        hintText: 'Ex: Peugeot',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty == true ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: 'Modèle *',
                        hintText: 'Ex: 208',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty == true ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Année et couleur
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _yearController,
                      decoration: const InputDecoration(
                        labelText: 'Année *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty == true) return 'Requis';
                        final year = int.tryParse(value!);
                        if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                          return 'Année invalide';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _colorController,
                      decoration: const InputDecoration(
                        labelText: 'Couleur *',
                        hintText: 'Ex: Blanc',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty == true ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Numéro carte grise
              TextFormField(
                controller: _carteGriseNumberController,
                decoration: const InputDecoration(
                  labelText: 'Numéro de carte grise *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty == true ? 'Requis' : null,
              ),
              const SizedBox(height: 16),

              // VIN (optionnel)
              TextFormField(
                controller: _vinController,
                decoration: const InputDecoration(
                  labelText: 'Numéro VIN (optionnel)',
                  hintText: 'Numéro de châssis',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Type de carburant
              DropdownButtonFormField<String>(
                value: _fuelType,
                decoration: const InputDecoration(
                  labelText: 'Type de carburant *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'essence', child: Text('Essence')),
                  DropdownMenuItem(value: 'diesel', child: Text('Diesel')),
                  DropdownMenuItem(value: 'hybride', child: Text('Hybride')),
                  DropdownMenuItem(value: 'electrique', child: Text('Électrique')),
                  DropdownMenuItem(value: 'gpl', child: Text('GPL')),
                ],
                onChanged: (value) {
                  if (mounted) setState(() {
                    _fuelType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Date de première mise en circulation
              InkWell(
                onTap: () => _selectFirstRegistrationDate(),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date de première mise en circulation *',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _firstRegistrationDate != null
                        ? '${_firstRegistrationDate!.day}/${_firstRegistrationDate!.month}/${_firstRegistrationDate!.year}'
                        : 'Sélectionner une date',
                    style: TextStyle(
                      color: _firstRegistrationDate != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep2OwnerInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations du conducteur',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // Question propriétaire
            const Text(
              'Êtes-vous le propriétaire de ce véhicule ?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Oui'),
                    value: true,
                    groupValue: _isConducteurOwner,
                    onChanged: (value) {
                      if (mounted) setState(() {
                        _isConducteurOwner = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Non'),
                    value: false,
                    groupValue: _isConducteurOwner,
                    onChanged: (value) {
                      if (mounted) setState(() {
                        _isConducteurOwner = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Informations personnelles du conducteur
            const Text(
              'Vos informations personnelles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Nom et prénom
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _conducteurPrenomController,
                    decoration: const InputDecoration(
                      labelText: 'Prénom *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Requis' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _conducteurNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Requis' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Adresse complète
            TextFormField(
              controller: _conducteurAddressController,
              decoration: const InputDecoration(
                labelText: 'Adresse complète *',
                hintText: 'Rue, ville, code postal',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) => value?.isEmpty == true ? 'Requis' : null,
            ),
            const SizedBox(height: 16),

            // Téléphone et email
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _conducteurPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone *',
                      hintText: '+216 XX XXX XXX',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value?.isEmpty == true ? 'Requis' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _conducteurEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Requis';
                      if (!value!.contains('@')) return 'Email invalide';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Informations permis de conduire
            const Text(
              'Permis de conduire',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Numéro de permis
            TextFormField(
              controller: _permisNumberController,
              decoration: const InputDecoration(
                labelText: 'Numéro de permis *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty == true ? 'Requis' : null,
            ),
            const SizedBox(height: 16),

            // Date de délivrance du permis
            InkWell(
              onTap: () => _selectPermisDeliveryDate(),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date de délivrance du permis *',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _permisDeliveryDate != null
                      ? '${_permisDeliveryDate!.day}/${_permisDeliveryDate!.month}/${_permisDeliveryDate!.year}'
                      : 'Sélectionner une date',
                  style: TextStyle(
                    color: _permisDeliveryDate != null ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),

            if (!_isConducteurOwner) ...[
              const SizedBox(height: 24),
              const Text(
                'Informations du propriétaire',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ownerNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet du propriétaire *',
                  border: OutlineInputBorder(),
                ),
                validator: !_isConducteurOwner 
                    ? (value) => value?.isEmpty == true ? 'Requis' : null
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ownerCinController,
                decoration: const InputDecoration(
                  labelText: 'CIN du propriétaire *',
                  border: OutlineInputBorder(),
                ),
                validator: !_isConducteurOwner 
                    ? (value) => value?.isEmpty == true ? 'Requis' : null
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ownerPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone (optionnel)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _relationToConducteur,
                decoration: const InputDecoration(
                  labelText: 'Relation avec le propriétaire *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'parent', child: Text('Parent')),
                  DropdownMenuItem(value: 'conjoint', child: Text('Conjoint(e)')),
                  DropdownMenuItem(value: 'ami', child: Text('Ami(e)')),
                  DropdownMenuItem(value: 'autre', child: Text('Autre')),
                ],
                onChanged: (value) {
                  if (mounted) setState(() {
                    _relationToConducteur = value!;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStep3InsuranceInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sélection de l\'assurance',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // Sélection compagnie et agence
            CompanyAgencySelector(
              selectedCompanyId: _selectedCompanyId,
              selectedAgencyId: _selectedAgencyId,
              onSelectionChanged: (companyId, agencyId) {
                if (mounted) setState(() {
                  _selectedCompanyId = companyId;
                  _selectedAgencyId = agencyId;
                });
              },
              isRequired: true,
            ),
            const SizedBox(height: 16),

            // Information sur le processus
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Processus de demande',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Vous soumettez votre demande\n'
                    '2. L\'agent crée votre contrat\n'
                    '3. Vous payez (agence/D17/virement)\n'
                    '4. Documents numériques générés\n'
                    '5. Carte verte avec QR Code',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4Documents() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Documents requis',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // Carte grise (recto-verso)
            _buildDocumentUpload(
              'Carte grise *',
              'Photos recto et verso de la carte grise',
              _carteGriseFile,
              () => _pickDocument('carte_grise'),
              isRequired: true,
            ),
            const SizedBox(height: 16),

            // Permis de conduire (recto-verso)
            _buildDocumentUpload(
              'Permis de conduire *',
              'Photos recto et verso de votre permis',
              _permisFile,
              () => _pickDocument('permis'),
              isRequired: true,
            ),
            const SizedBox(height: 16),

            // Carte d'identité (recto-verso)
            _buildDocumentUpload(
              'Carte d\'identité *',
              'Photos recto et verso de votre carte d\'identité',
              _carteIdentiteFile,
              () => _pickDocument('carte_identite'),
              isRequired: true,
            ),
            const SizedBox(height: 16),

            // Photos du véhicule
            _buildVehiclePhotosSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentUpload(String title, String subtitle, File? file, VoidCallback onTap, {bool isRequired = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: file != null ? Colors.green : Colors.grey),
          borderRadius: BorderRadius.circular(8),
          color: file != null ? Colors.green[50] : null,
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: file != null ? Colors.green[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: file != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(file, fit: BoxFit.cover),
                    )
                  : Icon(
                      Icons.camera_alt,
                      color: Colors.grey[600],
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    file != null ? 'Document ajouté' : subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: file != null ? Colors.green[700] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              file != null ? Icons.check_circle : Icons.camera_alt,
              color: file != null ? Colors.green : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehiclePhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photos du véhicule',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ajoutez des photos de votre véhicule (optionnel)',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Grille des photos
        if (_vehiclePhotos.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _vehiclePhotos.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(_vehiclePhotos[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeVehiclePhoto(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
        ],

        // Bouton ajouter photo
        InkWell(
          onTap: () => _pickDocument('vehicle_photo'),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 32, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Ajouter une photo', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: CustomButton(
                text: 'Précédent',
                onPressed: _previousStep,
                backgroundColor: Colors.grey[300],
                textColor: Colors.black87,
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: CustomButton(
              text: _currentStep == 3 ? 'Soumettre la demande' : 'Suivant',
              onPressed: _isLoading ? null : _nextStep,
              icon: _currentStep == 3 ? Icons.check : Icons.arrow_forward,
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < 3) {
      if (_validateCurrentStep()) {
        if (mounted) setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _submitInsuranceRequest();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      if (mounted) setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        // Validation étape 1 : informations véhicule
        if (!(_formKey.currentState?.validate() ?? false)) return false;
        if (_firstRegistrationDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Veuillez sélectionner la date de première mise en circulation'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        return true;

      case 1:
        // Validation étape 2 : informations conducteur et propriétaire
        if (_conducteurNameController.text.isEmpty ||
            _conducteurPrenomController.text.isEmpty ||
            _conducteurAddressController.text.isEmpty ||
            _conducteurPhoneController.text.isEmpty ||
            _conducteurEmailController.text.isEmpty ||
            _permisNumberController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Veuillez remplir tous les champs obligatoires'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }

        if (_permisDeliveryDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Veuillez sélectionner la date de délivrance du permis'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }

        // Vérifier les informations du propriétaire si différent
        if (!_isConducteurOwner) {
          if (_ownerNameController.text.isEmpty || _ownerCinController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Veuillez remplir les informations du propriétaire'),
                backgroundColor: Colors.red,
              ),
            );
            return false;
          }
        }
        return true;

      case 2:
        // Validation étape 3 : assurance
        if (_selectedCompanyId == null || _selectedAgencyId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Veuillez sélectionner une compagnie et une agence'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        return true;

      case 3:
        // Validation étape 4 : documents
        if (_carteGriseFile == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La carte grise est obligatoire'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        if (_permisFile == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Le permis de conduire est obligatoire'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        if (_carteIdentiteFile == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La carte d\'identité est obligatoire'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        return true;

      default:
        return false;
    }
  }

  Future<void> _submitInsuranceRequest() async {
    if (mounted) setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw const AuthException('Utilisateur non connecté');

      // Upload des documents vers Cloudinary
      final documentUrls = await _uploadDocuments(user.uid);

      // Préparer les données du véhicule
      final vehicleData = {
        'marque': _brandController.text.trim(),
        'modele': _modelController.text.trim(),
        'immatriculation': _plateController.text.trim().toUpperCase(),
        'couleur': _colorController.text.trim(),
        'annee': int.parse(_yearController.text.trim()),
        'typeVehicule': _fuelType,
        'carburant': _fuelType,
        'numeroCarteGrise': _carteGriseNumberController.text.trim(),
        'vin': _vinController.text.trim(),
        'firstRegistrationDate': _firstRegistrationDate?.toIso8601String(),
        'submittedAt': DateTime.now().toIso8601String(),
      };

      // Préparer les données du conducteur
      final conducteurData = {
        'nom': _conducteurNameController.text.trim(),
        'prenom': _conducteurPrenomController.text.trim(),
        'telephone': _conducteurPhoneController.text.trim(),
        'email': _conducteurEmailController.text.trim(),
        'adresse': _conducteurAddressController.text.trim(),
        'permisNumber': _permisNumberController.text.trim(),
        'permisDeliveryDate': _permisDeliveryDate?.toIso8601String(),
        'submittedAt': DateTime.now().toIso8601String(),
      };

      // Informations propriétaire si différent
      if (!_isConducteurOwner) {
        conducteurData['ownerName'] = _ownerNameController.text.trim();
        conducteurData['ownerCin'] = _ownerCinController.text.trim();
        conducteurData['ownerRelation'] = _relationToConducteur;
        conducteurData['ownerPhone'] = _ownerPhoneController.text.trim();
      }

      // Soumettre la demande d'assurance
      final result = await CompleteInsuranceWorkflowService.submitInsuranceRequest(
        conducteurData: conducteurData,
        vehicleData: vehicleData,
        compagnieId: _selectedCompanyId!,
        agenceId: _selectedAgencyId!,
      );

      // Succès
      if (mounted) {
        _showSuccessDialog(result);
      }

    } catch (e) {
      LoggingService.error('CompleteInsuranceRequest', 'Erreur soumission demande', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        if (mounted) setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, String>> _uploadDocuments(String userId) async {
    final documentUrls = <String, String>{};

    try {
      // Upload carte grise
      if (_carteGriseFile != null) {
        final url = await CloudinaryStorageService.uploadImage(
          imageFile: _carteGriseFile!,
          publicId: 'carte_grise_${_plateController.text}_$userId',
          folder: 'documents/$userId',
        );
        if (url != null) documentUrls['carteGrise'] = url;
      }

      // Upload permis
      if (_permisFile != null) {
        final url = await CloudinaryStorageService.uploadImage(
          imageFile: _permisFile!,
          publicId: 'permis_$userId',
          folder: 'documents/$userId',
        );
        if (url != null) documentUrls['permis'] = url;
      }

      // Upload carte identité
      if (_carteIdentiteFile != null) {
        final url = await CloudinaryStorageService.uploadImage(
          imageFile: _carteIdentiteFile!,
          publicId: 'carte_identite_$userId',
          folder: 'documents/$userId',
        );
        if (url != null) documentUrls['carteIdentite'] = url;
      }

      // Upload photos véhicule
      for (int i = 0; i < _vehiclePhotos.length; i++) {
        final url = await CloudinaryStorageService.uploadImage(
          imageFile: _vehiclePhotos[i],
          publicId: 'vehicule_${_plateController.text}_${i + 1}_$userId',
          folder: 'documents/$userId/vehicule',
        );
        if (url != null) {
          documentUrls['vehicule_photo_${i + 1}'] = url;
        }
      }

    } catch (e) {
      LoggingService.error('CompleteInsuranceRequest', 'Erreur upload documents', e);
    }

    return documentUrls;
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Demande soumise avec succès'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Votre demande a été enregistrée sous le numéro: ${result['requestId']}'),
            const SizedBox(height: 16),
            const Text(
              'Prochaines étapes:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('1. Un agent traitera votre demande'),
            const Text('2. Vous recevrez un contrat à signer'),
            const Text('3. Effectuez le paiement'),
            const Text('4. Recevez vos documents d\'assurance'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectFirstRegistrationDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _firstRegistrationDate ?? DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: 'Date de première mise en circulation',
    );
    if (date != null) {
      if (mounted) setState(() {
        _firstRegistrationDate = date;
      });
    }
  }

  Future<void> _selectPermisDeliveryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _permisDeliveryDate ?? DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: 'Date de délivrance du permis',
    );
    if (date != null) {
      if (mounted) setState(() {
        _permisDeliveryDate = date;
      });
    }
  }

  Future<void> _pickDocument(String documentType) async {
    // Choix entre caméra et galerie
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir une source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir depuis la galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          switch (documentType) {
            case 'carte_grise':
              _carteGriseFile = File(image.path);
              break;
            case 'permis':
              _permisFile = File(image.path);
              break;
            case 'carte_identite':
              _carteIdentiteFile = File(image.path);
              break;
            case 'vehicle_photo':
              if (_vehiclePhotos.length < 6) { // Limite à 6 photos
                _vehiclePhotos.add(File(image.path));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Maximum 6 photos autorisées'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              break;
          }
        });
      }
    }
  }

  void _removeVehiclePhoto(int index) {
    if (mounted) setState(() {
      _vehiclePhotos.removeAt(index);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _plateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _carteGriseNumberController.dispose();
    _vinController.dispose();
    _conducteurNameController.dispose();
    _conducteurPrenomController.dispose();
    _conducteurAddressController.dispose();
    _conducteurPhoneController.dispose();
    _conducteurEmailController.dispose();
    _permisNumberController.dispose();
    _ownerNameController.dispose();
    _ownerCinController.dispose();
    _ownerPhoneController.dispose();
    super.dispose();
  }
}

