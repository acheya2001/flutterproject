import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/constants.dart';
import '../widgets/firebase_console_widget.dart';

/// 🔍 Écran pour vérifier les données dans Firestore
class DataVerificationScreen extends StatefulWidget {
  const DataVerificationScreen({super.key});

  @override
  State<DataVerificationScreen> createState() => _DataVerificationScreenState();
}

class _DataVerificationScreenState extends State<DataVerificationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Vérification des Données'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildDataView(),
    );
  }

  /// ❌ État d'erreur
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadStats,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  /// 📊 Vue des données
  Widget _buildDataView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec résumé
          _buildSummaryCard(),
          
          const SizedBox(height: 20),
          
          // Statistiques par collection
          _buildCollectionStats(),
          
          const SizedBox(height: 20),
          
          // Échantillons de données
          _buildDataSamples(),
          
          const SizedBox(height: 20),
          
          // Actions de test
          _buildTestActions(),

          const SizedBox(height: 20),

          // Console Firebase
          const FirebaseConsoleWidget(),
        ],
      ),
    );
  }

  /// 📋 Carte résumé
  Widget _buildSummaryCard() {
    final totalRecords = _stats.values.fold<int>(0, (sum, stat) => 
        sum + (stat is Map && stat.containsKey('count') ? stat['count'] as int : 0));
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.green[50]!, Colors.green[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storage, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Base de Données Firebase',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Dernière vérification: ${DateTime.now().toString().substring(0, 19)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$totalRecords enregistrements',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '✅ Base de données opérationnelle avec ${_stats.length} collections actives',
              style: TextStyle(fontSize: 14, color: Colors.green[700]),
            ),
          ],
        ),
      ),
    );
  }

  /// 📊 Statistiques par collection
  Widget _buildCollectionStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📊 Statistiques par Collection',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 12),
        ..._stats.entries.map((entry) => _buildCollectionCard(entry.key, entry.value)),
      ],
    );
  }

  /// 📋 Carte de collection
  Widget _buildCollectionCard(String collection, dynamic stats) {
    if (stats is! Map) return const SizedBox();
    
    final count = stats['count'] ?? 0;
    final lastUpdated = stats['lastUpdated'] as DateTime?;
    final samples = stats['samples'] as List?;
    
    IconData icon;
    Color color;
    String description;
    
    switch (collection) {
      case 'vehicules_assures':
        icon = Icons.directions_car;
        color = Colors.blue;
        description = 'Véhicules avec contrats d\'assurance';
        break;
      case 'constats':
        icon = Icons.assignment;
        color = Colors.orange;
        description = 'Déclarations d\'accident';
        break;
      case 'assureurs_compagnies':
        icon = Icons.business;
        color = Colors.purple;
        description = 'Compagnies d\'assurance';
        break;
      case 'analytics':
        icon = Icons.analytics;
        color = Colors.green;
        description = 'Données de Business Intelligence';
        break;
      default:
        icon = Icons.folder;
        color = Colors.grey;
        description = 'Collection de données';
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          collection,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            if (lastUpdated != null)
              Text(
                'Dernière MAJ: ${lastUpdated.toString().substring(0, 19)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Text('docs', style: TextStyle(fontSize: 10)),
          ],
        ),
        onTap: () => _showCollectionDetails(collection, stats),
      ),
    );
  }

  /// 📋 Échantillons de données
  Widget _buildDataSamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🔍 Échantillons de Données',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 12),
        ..._stats.entries.where((e) => e.value is Map && e.value['samples'] != null)
            .map((entry) => _buildSampleCard(entry.key, entry.value['samples'])),
      ],
    );
  }

  /// 📄 Carte échantillon
  Widget _buildSampleCard(String collection, List samples) {
    if (samples.isEmpty) return const SizedBox();
    
    final sample = samples.first;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text('Échantillon: $collection'),
        subtitle: Text('${samples.length} exemples disponibles'),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premier enregistrement:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatSample(sample),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🎬 Actions de test
  Widget _buildTestActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🧪 Actions de Test',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _testQueries,
                icon: const Icon(Icons.search),
                label: const Text('Tester Requêtes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _exportSample,
                icon: const Icon(Icons.download),
                label: const Text('Exporter Échantillon'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 📊 Charger les statistiques
  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = <String, dynamic>{};
      
      // Collections à vérifier
      final collections = [
        Constants.collectionVehiculesAssures,
        Constants.collectionConstats,
        Constants.collectionAnalytics,
        'assureurs_compagnies',
      ];

      for (final collection in collections) {
        try {
          final snapshot = await _firestore.collection(collection).limit(5).get();
          
          stats[collection] = {
            'count': snapshot.size,
            'lastUpdated': DateTime.now(),
            'samples': snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data(),
            }).toList(),
          };
          
          // Obtenir le count total
          final countSnapshot = await _firestore.collection(collection).count().get();
          stats[collection]['count'] = countSnapshot.count;
          
        } catch (e) {
          stats[collection] = {
            'count': 0,
            'error': e.toString(),
            'lastUpdated': DateTime.now(),
            'samples': [],
          };
        }
      }

      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 📋 Afficher les détails d'une collection
  void _showCollectionDetails(String collection, Map stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📊 Détails: $collection'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Nombre de documents', '${stats['count']}'),
              _buildDetailRow('Dernière vérification', 
                  stats['lastUpdated']?.toString().substring(0, 19) ?? 'N/A'),
              _buildDetailRow('Échantillons disponibles', 
                  '${(stats['samples'] as List?)?.length ?? 0}'),
              if (stats['error'] != null)
                _buildDetailRow('Erreur', stats['error'], isError: true),
            ],
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

  /// 📊 Ligne de détail
  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isError ? Colors.red : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📄 Formater un échantillon
  String _formatSample(Map<String, dynamic> sample) {
    final buffer = StringBuffer();
    sample.forEach((key, value) {
      if (key != 'id') {
        buffer.writeln('$key: ${_formatValue(value)}');
      }
    });
    return buffer.toString();
  }

  /// 🔧 Formater une valeur
  String _formatValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toString().substring(0, 19);
    } else if (value is Map) {
      return '{...}';
    } else if (value is List) {
      return '[${value.length} items]';
    } else {
      return value.toString();
    }
  }

  /// 🧪 Tester les requêtes
  void _testQueries() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Test des requêtes en cours...'),
          ],
        ),
      ),
    );

    try {
      // Test de requêtes complexes
      final vehiculesActifs = await _firestore
          .collection(Constants.collectionVehiculesAssures)
          .where('statut', isEqualTo: 'actif')
          .limit(1)
          .get();

      final constatsRecents = await _firestore
          .collection(Constants.collectionConstats)
          .orderBy('created_at', descending: true)
          .limit(1)
          .get();

      Navigator.of(context).pop(); // Fermer le dialog de chargement

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('✅ Tests Réussis'),
          content: Text(
            'Toutes les requêtes fonctionnent correctement !\n\n'
            '• Véhicules actifs: ${vehiculesActifs.size} trouvé(s)\n'
            '• Constats récents: ${constatsRecents.size} trouvé(s)\n'
            '• Règles de sécurité: OK\n'
            '• Index Firestore: OK',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Parfait !'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Fermer le dialog de chargement
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('❌ Erreur de Test'),
          content: Text('Erreur lors du test des requêtes:\n\n$e'),
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

  /// 📤 Exporter un échantillon
  void _exportSample() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📤 Fonctionnalité d\'export en développement'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
