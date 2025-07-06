import 'package:flutter/material.dart';
import '../../../utils/test_data_creator.dart';

/// 🧪 Écran pour gérer les données de test
class TestDataScreen extends StatefulWidget {
  const TestDataScreen({super.key});

  @override
  State<TestDataScreen> createState() => _TestDataScreenState();
}

class _TestDataScreenState extends State<TestDataScreen> {
  final TestDataCreator _testDataCreator = TestDataCreator();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Données de Test'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            _buildHeader(),
            
            const SizedBox(height: 24),
            
            // Actions
            Expanded(
              child: ListView(
                children: [
                  _buildActionCard(
                    title: '🚗 Créer Véhicules de Test',
                    description: 'Crée des véhicules assurés pour différentes compagnies',
                    onTap: _createTestVehicules,
                    color: Colors.blue,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildActionCard(
                    title: '🏢 Créer Assureurs de Test',
                    description: 'Crée les compagnies d\'assurance (STAR, Maghrebia, GAT)',
                    onTap: _createTestAssureurs,
                    color: Colors.green,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildActionCard(
                    title: '📊 Créer Analytics de Test',
                    description: 'Crée des données de Business Intelligence',
                    onTap: _createTestAnalytics,
                    color: Colors.orange,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildActionCard(
                    title: '🚀 Créer Toutes les Données',
                    description: 'Crée un jeu complet de données de test',
                    onTap: _createAllTestData,
                    color: Colors.purple,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _buildActionCard(
                    title: '🧹 Nettoyer les Données',
                    description: 'Supprime toutes les données de test',
                    onTap: _cleanTestData,
                    color: Colors.red,
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📋 En-tête informatif
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[50]!, Colors.purple[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.science, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Environnement de Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    Text(
                      'Créez des données de test pour développer et tester l\'application',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '⚠️ Ces données sont uniquement pour le développement. '
            'Elles seront supprimées en production.',
            style: TextStyle(fontSize: 14, color: Colors.orange),
          ),
        ],
      ),
    );
  }

  /// 🎯 Widget carte d'action
  Widget _buildActionCard({
    required String title,
    required String description,
    required VoidCallback onTap,
    required Color color,
    bool isDestructive = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDestructive ? Colors.red[200]! : color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isDestructive ? Icons.delete_forever : Icons.add_circle,
                  color: color,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDestructive ? Colors.red[700] : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🚗 Créer véhicules de test
  void _createTestVehicules() async {
    setState(() => _isLoading = true);
    
    try {
      await _testDataCreator.createTestVehicules();
      _showSuccessMessage('Véhicules de test créés avec succès ! 🚗');
    } catch (e) {
      _showErrorMessage('Erreur lors de la création des véhicules: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🏢 Créer assureurs de test
  void _createTestAssureurs() async {
    setState(() => _isLoading = true);
    
    try {
      await _testDataCreator.createTestAssureurs();
      _showSuccessMessage('Assureurs de test créés avec succès ! 🏢');
    } catch (e) {
      _showErrorMessage('Erreur lors de la création des assureurs: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 📊 Créer analytics de test
  void _createTestAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      await _testDataCreator.createTestAnalytics();
      _showSuccessMessage('Analytics de test créées avec succès ! 📊');
    } catch (e) {
      _showErrorMessage('Erreur lors de la création des analytics: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🚀 Créer toutes les données
  void _createAllTestData() async {
    setState(() => _isLoading = true);
    
    try {
      await _testDataCreator.createAllTestData();
      _showSuccessMessage('Toutes les données de test créées avec succès ! 🎉');
    } catch (e) {
      _showErrorMessage('Erreur lors de la création des données: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🧹 Nettoyer les données
  void _cleanTestData() async {
    // Confirmation avant suppression
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirmation'),
          ],
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer toutes les données de test ?\n\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    
    try {
      await _testDataCreator.cleanTestData();
      _showSuccessMessage('Données de test supprimées avec succès ! 🧹');
    } catch (e) {
      _showErrorMessage('Erreur lors de la suppression: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ✅ Message de succès
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// ❌ Message d'erreur
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
