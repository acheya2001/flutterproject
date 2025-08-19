import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🌐 Service de stockage Cloudinary (GRATUIT - 25GB/mois)
class CloudinaryStorageService {
  // Configuration Cloudinary (GRATUIT)
  static const String _cloudName = 'dgw530dou'; 
  static const String _apiKey = '238965196817439'; 
  static const String _apiSecret = 'UEjPyY-6993xQnAhz8RCvgMYYLM'; 
  static const String _uploadUrl = 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// 📤 Upload d'image vers Cloudinary
  static Future<String?> uploadImage({
    required File imageFile,
    required String folder,
    String? publicId,
  }) async {
    try {
      debugPrint('🌐 Upload Cloudinary: ${imageFile.path}');

      // Générer signature et timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final signature = _generateSignature(timestamp, folder, publicId);

      // Préparer la requête multipart
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      
      // Ajouter les paramètres
      request.fields.addAll({
        'api_key': _apiKey,
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

      // Envoyer la requête
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        final imageUrl = jsonResponse['secure_url'] as String;
        
        debugPrint('✅ Image uploadée: $imageUrl');
        return imageUrl;
      } else {
        debugPrint('❌ Erreur Cloudinary: ${response.statusCode}');
        debugPrint('Response: $responseData');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Erreur upload Cloudinary: $e');
      return null;
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
    final stringToSign = '$paramString$_apiSecret';

    // Générer SHA1
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    
    return digest.toString();
  }

  /// 🗑️ Supprimer une image de Cloudinary
  static Future<bool> deleteImage(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final signature = _generateDeleteSignature(timestamp, publicId);

      final response = await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/destroy'),
        body: {
          'api_key': _apiKey,
          'timestamp': timestamp,
          'signature': signature,
          'public_id': publicId,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['result'] == 'ok';
      }
      return false;
    } catch (e) {
      debugPrint('❌ Erreur suppression Cloudinary: $e');
      return false;
    }
  }

  static String _generateDeleteSignature(String timestamp, String publicId) {
    final stringToSign = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
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

/// 🔄 Service hybride intelligent
class HybridStorageService {
  /// 📤 Upload intelligent avec fallback
  static Future<Map<String, dynamic>> uploadImage({
    required File imageFile,
    required String vehiculeId,
    required String type, // 'carte_grise', 'permis', etc.
  }) async {
    final folder = 'vehicules/$vehiculeId';
    final fileName = '${type}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    try {
      // Tentative Cloudinary d'abord
      debugPrint('🌐 Tentative upload Cloudinary...');
      final cloudinaryUrl = await CloudinaryStorageService.uploadImage(
        imageFile: imageFile,
        folder: folder,
        publicId: '${vehiculeId}_$type',
      );

      if (cloudinaryUrl != null) {
        return {
          'success': true,
          'url': cloudinaryUrl,
          'storage': 'cloudinary',
          'message': 'Image uploadée sur Cloudinary',
        };
      }

      // Fallback vers stockage local
      debugPrint('💾 Fallback vers stockage local...');
      final localPath = await LocalStorageService.saveImageLocally(
        imageFile: imageFile,
        folder: folder,
        fileName: fileName,
      );

      if (localPath != null) {
        // Marquer pour upload ultérieur
        await _markForLaterUpload(vehiculeId, type, localPath);
        
        return {
          'success': true,
          'url': localPath,
          'storage': 'local',
          'message': 'Image sauvée localement (sera uploadée plus tard)',
        };
      }

      return {
        'success': false,
        'message': 'Échec de sauvegarde',
      };
    } catch (e) {
      debugPrint('❌ Erreur upload hybride: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de l\'upload',
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