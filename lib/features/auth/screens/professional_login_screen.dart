import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../models/user_model.dart';
import '../../assureur/screens/hierarchical_agent_dashboard.dart';
import '../../expert/screens/expert_dashboard_screen.dart';

/// 🏢 Écran de connexion pour les professionnels (Assureurs et Experts)
class ProfessionalLoginScreen extends ConsumerStatefulWidget {
  final String userType; // 'assureur' ou 'expert'
  
  const ProfessionalLoginScreen({
    super.key,
    required this.userType,
  });

  @override
  ConsumerState<ProfessionalLoginScreen> createState() => _ProfessionalLoginScreenState();
}

class _ProfessionalLoginScreenState extends ConsumerState<ProfessionalLoginScreen> {
  final _formKey = GlobalKey<FormState>();
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

  /// 🔐 Connexion professionnel
  Future<void> _loginProfessional() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Connexion Firebase Auth
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (credential.user != null) {
        // Vérifier les informations utilisateur
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final userType = userData['userType'] as String?;
          final accountStatus = userData['accountStatus'] as String? ?? 'active';

          // Vérifier le type d'utilisateur
          if (userType != widget.userType) {
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              _showError('Ce compte n\'est pas un compte ${widget.userType == 'assureur' ? 'agent d\'assurance' : 'expert'}.');
            }
            return;
          }

          // Vérifier le statut du compte
          if (accountStatus == 'pending') {
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              _showError('Votre compte est en attente de validation par un administrateur.');
            }
            return;
          } else if (accountStatus == 'rejected') {
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              final reason = userData['rejectionReason'] as String? ?? 'Raison non spécifiée';
              _showError('Votre compte a été rejeté. Raison: $reason');
            }
            return;
          } else if (accountStatus == 'suspended') {
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              _showError('Votre compte a été suspendu. Contactez l\'administrateur.');
            }
            return;
          }

          // Connexion réussie - rediriger vers le bon dashboard
          if (mounted) {
            if (widget.userType == 'assureur') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const HierarchicalAgentDashboard(),
                ),
              );
            } else {
              // Pour les experts, créer un dashboard ou rediriger
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExpertDashboardScreen(),
                ),
              );
            }
          }
        } else {
          // Utilisateur non trouvé
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            _showError('Compte non trouvé dans la base de données.');
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Erreur de connexion';
      switch (e.code) {
        case 'user-not-found':
          message = 'Aucun compte trouvé avec cet email';
          break;
        case 'wrong-password':
          message = 'Mot de passe incorrect';
          break;
        case 'invalid-email':
          message = 'Email invalide';
          break;
        case 'user-disabled':
          message = 'Ce compte a été désactivé';
          break;
        case 'too-many-requests':
          message = 'Trop de tentatives. Réessayez plus tard';
          break;
        default:
          message = 'Erreur: ${e.message}';
      }

      if (mounted) {
        _showError(message);
      }
    } catch (e) {
      if (mounted) {
        _showError('Erreur inattendue: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// ❌ Afficher une erreur
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAssureur = widget.userType == 'assureur';
    
    return Scaffold(
      appBar: CustomAppBar(
        title: isAssureur ? 'Connexion Agent d\'Assurance' : 'Connexion Expert',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              
              // Logo et titre
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isAssureur ? Colors.blue[50] : Colors.orange[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isAssureur ? Icons.business : Icons.assignment_ind,
                      size: 64,
                      color: isAssureur ? Colors.blue[600] : Colors.orange[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isAssureur ? 'Agent d\'Assurance' : 'Expert',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connectez-vous à votre compte professionnel',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Champ Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email professionnel',
                  hintText: 'votre.email@exemple.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir votre email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Email invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Champ Mot de passe
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  hintText: 'Votre mot de passe',
                  prefixIcon: const Icon(Icons.lock_outlined),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir votre mot de passe';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Bouton de connexion
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _loginProfessional,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAssureur ? Colors.blue[600] : Colors.orange[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Lien mot de passe oublié
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: Implémenter la réinitialisation du mot de passe
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fonctionnalité à venir'),
                      ),
                    );
                  },
                  child: const Text('Mot de passe oublié ?'),
                ),
              ),
              const SizedBox(height: 32),

              // Information sur le statut du compte
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Compte en attente de validation ?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Votre compte doit être validé par un administrateur avant la première connexion. Vous recevrez un email de confirmation.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
