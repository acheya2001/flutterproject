import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'cloudinary_pdf_service.dart';

/// 🔄 Service pour migrer les PDFs de Firebase Storage vers Cloudinary
class PdfMigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _tag = 'PdfMigration';

  /// 🔄 Migrer un PDF spécifique de Firebase vers Cloudinary
  static Future<String?> migratePdfToCloudinary({
    required String firebaseUrl,
    required String sessionId,
    String folder = 'constats_migres',
  }) async {
    try {
      print('🔄 [$_tag] Migration PDF: $firebaseUrl');

      // 1. Télécharger le PDF depuis Firebase Storage
      final pdfBytes = await _downloadPdfFromFirebase(firebaseUrl);
      if (pdfBytes == null) {
        print('❌ [$_tag] Impossible de télécharger le PDF depuis Firebase');
        return null;
      }

      // 2. Générer un nom de fichier
      final fileName = 'migrated_${sessionId}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // 3. Uploader vers Cloudinary
      final cloudinaryUrl = await CloudinaryPdfService.uploadPdf(
        pdfBytes: pdfBytes,
        fileName: fileName,
        sessionId: sessionId,
        folder: folder,
      );

      print('✅ [$_tag] PDF migré vers Cloudinary: $cloudinaryUrl');
      return cloudinaryUrl;

    } catch (e) {
      print('❌ [$_tag] Erreur migration PDF: $e');
      return null;
    }
  }

  /// 📥 Télécharger un PDF depuis Firebase Storage
  static Future<Uint8List?> _downloadPdfFromFirebase(String firebaseUrl) async {
    try {
      // Méthode 1: Via Firebase Storage Reference
      try {
        final ref = _storage.refFromURL(firebaseUrl);
        final data = await ref.getData();
        if (data != null) {
          print('✅ [$_tag] PDF téléchargé via Firebase Storage (${data.length} bytes)');
          return data;
        }
      } catch (e) {
        print('⚠️ [$_tag] Échec téléchargement Firebase Storage: $e');
      }

      // Méthode 2: Via HTTP direct
      try {
        final response = await http.get(Uri.parse(firebaseUrl));
        if (response.statusCode == 200) {
          print('✅ [$_tag] PDF téléchargé via HTTP (${response.bodyBytes.length} bytes)');
          return response.bodyBytes;
        }
      } catch (e) {
        print('⚠️ [$_tag] Échec téléchargement HTTP: $e');
      }

      return null;
    } catch (e) {
      print('❌ [$_tag] Erreur téléchargement PDF: $e');
      return null;
    }
  }

  /// 🔄 Migrer tous les PDFs d'une session vers Cloudinary
  static Future<Map<String, dynamic>> migrateSessionPdfs(String sessionId) async {
    try {
      print('🔄 [$_tag] Migration des PDFs de la session: $sessionId');

      final results = <String, dynamic>{
        'success': false,
        'migratedUrls': <String>[],
        'errors': <String>[],
      };

      // 1. Vérifier le PDF principal de la session
      final sessionDoc = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .get();

      if (sessionDoc.exists) {
        final sessionData = sessionDoc.data()!;
        final pdfUrl = sessionData['pdfUrl'] as String?;

        if (pdfUrl != null && 
            pdfUrl.isNotEmpty && 
            pdfUrl.contains('firebasestorage.googleapis.com')) {
          
          print('📄 [$_tag] Migration du PDF principal...');
          final cloudinaryUrl = await migratePdfToCloudinary(
            firebaseUrl: pdfUrl,
            sessionId: sessionId,
            folder: 'constats_principaux',
          );

          if (cloudinaryUrl != null) {
            // Mettre à jour l'URL dans la session
            await _firestore
                .collection('sessions_collaboratives')
                .doc(sessionId)
                .update({'pdfUrl': cloudinaryUrl});

            results['migratedUrls'].add(cloudinaryUrl);
            print('✅ [$_tag] PDF principal migré et mis à jour');
          } else {
            results['errors'].add('Échec migration PDF principal');
          }
        }
      }

      // 2. Vérifier les PDFs dans constat_pdfs
      final constatsQuery = await _firestore
          .collection('constat_pdfs')
          .where('sessionId', isEqualTo: sessionId)
          .get();

      for (final doc in constatsQuery.docs) {
        final data = doc.data();
        final downloadUrl = data['downloadUrl'] as String?;

        if (downloadUrl != null && 
            downloadUrl.isNotEmpty && 
            downloadUrl.contains('firebasestorage.googleapis.com')) {
          
          print('📄 [$_tag] Migration PDF constat_pdfs: ${doc.id}');
          final cloudinaryUrl = await migratePdfToCloudinary(
            firebaseUrl: downloadUrl,
            sessionId: sessionId,
            folder: 'constats_metadata',
          );

          if (cloudinaryUrl != null) {
            // Mettre à jour l'URL dans constat_pdfs
            await doc.reference.update({'downloadUrl': cloudinaryUrl});
            results['migratedUrls'].add(cloudinaryUrl);
            print('✅ [$_tag] PDF constat_pdfs migré: ${doc.id}');
          } else {
            results['errors'].add('Échec migration PDF ${doc.id}');
          }
        }
      }

      results['success'] = results['errors'].isEmpty;
      print('🎉 [$_tag] Migration terminée: ${results['migratedUrls'].length} PDFs migrés');
      
      return results;

    } catch (e) {
      print('❌ [$_tag] Erreur migration session: $e');
      return {
        'success': false,
        'migratedUrls': <String>[],
        'errors': [e.toString()],
      };
    }
  }

  /// 🔍 Analyser les PDFs Firebase Storage dans le système
  static Future<Map<String, dynamic>> analyzeFirebasePdfs() async {
    try {
      print('🔍 [$_tag] Analyse des PDFs Firebase Storage...');

      final analysis = <String, dynamic>{
        'totalSessions': 0,
        'sessionsWithFirebasePdfs': 0,
        'totalFirebasePdfs': 0,
        'firebasePdfUrls': <String>[],
      };

      // Analyser les sessions collaboratives
      final sessionsQuery = await _firestore
          .collection('sessions_collaboratives')
          .get();

      analysis['totalSessions'] = sessionsQuery.docs.length;

      for (final doc in sessionsQuery.docs) {
        final data = doc.data();
        final pdfUrl = data['pdfUrl'] as String?;

        if (pdfUrl != null && 
            pdfUrl.isNotEmpty && 
            pdfUrl.contains('firebasestorage.googleapis.com')) {
          
          analysis['sessionsWithFirebasePdfs']++;
          analysis['totalFirebasePdfs']++;
          analysis['firebasePdfUrls'].add(pdfUrl);
        }
      }

      // Analyser constat_pdfs
      final constatsQuery = await _firestore
          .collection('constat_pdfs')
          .get();

      for (final doc in constatsQuery.docs) {
        final data = doc.data();
        final downloadUrl = data['downloadUrl'] as String?;

        if (downloadUrl != null && 
            downloadUrl.isNotEmpty && 
            downloadUrl.contains('firebasestorage.googleapis.com')) {
          
          analysis['totalFirebasePdfs']++;
          analysis['firebasePdfUrls'].add(downloadUrl);
        }
      }

      print('📊 [$_tag] Analyse terminée:');
      print('   - Sessions totales: ${analysis['totalSessions']}');
      print('   - Sessions avec PDFs Firebase: ${analysis['sessionsWithFirebasePdfs']}');
      print('   - PDFs Firebase totaux: ${analysis['totalFirebasePdfs']}');

      return analysis;

    } catch (e) {
      print('❌ [$_tag] Erreur analyse: $e');
      return {
        'error': e.toString(),
      };
    }
  }

  /// 🔄 Migration en lot de tous les PDFs Firebase vers Cloudinary
  static Future<Map<String, dynamic>> migrateAllFirebasePdfs() async {
    try {
      print('🔄 [$_tag] Début migration en lot...');

      final results = <String, dynamic>{
        'success': false,
        'totalProcessed': 0,
        'totalMigrated': 0,
        'errors': <String>[],
      };

      // Obtenir toutes les sessions avec des PDFs Firebase
      final sessionsQuery = await _firestore
          .collection('sessions_collaboratives')
          .where('pdfUrl', isGreaterThan: '')
          .get();

      for (final doc in sessionsQuery.docs) {
        final data = doc.data();
        final pdfUrl = data['pdfUrl'] as String?;

        if (pdfUrl != null && 
            pdfUrl.contains('firebasestorage.googleapis.com')) {
          
          results['totalProcessed']++;
          
          final migrationResult = await migrateSessionPdfs(doc.id);
          if (migrationResult['success'] == true) {
            results['totalMigrated'] += migrationResult['migratedUrls'].length;
          } else {
            results['errors'].addAll(migrationResult['errors']);
          }
        }
      }

      results['success'] = results['errors'].isEmpty;
      print('🎉 [$_tag] Migration en lot terminée:');
      print('   - Sessions traitées: ${results['totalProcessed']}');
      print('   - PDFs migrés: ${results['totalMigrated']}');
      print('   - Erreurs: ${results['errors'].length}');

      return results;

    } catch (e) {
      print('❌ [$_tag] Erreur migration en lot: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
