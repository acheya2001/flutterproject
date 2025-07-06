import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_routes.dart';
import '../../../utils/user_type.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus(); // Hide keyboard

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authState = ref.read(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final UserModel? loggedInUser = await authNotifier.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (loggedInUser != null) {
      // AuthProvider's error state should be null on success.
      // Navigation logic based on user type
      debugPrint("[LoginScreen] Login successful. User type: ${loggedInUser.type}");
      switch (loggedInUser.type) {
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
      // Login failed. AuthProvider should have set its 'error' state.
      // The ref.listen in the build method will display the error.
      debugPrint("[LoginScreen] Login failed. Error should be in authState.error from AuthProvider.");
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
    // Clear password field focus to avoid keyboard issues after filling
    FocusScope.of(context).unfocus();
  }

  Widget _buildTestButton(String userType, Color color) {
    return ElevatedButton(
      onPressed: () => _fillTestCredentials(userType),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        userType.substring(0, 1).toUpperCase() + userType.substring(1),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch AuthProvider state for isLoading and error
    final authState = ref.watch(authProvider);

    // Listen for error changes in AuthProvider to show a SnackBar
    ref.listen(authProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.redAccent,
          ),
        );
        // Optionally clear the error in the provider after showing it
        // ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
        elevation: 0, // Flat app bar
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
                  Icons.car_crash_outlined, // Using outlined version
                  size: 80,
                  color: Colors.blueAccent, // Adjusted color
                ),
                const SizedBox(height: 16),
                const Text(
                  'Constat Tunisie',
                  style: TextStyle(
                    fontSize: 28, // Slightly larger
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Error message display (now driven by AuthProvider's error state via SnackBar)
                // If you still want an inline error message, you can use authState.error here:
                // if (authState.error != null && !authState.isLoading) ...[
                //   // Your error display widget
                // ],

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
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

                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(
                       borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
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

                ElevatedButton(
                  onPressed: authState.isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(fontSize: 16, color: Colors.white)
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Se connecter',
                           style: TextStyle(color: Colors.white),
                        ),
                ),
                const SizedBox(height: 20),

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
                const SizedBox(height: 20),

                // Bouton pour demande de compte professionnel
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.professionalRequest);
                    },
                    icon: const Icon(Icons.business_center),
                    label: const Text('Demande de compte professionnel'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.blueAccent),
                      foregroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                const SizedBox(height: 30),

                const Text(
                  'Comptes de test',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTestButton('conducteur', Colors.blue.shade700),
                    _buildTestButton('assureur', Colors.green.shade700),
                    _buildTestButton('expert', Colors.orange.shade700),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}