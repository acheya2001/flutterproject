import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/agent_test_data_service.dart';
import '../../admin/screens/hierarchy_initialization_screen.dart';

/// 🎯 Écran de connexion admin ultra-simple qui fonctionne
class AdminLoginSimple extends StatefulWidget {
  const AdminLoginSimple({super.key});

  @override
  State<AdminLoginSimple> createState() => _AdminLoginSimpleState();
}

class _AdminLoginSimpleState extends State<AdminLoginSimple> {
  final _emailController = TextEditingController(text: 'constat.tunisie.app@gmail.com');
  final _passwordController = TextEditingController(text: 'Acheya123');
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 🔐 Connexion admin ultra-simple
  Future<void> _loginAdmin() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('🎯 [ADMIN_SIMPLE] Début connexion...');
      
      // Vérifier si déjà connecté
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.email == _emailController.text.trim()) {
        debugPrint('🎯 [ADMIN_SIMPLE] Déjà connecté, navigation directe...');
        _navigateToAdmin();
        return;
      }
      
      // Déconnexion préventive
      await FirebaseAuth.instance.signOut();
      await Future.delayed(const Duration(milliseconds: 500));
      
      debugPrint('🎯 [ADMIN_SIMPLE] Tentative de connexion...');
      
      // Connexion simple avec retry pour problèmes réseau
      bool connectionSuccess = false;
      int retryCount = 0;
      const maxRetries = 3;

      while (!connectionSuccess && retryCount < maxRetries) {
        try {
          retryCount++;
          debugPrint('🎯 [ADMIN_SIMPLE] Tentative $retryCount/$maxRetries...');

          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

          // Attendre un peu pour que Firebase se stabilise
          await Future.delayed(const Duration(milliseconds: 1000));

          // Vérifier la connexion
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            debugPrint('🎯 [ADMIN_SIMPLE] Connexion réussie: ${user.uid}');
            connectionSuccess = true;
            _navigateToAdmin();
          } else {
            throw Exception('Utilisateur non connecté après authentification');
          }

        } catch (authError) {
          debugPrint('🎯 [ADMIN_SIMPLE] Erreur auth tentative $retryCount: $authError');

          // Si erreur réseau, attendre avant retry
          if (authError.toString().contains('Connection reset by peer') ||
              authError.toString().contains('I/O error') ||
              authError.toString().contains('network')) {

            if (retryCount < maxRetries) {
              debugPrint('🎯 [ADMIN_SIMPLE] Erreur réseau, retry dans 2s...');
              await Future.delayed(const Duration(seconds: 2));
              continue;
            }
          }

          // Si erreur de type, essayer navigation directe
          if (authError.toString().contains('type cast') ||
              authError.toString().contains('subtype') ||
              authError.toString().contains('PigeonUserDetails')) {

            debugPrint('🎯 [ADMIN_SIMPLE] Erreur de type détectée, vérification utilisateur...');
            await Future.delayed(const Duration(milliseconds: 2000));

            final user = FirebaseAuth.instance.currentUser;
            if (user != null && user.email == _emailController.text.trim()) {
              debugPrint('🎯 [ADMIN_SIMPLE] Utilisateur connecté malgré erreur, navigation...');
              connectionSuccess = true;
              _navigateToAdmin();
              return;
            }
          }

          // Si dernière tentative, propager l'erreur
          if (retryCount >= maxRetries) {
            rethrow;
          }
        }
      }
      
    } catch (e) {
      debugPrint('🎯 [ADMIN_SIMPLE] Erreur finale: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
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

  /// 🚨 Connexion d'urgence (contournement pour problèmes réseau)
  Future<void> _emergencyLogin() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('🚨 [ADMIN_SIMPLE] Connexion d\'urgence activée...');

      // Vérifier les identifiants localement
      if (_emailController.text.trim() == 'constat.tunisie.app@gmail.com' &&
          _passwordController.text == 'Acheya123') {

        debugPrint('🚨 [ADMIN_SIMPLE] Identifiants valides, navigation directe...');

        // Navigation directe sans authentification Firebase
        _navigateToAdmin();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🚨 Connexion d\'urgence réussie'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        throw Exception('Identifiants incorrects');
      }

    } catch (e) {
      debugPrint('🚨 [ADMIN_SIMPLE] Erreur connexion d\'urgence: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
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

  /// 🚀 Navigation vers admin
  void _navigateToAdmin() {
    debugPrint('🎯 [ADMIN_SIMPLE] Navigation vers admin...');

    if (mounted) {
      // Navigation vers le dashboard admin propre
      Navigator.pushReplacementNamed(context, '/admin/home');
      debugPrint('🎯 [ADMIN_SIMPLE] Navigation terminée');
    }
  }

  /// 🧪 Créer les données de test pour l'agent
  Future<void> _createAgentTestData() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('🧪 [ADMIN_SIMPLE] Création données test agent...');

      await AgentTestDataService.createAgentTestData();

      // Récupérer les identifiants créés
      final credentials = AgentTestDataService.getTestCredentials();

      if (mounted) {
        if (credentials != null) {
          // Afficher les identifiants dans un dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('✅ Données de test créées'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Identifiants de connexion agent :'),
                  const SizedBox(height: 16),
                  SelectableText('Email: ${credentials['email']}'),
                  const SizedBox(height: 8),
                  SelectableText('Mot de passe: ${credentials['password']}'),
                  const SizedBox(height: 16),
                  const Text(
                    'Utilisez ces identifiants pour vous connecter en tant qu\'agent d\'assurance.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Données de test agent créées avec succès'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

      debugPrint('🧪 [ADMIN_SIMPLE] Données test créées avec succès');
    } catch (e) {
      debugPrint('🚨 [ADMIN_SIMPLE] Erreur création données test: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('🎯 Admin Simple'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                size: 60,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              'Connexion Administrateur',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Email
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              enabled: !_isLoading,
            ),
            
            const SizedBox(height: 16),
            
            // Mot de passe
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
              enabled: !_isLoading,
            ),
            
            const SizedBox(height: 32),

            // Bouton connexion
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _loginAdmin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Se connecter',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Bouton connexion d'urgence (contournement)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _emergencyLogin,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '🚨 Connexion d\'urgence',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bouton créer données de test agent
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createAgentTestData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '🧪 Créer données test agent',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Bouton Config Hiérarchie (NOUVEAU)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HierarchyInitializationScreen(),
                  ),
                ),
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('🏢 Initialiser Hiérarchie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '🎯 Version simplifiée qui contourne les erreurs de type Firebase',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
