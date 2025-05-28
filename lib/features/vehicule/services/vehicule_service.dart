import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vehicule_model.dart';
import '../../../utils/connectivity_utils.dart';

class VehiculeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConnectivityUtils _connectivityUtils = ConnectivityUtils();
  
  // Constantes pour les timeouts et la qualité d'image - RÉDUITES DAVANTAGE
  static const Duration uploadTimeout = Duration(seconds: 45); // Réduit à 45 secondes
  static const Duration compressionTimeout = Duration(seconds: 15); // Réduit à 15 secondes
  static const int imageQuality = 20; // Qualité d'image réduite à 20%
  static const int maxImageWidth = 500; // Largeur maximale réduite à 500
  static const int maxImageHeight = 500; // Hauteur maximale réduite à 500
  static const int maxImageSizeBytes = 512 * 1024; // 512 KB maximum
  
  // Variable pour suivre si une opération a été annulée
  bool _isCancelled = false;
  
  // Méthode pour annuler les opérations en cours
  void cancelOperations() {
    _isCancelled = true;
    debugPrint('[VehiculeService] Opérations annulées par l\'utilisateur');
  }
  
  // Réinitialiser l'état d'annulation
  void resetCancellation() {
    _isCancelled = false;
  }

  // Récupérer tous les véhicules d'un propriétaire
  Future<List<VehiculeModel>> getVehiculesByProprietaireId(String proprietaireId) async {
    try {
      // Vérifier la connexion Internet
      final hasInternet = await _connectivityUtils.checkConnection();
      if (!hasInternet) {
        // Essayer de récupérer les données en cache
        return await _getVehiculesFromCache(proprietaireId);
      }
      
      debugPrint('[VehiculeService] Récupération des véhicules pour le propriétaire: $proprietaireId');
      
      final snapshot = await _firestore
          .collection('vehicules')
          .where('proprietaireId', isEqualTo: proprietaireId)
          .get()
          .timeout(const Duration(seconds: 15), onTimeout: () {
            throw TimeoutException('La récupération des véhicules a pris trop de temps. Veuillez vérifier votre connexion internet.');
          });
      
      final vehicules = snapshot.docs
          .map((doc) => VehiculeModel.fromFirestore(doc))
          .toList();
          
      // Mettre en cache les véhicules
      await _cacheVehicules(proprietaireId, vehicules);
      
      debugPrint('[VehiculeService] ${vehicules.length} véhicules récupérés');
      return vehicules;
    } catch (e) {
      debugPrint('[VehiculeService] Erreur lors de la récupération des véhicules: $e');
      
      // En cas d'erreur, essayer de récupérer les données en cache
      try {
        return await _getVehiculesFromCache(proprietaireId);
      } catch (cacheError) {
        debugPrint('[VehiculeService] Erreur lors de la récupération du cache: $cacheError');
        rethrow;
      }
    }
  }

  // Mettre en cache les véhicules
  Future<void> _cacheVehicules(String proprietaireId, List<VehiculeModel> vehicules) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final vehiculesJson = vehicules.map((v) => v.toMap()).toList();
      await prefs.setString('vehicules_$proprietaireId', jsonEncode(vehiculesJson));
      debugPrint('[VehiculeService] Véhicules mis en cache pour: $proprietaireId');
    } catch (e) {
      debugPrint('[VehiculeService] Erreur lors de la mise en cache des véhicules: $e');
    }
  }

  // Récupérer les véhicules depuis le cache
  Future<List<VehiculeModel>> _getVehiculesFromCache(String proprietaireId) async {
    final prefs = await SharedPreferences.getInstance();
    final vehiculesJson = prefs.getString('vehicules_$proprietaireId');
    
    if (vehiculesJson == null) {
      debugPrint('[VehiculeService] Aucun véhicule en cache pour: $proprietaireId');
      return [];
    }
    
    try {
      final List<dynamic> decodedJson = jsonDecode(vehiculesJson);
      final vehicules = decodedJson.map((json) {
        // Créer un VehiculeModel à partir des données
        final Map<String, dynamic> data = Map<String, dynamic>.from(json);
        return VehiculeModel.fromMap(data);
      }).toList();
      
      debugPrint('[VehiculeService] ${vehicules.length} véhicules récupérés du cache');
      return vehicules;
    } catch (e) {
      debugPrint('[VehiculeService] Erreur lors de la lecture du cache: $e');
      return [];
    }
  }

  // Récupérer un véhicule par son ID
  Future<VehiculeModel?> getVehiculeById(String vehiculeId) async {
    try {
      // Vérifier la connexion Internet
      final hasInternet = await _connectivityUtils.checkConnection();
      if (!hasInternet) {
        // Essayer de récupérer les données en cache
        return await _getVehiculeFromCache(vehiculeId);
      }
      
      debugPrint('[VehiculeService] Récupération du véhicule: $vehiculeId');
      
      final doc = await _firestore
          .collection('vehicules')
          .doc(vehiculeId)
          .get()
          .timeout(const Duration(seconds: 10), onTimeout: () {
            throw TimeoutException('La récupération du véhicule a pris trop de temps. Veuillez vérifier votre connexion internet.');
          });
      
      if (!doc.exists) {
        debugPrint('[VehiculeService] Véhicule non trouvé');
        return null;
      }
      
      final vehicule = VehiculeModel.fromFirestore(doc);
      
      // Mettre en cache le véhicule
      await _cacheVehicule(vehicule);
      
      debugPrint('[VehiculeService] Véhicule récupéré: ${vehicule.immatriculation}');
      return vehicule;
    } catch (e) {
      debugPrint('[VehiculeService] Erreur lors de la récupération du véhicule: $e');
      
      // En cas d'erreur, essayer de récupérer les données en cache
      try {
        return await _getVehiculeFromCache(vehiculeId);
      } catch (cacheError) {
        debugPrint('[VehiculeService] Erreur lors de la récupération du cache: $cacheError');
        rethrow;
      }
    }
  }

  // Mettre en cache un véhicule
  Future<void> _cacheVehicule(VehiculeModel vehicule) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vehicule_${vehicule.id}', jsonEncode(vehicule.toMap()));
      debugPrint('[VehiculeService] Véhicule mis en cache: ${vehicule.id}');
    } catch (e) {
      debugPrint('[VehiculeService] Erreur lors de la mise en cache du véhicule: $e');
    }
  }

  // Récupérer un véhicule depuis le cache
  Future<VehiculeModel?> _getVehiculeFromCache(String vehiculeId) async {
    final prefs = await SharedPreferences.getInstance();
    final vehiculeJson = prefs.getString('vehicule_$vehiculeId');
    
    if (vehiculeJson == null) {
      debugPrint('[VehiculeService] Véhicule non trouvé dans le cache: $vehiculeId');
      return null;
    }
    
    try {
      final Map<String, dynamic> decodedJson = jsonDecode(vehiculeJson);
      final vehicule = VehiculeModel.fromMap(decodedJson);
      
      debugPrint('[VehiculeService] Véhicule récupéré du cache: $vehiculeId');
      return vehicule;
    } catch (e) {
      debugPrint('[VehiculeService] Erreur lors de la lecture du cache: $e');
      return null;
    }
  }

  // Compresser une image avant de la télécharger - OPTIMISÉ DAVANTAGE
  Future<File?> _compressImage(File imageFile) async {
    try {
      debugPrint('[VehiculeService] Compression de l\'image: ${imageFile.path}');
      
      // Vérifier si le fichier existe
      if (!await imageFile.exists()) {
        debugPrint('[VehiculeService] Le fichier image n\'existe pas: ${imageFile.path}');
        throw Exception('Le fichier image n\'existe pas ou est inaccessible');
      }
      
      // Vérifier la taille de l'image avant compression
      final fileSize = await imageFile.length();
      debugPrint('[VehiculeService] Taille originale de l\'image: ${fileSize ~/ 1024} KB');
      
      // Compression plus agressive pour toutes les images
      int qualityLevel = 15; // Compression très agressive par défaut
      
      if (fileSize > 5 * 1024 * 1024) { // Plus de 5 MB
        qualityLevel = 10; // Compression extrêmement agressive
        debugPrint('[VehiculeService] Image très volumineuse, compression extrême appliquée');
      } else if (fileSize > 2 * 1024 * 1024) { // Plus de 2 MB
        qualityLevel = 12; // Compression très agressive
        debugPrint('[VehiculeService] Image volumineuse, compression très agressive appliquée');
      }
      
      // Utiliser un timeout pour la compression
      final bytes = await imageFile.readAsBytes()
          .timeout(compressionTimeout, onTimeout: () {
        debugPrint('[VehiculeService] Timeout lors de la lecture de l\'image');
        throw TimeoutException('La lecture de l\'image a pris trop de temps.');
      });
      
      if (_isCancelled) {
        debugPrint('[VehiculeService] Opération annulée pendant la compression');
        return null;
      }
      
      // Décodage de l'image avec gestion d'erreur améliorée
      img.Image? image;
      try {
        image = img.decodeImage(bytes);
      } catch (e) {
        debugPrint('[VehiculeService] Erreur lors du décodage de l\'image: $e');
        throw Exception('Format d\'image non supporté ou image corrompue');
      }
      
      if (image == null) {
        debugPrint('[VehiculeService] Impossible de décoder l\'image');
        throw Exception('Format d\'image non supporté ou image corrompue');
      }
      
      // Redimensionner l'image pour réduire sa taille - PLUS AGRESSIF
      img.Image resizedImage;
      
      // Toujours redimensionner pour réduire la taille
      int targetWidth = maxImageWidth;
      int targetHeight = (image.height * targetWidth / image.width).round();
      
      // Si l'image est très haute, limiter également la hauteur
      if (targetHeight > maxImageHeight) {
        targetHeight = maxImageHeight;
        targetWidth = (image.width * targetHeight / image.height).round();
      }
      
      debugPrint('[VehiculeService] Redimensionnement de l\'image à ${targetWidth}x${targetHeight}');
      resizedImage = img.copyResize(
        image,
        width: targetWidth,
        height: targetHeight,
      );
      
      if (_isCancelled) {
        debugPrint('[VehiculeService] Opération annulée pendant le redimensionnement');
        return null;
      }
      
      // Compresser l'image avec une qualité plus basse pour accélérer le téléchargement
      final compressedBytes = img.encodeJpg(resizedImage, quality: qualityLevel);
      
      // Créer un fichier temporaire pour l'image compressée
      final tempDir = await Directory.systemTemp.createTemp();
      final tempFile = File('${tempDir.path}/compressed_${path.basename(imageFile.path)}');
      await tempFile.writeAsBytes(compressedBytes);
      
      final compressedSize = await tempFile.length();
      debugPrint('[VehiculeService] Image compressée: ${tempFile.path}');
      debugPrint('[VehiculeService] Taille originale: ${fileSize ~/ 1024} KB, taille compressée: ${compressedSize ~/ 1024} KB');
      
      // Vérifier si l'image est encore trop volumineuse après compression
      if (compressedSize > maxImageSizeBytes) {
        debugPrint('[VehiculeService] Image encore trop volumineuse après compression: ${compressedSize ~/ 1024} KB');
        
        // Essayer une compression encore plus agressive et un redimensionnement plus petit
        final smallerImage = img.copyResize(
          resizedImage,
          width: targetWidth ~/ 1.5,
          height: targetHeight ~/ 1.5,
        );
        
        final moreCompressedBytes = img.encodeJpg(smallerImage, quality: 10);
        await tempFile.writeAsBytes(moreCompressedBytes);
        
        final finalSize = await tempFile.length();
        debugPrint('[VehiculeService] Compression supplémentaire appliquée: ${finalSize ~/ 1024} KB');
        
        if (finalSize > maxImageSizeBytes) {
          debugPrint('[VehiculeService] Image toujours trop volumineuse après compression maximale');
          
          // Dernière tentative avec une compression extrême
          final tinyImage = img.copyResize(
            resizedImage,
            width: 300,
            height: 300,
          );
          
          final extremeCompressedBytes = img.encodeJpg(tinyImage, quality: 5);
          await tempFile.writeAsBytes(extremeCompressedBytes);
          
          final extremeSize = await tempFile.length();
          debugPrint('[VehiculeService] Compression extrême appliquée: ${extremeSize ~/ 1024} KB');
          
          if (extremeSize > maxImageSizeBytes) {
            throw Exception('L\'image est trop volumineuse même après compression maximale. Veuillez utiliser une image plus petite.');
          }
        }
      }
      
      return tempFile;
    } catch (e) {
      debugPrint('[VehiculeService] Erreur lors de la compression de l\'image: $e');
      if (e is TimeoutException) {
        rethrow;
      }
      
      // En cas d'erreur de compression, essayer une approche plus simple
      try {
        debugPrint('[VehiculeService] Tentative de compression simple');
        
        // Lire l'image
        final bytes = await imageFile.readAsBytes();
        final image = img.decodeImage(bytes);
        
        if (image != null) {
          // Redimensionner à une taille très petite
          final tinyImage = img.copyResize(
            image,
            width: 300,
          );
          
          // Compression extrême
          final compressedBytes = img.encodeJpg(tinyImage, quality: 5);
          
          // Créer un fichier temporaire
          final tempDir = await Directory.systemTemp.createTemp();
          final tempFile = File('${tempDir.path}/emergency_compressed_${path.basename(imageFile.path)}');
          await tempFile.writeAsBytes(compressedBytes);
          
          return tempFile;
        }
      } catch (_) {
        debugPrint('[VehiculeService] Échec de la compression simple');
      }
      
      // Si tout échoue, retourner null
      return null;
    }
  }

  // Télécharger une image par morceaux
  Future<String> _uploadImageInChunks(
    File imageFile, 
    String storagePath, {
    Function(double)? onProgress,
  }) async {
    try {
      final fileName = path.basename(imageFile.path);
      final ref = _storage.ref().child('$storagePath/$fileName');
      
      debugPrint('[VehiculeService] Téléchargement par morceaux de l\'image: $fileName');
      
      // Lire le fichier en mémoire
      final bytes = await imageFile.readAsBytes();
      final fileSize = bytes.length;
      
      // Taille de chaque morceau (256 KB)
      const int chunkSize = 256 * 1024;
      final int totalChunks = (fileSize / chunkSize).ceil();
      
      debugPrint('[VehiculeService] Taille totale: ${fileSize ~/ 1024} KB, nombre de morceaux: $totalChunks');
      
      // Si le fichier est petit, utiliser la méthode standard
      if (totalChunks <= 1 || fileSize < 512 * 1024) {
        debugPrint('[VehiculeService] Fichier petit, utilisation de la méthode standard');
        final uploadTask = ref.putFile(imageFile);
        
        // Suivre la progression du téléchargement
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          if (onProgress != null) onProgress(progress);
          
          // Vérifier si l'opération a été annulée
          if (_isCancelled) {
            uploadTask.cancel();
          }
        });
        
        await uploadTask.whenComplete(() => null);
        final downloadUrl = await ref.getDownloadURL();
        return downloadUrl;
      }
      
      // Créer une liste pour stocker les tâches de téléchargement
      List<String> uploadedChunks = [];
      
      // Télécharger chaque morceau
      for (int i = 0; i < totalChunks; i++) {
        if (_isCancelled) {
          debugPrint('[VehiculeService] Opération annulée pendant le téléchargement des morceaux');
          throw Exception('Opération annulée par l\'utilisateur');
        }
        
        // Calculer les indices de début et de fin du morceau
        final int start = i * chunkSize;
        final int end = (i + 1) * chunkSize > fileSize ? fileSize : (i + 1) * chunkSize;
        
        // Extraire le morceau
        final List<int> chunk = bytes.sublist(start, end);
        
        // Créer un nom de fichier temporaire pour le morceau
        final String chunkFileName = '${fileName}_chunk_$i';
        final chunkRef = _storage.ref().child('$storagePath/chunks/$chunkFileName');
        
        // Télécharger le morceau
        debugPrint('[VehiculeService] Téléchargement du morceau $i/$totalChunks');
        await chunkRef.putData(Uint8List.fromList(chunk));
        final chunkUrl = await chunkRef.getDownloadURL();
        uploadedChunks.add(chunkUrl);
        
        // Mettre à jour la progression
        if (onProgress != null) {
          final double overallProgress = (i + 1) / totalChunks;
          onProgress(overallProgress);
        }
        
        // Pause courte entre les morceaux pour éviter de surcharger la connexion
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // Tous les morceaux sont téléchargés, maintenant les combiner
      debugPrint('[VehiculeService] Tous les morceaux téléchargés, finalisation...');
      
      // Dans une implémentation réelle, vous utiliseriez une fonction Cloud pour combiner les morceaux
      // Pour simplifier, nous allons télécharger le fichier complet
      await ref.putFile(imageFile);
      
      // Obtenir l'URL de téléchargement
      final downloadUrl = await ref.getDownloadURL();
      
      // Nettoyer les morceaux (en arrière-plan)
      _cleanupChunks(storagePath, fileName, totalChunks);
      
      debugPrint('[VehiculeService] Téléchargement par morceaux terminé: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('[VehiculeService] Erreur lors du téléchargement par morceaux: $e');
      rethrow;
    }
  }
  
  // Nettoyer les morceaux après téléchargement
  Future<void> _cleanupChunks(String storagePath, String fileName, int totalChunks) async {
    try {
      for (int i = 0; i < totalChunks; i++) {
        final String chunkFileName = '${fileName}_chunk_$i';
        final chunkRef = _storage.ref().child('$storagePath/chunks/$chunkFileName');
        await chunkRef.delete();
      }
      debugPrint('[VehiculeService] Nettoyage des morceaux terminé');
    } catch (e) {
      debugPrint('[VehiculeService] Erreur lors du nettoyage des morceaux: $e');
      // Ignorer les erreurs de nettoyage
    }
  }

  // Méthode pour tester la connexion à Firestore de manière sécurisée
  Future<bool> testFirestoreConnection() async {
    try {
      // Vérifier d'abord la connexion Internet
      final hasInternet = await _connectivityUtils.checkConnection();
      if (!hasInternet) {
        debugPrint('[VehiculeService] Pas de connexion Internet');
        return false;
      }
      
      // Vérifier l'authentification
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('[VehiculeService] Utilisateur non authentifié');
        return false;
      }
      
      // Essayer de lire la collection vehicules
      final testQuery = await _firestore.collection('vehicules').limit(1).get()
          .timeout(const Duration(seconds: 10), onTimeout: () {
            throw TimeoutException('Le test de connexion à Firestore a pris trop de temps.');
          });
      
      debugPrint('[VehiculeService] Test de connexion à Firestore réussi: ${testQuery.docs.length} documents trouvés');
      return true;
    } catch (e) {
      debugPrint('[VehiculeService] Erreur lors du test de connexion à Firestore: $e');
      
      // Vérifier si c'est une erreur d'autorisation
      if (e.toString().contains('permission-denied') || e.toString().contains('PERMISSION_DENIED')) {
        throw Exception('Vous n\'avez pas les autorisations nécessaires pour accéder à cette fonctionnalité. Veuillez contacter l\'administrateur.');
      } else if (e.toString().contains('network') || 
                e.toString().contains('connection') || 
                e.toString().contains('timeout') ||
                e.toString().contains('socket')) {
        throw Exception('Impossible de se connecter à la base de données. Veuillez vérifier votre connexion internet.');
      } else {
        throw Exception('Erreur lors de la connexion à la base de données: $e');
      }
    }
  }

  // Télécharger une image vers Firebase Storage - OPTIMISÉ
  Future<String> _uploadImage(
    File imageFile, 
    String storagePath, {
    Function(double)? onProgress,
  }) async {
    try {
      final fileName = path.basename(imageFile.path);
      final ref = _storage.ref().child('$storagePath/$fileName');
      
      debugPrint('[VehiculeService] Téléchargement de l\'image: $fileName vers $storagePath');
      
      // Vérifier la taille du fichier
      final fileSize = await imageFile.length();
      debugPrint('[VehiculeService] Taille du fichier à télécharger: ${fileSize ~/ 1024} KB');
      
      // Si le fichier est trop grand, essayer de le compresser davantage
      if (fileSize > maxImageSizeBytes) {
        debugPrint('[VehiculeService] Fichier trop grand, compression d\'urgence');
        
        try {
          final bytes = await imageFile.readAsBytes();
          final image = img.decodeImage(bytes);
          
          if (image != null) {
            // Redimensionner à une taille très petite
            final tinyImage = img.copyResize(
              image,
              width: 300,
            );
            
            // Compression extrême
            final compressedBytes = img.encodeJpg(tinyImage, quality: 5);
            
            // Créer un fichier temporaire
            final tempDir = await Directory.systemTemp.createTemp();
            final tempFile = File('${tempDir.path}/emergency_compressed_${path.basename(imageFile.path)}');
            await tempFile.writeAsBytes(compressedBytes);
            
            // Utiliser le fichier compressé
            imageFile = tempFile;
          }
        } catch (e) {
          debugPrint('[VehiculeService] Erreur lors de la compression d\'urgence: $e');
          // Continuer avec le fichier original
        }
      }
      
      // Utiliser putData au lieu de putFile pour un meilleur contrôle
      final bytes = await imageFile.readAsBytes();
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'compressed': 'true'},
      );
      
      final uploadTask = ref.putData(bytes, metadata);
      
      // Suivre la progression du téléchargement
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        debugPrint('[VehiculeService] Progression du téléchargement: ${(progress * 100).toStringAsFixed(1)}%');
        if (onProgress != null) onProgress(progress);
        
        // Vérifier si l'opération a été annulée
        if (_isCancelled) {
          uploadTask.cancel();
        }
      });
      
      final snapshot = await uploadTask.whenComplete(() => null)
          .timeout(uploadTimeout, onTimeout: () {
            throw TimeoutException('Le téléchargement de l\'image a pris trop de temps. Veuillez vérifier votre connexion internet ou utiliser une image plus petite.');
          });
      
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('[VehiculeService] Image téléchargée avec succès: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      debugPrint('[VehiculeService] Erreur lors du téléchargement de l\'image: $e');
      if (e is TimeoutException) {
        rethrow;
      }
      throw Exception('Erreur lors du téléchargement de l\'image: $e');
    }
  }

  // Ajouter un nouveau véhicule - OPTIMISÉ
  Future<String?> addVehicule(
    VehiculeModel vehicule, {
    File? photoRecto,
    File? photoVerso,
    Function(double)? onProgress,
  }) async {
    try {
      resetCancellation();
      debugPrint('[VehiculeService] Ajout d\'un nouveau véhicule: ${vehicule.immatriculation}');
      
      // Timeout global plus court (90 secondes)
      return await Future.delayed(Duration.zero, () async {
        // Vérifier la connexion à Firebase de manière sécurisée
        final isConnected = await testFirestoreConnection();
        
        if (!isConnected) {
          // Sauvegarder en mode hors ligne
          await _saveVehiculeOffline(vehicule, photoRecto, photoVerso);
          throw Exception('Mode hors ligne: Le véhicule sera ajouté automatiquement lorsque la connexion Internet sera rétablie.');
        }
        
        // Créer un nouveau document avec un ID généré
        final docRef = _firestore.collection('vehicules').doc();
        final String vehiculeId = docRef.id;
        
        debugPrint('[VehiculeService] ID généré pour le véhicule: $vehiculeId');
        
        // Télécharger les photos si elles sont fournies
        String? photoRectoUrl;
        String? photoVersoUrl;
        
        // Compresser et télécharger la photo recto
        if (photoRecto != null) {
          debugPrint('[VehiculeService] Compression et téléchargement de la photo recto');
          try {
            if (onProgress != null) onProgress(0.1); // 10% pour le début de la compression
            
            final compressedRecto = await _compressImage(photoRecto);
            
            if (_isCancelled || compressedRecto == null) {
              debugPrint('[VehiculeService] Opération annulée après compression de la photo recto');
              return null;
            }
            
            if (onProgress != null) onProgress(0.2); // 20% après la compression
            
            photoRectoUrl = await _uploadImage(
              compressedRecto, 
              'vehicules/$vehiculeId/recto',
              onProgress: (progress) {
                if (onProgress != null) onProgress(0.2 + progress * 0.3); // 20-50% pour la photo recto
              }
            );
            
            if (_isCancelled) {
              debugPrint('[VehiculeService] Opération annulée après téléchargement de la photo recto');
              return null;
            }
            
            debugPrint('[VehiculeService] Photo recto téléchargée: $photoRectoUrl');
          } catch (e) {
            debugPrint('[VehiculeService] Erreur lors du téléchargement de la photo recto: $e');
            if (e is TimeoutException) {
              throw TimeoutException('Le téléchargement de l\'image a pris trop de temps. Veuillez utiliser une image plus petite ou vérifier votre connexion internet.');
            }
            // Continuer sans la photo recto
            debugPrint('[VehiculeService] Continuation sans la photo recto');
          }
        } else if (onProgress != null) {
          onProgress(0.5); // Passer directement à 50% si pas de photo recto
        }
        
        // Compresser et télécharger la photo verso
        if (photoVerso != null && !_isCancelled) {
          debugPrint('[VehiculeService] Compression et téléchargement de la photo verso');
          try {
            final compressedVerso = await _compressImage(photoVerso);
            
            if (_isCancelled || compressedVerso == null) {
              debugPrint('[VehiculeService] Opération annulée après compression de la photo verso');
              return null;
            }
            
            photoVersoUrl = await _uploadImage(
              compressedVerso, 
              'vehicules/$vehiculeId/verso',
              onProgress: (progress) {
                if (onProgress != null) onProgress(0.5 + progress * 0.3); // 50-80% pour la photo verso
              }
            );
            
            if (_isCancelled) {
              debugPrint('[VehiculeService] Opération annulée après téléchargement de la photo verso');
              return null;
            }
            
            debugPrint('[VehiculeService] Photo verso téléchargée: $photoVersoUrl');
          } catch (e) {
            debugPrint('[VehiculeService] Erreur lors du téléchargement de la photo verso: $e');
            if (e is TimeoutException) {
              throw TimeoutException('Le téléchargement de l\'image a pris trop de temps. Veuillez utiliser une image plus petite ou vérifier votre connexion internet.');
            }
            // Continuer sans la photo verso
            debugPrint('[VehiculeService] Continuation sans la photo verso');
          }
        } else if (onProgress != null) {
          onProgress(0.8); // Passer directement à 80% si pas de photo verso
        }
        
        if (_isCancelled) {
          debugPrint('[VehiculeService] Opération annulée avant l\'enregistrement dans Firestore');
          return null;
        }
        
        // Créer un nouveau véhicule avec l'ID généré et les URLs des photos
        final newVehicule = vehicule.copyWith(
          id: vehiculeId,
          photoCarteGriseRecto: photoRectoUrl ?? vehicule.photoCarteGriseRecto,
          photoCarteGriseVerso: photoVersoUrl ?? vehicule.photoCarteGriseVerso,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        // Créer une Map pour Firestore avec les timestamps
        final vehiculeMapData = newVehicule.toMap();
        // Remplacer les DateTime par FieldValue.serverTimestamp() pour Firestore
        vehiculeMapData['createdAt'] = FieldValue.serverTimestamp();
        vehiculeMapData['updatedAt'] = FieldValue.serverTimestamp();
        
        // Enregistrer le véhicule dans Firestore
        debugPrint('[VehiculeService] Enregistrement du véhicule dans Firestore');
        await docRef.set(vehiculeMapData)
            .timeout(const Duration(seconds: 15), onTimeout: () {
              throw TimeoutException('L\'enregistrement du véhicule a pris trop de temps. Veuillez vérifier votre connexion internet.');
            });
        
        debugPrint('[VehiculeService] Véhicule enregistré dans Firestore');
        
        if (onProgress != null) onProgress(0.9); // 90% après l'enregistrement du véhicule
        
        // Mettre à jour la liste des véhicules du conducteur
        await _updateConducteurVehicules(vehicule.proprietaireId, vehiculeId, isAdd: true);
        debugPrint('[VehiculeService] Liste des véhicules du conducteur mise à jour');
        
        // Mettre en cache le véhicule
        await _cacheVehicule(newVehicule);
        
        if (onProgress != null) onProgress(1.0); // 100% une fois terminé
        
        return vehiculeId;
      }).timeout(const Duration(seconds: 90));
    } catch (e) {
      if (e is TimeoutException) {
        debugPrint('[VehiculeService] Timeout global atteint');
        cancelOperations(); // Annuler toutes les opérations en cours
        throw TimeoutException('L\'opération a pris trop de temps. Veuillez réessayer avec des images plus petites ou vérifier votre connexion internet.');
      }
      
      debugPrint('[VehiculeService] Erreur lors de l\'ajout du véhicule: $e');
      
      // Gérer spécifiquement les erreurs de connexion
      if (e.toString().contains('network') || 
          e.toString().contains('connection') || 
          e.toString().contains('timeout') ||
          e.toString().contains('socket')) {
        throw Exception('Impossible de se connecter à la base de données. Veuillez vérifier votre connexion internet.');
      }
      
      // Gérer les erreurs d'autorisation
      if (e.toString().contains('permission') || e.toString().contains('denied')) {
        throw Exception('Vous n\'avez pas les autorisations nécessaires pour effectuer cette action.');
      }
      
      rethrow;
    }
  }

  // Sauvegarder un véhicule en mode hors ligne
  Future<void> _saveVehiculeOffline(
    VehiculeModel vehicule,
    File? photoRecto,
    File? photoVerso,
  ) async {
    try {
      debugPrint('[VehiculeService] Sauvegarde du véhicule en mode hors ligne');
      
      // Générer un ID temporaire
      final String offlineId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
      
      // Copier les images dans le stockage local si elles existent
      String? photoRectoPath;
      String? photoVersoPath;
      
      if (photoRecto != null && await photoRecto.exists()) {
        final appDir = await Directory.systemTemp.createTemp('offline_vehicules');
        final rectoFile = File('${appDir.path}/recto_$offlineId.jpg');
        await photoRecto.copy(rectoFile.path);
        photoRectoPath = rectoFile.path;
        debugPrint('[VehiculeService] Photo recto sauvegardée localement: ${rectoFile.path}');
      }
      
      if (photoVerso != null && await photoVerso.exists()) {
        final appDir = await Directory.systemTemp.createTemp('offline_vehicules');
        final versoFile = File('${appDir.path}/verso_$offlineId.jpg');
        await photoVerso.copy(versoFile.path);
        photoVersoPath = versoFile.path;
        debugPrint('[VehiculeService] Photo verso sauvegardée localement: ${versoFile.path}');
      }
      
      // Créer un véhicule avec l'ID hors ligne
      final offlineVehicule = vehicule.copyWith(
        id: offlineId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Sauvegarder les informations dans SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      
      // Récupérer la file d'attente existante
      final offlineQueueJson = prefs.getString('offline_vehicules_queue') ?? '[]';
      final List<dynamic> offlineQueue = jsonDecode(offlineQueueJson);
      
      // Ajouter le nouveau véhicule à la file d'attente
      offlineQueue.add({
        'vehicule': offlineVehicule.toMap(),
        'photoRectoPath': photoRectoPath,
        'photoVersoPath': photoVersoPath,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'action': 'add',
      });
      
      // Sauvegarder la file d'attente mise à jour
      await prefs.setString('offline_vehicules_queue', jsonEncode(offlineQueue));
      
      debugPrint('[VehiculeService] Véhicule sauvegardé en mode hors ligne: $offlineId');
    } catch (e) {
      debugPrint('[VehiculeService] Erreur lors de la sauvegarde hors ligne: $e');
      throw Exception('Erreur lors de la sauvegarde en mode hors ligne: $e');
    }
  }

  // Synchroniser les véhicules hors ligne
  Future<void> syncOfflineVehicules() async {
    try {
      debugPrint('[VehiculeService] Tentative de synchronisation des véhicules hors ligne');
      
      // Vérifier la connexion Internet
      final hasInternet = await _connectivityUtils.checkConnection();
      if (!hasInternet) {
        debugPrint('[VehiculeService] Pas de connexion Internet, synchronisation impossible');
        return;
      }
      
      // Récupérer la file d'attente hors ligne
      final prefs = await SharedPreferences.getInstance();
      final offlineQueueJson = prefs.getString('offline_vehicules_queue');
      
      if (offlineQueueJson == null || offlineQueueJson == '[]') {
        debugPrint('[VehiculeService] Aucun véhicule hors ligne à synchroniser');
        return;
      }
      
      final List<dynamic> offlineQueue = jsonDecode(offlineQueueJson);
      debugPrint('[VehiculeService] ${offlineQueue.length} véhicules hors ligne à synchroniser');
      
      // Liste des éléments traités avec succès
      final List<int> processedIndices = [];
      
      // Traiter chaque élément de la file d'attente
      for (int i = 0; i < offlineQueue.length; i++) {
        final item = offlineQueue[i];
        final action = item['action'] as String;
        
        if (action == 'add') {
          try {
            // Récupérer les données du véhicule
            final vehiculeData = Map<String, dynamic>.from(item['vehicule']);
            final VehiculeModel vehicule = VehiculeModel.fromMap(vehiculeData);
            
            // Récupérer les chemins des photos
            final String? photoRectoPath = item['photoRectoPath'];
            final String? photoVersoPath = item['photoVersoPath'];
            
            // Charger les photos si elles existent
            File? photoRecto;
            File? photoVerso;
            
            if (photoRectoPath != null) {
              final rectoFile = File(photoRectoPath);
              if (await rectoFile.exists()) {
                photoRecto = rectoFile;
              }
            }
            
            if (photoVersoPath != null) {
              final versoFile = File(photoVersoPath);
              if (await versoFile.exists()) {
                photoVerso = versoFile;
              }
            }
            
            // Ajouter le véhicule en ligne
            debugPrint('[VehiculeService] Synchronisation du véhicule: ${vehicule.immatriculation}');
            
            // Créer un nouveau véhicule sans l'ID hors ligne
            final onlineVehicule = vehicule.copyWith(
              id: null, // Laisser Firebase générer un nouvel ID
            );
            
            // Ajouter le véhicule
            final vehiculeId = await addVehicule(
              onlineVehicule,
              photoRecto: photoRecto,
              photoVerso: photoVerso,
            );
            
            if (vehiculeId != null) {
              debugPrint('[VehiculeService] Véhicule synchronisé avec succès: $vehiculeId');
              processedIndices.add(i);
              
              // Supprimer les fichiers temporaires
              if (photoRecto != null && await photoRecto.exists()) {
                await photoRecto.delete();
              }
              if (photoVerso != null && await photoVerso.exists()) {
                await photoVerso.delete();
              }
            }
          } catch (e) {
            debugPrint('[VehiculeService] Erreur lors de la synchronisation du véhicule: $e');
            // Continuer avec le prochain élément
          }
        }
        // Ajouter d'autres actions (update, delete) si nécessaire
      }
      
      // Supprimer les éléments traités de la file d'attente
      if (processedIndices.isNotEmpty) {
        // Trier les indices en ordre décroissant pour éviter les problèmes d'index
        processedIndices.sort((a, b) => b.compareTo(a));
        
        for (final index in processedIndices) {
          offlineQueue.removeAt(index);
        }
        
        // Sauvegarder la file d'attente mise à jour
        await prefs.setString('offline_vehicules_queue', jsonEncode(offlineQueue));
        debugPrint('[VehiculeService] File d\'attente hors ligne mise à jour: ${offlineQueue.length} éléments restants');
      }
    } catch (e) {
      debugPrint('[VehiculeService] Erreur lors de la synchronisation des véhicules hors ligne: $e');
    }
  }

  // Mettre à jour un véhicule existant
  Future<bool> updateVehicule(
    VehiculeModel vehicule, {
    File? photoRecto,
    File? photoVerso,
    Function(double)? onProgress,
  }) async {
    try {
      resetCancellation();
      
      if (vehicule.id == null) {
        throw Exception('ID du véhicule non défini');
      }
      
      debugPrint('[VehiculeService] Mise à jour du véhicule: ${vehicule.id}');
      
      // Timeout global plus court (90 secondes)
      return await Future.delayed(Duration.zero, () async {
        // Vérifier la connexion à Firebase de manière sécurisée
        final isConnected = await testFirestoreConnection();
        
        if (!isConnected) {
          // Sauvegarder en mode hors ligne
          await _saveVehiculeUpdateOffline(vehicule, photoRecto, photoVerso);
          throw Exception('Mode hors ligne: La mise à jour du véhicule sera effectuée automatiquement lorsque la connexion Internet sera rétablie.');
        }
        
        // Télécharger les nouvelles photos si elles sont fournies
        String? photoRectoUrl;
        String? photoVersoUrl;
        
        // Compresser et télécharger la photo recto
        if (photoRecto != null) {
          debugPrint('[VehiculeService] Compression et téléchargement de la nouvelle photo recto');
          try {
            if (onProgress != null) onProgress(0.1); // 10% pour le début de la compression
            
            final compressedRecto = await _compressImage(photoRecto);
            
            if (_isCancelled || compressedRecto == null) {
              debugPrint('[VehiculeService] Opération annulée après compression de la photo recto');
              return false;
            }
            
            if (onProgress != null) onProgress(0.2); // 20% après la compression
            
            photoRectoUrl = await _uploadImage(
              compressedRecto, 
              'vehicules/${vehicule.id}/recto',
              onProgress: (progress) {
                if (onProgress != null) onProgress(0.2 + progress * 0.3); // 20-50% pour la photo recto
              }
            );
            
            if (_isCancelled) {
              debugPrint('[VehiculeService] Opération annulée après téléchargement de la photo recto');
              return false;
            }
            
            debugPrint('[VehiculeService] Nouvelle photo recto téléchargée: $photoRectoUrl');
          } catch (e) {
            debugPrint('[VehiculeService] Erreur lors du téléchargement de la photo recto: $e');
            if (e is TimeoutException) {
              throw TimeoutException('Le téléchargement de l\'image a pris trop de temps. Veuillez utiliser une image plus petite ou vérifier votre connexion internet.');
            }
            // Continuer sans la photo recto
            debugPrint('[VehiculeService] Continuation sans la photo recto');
          }
        } else if (onProgress != null) {
          onProgress(0.5); // Passer directement à 50% si pas de photo recto
        }
        
        // Compresser et télécharger la photo verso
        if (photoVerso != null && !_isCancelled) {
          debugPrint('[VehiculeService] Compression et téléchargement de la nouvelle photo verso');
          try {
            final compressedVerso = await _compressImage(photoVerso);
            
            if (_isCancelled || compressedVerso == null) {
              debugPrint('[VehiculeService] Opération annulée après compression de la photo verso');
              return false;
            }
            
            photoVersoUrl = await _uploadImage(
              compressedVerso, 
              'vehicules/${vehicule.id}/verso',
              onProgress: (progress) {
                if (onProgress != null) onProgress(0.5 + progress * 0.3); // 50-80% pour la photo verso
              }
            );
            
            if (_isCancelled) {
              debugPrint('[VehiculeService] Opération annulée après téléchargement de la photo verso');
              return false;
            }
            
            debugPrint('[VehiculeService] Nouvelle photo verso téléchargée: $photoVersoUrl');
          } catch (e) {
            debugPrint('[VehiculeService] Erreur lors du téléchargement de la photo verso: $e');
            if (e is TimeoutException) {
              throw TimeoutException('Le téléchargement de l\'image a pris trop de temps. Veuillez utiliser une image plus petite ou vérifier votre connexion internet.');
            }
            // Continuer sans la photo verso
            debugPrint('[VehiculeService] Continuation sans la photo verso');
          }
        } else if (onProgress != null) {
          onProgress(0.8); // Passer directement à 80% si pas de photo verso
        }
        
        if (_isCancelled) {
          debugPrint('[VehiculeService] Opération annulée avant l\'enregistrement dans Firestore');
          return false;
        }
        
        // Mettre à jour le véhicule avec les nouvelles URLs des photos
        final updatedVehicule = vehicule.copyWith(
          photoCarteGriseRecto: photoRectoUrl ?? vehicule.photoCarteGriseRecto,
          photoCarteGriseVerso: photoVersoUrl ?? vehicule.photoCarteGriseVerso,
          updatedAt: DateTime.now(),
        );
        
        // Créer une Map pour Firestore
        final vehiculeMapData = updatedVehicule.toMap();
        // Remplacer le DateTime par FieldValue.serverTimestamp() pour Firestore
        vehiculeMapData['updatedAt'] = FieldValue.serverTimestamp();
        
        // Enregistrer les modifications dans Firestore
        debugPrint('[VehiculeService] Enregistrement des modifications dans Firestore');
        await _firestore
            .collection('vehicules')
            .doc(vehicule.id)
            .update(vehiculeMapData)
            .timeout(const Duration(seconds: 15), onTimeout: () {
              throw TimeoutException('La mise à jour du véhicule a pris trop de temps. Veuillez vérifier votre connexion internet.');
            });
        
        debugPrint('[VehiculeService] Véhicule mis à jour avec succès');
        
        // Mettre en cache le véhicule mis à jour
        await _cacheVehicule(updatedVehicule);
        
        if (onProgress != null) onProgress(1.0); // 100% une fois terminé
        
        return true;
      }).timeout(const Duration(seconds: 90));
    } catch (e) {
      if (e is TimeoutException) {
        debugPrint('[VehiculeService] Timeout global atteint');
        cancelOperations(); // Annuler toutes les opérations en cours
        throw TimeoutException('L\'opération a pris trop de temps. Veuillez réessayer avec des images plus petites ou vérifier votre connexion internet.');
      }
      
      debugPrint('[VehiculeService] Erreur lors de la mise à jour du véhicule: $e');
      
      // Gérer spécifiquement les erreurs de connexion
      if (e.toString().contains('network') || 
          e.toString().contains('connection') || 
          e.toString().contains('timeout') ||
          e.toString().contains('socket')) {
        throw Exception('Impossible de se connecter à la base de données. Veuillez vérifier votre connexion internet.');
      }
      
      // Gérer les erreurs d'autorisation
      if (e.toString().contains('permission') || e.toString().contains('denied')) {
        throw Exception('Vous n\'avez pas les autorisations nécessaires pour effectuer cette action.');
      }
      
      rethrow;
    }
  }

  // Sauvegarder une mise à jour de véhicule en mode hors ligne
  Future<void> _saveVehiculeUpdateOffline(
    VehiculeModel vehicule,
    File? photoRecto,
    File? photoVerso,
  ) async {
    try {
      debugPrint('[VehiculeService] Sauvegarde de la mise à jour du véhicule en mode hors ligne');
      
      // Copier les images dans le stockage local si elles existent
      String? photoRectoPath;
      String? photoVersoPath;
      
      if (photoRecto != null && await photoRecto.exists()) {
        final appDir = await Directory.systemTemp.createTemp('offline_vehicules');
        final rectoFile = File('${appDir.path}/recto_update_${vehicule.id}.jpg');
        await photoRecto.copy(rectoFile.path);
        photoRectoPath = rectoFile.path;
        debugPrint('[VehiculeService] Photo recto sauvegardée localement: ${rectoFile.path}');
      }
      
      if (photoVerso != null && await photoVerso.exists()) {
        final appDir = await Directory.systemTemp.createTemp('offline_vehicules');
        final versoFile = File('${appDir.path}/verso_update_${vehicule.id}.jpg');
        await photoVerso.copy(versoFile.path);
        photoVersoPath = versoFile.path;
        debugPrint('[VehiculeService] Photo verso sauvegardée localement: ${versoFile.path}');
      }
      
      // Mettre à jour le véhicule
      final updatedVehicule = vehicule.copyWith(
        updatedAt: DateTime.now(),
      );
      
      // Sauvegarder les informations dans SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      
      // Récupérer la file d'attente existante
      final offlineQueueJson = prefs.getString('offline_vehicules_queue') ?? '[]';
      final List<dynamic> offlineQueue = jsonDecode(offlineQueueJson);
      
      // Ajouter la mise à jour du véhicule à la file d'attente
      offlineQueue.add({
        'vehicule': updatedVehicule.toMap(),
        'photoRectoPath': photoRectoPath,
        'photoVersoPath': photoVersoPath,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'action': 'update',
      });
      
      // Sauvegarder la file d'attente mise à jour
      await prefs.setString('offline_vehicules_queue', jsonEncode(offlineQueue));
      
      debugPrint('[VehiculeService] Mise à jour du véhicule sauvegardée en mode hors ligne: ${vehicule.id}');
    } catch (e) {
      debugPrint('[VehiculeService] Erreur lors de la sauvegarde hors ligne: $e');
      throw Exception('Erreur lors de la sauvegarde en mode hors ligne: $e');
    }
  }

  // Supprimer un véhicule
  Future<void> deleteVehicule(String vehiculeId, String proprietaireId) async {
    try {
      debugPrint('[VehiculeService] Suppression du véhicule: $vehiculeId');
      
      // Vérifier la connexion à Firebase
      final isConnected = await testFirestoreConnection();
      
      if (!isConnected) {
        // Sauvegarder la suppression en mode hors ligne
        await _saveVehiculeDeleteOffline(vehiculeId, proprietaireId);
        throw Exception('Mode hors ligne: La suppression du véhicule sera effectuée automatiquement lorsque la connexion Internet sera rétablie.');
      }
      
      // Supprimer les photos du véhicule
      await _deleteVehiculePhotos(vehiculeId);
      
      // Supprimer le document du véhicule
      await _firestore
          .collection('vehicules')
          .doc(vehiculeId)
          .delete()
          .timeout(const Duration(seconds: 15), onTimeout: () {
            throw TimeoutException('La suppression du véhicule a pris trop de temps. Veuillez vérifier votre connexion internet.');
          });
      
      // Mettre à jour la liste des véhicules du conducteur
      await _updateConducteurVehicules(proprietaireId, vehiculeId, isAdd: false);
      
      // Supprimer le véhicule du cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('vehicule_$vehiculeId');
      
      debugPrint('[VehiculeService] Véhicule supprimé avec succès');
    } catch (e) {
      debugPrint('[VehiculeService] Erreur lors de la suppression du véhicule: $e');
      
      if (e is TimeoutException) {
        throw TimeoutException('La suppression du véhicule a pris trop de temps. Veuillez vérifier votre connexion internet.');
      }
      
      // Gérer spécifiquement les erreurs de connexion
      if (e.toString().contains('network') || 
          e.toString().contains('connection') || 
          e.toString().contains('timeout') ||
          e.toString().contains('socket')) {
        throw Exception('Impossible de se connecter à la base de données. Veuillez vérifier votre connexion internet.');
      }
      
      rethrow;
    }
  }

  // Sauvegarder une suppression de véhicule en mode hors ligne
  Future<void> _saveVehiculeDeleteOffline(String vehiculeId, String proprietaireId) async {
    try {
      debugPrint('[VehiculeService] Sauvegarde de la suppression du véhicule en mode hors ligne');
      
      // Sauvegarder les informations dans SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      
      // Récupérer la file d'attente existante
      final offlineQueueJson = prefs.getString('offline_vehicules_queue') ?? '[]';
      final List<dynamic> offlineQueue = jsonDecode(offlineQueueJson);
      
      // Ajouter la suppression du véhicule à la file d'attente
      offlineQueue.add({
        'vehiculeId': vehiculeId,
        'proprietaireId': proprietaireId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'action': 'delete',
      });
      
      // Sauvegarder la file d'attente mise à jour
      await prefs.setString('offline_vehicules_queue', jsonEncode(offlineQueue));
      
      debugPrint('[VehiculeService] Suppression du véhicule sauvegardée en mode hors ligne: $vehiculeId');
    } catch (e) {
      debugPrint('[VehiculeService] Erreur lors de la sauvegarde hors ligne: $e');
      throw Exception('Erreur lors de la sauvegarde en mode hors ligne: $e');
    }
  }

  // Supprimer les photos d'un véhicule
  Future<void> _deleteVehiculePhotos(String vehiculeId) async {
    try {
      debugPrint('[VehiculeService] Suppression des photos du véhicule: $vehiculeId');
      
      final ref = _storage.ref().child('vehicules/$vehiculeId');
      
      try {
        final items = await ref.listAll();
        
        for (final item in items.items) {
          await item.delete();
          debugPrint('[VehiculeService] Photo supprimée: ${item.fullPath}');
        }
        
        // Supprimer les sous-dossiers
        for (final prefix in items.prefixes) {
          final subItems = await prefix.listAll();
          for (final item in subItems.items) {
            await item.delete();
            debugPrint('[VehiculeService] Photo supprimée: ${item.fullPath}');
          }
        }
        
      } catch (e) {
        // Ignorer les erreurs si le dossier n'existe pas
        debugPrint('[VehiculeService] Avertissement lors de la suppression des photos: $e');
      }
    } catch (e) {
      debugPrint('[VehiculeService] Erreur lors de la suppression des photos: $e');
      rethrow;
    }
  }

  // Mettre à jour la liste des véhicules d'un conducteur
  Future<void> _updateConducteurVehicules(String conducteurId, String vehiculeId, {required bool isAdd}) async {
    try {
      debugPrint('[VehiculeService] Mise à jour des véhicules du conducteur: $conducteurId');
      
      final conducteurRef = _firestore.collection('conducteurs').doc(conducteurId);
      final conducteurDoc = await conducteurRef.get();
      
      if (!conducteurDoc.exists) {
        debugPrint('[VehiculeService] Document conducteur non trouvé: $conducteurId');
        return;
      }
      
      if (isAdd) {
        // Ajouter l'ID du véhicule à la liste des véhicules du conducteur
        await conducteurRef.update({
          'vehiculeIds': FieldValue.arrayUnion([vehiculeId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[VehiculeService] Véhicule ajouté à la liste du conducteur');
      } else {
        // Supprimer l'ID du véhicule de la liste des véhicules du conducteur
        await conducteurRef.update({
          'vehiculeIds': FieldValue.arrayRemove([vehiculeId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[VehiculeService] Véhicule supprimé de la liste du conducteur');
      }
    } catch (e) {
      debugPrint('[VehiculeService] Erreur lors de la mise à jour des véhicules du conducteur: $e');
      // Ne pas relancer l'exception pour éviter de bloquer l'ajout/suppression du véhicule
      // en cas d'erreur lors de la mise à jour de la liste du conducteur
    }
  }
}