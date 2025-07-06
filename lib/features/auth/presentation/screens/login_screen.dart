import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/config/app_router.dart';
import '../../../../core/enums/app_enums.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_button.dart';

/// 🔐 Écran de connexion moderne
class LoginScreen extends ConsumerStatefulWidget {
  final String? userType;

  const LoginScreen({
    Key? key,
    this.userType,
  }) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Écouter les changements d'état d'authentification
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null) {
        _showErrorSnackBar(next.error!);
      } else if (next.isAuthenticated && next.currentUser != null) {
        _navigateToUserDashboard(next.currentUser!.role);
      } else if (next.message != null) {
        _showSuccessSnackBar(next.message!);
      }
    });

    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor,
              Color(0xFF1565C0),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // En-tête
              _buildHeader(context),
              
              // Formulaire de connexion
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 32),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titre de connexion
                          _buildLoginTitle(context),
                          
                          const SizedBox(height: 32),
                          
                          // Champs de saisie
                          _buildEmailField(),
                          const SizedBox(height: 16),
                          _buildPasswordField(),
                          
                          const SizedBox(height: 16),
                          
                          // Options
                          _buildOptions(context),
                          
                          const SizedBox(height: 32),
                          
                          // Bouton de connexion
                          _buildLoginButton(authState),
                          
                          const SizedBox(height: 24),
                          
                          // Liens d'inscription
                          _buildSignupLinks(context),
                          
                          const SizedBox(height: 32),
                          
                          // Footer
                          _buildFooter(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📱 En-tête avec retour et titre
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connexion',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.userType != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _getUserTypeDisplayName(widget.userType!),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Titre de connexion
  Widget _buildLoginTitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bon retour !',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connectez-vous à votre compte pour continuer',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 📧 Champ email
  Widget _buildEmailField() {
    return CustomTextField(
      controller: _emailController,
      label: 'Adresse email',
      hint: 'Entrez votre adresse email',
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer votre email';
        }
        if (!RegExp(ValidationConstants.emailRegex).hasMatch(value)) {
          return 'Veuillez entrer un email valide';
        }
        return null;
      },
    );
  }

  /// 🔒 Champ mot de passe
  Widget _buildPasswordField() {
    return CustomTextField(
      controller: _passwordController,
      label: 'Mot de passe',
      hint: 'Entrez votre mot de passe',
      prefixIcon: Icons.lock_outlined,
      obscureText: _obscurePassword,
      suffixIcon: IconButton(
        onPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
        icon: Icon(
          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer votre mot de passe';
        }
        if (value.length < ValidationConstants.minPasswordLength) {
          return 'Le mot de passe doit contenir au moins ${ValidationConstants.minPasswordLength} caractères';
        }
        return null;
      },
    );
  }

  /// ⚙️ Options (Se souvenir de moi, Mot de passe oublié)
  Widget _buildOptions(BuildContext context) {
    return Row(
      children: [
        // Se souvenir de moi
        Expanded(
          child: CheckboxListTile(
            value: _rememberMe,
            onChanged: (value) {
              setState(() {
                _rememberMe = value ?? false;
              });
            },
            title: Text(
              'Se souvenir de moi',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
        
        // Mot de passe oublié
        TextButton(
          onPressed: () => _showForgotPasswordDialog(context),
          child: const Text('Mot de passe oublié ?'),
        ),
      ],
    );
  }

  /// 🔐 Bouton de connexion
  Widget _buildLoginButton(AuthState authState) {
    return SizedBox(
      width: double.infinity,
      child: LoadingButton(
        onPressed: authState.isLoading ? null : _handleLogin,
        isLoading: authState.isLoading,
        child: const Text(
          'Se connecter',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// 📝 Liens d'inscription
  Widget _buildSignupLinks(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        
        Text(
          'Pas encore de compte ?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        
        const SizedBox(height: 16),
        
        if (widget.userType == 'driver') ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Implémenter l'inscription conducteur
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Inscription conducteur - En cours de développement')),
                );
              },
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Créer un compte conducteur'),
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Implémenter l'inscription professionnelle
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Inscription professionnelle - En cours de développement')),
                );
              },
              icon: const Icon(Icons.business_center_outlined),
              label: const Text('Demander un compte professionnel'),
            ),
          ),
        ],
      ],
    );
  }

  /// 🦶 Footer
  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Text(
          'En vous connectant, vous acceptez nos conditions d\'utilisation',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textHint,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 🔐 Gestion de la connexion
  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authProvider.notifier).signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }

  /// 🔄 Dialog mot de passe oublié
  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mot de passe oublié'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Entrez votre adresse email pour recevoir un lien de réinitialisation.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Adresse email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.isNotEmpty) {
                ref.read(authProvider.notifier).resetPassword(emailController.text.trim());
                Navigator.of(context).pop();
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  /// 🧭 Navigation vers le dashboard approprié
  void _navigateToUserDashboard(UserRole role) {
    String route = AppRouter.getDashboardRoute(role);

    if (route == AppRouter.driverDashboard) {
      Navigator.pushReplacementNamed(context, route);
    } else {
      // Pour les autres rôles, afficher un message temporaire
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dashboard ${role.displayName} - En cours de développement'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
  }

  /// 📛 Affichage des erreurs
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// ✅ Affichage des succès
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.accentColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 🏷️ Nom d'affichage du type d'utilisateur
  String _getUserTypeDisplayName(String userType) {
    switch (userType) {
      case 'driver':
        return 'Espace Conducteur';
      case 'agent':
        return 'Espace Agent';
      case 'expert':
        return 'Espace Expert';
      case 'admin':
        return 'Espace Administrateur';
      default:
        return 'Connexion';
    }
  }
}
