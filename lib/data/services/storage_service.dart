import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';
import 'dart:io';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Logger _logger = Logger();

  // Télécharger un fichier
  Future<String> uploadFile(File file, String path) async {
    try {
      final storageRef = _storage.ref().child(path);
      
      // Télécharger le fichier
      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      _logger.e('Erreur lors du téléchargement du fichier: $e');
      rethrow;
    }
  }

  // Supprimer un fichier
  Future<void> deleteFile(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (e) {
      _logger.e('Erreur lors de la suppression du fichier: $e');
      rethrow;
    }
  }

  // Télécharger une image avec compression
  Future<String> uploadImage(File image, String path, {int quality = 85}) async {
    try {
      // Ici, vous pourriez ajouter une logique pour compresser l'image avant de la télécharger
      // Par exemple, en utilisant le package 'flutter_image_compress'
      
      return await uploadFile(image, path);
    } catch (e) {
      _logger.e('Erreur lors du téléchargement de l\'image: $e');
      rethrow;
    }
  }

  // Obtenir la liste des fichiers dans un dossier
  Future<List<String>> listFiles(String path) async {
    try {
      final ListResult result = await _storage.ref().child(path).listAll();
      
      List<String> urls = [];
      for (var item in result.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }
      
      return urls;
    } catch (e) {
      _logger.e('Erreur lors de la récupération des fichiers: $e');
      rethrow;
    }
  }
}