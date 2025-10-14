import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_routes.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../services/conducteur_auth_service.dart';
import 'forgot_password_sms_screen.dart';

class ConducteurLoginScreen extends ConsumerStatefulWidget {
  const ConducteurLoginScreen({super.key});

  @override
  _ConducteurLoginScreenState createState() => _ConducteurLoginScreenState();
}

class _ConducteurLoginScreenState extends ConsumerState<ConducteurLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Connexion Conducteur'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'Connexion Conducteur',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Accédez à votre tableau de bord et gérez vos véhicules',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email *',
                  hintText: 'votre.email@exemple.com',
                ),
                validator: (value) {
                  if (value!.isEmpty) return 'Email requis';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Format d\'email invalide';
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Mot de passe *'),
                obscureText: true,
                validator: (value) {
                  if (value!.isEmpty) return 'Mot de passe requis';
                  return null;
                },
              ),
              
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitForm,
                      child: Text('Se connecter'),
                    ),
              
              if (_errorMessage.isNotEmpty) 
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _errorMessage, 
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Pas encore de compte ? '),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.conducteurRegister),
                    child: Text('S\'inscrire'),
                  ),
                ],
              ),
              
              SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ForgotPasswordSMSScreen(
                      userEmail: _emailController.text.trim(),
                    ),
                  ),
                ),
                child: Text('Mot de passe oublié ?'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final result = await ConducteurAuthService.loginConducteur(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (result['success'] == true) {
          // Connexion réussie
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Connexion réussie !'),
              duration: Duration(seconds: 2),
            ),
          );
          
          // Rediriger vers le tableau de bord conducteur
          Navigator.pushNamed(context, AppRoutes.conducteurDashboard);
        } else {
          setState(() {
            _errorMessage = result['error'] ?? 'Erreur lors de la connexion';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Erreur lors de la connexion: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
