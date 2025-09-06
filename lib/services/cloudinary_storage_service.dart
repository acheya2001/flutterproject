import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/config/app_config.dart';
import '../core/services/logging_service.dart';
import '../core/exceptions/app_exceptions.dart';

/// 🌐 Service de stockage Cloudinary sécurisé (GRATUIT - 25GB/mois)
class CloudinaryStorageService {
  static const String _tag = 'CloudinaryStorage';

  /// 📤 Upload d'image vers Cloudinary avec gestion d'erreurs robuste
  static Future<String?> uploadImage({
    required File imageFile,
    required String folder,
    String? publicId,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Vérifier la configuration
      if (!AppConfig.isInitialized) {
        throw const StorageException(
          'Configuration non initialisée',
          code: 'config-not-initialized',
        );
      }

      // Vérifier que le fichier existe
      if (!await imageFile.exists()) {
        throw StorageException(
          'Fichier non trouvé: ${imageFile.path}',
          code: 'file-not-found',
        );
      }

      // Vérifier la taille du fichier (limite: 10MB)
      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw const StorageException(
          'Fichier trop volumineux (max: 10MB)',
          code: 'file-too-large',
        );
      }

      LoggingService.storage(_tag, 'upload_start', fileName: imageFile.path.split('/').last, fileSize: fileSize);

      // Générer signature et timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final signature = _generateSignature(timestamp, folder, publicId);

      // Préparer la requête multipart
      final request = http.MultipartRequest('POST', Uri.parse(AppConfig.cloudinaryUploadUrl));
      
      // Ajouter les paramètres
      request.fields.addAll({
        'api_key': AppConfig.cloudinaryApiKey,
        'timestamp': timestamp,
        'signature': signature,
        'folder': folder,
        if (publicId != null) 'public_id': publicId,
        'resource_type': 'image',
        'quality': 'auto:good', // Optimisation automatique
        'fetch_format': 'auto', // Format optimal
      });

      // Ajouter le fichier
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Envoyer la requête avec timeout
      final response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw const StorageException(
          'Timeout lors de l\'upload',
          code: 'upload-timeout',
        ),
      );

      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        final imageUrl = jsonResponse['secure_url'] as String;
        
        stopwatch.stop();
        LoggingService.performance(_tag, 'upload_success', stopwatch.elapsed, {
          'file_size': fileSize,
          'folder': folder,
        });
        LoggingService.storage(_tag, 'upload_complete', fileName: imageFile.path.split('/').last, success: true);
        
        return imageUrl;
      } else {
        throw StorageException(
          'Erreur HTTP ${response.statusCode}',
          code: 'http-error-${response.statusCode}',
          originalError: responseData,
        );
      }
    } on StorageException {
      rethrow;
    } catch (e, stackTrace) {
      stopwatch.stop();
      final exception = StorageException(
        'Erreur upload Cloudinary: $e',
        code: 'upload-failed',
        originalError: e,
        stackTrace: stackTrace,
      );
      
      LoggingService.exception(_tag, exception, stackTrace);
      LoggingService.storage(_tag, 'upload_failed', fileName: imageFile.path.split('/').last, success: false);
      
      throw exception;
    }
  }

  /// 🔐 Générer signature pour Cloudinary
  static String _generateSignature(String timestamp, String folder, String? publicId) {
    final params = <String, String>{
      'timestamp': timestamp,
      'folder': folder,
      if (publicId != null) 'public_id': publicId,
    };

    // Trier les paramètres par clé
    final sortedKeys = params.keys.toList()..sort();
    final paramString = sortedKeys
        .map((key) => '$key=${params[key]}')
        .join('&');

    // Ajouter le secret
    final stringToSign = '$paramString${AppConfig.cloudinaryApiSecret}';

    // Générer SHA1
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    
    return digest.toString();
  }

  /// 🗑️ Supprimer une image de Cloudinary avec gestion d'erreurs
  static Future<bool> deleteImage(String publicId) async {
    try {
      LoggingService.storage(_tag, 'delete_start', fileName: publicId);

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final signature = _generateDeleteSignature(timestamp, publicId);

      final response = await http.post(
        Uri.parse(AppConfig.cloudinaryDestroyUrl),
        body: {
          'api_key': AppConfig.cloudinaryApiKey,
          'timestamp': timestamp,
          'signature': signature,
          'public_id': publicId,
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw const StorageException(
          'Timeout lors de la suppression',
          code: 'delete-timeout',
        ),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final success = jsonResponse['result'] == 'ok';
        
        LoggingService.storage(_tag, 'delete_complete', fileName: publicId, success: success);
        return success;
      } else {
        throw StorageException(
          'Erreur HTTP ${response.statusCode}',
          code: 'http-error-${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      final exception = StorageException(
        'Erreur suppression Cloudinary: $e',
        code: 'delete-failed',
        originalError: e,
        stackTrace: stackTrace,
      );
      
      LoggingService.exception(_tag, exception, stackTrace);
      LoggingService.storage(_tag, 'delete_failed', fileName: publicId, success: false);
      
      throw exception;
    }
  }

  static String _generateDeleteSignature(String timestamp, String publicId) {
    final stringToSign = 'public_id=$publicId&timestamp=$timestamp${AppConfig.cloudinaryApiSecret}';
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }
}

/// 📱 Service de stockage local (fallback)
class LocalStorageService {
  /// 💾 Sauvegarder localement
  static Future<String?> saveImageLocally({
    required File imageFile,
    required String folder,
    required String fileName,
  }) async {
    try {
      // Utiliser le stockage de l'application
      final directory = await getApplicationDocumentsDirectory();
      final localDir = Directory('${directory.path}/$folder');
      
      if (!await localDir.exists()) {
        await localDir.create(recursive: true);
      }

      final localFile = File('${localDir.path}/$fileName');
      await imageFile.copy(localFile.path);

      debugPrint('💾 Image sauvée localement: ${localFile.path}');
      return localFile.path;
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde locale: $e');
      return null;
    }
  }

  /// 📂 Lister les images locales
  static Future<List<String>> getLocalImages(String folder) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final localDir = Directory('${directory.path}/$folder');
      
      if (!await localDir.exists()) {
        return [];
      }

      final files = await localDir.list().toList();
      return files
          .where((file) => file is File)
          .map((file) => file.path)
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur lecture locale: $e');
      return [];
    }
  }
}

/// 🔄 Service hybride intelligent avec gestion d'erreurs robuste
class HybridStorageService {
  static const String _tag = 'HybridStorage';

  /// 📤 Upload intelligent avec fallback et gestion d'erreurs
  static Future<Map<String, dynamic>> uploadImage({
    required File imageFile,
    required String vehiculeId,
    required String type, // 'carte_grise', 'permis', etc.
  }) async {
    final folder = 'vehicules/$vehiculeId';
    final fileName = '${type}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    try {
      LoggingService.storage(_tag, 'hybrid_upload_start', fileName: fileName);

      // Tentative Cloudinary d'abord
      try {
        LoggingService.info(_tag, 'Tentative upload Cloudinary pour $type');
        final cloudinaryUrl = await CloudinaryStorageService.uploadImage(
          imageFile: imageFile,
          folder: folder,
          publicId: '${vehiculeId}_$type',
        );

        if (cloudinaryUrl != null) {
          LoggingService.storage(_tag, 'cloudinary_upload_success', fileName: fileName, success: true);
          return {
            'success': true,
            'url': cloudinaryUrl,
            'storage': 'cloudinary',
            'message': 'Image uploadée sur Cloudinary',
          };
        }
      } on StorageException catch (e) {
        LoggingService.warning(_tag, 'Cloudinary upload failed, trying local fallback: ${e.message}');
        // Continue vers le fallback local
      }

      // Fallback vers stockage local
      LoggingService.info(_tag, 'Fallback vers stockage local pour $type');
      try {
        final localPath = await LocalStorageService.saveImageLocally(
          imageFile: imageFile,
          folder: folder,
          fileName: fileName,
        );

        if (localPath != null) {
          // Marquer pour upload ultérieur
          await _markForLaterUpload(vehiculeId, type, localPath);
          
          LoggingService.storage(_tag, 'local_storage_success', fileName: fileName, success: true);
          return {
            'success': true,
            'url': localPath,
            'storage': 'local',
            'message': 'Image sauvée localement (sera uploadée plus tard)',
          };
        }
      } catch (e) {
        LoggingService.error(_tag, 'Local storage failed: $e');
      }

      // Échec complet
      const exception = StorageException(
        'Échec de sauvegarde sur tous les services',
        code: 'all-storage-failed',
      );
      LoggingService.exception(_tag, exception);
      
      return {
        'success': false,
        'message': exception.userMessage,
        'error': exception.message,
      };
    } catch (e, stackTrace) {
      final exception = StorageException(
        'Erreur upload hybride: $e',
        code: 'hybrid-upload-failed',
        originalError: e,
        stackTrace: stackTrace,
      );
      
      LoggingService.exception(_tag, exception, stackTrace);
      
      return {
        'success': false,
        'error': exception.message,
        'message': exception.userMessage,
      };
    }
  }

  /// 📝 Marquer pour upload ultérieur
  static Future<void> _markForLaterUpload(String vehiculeId, String type, String localPath) async {
    try {
      await FirebaseFirestore.instance.collection('pending_uploads').add({
        'vehiculeId': vehiculeId,
        'type': type,
        'localPath': localPath,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'storage': 'local',
      });
    } catch (e) {
      debugPrint('❌ Erreur marquage upload: $e');
    }
  }

  /// 🔄 Synchroniser les uploads en attente
  static Future<void> syncPendingUploads() async {
    try {
      final pendingSnapshot = await FirebaseFirestore.instance
          .collection('pending_uploads')
          .where('status', isEqualTo: 'pending')
          .limit(10)
          .get();

      for (final doc in pendingSnapshot.docs) {
        final data = doc.data();
        final localPath = data['localPath'] as String;
        final vehiculeId = data['vehiculeId'] as String;
        final type = data['type'] as String;

        final file = File(localPath);
        if (await file.exists()) {
          final result = await CloudinaryStorageService.uploadImage(
            imageFile: file,
            folder: 'vehicules/$vehiculeId',
            publicId: '${vehiculeId}_$type',
          );

          if (result != null) {
            // Mettre à jour le véhicule avec la nouvelle URL
            await FirebaseFirestore.instance
                .collection('vehicules')
                .doc(vehiculeId)
                .update({
              '${type}Url': result,
              '${type}LocalPath': FieldValue.delete(),
              '${type}PendingUpload': FieldValue.delete(),
            });

            // Marquer comme synchronisé
            await doc.reference.update({
              'status': 'synced',
              'cloudinaryUrl': result,
              'syncedAt': FieldValue.serverTimestamp(),
            });

            // Supprimer le fichier local
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur synchronisation: $e');
    }
  }
}