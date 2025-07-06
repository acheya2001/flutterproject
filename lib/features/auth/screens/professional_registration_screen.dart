import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';



import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../../../core/config/app_routes.dart';

/// 🏢 Écran d'inscription professionnelle amélioré
class ProfessionalRegistrationScreen extends ConsumerStatefulWidget {
  final String userType; // 'assureur' ou 'expert'

  const ProfessionalRegistrationScreen({
    Key? key,
    required this.userType,
  }) : super(key: key);

  @override
  ConsumerState<ProfessionalRegistrationScreen> createState() => _ProfessionalRegistrationScreenState();
}

class _ProfessionalRegistrationScreenState extends ConsumerState<ProfessionalRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Contrôleurs de base
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();

  // Contrôleurs spécifiques aux assureurs
  final _compagnieController = TextEditingController();
  final _matriculeController = TextEditingController();
  final _agencePrefereeController = TextEditingController();
  String? _selectedGouvernorat;

  // Contrôleurs spécifiques aux experts
  final _cabinetController = TextEditingController();
  final _agrementController = TextEditingController();
  final _specialitesController = TextEditingController();

  // Documents et motivation
  final _motivationController = TextEditingController();
  final List<File> _selectedDocuments = [];
  final ImagePicker _picker = ImagePicker();

  // Gouvernorats tunisiens
  final List<String> _gouvernorats = [
    'Tunis', 'Ariana', 'Ben Arous', 'Manouba', 'Nabeul', 'Zaghouan',
    'Bizerte', 'Béja', 'Jendouba', 'Kef', 'Siliana', 'Sousse',
    'Monastir', 'Mahdia', 'Sfax', 'Kairouan', 'Kasserine', 'Sidi Bouzid',
    'Gabès', 'Médenine', 'Tataouine', 'Gafsa', 'Tozeur', 'Kébili'
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _compagnieController.dispose();
    _matriculeController.dispose();
    _agencePrefereeController.dispose();
    _cabinetController.dispose();
    _agrementController.dispose();
    _specialitesController.dispose();
    _motivationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userType == 'assureur'
            ? 'Inscription Agent d\'Assurance'
            : 'Inscription Expert'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
                _buildPersonalInfoStep(),
                _buildProfessionalInfoStep(),
                _buildDocumentsStep(),
                _buildReviewStep(),
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
      padding: const EdgeInsets.all(20),
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
                      color: isActive ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isCompleted ? Colors.green : (isActive ? Colors.blue : Colors.grey[300]),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompleted ? Icons.check : Icons.circle,
                          size: 12,
                          color: isActive || isCompleted ? Colors.white : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _getStepTitle(index),
                          style: TextStyle(
                            fontSize: 10,
                            color: isActive ? Colors.blue : Colors.grey[600],
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  String _getStepTitle(int index) {
    switch (index) {
      case 0: return 'Infos personnelles';
      case 1: return 'Infos professionnelles';
      case 2: return 'Documents';
      case 3: return 'Vérification';
      default: return '';
    }
  }

  /// 👤 Étape 1: Informations personnelles
  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              '👤 Informations Personnelles',
              'Veuillez renseigner vos informations personnelles',
            ),
            
            const SizedBox(height: 24),
            
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
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir votre email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Format d\'email invalide';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Mot de passe
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe *',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir un mot de passe';
                }
                if (value.length < 6) {
                  return 'Le mot de passe doit contenir au moins 6 caractères';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Confirmation mot de passe
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmer le mot de passe *',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Les mots de passe ne correspondent pas';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Nom et Prénom
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nomController,
                    decoration: const InputDecoration(
                      labelText: 'Nom *',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requis';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _prenomController,
                    decoration: const InputDecoration(
                      labelText: 'Prénom *',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requis';
                      }
                      return null;
                    },
                  ),
                ),
              ],
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir votre numéro de téléphone';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Adresse
            TextFormField(
              controller: _adresseController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Adresse',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🏢 Étape 2: Informations professionnelles
  Widget _buildProfessionalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            widget.userType == 'assureur' ? '🏢 Informations Assurance' : '🔍 Informations Expert',
            widget.userType == 'assureur' 
                ? 'Renseignez vos informations d\'agent d\'assurance'
                : 'Renseignez vos informations d\'expert',
          ),
          
          const SizedBox(height: 24),
          
          if (widget.userType == 'assureur') ..._buildAssureurFields(),
          if (widget.userType == 'expert') ..._buildExpertFields(),
        ],
      ),
    );
  }

  /// 📄 Étape 3: Documents justificatifs
  Widget _buildDocumentsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            '📄 Documents Justificatifs',
            'Ajoutez les documents nécessaires pour valider votre demande',
          ),
          
          const SizedBox(height: 24),
          
          // Zone d'upload de documents
          _buildDocumentUploadZone(),
          
          const SizedBox(height: 24),
          
          // Liste des documents ajoutés
          if (_selectedDocuments.isNotEmpty) _buildDocumentsList(),
          
          const SizedBox(height: 24),
          
          // Lettre de motivation
          TextFormField(
            controller: _motivationController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Lettre de motivation (optionnel)',
              hintText: 'Expliquez pourquoi vous souhaitez rejoindre notre plateforme...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Étape 4: Vérification et soumission
  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            '✅ Vérification',
            'Vérifiez vos informations avant de soumettre votre demande',
          ),
          
          const SizedBox(height: 24),
          
          // Résumé des informations
          _buildInfoSummary(),
          
          const SizedBox(height: 24),
          
          // Avertissement
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              border: Border.all(color: Colors.orange[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Information importante',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Votre demande sera examinée par nos administrateurs. Vous recevrez une notification par email une fois votre compte validé.',
                  style: TextStyle(color: Colors.orange[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
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
    );
  }

  /// 🏢 Champs spécifiques aux assureurs
  List<Widget> _buildAssureurFields() {
    return [
      // Compagnie d'assurance
      TextFormField(
        controller: _compagnieController,
        decoration: const InputDecoration(
          labelText: 'Compagnie d\'assurance *',
          prefixIcon: Icon(Icons.business),
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez saisir votre compagnie';
          }
          return null;
        },
      ),

      const SizedBox(height: 16),

      // Matricule agent
      TextFormField(
        controller: _matriculeController,
        decoration: const InputDecoration(
          labelText: 'Matricule agent *',
          prefixIcon: Icon(Icons.badge),
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez saisir votre matricule';
          }
          return null;
        },
      ),

      const SizedBox(height: 16),

      // Gouvernorat
      DropdownButtonFormField<String>(
        value: _selectedGouvernorat,
        decoration: const InputDecoration(
          labelText: 'Gouvernorat *',
          prefixIcon: Icon(Icons.location_city),
          border: OutlineInputBorder(),
        ),
        items: _gouvernorats.map((gouvernorat) {
          return DropdownMenuItem(
            value: gouvernorat,
            child: Text(gouvernorat),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedGouvernorat = value;
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Veuillez sélectionner un gouvernorat';
          }
          return null;
        },
      ),

      const SizedBox(height: 16),

      // Agence préférée
      TextFormField(
        controller: _agencePrefereeController,
        decoration: const InputDecoration(
          labelText: 'Agence préférée',
          prefixIcon: Icon(Icons.store),
          border: OutlineInputBorder(),
          hintText: 'Ex: Agence Tunis Centre',
        ),
      ),
    ];
  }

  /// 🔍 Champs spécifiques aux experts
  List<Widget> _buildExpertFields() {
    return [
      // Cabinet d'expertise
      TextFormField(
        controller: _cabinetController,
        decoration: const InputDecoration(
          labelText: 'Cabinet d\'expertise *',
          prefixIcon: Icon(Icons.business_center),
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez saisir votre cabinet';
          }
          return null;
        },
      ),

      const SizedBox(height: 16),

      // Numéro d'agrément
      TextFormField(
        controller: _agrementController,
        decoration: const InputDecoration(
          labelText: 'Numéro d\'agrément *',
          prefixIcon: Icon(Icons.verified),
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez saisir votre numéro d\'agrément';
          }
          return null;
        },
      ),

      const SizedBox(height: 16),

      // Spécialités
      TextFormField(
        controller: _specialitesController,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Spécialités',
          prefixIcon: Icon(Icons.star),
          border: OutlineInputBorder(),
          hintText: 'Ex: Expertise automobile, Dommages corporels...',
        ),
      ),
    ];
  }

  /// 📄 Zone d'upload de documents
  Widget _buildDocumentUploadZone() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_upload, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'Ajoutez vos documents justificatifs',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'CIN, Diplômes, Certificats professionnels...',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickDocument(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Caméra'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _pickDocument(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galerie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📋 Liste des documents ajoutés
  Widget _buildDocumentsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documents ajoutés (${_selectedDocuments.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_selectedDocuments.length, (index) {
          final file = _selectedDocuments[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.description, color: Colors.blue[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    file.path.split('/').last,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeDocument(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// 📊 Résumé des informations
  Widget _buildInfoSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow('Email', _emailController.text),
            _buildSummaryRow('Nom complet', '${_prenomController.text} ${_nomController.text}'),
            _buildSummaryRow('Téléphone', _telephoneController.text),
            if (widget.userType == 'assureur') ...[
              _buildSummaryRow('Compagnie', _compagnieController.text),
              _buildSummaryRow('Matricule', _matriculeController.text),
              _buildSummaryRow('Gouvernorat', _selectedGouvernorat ?? ''),
            ],
            if (widget.userType == 'expert') ...[
              _buildSummaryRow('Cabinet', _cabinetController.text),
              _buildSummaryRow('Agrément', _agrementController.text),
            ],
            _buildSummaryRow('Documents', '${_selectedDocuments.length} fichier(s)'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value.isEmpty ? 'Non renseigné' : value),
          ),
        ],
      ),
    );
  }

  /// 🔄 Boutons de navigation
  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Précédent'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
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
                  : Text(_currentStep == 3 ? 'Soumettre la demande' : 'Suivant'),
            ),
          ),
        ],
      ),
    );
  }

  /// ⬅️ Étape précédente
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// ➡️ Étape suivante
  void _nextStep() {
    if (_currentStep < 3) {
      if (_validateCurrentStep()) {
        setState(() {
          _currentStep++;
        });
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _submitRequest();
    }
  }

  /// ✅ Valider l'étape actuelle
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _formKey.currentState?.validate() ?? false;
      case 1:
        if (widget.userType == 'assureur') {
          return _compagnieController.text.isNotEmpty &&
                 _matriculeController.text.isNotEmpty &&
                 _selectedGouvernorat != null;
        } else {
          return _cabinetController.text.isNotEmpty &&
                 _agrementController.text.isNotEmpty;
        }
      case 2:
        return true; // Documents optionnels
      case 3:
        return true; // Révision
      default:
        return false;
    }
  }

  /// 📄 Sélectionner un document
  Future<void> _pickDocument(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedDocuments.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection: $e')),
        );
      }
    }
  }

  /// 🗑️ Supprimer un document
  void _removeDocument(int index) {
    setState(() {
      _selectedDocuments.removeAt(index);
    });
  }

  /// 📤 Soumettre la demande
  Future<void> _submitRequest() async {
    print('🔍 DEBUG: Début de _submitRequest()');

    setState(() {
      _isLoading = true;
    });

    try {
      // Créer la demande de compte professionnel
      final currentUser = FirebaseAuth.instance.currentUser;
      print('🔍 DEBUG: Utilisateur actuel: ${currentUser?.uid ?? 'null'}');
      print('🔍 DEBUG: Email utilisateur: ${currentUser?.email ?? 'null'}');
      print('🔍 DEBUG: Utilisateur authentifié: ${currentUser != null}');

      // Si pas d'utilisateur, essayons de nous connecter anonymement
      if (currentUser == null) {
        print('🔍 DEBUG: Pas d\'utilisateur connecté, connexion anonyme...');
        try {
          final userCredential = await FirebaseAuth.instance.signInAnonymously();
          print('✅ DEBUG: Connexion anonyme réussie: ${userCredential.user?.uid}');
        } catch (e) {
          print('❌ DEBUG: Erreur connexion anonyme: $e');
        }
      }

      final request = ProfessionalAccountRequest(
        id: '', // Sera généré par Firestore
        userId: currentUser?.uid ?? 'temp_${DateTime.now().millisecondsSinceEpoch}', // ID temporaire si pas connecté
        email: _emailController.text.trim(),
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        telephone: _telephoneController.text.trim(),
        adresse: _adresseController.text.trim().isNotEmpty ? _adresseController.text.trim() : null,
        userType: widget.userType,
        compagnie: widget.userType == 'assureur' ? _compagnieController.text.trim() : null,
        matricule: widget.userType == 'assureur' ? _matriculeController.text.trim() : null,
        gouvernorat: _selectedGouvernorat,
        agencePreferee: _agencePrefereeController.text.trim().isNotEmpty ? _agencePrefereeController.text.trim() : null,
        cabinet: widget.userType == 'expert' ? _cabinetController.text.trim() : null,
        agrement: widget.userType == 'expert' ? _agrementController.text.trim() : null,
        specialites: widget.userType == 'expert' && _specialitesController.text.trim().isNotEmpty ? _specialitesController.text.trim() : null,
        motivationLetter: _motivationController.text.trim().isNotEmpty ? _motivationController.text.trim() : null,
        createdAt: DateTime.now(),
      );

      print('🔍 DEBUG: Objet request créé - Email: ${request.email}, UserType: ${request.userType}');

      // Soumettre la demande
      print('🔍 DEBUG: Appel de ProfessionalAccountService.createAccountRequest()');
      await ProfessionalAccountService.createAccountRequest(request);
      print('✅ DEBUG: createAccountRequest() terminé avec succès');

      if (mounted) {
        // Afficher le message de succès
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            title: const Text('Demande soumise !'),
            content: const Text(
              'Votre demande de compte professionnel a été soumise avec succès. '
              'Vous recevrez une notification par email une fois votre compte validé par nos administrateurs.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fermer le dialog
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.userTypeSelection,
                    (route) => false,
                  );
                },
                child: const Text('Retour au choix du type'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ DEBUG: Erreur dans _submitRequest(): $e');
      print('❌ DEBUG: Type d\'erreur: ${e.runtimeType}');
      if (e is Exception) {
        print('❌ DEBUG: Exception détails: ${e.toString()}');
      }

      if (mounted) {
        String errorMessage = 'Erreur lors de la soumission: $e';

        // Message spécifique pour email dupliqué
        if (e.toString().contains('email existe déjà') ||
            e.toString().contains('demande est en cours')) {
          errorMessage = '⚠️ Un compte avec cet email existe déjà ou une demande est en cours de traitement.\n\nVeuillez utiliser un autre email ou vérifier le statut de votre demande précédente.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
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
