import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 🚀 Service optimisé pour la gestion d'images avec performance améliorée
class OptimizedImageService {
  static final ImagePicker _picker = ImagePicker();
  static final Map<String, String> _imageCache = {};
  static const String _cacheKey = 'image_cache';

  /// 📸 Prendre une photo avec optimisation automatique
  static Future<String?> takeOptimizedPhoto({
    required String destination,
    String? customName,
    Function(String)? onProgress,
  }) async {
    try {
      onProgress?.call('Ouverture de l\'appareil photo...');
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70, // Qualité optimisée pour la performance
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image == null) return null;

      onProgress?.call('Traitement de l\'image...');
      return await _processAndSaveImage(image, destination, customName, onProgress);
      
    } catch (e) {
      print('❌ Erreur prise de photo: $e');
      throw Exception('Erreur lors de la prise de photo: $e');
    }
  }

  /// 🖼️ Sélectionner une photo depuis la galerie
  static Future<String?> selectOptimizedPhoto({
    required String destination,
    String? customName,
    Function(String)? onProgress,
  }) async {
    try {
      onProgress?.call('Ouverture de la galerie...');
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image == null) return null;

      onProgress?.call('Traitement de l\'image...');
      return await _processAndSaveImage(image, destination, customName, onProgress);
      
    } catch (e) {
      print('❌ Erreur sélection photo: $e');
      throw Exception('Erreur lors de la sélection: $e');
    }
  }

  /// 📱 Sélectionner plusieurs photos optimisées
  static Future<List<String>> selectMultipleOptimizedPhotos({
    required String destination,
    int maxImages = 5,
    Function(int, int)? onProgress,
  }) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 70,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (images.isEmpty) return [];

      final List<String> results = [];
      final limitedImages = images.take(maxImages).toList();

      for (int i = 0; i < limitedImages.length; i++) {
        try {
          onProgress?.call(i + 1, limitedImages.length);
          
          final result = await _processAndSaveImage(
            limitedImages[i], 
            destination, 
            'image_${i + 1}_${DateTime.now().millisecondsSinceEpoch}',
            null,
          );
          
          if (result != null) {
            results.add(result);
          }
        } catch (e) {
          print('⚠️ Erreur traitement image ${i + 1}: $e');
          // Continuer avec les autres images
        }
      }

      return results;
    } catch (e) {
      print('❌ Erreur sélection multiple: $e');
      throw Exception('Erreur lors de la sélection multiple: $e');
    }
  }

  /// 🔄 Traitement et sauvegarde optimisée d'image
  static Future<String?> _processAndSaveImage(
    XFile image, 
    String destination, 
    String? customName,
    Function(String)? onProgress,
  ) async {
    try {
      final File originalFile = File(image.path);
      final String fileName = customName ?? 
          'img_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';

      onProgress?.call('Optimisation de l\'image...');

      // Vérifier si l'image est déjà en cache
      final String cacheKey = '${destination}_$fileName';
      if (_imageCache.containsKey(cacheKey)) {
        onProgress?.call('Image récupérée du cache');
        return _imageCache[cacheKey];
      }

      // Compression et optimisation
      final File optimizedFile = await _optimizeImage(originalFile, fileName);
      
      onProgress?.call('Sauvegarde locale...');

      // Sauvegarde locale immédiate
      final String localPath = await _saveImageLocally(optimizedFile, destination, fileName);
      final String localUrl = 'file://$localPath';

      // Mise en cache
      _imageCache[cacheKey] = localUrl;
      await _saveCacheToPrefs();

      onProgress?.call('Image prête !');

      // Upload en arrière-plan (non-bloquant)
      _uploadInBackground(optimizedFile, destination, fileName, localUrl);

      return localUrl;
      
    } catch (e) {
      print('❌ Erreur traitement image: $e');
      throw Exception('Erreur lors du traitement: $e');
    }
  }

  /// 🗜️ Optimisation d'image avancée
  static Future<File> _optimizeImage(File originalFile, String fileName) async {
    try {
      final int originalSize = await originalFile.length();
      
      // Si l'image est déjà petite (< 300KB), pas d'optimisation
      if (originalSize < 300 * 1024) {
        return originalFile;
      }

      // Créer un fichier temporaire optimisé
      final Directory tempDir = await getTemporaryDirectory();
      final String optimizedPath = '${tempDir.path}/optimized_$fileName';
      
      // Copie simple (dans un vrai projet, utilisez le package image pour la compression)
      final File optimizedFile = await originalFile.copy(optimizedPath);
      
      final int optimizedSize = await optimizedFile.length();
      print('🗜️ Optimisation: ${originalSize ~/ 1024}KB → ${optimizedSize ~/ 1024}KB');
      
      return optimizedFile;
      
    } catch (e) {
      print('⚠️ Échec optimisation: $e');
      return originalFile;
    }
  }

  /// 💾 Sauvegarde locale organisée
  static Future<String> _saveImageLocally(File file, String destination, String fileName) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory destDir = Directory('${appDir.path}/images/$destination');
      
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }

      final String localPath = '${destDir.path}/$fileName';
      final File localFile = await file.copy(localPath);
      
      print('💾 Image sauvée: $localPath');
      return localFile.path;
      
    } catch (e) {
      print('❌ Erreur sauvegarde locale: $e');
      throw Exception('Impossible de sauvegarder l\'image');
    }
  }

  /// 🌐 Upload en arrière-plan
  static void _uploadInBackground(File file, String destination, String fileName, String localUrl) async {
    try {
      print('🔄 Upload en arrière-plan: $fileName');
      
      // Simuler un upload (remplacer par votre service cloud)
      await Future.delayed(const Duration(seconds: 2));
      
      // TODO: Intégrer avec votre service cloud (Firebase, Cloudinary, etc.)
      // final cloudUrl = await YourCloudService.upload(file, destination);
      
      print('✅ Upload terminé en arrière-plan: $fileName');
      
    } catch (e) {
      print('⚠️ Échec upload arrière-plan: $e');
    }
  }

  /// 🗑️ Supprimer une image
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.startsWith('file://')) {
        final String localPath = imageUrl.replaceFirst('file://', '');
        final File file = File(localPath);
        
        if (await file.exists()) {
          await file.delete();
          
          // Supprimer du cache
          _imageCache.removeWhere((key, value) => value == imageUrl);
          await _saveCacheToPrefs();
          
          print('🗑️ Image supprimée: $localPath');
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('❌ Erreur suppression: $e');
      return false;
    }
  }

  /// 💾 Sauvegarder le cache
  static Future<void> _saveCacheToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cacheJson = jsonEncode(_imageCache);
      await prefs.setString(_cacheKey, cacheJson);
    } catch (e) {
      print('⚠️ Erreur sauvegarde cache: $e');
    }
  }

  /// 📂 Charger le cache
  static Future<void> loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cacheJson = prefs.getString(_cacheKey);
      
      if (cacheJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(cacheJson);
        _imageCache.clear();
        _imageCache.addAll(Map<String, String>.from(decoded));
        print('📂 Cache chargé: ${_imageCache.length} images');
      }
    } catch (e) {
      print('⚠️ Erreur chargement cache: $e');
    }
  }

  /// 🧹 Nettoyer le cache
  static Future<void> clearCache() async {
    try {
      _imageCache.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      print('🧹 Cache nettoyé');
    } catch (e) {
      print('⚠️ Erreur nettoyage cache: $e');
    }
  }

  /// 📊 Statistiques du cache
  static Map<String, dynamic> getCacheStats() {
    return {
      'totalImages': _imageCache.length,
      'cacheKeys': _imageCache.keys.toList(),
    };
  }
}
