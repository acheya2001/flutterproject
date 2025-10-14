import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'services/firebase_pdf_upload_service.dart';

/// 🧪 Page de test pour l'upload PDF vers Firebase Storage
class TestFirebasePdfPage extends StatefulWidget {
  const TestFirebasePdfPage({Key? key}) : super(key: key);

  @override
  State<TestFirebasePdfPage> createState() => _TestFirebasePdfPageState();
}

class _TestFirebasePdfPageState extends State<TestFirebasePdfPage> {
  String _resultat = '';
  bool _isLoading = false;

  /// 🧪 Test d'upload d'un PDF simple vers Firebase Storage
  Future<void> _testFirebaseUpload() async {
    setState(() {
      _isLoading = true;
      _resultat = '🔄 Test en cours...';
    });

    try {
      // Créer un PDF de test simple
      final pdfBytes = await _creerPdfTest();
      
      print('🧪 [TEST] Début test upload Firebase Storage...');
      print('🧪 [TEST] Taille PDF test: ${pdfBytes.length} bytes');

      // Tester l'upload vers Firebase Storage
      final url = await FirebasePdfUploadService.uploadPdf(
        pdfBytes: pdfBytes,
        fileName: 'test_pdf_${DateTime.now().millisecondsSinceEpoch}.pdf',
        sessionId: 'TEST_SESSION_${DateTime.now().millisecondsSinceEpoch}',
        folder: 'test_pdfs',
      );

      setState(() {
        _resultat = '''✅ Test Firebase Storage RÉUSSI !

📤 PDF uploadé avec succès
🔗 URL: $url

📊 Détails:
- Taille: ${pdfBytes.length} bytes
- Service: Firebase Storage
- Statut: ✅ Succès''';
      });

      print('✅ [TEST] Upload Firebase réussi: $url');

    } catch (e) {
      setState(() {
        _resultat = '''❌ Test Firebase Storage ÉCHOUÉ !

🚨 Erreur: $e

📊 Détails:
- Service: Firebase Storage
- Statut: ❌ Échec''';
      });

      print('❌ [TEST] Erreur upload Firebase: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 📄 Créer un PDF de test simple
  Future<Uint8List> _creerPdfTest() async {
    // Simuler un PDF simple (en réalité, on devrait utiliser le package pdf)
    // Pour ce test, on crée juste des données binaires qui ressemblent à un PDF
    final String pdfContent = '''%PDF-1.4
1 0 obj
<<
/Type /Catalog
/Pages 2 0 R
>>
endobj

2 0 obj
<<
/Type /Pages
/Kids [3 0 R]
/Count 1
>>
endobj

3 0 obj
<<
/Type /Page
/Parent 2 0 R
/MediaBox [0 0 612 792]
/Contents 4 0 R
>>
endobj

4 0 obj
<<
/Length 44
>>
stream
BT
/F1 12 Tf
100 700 Td
(Test PDF Firebase) Tj
ET
endstream
endobj

xref
0 5
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000206 00000 n 
trailer
<<
/Size 5
/Root 1 0 R
>>
startxref
300
%%EOF''';

    return Uint8List.fromList(pdfContent.codeUnits);
  }

  /// 🧪 Test de récupération d'URL
  Future<void> _testGetUrl() async {
    setState(() {
      _isLoading = true;
      _resultat = '🔄 Test récupération URL...';
    });

    try {
      final url = await FirebasePdfUploadService.getPdfUrl('TEST_SESSION_123');
      
      setState(() {
        _resultat = url != null 
          ? '✅ URL trouvée: $url'
          : '⚠️ Aucune URL trouvée pour cette session';
      });

    } catch (e) {
      setState(() {
        _resultat = '❌ Erreur récupération URL: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Test Firebase PDF'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Titre
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.cloud_upload, size: 48, color: Colors.blue[600]),
                    const SizedBox(height: 8),
                    const Text(
                      'Test Firebase Storage PDF',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vérification du service d\'upload PDF',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Boutons de test
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testFirebaseUpload,
              icon: _isLoading 
                ? const SizedBox(
                    width: 16, 
                    height: 16, 
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file),
              label: const Text('🧪 Test Upload Firebase'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testGetUrl,
              icon: const Icon(Icons.link),
              label: const Text('🔍 Test Récupération URL'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 20),

            // Résultats
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.assessment, color: Colors.blue[600]),
                          const SizedBox(width: 8),
                          const Text(
                            'Résultats du Test',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _resultat.isEmpty ? '🔄 Aucun test effectué' : _resultat,
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                        ),
                      ),
                      if (_resultat.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _resultat));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Résultats copiés'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copier'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
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
}
