import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../models/vehicule_model.dart';
import '../services/vehicule_service.dart';
import '../services/insurance_data_service.dart';
import '../../../services/cloudinary_storage_service.dart';

class AddVehicleModernScreen extends StatefulWidget {
  const AddVehicleModernScreen({super.key});

  @override
  State<AddVehicleModernScreen> createState() => _AddVehicleModernScreenState();
}

class _AddVehicleModernScreenState extends State<AddVehicleModernScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  
  // Controllers
  final _plateController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _carteGriseController = TextEditingController();
  final _numeroPermisController = TextEditingController();
  final _contractController = TextEditingController();
  final _puissanceFiscaleController = TextEditingController();
  final _cylindreeController = TextEditingController();
  final _poidsController = TextEditingController();
  final _numeroSerieController = TextEditingController();
  final _nomProprietaireController = TextEditingController();
  final _prenomProprietaireController = TextEditingController();
  final _adresseProprietaireController = TextEditingController();

  // Variables d'état
  String _selectedTypeVehicule = 'VP';
  String _selectedCarburant = 'Essence';
  String _selectedUsage = 'Personnel';
  String _selectedCategoriePermis = 'B';
  int _selectedNombrePlaces = 5;
  String _selectedEtatCompte = 'En attente';
  bool _hasInsurance = false;
  bool _isLoading = false;
  bool _isLoadingCompagnies = false;
  bool _isLoadingAgences = false;

  // Variables pour les données Firebase
  List<Map<String, dynamic>> _compagnies = [];
  List<Map<String, dynamic>> _agences = [];
  String? _selectedCompagnieId;
  String? _selectedAgenceId;
  DateTime? _dateImmatriculation;
  DateTime? _dateMiseCirculation;
  DateTime? _dateObtentionPermis;
  DateTime? _dateExpirationPermis;
  DateTime? _dateDebutAssurance;
  DateTime? _dateFinAssurance;
  DateTime? _dateDerniereAssurance;

  // Variables pour les images
  File? _imageCarteGrise;
  File? _imagePermis;
  String? _imageCarteGriseUrl;
  String? _imagePermisUrl;
  final ImagePicker _picker = ImagePicker();

  // Listes des options tunisiennes
  final List<Map<String, String>> _typesVehicules = [
    {'code': 'VP', 'label': 'VP - Véhicule Particulier'},
    {'code': 'VU', 'label': 'VU - Véhicule Utilitaire'},
    {'code': 'PL', 'label': 'PL - Poids Lourds'},
    {'code': 'MOTO', 'label': 'MOTO - Motos/Scooters'},
    {'code': 'TAXI', 'label': 'TAXI - Taxi'},
    {'code': 'LOUEUR', 'label': 'LOUEUR - Location'},
    {'code': 'BUS', 'label': 'BUS - Transport Personnes'},
    {'code': 'AMBULANCE', 'label': 'AMBULANCE - Médicalisé'},
    {'code': 'TRACTEUR', 'label': 'TRACTEUR - Routier/Agricole'},
    {'code': 'ENGIN', 'label': 'ENGIN - Chantier'},
    {'code': 'REMORQUE', 'label': 'REMORQUE/SEMI'},
    {'code': 'AUTO_ECOLE', 'label': 'AUTO-ÉCOLE'},
    {'code': 'DIPLOMATIQUE', 'label': 'DIPLOMATIQUE'},
    {'code': 'ADMINISTRATIF', 'label': 'ADMINISTRATIF'},
  ];

  final List<Map<String, String>> _carburants = [
    {'code': 'Essence', 'label': 'Essence'},
    {'code': 'Diesel', 'label': 'Diesel'},
    {'code': 'Hybride', 'label': 'Hybride'},
    {'code': 'Électrique', 'label': 'Électrique'},
    {'code': 'GPL', 'label': 'GPL'},
    {'code': 'GNV', 'label': 'GNV'},
  ];

  final List<Map<String, String>> _usages = [
    {'code': 'Personnel', 'label': 'Personnel'},
    {'code': 'Professionnel', 'label': 'Professionnel'},
    {'code': 'Taxi', 'label': 'Taxi'},
    {'code': 'Location', 'label': 'Location'},
    {'code': 'Transport', 'label': 'Transport'},
    {'code': 'Livraison', 'label': 'Livraison'},
    {'code': 'Agricole', 'label': 'Agricole'},
    {'code': 'Chantier', 'label': 'Chantier'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCompagnies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _plateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _carteGriseController.dispose();
    _numeroPermisController.dispose();
    _contractController.dispose();
    _puissanceFiscaleController.dispose();
    _cylindreeController.dispose();
    _poidsController.dispose();
    _numeroSerieController.dispose();
    _nomProprietaireController.dispose();
    _prenomProprietaireController.dispose();
    _adresseProprietaireController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Ajouter un Véhicule',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFF59E0B),
          indicatorWeight: 4,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFFE0E7FF),
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.directions_car, size: 20), text: 'Véhicule'),
            Tab(icon: Icon(Icons.credit_card, size: 20), text: 'Documents'),
            Tab(icon: Icon(Icons.badge, size: 20), text: 'Permis'),
            Tab(icon: Icon(Icons.shield, size: 20), text: 'Assurance'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVehicleTab(),
                _buildDocumentsTab(),
                _buildPermisTab(),
                _buildAssuranceTab(),
              ],
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildVehicleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildCard(
            title: '🚗 Informations Générales',
            children: [
              _buildTextField(
                controller: _plateController,
                label: 'Numéro d\'immatriculation *',
                hint: 'Ex: 175 TU 5687',
                icon: Icons.confirmation_number,
                isRequired: true,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _brandController,
                label: 'Marque du véhicule *',
                hint: 'Ex: Renault, Peugeot, Toyota',
                icon: Icons.branding_watermark,
                isRequired: true,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _modelController,
                label: 'Modèle *',
                hint: 'Ex: Clio 4, 208, Corolla',
                icon: Icons.directions_car,
                isRequired: true,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _yearController,
                      label: 'Année circulation *',
                      hint: '2021',
                      icon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                      isRequired: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _colorController,
                      label: 'Couleur *',
                      hint: 'Blanc, Noir, Rouge',
                      icon: Icons.palette,
                      isRequired: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCard(
            title: '⚙️ Catégorie et Caractéristiques',
            children: [
              _buildDropdown(
                label: 'Type de véhicule *',
                value: _selectedTypeVehicule,
                items: _typesVehicules.map((e) => e['code']!).toList(),
                itemLabels: _typesVehicules.map((e) => e['label']!).toList(),
                onChanged: (value) => setState(() => _selectedTypeVehicule = value!),
              ),
              const SizedBox(height: 20),
              _buildDropdown(
                label: 'Type de carburant',
                value: _selectedCarburant,
                items: _carburants.map((e) => e['code']!).toList(),
                itemLabels: _carburants.map((e) => e['label']!).toList(),
                onChanged: (value) => setState(() => _selectedCarburant = value!),
              ),
              const SizedBox(height: 20),
              _buildDropdown(
                label: 'Usage principal',
                value: _selectedUsage,
                items: _usages.map((e) => e['code']!).toList(),
                itemLabels: _usages.map((e) => e['label']!).toList(),
                onChanged: (value) => setState(() => _selectedUsage = value!),
              ),
              const SizedBox(height: 20),
              _buildDropdown(
                label: 'Nombre de places',
                value: _selectedNombrePlaces.toString(),
                items: ['2', '4', '5', '7', '9', '12', '15', '20', '30', '50'],
                itemLabels: ['2 places', '4 places', '5 places', '7 places', '9 places', '12 places', '15 places', '20 places', '30 places', '50+ places'],
                onChanged: (value) => setState(() => _selectedNombrePlaces = int.parse(value!)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCard(
            title: '🔧 Spécifications Techniques',
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _puissanceFiscaleController,
                      label: 'Puissance fiscale',
                      hint: '5 CV',
                      icon: Icons.speed,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _cylindreeController,
                      label: 'Cylindrée',
                      hint: '1200 cm³',
                      icon: Icons.engineering,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _poidsController,
                      label: 'Poids (kg)',
                      hint: '1200',
                      icon: Icons.fitness_center,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _numeroSerieController,
                      label: 'Numéro de série',
                      hint: 'VIN123456789',
                      icon: Icons.qr_code,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildCard(
            title: '📄 Carte Grise',
            children: [
              _buildTextField(
                controller: _carteGriseController,
                label: 'Numéro de carte grise *',
                hint: 'Ex: 123456789',
                icon: Icons.credit_card,
                isRequired: true,
              ),
              const SizedBox(height: 20),
              _buildDateField(
                label: 'Date première immatriculation',
                selectedDate: _dateImmatriculation,
                onDateSelected: (date) => setState(() => _dateImmatriculation = date),
              ),
              const SizedBox(height: 20),
              _buildDateField(
                label: 'Date mise en circulation',
                selectedDate: _dateMiseCirculation,
                onDateSelected: (date) => setState(() => _dateMiseCirculation = date),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCard(
            title: '👤 Propriétaire du Véhicule',
            children: [
              _buildTextField(
                controller: _nomProprietaireController,
                label: 'Nom du propriétaire *',
                hint: 'Ex: Ben Ali',
                icon: Icons.person,
                isRequired: true,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _prenomProprietaireController,
                label: 'Prénom du propriétaire *',
                hint: 'Ex: Mohamed',
                icon: Icons.person_outline,
                isRequired: true,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _adresseProprietaireController,
                label: 'Adresse du propriétaire',
                hint: 'Ex: 123 Rue de la République, Tunis',
                icon: Icons.location_on,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCard(
            title: '📸 Photos des Documents',
            children: [
              _buildPhotoUploadSection(
                title: 'Photo de la carte grise',
                subtitle: 'Ajoutez une photo de votre carte grise',
                icon: Icons.credit_card,
                onTap: () => _showPhotoUploadDialog('carte_grise'),
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPermisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildCard(
            title: '🪪 Permis de Conduire',
            children: [
              _buildTextField(
                controller: _numeroPermisController,
                label: 'Numéro de permis *',
                hint: 'Ex: 123456789',
                icon: Icons.badge,
                isRequired: true,
              ),
              const SizedBox(height: 20),
              _buildDropdown(
                label: 'Catégorie de permis',
                value: _selectedCategoriePermis,
                items: ['A', 'A1', 'A2', 'B', 'BE', 'C', 'CE', 'D', 'DE'],
                itemLabels: [
                  'A - Moto > 35kW',
                  'A1 - Moto ≤ 125cm³',
                  'A2 - Moto ≤ 35kW',
                  'B - Voiture particulière',
                  'BE - Voiture + remorque',
                  'C - Camion ≤ 7,5T',
                  'CE - Camion + remorque',
                  'D - Transport de personnes',
                  'DE - Bus + remorque'
                ],
                onChanged: (value) => setState(() => _selectedCategoriePermis = value!),
              ),
              const SizedBox(height: 20),
              _buildDateField(
                label: 'Date d\'obtention du permis',
                selectedDate: _dateObtentionPermis,
                onDateSelected: (date) => setState(() => _dateObtentionPermis = date),
              ),
              const SizedBox(height: 20),
              _buildDateField(
                label: 'Date d\'expiration du permis',
                selectedDate: _dateExpirationPermis,
                onDateSelected: (date) => setState(() => _dateExpirationPermis = date),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCard(
            title: '📸 Photo du Permis',
            children: [
              _buildPhotoUploadSection(
                title: 'Photo du permis de conduire',
                subtitle: 'Ajoutez une photo de votre permis',
                icon: Icons.badge,
                onTap: () => _showPhotoUploadDialog('permis'),
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildAssuranceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildCard(
            title: '🛡️ Assurance du Véhicule',
            children: [
              Row(
                children: [
                  Switch(
                    value: _hasInsurance,
                    onChanged: (value) => setState(() => _hasInsurance = value),
                    activeColor: const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Le véhicule est assuré',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
              if (_hasInsurance) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.blue.shade600, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Génération Automatique',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Le numéro de contrat sera généré automatiquement lors de la création du contrat par votre agent d\'assurance.',
                              style: TextStyle(
                                color: Colors.blue.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildCompagnieDropdown(),
                if (_selectedCompagnieId != null) ...[
                  const SizedBox(height: 20),
                  _buildAgenceDropdown(),
                ],
                const SizedBox(height: 20),
                _buildDateField(
                  label: 'Date début assurance',
                  selectedDate: _dateDebutAssurance,
                  onDateSelected: (date) => setState(() => _dateDebutAssurance = date),
                ),
                const SizedBox(height: 20),
                _buildDateField(
                  label: 'Date fin assurance',
                  selectedDate: _dateFinAssurance,
                  onDateSelected: (date) => setState(() => _dateFinAssurance = date),
                ),
                const SizedBox(height: 20),
                _buildDateField(
                  label: 'Date dernière assurance',
                  selectedDate: _dateDerniereAssurance,
                  onDateSelected: (date) => setState(() => _dateDerniereAssurance = date),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          _buildCard(
            title: '📊 État du Compte',
            children: [
              _buildDropdown(
                label: 'État du compte',
                value: _selectedEtatCompte,
                items: ['Actif', 'Suspendu', 'En attente', 'Bloqué'],
                itemLabels: [
                  'Actif - Compte opérationnel',
                  'Suspendu - Temporairement inactif',
                  'En attente - Validation en cours',
                  'Bloqué - Compte désactivé'
                ],
                onChanged: (value) => setState(() => _selectedEtatCompte = value!),
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    bool isRequired = false,
  }) {
    final isEmpty = controller.text.trim().isEmpty;
    final showError = isRequired && isEmpty;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(
          icon,
          color: showError ? const Color(0xFFEF4444) : const Color(0xFF6B7280)
        ) : null,
        suffixIcon: isRequired ? Icon(
          isEmpty ? Icons.error_outline : Icons.check_circle,
          color: isEmpty ? const Color(0xFFEF4444) : const Color(0xFF10B981),
          size: 20,
        ) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: showError ? const Color(0xFFEF4444) : const Color(0xFFE5E7EB)
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: showError ? const Color(0xFFEF4444) : const Color(0xFF8B5CF6),
            width: 2
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        errorText: showError ? 'Ce champ est obligatoire' : null,
      ),
      onChanged: (value) => setState(() {}), // Refresh pour les indicateurs
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    List<String>? itemLabels,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      dropdownColor: Colors.white,
      items: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final displayLabel = itemLabels != null && index < itemLabels.length
            ? itemLabels[index]
            : item;
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            displayLabel,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? selectedDate,
    required void Function(DateTime) onDateSelected,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          onDateSelected(date);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFF6B7280)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedDate != null
                        ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                        : 'Sélectionner une date',
                    style: TextStyle(
                      fontSize: 16,
                      color: selectedDate != null
                          ? const Color(0xFF111827)
                          : const Color(0xFF9CA3AF),
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

  Widget _buildPhotoUploadSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    // Déterminer quelle image afficher selon le titre
    File? currentImage;
    if (title.contains('carte grise')) {
      currentImage = _imageCarteGrise;
    } else if (title.contains('permis')) {
      currentImage = _imagePermis;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: currentImage != null ? const Color(0xFFF0FDF4) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: currentImage != null ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
          width: currentImage != null ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          if (currentImage != null) ...[
            // Prévisualisation de l'image
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: FileImage(currentImage),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Photo ajoutée avec succès',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF065F46),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      if (title.contains('carte grise')) {
                        _imageCarteGrise = null;
                      } else if (title.contains('permis')) {
                        _imagePermis = null;
                      }
                    });
                  },
                  icon: const Icon(Icons.delete, size: 16, color: Color(0xFFEF4444)),
                  label: const Text(
                    'Supprimer',
                    style: TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.camera_alt, size: 16),
                label: const Text('Changer la photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Interface d'upload initial
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(icon, color: const Color(0xFF8B5CF6), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.add_a_photo, size: 16),
                  label: const Text('Ajouter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showPhotoUploadDialog(String type) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Ajouter une photo ${type == 'carte_grise' ? 'de la carte grise' : 'du permis'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPhotoOption(
                          icon: Icons.camera_alt,
                          title: 'Caméra',
                          subtitle: 'Prendre une photo',
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.camera, type);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPhotoOption(
                          icon: Icons.photo_library,
                          title: 'Galerie',
                          subtitle: 'Choisir une photo',
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.gallery, type);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF8B5CF6),
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, String type) async {
    try {
      // Demander les permissions
      if (source == ImageSource.camera) {
        final cameraStatus = await Permission.camera.request();
        if (cameraStatus.isDenied) {
          _showErrorSnackBar('Permission caméra refusée');
          return;
        }
      } else {
        final storageStatus = await Permission.photos.request();
        if (storageStatus.isDenied) {
          _showErrorSnackBar('Permission galerie refusée');
          return;
        }
      }

      // Sélectionner l'image
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          if (type == 'carte_grise') {
            _imageCarteGrise = File(pickedFile.path);
          } else {
            _imagePermis = File(pickedFile.path);
          }
        });

        _showSuccessSnackBar('Photo ${type == 'carte_grise' ? 'carte grise' : 'permis'} ajoutée avec succès !');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sélection de l\'image: $e');
    }
  }

  /// 🌐 Upload image vers Cloudinary (remplace Firebase Storage)
  Future<String?> _uploadImageToCloudinary(File imageFile, String type, String userId) async {
    try {
      print('🌐 Upload Cloudinary: $type pour utilisateur $userId');

      final result = await HybridStorageService.uploadImage(
        imageFile: imageFile,
        vehiculeId: userId,
        type: type,
      );

      if (result['success'] == true) {
        final imageUrl = result['url'] as String;
        print('✅ Image uploadée sur ${result['storage']}: $imageUrl');
        return imageUrl;
      } else {
        print('❌ Échec upload: ${result['message']}');
        return null;
      }
    } catch (e) {
      print('❌ Erreur upload Cloudinary: $e');
      return null;
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showProgressSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF8B5CF6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _canSave() && !_isLoading ? _saveVehicle : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Enregistrer le Véhicule',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  bool _canSave() {
    // Champs obligatoires de base
    final basicFieldsValid = _plateController.text.trim().isNotEmpty &&
                            _brandController.text.trim().isNotEmpty &&
                            _modelController.text.trim().isNotEmpty &&
                            _yearController.text.trim().isNotEmpty &&
                            _colorController.text.trim().isNotEmpty;

    // Champs obligatoires pour les documents
    final documentsValid = _carteGriseController.text.trim().isNotEmpty &&
                          _nomProprietaireController.text.trim().isNotEmpty &&
                          _prenomProprietaireController.text.trim().isNotEmpty;

    // Champs obligatoires pour le permis
    final permisValid = _numeroPermisController.text.trim().isNotEmpty;

    // Validation de base
    bool isValid = basicFieldsValid && documentsValid && permisValid;

    // Si assurance activée, vérifier les champs d'assurance
    if (_hasInsurance) {
      final insuranceFieldsValid = _selectedCompagnieId != null &&
                                  _selectedAgenceId != null &&
                                  _contractController.text.trim().isNotEmpty;
      isValid = isValid && insuranceFieldsValid;
    }

    return isValid;
  }

  /// Charge la liste des compagnies depuis Firebase
  Future<void> _loadCompagnies() async {
    setState(() => _isLoadingCompagnies = true);

    try {
      print('🔄 Début du chargement des compagnies...');
      final compagnies = await InsuranceDataService.getCompagnies();

      setState(() {
        _compagnies = compagnies;
        _isLoadingCompagnies = false;
      });

      print('✅ ${compagnies.length} compagnies chargées avec succès');

      if (compagnies.isNotEmpty) {
        _showSuccessSnackBar('${compagnies.length} compagnies d\'assurance chargées');
      }
    } catch (e) {
      setState(() {
        _compagnies = [];
        _isLoadingCompagnies = false;
      });

      print('❌ Erreur chargement compagnies: $e');
      _showErrorSnackBar('Impossible de charger les compagnies d\'assurance.\nVérifiez votre connexion internet.');
    }
  }

  /// Charge la liste des agences pour une compagnie donnée
  Future<void> _loadAgences(String compagnieId) async {
    setState(() {
      _isLoadingAgences = true;
      _agences = [];
      _selectedAgenceId = null;
    });

    try {
      print('🔄 Début du chargement des agences pour: $compagnieId');
      final agences = await InsuranceDataService.getAgencesByCompagnie(compagnieId);

      setState(() {
        _agences = agences;
        _isLoadingAgences = false;
      });

      print('✅ ${agences.length} agences chargées avec succès');

      if (agences.isEmpty) {
        _showErrorSnackBar('Aucune agence disponible pour cette compagnie');
      } else {
        _showSuccessSnackBar('${agences.length} agences trouvées');
      }
    } catch (e) {
      setState(() {
        _agences = [];
        _isLoadingAgences = false;
      });

      print('❌ Erreur chargement agences: $e');
      _showErrorSnackBar('Impossible de charger les agences.\nVérifiez votre connexion internet.');
    }
  }

  /// Crée des données de test dans Firebase (développement uniquement)
  Future<void> _createTestData() async {
    try {
      _showProgressSnackBar('Création des données de test...');

      await InsuranceDataService.createTestData();

      _showSuccessSnackBar('Données de test créées avec succès !');

      // Recharger les compagnies après création
      await _loadCompagnies();
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la création des données de test: $e');
    }
  }

  /// Upload les images en arrière-plan avec compression et gestion d'erreurs robuste
  Future<void> _uploadImagesInBackgroundOptimized(String vehiculeId, String userId) async {
    try {
      print('🔄 Début upload images optimisé en arrière-plan pour véhicule: $vehiculeId');

      String? imageCarteGriseUrl;
      String? imagePermisUrl;

      // Upload carte grise si présente
      if (_imageCarteGrise != null) {
        try {
          print('📄 Compression et upload carte grise...');
          final compressedImage = await _compressImage(_imageCarteGrise!);
          imageCarteGriseUrl = await _uploadImageToCloudinaryOptimized(compressedImage, 'carte_grise', userId);
          if (imageCarteGriseUrl != null) {
            print('✅ Carte grise uploadée: $imageCarteGriseUrl');
          }
        } catch (e) {
          print('❌ Erreur upload carte grise: $e');
          // Continuer même si une image échoue
        }
      }

      // Upload permis si présent
      if (_imagePermis != null) {
        try {
          print('🪪 Compression et upload permis...');
          final compressedImage = await _compressImage(_imagePermis!);
          imagePermisUrl = await _uploadImageToCloudinaryOptimized(compressedImage, 'permis', userId);
          if (imagePermisUrl != null) {
            print('✅ Permis uploadé: $imagePermisUrl');
          }
        } catch (e) {
          print('❌ Erreur upload permis: $e');
          // Continuer même si une image échoue
        }
      }

      // Mettre à jour le véhicule avec les URLs des images (seulement celles qui ont réussi)
      if (imageCarteGriseUrl != null || imagePermisUrl != null) {
        try {
          await VehiculeService.updateVehiculeImages(vehiculeId, imageCarteGriseUrl, imagePermisUrl);
          print('✅ Véhicule mis à jour avec les images disponibles');

          // Notification de succès pour les images uploadées
          _showBackgroundSuccessNotification(imageCarteGriseUrl != null, imagePermisUrl != null);
        } catch (e) {
          print('❌ Erreur mise à jour véhicule: $e');
        }
      } else {
        // Aucune image n'a pu être uploadée
        print('⚠️ Aucune image n\'a pu être uploadée - problème de connexion ou de configuration Cloudinary');
        _showBackgroundErrorNotification();
      }

    } catch (e) {
      print('❌ Erreur générale upload images: $e');
      _showBackgroundErrorNotification();
    }
  }

  /// Affiche une notification de succès pour l'upload en arrière-plan
  void _showBackgroundSuccessNotification(bool carteGriseUploaded, bool permisUploaded) {
    String message = 'Images uploadées avec succès : ';
    if (carteGriseUploaded && permisUploaded) {
      message += 'carte grise et permis';
    } else if (carteGriseUploaded) {
      message += 'carte grise';
    } else if (permisUploaded) {
      message += 'permis';
    }

    // Cette notification pourrait être affichée via un service de notifications
    print('🎉 $message');
  }

  /// Affiche une notification d'erreur pour l'upload en arrière-plan
  void _showBackgroundErrorNotification() {
    print('⚠️ Les images n\'ont pas pu être uploadées. Vous pourrez les ajouter plus tard depuis la liste des véhicules.');

    // Cette notification pourrait être affichée via un service de notifications
    // ou stockée pour être affichée lors de la prochaine ouverture de l'app
  }

  /// Compresse une image pour réduire sa taille
  Future<File> _compressImage(File imageFile) async {
    try {
      final String targetPath = '${imageFile.path}_compressed.jpg';

      final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: 70, // Qualité 70% pour un bon compromis taille/qualité
        minWidth: 1024, // Largeur max 1024px
        minHeight: 1024, // Hauteur max 1024px
        format: CompressFormat.jpeg,
      );

      if (compressedFile != null) {
        final compressedFileObj = File(compressedFile.path);
        final originalSize = await imageFile.length();
        final compressedSize = await compressedFileObj.length();

        print('📦 Compression: ${originalSize} bytes → ${compressedSize} bytes (${((1 - compressedSize/originalSize) * 100).toStringAsFixed(1)}% de réduction)');

        return compressedFileObj;
      } else {
        print('⚠️ Compression échouée, utilisation de l\'image originale');
        return imageFile;
      }
    } catch (e) {
      print('❌ Erreur compression: $e, utilisation de l\'image originale');
      return imageFile;
    }
  }

  /// 🌐 Upload optimisé vers Cloudinary avec compression
  Future<String?> _uploadImageToCloudinaryOptimized(File imageFile, String type, String userId) async {
    try {
      print('🌐 Upload Cloudinary optimisé: $type pour utilisateur $userId');

      final result = await HybridStorageService.uploadImage(
        imageFile: imageFile,
        vehiculeId: userId,
        type: type,
      );

      if (result['success'] == true) {
        final imageUrl = result['url'] as String;
        print('✅ Image uploadée sur ${result['storage']}: $imageUrl');
        return imageUrl;
      } else {
        print('❌ Échec upload optimisé: ${result['message']}');
        return null;
      }
    } catch (e) {
      print('❌ Erreur upload Cloudinary optimisé: $e');
      return null;
    }
  }

  Future<void> _saveVehicle() async {
    if (!_canSave()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      _showProgressSnackBar('Enregistrement du véhicule...');

      // Créer le véhicule IMMÉDIATEMENT sans attendre les images
      final vehicule = Vehicule(
        conducteurId: currentUser.uid,
        marque: _brandController.text.trim(),
        modele: _modelController.text.trim(),
        numeroImmatriculation: _plateController.text.trim().toUpperCase(),
        couleur: _colorController.text.trim(),
        annee: int.tryParse(_yearController.text) ?? DateTime.now().year,
        typeVehicule: _selectedTypeVehicule,
        carburant: _selectedCarburant,
        usage: _selectedUsage,
        nombrePlaces: _selectedNombrePlaces,
        numeroSerie: _numeroSerieController.text.trim(),
        puissanceFiscale: _puissanceFiscaleController.text.trim(),
        cylindree: _cylindreeController.text.trim(),
        poids: double.tryParse(_poidsController.text) ?? 0.0,
        genre: _selectedTypeVehicule,
        numeroCarteGrise: _carteGriseController.text.trim(),
        datePremiereImmatriculation: _dateImmatriculation ?? DateTime.now(),
        dateMiseEnCirculation: _dateMiseCirculation ?? DateTime.now(),
        imageCarteGriseUrl: null, // Sera ajouté plus tard
        nomProprietaire: _nomProprietaireController.text.trim().isNotEmpty
            ? _nomProprietaireController.text.trim()
            : 'Non spécifié',
        prenomProprietaire: _prenomProprietaireController.text.trim().isNotEmpty
            ? _prenomProprietaireController.text.trim()
            : 'Non spécifié',
        adresseProprietaire: _adresseProprietaireController.text.trim().isNotEmpty
            ? _adresseProprietaireController.text.trim()
            : 'Non spécifiée',
        numeroPermis: _numeroPermisController.text.trim(),
        categoriePermis: _selectedCategoriePermis,
        dateObtentionPermis: _dateObtentionPermis ?? DateTime.now(),
        dateExpirationPermis: _dateExpirationPermis ?? DateTime.now().add(const Duration(days: 3650)),
        imagePermisUrl: null, // Sera ajouté plus tard
        estAssure: _hasInsurance,
        compagnieAssuranceId: _hasInsurance ? _selectedCompagnieId : null,
        agenceAssuranceId: _hasInsurance ? _selectedAgenceId : null,
        numeroContratAssurance: _hasInsurance ? _contractController.text.trim() : null,
        dateDebutAssurance: _hasInsurance ? _dateDebutAssurance : null,
        dateFinAssurance: _hasInsurance ? _dateFinAssurance : null,
        dateDerniereAssurance: _hasInsurance ? _dateDerniereAssurance : null,
        etatCompte: _selectedEtatCompte,
        controleValide: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: currentUser.uid,
      );

      // Enregistrer le véhicule RAPIDEMENT
      final vehiculeId = await VehiculeService.createVehicule(vehicule);

      if (mounted) {
        setState(() => _isLoading = false);

        // Message différent selon la présence d'images
        if (_imageCarteGrise != null || _imagePermis != null) {
          _showSuccessSnackBar('Véhicule enregistré ! Upload des images en cours...');
          // Démarrer l'upload des images EN ARRIÈRE-PLAN
          _uploadImagesInBackgroundOptimized(vehiculeId, currentUser.uid);
        } else {
          _showSuccessSnackBar('Véhicule enregistré avec succès !');
        }

        Navigator.pop(context, true); // Retourner true pour indiquer le succès
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }



  /// Widget dropdown pour les compagnies d'assurance
  Widget _buildCompagnieDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Compagnie d\'assurance *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        if (_compagnies.isEmpty && !_isLoadingCompagnies) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEF4444)),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 32),
                const SizedBox(height: 8),
                const Text(
                  'Aucune compagnie d\'assurance trouvée',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Vérifiez votre connexion internet',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7F1D1D),
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loadCompagnies,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Réessayer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _createTestData,
                        icon: const Icon(Icons.science, size: 16),
                        label: const Text('Créer données de test'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<String>(
          value: _selectedCompagnieId,
          decoration: InputDecoration(
            hintText: _isLoadingCompagnies
                ? 'Chargement des compagnies...'
                : _compagnies.isEmpty
                    ? 'Aucune compagnie disponible'
                    : 'Sélectionner une compagnie',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: _isLoadingCompagnies
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          dropdownColor: Colors.white,
          items: _compagnies.map((compagnie) {
            return DropdownMenuItem<String>(
              value: compagnie['id'],
              child: Text(
                compagnie['nom'],
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: _isLoadingCompagnies ? null : (value) {
            setState(() {
              _selectedCompagnieId = value;
              _selectedAgenceId = null;
              _agences = [];
            });
            if (value != null) {
              _loadAgences(value);
            }
          },
        ),
      ],
    );
  }

  /// Widget dropdown pour les agences
  Widget _buildAgenceDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Agence d\'assurance *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedAgenceId,
          decoration: InputDecoration(
            hintText: _isLoadingAgences
                ? 'Chargement des agences...'
                : _agences.isEmpty
                    ? 'Aucune agence disponible'
                    : 'Sélectionner une agence',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: _isLoadingAgences
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          dropdownColor: Colors.white,
          items: _agences.map((agence) {
            return DropdownMenuItem<String>(
              value: agence['id'],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    agence['nom'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (agence['ville'] != null && agence['ville'].isNotEmpty)
                    Text(
                      agence['ville'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: _isLoadingAgences || _agences.isEmpty ? null : (value) {
            setState(() => _selectedAgenceId = value);
          },
        ),
      ],
    );
  }
}
