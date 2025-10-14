import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/cloudinary_pdf_service.dart';
import '../../services/complete_elegant_pdf_service.dart';
import '../../services/pdf_migration_service.dart';

/// 🧪 Écran de test pour Cloudinary PDF
class CloudinaryPdfTestScreen extends StatefulWidget {
  const CloudinaryPdfTestScreen({Key? key}) : super(key: key);

  @override
  State<CloudinaryPdfTestScreen> createState() => _CloudinaryPdfTestScreenState();
}

class _CloudinaryPdfTestScreenState extends State<CloudinaryPdfTestScreen> {
  String _testResults = '';
  bool _isLoading = false;
  String? _lastGeneratedPdfUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Test Cloudinary PDF'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Titre
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 48, color: Colors.blue[700]),
                    const SizedBox(height: 8),
                    Text(
                      'Test Cloudinary PDF Service',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Testez la génération et l\'upload de PDFs vers Cloudinary',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Boutons de test
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testPdfGeneration,
                  icon: const Icon(Icons.create),
                  label: const Text('Générer PDF Test'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _analyzeFirebasePdfs,
                  icon: const Icon(Icons.analytics),
                  label: const Text('Analyser PDFs Firebase'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testMigration,
                  icon: const Icon(Icons.sync),
                  label: const Text('Test Migration'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (_lastGeneratedPdfUrl != null)
                  ElevatedButton.icon(
                    onPressed: () => _openPdf(_lastGeneratedPdfUrl!),
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Ouvrir PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Zone de résultats
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.terminal, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Résultats des tests',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const Spacer(),
                          if (_testResults.isNotEmpty)
                            IconButton(
                              onPressed: _clearResults,
                              icon: const Icon(Icons.clear),
                              tooltip: 'Effacer',
                            ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: _isLoading
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text('Test en cours...'),
                                  ],
                                ),
                              )
                            : SingleChildScrollView(
                                child: Text(
                                  _testResults.isEmpty
                                      ? 'Aucun test exécuté.\nCliquez sur un bouton pour commencer.'
                                      : _testResults,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🧪 Test de génération de PDF avec upload Cloudinary
  Future<void> _testPdfGeneration() async {
    setState(() {
      _isLoading = true;
      _testResults += '\n🧪 === TEST GÉNÉRATION PDF CLOUDINARY ===\n';
      _testResults += '⏰ ${DateTime.now().toString()}\n\n';
    });

    try {
      // Générer un PDF de test
      _testResults += '📄 Génération PDF de test...\n';
      setState(() {});

      final pdfUrl = await CompleteElegantPdfService.genererConstatCompletElegant(
        sessionId: 'test_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (pdfUrl.contains('cloudinary.com')) {
        _testResults += '✅ PDF généré et uploadé vers Cloudinary !\n';
        _testResults += '🔗 URL: $pdfUrl\n';
        _lastGeneratedPdfUrl = pdfUrl;
        
        // Test des informations du PDF
        final publicId = CloudinaryPdfService.extractPublicIdFromUrl(pdfUrl);
        if (publicId != null) {
          _testResults += '🆔 Public ID: $publicId\n';
          
          final pdfInfo = await CloudinaryPdfService.getPdfInfo(publicId);
          if (pdfInfo != null) {
            _testResults += '📊 Taille: ${pdfInfo['bytes']} bytes\n';
            _testResults += '📅 Créé: ${pdfInfo['created_at']}\n';
          }
        }
      } else {
        _testResults += '⚠️ PDF généré mais pas sur Cloudinary: $pdfUrl\n';
      }

    } catch (e) {
      _testResults += '❌ Erreur génération PDF: $e\n';
    }

    setState(() {
      _isLoading = false;
      _testResults += '\n';
    });
  }

  /// 📊 Analyser les PDFs Firebase existants
  Future<void> _analyzeFirebasePdfs() async {
    setState(() {
      _isLoading = true;
      _testResults += '\n📊 === ANALYSE PDFS FIREBASE ===\n';
      _testResults += '⏰ ${DateTime.now().toString()}\n\n';
    });

    try {
      final analysis = await PdfMigrationService.analyzeFirebasePdfs();
      
      if (analysis.containsKey('error')) {
        _testResults += '❌ Erreur analyse: ${analysis['error']}\n';
      } else {
        _testResults += '📈 Sessions totales: ${analysis['totalSessions']}\n';
        _testResults += '🔥 Sessions avec PDFs Firebase: ${analysis['sessionsWithFirebasePdfs']}\n';
        _testResults += '📄 PDFs Firebase totaux: ${analysis['totalFirebasePdfs']}\n';
        
        if (analysis['firebasePdfUrls'].isNotEmpty) {
          _testResults += '\n📋 Exemples d\'URLs Firebase:\n';
          final urls = analysis['firebasePdfUrls'] as List;
          for (int i = 0; i < urls.length && i < 3; i++) {
            _testResults += '   ${i + 1}. ${urls[i]}\n';
          }
          if (urls.length > 3) {
            _testResults += '   ... et ${urls.length - 3} autres\n';
          }
        }
      }

    } catch (e) {
      _testResults += '❌ Erreur analyse: $e\n';
    }

    setState(() {
      _isLoading = false;
      _testResults += '\n';
    });
  }

  /// 🔄 Test de migration d'un PDF
  Future<void> _testMigration() async {
    setState(() {
      _isLoading = true;
      _testResults += '\n🔄 === TEST MIGRATION PDF ===\n';
      _testResults += '⏰ ${DateTime.now().toString()}\n\n';
    });

    try {
      // D'abord analyser pour trouver des PDFs Firebase
      final analysis = await PdfMigrationService.analyzeFirebasePdfs();
      
      if (analysis['firebasePdfUrls'].isNotEmpty) {
        final firebaseUrl = analysis['firebasePdfUrls'][0] as String;
        _testResults += '🎯 Test migration du PDF: $firebaseUrl\n';
        
        final cloudinaryUrl = await PdfMigrationService.migratePdfToCloudinary(
          firebaseUrl: firebaseUrl,
          sessionId: 'migration_test_${DateTime.now().millisecondsSinceEpoch}',
          folder: 'test_migration',
        );
        
        if (cloudinaryUrl != null) {
          _testResults += '✅ Migration réussie !\n';
          _testResults += '🔗 Nouvelle URL Cloudinary: $cloudinaryUrl\n';
          _lastGeneratedPdfUrl = cloudinaryUrl;
        } else {
          _testResults += '❌ Échec de la migration\n';
        }
      } else {
        _testResults += '⚠️ Aucun PDF Firebase trouvé pour tester la migration\n';
        _testResults += '💡 Générez d\'abord un PDF de test avec l\'ancien système\n';
      }

    } catch (e) {
      _testResults += '❌ Erreur migration: $e\n';
    }

    setState(() {
      _isLoading = false;
      _testResults += '\n';
    });
  }

  /// 🌐 Ouvrir le PDF dans le navigateur
  Future<void> _openPdf(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _testResults += '🌐 PDF ouvert dans le navigateur\n';
      } else {
        _testResults += '❌ Impossible d\'ouvrir le PDF\n';
      }
    } catch (e) {
      _testResults += '❌ Erreur ouverture PDF: $e\n';
    }
    setState(() {});
  }

  /// 🧹 Effacer les résultats
  void _clearResults() {
    setState(() {
      _testResults = '';
      _lastGeneratedPdfUrl = null;
    });
  }
}
