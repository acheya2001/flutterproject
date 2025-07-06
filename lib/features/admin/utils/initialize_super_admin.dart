import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/super_admin_setup.dart';

/// 🚀 Utilitaire pour initialiser le Super Admin
class InitializeSuperAdmin {
  
  /// 🔐 Initialiser le Super Admin au premier lancement
  static Future<void> initialize() async {
    try {
      debugPrint('[INIT_SUPER_ADMIN] 🚀 Initialisation du Super Admin...');
      
      // Créer le Super Admin s'il n'existe pas
      await SuperAdminSetup.createSuperAdmin();
      
      debugPrint('[INIT_SUPER_ADMIN] ✅ Initialisation terminée');
    } catch (e) {
      debugPrint('[INIT_SUPER_ADMIN] ❌ Erreur lors de l\'initialisation: $e');
    }
  }

  /// 🔍 Vérifier si le Super Admin existe
  static Future<bool> checkSuperAdminExists() async {
    try {
      final superAdmin = await SuperAdminSetup.getSuperAdminInfo();
      return superAdmin != null;
    } catch (e) {
      debugPrint('[INIT_SUPER_ADMIN] Erreur lors de la vérification: $e');
      return false;
    }
  }

  /// 📋 Afficher les informations du Super Admin
  static Future<void> showSuperAdminInfo() async {
    try {
      final superAdmin = await SuperAdminSetup.getSuperAdminInfo();
      
      if (superAdmin != null) {
        debugPrint('[SUPER_ADMIN_INFO] ✅ Super Admin trouvé:');
        debugPrint('[SUPER_ADMIN_INFO] 📧 Email: ${superAdmin.email}');
        debugPrint('[SUPER_ADMIN_INFO] 👤 Nom: ${superAdmin.fullName}');
        debugPrint('[SUPER_ADMIN_INFO] 🆔 ID: ${superAdmin.id}');
        debugPrint('[SUPER_ADMIN_INFO] 📅 Créé le: ${superAdmin.createdAt}');
      } else {
        debugPrint('[SUPER_ADMIN_INFO] ❌ Aucun Super Admin trouvé');
      }
    } catch (e) {
      debugPrint('[SUPER_ADMIN_INFO] ❌ Erreur: $e');
    }
  }
}

/// 🔐 Widget pour tester la connexion Super Admin
class SuperAdminTestWidget extends StatefulWidget {
  const SuperAdminTestWidget({Key? key}) : super(key: key);

  @override
  State<SuperAdminTestWidget> createState() => _SuperAdminTestWidgetState();
}

class _SuperAdminTestWidgetState extends State<SuperAdminTestWidget> {
  bool _isLoading = false;
  String _status = 'Prêt';

  /// 🚀 Initialiser le Super Admin
  Future<void> _initializeSuperAdmin() async {
    setState(() {
      _isLoading = true;
      _status = 'Initialisation en cours...';
    });

    try {
      await InitializeSuperAdmin.initialize();
      setState(() {
        _status = 'Super Admin initialisé avec succès !';
      });
    } catch (e) {
      setState(() {
        _status = 'Erreur: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 🔍 Vérifier le Super Admin
  Future<void> _checkSuperAdmin() async {
    setState(() {
      _isLoading = true;
      _status = 'Vérification en cours...';
    });

    try {
      final exists = await InitializeSuperAdmin.checkSuperAdminExists();
      setState(() {
        _status = exists 
            ? 'Super Admin existe ✅' 
            : 'Super Admin n\'existe pas ❌';
      });
      
      if (exists) {
        await InitializeSuperAdmin.showSuperAdminInfo();
      }
    } catch (e) {
      setState(() {
        _status = 'Erreur: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 🔐 Tester la connexion
  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Test de connexion...';
    });

    try {
      final userCredential = await SuperAdminSetup.signInSuperAdmin();
      
      if (userCredential != null) {
        setState(() {
          _status = 'Connexion réussie ! ✅';
        });
        
        // Se déconnecter immédiatement après le test
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      setState(() {
        _status = 'Erreur de connexion: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Super Admin'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Statut
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Statut: $_status',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Boutons d'action
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _initializeSuperAdmin,
              icon: const Icon(Icons.rocket_launch),
              label: const Text('Initialiser Super Admin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _checkSuperAdmin,
              icon: const Icon(Icons.search),
              label: const Text('Vérifier Super Admin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testConnection,
              icon: const Icon(Icons.login),
              label: const Text('Tester Connexion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Informations
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.yellow[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informations de connexion:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('📧 Email: constat.tunisie.app@gmail.com'),
                  Text('🔑 Mot de passe: Acheya123'),
                  SizedBox(height: 8),
                  Text(
                    '⚠️ Ces informations sont pour le développement uniquement.',
                    style: TextStyle(
                      color: Colors.red,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
