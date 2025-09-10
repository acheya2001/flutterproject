import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/navigation_service.dart';
import '../../../services/admin_compagnie_auth_service.dart';
import '../../../services/agent_auth_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/conducteur_workaround_service.dart';
import '../../admin_compagnie/screens/admin_compagnie_dashboard.dart';
import 'conducteur_register_simple_screen.dart';
import '../../admin_agence/screens/modern_admin_agence_dashboard.dart';
import '../../agent/screens/agent_dashboard_screen.dart';
import '../../../conducteur/screens/guest_join_session_screen.dart';
import '../../../debug/check_admin_account.dart';
import '../../conducteur/presentation/screens/conducteur_registration_screen.dart';

/// 🔐 Écran de connexion pour tous les types d'utilisateurs
class LoginScreen extends StatefulWidget {
  final String userType;

  const LoginScreen({
    Key? key,
    required this.userType,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _userTypeTitle {
    switch (widget.userType) {
      case 'driver':
        return 'Conducteur';
      case 'agent':
        return 'Agent d\'Assurance';
      case 'expert':
        return 'Expert Automobile';
      case 'admin':
        return 'Administrateur';
      default:
        return 'Utilisateur';
    }
  }

  IconData get _userTypeIcon {
    switch (widget.userType) {
      case 'driver':
        return Icons.person;
      case 'agent':
        return Icons.business_center;
      case 'expert':
        return Icons.engineering;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  Color get _userTypeColor {
    switch (widget.userType) {
      case 'driver':
        return AppTheme.primaryColor;
      case 'agent':
        return AppTheme.secondaryColor;
      case 'expert':
        return AppTheme.accentColor;
      case 'admin':
        return Colors.red.shade600;
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _userTypeColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [

              // Contenu principal
              SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                // Icône du type d'utilisateur
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _userTypeColor,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: _userTypeColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    _userTypeIcon,
                    size: 50,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 32),

                // Titre
                Text(
                  'Connexion $_userTypeTitle',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _userTypeColor,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Connectez-vous à votre espace personnel',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Formulaire de connexion
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _userTypeColor),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez saisir votre email';
                          }
                          if (!value.contains('@')) {
                            return 'Email invalide';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Mot de passe
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              if (mounted) setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _userTypeColor),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez saisir votre mot de passe';
                          }
                          if (value.length < 6) {
                            return 'Le mot de passe doit contenir au moins 6 caractères';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Bouton de connexion
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _userTypeColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                )
                              : const Text(
                                  'Se connecter',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Mot de passe oublié
                      TextButton(
                        onPressed: _handleForgotPassword,
                        child: Text(
                          'Mot de passe oublié ?',
                          style: TextStyle(
                            color: _userTypeColor,
                            fontSize: 14,
                          ),
                        ),
                      ),

                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Lien d'inscription pour conducteurs
                if (widget.userType == 'driver')
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Pas encore de compte ? ',
                              style: TextStyle(color: Colors.grey),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ConducteurRegisterSimpleScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'S\'inscrire',
                                style: TextStyle(
                                  color: _userTypeColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Bouton Invité pour rejoindre une session
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const GuestJoinSessionScreen(
                                    sessionCode: '', // Code vide, sera saisi par l'utilisateur
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.group_add),
                            label: const Text('Rejoindre en tant qu\'invité'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _userTypeColor,
                              side: BorderSide(color: _userTypeColor),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Retour
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Retour'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                  ),
                ),

                // Icône cadenas pour super admin (en bas)
                if (widget.userType == 'admin') ...[
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: _handleSuperAdminAccess,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Icon(
                        Icons.lock,
                        color: Colors.red.shade600,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Accès Super Admin',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) setState(() {
      _isLoading = true;
    });

    try {
      // Connexion Firebase Auth réelle
      final result = await _performFirebaseLogin();

      if (result['success']) {
        final userRole = result['role'] as String;
        final isDirectMode = result['directMode'] ?? false;

        // Afficher le message de succès avec le vrai rôle
        if (isDirectMode) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Connexion réussie (mode direct) - $userRole'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          NavigationService.showLoginSuccess(userRole);
        }

        // Attendre un peu pour que l'utilisateur voie le message
        await Future.delayed(const Duration(milliseconds: 1500));

        // Rediriger vers le dashboard approprié selon le vrai rôle
        if (userRole == 'admin_compagnie') {
          // Redirection spéciale pour admin compagnie avec données
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminCompagnieDashboard(
                userData: result['userData'],
              ),
            ),
          );
        } else if (userRole == 'admin_agence') {
          // Redirection spéciale pour admin agence avec données
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ModernAdminAgenceDashboard(
                userData: result['userData'],
              ),
            ),
          );
        } else if (userRole == 'agent') {
          // Redirection spéciale pour agent avec données
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AgentDashboardScreen(),
            ),
          );
        } else if (userRole == 'conducteur') {
          // Redirection spéciale pour conducteur
          Navigator.pushReplacementNamed(context, '/conducteur-dashboard');
        } else {
          NavigationService.redirectToDashboard(userRole);
        }
      } else {
        // Vérifier si c'est un compte désactivé
        if (result['isAccountDisabled'] == true) {
          _showAccountDisabledDialog(result['error']);
        } else {
          throw Exception(result['error'] ?? 'Erreur de connexion');
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur de connexion'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        if (mounted) setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 🚫 Afficher le dialogue de compte désactivé
  void _showAccountDisabledDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.block_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Compte Désactivé',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_rounded, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Si vous pensez qu\'il s\'agit d\'une erreur, contactez votre administrateur.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Optionnel : ouvrir l'app email ou téléphone
            },
            icon: const Icon(Icons.contact_support_rounded),
            label: const Text('Contacter Support'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mot de passe oublié'),
        content: const Text(
          'Contactez votre administrateur pour réinitialiser votre mot de passe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleSuperAdminAccess() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('Accès Super Admin'),
          ],
        ),
        content: const Text(
          'Accès réservé aux super administrateurs uniquement.\n\n'
          'Cet accès permet de gérer l\'ensemble du système.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigation vers le dashboard Super Admin
              Navigator.pushReplacementNamed(context, '/super-admin-dashboard');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Accéder'),
          ),
        ],
      ),
    );
  }

  /// 🔐 Effectuer la connexion Firebase réelle
  Future<Map<String, dynamic>> _performFirebaseLogin() async {
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      print('[LOGIN] 🔐 Tentative de connexion pour: $email');

      // 🚗 CONNEXION SPÉCIALE POUR LES CONDUCTEURS (Service hybride)
      if (widget.userType == 'driver') {
        print('[LOGIN] 🚗 Mode conducteur détecté, utilisation service hybride...');
        try {
          final result = await ConducteurWorkaroundService.connecterConducteurHybride(
            email: email,
            password: password,
          );

          if (result['success'] == true) {
            print('[LOGIN] ✅ Connexion conducteur réussie (mode: ${result['mode'] ?? 'firebase'})');

            // Redirection immédiate vers le dashboard conducteur
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/conducteur-dashboard');
              }
            });

            return result;
          } else {
            print('[LOGIN] ❌ Échec connexion conducteur: ${result['error']}');
            return result;
          }
        } catch (e) {
          print('[LOGIN] ❌ Erreur connexion conducteur: $e');
          return {
            'success': false,
            'error': 'Erreur de connexion conducteur: $e',
          };
        }
      }

      // 🔧 CONNEXION SPÉCIALE POUR LES AGENTS (Service avec création différée)
      // Vérifier d'abord si c'est un agent
      try {
        final agentQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .where('role', isEqualTo: 'agent')
            .limit(1)
            .get();

        if (agentQuery.docs.isNotEmpty) {
          print('[LOGIN] 🔧 Agent détecté, utilisation service spécialisé...');
          final result = await AgentAuthService.loginAgent(
            email: email,
            password: password,
          );

          if (result['success'] == true) {
            print('[LOGIN] ✅ Connexion agent réussie');
            return {
              'success': true,
              'user': result['user'],
              'userData': result['userData'],
              'role': 'agent',
              'message': result['message'],
              'directMode': false,
            };
          } else {
            print('[LOGIN] ❌ Échec connexion agent: ${result['error']}');
            return result;
          }
        }
      } catch (e) {
        print('[LOGIN] ⚠️ Erreur vérification agent: $e');
      }

      // 🎯 VÉRIFICATION DIRECTE DANS FIRESTORE (CONTOURNEMENT SSL)
      print('[LOGIN] 🔍 Vérification directe Firestore...');

      try {
        // Chercher d'abord dans la collection 'users'
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        Map<String, dynamic>? userData;
        String? userDocId;
        String? userRole;

        if (userQuery.docs.isNotEmpty) {
          final userDoc = userQuery.docs.first;
          userData = userDoc.data();
          userDocId = userDoc.id;
          userRole = userData['role'];
          print('[LOGIN] 👤 Utilisateur trouvé dans collection "users"');
        } else {
          // Si pas trouvé dans 'users', chercher dans 'conducteurs'
          print('[LOGIN] 🔍 Recherche dans collection "conducteurs"...');
          final conducteurQuery = await FirebaseFirestore.instance
              .collection('conducteurs')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

          if (conducteurQuery.docs.isNotEmpty) {
            final conducteurDoc = conducteurQuery.docs.first;
            userData = conducteurDoc.data();
            userDocId = conducteurDoc.id;
            userRole = 'conducteur';
            print('[LOGIN] 🚗 Conducteur trouvé dans collection "conducteurs"');
          }
        }

        if (userData != null && userDocId != null) {
          // Vérifier le mot de passe
          final storedPassword = userData['password'] ??
                                userData['temporaryPassword'] ??
                                userData['motDePasseTemporaire'] ??
                                userData['generated_password'];

          if (storedPassword == password) {
            print('[LOGIN] ✅ Connexion Firestore directe réussie');

            // 🔒 VÉRIFICATION DU STATUT DU COMPTE
            print('[LOGIN] 🔍 Vérification du statut du compte...');
            final accountStatus = await AuthService.checkAccountStatus(userData);

            if (!accountStatus['isActive']) {
              print('[LOGIN] 🚫 Compte désactivé: ${accountStatus['reason']}');
              return {
                'success': false,
                'error': accountStatus['message'],
                'isAccountDisabled': true,
              };
            }

            print('[LOGIN] ✅ Compte actif et autorisé');

            // Créer un objet utilisateur simulé (sans Firebase Auth)
            final fakeUser = {
              'uid': userDocId,
              'email': email,
              'displayName': '${userData['prenom']} ${userData['nom']}',
            };

            return {
              'success': true,
              'user': fakeUser,
              'userData': userData,
              'role': userRole,
              'message': 'Connexion réussie (mode direct)',
              'directMode': true,
            };
          } else {
            print('[LOGIN] ❌ Mot de passe incorrect');
            return {
              'success': false,
              'error': 'Mot de passe incorrect',
            };
          }
        }
      } catch (e) {
        print('[LOGIN] ⚠️ Erreur vérification Firestore: $e');
      }

      // Si ce n'est pas trouvé dans Firestore, continuer avec la connexion standard
      print('[LOGIN] 🔐 Connexion Firebase Auth standard...');

      // Connexion Firebase Auth standard pour les autres utilisateurs
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return {
          'success': false,
          'error': 'Utilisateur non trouvé après connexion',
        };
      }

      print('[LOGIN] ✅ Connexion Firebase Auth réussie: ${user.uid}');

      // Récupérer les données utilisateur depuis Firestore
      // Chercher d'abord dans 'users', puis dans 'conducteurs'
      DocumentSnapshot? userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      Map<String, dynamic>? userData;
      String? userRole;

      if (userDoc.exists) {
        userData = userDoc.data() as Map<String, dynamic>;
        userRole = userData['role'] as String?;
        print('[LOGIN] 👤 Données trouvées dans collection "users"');
      } else {
        // Chercher dans la collection 'conducteurs'
        userDoc = await FirebaseFirestore.instance
            .collection('conducteurs')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          userData = userDoc.data() as Map<String, dynamic>;
          userRole = 'conducteur';
          print('[LOGIN] 🚗 Données trouvées dans collection "conducteurs"');
        }
      }

      if (userData == null) {
        return {
          'success': false,
          'error': 'Données utilisateur non trouvées dans Firestore',
        };
      }

      if (userRole == null || userRole.isEmpty) {
        return {
          'success': false,
          'error': 'Rôle utilisateur non défini',
        };
      }

      // 🔒 VÉRIFICATION DU STATUT DU COMPTE (Firebase Auth)
      print('[LOGIN] 🔍 Vérification du statut du compte (Firebase Auth)...');
      final accountStatus = await AuthService.checkAccountStatus(userData);

      if (!accountStatus['isActive']) {
        print('[LOGIN] 🚫 Compte désactivé: ${accountStatus['reason']}');
        await FirebaseAuth.instance.signOut(); // Déconnecter immédiatement
        return {
          'success': false,
          'error': accountStatus['message'],
          'isAccountDisabled': true,
        };
      }

      print('[LOGIN] ✅ Compte actif et autorisé (Firebase Auth)');
      print('[LOGIN] ✅ Utilisateur trouvé avec rôle: $userRole');
      print('[LOGIN] 📊 Données utilisateur: ${userData['displayName']} - ${userData['email']}');

      return {
        'success': true,
        'role': userRole,
        'userData': userData,
      };

    } on FirebaseAuthException catch (e) {
      print('[LOGIN] ❌ Erreur Firebase Auth: ${e.code} - ${e.message}');

      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Aucun utilisateur trouvé avec cet email';
          break;
        case 'wrong-password':
          errorMessage = 'Mot de passe incorrect';
          break;
        case 'invalid-email':
          errorMessage = 'Format d\'email invalide';
          break;
        case 'user-disabled':
          errorMessage = 'Ce compte a été désactivé';
          break;
        default:
          errorMessage = 'Erreur de connexion: ${e.message}';
      }

      return {
        'success': false,
        'error': errorMessage,
      };

    } catch (e) {
      print('[LOGIN] ❌ Erreur générale: $e');
      return {
        'success': false,
        'error': 'Erreur de connexion: $e',
      };
    }
  }
}
