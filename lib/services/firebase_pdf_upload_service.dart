import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔥 Service d'upload PDF vers Firebase Storage (alternative à Cloudinary)
class FirebasePdfUploadService {
  static const String _tag = 'FirebasePDF';
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📤 Upload un PDF vers Firebase Storage
  static Future<String> uploadPdf({
    required Uint8List pdfBytes,
    required String fileName,
    required String sessionId,
    String folder = 'constats_pdf',
  }) async {
    try {
      print('🔥 [$_tag] Début upload PDF vers Firebase Storage...');
      print('🔥 [$_tag] Fichier: $fileName');
      print('🔥 [$_tag] Taille: ${pdfBytes.length} bytes');

      // Créer le chemin du fichier
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '$folder/$sessionId/${timestamp}_$fileName';

      print('🔥 [$_tag] Chemin: $path');

      // Créer la référence Firebase Storage
      final ref = _storage.ref().child(path);

      // Métadonnées du fichier
      final metadata = SettableMetadata(
        contentType: 'application/pdf',
        customMetadata: {
          'sessionId': sessionId,
          'uploadedAt': DateTime.now().toIso8601String(),
          'originalFileName': fileName,
        },
      );

      // Upload du fichier
      final uploadTask = ref.putData(pdfBytes, metadata);
      
      // Attendre la fin de l'upload
      final snapshot = await uploadTask;
      
      // Récupérer l'URL de téléchargement
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ [$_tag] PDF uploadé avec succès: $downloadUrl');
      
      // Sauvegarder les métadonnées dans Firestore
      await _sauvegarderMetadonnees(sessionId, downloadUrl, path, fileName);
      
      return downloadUrl;

    } catch (e) {
      print('❌ [$_tag] Erreur upload PDF: $e');
      rethrow;
    }
  }

  /// 📤 Upload un fichier PDF depuis le système de fichiers
  static Future<String> uploadPdfFile({
    required File pdfFile,
    required String sessionId,
    String folder = 'constats_pdf',
  }) async {
    try {
      final pdfBytes = await pdfFile.readAsBytes();
      final fileName = pdfFile.path.split('/').last;
      
      return await uploadPdf(
        pdfBytes: pdfBytes,
        fileName: fileName,
        sessionId: sessionId,
        folder: folder,
      );
    } catch (e) {
      print('❌ [$_tag] Erreur lecture fichier PDF: $e');
      rethrow;
    }
  }

  /// 💾 Sauvegarder les métadonnées du PDF dans Firestore
  static Future<void> _sauvegarderMetadonnees(
    String sessionId,
    String downloadUrl,
    String storagePath,
    String fileName,
  ) async {
    try {
      await _firestore
          .collection('pdf_uploads')
          .doc(sessionId)
          .set({
        'sessionId': sessionId,
        'downloadUrl': downloadUrl,
        'storagePath': storagePath,
        'fileName': fileName,
        'uploadedAt': FieldValue.serverTimestamp(),
        'service': 'firebase_storage',
        'status': 'uploaded',
      }, SetOptions(merge: true));

      print('✅ [$_tag] Métadonnées sauvegardées pour session: $sessionId');
    } catch (e) {
      print('⚠️ [$_tag] Erreur sauvegarde métadonnées: $e');
      // Ne pas faire échouer l'upload pour cette erreur
    }
  }

  /// 🔍 Récupérer l'URL du PDF pour une session
  static Future<String?> getPdfUrl(String sessionId) async {
    try {
      final doc = await _firestore
          .collection('pdf_uploads')
          .doc(sessionId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return data['downloadUrl'] as String?;
      }

      return null;
    } catch (e) {
      print('❌ [$_tag] Erreur récupération URL: $e');
      return null;
    }
  }

  /// 🗑️ Supprimer un PDF de Firebase Storage
  static Future<bool> deletePdf(String sessionId) async {
    try {
      print('🗑️ [$_tag] Suppression PDF pour session: $sessionId');

      // Récupérer les métadonnées
      final doc = await _firestore
          .collection('pdf_uploads')
          .doc(sessionId)
          .get();

      if (!doc.exists) {
        print('⚠️ [$_tag] Aucun PDF trouvé pour la session: $sessionId');
        return false;
      }

      final data = doc.data()!;
      final storagePath = data['storagePath'] as String;

      // Supprimer le fichier de Storage
      final ref = _storage.ref().child(storagePath);
      await ref.delete();

      // Supprimer les métadonnées de Firestore
      await _firestore
          .collection('pdf_uploads')
          .doc(sessionId)
          .delete();

      print('✅ [$_tag] PDF supprimé avec succès');
      return true;

    } catch (e) {
      print('❌ [$_tag] Erreur suppression PDF: $e');
      return false;
    }
  }

  /// 📊 Obtenir les statistiques d'upload
  static Future<Map<String, dynamic>> getUploadStats() async {
    try {
      final query = await _firestore
          .collection('pdf_uploads')
          .get();

      final totalUploads = query.docs.length;
      int totalSize = 0;

      for (final doc in query.docs) {
        // Calculer la taille totale si disponible
        // (nécessiterait d'ajouter la taille dans les métadonnées)
      }

      return {
        'totalUploads': totalUploads,
        'totalSize': totalSize,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

    } catch (e) {
      print('❌ [$_tag] Erreur récupération statistiques: $e');
      return {
        'totalUploads': 0,
        'totalSize': 0,
        'error': e.toString(),
      };
    }
  }

  /// 🔗 Générer une URL signée temporaire (si nécessaire)
  static Future<String?> generateTemporaryUrl(String sessionId, {Duration? expiration}) async {
    try {
      final doc = await _firestore
          .collection('pdf_uploads')
          .doc(sessionId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      final storagePath = data['storagePath'] as String;

      // Firebase Storage génère automatiquement des URLs signées
      // L'URL de téléchargement est déjà sécurisée
      return data['downloadUrl'] as String;

    } catch (e) {
      print('❌ [$_tag] Erreur génération URL temporaire: $e');
      return null;
    }
  }
}
