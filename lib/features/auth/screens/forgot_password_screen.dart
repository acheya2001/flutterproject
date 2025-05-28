import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
      _isSuccess = false;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.sendPasswordResetEmail(_emailController.text.trim());

      setState(() {
        _isLoading = false;
        if (success) {
          _isSuccess = true;
          _message = 'Un email de réinitialisation a été envoyé à ${_emailController.text}';
        } else {
          _message = authProvider.error ?? 'Une erreur s\'est produite. Veuillez réessayer.';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Une erreur s\'est produite: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mot de passe oublié'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.lock_reset,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Réinitialisation du mot de passe',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Entrez votre adresse email pour recevoir un lien de réinitialisation de mot de passe.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Message
                if (_message != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isSuccess ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _message!,
                      style: TextStyle(
                        color: _isSuccess ? Colors.green : Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

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
                const SizedBox(height: 20),

                // Bouton de réinitialisation
                ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
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
                          'Réinitialiser le mot de passe',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
                const SizedBox(height: 20),

                // Retour à la connexion
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Retour à la connexion'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
