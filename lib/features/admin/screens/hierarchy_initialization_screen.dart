import 'package:flutter/material.dart';
import '../services/hierarchy_setup_service.dart';

/// 🏗️ Écran d'initialisation de la hiérarchie admin
class HierarchyInitializationScreen extends StatefulWidget {
  const HierarchyInitializationScreen({super.key});

  @override
  State<HierarchyInitializationScreen> createState() => _HierarchyInitializationScreenState();
}

class _HierarchyInitializationScreenState extends State<HierarchyInitializationScreen> {
  bool _isInitializing = false;
  bool _isInitialized = false;
  String _status = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('🏗️ Initialisation Hiérarchie'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.deepPurple.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Configuration Hiérarchique',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Initialiser la structure admin complète',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Structure preview
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 Structure qui sera créée :',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStructureCard(),
                    const SizedBox(height: 24),
                    _buildCredentialsCard(),
                  ],
                ),
              ),
            ),

            // Status
            if (_status.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isInitialized ? Colors.green[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isInitialized ? Colors.green : Colors.blue,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isInitialized ? Icons.check_circle : Icons.info,
                      color: _isInitialized ? Colors.green : Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _status,
                        style: TextStyle(
                          color: _isInitialized ? Colors.green[700] : Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Actions
            if (!_isInitialized) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isInitializing ? null : _initializeHierarchy,
                  icon: _isInitializing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.rocket_launch),
                  label: Text(_isInitializing ? 'Initialisation...' : 'Initialiser la Hiérarchie'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isInitializing ? null : _createTestData,
                  icon: const Icon(Icons.science),
                  label: const Text('Créer Données de Test'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/admin/home'),
                  icon: const Icon(Icons.dashboard),
                  label: const Text('Aller au Dashboard Admin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStructureCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHierarchyItem('👑 Super Admin', 'Gestion globale', Colors.red, 0),
            _buildHierarchyItem('🏢 Admin Compagnie', 'STAR, Maghrebia, GAT', Colors.blue, 1),
            _buildHierarchyItem('🏪 Admin Agence', 'Tunis, Manouba, Sfax, Sousse', Colors.green, 2),
            _buildHierarchyItem('👨‍💼 Agents', 'Demandes d\'inscription', Colors.orange, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildHierarchyItem(String title, String subtitle, Color color, int level) {
    return Padding(
      padding: EdgeInsets.only(left: level * 20.0, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔐 Identifiants créés :',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _buildCredentialRow('Super Admin', 'constat.tunisie.app@gmail.com'),
            _buildCredentialRow('Admin STAR', 'admin@star.tn'),
            _buildCredentialRow('Admin Maghrebia', 'admin@maghrebia.tn'),
            _buildCredentialRow('Admin GAT', 'admin@gat.tn'),
            _buildCredentialRow('Admin Agence Tunis', 'tunis@star.tn'),
            _buildCredentialRow('Admin Agence Manouba', 'manouba@star.tn'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mot de passe par défaut: Acheya123',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
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

  Widget _buildCredentialRow(String role, String email) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              role,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              email,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeHierarchy() async {
    setState(() {
      _isInitializing = true;
      _status = 'Initialisation en cours...';
    });

    try {
      final success = await HierarchySetupService.initializeHierarchy();
      
      setState(() {
        _isInitializing = false;
        _isInitialized = success;
        _status = success 
            ? '✅ Hiérarchie initialisée avec succès !'
            : '❌ Erreur lors de l\'initialisation';
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _status = '❌ Erreur: $e';
      });
    }
  }

  Future<void> _createTestData() async {
    setState(() {
      _isInitializing = true;
      _status = 'Création des données de test...';
    });

    try {
      await HierarchySetupService.createTestDemandes();
      
      setState(() {
        _isInitializing = false;
        _status = '✅ Données de test créées !';
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _status = '❌ Erreur: $e';
      });
    }
  }
}
