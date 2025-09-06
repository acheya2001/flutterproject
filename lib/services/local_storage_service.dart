import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// 📱 Service de stockage local pour les images
class LocalStorageService {
  /// 📤 Sauvegarder une image localement et retourner le chemin
  static Future<String?> saveImageLocally(File imageFile, String folder) async {
    try {
      print('💾 Sauvegarde locale de l\'image...');
      
      // Obtenir le répertoire de l'application
      final appDir = await getApplicationDocumentsDirectory();
      final constatsDir = Directory('${appDir.path}/constat_tunisie/$folder');
      
      // Créer le dossier s'il n'existe pas
      if (!await constatsDir.exists()) {
        await constatsDir.create(recursive: true);
      }
      
      // Générer un nom de fichier unique
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path);
      final fileName = 'image_${timestamp}$extension';
      final localPath = '${constatsDir.path}/$fileName';
      
      // Copier le fichier
      final savedFile = await imageFile.copy(localPath);
      
      print('✅ Image sauvegardée localement: $localPath');
      return savedFile.path;
      
    } catch (e) {
      print('❌ Erreur sauvegarde locale: $e');
      return null;
    }
  }
  
  /// 📋 Lister toutes les images d'un dossier
  static Future<List<String>> listLocalImages(String folder) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final constatsDir = Directory('${appDir.path}/constat_tunisie/$folder');
      
      if (!await constatsDir.exists()) {
        return [];
      }
      
      final files = await constatsDir.list().toList();
      final imagePaths = files
          .where((file) => file is File)
          .map((file) => file.path)
          .where((path) => _isImageFile(path))
          .toList();
      
      return imagePaths;
    } catch (e) {
      print('❌ Erreur listage images: $e');
      return [];
    }
  }
  
  /// 🗑️ Supprimer une image locale
  static Future<bool> deleteLocalImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        print('✅ Image locale supprimée: $imagePath');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Erreur suppression: $e');
      return false;
    }
  }
  
  /// 🔍 Vérifier si c'est un fichier image
  static bool _isImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension);
  }
  
  /// 📊 Obtenir la taille d'une image
  static Future<int> getImageSize(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.size;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
  
  /// 🧹 Nettoyer les anciennes images (plus de 30 jours)
  static Future<void> cleanOldImages() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final constatsDir = Directory('${appDir.path}/constat_tunisie');
      
      if (!await constatsDir.exists()) {
        return;
      }
      
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      
      await for (final entity in constatsDir.list(recursive: true)) {
        if (entity is File && _isImageFile(entity.path)) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await entity.delete();
            print('🧹 Image ancienne supprimée: ${entity.path}');
          }
        }
      }
    } catch (e) {
      print('❌ Erreur nettoyage: $e');
    }
  }
}
