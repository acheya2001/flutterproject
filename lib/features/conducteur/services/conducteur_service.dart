import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;

import '../models/conducteur_model.dart';

class ConducteurService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Récupérer tous les conducteurs
  Future<List<ConducteurModel>> getAllConducteurs() async {
    try {
      debugPrint('[ConducteurService] Récupération de tous les conducteurs');
      
      final snapshot = await _firestore
          .collection('conducteurs')
          .orderBy('nom')
          .get();
      
      final conducteurs = snapshot.docs
          .map((doc) => ConducteurModel.fromFirestore(doc))
          .toList();
          
      debugPrint('[ConducteurService] ${conducteurs.length} conducteurs récupérés');
      return conducteurs;
    } catch (e) {
      debugPrint('[ConducteurService] Erreur lors de la récupération des conducteurs: $e');
      rethrow;
    }
  }

  // Récupérer un conducteur par son ID
  Future<ConducteurModel?> getConducteurById(String conducteurId) async {
    try {
      debugPrint('[ConducteurService] Récupération du conducteur: $conducteurId');
      
      final doc = await _firestore
          .collection('conducteurs')
          .doc(conducteurId)
          .get();
      
      if (!doc.exists) {
        debugPrint('[ConducteurService] Conducteur non trouvé');
        return null;
      }
      
      final conducteur = ConducteurModel.fromFirestore(doc);
      debugPrint('[ConducteurService] Conducteur récupéré: ${conducteur.nom} ${conducteur.prenom}');
      return conducteur;
    } catch (e) {
      debugPrint('[ConducteurService] Erreur lors de la récupération du conducteur: $e');
      rethrow;
    }
  }

  // Compresser une image avant de la télécharger
  Future<File> _compressImage(File imageFile) async {
    debugPrint('[ConducteurService] Compression de l\'image: ${imageFile.path}');
    
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image == null) {
      debugPrint('[ConducteurService] Impossible de décoder l\'image');
      return imageFile;
    }
    
    // Redimensionner l'image si elle est trop grande
    img.Image resizedImage = image;
    if (image.width > 1200 || image.height > 1200) {
      resizedImage = img.copyResize(
        image,
        width: image.width > 1200 ? 1200 : null,
        height: image.height > 1200 ? 1200 : null,
      );
    }
    
    // Compresser l'image
    final compressedBytes = img.encodeJpg(resizedImage, quality: 80);
    
    // Créer un fichier temporaire pour l'image compressée
    final tempDir = await Directory.systemTemp.createTemp();
    final tempFile = File('${tempDir.path}/compressed_${path.basename(imageFile.path)}');
    await tempFile.writeAsBytes(compressedBytes);
    
    debugPrint('[ConducteurService] Image compressée: ${tempFile.path}');
    debugPrint('[ConducteurService] Taille originale: ${bytes.length} octets, taille compressée: ${compressedBytes.length} octets');
    
    return tempFile;
  }

  // Ajouter un nouveau conducteur
  Future<String?> addConducteur(
    ConducteurModel conducteur, {
    File? photoPermis,
    File? photoCIN,
  }) async {
    try {
      debugPrint('[ConducteurService] Ajout d\'un nouveau conducteur: ${conducteur.nom} ${conducteur.prenom}');
      
      // Créer un nouveau document avec un ID généré
      final docRef = _firestore.collection('conducteurs').doc();
      final String conducteurId = docRef.id;
      
      debugPrint('[ConducteurService] ID généré pour le conducteur: $conducteurId');
      
      // Télécharger les photos si elles sont fournies
      String? urlPhotoPermis;
      String? urlPhotoCIN;
      
      // Compresser et télécharger la photo du permis
      if (photoPermis != null) {
        debugPrint('[ConducteurService] Compression et téléchargement de la photo du permis');
        final compressedPermis = await _compressImage(photoPermis);
        final permisRef = _storage.ref().child('conducteurs/$conducteurId/permis.jpg');
        await permisRef.putFile(compressedPermis);
        urlPhotoPermis = await permisRef.getDownloadURL();
        debugPrint('[ConducteurService] Photo du permis téléchargée: $urlPhotoPermis');
      }
      
      // Compresser et télécharger la photo de la CIN
      if (photoCIN != null) {
        debugPrint('[ConducteurService] Compression et téléchargement de la photo de la CIN');
        final compressedCIN = await _compressImage(photoCIN);
        final cinRef = _storage.ref().child('conducteurs/$conducteurId/cin.jpg');
        await cinRef.putFile(compressedCIN);
        urlPhotoCIN = await cinRef.getDownloadURL();
        debugPrint('[ConducteurService] Photo de la CIN téléchargée: $urlPhotoCIN');
      }
      
      // Créer un nouveau conducteur avec l'ID généré et les URLs des photos
      final newConducteur = conducteur.copyWith(
        id: conducteurId,
        urlPhotoPermis: urlPhotoPermis,
        urlPhotoCIN: urlPhotoCIN,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Enregistrer le conducteur dans Firestore
      await docRef.set(newConducteur.toMap());
      debugPrint('[ConducteurService] Conducteur enregistré dans Firestore');
      
      return conducteurId;
    } catch (e) {
      debugPrint('[ConducteurService] Erreur lors de l\'ajout du conducteur: $e');
      rethrow;
    }
  }

  // Mettre à jour un conducteur existant
  Future<bool> updateConducteur(
    ConducteurModel conducteur, {
    File? photoPermis,
    File? photoCIN,
  }) async {
    try {
      if (conducteur.id == null) {
        throw Exception('ID du conducteur non défini');
      }
      
      debugPrint('[ConducteurService] Mise à jour du conducteur: ${conducteur.id}');
      
      // Télécharger les nouvelles photos si elles sont fournies
      String? urlPhotoPermis = conducteur.urlPhotoPermis;
      String? urlPhotoCIN = conducteur.urlPhotoCIN;
      
      // Compresser et télécharger la photo du permis
      if (photoPermis != null) {
        debugPrint('[ConducteurService] Compression et téléchargement de la nouvelle photo du permis');
        final compressedPermis = await _compressImage(photoPermis);
        final permisRef = _storage.ref().child('conducteurs/${conducteur.id}/permis.jpg');
        await permisRef.putFile(compressedPermis);
        urlPhotoPermis = await permisRef.getDownloadURL();
        debugPrint('[ConducteurService] Nouvelle photo du permis téléchargée: $urlPhotoPermis');
      }
      
      // Compresser et télécharger la photo de la CIN
      if (photoCIN != null) {
        debugPrint('[ConducteurService] Compression et téléchargement de la nouvelle photo de la CIN');
        final compressedCIN = await _compressImage(photoCIN);
        final cinRef = _storage.ref().child('conducteurs/${conducteur.id}/cin.jpg');
        await cinRef.putFile(compressedCIN);
        urlPhotoCIN = await cinRef.getDownloadURL();
        debugPrint('[ConducteurService] Nouvelle photo de la CIN téléchargée: $urlPhotoCIN');
      }
      
      // Mettre à jour le conducteur avec les nouvelles URLs des photos
      final updatedConducteur = conducteur.copyWith(
        urlPhotoPermis: urlPhotoPermis,
        urlPhotoCIN: urlPhotoCIN,
        updatedAt: DateTime.now(),
      );
      
      // Enregistrer les modifications dans Firestore
      await _firestore
          .collection('conducteurs')
          .doc(conducteur.id)
          .update(updatedConducteur.toMap());
      
      debugPrint('[ConducteurService] Conducteur mis à jour avec succès');
      
      return true;
    } catch (e) {
      debugPrint('[ConducteurService] Erreur lors de la mise à jour du conducteur: $e');
      rethrow;
    }
  }

  // Supprimer un conducteur
  Future<void> deleteConducteur(String conducteurId) async {
    try {
      debugPrint('[ConducteurService] Suppression du conducteur: $conducteurId');
      
      // Supprimer les photos du conducteur
      await _deleteConducteurPhotos(conducteurId);
      
      // Supprimer le document du conducteur
      await _firestore
          .collection('conducteurs')
          .doc(conducteurId)
          .delete();
      
      debugPrint('[ConducteurService] Conducteur supprimé avec succès');
    } catch (e) {
      debugPrint('[ConducteurService] Erreur lors de la suppression du conducteur: $e');
      rethrow;
    }
  }

  // Supprimer les photos d'un conducteur
  Future<void> _deleteConducteurPhotos(String conducteurId) async {
    try {
      debugPrint('[ConducteurService] Suppression des photos du conducteur: $conducteurId');
      
      final ref = _storage.ref().child('conducteurs/$conducteurId');
      
      try {
        final items = await ref.listAll();
        
        for (final item in items.items) {
          await item.delete();
          debugPrint('[ConducteurService] Photo supprimée: ${item.fullPath}');
        }
        
        // Supprimer les sous-dossiers
        for (final prefix in items.prefixes) {
          final subItems = await prefix.listAll();
          for (final item in subItems.items) {
            await item.delete();
            debugPrint('[ConducteurService] Photo supprimée: ${item.fullPath}');
          }
        }
        
      } catch (e) {
        // Ignorer les erreurs si le dossier n'existe pas
        debugPrint('[ConducteurService] Avertissement lors de la suppression des photos: $e');
      }
    } catch (e) {
      debugPrint('[ConducteurService] Erreur lors de la suppression des photos: $e');
      rethrow;
    }
  }
}