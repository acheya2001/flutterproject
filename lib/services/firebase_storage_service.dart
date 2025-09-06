import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

/// 🔥 Service Firebase Storage pour upload d'images réelles
class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 📤 Upload une image vers Firebase Storage
  static Future<String?> uploadImage(File imageFile, String folder) async {
    try {
      print('🔄 Upload vers Firebase Storage...');
      
      // Générer un nom de fichier unique
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final folderPath = 'constat_tunisie/$folder';
      
      // Référence vers le fichier dans Firebase Storage
      final ref = _storage.ref().child('$folderPath/$fileName');
      
      // Métadonnées
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploaded_by': 'constat_tunisie_app',
          'folder': folder,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      print('📤 Envoi vers Firebase Storage...');
      
      // Upload du fichier
      final uploadTask = ref.putFile(imageFile, metadata);
      
      // Attendre la fin de l'upload
      final snapshot = await uploadTask;
      
      // Récupérer l'URL de téléchargement
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Upload Firebase réussi: $downloadUrl');
      return downloadUrl;
      
    } catch (e) {
      print('❌ Erreur upload Firebase Storage: $e');
      return null;
    }
  }

  /// 🗑️ Supprimer une image
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('✅ Image supprimée: $imageUrl');
      return true;
    } catch (e) {
      print('❌ Erreur suppression: $e');
      return false;
    }
  }

  /// 📋 Lister les images d'un dossier
  static Future<List<String>> listImages(String folder) async {
    try {
      final ref = _storage.ref().child('constat_tunisie/$folder');
      final result = await ref.listAll();
      
      final urls = <String>[];
      for (final item in result.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }
      
      return urls;
    } catch (e) {
      print('❌ Erreur listage: $e');
      return [];
    }
  }
}
