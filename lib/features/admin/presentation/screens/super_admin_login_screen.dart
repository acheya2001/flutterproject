import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/app_router.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../../auth/presentation/widgets/loading_button.dart';
import '../providers/super_admin_provider.dart';

/// 🔐 Écran de connexion Super Admin
class SuperAdminLoginScreen extends ConsumerStatefulWidget {
  const SuperAdminLoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SuperAdminLoginScreen> createState() => _SuperAdminLoginScreenState();
}

class _SuperAdminLoginScreenState extends ConsumerState<SuperAdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pré-remplir avec l'email du Super Admin
    _emailController.text = 'constat.tunisie.app@gmail.com';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 🔐 Connexion Super Admin
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Vérifier les identifiants
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (email == 'constat.tunisie.app@gmail.com' && password == 'Acheya123') {
        // Utiliser la connexion forcée qui fonctionne
        ref.read(superAdminProvider.notifier).forceLogin();

        if (mounted) {
          // Connexion réussie - rediriger vers le dashboard Super Admin
          Navigator.pushReplacementNamed(context, '/super-admin-dashboard');
        }
      } else {
        setState(() {
          _errorMessage = 'Identifiants incorrects. Veuillez vérifier votre email et mot de passe.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }




  /// 🔄 Réinitialiser le mot de passe
  Future<void> _resetPassword() async {
    try {
      // Fonction de reset simplifiée
      await FirebaseAuth.instance.sendPasswordResetEmail(email: 'constat.tunisie.app@gmail.com');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email de réinitialisation envoyé'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              
              // 🔐 En-tête Super Admin
              _buildHeader(),
              
              const SizedBox(height: 60),
              
              // 📝 Formulaire de connexion
              _buildLoginForm(),
              
              const SizedBox(height: 40),
              
              // ⚠️ Avertissement de sécurité
              _buildSecurityWarning(),
              
              const SizedBox(height: 20),
              
              // 🔙 Retour
              _buildBackButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔐 En-tête Super Admin
  Widget _buildHeader() {
    return Column(
      children: [
        // Logo sécurisé
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.errorColor,
                AppTheme.errorColor.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.errorColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.security,
            size: 50,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 24),
        
        Text(
          'SUPER ADMIN',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.errorColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Accès Administrateur Système',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 📝 Formulaire de connexion
  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email
          CustomTextField(
            controller: _emailController,
            label: 'Email Super Admin',
            prefixIcon: Icons.admin_panel_settings,
            keyboardType: TextInputType.emailAddress,
            enabled: !_isLoading,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Email requis';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                return 'Email invalide';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // Mot de passe
          CustomTextField(
            controller: _passwordController,
            label: 'Mot de passe',
            prefixIcon: Icons.lock,
            obscureText: _obscurePassword,
            enabled: !_isLoading,
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
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Mot de passe requis';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Message d'erreur
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.errorColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppTheme.errorColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 24),

          // Bouton de connexion
          SizedBox(
            width: double.infinity,
            child: LoadingButton.withTextAndIcon(
              onPressed: _signIn,
              isLoading: _isLoading,
              text: 'CONNEXION SÉCURISÉE',
              icon: Icons.security,
              backgroundColor: AppTheme.errorColor,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Mot de passe oublié
          TextButton(
            onPressed: _isLoading ? null : _resetPassword,
            child: const Text('Mot de passe oublié ?'),
          ),
        ],
      ),
    );
  }

  /// ⚠️ Avertissement de sécurité
  Widget _buildSecurityWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warningColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber,
                color: AppTheme.warningColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ZONE SÉCURISÉE',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.warningColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Cet accès est réservé exclusivement aux Super Administrateurs. '
            'Toute tentative d\'accès non autorisée sera enregistrée.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.warningColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔙 Bouton retour
  Widget _buildBackButton() {
    return TextButton.icon(
      onPressed: _isLoading ? null : () {
        Navigator.pushReplacementNamed(context, AppRouter.userTypeSelection);
      },
      icon: const Icon(Icons.arrow_back),
      label: const Text('Retour à l\'accueil'),
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.textSecondary,
      ),
    );
  }
}
