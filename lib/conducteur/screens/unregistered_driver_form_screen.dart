import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'constat_complet_screen.dart';

/// 📝 Formulaire complet pour conducteur non-inscrit
class UnregisteredDriverFormScreen extends StatefulWidget {
  final String sinistreId;
  final String conducteurLetter;
  final Map<String, dynamic> sessionData;

  const UnregisteredDriverFormScreen({
    Key? key,
    required this.sinistreId,
    required this.conducteurLetter,
    required this.sessionData,
  }) : super(key: key);

  @override
  State<UnregisteredDriverFormScreen> createState() => _UnregisteredDriverFormScreenState();
}

class _UnregisteredDriverFormScreenState extends State<UnregisteredDriverFormScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  bool _isLoading = false;

  // Controllers pour tous les champs
  final Map<String, TextEditingController> _controllers = {};

  // Listes pour les dropdowns
  List<Map<String, dynamic>> _compagnies = [];
  List<Map<String, dynamic>> _agences = [];
  String? _selectedCompagnie;
  String? _selectedAgence;

  final List<String> _sections = [
    'Informations personnelles',
    'Permis de conduire',
    'Véhicule',
    'Assurance',
    'Validation',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _sections.length, vsync: this);
    _initializeControllers();
    _loadCompagnies();
  }

  /// 🔧 Initialiser tous les controllers
  void _initializeControllers() {
    final fields = [
      // Informations personnelles
      'nom', 'prenom', 'dateNaissance', 'lieuNaissance',
      'adresse', 'ville', 'codePostal', 'telephone', 'email',
      'profession', 'nationalite',
      
      // Permis de conduire
      'numeroPermis', 'categoriePermis', 'dateDelivrancePermis',
      'lieuDelivrancePermis', 'dateValiditePermis',
      
      // Véhicule
      'marque', 'modele', 'immatriculation', 'couleur',
      'annee', 'numeroSerie', 'puissanceFiscale', 'nombrePlaces',
      'usage', 'datePremiereImmatriculation',
      
      // Assurance
      'numeroPolice', 'dateDebutContrat', 'dateFinContrat',
      'montantFranchise', 'typeContrat',
    ];

    for (String field in fields) {
      _controllers[field] = TextEditingController();
    }
  }

  /// 🏢 Charger les compagnies d'assurance
  Future<void> _loadCompagnies() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('compagnies_assurance')
          .orderBy('nom')
          .get();

      setState(() {
        _compagnies = snapshot.docs.map((doc) => {
          'id': doc.id,
          'nom': doc.data()['nom'],
          'code': doc.data()['code'],
        }).toList();
      });
    } catch (e) {
      print('❌ Erreur chargement compagnies: $e');
    }
  }

  /// 🏪 Charger les agences d'une compagnie
  Future<void> _loadAgences(String compagnieId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('compagnies_assurance')
          .doc(compagnieId)
          .collection('agences')
          .orderBy('nom')
          .get();

      setState(() {
        _agences = snapshot.docs.map((doc) => {
          'id': doc.id,
          'nom': doc.data()['nom'],
          'adresse': doc.data()['adresse'],
          'telephone': doc.data()['telephone'],
        }).toList();
        _selectedAgence = null; // Reset selection
      });
    } catch (e) {
      print('❌ Erreur chargement agences: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Conducteur ${widget.conducteurLetter} - Inscription'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _sections.map((section) => Tab(text: section)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPersonalInfoTab(),
                  _buildLicenseTab(),
                  _buildVehicleTab(),
                  _buildInsuranceTab(),
                  _buildValidationTab(),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  /// 👤 Onglet informations personnelles
  Widget _buildPersonalInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            '👤 Informations personnelles',
            'Veuillez renseigner vos informations personnelles complètes',
          ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'nom',
                  'Nom *',
                  Icons.person,
                  required: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'prenom',
                  'Prénom *',
                  Icons.person_outline,
                  required: true,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'dateNaissance',
                  'Date de naissance *',
                  Icons.calendar_today,
                  required: true,
                  inputType: TextInputType.datetime,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'lieuNaissance',
                  'Lieu de naissance *',
                  Icons.location_on,
                  required: true,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildTextField(
            'adresse',
            'Adresse complète *',
            Icons.home,
            required: true,
            maxLines: 2,
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                  'ville',
                  'Ville *',
                  Icons.location_city,
                  required: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'codePostal',
                  'Code postal *',
                  Icons.mail,
                  required: true,
                  inputType: TextInputType.number,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'telephone',
                  'Téléphone *',
                  Icons.phone,
                  required: true,
                  inputType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'email',
                  'Email *',
                  Icons.email,
                  required: true,
                  inputType: TextInputType.emailAddress,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'profession',
                  'Profession',
                  Icons.work,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'nationalite',
                  'Nationalité',
                  Icons.flag,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🛡️ Onglet assurance
  Widget _buildInsuranceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            '🛡️ Assurance',
            'Informations sur votre contrat d\'assurance',
          ),

          const SizedBox(height: 20),

          // Sélection compagnie
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedCompagnie,
              decoration: InputDecoration(
                labelText: 'Compagnie d\'assurance *',
                prefixIcon: Icon(Icons.business, color: Colors.blue[600]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              items: _compagnies.map((compagnie) {
                return DropdownMenuItem<String>(
                  value: compagnie['id'],
                  child: Text(compagnie['nom']),
                );
              }).toList(),
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez sélectionner une compagnie';
                }
                return null;
              },
            ),
          ),

          const SizedBox(height: 16),

          // Sélection agence
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedAgence,
              decoration: InputDecoration(
                labelText: 'Agence *',
                prefixIcon: Icon(Icons.store, color: Colors.blue[600]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              items: _agences.map((agence) {
                return DropdownMenuItem<String>(
                  value: agence['id'],
                  child: Text(agence['nom']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAgence = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez sélectionner une agence';
                }
                return null;
              },
            ),
          ),

          const SizedBox(height: 16),

          _buildTextField(
            'numeroPolice',
            'Numéro de police *',
            Icons.policy,
            required: true,
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'dateDebutContrat',
                  'Début contrat *',
                  Icons.calendar_today,
                  required: true,
                  inputType: TextInputType.datetime,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'dateFinContrat',
                  'Fin contrat *',
                  Icons.event_busy,
                  required: true,
                  inputType: TextInputType.datetime,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'montantFranchise',
                  'Franchise (DT)',
                  Icons.money,
                  inputType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'typeContrat',
                  'Type de contrat',
                  Icons.description,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🪪 Onglet permis de conduire
  Widget _buildLicenseTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            '🪪 Permis de conduire',
            'Informations sur votre permis de conduire',
          ),
          
          const SizedBox(height: 20),
          
          _buildTextField(
            'numeroPermis',
            'Numéro de permis *',
            Icons.credit_card,
            required: true,
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'categoriePermis',
                  'Catégorie *',
                  Icons.category,
                  required: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'dateDelivrancePermis',
                  'Date de délivrance *',
                  Icons.calendar_today,
                  required: true,
                  inputType: TextInputType.datetime,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'lieuDelivrancePermis',
                  'Lieu de délivrance *',
                  Icons.location_on,
                  required: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'dateValiditePermis',
                  'Date de validité',
                  Icons.event_available,
                  inputType: TextInputType.datetime,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🚗 Onglet véhicule
  Widget _buildVehicleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            '🚗 Véhicule impliqué',
            'Informations sur le véhicule que vous conduisiez',
          ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'marque',
                  'Marque *',
                  Icons.directions_car,
                  required: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'modele',
                  'Modèle *',
                  Icons.car_rental,
                  required: true,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'immatriculation',
                  'Immatriculation *',
                  Icons.confirmation_number,
                  required: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'couleur',
                  'Couleur *',
                  Icons.palette,
                  required: true,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'annee',
                  'Année *',
                  Icons.calendar_view_year,
                  required: true,
                  inputType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'numeroSerie',
                  'Numéro de série',
                  Icons.numbers,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
