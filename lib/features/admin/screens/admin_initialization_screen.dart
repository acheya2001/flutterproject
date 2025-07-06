import 'package:flutter/material.dart';
import '../../../services/admin_service.dart';

class AdminInitializationScreen extends StatefulWidget {
  const AdminInitializationScreen({super.key});

  @override
  State<AdminInitializationScreen> createState() => _AdminInitializationScreenState();
}

class _AdminInitializationScreenState extends State<AdminInitializationScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _adminEmail;
  String? _adminPassword;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Initialisation du Système'),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings,
              size: 100,
              color: _isInitialized ? Colors.green : Colors.red[800],
            ),
            const SizedBox(height: 24),
            Text(
              _isInitialized 
                  ? 'Système Initialisé ✅'
                  : 'Initialisation Requise',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _isInitialized ? Colors.green : Colors.red[800],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isInitialized
                  ? 'Le système a été initialisé avec succès. Vous pouvez maintenant vous connecter avec le compte administrateur.'
                  : 'Le système doit être initialisé avec un compte super administrateur pour commencer.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            
            if (_isInitialized) ...[
              _buildCredentialsCard(),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                icon: const Icon(Icons.login),
                label: const Text('Aller à la Connexion'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ] else ...[
              _buildInitializationCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialsCard() {
    return Card(
      elevation: 4,
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.key, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Identifiants Administrateur',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCredentialRow('Email', _adminEmail ?? 'admin@constat-tunisie.tn'),
            const SizedBox(height: 8),
            _buildCredentialRow('Mot de passe', _adminPassword ?? 'AdminConstat2024!'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Changez le mot de passe après la première connexion',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 20),
          onPressed: () => _copyToClipboard(value),
          tooltip: 'Copier',
        ),
      ],
    );
  }

  Widget _buildInitializationCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.rocket_launch,
              size: 64,
              color: Colors.blue[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Initialiser le Système',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Cette action va créer le compte super administrateur qui pourra ensuite gérer toutes les compagnies d\'assurance et leurs agences.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _initializeSystem,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_isLoading ? 'Initialisation...' : 'Initialiser Maintenant'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeSystem() async {
    setState(() => _isLoading = true);
    
    try {
      await _adminService.initialiserSuperAdmin();
      
      setState(() {
        _isLoading = false;
        _isInitialized = true;
        _adminEmail = 'admin@constat-tunisie.tn';
        _adminPassword = 'AdminConstat2024!';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Système initialisé avec succès !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text) {
    // TODO: Implémenter la copie dans le presse-papiers
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copié: $text'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
