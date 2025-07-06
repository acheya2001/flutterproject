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
  final int maxImageSizeBytes = 1 * 1024 * 1024; // 1 MB
 final Duration uploadTimeout = const Duration(seconds: 60); // Augmenté à 60 secondes

  
  // Variable pour suivre l'annulation des opérations
  bool _isCancelled = false;
  
  // Méthode pour annuler les opérations en cours
  void cancelOperations() {
    _isCancelled = true;
    debugPrint('[VehiculeService] Annulation des opérations en cours');
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
  
  // Récupérer un véhicule par son ID
  Future<VehiculeModel?> getVehiculeById(String vehiculeId) async {
    try {
      // Essayer d'abord de récupérer depuis le cache
      final cachedVehicule = await _getVehiculeFromCache(vehiculeId);
      if (cachedVehicule != null) {
        debugPrint('[VehiculeService] Véhicule récupéré du cache: $vehiculeId');
        return cachedVehicule;
      }

      // Sinon, récupérer depuis Firestore
      final doc = await _firestore.collection('vehicules').doc(vehiculeId).get();
      
      if (!doc.exists) {
        debugPrint('[VehiculeService] Véhicule non trouvé: $vehiculeId');
        return null;
      }
      
      final vehicule = VehiculeModel.fromFirestore(doc);
      
      // Mettre en cache pour les prochaines requêtes
      await _cacheVehicule(vehicule);
      
      debugPrint('[VehiculeService] Véhicule récupéré: $vehiculeId');
      return vehicule;
    } catch (e) {
      debugPrint('[VehiculeService] Erreur lors de la récupération du véhicule: $e');
      return null;
    }
  }

  // Mettre en cache les véhicules
  Future<void> _cacheVehicules(String proprietaireId, List<VehiculeModel> vehicules) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convertir les véhicules en JSON
      final List<Map<String, dynamic>> vehiculesJson = vehicules.map((v) {
        final map = v.toMap();
        
        // Convertir les DateTime en chaînes ISO8601
        if (map['createdAt'] is DateTime) {
          map['createdAt'] = (map['createdAt'] as DateTime).toIso8601String();
        }
        if (map['updatedAt'] is DateTime) {
          map['updatedAt'] = (map['updatedAt'] as DateTime).toIso8601String();
        }
        if (map['dateDebutValidite'] is DateTime) {
          map['dateDebutValidite'] = (map['dateDebutValidite'] as DateTime).toIso8601String();
        }
        if (map['dateFinValidite'] is DateTime) {
          map['dateFinValidite'] = (map['dateFinValidite'] as DateTime).toIso8601String();
        }
        
        return map;
      }).toList();
      
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
        
        // Convertir les chaînes ISO8601 en DateTime
        if (data['createdAt'] is String) {
          data['createdAt'] = DateTime.parse(data['createdAt']);
        }
        if (data['updatedAt'] is String) {
          data['updatedAt'] = DateTime.parse(data['updatedAt']);
        }
        if (data['dateDebutValidite'] is String) {
          data['dateDebutValidite'] = DateTime.parse(data['dateDebutValidite']);
        }
        if (data['dateFinValidite'] is String) {
          data['dateFinValidite'] = DateTime.parse(data['dateFinValidite']);
        }
        
        return VehiculeModel.fromMap(data);
      }).toList();
      
      debugPrint('[VehiculeService] ${vehicules.length} véhicules récupérés du cache');
      return vehicules;
    } catch (e) {
      debugPrint('[VehiculeService] Erreur lors de la lecture du cache: $e');
      return [];
    }
  }

  // Mettre en cache un véhicule
  Future<void> _cacheVehicule(VehiculeModel vehicule) async {
    try {
      if (vehicule.id == null) {
        debugPrint('[VehiculeService] Impossible de mettre en cache un véhicule sans ID');
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      
      // Convertir le véhicule en JSON
      final vehiculeMap = vehicule.toMap();
      
      // Convertir les DateTime en chaînes ISO8601
      if (vehiculeMap['createdAt'] is DateTime) {
        vehiculeMap['createdAt'] = (vehiculeMap['createdAt'] as DateTime).toIso8601String();
      }
      if (vehiculeMap['updatedAt'] is DateTime) {
        vehiculeMap['updatedAt'] = (vehiculeMap['updatedAt'] as DateTime).toIso8601String();
      }
      if (vehiculeMap['dateDebutValidite'] is DateTime) {
        vehiculeMap['dateDebutValidite'] = (vehiculeMap['dateDebutValidite'] as DateTime).toIso8601String();
      }
      if (vehiculeMap['dateFinValidite'] is DateTime) {
        vehiculeMap['dateFinValidite'] = (vehiculeMap['dateFinValidite'] as DateTime).toIso8601String();
      }
      
      await prefs.setString('vehicule_${vehicule.id}', jsonEncode(vehiculeMap));
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
      
      // Convertir les chaînes ISO8601 en DateTime
      if (decodedJson['createdAt'] is String) {
        decodedJson['createdAt'] = DateTime.parse(decodedJson['createdAt']);
      }
      if (decodedJson['updatedAt'] is String) {
        decodedJson['updatedAt'] = DateTime.parse(decodedJson['updatedAt']);
      }
      if (decodedJson['dateDebutValidite'] is String) {
        decodedJson['dateDebutValidite'] = DateTime.parse(decodedJson['dateDebutValidite']);
      }
      if (decodedJson['dateFinValidite'] is String) {
        decodedJson['dateFinValidite'] = DateTime.parse(decodedJson['dateFinValidite']);
      }
      
      final vehicule = VehiculeModel.fromMap(decodedJson);
      
      debugPrint('[VehiculeService] Véhicule récupéré du cache: $vehiculeId');
      return vehicule;
    } catch (e) {
      debugPrint('[VehiculeService] Erreur lors de la lecture du cache: $e');
      return null;
    }
  }

  // Compresser une image
  Future<File?> _compressImage(File imageFile) async {
    try {
      debugPrint('[VehiculeService] Compression de l\'image: ${imageFile.path}');
      
      // Limites de taille pour les images
      const int maxImageWidth = 1200;
      const int maxImageHeight = 1200;
      
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
      
      // Lire l'image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
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
      
      // Redimensionner l'image
      resizedImage = img.copyResize(
        image,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.average,
      );
      
      // Compresser l'image avec une qualité plus basse pour accélérer le téléchargement
      final compressedBytes = img.encodeJpg(resizedImage, quality: qualityLevel);
      
      // Créer un fichier temporaire pour l'image compressée
      final tempDir = await Directory.systemTemp.createTemp();
      final tempFile = File('${tempDir.path}/compressed_${path.basename(imageFile.path)}');
      await tempFile.writeAsBytes(compressedBytes);
      
      final compressedSize = await tempFile.length();
      debugPrint('[VehiculeService] Image compressée: ${tempFile.path}');
      debugPrint('[VehiculeService] Taille originale: ${fileSize ~/ 1024} KB, taille compressée: ${compressedSize ~/ 1024} KB');
      
      return tempFile;
    } catch (e) {
      debugPrint('[VehiculeService] Erreur lors de la compression de l\'image: $e');
      
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
      } catch (innerError) {
        debugPrint('[VehiculeService] Erreur lors de la compression simple: $innerError');
      }
      
      // Si toutes les tentatives échouent, retourner null
      return null;
    }
  }

  // Télécharger une image directement sans compression complexe
  Future<String?> _uploadImageDirect(
    File imageFile,
    String storagePath, {
    Function(double)? onProgress,
  }) async {
    try {
      debugPrint('[VehiculeService] 🚀 DÉBUT téléchargement direct: ${imageFile.path}');
      debugPrint('[VehiculeService] 📂 Chemin de stockage: $storagePath');

      // Vérifier que le fichier existe
      if (!await imageFile.exists()) {
        debugPrint('[VehiculeService] ❌ Le fichier n\'existe pas: ${imageFile.path}');
        throw Exception('Le fichier image n\'existe pas');
      }
      debugPrint('[VehiculeService] ✅ Fichier existe');

      // Vérifier l'état de Firebase et réinitialiser si nécessaire
      debugPrint('[VehiculeService] 🔄 Vérification Firebase Storage...');

      try {
        // Test rapide de Firebase Storage
        final storage = FirebaseStorage.instance;
        final testRef = storage.ref().child('test_connection');
        await testRef.getDownloadURL().timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Test connexion timeout')
        );
      } catch (e) {
        debugPrint('[VehiculeService] ⚠️ Test connexion Firebase: $e');
        // Continuer quand même, l'erreur sera gérée plus tard
      }

      final storage = FirebaseStorage.instance;

      // Créer une référence au fichier dans Firebase Storage
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final fullPath = '$storagePath/$fileName';
      final ref = storage.ref().child(fullPath);

      debugPrint('[VehiculeService] 📁 Chemin complet Firebase: $fullPath');

      // Vérifier la taille du fichier
      final fileSize = await imageFile.length();
      debugPrint('[VehiculeService] 📊 Taille du fichier: ${fileSize ~/ 1024} KB');

      // Compression simple si le fichier est très volumineux
      File finalFile = imageFile;
      if (fileSize > 5 * 1024 * 1024) { // Plus de 5 MB
        debugPrint('[VehiculeService] Fichier très volumineux, compression simple');
        try {
          final bytes = await imageFile.readAsBytes();
          final image = img.decodeImage(bytes);

          if (image != null) {
            // Redimensionner simplement
            final resizedImage = img.copyResize(image, width: 800);
            final compressedBytes = img.encodeJpg(resizedImage, quality: 70);

            // Créer un fichier temporaire
            final tempDir = await Directory.systemTemp.createTemp();
            final tempFile = File('${tempDir.path}/resized_${path.basename(imageFile.path)}');
            await tempFile.writeAsBytes(compressedBytes);

            finalFile = tempFile;
            debugPrint('[VehiculeService] Image redimensionnée: ${compressedBytes.length ~/ 1024} KB');
          }
        } catch (e) {
          debugPrint('[VehiculeService] Erreur compression simple: $e, utilisation fichier original');
        }
      }

      // Téléchargement direct avec bytes pour éviter les erreurs de canal
      debugPrint('[VehiculeService] 📤 DÉBUT téléchargement vers Firebase Storage');
      debugPrint('[VehiculeService] 📁 Fichier à télécharger: ${finalFile.path}');

      // Lire les bytes du fichier
      final bytes = await finalFile.readAsBytes();
      debugPrint('[VehiculeService] 📊 Bytes lus: ${bytes.length}');

      // Utiliser putData au lieu de putFile pour éviter les erreurs de canal
      final uploadTask = ref.putData(bytes);

      // Suivre la progression
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (snapshot.totalBytes > 0) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          if (onProgress != null) onProgress(progress);
          debugPrint('[VehiculeService] 📊 Progression: ${(progress * 100).toStringAsFixed(1)}% (${snapshot.bytesTransferred}/${snapshot.totalBytes} bytes)');
        } else {
          debugPrint('[VehiculeService] ⚠️ Taille totale inconnue');
        }

        // Vérifier l'annulation
        if (_isCancelled) {
          debugPrint('[VehiculeService] ❌ Annulation du téléchargement demandée');
          uploadTask.cancel();
        }
      });

      // Attendre la fin avec timeout
      await uploadTask.timeout(
        const Duration(minutes: 2), // Timeout de 2 minutes
        onTimeout: () {
          debugPrint('[VehiculeService] Timeout du téléchargement atteint');
          uploadTask.cancel();
          throw TimeoutException('Le téléchargement a pris trop de temps. Vérifiez votre connexion internet.');
        }
      );

      // Obtenir l'URL de téléchargement
      final downloadUrl = await ref.getDownloadURL();
      debugPrint('[VehiculeService] ✅ Téléchargement réussi: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      debugPrint('[VehiculeService] ❌ Erreur téléchargement: $e');

      // Si c'est une erreur de canal, essayer une méthode alternative
      if (e.toString().contains('channel-error') || e.toString().contains('Unable to establish connection')) {
        debugPrint('[VehiculeService] 🔄 Erreur de canal détectée, tentative avec méthode alternative...');
        return await _uploadImageAlternative(imageFile, storagePath, onProgress: onProgress);
      }

      if (e.toString().contains('permission') || e.toString().contains('denied')) {
        throw Exception('Erreur d\'autorisation Firebase Storage. Vérifiez les règles de sécurité.');
      }

      if (e is TimeoutException) {
        throw TimeoutException('Le téléchargement a pris trop de temps. Vérifiez votre connexion internet.');
      }

      rethrow;
    }
  }

  // Méthode alternative de téléchargement pour contourner les erreurs de canal
  Future<String?> _uploadImageAlternative(
    File imageFile,
    String storagePath, {
    Function(double)? onProgress,
  }) async {
    try {
      debugPrint('[VehiculeService] 🔄 MÉTHODE ALTERNATIVE de téléchargement');

      // Attendre un peu pour laisser le canal se réinitialiser
      await Future.delayed(const Duration(seconds: 2));

      // Réinitialiser complètement Firebase Storage
      final storage = FirebaseStorage.instance;

      // Créer un nom de fichier unique
      final fileName = 'alt_${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final fullPath = '$storagePath/$fileName';

      debugPrint('[VehiculeService] 📁 Chemin alternatif: $fullPath');

      // Lire le fichier en bytes
      final bytes = await imageFile.readAsBytes();
      debugPrint('[VehiculeService] 📊 Taille bytes: ${bytes.length}');

      // Créer la référence
      final ref = storage.ref().child(fullPath);

      // Téléchargement avec putData et métadonnées
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': 'constat_tunisie_app',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('[VehiculeService] 📤 Début téléchargement alternatif...');

      // Utiliser putData avec métadonnées
      final uploadTask = ref.putData(bytes, metadata);

      // Suivre la progression
      uploadTask.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          if (onProgress != null) onProgress(progress);
          debugPrint('[VehiculeService] 📊 Progression alternative: ${(progress * 100).toStringAsFixed(1)}%');
        }
      });

      // Attendre la fin
      await uploadTask.timeout(
        const Duration(minutes: 3),
        onTimeout: () {
          uploadTask.cancel();
          throw TimeoutException('Timeout méthode alternative');
        }
      );

      // Obtenir l'URL
      final downloadUrl = await ref.getDownloadURL();
      debugPrint('[VehiculeService] ✅ Téléchargement alternatif réussi: $downloadUrl');

      return downloadUrl;

    } catch (e) {
      debugPrint('[VehiculeService] ❌ Erreur méthode alternative: $e');
      throw Exception('Impossible de télécharger l\'image. Vérifiez votre connexion internet et réessayez.');
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
        
        // Télécharger la photo recto directement
        if (photoRecto != null) {
          debugPrint('[VehiculeService] Téléchargement direct de la photo recto');
          try {
            if (onProgress != null) onProgress(0.1); // 10% pour le début

            photoRectoUrl = await _uploadImageDirect(
              photoRecto,
              'vehicules/$vehiculeId/recto',
              onProgress: (progress) {
                if (onProgress != null) onProgress(0.1 + progress * 0.4); // 10-50% pour la photo recto
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
        
        // Télécharger la photo verso directement
        if (photoVerso != null && !_isCancelled) {
          debugPrint('[VehiculeService] Téléchargement direct de la photo verso');
          try {
            photoVersoUrl = await _uploadImageDirect(
              photoVerso,
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
      }).timeout(const Duration(minutes: 3)); // Timeout augmenté à 3 minutes
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
      
      // Timeout global augmenté (3 minutes)
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
        
        // Télécharger la nouvelle photo recto directement
        if (photoRecto != null) {
          debugPrint('[VehiculeService] Téléchargement direct de la nouvelle photo recto');
          try {
            if (onProgress != null) onProgress(0.1); // 10% pour le début

            photoRectoUrl = await _uploadImageDirect(
              photoRecto,
              'vehicules/${vehicule.id}/recto',
              onProgress: (progress) {
                if (onProgress != null) onProgress(0.1 + progress * 0.4); // 10-50% pour la photo recto
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
        
        // Télécharger la nouvelle photo verso directement
        if (photoVerso != null && !_isCancelled) {
          debugPrint('[VehiculeService] Téléchargement direct de la nouvelle photo verso');
          try {
            photoVersoUrl = await _uploadImageDirect(
              photoVerso,
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
      }).timeout(const Duration(minutes: 3)); // Timeout augmenté à 3 minutes
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