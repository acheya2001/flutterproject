import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_routes.dart';
import '../../../utils/user_type.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _cinController = TextEditingController();
  final _compagnieController = TextEditingController();
  final _matriculeController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  
  UserType _selectedUserType = UserType.conducteur;

  // Nouveaux contrôleurs pour les champs hiérarchiques
  final _adresseController = TextEditingController();
  String? _selectedCompagnie;
  String? _selectedAgence;
  String? _selectedGouvernorat;
  String? _selectedPoste;

  // Listes pour les dropdowns
  List<Map<String, dynamic>> _compagnies = [];
  List<Map<String, dynamic>> _agences = [];
  List<String> _gouvernorats = [
    'Tunis', 'Ariana', 'Ben Arous', 'Manouba', 'Nabeul', 'Zaghouan',
    'Bizerte', 'Béja', 'Jendouba', 'Kef', 'Siliana', 'Sousse',
    'Monastir', 'Mahdia', 'Sfax', 'Kairouan', 'Kasserine', 'Sidi Bouzid',
    'Gabès', 'Médenine', 'Tataouine', 'Gafsa', 'Tozeur', 'Kébili'
  ];
  List<String> _postes = [
    'Agent Commercial',
    'Conseiller Clientèle',
    'Responsable Agence',
    'Superviseur',
    'Chargé de Sinistres'
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _cinController.dispose();
    _compagnieController.dispose();
    _matriculeController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      setState(() {
        _errorMessage = "Veuillez accepter les conditions d'utilisation";
      });
      return;
    }

    // Vérifier que seuls les conducteurs peuvent s'inscrire
    if (_selectedUserType != UserType.conducteur) {
      setState(() {
        _errorMessage = "Seuls les conducteurs peuvent s'inscrire directement. Les professionnels doivent contacter leur responsable.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Ajout de logs de débogage
      debugPrint('=== DÉBUT INSCRIPTION ===');
      debugPrint('Email: ${_emailController.text.trim()}');
      debugPrint('Nom: ${_nomController.text.trim()}');
      debugPrint('Prénom: ${_prenomController.text.trim()}');
      debugPrint('Type: $_selectedUserType');
      
      // Utiliser le AuthProvider pour l'inscription
      final authProviderInstance = ref.read(authProvider);
      final user = await authProviderInstance.registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        telephone: _telephoneController.text.trim(),
        userType: _selectedUserType,
        cin: _selectedUserType == UserType.conducteur ? _cinController.text.trim() : null,
        compagnie: _selectedUserType == UserType.assureur ? _compagnieController.text.trim() : null,
        matricule: _selectedUserType == UserType.assureur ? _matriculeController.text.trim() : null,
        cabinet: _selectedUserType == UserType.expert ? _compagnieController.text.trim() : null,
        agrement: _selectedUserType == UserType.expert ? _matriculeController.text.trim() : null,
      );

      if (!mounted) return;

      if (user != null) {
        debugPrint('Inscription terminée avec succès');
        debugPrint('Redirection vers la page d\'accueil...');

        // Rediriger vers la page appropriée
        switch (_selectedUserType) {
          case UserType.conducteur:
            Navigator.pushReplacementNamed(context, AppRoutes.conducteurHome);
            break;
          case UserType.assureur:
            Navigator.pushReplacementNamed(context, AppRoutes.assureurHome);
            break;
          case UserType.expert:
            Navigator.pushReplacementNamed(context, AppRoutes.expertHome);
            break;
          case UserType.admin:
            Navigator.pushReplacementNamed(context, AppRoutes.adminHome);
            break;
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = authProviderInstance.error ?? "Erreur lors de l'inscription";
        });
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('ERREUR FirebaseAuthException: ${e.code} - ${e.message}');
      setState(() {
        _isLoading = false;
        switch (e.code) {
          case 'email-already-in-use':
            _errorMessage = "Cet email est déjà utilisé par un autre compte";
            break;
          case 'invalid-email':
            _errorMessage = "Format d'email invalide";
            break;
          case 'weak-password':
            _errorMessage = "Le mot de passe est trop faible";
            break;
          default:
            _errorMessage = "Erreur d'inscription: ${e.message}";
        }
      });
    } catch (e) {
      debugPrint('ERREUR générale: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Une erreur s'est produite: $e";
        });
      }
    } finally {
      debugPrint('=== FIN INSCRIPTION ===');
    }
  }

  void _fillTestData() {
    setState(() {
      _emailController.text = 'test${DateTime.now().millisecondsSinceEpoch}@example.com';
      _passwordController.text = 'password123';
      _confirmPasswordController.text = 'password123';
      _nomController.text = 'Nom Test';
      _prenomController.text = 'Prénom Test';
      _telephoneController.text = '12345678';
      
      if (_selectedUserType == UserType.conducteur) {
        _cinController.text = '12345678';
      } else {
        _compagnieController.text = _selectedUserType == UserType.assureur 
            ? 'Assurance Test' 
            : 'Cabinet Test';
        _matriculeController.text = _selectedUserType == UserType.assureur 
            ? 'MAT123456' 
            : 'EXP123456';
      }
      
      _acceptTerms = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high),
            tooltip: 'Remplir avec des données de test',
            onPressed: _fillTestData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Message d'erreur
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Type d'utilisateur
              const Text(
                'Type de compte',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              
              // Sélection du type d'utilisateur
              Column(
                children: [
                  // Option Conducteur
                  _buildUserTypeOption(UserType.conducteur, 'Conducteur', Icons.drive_eta),

                  const SizedBox(height: 15),

                  // Lien vers inscription professionnelle
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.business_center,
                          size: 32,
                          color: Colors.blue[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vous êtes un professionnel ?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Agent d\'assurance ou Expert',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/professional-info');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text('En savoir plus'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Informations de connexion
              const Text(
                'Informations de connexion',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              
              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Veuillez entrer un email valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Mot de passe
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un mot de passe';
                  }
                  if (value.length < 6) {
                    return 'Le mot de passe doit contenir au moins 6 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Confirmer mot de passe
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                obscureText: _obscureConfirmPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez confirmer votre mot de passe';
                  }
                  if (value != _passwordController.text) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Informations personnelles
              const Text(
                'Informations personnelles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              
              // Nom et prénom
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Obligatoire';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _prenomController,
                      decoration: const InputDecoration(
                        labelText: 'Prénom',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Obligatoire';
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
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre numéro de téléphone';
                  }
                  if (!RegExp(r'^[0-9]{8}$').hasMatch(value)) {
                    return 'Format invalide (8 chiffres)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Champs spécifiques au type d'utilisateur
              Text(
                _selectedUserType == UserType.conducteur
                    ? 'Informations du conducteur'
                    : _selectedUserType == UserType.assureur
                        ? 'Informations de l\'assureur'
                        : 'Informations de l\'expert',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              
              if (_selectedUserType == UserType.conducteur) ...[
                // CIN
                TextFormField(
                  controller: _cinController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de CIN',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre numéro de CIN';
                    }
                    if (!RegExp(r'^[0-9]{8}$').hasMatch(value)) {
                      return 'Format invalide (8 chiffres)';
                    }
                    return null;
                  },
                ),
              ],
              
              if (_selectedUserType != UserType.conducteur) ...[
                // Compagnie
                TextFormField(
                  controller: _compagnieController,
                  decoration: InputDecoration(
                    labelText: _selectedUserType == UserType.assureur
                        ? 'Compagnie d\'assurance'
                        : 'Cabinet d\'expertise',
                    prefixIcon: const Icon(Icons.business),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ce champ est obligatoire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Matricule
                TextFormField(
                  controller: _matriculeController,
                  decoration: InputDecoration(
                    labelText: _selectedUserType == UserType.assureur
                        ? 'Matricule'
                        : 'Numéro d\'agrément',
                    prefixIcon: const Icon(Icons.numbers),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ce champ est obligatoire';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 20),

              // Conditions d'utilisation
              Row(
                children: [
                  Checkbox(
                    value: _acceptTerms,
                    onChanged: (value) {
                      setState(() {
                        _acceptTerms = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _acceptTerms = !_acceptTerms;
                        });
                      },
                      child: const Text(
                        'J\'accepte les conditions d\'utilisation et la politique de confidentialité',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Bouton d'inscription
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'S\'inscrire',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 20),

              // Lien de connexion
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Vous avez déjà un compte?"),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Se connecter'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeOption(UserType type, String label, IconData icon) {
    final isSelected = _selectedUserType == type;
    final color = isSelected ? Theme.of(context).primaryColor : Colors.grey;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedUserType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
