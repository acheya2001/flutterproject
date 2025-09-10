import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/modern_sinistre_service.dart';
import '../../common/widgets/custom_app_bar.dart';
import '../../common/widgets/gradient_background.dart';
import 'modern_single_accident_info_screen.dart';

/// 👤 Écran d'inscription complète pour conducteur invité non-inscrit
class GuestRegistrationFormScreen extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  final String sessionId;

  const GuestRegistrationFormScreen({
    Key? key,
    required this.sessionData,
    required this.sessionId,
  }) : super(key: key);

  @override
  State<GuestRegistrationFormScreen> createState() => _GuestRegistrationFormScreenState();
}

class _GuestRegistrationFormScreenState extends State<GuestRegistrationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Contrôleurs pour les informations personnelles
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _cinController = TextEditingController();
  final _dateNaissanceController = TextEditingController();

  // Contrôleurs pour le véhicule
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _immatriculationController = TextEditingController();
  final _anneeController = TextEditingController();
  final _couleurController = TextEditingController();

  // Contrôleurs pour l'assurance
  final _numeroContratController = TextEditingController();
  final _numeroPoliceController = TextEditingController();
  final _dateDebutController = TextEditingController();
  final _dateFinController = TextEditingController();

  // Données sélectionnées
  String? _compagnieSelectionnee;
  String? _agenceSelectionnee;
  List<Map<String, dynamic>> _compagnies = [];
  List<Map<String, dynamic>> _agences = [];

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _chargerCompagnies();
    });
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _cinController.dispose();
    _dateNaissanceController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _immatriculationController.dispose();
    _anneeController.dispose();
    _couleurController.dispose();
    _numeroContratController.dispose();
    _numeroPoliceController.dispose();
    _dateDebutController.dispose();
    _dateFinController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _chargerCompagnies() async {
    try {
      final compagniesQuery = await FirebaseFirestore.instance
          .collection('compagnies_assurance')
          .get();

      setState(() {
        _compagnies = compagniesQuery.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
      });
    } catch (e) {
      print('❌ Erreur chargement compagnies: $e');
    }
  }

  Future<void> _chargerAgences(String compagnieId) async {
    try {
      setState(() => _isLoading = true);
      
      final agences = await ModernSinistreService.getAgencesParCompagnie(compagnieId);
      
      if (mounted) setState(() {
        _agences = agences;
        _agenceSelectionnee = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Erreur chargement agences: $e');
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _terminerInscription();
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
    switch (_currentPage) {
      case 0:
        return _nomController.text.isNotEmpty &&
               _prenomController.text.isNotEmpty &&
               _emailController.text.isNotEmpty &&
               _telephoneController.text.isNotEmpty &&
               _cinController.text.isNotEmpty;
      case 1:
        return _marqueController.text.isNotEmpty &&
               _modeleController.text.isNotEmpty &&
               _immatriculationController.text.isNotEmpty &&
               _anneeController.text.isNotEmpty;
      case 2:
        return _compagnieSelectionnee != null &&
               _agenceSelectionnee != null &&
               _numeroContratController.text.isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _terminerInscription() async {
    if (!_validateCurrentPage()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Créer les données du conducteur invité
      final conducteurData = {
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'email': _emailController.text.trim(),
        'telephone': _telephoneController.text.trim(),
        'adresse': _adresseController.text.trim(),
        'cin': _cinController.text.trim(),
        'dateNaissance': _dateNaissanceController.text.trim(),
        'compagnieId': _compagnieSelectionnee,
        'agenceId': _agenceSelectionnee,
        'isInvite': true,
        'isInscrit': false,
      };

      // Créer les données du véhicule
      final vehiculeData = {
        'marque': _marqueController.text.trim(),
        'modele': _modeleController.text.trim(),
        'immatriculation': _immatriculationController.text.trim(),
        'annee': _anneeController.text.trim(),
        'couleur': _couleurController.text.trim(),
        'numeroContrat': _numeroContratController.text.trim(),
        'numeroPolice': _numeroPoliceController.text.trim(),
        'dateDebut': _dateDebutController.text.trim(),
        'dateFin': _dateFinController.text.trim(),
        'compagnieId': _compagnieSelectionnee,
        'agenceId': _agenceSelectionnee,
      };

      // Naviguer vers le formulaire de constat
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ModernSingleAccidentInfoScreen(
            typeAccident: 'Collision entre deux véhicules',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                title: 'Inscription Conducteur',
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              _buildProgressIndicator(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildPageView(),
              ),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          for (int i = 0; i < 3; i++) ...[
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i <= _currentPage ? Colors.blue[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (i < 2) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildPageView() {
    return PageView(
      controller: _pageController,
      onPageChanged: (page) => setState(() => _currentPage = page),
      children: [
        _buildPersonalInfoPage(),
        _buildVehicleInfoPage(),
        _buildInsuranceInfoPage(),
      ],
    );
  }

  Widget _buildPersonalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Informations Personnelles',
              'Veuillez remplir vos informations personnelles',
              Icons.person,
            ),
            const SizedBox(height: 24),
            _buildTextField(_nomController, 'Nom', Icons.person_outline),
            const SizedBox(height: 16),
            _buildTextField(_prenomController, 'Prénom', Icons.person_outline),
            const SizedBox(height: 16),
            _buildTextField(_emailController, 'Email', Icons.email_outlined, 
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildTextField(_telephoneController, 'Téléphone', Icons.phone_outlined,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildTextField(_adresseController, 'Adresse', Icons.location_on_outlined),
            const SizedBox(height: 16),
            _buildTextField(_cinController, 'CIN', Icons.credit_card_outlined),
            const SizedBox(height: 16),
            _buildTextField(_dateNaissanceController, 'Date de naissance', Icons.calendar_today_outlined,
                hintText: 'JJ/MM/AAAA'),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Informations Véhicule',
            'Renseignez les détails de votre véhicule',
            Icons.directions_car,
          ),
          const SizedBox(height: 24),
          _buildTextField(_marqueController, 'Marque', Icons.directions_car_outlined),
          const SizedBox(height: 16),
          _buildTextField(_modeleController, 'Modèle', Icons.directions_car_outlined),
          const SizedBox(height: 16),
          _buildTextField(_immatriculationController, 'Immatriculation', Icons.confirmation_number_outlined),
          const SizedBox(height: 16),
          _buildTextField(_anneeController, 'Année', Icons.calendar_today_outlined,
              keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          _buildTextField(_couleurController, 'Couleur', Icons.palette_outlined),
        ],
      ),
    );
  }

  Widget _buildInsuranceInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Informations Assurance',
            'Sélectionnez votre compagnie et agence d\'assurance',
            Icons.security,
          ),
          const SizedBox(height: 24),
          _buildCompagnieDropdown(),
          const SizedBox(height: 16),
          _buildAgenceDropdown(),
          const SizedBox(height: 16),
          _buildTextField(_numeroContratController, 'Numéro de contrat', Icons.description_outlined),
          const SizedBox(height: 16),
          _buildTextField(_numeroPoliceController, 'Numéro de police', Icons.description_outlined),
          const SizedBox(height: 16),
          _buildTextField(_dateDebutController, 'Date début contrat', Icons.calendar_today_outlined,
              hintText: 'JJ/MM/AAAA'),
          const SizedBox(height: 16),
          _buildTextField(_dateFinController, 'Date fin contrat', Icons.calendar_today_outlined,
              hintText: 'JJ/MM/AAAA'),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blue[600], size: 24),
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
                    fontWeight: FontWeight.bold,
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    String? hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Ce champ est obligatoire';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCompagnieDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _compagnieSelectionnee,
        decoration: InputDecoration(
          labelText: 'Compagnie d\'assurance',
          prefixIcon: const Icon(Icons.business),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        items: _compagnies.map((compagnie) {
          return DropdownMenuItem<String>(
            value: compagnie['id'],
            child: Text(compagnie['nom'] ?? 'Compagnie'),
          );
        }).toList(),
        onChanged: (value) {
          if (mounted) setState(() {
            _compagnieSelectionnee = value;
            _agenceSelectionnee = null;
            _agences.clear();
          });
          if (value != null) {
            _chargerAgences(value);
          }
        },
        validator: (value) {
          if (value == null) {
            return 'Veuillez sélectionner une compagnie';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildAgenceDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _agenceSelectionnee,
        decoration: InputDecoration(
          labelText: 'Agence',
          prefixIcon: const Icon(Icons.location_city),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        items: _agences.map((agence) {
          return DropdownMenuItem<String>(
            value: agence['id'],
            child: Text(agence['nom'] ?? 'Agence'),
          );
        }).toList(),
        onChanged: _compagnieSelectionnee == null ? null : (value) {
          setState(() => _agenceSelectionnee = value);
        },
        validator: (value) {
          if (value == null) {
            return 'Veuillez sélectionner une agence';
          }
          return null;
        },
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
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Précédent'),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: _currentPage > 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: _validateCurrentPage() ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentPage == 2 ? 'Terminer' : 'Suivant',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

