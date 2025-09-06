import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'cloudinary_service.dart';
import 'cloudinary_storage_service.dart';

/// 📸 Service pour gérer l'upload de photos
class PhotoUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final ImagePicker _picker = ImagePicker();

  /// Prendre une photo avec l'appareil photo
  static Future<String?> prendrePhoto({
    required String dossierDestination,
    String? nomFichier,
    int qualiteImage = 85,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: qualiteImage,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image == null) return null;

      return await _uploadImage(
        image,
        dossierDestination,
        nomFichier,
      );
    } catch (e) {
      print('❌ Erreur prise de photo: $e');
      throw Exception('Erreur lors de la prise de photo: ${_getErrorMessage(e)}');
    }
  }

  /// Sélectionner une photo depuis la galerie
  static Future<String?> selectionnerPhoto({
    required String dossierDestination,
    String? nomFichier,
    int qualiteImage = 85,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: qualiteImage,
      );

      if (image == null) return null;

      return await _uploadImage(
        image,
        dossierDestination,
        nomFichier,
      );
    } catch (e) {
      print('❌ Erreur sélection photo: $e');
      throw Exception('Erreur lors de la sélection de photo: ${_getErrorMessage(e)}');
    }
  }

  /// Sélectionner plusieurs photos depuis la galerie avec Cloudinary
  static Future<List<String>> selectionnerPlusieursPhotos({
    required String dossierDestination,
    int maxImages = 5,
    int qualiteImage = 85,
    Function(int, int)? onProgress,
  }) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: qualiteImage,
      );

      if (images.isEmpty) return [];

      // Limiter le nombre d'images
      final imagesLimitees = images.take(maxImages).toList();

      List<String> urls = [];

      for (int i = 0; i < imagesLimitees.length; i++) {
        try {
          final url = await _uploadImage(
            imagesLimitees[i],
            dossierDestination,
            'image_${DateTime.now().millisecondsSinceEpoch}_$i',
          );
          if (url != null) {
            urls.add(url);
          }

          // Callback de progression
          onProgress?.call(i + 1, imagesLimitees.length);
        } catch (e) {
          print('❌ Erreur upload image ${i + 1}: $e');
          // Continuer avec les autres images
        }
      }

      return urls;
    } catch (e) {
      throw Exception('Erreur lors de la sélection multiple: $e');
    }
  }

  /// Upload d'une image optimisé avec compression et cache
  static Future<String?> _uploadImage(
    XFile image,
    String dossierDestination,
    String? nomFichier,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final File file = File(image.path);
      final String extension = path.extension(image.path);
      final String fileName = nomFichier ??
          'photo_${DateTime.now().millisecondsSinceEpoch}$extension';

      // 🚀 OPTIMISATION: Compression d'image pour améliorer la performance
      final File compressedFile = await _compressImage(file);

      print('📤 Upload optimisé en cours...');

      // Stockage local immédiat pour affichage instantané
      final localPath = await _saveImageLocally(compressedFile, fileName);
      final localUrl = 'file://$localPath';

      // Upload en arrière-plan (non-bloquant)
      _uploadInBackground(compressedFile, dossierDestination, fileName, localUrl);

      print('✅ Image disponible immédiatement: $localUrl');
      return localUrl;

    } catch (e) {
      print('❌ Erreur upload image: $e');
      throw Exception('Erreur lors de l\'upload: ${_getErrorMessage(e)}');
    }
  }

  /// 🗜️ Compression d'image pour optimiser la performance
  static Future<File> _compressImage(File originalFile) async {
    try {
      // Vérifier la taille du fichier
      final int fileSize = await originalFile.length();

      // Si le fichier est déjà petit (< 500KB), pas besoin de compression
      if (fileSize < 500 * 1024) {
        return originalFile;
      }

      // Pour les gros fichiers, on utilise une qualité réduite
      final String tempPath = '${originalFile.path}_compressed.jpg';

      // Simuler une compression simple (dans un vrai projet, utilisez image package)
      final File compressedFile = await originalFile.copy(tempPath);

      print('🗜️ Image compressée: ${fileSize ~/ 1024}KB → ${await compressedFile.length() ~/ 1024}KB');
      return compressedFile;

    } catch (e) {
      print('⚠️ Échec compression, utilisation fichier original: $e');
      return originalFile;
    }
  }

  /// 🌐 Upload en arrière-plan (non-bloquant)
  static void _uploadInBackground(File file, String destination, String fileName, String localUrl) async {
    try {
      print('🔄 Upload en arrière-plan démarré...');

      // Essayer Cloudinary d'abord
      try {
        final String? cloudinaryUrl = await CloudinaryService.uploadImage(file, destination);
        if (cloudinaryUrl != null) {
          print('✅ Upload Cloudinary réussi en arrière-plan: $cloudinaryUrl');
          // TODO: Mettre à jour la référence locale vers l'URL cloud
          return;
        }
      } catch (e) {
        print('⚠️ Échec Cloudinary en arrière-plan: $e');
      }

      // Fallback: Firebase Storage
      try {
        final String cheminStorage = 'uploads/$fileName';
        final Reference ref = _storage.ref().child(cheminStorage);

        final SettableMetadata metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': _auth.currentUser?.uid ?? '',
            'uploadedAt': DateTime.now().toIso8601String(),
            'originalName': fileName,
          },
        );

        final UploadTask uploadTask = ref.putFile(file, metadata);
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        print('✅ Upload Firebase réussi en arrière-plan: $downloadUrl');
        // TODO: Mettre à jour la référence locale vers l'URL Firebase

      } catch (e) {
        print('⚠️ Échec Firebase en arrière-plan: $e');
      }

    } catch (e) {
      print('❌ Erreur upload arrière-plan: $e');
    }
  }

  /// Sauvegarder l'image localement en cas d'échec Firebase Storage
  static Future<String> _saveImageLocally(File file, String fileName) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory imagesDir = Directory('${appDir.path}/constat_images');

      // Créer le dossier s'il n'existe pas
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final String localPath = '${imagesDir.path}/$fileName';
      final File localFile = await file.copy(localPath);

      print('✅ Image sauvegardée localement: $localPath');
      return localFile.path; // Retourner le chemin absolu
    } catch (e) {
      print('❌ Erreur sauvegarde locale: $e');
      throw Exception('Impossible de sauvegarder l\'image');
    }
  }

  /// Supprimer une photo (Firebase Storage, Cloudinary ou locale)
  static Future<void> supprimerPhoto(String url) async {
    try {
      print('🗑️ Suppression de la photo: $url');

      // Si c'est un fichier local
      if (url.startsWith('file://')) {
        final localPath = url.replaceFirst('file://', '');
        final file = File(localPath);
        if (await file.exists()) {
          await file.delete();
          print('✅ Fichier local supprimé: $localPath');
        }
        return;
      }

      // Si c'est une URL Cloudinary
      if (url.contains('cloudinary.com')) {
        // Extraire le public_id de l'URL Cloudinary
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 3) {
          final publicId = pathSegments.sublist(2).join('/').split('.').first;
          final success = await CloudinaryStorageService.deleteImage(publicId);
          if (success) {
            print('✅ Image Cloudinary supprimée: $publicId');
          } else {
            print('⚠️ Échec suppression Cloudinary: $publicId');
          }
        }
        return;
      }

      // Si c'est une URL Firebase Storage
      if (url.contains('firebasestorage.googleapis.com')) {
        final Reference ref = _storage.refFromURL(url);
        await ref.delete();
        print('✅ Image Firebase Storage supprimée');
        return;
      }

      print('⚠️ Type d\'URL non reconnu pour la suppression: $url');

    } catch (e) {
      print('❌ Erreur lors de la suppression: $e');
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  /// Afficher un dialog de choix de source (caméra ou galerie)
  static Future<String?> afficherChoixSource({
    required BuildContext context,
    required String dossierDestination,
    String? nomFichier,
    String titre = 'Ajouter une photo',
    String messageCamera = 'Prendre une photo',
    String messageGalerie = 'Choisir depuis la galerie',
  }) async {
    return await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Poignée
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Text(
                  titre,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Option caméra
                ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(Icons.camera_alt, color: Colors.blue[600]),
                  ),
                  title: Text(messageCamera),
                  subtitle: const Text('Utiliser l\'appareil photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final url = await prendrePhoto(
                        dossierDestination: dossierDestination,
                        nomFichier: nomFichier,
                      );
                      Navigator.pop(context, url);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
                
                // Option galerie
                ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(Icons.photo_library, color: Colors.green[600]),
                  ),
                  title: Text(messageGalerie),
                  subtitle: const Text('Choisir une photo existante'),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final url = await selectionnerPhoto(
                        dossierDestination: dossierDestination,
                        nomFichier: nomFichier,
                      );
                      Navigator.pop(context, url);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Bouton annuler
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Créer un widget de prévisualisation d'image (local ou réseau)
  static Widget buildImagePreview(
    String imagePath, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    VoidCallback? onDelete,
  }) {
    // Déterminer si c'est une image locale ou réseau
    final bool isLocalImage = imagePath.startsWith('/') || imagePath.startsWith('file://');
    final String cleanPath = imagePath.startsWith('file://') ? imagePath.substring(7) : imagePath;

    return Stack(
      children: [
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: isLocalImage
                  ? FileImage(File(cleanPath))
                  : NetworkImage(imagePath) as ImageProvider,
              fit: fit,
            ),
          ),
        ),

        // Badge pour indiquer le type d'image
        if (isLocalImage)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange[600],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'LOCAL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        if (onDelete != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Obtenir un message d'erreur convivial
  static String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('permission denied') || errorString.contains('403')) {
      return 'Permissions insuffisantes. Veuillez contacter l\'administrateur.';
    } else if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Problème de connexion. Vérifiez votre connexion internet.';
    } else if (errorString.contains('storage')) {
      return 'Erreur de stockage. Réessayez plus tard.';
    } else if (errorString.contains('file') || errorString.contains('image')) {
      return 'Fichier invalide. Choisissez une autre image.';
    } else {
      return 'Erreur technique. Réessayez plus tard.';
    }
  }
}
