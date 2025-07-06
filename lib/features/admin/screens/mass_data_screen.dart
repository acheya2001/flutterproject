import 'package:flutter/material.dart';
import '../../../utils/mass_data_generator.dart';

/// 🏭 Écran pour générer des données massives
class MassDataScreen extends StatefulWidget {
  const MassDataScreen({super.key});

  @override
  State<MassDataScreen> createState() => _MassDataScreenState();
}

class _MassDataScreenState extends State<MassDataScreen> {
  final MassDataGenerator _generator = MassDataGenerator();
  
  bool _isGenerating = false;
  String _currentOperation = '';
  double _progress = 0.0;
  
  // Paramètres configurables
  int _nombreVehicules = 1000;
  int _nombreConstats = 200;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏭 Générateur de Données Massives'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            _buildHeader(),
            
            const SizedBox(height: 24),
            
            // Configuration
            _buildConfiguration(),
            
            const SizedBox(height: 24),
            
            // Aperçu des données
            _buildDataPreview(),
            
            const SizedBox(height: 24),
            
            // Actions
            _buildActions(),
            
            const SizedBox(height: 24),
            
            // Progression
            if (_isGenerating) _buildProgress(),
          ],
        ),
      ),
    );
  }

  /// 📋 En-tête
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple[50]!, Colors.deepPurple[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.factory, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Base de Données Massive',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    Text(
                      'Générez des milliers de contrats réalistes',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '🎯 Créez une base de données complète avec des données réalistes pour '
            'tester votre application à grande échelle. Parfait pour votre PFE !',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// ⚙️ Configuration
  Widget _buildConfiguration() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.deepPurple, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Configuration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Nombre de véhicules
            _buildSliderConfig(
              'Nombre de véhicules',
              _nombreVehicules,
              100,
              5000,
              (value) => setState(() => _nombreVehicules = value.round()),
              '🚗',
            ),
            
            const SizedBox(height: 16),
            
            // Nombre de constats
            _buildSliderConfig(
              'Nombre de constats',
              _nombreConstats,
              50,
              1000,
              (value) => setState(() => _nombreConstats = value.round()),
              '📋',
            ),
            
            const SizedBox(height: 16),
            
            // Estimation du temps
            _buildTimeEstimation(),
          ],
        ),
      ),
    );
  }

  /// 🎛️ Widget slider de configuration
  Widget _buildSliderConfig(
    String title,
    int value,
    double min,
    double max,
    Function(double) onChanged,
    String emoji,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.deepPurple[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple[700],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value.toDouble(),
          min: min,
          max: max,
          divisions: ((max - min) / 50).round(),
          activeColor: Colors.deepPurple,
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// ⏱️ Estimation du temps
  Widget _buildTimeEstimation() {
    final tempsEstime = (_nombreVehicules / 100 + _nombreConstats / 50).round();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: Colors.orange[700], size: 20),
          const SizedBox(width: 8),
          Text(
            'Temps estimé: ~$tempsEstime minutes',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Aperçu des données
  Widget _buildDataPreview() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.preview, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Aperçu des Données',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildPreviewItem('🏢', 'Compagnies d\'assurance', '8 compagnies tunisiennes'),
            _buildPreviewItem('🚗', 'Véhicules assurés', '$_nombreVehicules contrats réalistes'),
            _buildPreviewItem('📋', 'Constats d\'accident', '$_nombreConstats déclarations'),
            _buildPreviewItem('📊', 'Analytics BI', 'Tableaux de bord complets'),
            _buildPreviewItem('👥', 'Utilisateurs', 'Conducteurs, assureurs, experts'),
            _buildPreviewItem('🗺️', 'Couverture géographique', '24 gouvernorats tunisiens'),
          ],
        ),
      ),
    );
  }

  /// 📋 Item d'aperçu
  Widget _buildPreviewItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🎬 Actions
  Widget _buildActions() {
    return Column(
      children: [
        // Bouton principal de génération
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isGenerating ? null : _generateMassiveData,
            icon: _isGenerating 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.rocket_launch),
            label: Text(_isGenerating ? 'Génération en cours...' : 'Générer la Base de Données'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Actions secondaires
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: _isGenerating ? null : _showCleanDialog,
                icon: const Icon(Icons.delete_sweep, color: Colors.red),
                label: const Text(
                  'Nettoyer Tout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextButton.icon(
                onPressed: _isGenerating ? null : _showInfoDialog,
                icon: const Icon(Icons.info, color: Colors.blue),
                label: const Text(
                  'Plus d\'infos',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 📊 Progression
  Widget _buildProgress() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.hourglass_top, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Génération en cours',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              _currentOperation,
              style: const TextStyle(fontSize: 14),
            ),
            
            const SizedBox(height: 8),
            
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 8,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              '${(_progress * 100).round()}% terminé',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🚀 Générer les données massives
  void _generateMassiveData() async {
    setState(() {
      _isGenerating = true;
      _currentOperation = 'Initialisation...';
      _progress = 0.0;
    });

    try {
      await _generator.generateMassiveDatabase(
        nombreVehicules: _nombreVehicules,
        nombreConstats: _nombreConstats,
        showProgress: true,
      );

      setState(() {
        _currentOperation = 'Génération terminée !';
        _progress = 1.0;
      });

      _showSuccessDialog();
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  /// 🧹 Dialog de nettoyage
  void _showCleanDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Attention !'),
          ],
        ),
        content: const Text(
          'Cette action va supprimer TOUTES les données de la base :\n\n'
          '• Tous les véhicules assurés\n'
          '• Tous les constats\n'
          '• Toutes les analytics\n'
          '• Toutes les compagnies\n\n'
          'Cette action est IRRÉVERSIBLE !',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cleanAllData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer Tout'),
          ),
        ],
      ),
    );
  }

  /// 🧹 Nettoyer toutes les données
  void _cleanAllData() async {
    setState(() {
      _isGenerating = true;
      _currentOperation = 'Nettoyage en cours...';
      _progress = 0.5;
    });

    try {
      await _generator.cleanAllData();
      
      setState(() {
        _currentOperation = 'Nettoyage terminé !';
        _progress = 1.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🧹 Base de données nettoyée avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  /// ℹ️ Dialog d'informations
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📊 Informations sur les Données'),
        content: const SingleChildScrollView(
          child: Text(
            'Cette fonctionnalité génère une base de données complète avec :\n\n'
            '🏢 8 compagnies d\'assurance tunisiennes réelles\n'
            '🚗 Véhicules avec marques populaires en Tunisie\n'
            '👥 Noms et prénoms tunisiens authentiques\n'
            '📍 Couverture des 24 gouvernorats\n'
            '📋 Constats d\'accident réalistes\n'
            '📊 Analytics et KPIs automatiques\n\n'
            '⚡ Optimisé pour Firebase avec batch operations\n'
            '🔒 Respecte les règles de sécurité Firestore\n'
            '📱 Compatible avec votre application mobile\n\n'
            'Parfait pour démontrer votre PFE avec des données réalistes !',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// ✅ Dialog de succès
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Succès !'),
          ],
        ),
        content: Text(
          '🎉 Base de données générée avec succès !\n\n'
          '📊 Résumé :\n'
          '• $_nombreVehicules véhicules assurés\n'
          '• $_nombreConstats constats d\'accident\n'
          '• 8 compagnies d\'assurance\n'
          '• Analytics complètes\n\n'
          'Votre application est prête pour la démonstration !',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Parfait !'),
          ),
        ],
      ),
    );
  }

  /// ❌ Dialog d'erreur
  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Erreur'),
          ],
        ),
        content: Text('Une erreur s\'est produite :\n\n$error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
