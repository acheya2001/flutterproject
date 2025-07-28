import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// 🔧 Service pour gérer et vérifier les règles Firestore
class FirestoreRulesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔍 Vérifier si les règles Firestore permettent les opérations nécessaires
  static Future<Map<String, dynamic>> checkFirestoreRules() async {
    try {
      debugPrint('[FIRESTORE_RULES] 🔍 Vérification des règles Firestore...');

      final results = <String, bool>{};
      final errors = <String>[];

      // Test 1: Lecture des utilisateurs
      try {
        await _firestore.collection('users').limit(1).get();
        results['read_users'] = true;
        debugPrint('[FIRESTORE_RULES] ✅ Lecture users: OK');
      } catch (e) {
        results['read_users'] = false;
        errors.add('Lecture users: $e');
        debugPrint('[FIRESTORE_RULES] ❌ Lecture users: $e');
      }

      // Test 2: Écriture des utilisateurs
      try {
        final testDoc = _firestore.collection('users').doc('test_rules_check');
        await testDoc.set({
          'test': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
        await testDoc.delete(); // Nettoyer
        results['write_users'] = true;
        debugPrint('[FIRESTORE_RULES] ✅ Écriture users: OK');
      } catch (e) {
        results['write_users'] = false;
        errors.add('Écriture users: $e');
        debugPrint('[FIRESTORE_RULES] ❌ Écriture users: $e');
      }

      // Test 3: Lecture des compagnies
      try {
        await _firestore.collection('compagnies').limit(1).get();
        results['read_companies'] = true;
        debugPrint('[FIRESTORE_RULES] ✅ Lecture compagnies: OK');
      } catch (e) {
        results['read_companies'] = false;
        errors.add('Lecture compagnies: $e');
        debugPrint('[FIRESTORE_RULES] ❌ Lecture compagnies: $e');
      }

      // Test 4: Écriture des compagnies
      try {
        final testDoc = _firestore.collection('compagnies').doc('test_rules_check');
        await testDoc.set({
          'test': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
        await testDoc.delete(); // Nettoyer
        results['write_companies'] = true;
        debugPrint('[FIRESTORE_RULES] ✅ Écriture compagnies: OK');
      } catch (e) {
        results['write_companies'] = false;
        errors.add('Écriture compagnies: $e');
        debugPrint('[FIRESTORE_RULES] ❌ Écriture compagnies: $e');
      }

      final allPassed = results.values.every((passed) => passed);

      return {
        'success': allPassed,
        'results': results,
        'errors': errors,
        'message': allPassed 
            ? 'Toutes les règles Firestore sont correctes'
            : 'Certaines règles Firestore doivent être ajustées',
      };

    } catch (e) {
      debugPrint('[FIRESTORE_RULES] ❌ Erreur vérification règles: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de la vérification des règles',
      };
    }
  }

  /// 📋 Obtenir les règles Firestore recommandées
  static String getRecommendedRules() {
    return '''
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 🔑 Super Admin : Accès total
    match /{document=**} {
      allow read, write: if request.auth != null && 
        request.auth.token.email == 'constat.tunisie.app@gmail.com';
    }
    
    // 👤 Utilisateurs : Gestion par Super Admin
    match /users/{userId} {
      allow read, write: if request.auth != null && (
        request.auth.token.email == 'constat.tunisie.app@gmail.com' ||
        request.auth.uid == userId ||
        exists(/databases/\$(database)/documents/users/\$(request.auth.uid)) &&
        get(/databases/\$(database)/documents/users/\$(request.auth.uid)).data.role in ['super_admin', 'admin_compagnie']
      );
    }
    
    // 🏢 Compagnies : Gestion par Super Admin et Admin Compagnie
    match /compagnies/{companyId} {
      allow read, write: if request.auth != null && (
        request.auth.token.email == 'constat.tunisie.app@gmail.com' ||
        (exists(/databases/\$(database)/documents/users/\$(request.auth.uid)) &&
         get(/databases/\$(database)/documents/users/\$(request.auth.uid)).data.role in ['super_admin', 'admin_compagnie'])
      );
    }
    
    // 🏪 Agences : Gestion par admins
    match /agences/{agencyId} {
      allow read, write: if request.auth != null && (
        request.auth.token.email == 'constat.tunisie.app@gmail.com' ||
        (exists(/databases/\$(database)/documents/users/\$(request.auth.uid)) &&
         get(/databases/\$(database)/documents/users/\$(request.auth.uid)).data.role in ['super_admin', 'admin_compagnie', 'admin_agence'])
      );
    }
    
    // 📋 Demandes professionnelles : Lecture publique, écriture pour tous
    match /demandes_professionnels/{demandeId} {
      allow read: if request.auth != null;
      allow write: if true; // Permettre les inscriptions publiques
    }
  }
}''';
  }

  /// 🔧 Obtenir les règles de développement (permissives)
  static String getDevelopmentRules() {
    return '''
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}''';
  }

  /// 📊 Obtenir des informations sur l'utilisateur actuel
  static Future<Map<String, dynamic>> getCurrentUserInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'authenticated': false,
          'message': 'Aucun utilisateur connecté',
        };
      }

      // Essayer de récupérer les données utilisateur
      DocumentSnapshot? userDoc;
      try {
        userDoc = await _firestore.collection('users').doc(user.uid).get();
      } catch (e) {
        debugPrint('[FIRESTORE_RULES] ❌ Impossible de lire le document utilisateur: $e');
      }

      return {
        'authenticated': true,
        'uid': user.uid,
        'email': user.email,
        'emailVerified': user.emailVerified,
        'hasUserDoc': userDoc?.exists ?? false,
        'userRole': userDoc?.exists == true ? userDoc!.data() as Map<String, dynamic>? : null,
      };

    } catch (e) {
      debugPrint('[FIRESTORE_RULES] ❌ Erreur info utilisateur: $e');
      return {
        'error': e.toString(),
      };
    }
  }
}
