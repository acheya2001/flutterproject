import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:typed_data';

class FirebaseRulesTest {
  static Future<void> testStorageRules() async {
    try {
      debugPrint('[FirebaseRulesTest] Test des règles Firebase Storage...');
      
      // Vérifier l'authentification
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('[FirebaseRulesTest] ❌ Utilisateur non authentifié');
        return;
      }
      
      debugPrint('[FirebaseRulesTest] ✅ Utilisateur authentifié: ${user.uid}');
      
      // Test d'écriture dans Storage
      final storage = FirebaseStorage.instance;
      final testVehiculeId = 'test_${DateTime.now().millisecondsSinceEpoch}';
      final testFileName = 'test_image.jpg';
      
      // Créer une image de test (1x1 pixel rouge)
      final testImageData = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
        0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
        0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
        0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
        0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
        0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
        0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
        0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x11, 0x08, 0x00, 0x01,
        0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0x02, 0x11, 0x01, 0x03, 0x11, 0x01,
        0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0xFF, 0xC4,
        0x00, 0x14, 0x10, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xDA, 0x00, 0x0C,
        0x03, 0x01, 0x00, 0x02, 0x11, 0x03, 0x11, 0x00, 0x3F, 0x00, 0x00, 0xFF, 0xD9
      ]);
      
      // Test du chemin utilisé par l'application
      final testPath = 'vehicules/$testVehiculeId/recto/$testFileName';
      final ref = storage.ref().child(testPath);
      
      debugPrint('[FirebaseRulesTest] Test d\'écriture sur le chemin: $testPath');
      
      try {
        await ref.putData(testImageData);
        debugPrint('[FirebaseRulesTest] ✅ Écriture réussie dans Storage');
        
        // Test de lecture
        final downloadUrl = await ref.getDownloadURL();
        debugPrint('[FirebaseRulesTest] ✅ Lecture réussie: $downloadUrl');
        
        // Nettoyer le test
        await ref.delete();
        debugPrint('[FirebaseRulesTest] ✅ Suppression réussie');
        
      } catch (e) {
        debugPrint('[FirebaseRulesTest] ❌ Erreur Storage: $e');
        
        if (e.toString().contains('permission') || e.toString().contains('denied')) {
          debugPrint('[FirebaseRulesTest] 🔍 Problème de permissions détecté');
          debugPrint('[FirebaseRulesTest] Chemin testé: $testPath');
          debugPrint('[FirebaseRulesTest] UID utilisateur: ${user.uid}');
        }
      }
      
    } catch (e) {
      debugPrint('[FirebaseRulesTest] ❌ Erreur générale: $e');
    }
  }
  
  static Future<void> testFirestoreRules() async {
    try {
      debugPrint('[FirebaseRulesTest] Test des règles Firestore...');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('[FirebaseRulesTest] ❌ Utilisateur non authentifié');
        return;
      }
      
      final firestore = FirebaseFirestore.instance;
      final testVehiculeId = 'test_${DateTime.now().millisecondsSinceEpoch}';
      
      // Test d'écriture dans Firestore
      final testData = {
        'immatriculation': 'TEST 123',
        'marque': 'Test',
        'modele': 'Test',
        'proprietaireId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      try {
        await firestore.collection('vehicules').doc(testVehiculeId).set(testData);
        debugPrint('[FirebaseRulesTest] ✅ Écriture Firestore réussie');
        
        // Test de lecture
        final doc = await firestore.collection('vehicules').doc(testVehiculeId).get();
        if (doc.exists) {
          debugPrint('[FirebaseRulesTest] ✅ Lecture Firestore réussie');
        }
        
        // Nettoyer
        await firestore.collection('vehicules').doc(testVehiculeId).delete();
        debugPrint('[FirebaseRulesTest] ✅ Suppression Firestore réussie');
        
      } catch (e) {
        debugPrint('[FirebaseRulesTest] ❌ Erreur Firestore: $e');
      }
      
    } catch (e) {
      debugPrint('[FirebaseRulesTest] ❌ Erreur générale Firestore: $e');
    }
  }
  
  static Future<void> runAllTests() async {
    debugPrint('[FirebaseRulesTest] 🚀 Début des tests Firebase...');
    await testFirestoreRules();
    await testStorageRules();
    debugPrint('[FirebaseRulesTest] ✅ Tests terminés');
  }
}
