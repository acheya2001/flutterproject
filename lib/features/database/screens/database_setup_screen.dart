import 'package:flutter/material.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../services/firebase_data_organizer.dart';
import '../../insurance/services/vehicule_complet_generator.dart';

/// 🗄️ Écran de configuration de la base de données
class DatabaseSetupScreen extends StatefulWidget {
  const DatabaseSetupScreen({super.key});

  @override
  State<DatabaseSetupScreen> createState() => _DatabaseSetupScreenState();
}

class _DatabaseSetupScreenState extends State<DatabaseSetupScreen> {
  bool _isGenerating = false;
  bool _isClearing = false;
  String _statusMessage = '';
  List<String> _logs = [];

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toLocal().toString().substring(11, 19)} - $message');
    });
  }

  Future<void> _generateCompleteDatabase() async {
    setState(() {
      _isGenerating = true;
      _statusMessage = 'Génération de la base de données en cours...';
      _logs.clear();
    });

    try {
      _addLog('🚀 Début de la génération');

      await FirebaseDataOrganizer.generateCompleteDatabase();

      _addLog('✅ Base de données générée avec succès');
      setState(() {
        _statusMessage = 'Base de données générée avec succès !';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Base de données générée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _addLog('❌ Erreur: $e');
      setState(() {
        _statusMessage = 'Erreur: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _generateNewInsuranceStructure() async {
    setState(() {
      _isGenerating = true;
      _statusMessage = 'Génération structure d\'assurance complète...';
      _logs.clear();
    });

    try {
      _addLog('🚀 Début génération structure assurance');

      await VehiculeCompletGenerator.generateCompleteInsuranceStructure();

      _addLog('✅ Structure d\'assurance générée avec succès');
      setState(() {
        _statusMessage = 'Structure d\'assurance générée avec succès !';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Structure d\'assurance générée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _addLog('❌ Erreur: $e');
      setState(() {
        _statusMessage = 'Erreur: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirmation'),
        content: const Text('Êtes-vous sûr de vouloir supprimer toutes les données ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isClearing = true;
      _statusMessage = 'Suppression des données en cours...';
      _logs.clear();
    });

    try {
      _addLog('🧹 Début du nettoyage');
      
      await FirebaseDataOrganizer.clearAllData();
      
      _addLog('✅ Données supprimées avec succès');
      setState(() {
        _statusMessage = 'Données supprimées avec succès !';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Données supprimées avec succès'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      _addLog('❌ Erreur: $e');
      setState(() {
        _statusMessage = 'Erreur: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isClearing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Configuration Base de Données',
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            _buildHeader(),
            
            const SizedBox(height: 24),
            
            // Actions
            _buildActions(),
            
            const SizedBox(height: 24),
            
            // Statut
            if (_statusMessage.isNotEmpty) _buildStatus(),
            
            const SizedBox(height: 24),
            
            // Logs
            if (_logs.isNotEmpty) _buildLogs(),
            
            const SizedBox(height: 24),
            
            // Informations
            _buildInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepOrange[50]!, Colors.deepOrange[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepOrange[600],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.storage, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuration Firebase',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Génération et gestion des données',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚡ Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        
        // Générer base de données
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isGenerating || _isClearing ? null : _generateCompleteDatabase,
            icon: _isGenerating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_circle),
            label: Text(_isGenerating ? 'Génération en cours...' : 'Générer Base de Données Complète'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Générer nouvelle structure d'assurance
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isGenerating || _isClearing ? null : _generateNewInsuranceStructure,
            icon: _isGenerating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.business),
            label: Text(_isGenerating ? 'Génération en cours...' : 'Générer Structure Assurance Complète'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Supprimer toutes les données
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isGenerating || _isClearing ? null : _clearAllData,
            icon: _isClearing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_sweep),
            label: Text(_isClearing ? 'Suppression en cours...' : 'Supprimer Toutes les Données'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.blue[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _statusMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📋 Logs',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            itemCount: _logs.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  _logs[index],
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ℹ️ Informations',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Structure Assurance Complète génère :',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: 8),
              Text('• 5 compagnies d\'assurance tunisiennes (STAR, Maghrebia, Lloyd, GAT, AST)', style: TextStyle(fontSize: 12)),
              Text('• 15 agences réparties par gouvernorat avec directeurs', style: TextStyle(fontSize: 12)),
              Text('• 45+ agents d\'assurance avec portefeuilles clients', style: TextStyle(fontSize: 12)),
              Text('• 500 véhicules complets avec contrats d\'assurance', style: TextStyle(fontSize: 12)),
              Text('• Conducteurs autorisés avec droits et permissions', style: TextStyle(fontSize: 12)),
              Text('• Hiérarchie réelle d\'assurance tunisienne', style: TextStyle(fontSize: 12)),
              SizedBox(height: 8),
              Text(
                'Base de Données Ancienne génère :',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: 4),
              Text('• Structure simplifiée pour compatibilité', style: TextStyle(fontSize: 12)),
              Text('• 150 liaisons véhicule-conducteur', style: TextStyle(fontSize: 12)),
              Text('• 20 demandes de validation agents', style: TextStyle(fontSize: 12)),
              SizedBox(height: 12),
              Text(
                '⚠️ Ces opérations peuvent prendre plusieurs minutes',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
