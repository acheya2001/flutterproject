import 'package:flutter/material.dart';
import 'package:constat_tunisie/core/providers/auth_provider.dart';
import 'package:constat_tunisie/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key}); // Utilisation de super.key

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _logger = Logger();
  
  bool _isEmailSent = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
  
  Future<void> _resetPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        await authProvider.resetPassword(_emailController.text.trim());
        
        if (mounted) {
          setState(() {
            _isEmailSent = true;
          });
        }
      } catch (e) {
        _logger.e('Erreur lors de la réinitialisation du mot de passe: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mot de passe oublié'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _isEmailSent ? _buildSuccessView() : _buildResetForm(authProvider),
      ),
    );
  }
  
  Widget _buildResetForm(AuthProvider authProvider) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          
          // Icône
          Icon(
            Icons.lock_reset,
            size: 80,
            color: AppTheme.primaryColor,
          ),
          
          const SizedBox(height: 20),
          
          // Titre
          const Text(
            'Réinitialisation du mot de passe',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            'Entrez votre adresse email pour recevoir un lien de réinitialisation de mot de passe.',
            style: TextStyle(
              color: Colors.grey.withAlpha(230), // Remplacé withOpacity par withAlpha
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 30),
          
          // Champ email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Entrez votre adresse email',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre adresse email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Veuillez entrer une adresse email valide';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),
          
          // Bouton de réinitialisation
          ElevatedButton(
            onPressed: authProvider.isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: authProvider.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Envoyer le lien',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          
          const SizedBox(height: 16),
          
          // Lien de retour
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Retour à la connexion',
              style: TextStyle(
                color: AppTheme.greyColor, // Utilisation de la couleur ajoutée
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        
        // Icône de succès
        Icon(
          Icons.check_circle,
          size: 100,
          color: AppTheme.successColor,
        ),
        
        const SizedBox(height: 30),
        
        // Titre
        const Text(
          'Email envoyé !',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 16),
        
        // Description
        Text(
          'Un lien de réinitialisation a été envoyé à ${_emailController.text}. Veuillez vérifier votre boîte de réception et suivre les instructions.',
          style: TextStyle(
            color: Colors.grey.withAlpha(230), // Remplacé withOpacity par withAlpha
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 30),
        
        // Instructions supplémentaires
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha(30), // Remplacé withOpacity par withAlpha
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.blue.withAlpha(100), // Remplacé withOpacity par withAlpha
            ),
          ),
          child: Column(
            children: const [
              Text(
                'Conseils:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '• Vérifiez également votre dossier spam\n'
                '• Le lien est valide pendant 1 heure\n'
                '• Si vous ne recevez pas l\'email, vous pouvez réessayer',
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Bouton de retour
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Retour à la connexion',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
