import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'services/complete_pdf_test_service.dart';
import 'services/debug_pdf_service.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

/// 🧪 Widget de test pour le générateur PDF complet
/// Utilisé uniquement en mode debug pour tester le PDF
class TestPdfDebugWidget extends StatefulWidget {
  const TestPdfDebugWidget({Key? key}) : super(key: key);

  @override
  State<TestPdfDebugWidget> createState() => _TestPdfDebugWidgetState();
}

class _TestPdfDebugWidgetState extends State<TestPdfDebugWidget> {
  bool _isLoading = false;
  String? _lastPdfPath;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test PDF Complet - Debug'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[600]!, Colors.blue[600]!],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.science,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'TEST PDF COMPLET ET ÉLÉGANT',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mode développement uniquement',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎯 Ce test va :',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...const [
                    '1. Créer une session de test avec 3 participants',
                    '2. Générer des formulaires complets pour chaque participant',
                    '3. Ajouter des signatures, croquis et photos',
                    '4. Générer un PDF complet et élégant',
                    '5. Ouvrir le PDF généré',
                  ].map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
                      ),
                    ),
                  )),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Boutons d'action
            if (_isLoading) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Test en cours...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Création des données et génération du PDF',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _testerPDF,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Test PDF avec Données Complètes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: _testerPDFDebug,
                icon: const Icon(Icons.bug_report),
                label: const Text('Test PDF Debug (Données Réelles)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _nettoyerDonnees,
                icon: const Icon(Icons.cleaning_services),
                label: const Text('Nettoyer les Données de Test'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange[600],
                  side: BorderSide(color: Colors.orange[300]!),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              if (_lastPdfPath != null) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _ouvrirDernierPDF,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Ouvrir le Dernier PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ],

            const Spacer(),

            // Pied de page
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '⚠️ Ce widget n\'est visible qu\'en mode debug.\n'
                'Il sera automatiquement masqué en production.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🧪 Tester la génération PDF
  Future<void> _testerPDF() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🧪 [DEBUG] Début du test PDF complet');

      final pdfPath = await CompletePdfTestService.creerSessionTestEtGenererPDF();

      setState(() {
        _isLoading = false;
        _lastPdfPath = pdfPath;
      });

      // Afficher le succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ PDF de test généré avec succès !'),
            backgroundColor: Colors.green[600],
            action: SnackBarAction(
              label: 'Ouvrir',
              textColor: Colors.white,
              onPressed: _ouvrirDernierPDF,
            ),
          ),
        );
      }

      print('✅ [DEBUG] Test PDF terminé: $pdfPath');

    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur test PDF: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }

      print('❌ [DEBUG] Erreur test PDF: $e');
    }
  }

  /// 🔍 Tester la génération PDF avec données debug réelles
  Future<void> _testerPDFDebug() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 [DEBUG] Début du test PDF avec données réelles');

      final pdfPath = await DebugPdfService.creerSessionTestEtGenererPDF();

      setState(() {
        _isLoading = false;
        _lastPdfPath = pdfPath;
      });

      // Afficher le succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ PDF debug généré avec données réelles !'),
            backgroundColor: Colors.purple[600],
            action: SnackBarAction(
              label: 'Ouvrir',
              textColor: Colors.white,
              onPressed: _ouvrirDernierPDF,
            ),
          ),
        );
      }

      print('✅ [DEBUG] Test PDF debug terminé: $pdfPath');

    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur test PDF debug: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }

      print('❌ [DEBUG] Erreur test PDF debug: $e');
    }
  }

  /// 🧹 Nettoyer les données de test
  Future<void> _nettoyerDonnees() async {
    try {
      await CompletePdfTestService.nettoyerDonneesTest();
      await DebugPdfService.nettoyerDonneesTest();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🧹 Toutes les données de test nettoyées'),
            backgroundColor: Colors.orange[600],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur nettoyage: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  /// 📂 Ouvrir le dernier PDF généré
  Future<void> _ouvrirDernierPDF() async {
    if (_lastPdfPath == null) return;

    try {
      final file = File(_lastPdfPath!);
      if (await file.exists()) {
        final result = await OpenFile.open(_lastPdfPath!);
        if (result.type != ResultType.done) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('PDF sauvegardé dans: $_lastPdfPath'),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Fichier PDF non trouvé'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
