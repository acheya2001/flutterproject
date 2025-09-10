import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

/// 🧹 Application simple pour nettoyer les données
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const CleanupApp());
}

class CleanupApp extends StatelessWidget {
  const CleanupApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nettoyage Données',
      theme: ThemeData(primarySwatch: Colors.red),
      home: const CleanupScreen(),
    );
  }
}

class CleanupScreen extends StatefulWidget {
  const CleanupScreen({Key? key}) : super(key: key);

  @override
  State<CleanupScreen> createState() => _CleanupScreenState();
}

class _CleanupScreenState extends State<CleanupScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  Map<String, int> _counts = {};

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    setState(() => _isLoading = true);
    
    final collections = [
      'sinistres',
      'declarations_sinistres',
      'accident_sessions_complete',
      'accident_sessions',
      'constats'
    ];

    final counts = <String, int>{};
    
    for (final collection in collections) {
      try {
        final snapshot = await _firestore.collection(collection).get();
        counts[collection] = snapshot.docs.length;
      } catch (e) {
        counts[collection] = -1;
      }
    }

    setState(() {
      _counts = counts;
      _isLoading = false;
    });
  }

  Future<void> _deleteAllSinistres() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirmation'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer TOUS les sinistres ?\n\n'
          'Cette action est IRRÉVERSIBLE !',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('SUPPRIMER TOUT', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final collections = [
        'sinistres',
        'declarations_sinistres',
        'accident_sessions_complete',
        'accident_sessions',
        'constats'
      ];

      for (final collectionName in collections) {
        await _deleteCollection(collectionName);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Tous les sinistres ont été supprimés !'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadCounts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCollection(String collectionName) async {
    print('🗑️ Suppression de la collection: $collectionName');
    
    final snapshot = await _firestore.collection(collectionName).get();
    print('📊 ${snapshot.docs.length} documents trouvés');

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    print('✅ ${snapshot.docs.length} documents supprimés de $collectionName');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧹 Nettoyage des Sinistres'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Documents actuels:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (_isLoading) ...[
              const Center(child: CircularProgressIndicator()),
            ] else ...[
              ..._counts.entries.map((entry) => Card(
                child: ListTile(
                  title: Text(entry.key),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: entry.value > 0 ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      entry.value.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: entry.value > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ),
              )).toList(),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _deleteAllSinistres,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('SUPPRIMER TOUS LES SINISTRES'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _loadCounts,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualiser les compteurs'),
                ),
              ),
            ],

            const Spacer(),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚠️ ATTENTION: Cette action supprime définitivement tous les sinistres. Elle ne peut pas être annulée !',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
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
}
