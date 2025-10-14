import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'dart:math';
import 'constat_pdf_service.dart';

/// 🧪 Service de test pour l'envoi de PDF de constat aux agents
class TestEnvoiPdfService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🧪 Tester l'envoi de PDF complet
  static Future<Map<String, dynamic>> testEnvoiPdfComplet() async {
    try {
      debugPrint('[TEST_ENVOI_PDF] 🧪 Début du test complet');

      final results = <String, dynamic>{
        'success': true,
        'steps': <String, dynamic>{},
        'errors': <String>[],
      };

      // 1. Créer des données de test
      final testData = await _createTestData();
      results['steps']['createTestData'] = {
        'success': true,
        'message': 'Données de test créées',
        'data': testData,
      };

      // 2. Créer un PDF de test
      final pdfBytes = await _createTestPdf();
      results['steps']['createTestPdf'] = {
        'success': true,
        'message': 'PDF de test créé (${pdfBytes.length} bytes)',
      };

      // 3. Tester l'envoi du PDF
      final envoyResult = await ConstatPdfService.sendConstatPdfToAgent(
        sinistreId: testData['sinistreId'],
        pdfBytes: pdfBytes,
        fileName: 'test_constat_${DateTime.now().millisecondsSinceEpoch}.pdf',
        message: 'Test d\'envoi automatique de PDF de constat',
      );

      if (envoyResult['success']) {
        results['steps']['sendPdf'] = {
          'success': true,
          'message': 'PDF envoyé avec succès',
          'envoiId': envoyResult['envoiId'],
          'agentInfo': envoyResult['agentInfo'],
        };
      } else {
        results['steps']['sendPdf'] = {
          'success': false,
          'message': 'Échec envoi PDF: ${envoyResult['error']}',
        };
        results['errors'].add('Échec envoi PDF: ${envoyResult['error']}');
        results['success'] = false;
      }

      // 4. Vérifier la réception côté agent
      if (envoyResult['success']) {
        final agentId = envoyResult['agentInfo']['id'];
        final envoisAgent = await ConstatPdfService.getEnvoisForAgent(agentId);
        
        final envoiTrouve = envoisAgent.any((envoi) => envoi['id'] == envoyResult['envoiId']);
        
        results['steps']['verifyAgentReception'] = {
          'success': envoiTrouve,
          'message': envoiTrouve 
              ? 'Envoi trouvé côté agent (${envoisAgent.length} envois total)'
              : 'Envoi non trouvé côté agent',
        };

        if (!envoiTrouve) {
          results['errors'].add('Envoi non trouvé côté agent');
          results['success'] = false;
        }
      }

      // 5. Vérifier la réception côté conducteur
      if (envoyResult['success']) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final envoisConducteur = await ConstatPdfService.getEnvoisForConducteur(user.uid);
          
          final envoiTrouve = envoisConducteur.any((envoi) => envoi['id'] == envoyResult['envoiId']);
          
          results['steps']['verifyConducteurReception'] = {
            'success': envoiTrouve,
            'message': envoiTrouve 
                ? 'Envoi trouvé côté conducteur (${envoisConducteur.length} envois total)'
                : 'Envoi non trouvé côté conducteur',
          };

          if (!envoiTrouve) {
            results['errors'].add('Envoi non trouvé côté conducteur');
            results['success'] = false;
          }
        }
      }

      debugPrint('[TEST_ENVOI_PDF] ${results['success'] ? '✅' : '❌'} Test terminé');
      return results;

    } catch (e) {
      debugPrint('[TEST_ENVOI_PDF] ❌ Erreur test: $e');
      return {
        'success': false,
        'error': e.toString(),
        'steps': {},
        'errors': [e.toString()],
      };
    }
  }

  /// 📋 Créer des données de test
  static Future<Map<String, dynamic>> _createTestData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non authentifié');
    }

    // Récupérer les données utilisateur
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      throw Exception('Données utilisateur non trouvées');
    }

    final userData = userDoc.data()!;
    final agenceId = userData['agenceId'];
    final compagnieId = userData['compagnieId'];

    if (agenceId == null || compagnieId == null) {
      throw Exception('AgenceId ou CompagnieId manquant pour l\'utilisateur');
    }

    // Créer un sinistre de test
    final sinistreId = _firestore.collection('sinistres').doc().id;
    final sinistreData = {
      'id': sinistreId,
      'numeroSinistre': 'TEST-${DateTime.now().millisecondsSinceEpoch}',
      'conducteurId': user.uid,
      'agenceId': agenceId,
      'compagnieId': compagnieId,
      'typeAccident': 'Collision',
      'dateAccident': Timestamp.now(),
      'lieuAccident': 'Avenue Habib Bourguiba, Tunis',
      'statut': 'ouvert',
      'statutConstat': 'en_attente',
      'dateDeclaration': FieldValue.serverTimestamp(),
      'isFakeData': true, // Marquer comme données de test
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('sinistres').doc(sinistreId).set(sinistreData);

    return {
      'sinistreId': sinistreId,
      'agenceId': agenceId,
      'compagnieId': compagnieId,
      'conducteurId': user.uid,
    };
  }

  /// 📄 Créer un PDF de test
  static Future<Uint8List> _createTestPdf() async {
    // Créer un PDF simple pour le test
    final content = '''
%PDF-1.4
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
(Test PDF Constat) Tj
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
%%EOF
''';

    return Uint8List.fromList(content.codeUnits);
  }

  /// 🧹 Nettoyer les données de test
  static Future<void> cleanupTestData() async {
    try {
      debugPrint('[TEST_ENVOI_PDF] 🧹 Nettoyage des données de test');

      // Supprimer les sinistres de test
      final sinistresQuery = await _firestore
          .collection('sinistres')
          .where('isFakeData', isEqualTo: true)
          .get();

      for (final doc in sinistresQuery.docs) {
        await doc.reference.delete();
      }

      // Supprimer les envois de test
      final envoisQuery = await _firestore
          .collection('envois_constats')
          .get();

      for (final doc in envoisQuery.docs) {
        final data = doc.data();
        if (data['sinistreInfo']?['numeroSinistre']?.toString().startsWith('TEST-') == true) {
          await doc.reference.delete();
        }
      }

      debugPrint('[TEST_ENVOI_PDF] ✅ Nettoyage terminé');
    } catch (e) {
      debugPrint('[TEST_ENVOI_PDF] ❌ Erreur nettoyage: $e');
    }
  }

  /// 📊 Obtenir un rapport des données de test
  static Future<Map<String, dynamic>> getTestReport() async {
    try {
      final report = <String, dynamic>{};

      // Compter les sinistres de test
      final sinistresQuery = await _firestore
          .collection('sinistres')
          .where('isFakeData', isEqualTo: true)
          .get();
      
      report['sinistres_test'] = {
        'count': sinistresQuery.docs.length,
        'documents': sinistresQuery.docs.map((doc) => {
          'id': doc.id,
          'numeroSinistre': doc.data()['numeroSinistre'],
        }).toList(),
      };

      // Compter les envois de test
      final envoisQuery = await _firestore
          .collection('envois_constats')
          .get();

      final envoisTest = envoisQuery.docs.where((doc) {
        final data = doc.data();
        return data['sinistreInfo']?['numeroSinistre']?.toString().startsWith('TEST-') == true;
      }).toList();

      report['envois_test'] = {
        'count': envoisTest.length,
        'documents': envoisTest.map((doc) => {
          'id': doc.id,
          'fileName': doc.data()['fileName'],
          'statut': doc.data()['statut'],
        }).toList(),
      };

      return report;
    } catch (e) {
      debugPrint('[TEST_ENVOI_PDF] ❌ Erreur rapport: $e');
      return {'error': e.toString()};
    }
  }
}
