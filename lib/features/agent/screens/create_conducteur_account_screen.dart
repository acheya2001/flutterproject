import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/email_notification_service.dart';

/// 👨‍💼 Écran pour l'agent - Créer un compte conducteur existant
class CreateConducteurAccountScreen extends StatefulWidget {
  const CreateConducteurAccountScreen({Key? key}) : super(key: key);

  @override
  State<CreateConducteurAccountScreen> createState() => _CreateConducteurAccountScreenState();
}

class _CreateConducteurAccountScreenState extends State<CreateConducteurAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _errorMessage = '';

  // Controllers pour les informations du conducteur
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _cinController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _adresseController = TextEditingController();

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
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _cinController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    _immatriculationController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _anneeController.dispose();
    _puissanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Créer Compte Conducteur',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        centerTitle: true,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 24),
                    _buildConducteurSection(),
                    const SizedBox(height: 24),
                    _buildVehiculeSection(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Création de compte conducteur existant',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Créez un compte pour un conducteur qui possède déjà un contrat d\'assurance. Les identifiants seront envoyés par email.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConducteurSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Informations du conducteur', Icons.person),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _prenomController,
                label: 'Prénom',
                icon: Icons.person_outline,
                validator: (value) => value?.isEmpty == true ? 'Prénom requis' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _nomController,
                label: 'Nom',
                icon: Icons.person,
                validator: (value) => value?.isEmpty == true ? 'Nom requis' : null,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        _buildTextField(
          controller: _cinController,
          label: 'Numéro CIN',
          icon: Icons.badge,
          validator: (value) {
            if (value?.isEmpty == true) return 'CIN requis';
            if (value!.length != 8) return 'CIN doit contenir 8 chiffres';
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _telephoneController,
                label: 'Téléphone',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) => value?.isEmpty == true ? 'Téléphone requis' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Email requis';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                    return 'Email invalide';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        _buildTextField(
          controller: _adresseController,
          label: 'Adresse',
          icon: Icons.location_on,
          maxLines: 2,
          validator: (value) => value?.isEmpty == true ? 'Adresse requise' : null,
        ),
      ],
    );
  }

  Widget _buildVehiculeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Véhicule assuré', Icons.directions_car),
        const SizedBox(height: 16),
        
        _buildTextField(
          controller: _immatriculationController,
          label: 'Numéro d\'immatriculation',
          icon: Icons.confirmation_number,
          validator: (value) => value?.isEmpty == true ? 'Immatriculation requise' : null,
        ),
        
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _marqueController,
                label: 'Marque',
                icon: Icons.branding_watermark,
                validator: (value) => value?.isEmpty == true ? 'Marque requise' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _modeleController,
                label: 'Modèle',
                icon: Icons.model_training,
                validator: (value) => value?.isEmpty == true ? 'Modèle requis' : null,
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
          items: _typesVehicules.map((type) => DropdownMenuItem(
            value: type['value'],
            child: Text(type['label']!),
          )).toList(),
          onChanged: (value) => setState(() => _selectedTypeVehicule = value),
        ),
        
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                label: 'Carburant',
                icon: Icons.local_gas_station,
                value: _selectedCarburant,
                items: _carburants.map((carburant) => DropdownMenuItem(
                  value: carburant,
                  child: Text(carburant),
                )).toList(),
                onChanged: (value) => setState(() => _selectedCarburant = value),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: 'Usage',
                icon: Icons.work,
                value: _selectedUsage,
                items: _usages.map((usage) => DropdownMenuItem(
                  value: usage,
                  child: Text(usage),
                )).toList(),
                onChanged: (value) => setState(() => _selectedUsage = value),
              ),
            ),
          ],
        ),
      ],
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

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
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
            : const Text(
                'Créer le compte et envoyer les identifiants',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTypeVehicule == null) {
      _showError('Veuillez sélectionner le type de véhicule');
      return;
    }

    if (_selectedCarburant == null) {
      _showError('Veuillez sélectionner le type de carburant');
      return;
    }

    if (_selectedUsage == null) {
      _showError('Veuillez sélectionner l\'usage du véhicule');
      return;
    }

    if (mounted) setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Vérifier si l'email existe déjà
      final existingUser = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _emailController.text.trim())
          .get();

      if (existingUser.docs.isNotEmpty) {
        throw Exception('Un compte avec cet email existe déjà');
      }

      // Générer un mot de passe temporaire
      final tempPassword = _generateTempPassword();

      // Créer le compte Firebase Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: tempPassword,
      );

      final userId = userCredential.user!.uid;

      // Récupérer les informations de l'agent connecté
      final currentUser = FirebaseAuth.instance.currentUser;
      final agentDoc = await FirebaseFirestore.instance
          .collection('agents_assurance')
          .where('email', isEqualTo: currentUser?.email)
          .limit(1)
          .get();

      String? agentId;
      String? compagnieId;
      String? agenceId;

      if (agentDoc.docs.isNotEmpty) {
        final agentData = agentDoc.docs.first.data();
        agentId = agentDoc.docs.first.id;
        compagnieId = agentData['compagnieId'];
        agenceId = agentData['agenceId'];
      }

      // Créer le profil utilisateur
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'cin': _cinController.text.trim(),
        'telephone': _telephoneController.text.trim(),
        'email': _emailController.text.trim(),
        'adresse': _adresseController.text.trim(),
        'role': 'conducteur',
        'statut': 'actif',
        'dateCreation': FieldValue.serverTimestamp(),
        'creePar': agentId,
        'typeCreation': 'agent_creation',
        'tempPassword': tempPassword, // Temporaire pour l'email
      });

      // Créer le contrat d'assurance
      await FirebaseFirestore.instance.collection('contrats_assurance').add({
        'conducteurId': userId,
        'conducteur': {
          'nom': _nomController.text.trim(),
          'prenom': _prenomController.text.trim(),
          'cin': _cinController.text.trim(),
          'telephone': _telephoneController.text.trim(),
          'email': _emailController.text.trim(),
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
        'compagnieId': compagnieId,
        'agenceId': agenceId,
        'agentId': agentId,
        'statut': 'actif',
        'dateCreation': FieldValue.serverTimestamp(),
        'dateDebut': FieldValue.serverTimestamp(),
        'typeContrat': 'existant_cree_par_agent',
      });

      // Envoyer l'email avec les identifiants
      await _sendCredentialsEmail(
        _emailController.text.trim(),
        _prenomController.text.trim(),
        _nomController.text.trim(),
        tempPassword,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Compte créé avec succès ! Les identifiants ont été envoyés par email.'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 5),
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showError('Erreur lors de la création du compte: $e');
      }
    } finally {
      if (mounted) {
        if (mounted) setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _generateTempPassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(8, (index) => chars[random % chars.length]).join();
  }

  Future<void> _sendCredentialsEmail(String email, String prenom, String nom, String password) async {
    try {
      // TODO: Implémenter l'envoi d'email avec les identifiants
      print('Email à envoyer à $email avec mot de passe: $password');
    } catch (e) {
      print('Erreur lors de l\'envoi de l\'email: $e');
      // Ne pas faire échouer la création du compte si l'email échoue
    }
  }

  void _showError(String message) {
    if (mounted) setState(() {
      _errorMessage = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );

    // Effacer le message d'erreur après 5 secondes
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        if (mounted) setState(() {
          _errorMessage = '';
        });
      }
    });
  }
}

