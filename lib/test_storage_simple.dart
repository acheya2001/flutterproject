import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class SimpleStorageTest {
  static Future<void> testBasicUpload() async {
    try {
      debugPrint('[SimpleStorageTest] 🚀 Test de téléchargement basique...');
      
      // Vérifier l'authentification
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('[SimpleStorageTest] ❌ Utilisateur non authentifié');
        return;
      }
      
      debugPrint('[SimpleStorageTest] ✅ Utilisateur authentifié: ${user.uid}');
      
      // Créer une image de test très simple (1x1 pixel)
      final testImageData = Uint8List.fromList([
        // En-tête JPEG minimal
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46,
        0x00, 0x01, 0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00,
        // Fin JPEG
        0xFF, 0xD9
      ]);
      
      debugPrint('[SimpleStorageTest] 📁 Taille de l\'image test: ${testImageData.length} bytes');
      
      // Test avec le chemin exact utilisé par l'application
      final storage = FirebaseStorage.instance;
      final testVehiculeId = 'test_${DateTime.now().millisecondsSinceEpoch}';
      final testFileName = 'test_image.jpg';
      final testPath = 'vehicules/$testVehiculeId/recto/$testFileName';
      
      debugPrint('[SimpleStorageTest] 📤 Test d\'upload sur: $testPath');
      
      final ref = storage.ref().child(testPath);
      
      try {
        // Téléchargement simple
        final uploadTask = ref.putData(testImageData);
        
        // Suivre la progression
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          debugPrint('[SimpleStorageTest] 📊 Progression: ${(progress * 100).toStringAsFixed(1)}%');
        });
        
        // Attendre la fin
        await uploadTask;
        
        debugPrint('[SimpleStorageTest] ✅ Upload terminé avec succès');
        
        // Obtenir l'URL
        final downloadUrl = await ref.getDownloadURL();
        debugPrint('[SimpleStorageTest] 🔗 URL obtenue: $downloadUrl');
        
        // Test de lecture
        final downloadedData = await ref.getData();
        if (downloadedData != null) {
          debugPrint('[SimpleStorageTest] ✅ Lecture réussie: ${downloadedData.length} bytes');
        } else {
          debugPrint('[SimpleStorageTest] ⚠️ Données téléchargées nulles');
        }
        
        // Nettoyer
        await ref.delete();
        debugPrint('[SimpleStorageTest] 🗑️ Fichier supprimé');
        
        debugPrint('[SimpleStorageTest] 🎉 Test réussi !');
        
      } catch (e) {
        debugPrint('[SimpleStorageTest] ❌ Erreur lors du test: $e');
        
        if (e.toString().contains('permission') || e.toString().contains('denied')) {
          debugPrint('[SimpleStorageTest] 🔒 Problème de permissions détecté');
          debugPrint('[SimpleStorageTest] 📋 Vérifiez vos règles Firebase Storage');
          debugPrint('[SimpleStorageTest] 👤 UID utilisateur: ${user.uid}');
          debugPrint('[SimpleStorageTest] 📂 Chemin testé: $testPath');
        } else if (e.toString().contains('network') || e.toString().contains('connection')) {
          debugPrint('[SimpleStorageTest] 🌐 Problème de connexion réseau');
        } else {
          debugPrint('[SimpleStorageTest] ⚠️ Erreur inconnue: ${e.runtimeType}');
        }
      }
      
    } catch (e) {
      debugPrint('[SimpleStorageTest] ❌ Erreur générale: $e');
    }
  }
  
  static Future<void> testAuthStatus() async {
    try {
      debugPrint('[SimpleStorageTest] 🔐 Vérification du statut d\'authentification...');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('[SimpleStorageTest] ❌ Aucun utilisateur connecté');
        return;
      }
      
      debugPrint('[SimpleStorageTest] ✅ Utilisateur connecté:');
      debugPrint('[SimpleStorageTest]   - UID: ${user.uid}');
      debugPrint('[SimpleStorageTest]   - Email: ${user.email ?? 'Non défini'}');
      debugPrint('[SimpleStorageTest]   - Vérifié: ${user.emailVerified}');
      debugPrint('[SimpleStorageTest]   - Anonyme: ${user.isAnonymous}');
      
      // Vérifier le token
      try {
        final token = await user.getIdToken();
        debugPrint('[SimpleStorageTest] ✅ Token obtenu (longueur: ${token?.length ?? 0})');
      } catch (e) {
        debugPrint('[SimpleStorageTest] ❌ Erreur lors de l\'obtention du token: $e');
      }
      
    } catch (e) {
      debugPrint('[SimpleStorageTest] ❌ Erreur lors de la vérification auth: $e');
    }
  }
  
  static Future<void> runAllTests() async {
    debugPrint('[SimpleStorageTest] 🚀 Début des tests Firebase Storage...');
    debugPrint('[SimpleStorageTest] =====================================');
    
    await testAuthStatus();
    debugPrint('[SimpleStorageTest] -------------------------------------');
    await testBasicUpload();
    
    debugPrint('[SimpleStorageTest] =====================================');
    debugPrint('[SimpleStorageTest] ✅ Tests terminés');
  }
}
