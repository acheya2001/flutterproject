import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// 📸 Service d'upload d'images vers Firebase Storage
class ImageUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 📤 Upload une image vers Firebase Storage
  static Future<String> uploadImage(
    File imageFile,
    String folder,
    String fileName,
  ) async {
    try {
      debugPrint('[ImageUpload] 📤 Upload image: $folder/$fileName');

      // Créer la référence du fichier
      final ref = _storage.ref().child('$folder/$fileName');

      // Upload le fichier
      final uploadTask = ref.putFile(imageFile);

      // Attendre la fin de l'upload
      final snapshot = await uploadTask;

      // Récupérer l'URL de téléchargement
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('[ImageUpload] ✅ Upload réussi: $downloadUrl');
      return downloadUrl;

    } catch (e) {
      debugPrint('[ImageUpload] ❌ Erreur upload: $e');
      throw Exception('Erreur lors de l\'upload de l\'image: $e');
    }
  }

  /// 📤 Upload multiple images
  static Future<List<String>> uploadMultipleImages(
    List<File> imageFiles,
    String folder,
    String baseFileName,
  ) async {
    final urls = <String>[];

    for (int i = 0; i < imageFiles.length; i++) {
      final fileName = '${baseFileName}_$i.jpg';
      final url = await uploadImage(imageFiles[i], folder, fileName);
      urls.add(url);
    }

    return urls;
  }

  /// 🗑️ Supprimer une image
  static Future<void> deleteImage(String imageUrl) async {
    try {
      debugPrint('[ImageUpload] 🗑️ Suppression image: $imageUrl');

      // Créer la référence depuis l'URL
      final ref = _storage.refFromURL(imageUrl);

      // Supprimer le fichier
      await ref.delete();

      debugPrint('[ImageUpload] ✅ Suppression réussie');

    } catch (e) {
      debugPrint('[ImageUpload] ❌ Erreur suppression: $e');
      throw Exception('Erreur lors de la suppression de l\'image: $e');
    }
  }

  /// 📊 Obtenir les métadonnées d'une image
  static Future<FullMetadata> getImageMetadata(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      return await ref.getMetadata();
    } catch (e) {
      debugPrint('[ImageUpload] ❌ Erreur métadonnées: $e');
      throw Exception('Erreur lors de la récupération des métadonnées: $e');
    }
  }

  /// 📏 Obtenir la taille d'une image en bytes
  static Future<int> getImageSize(String imageUrl) async {
    try {
      final metadata = await getImageMetadata(imageUrl);
      return metadata.size ?? 0;
    } catch (e) {
      debugPrint('[ImageUpload] ❌ Erreur taille: $e');
      return 0;
    }
  }

  /// 🔗 Générer un nom de fichier unique
  static String generateUniqueFileName(String prefix, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_$timestamp.$extension';
  }

  /// 📁 Lister les images dans un dossier
  static Future<List<Reference>> listImagesInFolder(String folder) async {
    try {
      final ref = _storage.ref().child(folder);
      final result = await ref.listAll();
      return result.items;
    } catch (e) {
      debugPrint('[ImageUpload] ❌ Erreur listage: $e');
      return [];
    }
  }

  /// 🧹 Nettoyer les images orphelines
  static Future<void> cleanupOrphanedImages(
    String folder,
    List<String> validImageUrls,
  ) async {
    try {
      debugPrint('[ImageUpload] 🧹 Nettoyage dossier: $folder');

      final allImages = await listImagesInFolder(folder);
      
      for (final imageRef in allImages) {
        final imageUrl = await imageRef.getDownloadURL();
        
        if (!validImageUrls.contains(imageUrl)) {
          debugPrint('[ImageUpload] 🗑️ Suppression image orpheline: $imageUrl');
          await imageRef.delete();
        }
      }

      debugPrint('[ImageUpload] ✅ Nettoyage terminé');

    } catch (e) {
      debugPrint('[ImageUpload] ❌ Erreur nettoyage: $e');
    }
  }

  /// 📊 Obtenir les statistiques d'un dossier
  static Future<Map<String, dynamic>> getFolderStats(String folder) async {
    try {
      final images = await listImagesInFolder(folder);
      int totalSize = 0;
      
      for (final imageRef in images) {
        final metadata = await imageRef.getMetadata();
        totalSize += metadata.size ?? 0;
      }

      return {
        'count': images.length,
        'totalSize': totalSize,
        'averageSize': images.isNotEmpty ? totalSize / images.length : 0,
      };

    } catch (e) {
      debugPrint('[ImageUpload] ❌ Erreur statistiques: $e');
      return {
        'count': 0,
        'totalSize': 0,
        'averageSize': 0,
      };
    }
  }

  /// 🔄 Copier une image vers un autre dossier
  static Future<String> copyImageToFolder(
    String sourceImageUrl,
    String targetFolder,
    String targetFileName,
  ) async {
    try {
      debugPrint('[ImageUpload] 🔄 Copie image vers: $targetFolder/$targetFileName');

      // Télécharger l'image source
      final sourceRef = _storage.refFromURL(sourceImageUrl);
      final imageData = await sourceRef.getData();

      if (imageData == null) {
        throw Exception('Impossible de télécharger l\'image source');
      }

      // Upload vers la nouvelle destination
      final targetRef = _storage.ref().child('$targetFolder/$targetFileName');
      await targetRef.putData(imageData);

      // Récupérer l'URL de la nouvelle image
      final newUrl = await targetRef.getDownloadURL();

      debugPrint('[ImageUpload] ✅ Copie réussie: $newUrl');
      return newUrl;

    } catch (e) {
      debugPrint('[ImageUpload] ❌ Erreur copie: $e');
      throw Exception('Erreur lors de la copie de l\'image: $e');
    }
  }

  /// 🔒 Vérifier les permissions d'upload
  static Future<bool> checkUploadPermissions() async {
    try {
      // Tenter d'uploader un petit fichier de test
      final testRef = _storage.ref().child('test/permission_check.txt');
      await testRef.putString('test');
      await testRef.delete();
      return true;
    } catch (e) {
      debugPrint('[ImageUpload] ❌ Pas de permissions d\'upload: $e');
      return false;
    }
  }

  /// 📱 Optimiser une image pour mobile
  static Future<String> uploadOptimizedImage(
    File imageFile,
    String folder,
    String fileName, {
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
  }) async {
    try {
      // Pour l'instant, on upload directement
      // TODO: Ajouter la compression d'image si nécessaire
      return await uploadImage(imageFile, folder, fileName);
    } catch (e) {
      debugPrint('[ImageUpload] ❌ Erreur upload optimisé: $e');
      rethrow;
    }
  }

  /// 🎯 Upload avec retry automatique
  static Future<String> uploadImageWithRetry(
    File imageFile,
    String folder,
    String fileName, {
    int maxRetries = 3,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await uploadImage(imageFile, folder, fileName);
      } catch (e) {
        attempts++;
        debugPrint('[ImageUpload] ❌ Tentative $attempts/$maxRetries échouée: $e');
        
        if (attempts >= maxRetries) {
          rethrow;
        }
        
        // Attendre avant de réessayer
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    
    throw Exception('Échec de l\'upload après $maxRetries tentatives');
  }
}
