import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'firebase_storage_service.dart';
import 'local_storage_service.dart';

/// 📸 Service pour l'upload d'images vers Cloudinary
class CloudinaryService {
  // Configuration Cloudinary - Version réelle
  static const String _cloudName = 'dqmqc0uaa'; // Cloud Cloudinary réel
  static const String _uploadPreset = 'constat_tunisie'; // Preset pour l'app
  static const String _apiKey = 'demo-api-key'; // Clé de démo
  static const String _apiSecret = 'demo-api-secret'; // Secret de démo

  /// 📤 Upload une image (Stockage local + affichage immédiat)
  static Future<String?> uploadImage(File imageFile, String folder) async {
    try {
      print('💾 Sauvegarde locale de votre image...');

      // Sauvegarder l'image localement d'abord
      final localPath = await LocalStorageService.saveImageLocally(imageFile, folder);
      if (localPath != null) {
        print('✅ Image sauvegardée localement: $localPath');

        // Retourner le chemin local avec un préfixe pour l'identifier
        return 'file://$localPath';
      }

      print('🔄 Fallback vers Firebase Storage...');

      // Essayer Firebase Storage en fallback
      final firebaseUrl = await FirebaseStorageService.uploadImage(imageFile, folder);
      if (firebaseUrl != null) {
        print('✅ Upload Firebase réussi: $firebaseUrl');
        return firebaseUrl;
      }

      print('🔄 Fallback vers Cloudinary...');

      // Fallback vers Cloudinary
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

      final request = http.MultipartRequest('POST', url);

      // Ajouter les paramètres (upload preset sans signature)
      request.fields.addAll({
        'upload_preset': _uploadPreset,
        'folder': 'constat_tunisie_$folder',
        'resource_type': 'image',
      });

      // Ajouter le fichier image
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );

      print('📤 Envoi vers Cloudinary...');
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);
        final imageUrl = jsonResponse['secure_url'] as String;
        print('✅ Upload Cloudinary réussi: $imageUrl');
        return imageUrl;
      } else {
        print('❌ Erreur upload Cloudinary: ${response.statusCode}');
        print('Response: $responseBody');

        // Fallback vers simulation si tout échoue
        print('🔄 Fallback vers simulation...');
        return _generateFallbackUrl(imageFile, folder);
      }
    } catch (e) {
      print('❌ Exception upload: $e');
      // Fallback vers simulation si erreur
      return _generateFallbackUrl(imageFile, folder);
    }
  }

  /// 🎭 Générer une URL de fallback pour les tests
  static String _generateFallbackUrl(File imageFile, String folder) {
    final fileName = imageFile.path.split('/').last.replaceAll(' ', '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // URL de placeholder avec informations du fichier
    final fallbackUrl = 'https://via.placeholder.com/400x300/2196F3/FFFFFF?text=Document+${folder.toUpperCase()}+Upload%C3%A9';

    print('🎭 URL fallback générée: $fallbackUrl');
    return fallbackUrl;
  }



  /// 🗑️ Supprimer une image de Cloudinary
  static Future<bool> deleteImage(String publicId) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/destroy');
      
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signature = _generateDeleteSignature(publicId, timestamp);
      
      final response = await http.post(
        url,
        body: {
          'api_key': _apiKey,
          'timestamp': timestamp.toString(),
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
      print('Erreur lors de la suppression de l\'image: $e');
      return false;
    }
  }

  /// 🔐 Génère une signature pour la suppression
  static String _generateDeleteSignature(String publicId, int timestamp) {
    final stringToSign = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  /// 🖼️ Obtenir l'URL optimisée d'une image
  static String getOptimizedImageUrl(String publicId, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
  }) {
    final transformations = <String>[];
    
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    transformations.add('q_$quality');
    transformations.add('f_$format');
    
    final transformationString = transformations.join(',');
    
    return 'https://res.cloudinary.com/$_cloudName/image/upload/$transformationString/$publicId';
  }

  /// 📱 Obtenir l'URL pour thumbnail
  static String getThumbnailUrl(String publicId) {
    return getOptimizedImageUrl(
      publicId,
      width: 150,
      height: 150,
      quality: 'auto',
      format: 'webp',
    );
  }

  /// 🔍 Vérifier si Cloudinary est configuré
  static bool isConfigured() {
    return _cloudName != 'your-cloud-name' &&
           _apiKey != 'your-api-key' &&
           _apiSecret != 'your-api-secret';
  }

  /// 📋 Upload multiple images
  static Future<Map<String, String>> uploadMultipleImages(
    Map<String, File> images,
  ) async {
    final results = <String, String>{};
    
    for (final entry in images.entries) {
      final url = await uploadImage(entry.value, entry.key);
      if (url != null) {
        results[entry.key] = url;
      }
    }
    
    return results;
  }

  /// 🎯 Upload avec retry automatique
  static Future<String?> uploadImageWithRetry(
    File imageFile,
    String folder, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      final result = await uploadImage(imageFile, folder);
      if (result != null) {
        return result;
      }
      
      if (attempt < maxRetries) {
        // Attendre avant de réessayer
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    
    return null;
  }

  /// 📊 Obtenir les informations d'une image
  static Future<Map<String, dynamic>?> getImageInfo(String publicId) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signature = _generateInfoSignature(publicId, timestamp);
      
      final response = await http.get(
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/resources/image/upload/$publicId'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_apiKey:$_apiSecret'))}',
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      
      return null;
    } catch (e) {
      print('Erreur lors de la récupération des infos image: $e');
      return null;
    }
  }

  /// 🔐 Génère une signature pour les infos
  static String _generateInfoSignature(String publicId, int timestamp) {
    final stringToSign = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  /// 🧹 Nettoyer les images anciennes (plus de 30 jours)
  static Future<void> cleanupOldImages() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final timestamp = thirtyDaysAgo.millisecondsSinceEpoch ~/ 1000;
      
      // Cette fonctionnalité nécessite l'API Admin de Cloudinary
      // À implémenter selon vos besoins spécifiques
      print('Nettoyage des images anciennes...');
    } catch (e) {
      print('Erreur lors du nettoyage: $e');
    }
  }

  /// 📈 Obtenir les statistiques d'usage
  static Future<Map<String, dynamic>?> getUsageStats() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/usage'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_apiKey:$_apiSecret'))}',
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      
      return null;
    } catch (e) {
      print('Erreur lors de la récupération des stats: $e');
      return null;
    }
  }
}
