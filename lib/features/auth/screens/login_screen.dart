import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_routes.dart';
import '../../../utils/user_type.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Utiliser le AuthProvider pour la connexion
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (success != null) {
        // Rediriger vers la page appropriée
        switch (success.type) {
          case UserType.conducteur:
            Navigator.pushReplacementNamed(context, AppRoutes.conducteurHome);
            break;
          case UserType.assureur:
            Navigator.pushReplacementNamed(context, AppRoutes.assureurHome);
            break;
          case UserType.expert:
            Navigator.pushReplacementNamed(context, AppRoutes.expertHome);
            break;
        }
      } else {
        setState(() {
          _errorMessage = authProvider.error ?? "Erreur de connexion";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Une erreur s'est produite: $e";
        });
      }
    }
  }

  void _fillTestCredentials(String userType) {
    switch (userType) {
      case 'conducteur':
        _emailController.text = 'conducteur@test.com';
        _passwordController.text = 'password123';
        break;
      case 'assureur':
        _emailController.text = 'assureur@test.com';
        _passwordController.text = 'password123';
        break;
      case 'expert':
        _emailController.text = 'expert@test.com';
        _passwordController.text = 'password123';
        break;
    }
  }

  // Conservé pour une utilisation future potentielle
  // Convertit une chaîne de caractères en UserType
  UserType _stringToUserType(String type) {
    switch (type) {
      case 'conducteur':
        return UserType.conducteur;
      case 'assureur':
        return UserType.assureur;
      case 'expert':
        return UserType.expert;
      default:
        return UserType.conducteur;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
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
                // Logo
                const Icon(
                  Icons.car_crash,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Constat Tunisie',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

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
                      return 'Veuillez entrer votre mot de passe';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Mot de passe oublié
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.forgotPassword);
                    },
                    child: const Text('Mot de passe oublié?'),
                  ),
                ),
                const SizedBox(height: 20),

                // Bouton de connexion
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
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
                          'Se connecter',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
                const SizedBox(height: 20),

                // Lien d'inscription
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Vous n'avez pas de compte?"),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.register);
                      },
                      child: const Text('S\'inscrire'),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Comptes de test
                const Text(
                  'Comptes de test',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTestButton('conducteur', Colors.blue),
                    _buildTestButton('assureur', Colors.green),
                    _buildTestButton('expert', Colors.orange),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestButton(String userType, Color color) {
    return ElevatedButton(
      onPressed: () => _fillTestCredentials(userType),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      child: Text(
        userType.capitalize(),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
