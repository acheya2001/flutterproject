import 'package:flutter/material.dart';
import 'package:constat_tunisie/data/enums/user_role.dart';
import 'package:constat_tunisie/core/providers/auth_provider.dart';
import 'package:constat_tunisie/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

class RegisterScreen extends StatefulWidget {
  final Function? toggleView;
  
  const RegisterScreen({super.key, this.toggleView});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _logger = Logger();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  UserRole _selectedRole = UserRole.driver;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _errorMessage;
  
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedRole = UserRole.driver;
            break;
          case 1:
            _selectedRole = UserRole.insurance;
            break;
          case 2:
            _selectedRole = UserRole.expert;
            break;
        }
      });
    });
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  Map<String, dynamic> _buildProfileData() {
    // Données de base communes à tous les rôles
    final Map<String, dynamic> profileData = {
      'createdAt': DateTime.now().toIso8601String(),
      'lastUpdated': DateTime.now().toIso8601String(),
    };
    
    // Ajouter des données spécifiques au rôle
    switch (_selectedRole) {
      case UserRole.driver:
        profileData['vehicleInfo'] = {};
        profileData['licenseInfo'] = {};
        break;
      case UserRole.insurance:
        profileData['companyName'] = '';
        profileData['registrationNumber'] = '';
        break;
      case UserRole.expert:
        profileData['specialization'] = '';
        profileData['certifications'] = [];
        break;
      case UserRole.admin:
        profileData['adminLevel'] = 'standard';
        break;
    }
    
    return profileData;
  }
  
  Future<void> _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _errorMessage = null;
      });
      
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        await authProvider.registerWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
          role: _selectedRole,
          phoneNumber: _phoneController.text.trim(),
          profileData: _buildProfileData(), // Ajout de l'argument manquant
        );
        
        if (!mounted) return;
        
        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inscription réussie! Veuillez vérifier votre email.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Rediriger vers l'écran approprié en fonction du rôle
        switch (_selectedRole) {
          case UserRole.driver:
            Navigator.of(context).pushReplacementNamed('/driver-home');
            break;
          case UserRole.insurance:
            Navigator.of(context).pushReplacementNamed('/insurance-home');
            break;
          case UserRole.expert:
            Navigator.of(context).pushReplacementNamed('/expert-home');
            break;
          case UserRole.admin:
            Navigator.of(context).pushReplacementNamed('/admin-home');
            break;
        }
      } catch (e) {
        _logger.e('Erreur lors de l\'inscription: $e');
        if (!mounted) return;
        
        setState(() {
          _errorMessage = 'Erreur lors de l\'inscription: $e';
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Stack(
        children: [
          // Fond avec dégradé
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _getRoleColor(_selectedRole).withAlpha(204), // 0.8 * 255 = 204
                  Colors.white,
                ],
                stops: const [0.0, 0.4],
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // En-tête avec logo et titre
                    SizedBox(height: size.height * 0.02),
                    Image.asset(
                      'assets/images/logo.png',
                      height: 80,
                      width: 80,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Créer un compte',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                            color: Colors.black.withAlpha(77), // 0.3 * 255 = 77
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rejoignez Constat Tunisie dès maintenant',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.black.withAlpha(77), // 0.3 * 255 = 77
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Carte principale
                    Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            // Sélecteur de rôle avec TabBar
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: TabBar(
                                controller: _tabController,
                                indicator: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                  color: _getRoleColor(_selectedRole),
                                ),
                                labelColor: Colors.white,
                                unselectedLabelColor: Colors.grey[700],
                                tabs: const [
                                  Tab(
                                    icon: Icon(Icons.drive_eta),
                                    text: 'Conducteur',
                                  ),
                                  Tab(
                                    icon: Icon(Icons.security),
                                    text: 'Assurance',
                                  ),
                                  Tab(
                                    icon: Icon(Icons.engineering),
                                    text: 'Expert',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),
                            
                            // Message d'erreur
                            if (_errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.red[700]),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(color: Colors.red[700]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            // Formulaire d'inscription
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Nom complet
                                  _buildTextField(
                                    controller: _nameController,
                                    label: 'Nom complet',
                                    hint: 'Entrez votre nom complet',
                                    icon: Icons.person,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer votre nom';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Email
                                  _buildTextField(
                                    controller: _emailController,
                                    label: 'Email',
                                    hint: 'Entrez votre adresse email',
                                    icon: Icons.email,
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
                                  
                                  // Téléphone
                                  _buildTextField(
                                    controller: _phoneController,
                                    label: 'Téléphone',
                                    hint: 'Entrez votre numéro de téléphone',
                                    icon: Icons.phone,
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer votre numéro de téléphone';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Mot de passe
                                  _buildTextField(
                                    controller: _passwordController,
                                    label: 'Mot de passe',
                                    hint: 'Entrez votre mot de passe',
                                    icon: Icons.lock,
                                    isPassword: true,
                                    isPasswordVisible: _isPasswordVisible,
                                    onTogglePasswordVisibility: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
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
                                  
                                  // Confirmer le mot de passe
                                  _buildTextField(
                                    controller: _confirmPasswordController,
                                    label: 'Confirmer le mot de passe',
                                    hint: 'Confirmez votre mot de passe',
                                    icon: Icons.lock_outline,
                                    isPassword: true,
                                    isPasswordVisible: _isConfirmPasswordVisible,
                                    onTogglePasswordVisibility: () {
                                      setState(() {
                                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                      });
                                    },
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
                                  
                                  const SizedBox(height: 30),
                                  
                                  // Bouton d'inscription
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: authProvider.isLoading ? null : _register,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _getRoleColor(_selectedRole),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 3,
                                      ),
                                      child: authProvider.isLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: const [
                                                Icon(Icons.app_registration),
                                                SizedBox(width: 10),
                                                Text(
                                                  'S\'inscrire',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Lien vers la connexion
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Déjà un compte ? ',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            if (widget.toggleView != null) {
                              widget.toggleView!();
                            } else {
                              Navigator.of(context).pushReplacementNamed('/login');
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: _getRoleColor(_selectedRole),
                          ),
                          child: const Text(
                            'Se connecter',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePasswordVisibility,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !isPasswordVisible,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: _getRoleColor(_selectedRole),
              size: 22,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: onTogglePasswordVisibility,
                  )
                : null,
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
              borderSide: BorderSide(color: _getRoleColor(_selectedRole), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[400]!, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[400]!, width: 2),
            ),
          ),
        ),
      ],
    );
  }
  
  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.driver:
        return AppTheme.driverColor;
      case UserRole.insurance:
        return AppTheme.insuranceColor;
      case UserRole.expert:
        return AppTheme.expertColor;
      case UserRole.admin:
        return Colors.purple; // Ou AppTheme.adminColor si disponible
    }
  }
}