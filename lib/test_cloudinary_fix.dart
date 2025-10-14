import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'services/cloudinary_pdf_service.dart';
import 'services/complete_elegant_pdf_service.dart';
import 'services/constat_agent_notification_service.dart';

/// 🧪 Test rapide pour vérifier la correction Cloudinary
class TestCloudinaryFix extends StatefulWidget {
  const TestCloudinaryFix({Key? key}) : super(key: key);

  @override
  State<TestCloudinaryFix> createState() => _TestCloudinaryFixState();
}

class _TestCloudinaryFixState extends State<TestCloudinaryFix> {
  String _results = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Test Cloudinary Fix'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testConfiguration,
              child: const Text('Test Configuration'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _testPdfGeneration,
              child: const Text('Test PDF Generation'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _testCompleteWorkflow,
              child: const Text('Test Workflow Complet'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _testCloudinarySignature,
              child: const Text('Test Signature Cloudinary'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _testQuickSignature,
              child: const Text('🔐 Test Signature Rapide'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _nettoyerEtRetester,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
              child: const Text('🧹 Nettoyer & Retester Notifications', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Text(
                          _results.isEmpty ? 'Aucun test exécuté' : _results,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testConfiguration() async {
    setState(() {
      _isLoading = true;
      _results = '🧪 Test Configuration Cloudinary\n\n';
    });

    try {
      final config = CloudinaryPdfService.testConfiguration();
      _results += '✅ Configuration chargée:\n';
      _results += '   Cloud Name: ${config['cloudName']}\n';
      _results += '   API Key: ${config['apiKey']}\n';
      _results += '   API Secret: ${config['apiSecret']}\n';
      _results += '   Configuré: ${config['configured']}\n\n';
    } catch (e) {
      _results += '❌ Erreur configuration: $e\n\n';
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testPdfGeneration() async {
    setState(() {
      _isLoading = true;
      _results += '🧪 Test Génération PDF\n\n';
    });

    try {
      _results += '📄 Génération PDF de test...\n';
      setState(() {});

      final sessionId = 'test_fix_${DateTime.now().millisecondsSinceEpoch}';
      final pdfUrl = await CompleteElegantPdfService.genererConstatCompletElegant(
        sessionId: sessionId,
      );

      if (pdfUrl.contains('cloudinary.com')) {
        _results += '✅ PDF uploadé vers Cloudinary !\n';
        _results += '🔗 URL: $pdfUrl\n';

        // Extraire le public ID
        final publicId = CloudinaryPdfService.extractPublicIdFromUrl(pdfUrl);
        if (publicId != null) {
          _results += '🆔 Public ID: $publicId\n';
        }

        // 🧪 NOUVEAU: Tester l'accessibilité de l'URL
        await _testUrlAccessibility(pdfUrl);

      } else if (pdfUrl.startsWith('https://')) {
        _results += '⚠️ PDF uploadé mais pas sur Cloudinary: $pdfUrl\n';
      } else {
        _results += '❌ PDF local généré: $pdfUrl\n';
        _results += '💡 L\'upload Cloudinary a échoué\n';
      }
    } catch (e) {
      _results += '❌ Erreur génération: $e\n';
    }

    setState(() {
      _isLoading = false;
      _results += '\n';
    });
  }

  /// 🌐 Tester l'accessibilité d'une URL
  Future<void> _testUrlAccessibility(String url) async {
    _results += '\n🌐 Test accessibilité URL...\n';
    setState(() {});

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'application/pdf,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 10));

      _results += '📊 Status Code: ${response.statusCode}\n';
      _results += '📊 Content-Type: ${response.headers['content-type'] ?? 'Non spécifié'}\n';
      _results += '📊 Content-Length: ${response.headers['content-length'] ?? 'Non spécifié'}\n';

      if (response.statusCode == 200) {
        _results += '✅ URL accessible ! PDF téléchargeable\n';

        // Vérifier si c'est vraiment un PDF
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('pdf')) {
          _results += '✅ Content-Type PDF confirmé\n';
        } else {
          _results += '⚠️ Content-Type inattendu: $contentType\n';
        }
      } else if (response.statusCode == 404) {
        _results += '❌ URL non trouvée (404) - Le fichier n\'existe pas sur Cloudinary\n';
      } else if (response.statusCode == 403) {
        _results += '❌ Accès refusé (403) - Problème d\'authentification\n';
      } else {
        _results += '❌ Erreur HTTP ${response.statusCode}\n';
      }

    } catch (e) {
      _results += '❌ Erreur test accessibilité: $e\n';
    }

    setState(() {});
  }

  Future<void> _testCompleteWorkflow() async {
    setState(() {
      _isLoading = true;
      _results += '🧪 Test Workflow Complet\n\n';
    });

    try {
      final sessionId = 'test_workflow_${DateTime.now().millisecondsSinceEpoch}';

      _results += '1️⃣ Génération PDF...\n';
      setState(() {});

      final pdfUrl = await CompleteElegantPdfService.genererConstatCompletElegant(
        sessionId: sessionId,
      );

      if (pdfUrl.contains('cloudinary.com')) {
        _results += '✅ PDF généré et uploadé vers Cloudinary\n';
        _results += '🔗 URL: $pdfUrl\n\n';
      } else {
        _results += '❌ PDF non uploadé vers Cloudinary: $pdfUrl\n\n';
      }

      _results += '2️⃣ Vérification sauvegarde session...\n';
      setState(() {});

      // Vérifier que l'URL est sauvegardée dans la session
      final sessionDoc = await FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .get();

      if (sessionDoc.exists) {
        final sessionData = sessionDoc.data()!;
        final savedPdfUrl = sessionData['pdfUrl'] as String?;

        if (savedPdfUrl == pdfUrl) {
          _results += '✅ URL PDF sauvegardée dans session\n';
          _results += '📄 Type: ${sessionData['pdfType'] ?? 'non spécifié'}\n\n';
        } else {
          _results += '❌ URL PDF non sauvegardée ou différente\n';
          _results += '   Attendue: $pdfUrl\n';
          _results += '   Trouvée: $savedPdfUrl\n\n';
        }
      } else {
        _results += '❌ Session non trouvée dans Firestore\n\n';
      }

      _results += '3️⃣ Test notification agent...\n';
      setState(() {});

      // Tester la notification aux agents
      final result = await ConstatAgentNotificationService.envoyerConstatAuxAgents(
        sessionId: sessionId,
      );

      if (result['success'] == true) {
        _results += '✅ Notification agent réussie\n';
        _results += '📧 Agents notifiés: ${result['agentsNotifies'] ?? 0}\n';

        if (result['pdfUrl'] == pdfUrl) {
          _results += '✅ URL identique - pas de régénération\n';
        } else {
          _results += '⚠️ URL différente - PDF régénéré\n';
        }
      } else {
        _results += '❌ Erreur notification agent: ${result['error']}\n';
      }

    } catch (e) {
      _results += '❌ Erreur workflow: $e\n';
    }

    setState(() {
      _isLoading = false;
      _results += '\n';
    });
  }

  Future<void> _testCloudinarySignature() async {
    setState(() {
      _isLoading = true;
      _results += '🔐 Test Signature Cloudinary\n\n';
    });

    try {
      _results += '📋 Test avec un petit PDF...\n';
      setState(() {});

      // Créer un petit PDF de test
      final testPdfBytes = Uint8List.fromList([
        0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34, // %PDF-1.4
        0x0A, 0x25, 0xE2, 0xE3, 0xCF, 0xD3, 0x0A, // Header
        // Contenu minimal d'un PDF
      ]);

      final sessionId = 'test_signature_${DateTime.now().millisecondsSinceEpoch}';

      _results += '📤 Tentative upload vers Cloudinary...\n';
      setState(() {});

      final pdfUrl = await CloudinaryPdfService.uploadPdf(
        pdfBytes: testPdfBytes,
        fileName: 'test_signature.pdf',
        sessionId: sessionId,
        folder: 'test_signatures',
      );

      if (pdfUrl.contains('cloudinary.com')) {
        _results += '✅ Upload réussi vers Cloudinary !\n';
        _results += '🔗 URL: $pdfUrl\n';
        _results += '✅ Signature correcte\n';
      } else {
        _results += '❌ Upload échoué - signature incorrecte\n';
        _results += '📁 Fichier local: $pdfUrl\n';
      }

    } catch (e) {
      _results += '❌ Erreur test signature: $e\n';
      if (e.toString().contains('401')) {
        _results += '🔐 Erreur 401 = Signature invalide\n';
      } else if (e.toString().contains('403')) {
        _results += '🔐 Erreur 403 = Clés API invalides\n';
      }
    }

    setState(() {
      _isLoading = false;
      _results += '\n';
    });
  }

  Future<void> _testQuickSignature() async {
    setState(() {
      _isLoading = true;
      _results += '🔐 Test Signature Rapide\n\n';
    });

    try {
      final config = CloudinaryPdfService.testConfiguration();
      _results += '📋 Configuration:\n';
      _results += '   Cloud Name: ${config['cloudName']}\n';
      _results += '   API Key: ${config['apiKey']}\n';
      _results += '   Configuré: ${config['configured']}\n\n';

      _results += '🔐 Test signature avec paramètres corrects...\n';

      // Simuler les paramètres exacts
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final publicId = 'test_${DateTime.now().millisecondsSinceEpoch}';

      _results += '   Timestamp: $timestamp\n';
      _results += '   Public ID: $publicId\n';
      _results += '   Folder: test_signatures\n\n';

      // Créer un très petit PDF de test (1KB)
      final testPdfBytes = Uint8List.fromList(List.generate(1024, (i) => i % 256));

      _results += '📤 Test upload avec signature corrigée...\n';
      setState(() {});

      final pdfUrl = await CloudinaryPdfService.uploadPdf(
        pdfBytes: testPdfBytes,
        fileName: 'test_quick.pdf',
        sessionId: 'test_quick',
        folder: 'test_signatures',
      );

      if (pdfUrl.contains('cloudinary.com')) {
        _results += '✅ SUCCESS! Upload réussi vers Cloudinary\n';
        _results += '🔗 URL: $pdfUrl\n';
        _results += '🎉 Signature correcte maintenant!\n';
      } else {
        _results += '❌ Upload échoué - signature encore incorrecte\n';
      }

    } catch (e) {
      _results += '❌ Erreur: $e\n';
      if (e.toString().contains('Invalid Signature')) {
        _results += '🔐 Signature encore invalide - vérifier les paramètres\n';
      }
    }

    setState(() {
      _isLoading = false;
      _results += '\n';
    });
  }

  Future<void> _nettoyerEtRetester() async {
    setState(() {
      _isLoading = true;
      _results = '';
    });

    try {
      _results += '🧹 Nettoyage & Test Notifications\n';
      _results += '=' * 40 + '\n';
      setState(() {});

      // 1. Nettoyer les notifications existantes pour la session de test
      const sessionId = 'VOReABmLhZlIHKMtGdod'; // Session de test

      _results += '🧹 Nettoyage notifications pour session: $sessionId\n';
      setState(() {});

      final nettoyageResult = await ConstatAgentNotificationService.nettoyerNotificationsSession(sessionId);

      if (nettoyageResult['success'] == true) {
        _results += '✅ Nettoyage réussi:\n';
        _results += '   - Notifications supprimées: ${nettoyageResult['notificationsSupprimes']}\n';
        _results += '   - Constats supprimés: ${nettoyageResult['constatsSupprimes']}\n';
        _results += '   - Envois supprimés: ${nettoyageResult['envoisSupprimes']}\n\n';
      } else {
        _results += '❌ Erreur nettoyage: ${nettoyageResult['error']}\n\n';
      }
      setState(() {});

      // 2. Retester la notification
      _results += '📧 Test nouvelle notification...\n';
      setState(() {});

      final notificationResult = await ConstatAgentNotificationService.envoyerConstatAuxAgents(
        sessionId: sessionId,
      );

      if (notificationResult['success'] == true) {
        _results += '✅ Notification réussie:\n';
        _results += '   - Agents notifiés: ${notificationResult['notificationsReussies']}\n';
        _results += '   - Total agents: ${notificationResult['totalAgents']}\n';
        _results += '   - Échecs: ${notificationResult['notificationsEchouees']}\n';

        if (notificationResult['notificationsReussies'] > 0) {
          _results += '\n🎉 L\'agent devrait maintenant voir la notification!\n';
          _results += '👉 Connectez-vous en tant qu\'agent pour vérifier.\n';
        }
      } else {
        _results += '❌ Erreur notification: ${notificationResult['error']}\n';
      }

    } catch (e) {
      _results += '❌ ERREUR: $e\n';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
