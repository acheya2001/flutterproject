import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import '../services/universal_auth_service.dart';
import 'agent_login_screen.dart';

/// 📝 Écran d'inscription agent moderne et structuré
class AgentRegistrationScreen extends ConsumerStatefulWidget {
  const AgentRegistrationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AgentRegistrationScreen> createState() => _AgentRegistrationScreenState();
}

class _AgentRegistrationScreenState extends ConsumerState<AgentRegistrationScreen> {
  // 🎛️ Contrôleurs et clés
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  
  // 📝 Contrôleurs de texte - Informations personnelles
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _numeroAgentController = TextEditingController();

  // 📝 Contrôleurs de texte - Informations agence
  final _agenceNomController = TextEditingController();
  final _agenceAdresseController = TextEditingController();
  final _agenceVilleController = TextEditingController();
  final _agenceGouvernoratController = TextEditingController();
  final _agenceTelephoneController = TextEditingController();

  // 🔒 Variables d'état
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  int _currentPage = 0;
  
  // 📋 Sélections
  Map<String, dynamic>? _selectedCompagnie;
  String? _selectedGouvernorat;
  String? _selectedPoste;

  // 📸 Images
  File? _cinRecto;
  File? _cinVerso;
  File? _justificatifTravail;

  // 🏢 Données dynamiques
  List<Map<String, dynamic>> _compagnies = [];
  bool _loadingCompagnies = true;

  // 📊 Données statiques
  static const List<String> _postes = [
    'Agent Commercial',
    'Conseiller Clientèle',
    'Chargé de Sinistres',
    'Inspecteur Commercial',
    'Responsable Agence',
    'Chef d\'Équipe',
    'Agent de Production',
    'Gestionnaire de Contrats',
  ];

  static const List<String> _gouvernorats = [
    'Tunis', 'Ariana', 'Ben Arous', 'Manouba', 'Nabeul', 'Zaghouan',
    'Bizerte', 'Béja', 'Jendouba', 'Le Kef', 'Siliana', 'Kairouan',
    'Kasserine', 'Sidi Bouzid', 'Sousse', 'Monastir', 'Mahdia', 'Sfax',
    'Gafsa', 'Tozeur', 'Kebili', 'Gabès', 'Medenine', 'Tataouine',
  ];

  @override
  void initState() {
    super.initState();
    _loadCompagnies();
  }

  @override
  void dispose() {
    // Dispose des contrôleurs personnels
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _prenomController.dispose();
    _nomController.dispose();
    _telephoneController.dispose();
    _numeroAgentController.dispose();
    
    // Dispose des contrôleurs agence
    _agenceNomController.dispose();
    _agenceAdresseController.dispose();
    _agenceVilleController.dispose();
    _agenceGouvernoratController.dispose();
    _agenceTelephoneController.dispose();
    
    _pageController.dispose();
    super.dispose();
  }

  /// 🏢 Charger les compagnies depuis Firestore
  Future<void> _loadCompagnies() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('compagnies_assurance')
          .where('active', isEqualTo: true)
          .get();

      setState(() {
        _compagnies = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        _loadingCompagnies = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement compagnies: $e');
      setState(() => _loadingCompagnies = false);
    }
  }

  /// 📸 Sélectionner une image
  Future<void> _pickImage(String type) async {
    try {
      final ImagePicker picker = ImagePicker();
      
      final source = await _showImageSourceDialog();
      if (source == null) return;

      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          switch (type) {
            case 'cinRecto':
              _cinRecto = File(image.path);
              break;
            case 'cinVerso':
              _cinVerso = File(image.path);
              break;
            case 'justificatifTravail':
              _justificatifTravail = File(image.path);
              break;
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sélection de l\'image: $e');
    }
  }

  /// 📱 Dialog de sélection source image
  Future<ImageSource?> _showImageSourceDialog() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
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
  }

  /// ⚠️ Afficher message d'erreur
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// ✅ Afficher message de succès
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// 📝 Soumettre la demande d'inscription
  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_validateRequiredFields()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Créer la demande d'inscription
      final demandData = _buildRegistrationData();
      
      // Sauvegarder dans Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('professional_account_requests')
          .add(demandData);

      debugPrint('✅ Demande créée: ${docRef.id}');

      // Afficher dialog de confirmation
      _showSuccessDialog();

    } catch (e) {
      debugPrint('❌ Erreur inscription: $e');
      _showErrorSnackBar('Erreur lors de l\'inscription: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ✅ Valider les champs obligatoires
  bool _validateRequiredFields() {
    if (_selectedCompagnie == null ||
        _agenceNomController.text.trim().isEmpty ||
        _selectedGouvernorat == null ||
        _selectedPoste == null) {
      _showErrorSnackBar('Veuillez remplir tous les champs obligatoires');
      return false;
    }
    return true;
  }

  /// 📋 Construire les données d'inscription
  Map<String, dynamic> _buildRegistrationData() {
    return {
      'email': _emailController.text.trim(),
      'nom': _nomController.text.trim(),
      'prenom': _prenomController.text.trim(),
      'telephone': _telephoneController.text.trim(),
      'compagnieId': _selectedCompagnie!['id'],
      'compagnieNom': _selectedCompagnie!['nom'],
      'agenceNom': _agenceNomController.text.trim(),
      'agenceAdresse': _agenceAdresseController.text.trim(),
      'agenceVille': _agenceVilleController.text.trim(),
      'agenceGouvernorat': _selectedGouvernorat!,
      'agenceTelephone': _agenceTelephoneController.text.trim(),
      'poste': _selectedPoste!,
      'numeroAgent': _numeroAgentController.text.trim(),
      'status': 'pending',
      'submittedAt': DateTime.now().toIso8601String(),
      'password': _passwordController.text, // Stocké temporairement
    };
  }

  /// 🎉 Dialog de succès
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('📋 Demande Envoyée !'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pending_actions, color: Colors.orange, size: 64),
            const SizedBox(height: 16),
            Text(
              'Demande d\'inscription créée\n${_prenomController.text} ${_nomController.text}',
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${_selectedCompagnie?['nom'] ?? ''} - ${_agenceNomController.text}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Votre demande est en attente d\'approbation.\n'
              'Vous recevrez un email de confirmation.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AgentLoginScreen()),
              );
            },
            child: const Text('Aller à la Connexion'),
          ),
        ],
      ),
    );
  }

  // 🎨 INTERFACE UTILISATEUR

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription Agent'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Indicateur de progression
            _buildProgressIndicator(),

            // Contenu des pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildPersonalInfoPage(),
                  _buildProfessionalInfoPage(),
                  _buildDocumentsPage(),
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

  /// 📊 Indicateur de progression
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
                  color: i <= _currentPage ? Colors.blue : Colors.grey[300],
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

  /// 👤 Page 1 : Informations personnelles
  Widget _buildPersonalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '👤 Informations Personnelles',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Prénom
          TextFormField(
            controller: _prenomController,
            decoration: const InputDecoration(
              labelText: 'Prénom *',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (value) => value?.trim().isEmpty == true ? 'Prénom requis' : null,
          ),
          const SizedBox(height: 16),

          // Nom
          TextFormField(
            controller: _nomController,
            decoration: const InputDecoration(
              labelText: 'Nom *',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            validator: (value) => value?.trim().isEmpty == true ? 'Nom requis' : null,
          ),
          const SizedBox(height: 16),

          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email professionnel *',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value?.trim().isEmpty == true) return 'Email requis';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                return 'Email invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Téléphone
          TextFormField(
            controller: _telephoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Téléphone *',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            validator: (value) => value?.trim().isEmpty == true ? 'Téléphone requis' : null,
          ),
          const SizedBox(height: 16),

          // Mot de passe
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mot de passe *',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value?.trim().isEmpty == true) return 'Mot de passe requis';
              if (value!.length < 6) return 'Au moins 6 caractères';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirmation mot de passe
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirmer le mot de passe *',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Les mots de passe ne correspondent pas';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  /// 🏢 Page 2 : Informations professionnelles
  Widget _buildProfessionalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '🏢 Informations Professionnelles',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Compagnie d'assurance
          _loadingCompagnies
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedCompagnie,
                  decoration: const InputDecoration(
                    labelText: 'Compagnie d\'assurance *',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                  ),
                  items: _compagnies.map((compagnie) {
                    return DropdownMenuItem(
                      value: compagnie,
                      child: Text(compagnie['nom'] ?? 'Nom non disponible'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedCompagnie = value),
                  validator: (value) => value == null ? 'Compagnie requise' : null,
                ),
          const SizedBox(height: 16),

          // Nom de l'agence
          TextFormField(
            controller: _agenceNomController,
            decoration: const InputDecoration(
              labelText: 'Nom de l\'agence *',
              prefixIcon: Icon(Icons.store),
              border: OutlineInputBorder(),
            ),
            validator: (value) => value?.trim().isEmpty == true ? 'Nom d\'agence requis' : null,
          ),
          const SizedBox(height: 16),

          // Gouvernorat
          DropdownButtonFormField<String>(
            value: _selectedGouvernorat,
            decoration: const InputDecoration(
              labelText: 'Gouvernorat *',
              prefixIcon: Icon(Icons.location_on),
              border: OutlineInputBorder(),
            ),
            items: _gouvernorats.map((gov) {
              return DropdownMenuItem(value: gov, child: Text(gov));
            }).toList(),
            onChanged: (value) => setState(() => _selectedGouvernorat = value),
            validator: (value) => value == null ? 'Gouvernorat requis' : null,
          ),
          const SizedBox(height: 16),

          // Poste
          DropdownButtonFormField<String>(
            value: _selectedPoste,
            decoration: const InputDecoration(
              labelText: 'Poste *',
              prefixIcon: Icon(Icons.work),
              border: OutlineInputBorder(),
            ),
            items: _postes.map((poste) {
              return DropdownMenuItem(value: poste, child: Text(poste));
            }).toList(),
            onChanged: (value) => setState(() => _selectedPoste = value),
            validator: (value) => value == null ? 'Poste requis' : null,
          ),
          const SizedBox(height: 16),

          // Numéro d'agent
          TextFormField(
            controller: _numeroAgentController,
            decoration: const InputDecoration(
              labelText: 'Numéro d\'agent (optionnel)',
              prefixIcon: Icon(Icons.badge),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  /// 🆔 Page 3 : Documents
  Widget _buildDocumentsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '🆔 Documents d\'Identité',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'CIN obligatoire • Justificatif de travail recommandé',
            style: TextStyle(
              color: Colors.orange[600],
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // CIN recto
          _buildImagePicker(
            'CIN (Recto) *',
            _cinRecto,
            () => _pickImage('cinRecto'),
            Icons.credit_card,
          ),
          const SizedBox(height: 16),

          // CIN verso
          _buildImagePicker(
            'CIN (Verso) *',
            _cinVerso,
            () => _pickImage('cinVerso'),
            Icons.credit_card,
          ),
          const SizedBox(height: 16),

          // Justificatif de travail
          _buildImagePicker(
            'Justificatif de Travail (Optionnel)',
            _justificatifTravail,
            () => _pickImage('justificatifTravail'),
            Icons.work,
          ),
        ],
      ),
    );
  }

  /// 📸 Widget de sélection d'image
  Widget _buildImagePicker(String label, File? image, VoidCallback onTap, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (image != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    image,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                    ),
                  ],
                ),
              ] else ...[
                Icon(icon, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Appuyez pour ajouter', style: TextStyle(color: Colors.grey)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 🔘 Boutons de navigation
  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentPage > 0)
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
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : () {
                if (_currentPage < 2) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  _submitRegistration();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
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
                  : Text(_currentPage < 2 ? 'Suivant' : 'Soumettre'),
            ),
          ),
        ],
      ),
    );
  }
}
