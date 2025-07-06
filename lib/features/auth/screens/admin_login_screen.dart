import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔐 Écran de connexion admin spécialisé
class AdminLoginScreen extends StatefulWidget {
  final String adminType;

  const AdminLoginScreen({
    super.key,
    required this.adminType,
  });

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: _getColor(),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_getColor(), _getColor().withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    _getIcon(),
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getTitle(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getSubtitle(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Formulaire de connexion
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Email
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email administrateur',
                        hintText: _getEmailHint(),
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isLoading,
                    ),

                    const SizedBox(height: 20),

                    // Mot de passe
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      enabled: !_isLoading,
                    ),

                    const SizedBox(height: 24),

                    // Bouton de connexion
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _login,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.login),
                        label: Text(_isLoading ? 'Connexion...' : 'Se connecter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getColor(),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Exemples d'identifiants
            _buildExamplesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildExamplesCard() {
    final examples = _getExamples();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: _getColor(), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Exemples d\'identifiants',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getColor(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...examples.map((example) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _fillExample(example),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getColor().withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getColor().withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              example['email']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              example['description']!,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.touch_app,
                        color: _getColor(),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (widget.adminType) {
      case 'super_admin':
        return '👑 Super Administrateur';
      case 'admin_compagnie':
        return '🏢 Admin Compagnie';
      case 'admin_agence':
        return '🏪 Admin Agence';
      default:
        return 'Administration';
    }
  }

  String _getSubtitle() {
    switch (widget.adminType) {
      case 'super_admin':
        return 'Accès complet au système';
      case 'admin_compagnie':
        return 'Gestion de votre compagnie d\'assurance';
      case 'admin_agence':
        return 'Gestion de votre agence';
      default:
        return '';
    }
  }

  Color _getColor() {
    switch (widget.adminType) {
      case 'super_admin':
        return Colors.red;
      case 'admin_compagnie':
        return Colors.blue;
      case 'admin_agence':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getIcon() {
    switch (widget.adminType) {
      case 'super_admin':
        return Icons.admin_panel_settings;
      case 'admin_compagnie':
        return Icons.business;
      case 'admin_agence':
        return Icons.store;
      default:
        return Icons.person;
    }
  }

  String _getEmailHint() {
    switch (widget.adminType) {
      case 'super_admin':
        return 'super.admin@constat-tunisie.tn';
      case 'admin_compagnie':
        return 'admin.compagnie@constat-tunisie.tn';
      case 'admin_agence':
        return 'admin.agence@constat-tunisie.tn';
      default:
        return '';
    }
  }

  List<Map<String, String>> _getExamples() {
    switch (widget.adminType) {
      case 'super_admin':
        return [
          {
            'email': 'super.admin@constat-tunisie.tn',
            'password': 'SuperAdmin2024!',
            'description': 'Super Administrateur',
          },
        ];
      case 'admin_compagnie':
        return [
          {
            'email': 'admin.star@constat-tunisie.tn',
            'password': 'AdminStar2024!',
            'description': 'Admin STAR Assurance',
          },
          {
            'email': 'admin.maghrebia@constat-tunisie.tn',
            'password': 'AdminMaghrebia2024!',
            'description': 'Admin Maghrebia',
          },
          {
            'email': 'admin.gat@constat-tunisie.tn',
            'password': 'AdminGat2024!',
            'description': 'Admin GAT',
          },
        ];
      case 'admin_agence':
        return [
          {
            'email': 'admin.star.tunis@constat-tunisie.tn',
            'password': 'AdminStarTunis2024!',
            'description': 'Admin STAR Tunis',
          },
          {
            'email': 'admin.star.manouba@constat-tunisie.tn',
            'password': 'AdminStarManouba2024!',
            'description': 'Admin STAR Manouba',
          },
        ];
      default:
        return [];
    }
  }

  void _fillExample(Map<String, String> example) {
    _emailController.text = example['email']!;
    _passwordController.text = example['password']!;
  }

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Connexion Firebase Auth
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Vérifier le type d'admin dans Firestore
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins_users')
          .doc(credential.user!.uid)
          .get();

      if (!adminDoc.exists) {
        throw Exception('Compte admin non trouvé');
      }

      final adminData = adminDoc.data()!;
      final adminType = adminData['type'] as String;

      // Vérifier que le type correspond
      if (adminType != widget.adminType) {
        await FirebaseAuth.instance.signOut();
        throw Exception('Type d\'admin incorrect');
      }

      // Navigation vers le dashboard approprié
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/admin/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
