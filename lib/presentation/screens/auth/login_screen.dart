import 'package:flutter/material.dart';
import 'package:constat_tunisie/core/providers/auth_provider.dart';
import 'package:constat_tunisie/core/theme/app_theme.dart';
import 'package:constat_tunisie/core/enums/user_role.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

class LoginScreen extends StatefulWidget {
  final Function? toggleView;
  
  const LoginScreen({super.key, this.toggleView});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _logger = Logger();
  
  bool _isPasswordVisible = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _errorMessage = null;
      });
      
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        await authProvider.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        if (!mounted) return;
        
        // Rediriger vers l'écran approprié en fonction du rôle
        switch (authProvider.currentUser?.role) {
          case UserRole.driver:
            Navigator.of(context).pushReplacementNamed('/driver-home');
            break;
          case UserRole.insurance:
            Navigator.of(context).pushReplacementNamed('/insurance-home');
            break;
          case UserRole.expert:
            Navigator.of(context).pushReplacementNamed('/expert-home');
            break;
          default:
            Navigator.of(context).pushReplacementNamed('/driver-home');
        }
      } catch (e) {
        _logger.e('Erreur lors de la connexion: $e');
        if (!mounted) return;
        
        setState(() {
          _errorMessage = 'Erreur lors de la connexion: $e';
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
                  AppTheme.primaryColor.withOpacity(0.8),
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
                    SizedBox(height: size.height * 0.05),
                    Image.asset(
                      'assets/images/logo.png',
                      height: 100,
                      width: 100,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Connexion',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Bienvenue sur Constat Tunisie',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Carte principale
                    Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
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
                            
                            // Formulaire de connexion
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
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
                                      return null;
                                    },
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  
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
                                        return 'Veuillez entrer votre mot de passe';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  const SizedBox(height: 10),
                                  
                                  // Lien mot de passe oublié
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pushNamed('/forgot-password');
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppTheme.primaryColor,
                                      ),
                                      child: const Text(
                                        'Mot de passe oublié ?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 30),
                                  
                                  // Bouton de connexion
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: authProvider.isLoading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 3,
                                      ),
                                      child: authProvider.isLoading
                                          ? const CircularProgressIndicator(color: Colors.white)
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: const [
                                                Icon(Icons.login),
                                                SizedBox(width: 10),
                                                Text(
                                                  'Se connecter',
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
                    
                    const SizedBox(height: 30),
                    
                    // Lien vers l'inscription
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Pas encore de compte ? ',
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
                              Navigator.of(context).pushReplacementNamed('/register');
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                          ),
                          child: const Text(
                            'S\'inscrire',
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
            fontSize: 16,
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
              color: AppTheme.primaryColor,
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
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
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
}
