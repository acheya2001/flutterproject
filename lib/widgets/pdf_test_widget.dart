import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/pdf_test_service.dart';

/// 🧪 Widget de test pour la génération PDF
class PDFTestWidget extends StatefulWidget {
  const PDFTestWidget({Key? key}) : super(key: key);

  @override
  State<PDFTestWidget> createState() => _PDFTestWidgetState();
}

class _PDFTestWidgetState extends State<PDFTestWidget> {
  bool _isLoading = false;
  String? _lastGeneratedPdfUrl;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.science, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Test Génération PDF Améliorée',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Ce test génère un PDF avec des données complètes pour valider les améliorations:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),

            const _TestFeaturesList(),
            const SizedBox(height: 16),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testerGenerationPDF,
                    icon: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.picture_as_pdf),
                    label: Text(_isLoading ? 'Génération...' : 'Tester PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _nettoyerDonneesTest,
                  icon: const Icon(Icons.cleaning_services),
                  label: const Text('Nettoyer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            // Résultats
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error, color: Colors.red[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Erreur',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ],
                ),
              ),
            ],

            if (_lastGeneratedPdfUrl != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'PDF généré avec succès!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _lastGeneratedPdfUrl!,
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _ouvrirPDF(_lastGeneratedPdfUrl!),
                          icon: const Icon(Icons.open_in_new),
                          tooltip: 'Ouvrir le PDF',
                          color: Colors.green[700],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _testerGenerationPDF() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _lastGeneratedPdfUrl = null;
    });

    try {
      final pdfUrl = await PDFTestService.testerGenerationPDF();
      setState(() {
        _lastGeneratedPdfUrl = pdfUrl;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ PDF généré avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _nettoyerDonneesTest() async {
    try {
      await PDFTestService.nettoyerDonneesTest();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🧹 Données de test nettoyées'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur nettoyage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _ouvrirPDF(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Impossible d\'ouvrir le PDF';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur ouverture PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// 📋 Liste des fonctionnalités testées
class _TestFeaturesList extends StatelessWidget {
  const _TestFeaturesList();

  @override
  Widget build(BuildContext context) {
    const features = [
      '📅 Date, lieu et heure récupérés depuis les formulaires',
      '🚗 Informations d\'assurance avec validité réelle',
      '🆔 Données de permis avec dates de délivrance',
      '💥 Points de choc et dégâts sélectionnés',
      '⚡ Circonstances cochées par chaque conducteur',
      '💬 Observations et remarques complètes',
      '🎨 Croquis réels si disponibles',
      '✍️ Signatures électroniques intégrées',
      '👥 Informations des témoins',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features.map((feature) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ', style: TextStyle(color: Colors.green)),
            Expanded(
              child: Text(
                feature,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}
