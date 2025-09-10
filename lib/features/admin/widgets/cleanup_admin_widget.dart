import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../services/cleanup_service.dart';

/// 🧹 Widget d'administration pour le nettoyage des données
class CleanupAdminWidget extends StatefulWidget {
  const CleanupAdminWidget({Key? key}) : super(key: key);

  @override
  State<CleanupAdminWidget> createState() => _CleanupAdminWidgetState();
}

class _CleanupAdminWidgetState extends State<CleanupAdminWidget> {
  bool _isLoading = false;
  Map<String, int> _documentCounts = {};

  @override
  void initState() {
    super.initState();
    _loadDocumentCounts();
  }

  Future<void> _loadDocumentCounts() async {
    try {
      final counts = await CleanupService.countSinistresDocuments();
      setState(() {
        _documentCounts = counts;
      });
    } catch (e) {
      print('Erreur chargement compteurs: $e');
    }
  }

  Future<void> _deleteAllTestSinistres() async {
    final confirmed = await _showConfirmationDialog(
      'Supprimer tous les sinistres',
      'Êtes-vous sûr de vouloir supprimer TOUS les sinistres de test ?\n\nCette action est irréversible !',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      await CleanupService.deleteAllTestSinistres();
      await _loadDocumentCounts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tous les sinistres ont été supprimés'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteOnlyFakeData() async {
    final confirmed = await _showConfirmationDialog(
      'Supprimer les données de test',
      'Supprimer seulement les documents avec isFakeData = true ?',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      await CleanupService.deleteOnlyFakeDataSinistres();
      await _loadDocumentCounts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Données de test supprimées'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            '🚨 Outils de nettoyage disponibles uniquement en mode debug',
            style: TextStyle(color: Colors.orange),
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cleaning_services, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Nettoyage des données',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Compteurs de documents
            if (_documentCounts.isNotEmpty) ...[
              const Text(
                'Documents actuels:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ..._documentCounts.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: entry.value > 0 ? Colors.orange.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        entry.value.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: entry.value > 0 ? Colors.orange[800] : Colors.green[800],
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
              const SizedBox(height: 16),
            ],

            // Boutons d'action
            if (_isLoading) ...[
              const Center(
                child: CircularProgressIndicator(),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _deleteOnlyFakeData,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Supprimer données de test'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _deleteAllTestSinistres,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Supprimer TOUS les sinistres'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loadDocumentCounts,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualiser les compteurs'),
                ),
              ),
            ],

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ATTENTION: Ces actions sont irréversibles !',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
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
