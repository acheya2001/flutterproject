import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../services/cloudinary_service.dart';

/// 🚗 Écran de nouvelle demande d'assurance pour un véhicule supplémentaire
class NewInsuranceRequestScreen extends StatefulWidget {
  const NewInsuranceRequestScreen({Key? key}) : super(key: key);

  @override
  State<NewInsuranceRequestScreen> createState() => _NewInsuranceRequestScreenState();
}

class _NewInsuranceRequestScreenState extends State<NewInsuranceRequestScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  bool _isLoading = false;
  String _errorMessage = '';

  // Controllers pour les informations du véhicule
  final _immatriculationController = TextEditingController();
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _anneeController = TextEditingController();
  final _puissanceController = TextEditingController();

  // Sélections
  String? _selectedTypeVehicule;
  String? _selectedCarburant;
  String? _selectedUsage;
  String? _selectedCompagnie;
  String? _selectedAgence;

  // Images
  File? _carteGriseImage;
  File? _carteGriseVersoImage;

  // Données
  List<Map<String, dynamic>> _compagnies = [];
  List<Map<String, dynamic>> _agences = [];

  // Types de véhicules
  final List<Map<String, String>> _typesVehicules = [
    {'value': 'VP', 'label': 'Voiture Particulière (VP)'},
    {'value': 'VU', 'label': 'Véhicule Utilitaire (VU)'},
    {'value': 'PL', 'label': 'Poids Lourd (PL)'},
    {'value': 'MOTO', 'label': 'Motocyclette'},
    {'value': 'SCOOTER', 'label': 'Scooter'},
    {'value': 'QUAD', 'label': 'Quad/ATV'},
    {'value': 'TRACTEUR', 'label': 'Tracteur Agricole'},
    {'value': 'REMORQUE', 'label': 'Remorque'},
    {'value': 'AUTOCAR', 'label': 'Autocar'},
    {'value': 'TAXI', 'label': 'Taxi'},
    {'value': 'AMBULANCE', 'label': 'Ambulance'},
    {'value': 'CAMIONNETTE', 'label': 'Camionnette'},
    {'value': 'FOURGON', 'label': 'Fourgon'},
    {'value': 'AUTRE', 'label': 'Autre'},
  ];

  final List<String> _carburants = [
    'Essence',
    'Diesel',
    'GPL',
    'Électrique',
    'Hybride',
    'Autre'
  ];

  final List<String> _usages = [
    'Personnel',
    'Professionnel',
    'Commercial',
    'Transport',
    'Agricole',
    'Autre'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCompagnies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _immatriculationController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _anneeController.dispose();
    _puissanceController.dispose();
    super.dispose();
  }

  Future<void> _loadCompagnies() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('compagnies_assurance')
          .where('statut', isEqualTo: 'actif')
          .orderBy('nom')
          .get();

      setState(() {
        _compagnies = snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
      });
    } catch (e) {
      print('Erreur lors du chargement des compagnies: $e');
    }
  }

  Future<void> _loadAgences(String compagnieId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('agences_assurance')
          .where('compagnieId', isEqualTo: compagnieId)
          .where('statut', isEqualTo: 'actif')
          .orderBy('nom')
          .get();

      setState(() {
        _agences = snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
      });
    } catch (e) {
      print('Erreur lors du chargement des agences: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Nouvelle Demande d\'Assurance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF3B82F6),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: const Color(0xFF3B82F6),
          tabs: const [
            Tab(
              icon: Icon(Icons.directions_car),
              text: 'Véhicule',
            ),
            Tab(
              icon: Icon(Icons.image),
              text: 'Documents',
            ),
            Tab(
              icon: Icon(Icons.business),
              text: 'Assurance',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_errorMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.red[50],
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red[700]),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVehicleInfoTab(),
                _buildDocumentsTab(),
                _buildInsuranceSelectionTab(),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Informations du véhicule', Icons.directions_car),
            const SizedBox(height: 20),
            
            _buildTextField(
              controller: _immatriculationController,
              label: 'Numéro d\'immatriculation',
              icon: Icons.confirmation_number,
              validator: (value) => value?.isEmpty == true ? 'Immatriculation requise' : null,
            ),
            
            const SizedBox(height: 16),
            _buildTextField(
              controller: _marqueController,
              label: 'Marque',
              icon: Icons.branding_watermark,
              validator: (value) => value?.isEmpty == true ? 'Marque requise' : null,
            ),
            
            const SizedBox(height: 16),
            _buildTextField(
              controller: _modeleController,
              label: 'Modèle',
              icon: Icons.model_training,
              validator: (value) => value?.isEmpty == true ? 'Modèle requis' : null,
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
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Année requise';
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
                  child: _buildTextField(
                    controller: _puissanceController,
                    label: 'Puissance (CV)',
                    icon: Icons.speed,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Puissance requise';
                      final power = int.tryParse(value!);
                      if (power == null || power <= 0) {
                        return 'Puissance invalide';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            _buildDropdownField(
              label: 'Type de véhicule',
              icon: Icons.category,
              value: _selectedTypeVehicule,
              items: _typesVehicules.map((type) => DropdownMenuItem<String>(
                value: type['value'],
                child: Text(type['label']!),
              )).toList(),
              onChanged: (value) => setState(() => _selectedTypeVehicule = value),
            ),
            
            const SizedBox(height: 16),
            _buildDropdownField(
              label: 'Type de carburant',
              icon: Icons.local_gas_station,
              value: _selectedCarburant,
              items: _carburants.map((carburant) => DropdownMenuItem<String>(
                value: carburant,
                child: Text(carburant),
              )).toList(),
              onChanged: (value) => setState(() => _selectedCarburant = value),
            ),
            
            const SizedBox(height: 16),
            _buildDropdownField(
              label: 'Usage du véhicule',
              icon: Icons.work,
              value: _selectedUsage,
              items: _usages.map((usage) => DropdownMenuItem<String>(
                value: usage,
                child: Text(usage),
              )).toList(),
              onChanged: (value) => setState(() => _selectedUsage = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF3B82F6),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
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
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF3B82F6)),
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
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF3B82F6)),
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
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items,
      onChanged: onChanged,
      validator: (value) => value == null ? '$label requis' : null,
    );
  }

  Widget _buildDocumentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Documents du véhicule', Icons.image),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Prenez des photos claires et lisibles des documents. Assurez-vous que tous les textes sont visibles.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildImageUploadCard(
            title: 'Carte Grise (Recto)',
            subtitle: 'Photo de la face avant de la carte grise',
            icon: Icons.credit_card,
            image: _carteGriseImage,
            onTap: () => _pickImage('carte_grise'),
          ),

          const SizedBox(height: 16),

          _buildImageUploadCard(
            title: 'Carte Grise (Verso)',
            subtitle: 'Photo de la face arrière de la carte grise',
            icon: Icons.credit_card,
            image: _carteGriseVersoImage,
            onTap: () => _pickImage('carte_grise_verso'),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Documents requis',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDocumentRequirement('Carte grise recto', _carteGriseImage != null),
                _buildDocumentRequirement('Carte grise verso', _carteGriseVersoImage != null),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required File? image,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: image != null ? const Color(0xFF10B981) : Colors.grey[300]!,
            width: image != null ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (image != null ? const Color(0xFF10B981) : const Color(0xFF3B82F6)).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    image != null ? Icons.check_circle : icon,
                    color: image != null ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
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
                Icon(
                  image != null ? Icons.edit : Icons.camera_alt,
                  color: const Color(0xFF3B82F6),
                ),
              ],
            ),

            if (image != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  image,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentRequirement(String document, bool isUploaded) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isUploaded ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: isUploaded ? const Color(0xFF10B981) : Colors.grey[400],
          ),
          const SizedBox(width: 12),
          Text(
            document,
            style: TextStyle(
              fontSize: 14,
              color: isUploaded ? const Color(0xFF10B981) : Colors.grey[600],
              fontWeight: isUploaded ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsuranceSelectionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Sélection de l\'assurance', Icons.business),
          const SizedBox(height: 20),

          _buildDropdownField(
            label: 'Compagnie d\'assurance',
            icon: Icons.business,
            value: _selectedCompagnie,
            items: _compagnies.map((compagnie) => DropdownMenuItem<String>(
              value: compagnie['id'] as String,
              child: Text(compagnie['nom'] ?? 'Compagnie'),
            )).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCompagnie = value;
                _selectedAgence = null;
                _agences.clear();
              });
              if (value != null) {
                _loadAgences(value);
              }
            },
          ),

          const SizedBox(height: 16),
          _buildDropdownField(
            label: 'Agence',
            icon: Icons.location_city,
            value: _selectedAgence,
            items: _agences.map((agence) => DropdownMenuItem<String>(
              value: agence['id'] as String,
              child: Text(agence['nom'] ?? 'Agence'),
            )).toList(),
            onChanged: (value) => setState(() => _selectedAgence = value),
          ),

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF3B82F6),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Processus de traitement',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildProcessStep('1', 'Soumission de votre demande'),
                _buildProcessStep('2', 'Validation par l\'admin d\'agence'),
                _buildProcessStep('3', 'Affectation à un agent'),
                _buildProcessStep('4', 'Traitement par l\'agent'),
                _buildProcessStep('5', 'Rendez-vous à l\'agence pour finaliser'),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Votre demande sera traitée dans les plus brefs délais. Vous recevrez une notification une fois approuvée.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessStep(String number, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_tabController.index > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _tabController.animateTo(_tabController.index - 1);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Précédent'),
              ),
            ),

          if (_tabController.index > 0) const SizedBox(width: 16),

          Expanded(
            flex: _tabController.index == 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleNextButton,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _tabController.index == 2 ? 'Soumettre la demande' : 'Suivant',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNextButton() {
    if (_tabController.index < 2) {
      if (_validateCurrentTab()) {
        _tabController.animateTo(_tabController.index + 1);
      }
    } else {
      _submitRequest();
    }
  }

  bool _validateCurrentTab() {
    switch (_tabController.index) {
      case 0:
        if (!_formKey.currentState!.validate()) return false;
        if (_selectedTypeVehicule == null) {
          _showError('Veuillez sélectionner le type de véhicule');
          return false;
        }
        if (_selectedCarburant == null) {
          _showError('Veuillez sélectionner le type de carburant');
          return false;
        }
        if (_selectedUsage == null) {
          _showError('Veuillez sélectionner l\'usage du véhicule');
          return false;
        }
        return true;
      case 1:
        if (_carteGriseImage == null) {
          _showError('Veuillez prendre une photo de la carte grise (recto)');
          return false;
        }
        if (_carteGriseVersoImage == null) {
          _showError('Veuillez prendre une photo de la carte grise (verso)');
          return false;
        }
        return true;
      case 2:
        if (_selectedCompagnie == null) {
          _showError('Veuillez sélectionner une compagnie d\'assurance');
          return false;
        }
        if (_selectedAgence == null) {
          _showError('Veuillez sélectionner une agence');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );

    // Effacer le message d'erreur après 3 secondes
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _errorMessage = '';
        });
      }
    });
  }

  Future<void> _pickImage(String type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          switch (type) {
            case 'carte_grise':
              _carteGriseImage = File(image.path);
              break;
            case 'carte_grise_verso':
              _carteGriseVersoImage = File(image.path);
              break;
          }
        });
      }
    } catch (e) {
      _showError('Erreur lors de la prise de photo: $e');
    }
  }

  Future<void> _submitRequest() async {
    if (!_validateCurrentTab()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer les informations du conducteur
      final conducteurDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!conducteurDoc.exists) {
        throw Exception('Profil conducteur non trouvé');
      }

      final conducteurData = conducteurDoc.data()!;

      // Upload des images vers Cloudinary
      Map<String, String> imageUrls = {};

      if (_carteGriseImage != null) {
        final url = await CloudinaryService.uploadImage(_carteGriseImage!, 'carte_grise');
        if (url != null) imageUrls['carte_grise'] = url;
      }

      if (_carteGriseVersoImage != null) {
        final url = await CloudinaryService.uploadImage(_carteGriseVersoImage!, 'carte_grise_verso');
        if (url != null) imageUrls['carte_grise_verso'] = url;
      }

      // Créer la demande d'assurance
      await FirebaseFirestore.instance.collection('insurance_requests').add({
        'conducteurId': user.uid,
        'conducteur': {
          'nom': conducteurData['nom'],
          'prenom': conducteurData['prenom'],
          'cin': conducteurData['cin'],
          'telephone': conducteurData['telephone'],
          'email': conducteurData['email'],
          'adresse': conducteurData['adresse'],
        },
        'vehicule': {
          'immatriculation': _immatriculationController.text.trim(),
          'marque': _marqueController.text.trim(),
          'modele': _modeleController.text.trim(),
          'annee': int.tryParse(_anneeController.text.trim()) ?? 0,
          'puissanceFiscale': int.tryParse(_puissanceController.text.trim()) ?? 0,
          'typeVehicule': _selectedTypeVehicule,
          'carburant': _selectedCarburant,
          'usage': _selectedUsage,
        },
        'assurance': {
          'compagnieId': _selectedCompagnie,
          'agenceId': _selectedAgence,
        },
        'documents': imageUrls,
        'statut': 'en_attente',
        'dateCreation': FieldValue.serverTimestamp(),
        'type': 'nouveau_vehicule', // Distinguer des demandes d'inscription
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Demande soumise avec succès ! Vous recevrez une notification une fois traitée.'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 5),
          ),
        );

        Navigator.pop(context, true); // Retourner au dashboard avec succès
      }
    } catch (e) {
      if (mounted) {
        _showError('Erreur lors de la soumission: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
