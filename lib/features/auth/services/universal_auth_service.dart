import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🌟 Service d'authentification universel - Fonctionne pour tous les types d'utilisateurs
class UniversalAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔐 Connexion universelle avec gestion d'erreurs robuste
  static Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      debugPrint('[UniversalAuth] 🔐 Début connexion: $email');

      User? user;
      bool pigeonWorkaround = false;

      // Étape 1: Tentative de connexion Firebase Auth
      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = userCredential.user;
        debugPrint('[UniversalAuth] ✅ Connexion Firebase Auth directe réussie');
      } catch (authError) {
        debugPrint('[UniversalAuth] ⚠️ Erreur Firebase Auth: $authError');

        // Gestion spéciale PigeonUserDetails
        if (authError.toString().contains('PigeonUserDetails')) {
          debugPrint('[UniversalAuth] 🔧 Erreur PigeonUserDetails détectée, contournement...');
          
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            user = currentUser;
            pigeonWorkaround = true;
            debugPrint('[UniversalAuth] ✅ Contournement PigeonUserDetails réussi: ${user.uid}');
          } else {
            return {
              'success': false,
              'error': 'Erreur PigeonUserDetails - utilisateur non connecté',
            };
          }
        } else {
          return {
            'success': false,
            'error': 'Identifiants incorrects: ${authError.toString()}',
          };
        }
      }

      if (user == null) {
        return {
          'success': false,
          'error': 'Utilisateur non trouvé après connexion',
        };
      }

      // Étape 2: Récupération des données utilisateur avec retry
      Map<String, dynamic>? userData;
      String? userType;

      // Tentative de récupération avec plusieurs collections
      final collections = ['conducteurs', 'agents_assurance', 'experts'];
      
      for (final collection in collections) {
        try {
          debugPrint('[UniversalAuth] 🔍 Recherche dans $collection...');
          
          final doc = await _firestore.collection(collection).doc(user.uid).get();
          
          if (doc.exists && doc.data() != null) {
            userData = doc.data() as Map<String, dynamic>;
            userType = userData['userType'] ?? _getTypeFromCollection(collection);
            debugPrint('[UniversalAuth] ✅ Données trouvées dans $collection: $userType');
            break;
          }
        } catch (firestoreError) {
          debugPrint('[UniversalAuth] ⚠️ Erreur $collection: $firestoreError');
          // Continuer avec la collection suivante
        }
      }

      // Si aucune donnée trouvée, retourner une erreur
      if (userData == null) {
        debugPrint('[UniversalAuth] ❌ Aucune donnée utilisateur trouvée pour: ${user.uid}');
        return {
          'success': false,
          'error': 'Compte non trouvé. Veuillez vous inscrire d\'abord.',
        };
      }

      // Étape 3: Retourner le résultat
      final result = {
        'success': true,
        'uid': user.uid,
        'email': userData['email']?.toString() ?? email,
        'userType': userType,
        'nom': userData['nom']?.toString() ?? 'Utilisateur',
        'prenom': userData['prenom']?.toString() ?? 'Firebase',
        'pigeonWorkaround': pigeonWorkaround,
        'userData': userData,
      };

      debugPrint('[UniversalAuth] 🎉 Connexion universelle réussie: $userType (${user.uid})');
      return result;

    } catch (e) {
      debugPrint('[UniversalAuth] ❌ Erreur générale: $e');
      return {
        'success': false,
        'error': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// 📝 Inscription universelle
  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String userType,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      debugPrint('[UniversalAuth] 📝 Début inscription: $email ($userType)');

      // Création du compte Firebase Auth
      UserCredential? userCredential;
      User? user;
      bool pigeonWorkaround = false;

      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = userCredential.user;
      } catch (authError) {
        debugPrint('[UniversalAuth] ⚠️ Erreur Firebase Auth: $authError');

        // Contournement automatique PigeonUserDetails
        if (authError.toString().contains('PigeonUserDetails')) {
          debugPrint('[UniversalAuth] 🔧 Erreur PigeonUserDetails détectée, contournement...');
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            user = currentUser;
            pigeonWorkaround = true;
            debugPrint('[UniversalAuth] ✅ Contournement PigeonUserDetails réussi: ${user.uid}');
          }
        }

        if (user == null) {
          debugPrint('[UniversalAuth] ❌ Erreur création compte: $authError');
          return {
            'success': false,
            'error': 'Erreur création compte: ${authError.toString()}',
          };
        }
      }

      // Si user n'est pas encore défini, essayer de le récupérer
      if (user == null && userCredential != null) {
        user = userCredential.user;
      }

      if (user == null) {
        return {
          'success': false,
          'error': 'Erreur création utilisateur',
        };
      }

      // Création du profil utilisateur
      final userData = {
        'uid': user.uid,
        'email': email,
        'nom': nom,
        'prenom': prenom,
        'userType': userType,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        ...?additionalData,
      };

      // Sauvegarde dans la collection appropriée
      final collection = _getCollectionForUserType(userType);
      try {
        await _firestore.collection(collection).doc(user.uid).set(userData);
        debugPrint('[UniversalAuth] ✅ Profil créé dans $collection');
      } catch (firestoreError) {
        debugPrint('[UniversalAuth] ❌ Erreur Firestore: $firestoreError');
        // Supprimer le compte Auth si Firestore échoue
        await user.delete();
        return {
          'success': false,
          'error': 'Erreur sauvegarde données',
        };
      }

      return {
        'success': true,
        'uid': user.uid,
        'email': email,
        'nom': nom,
        'prenom': prenom,
        'userType': userType,
        'message': 'Inscription réussie !',
      };

    } catch (e) {
      debugPrint('[UniversalAuth] ❌ Erreur générale inscription: $e');
      return {
        'success': false,
        'error': 'Erreur inscription: ${e.toString()}',
      };
    }
  }

  /// 🚪 Déconnexion universelle
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('[UniversalAuth] 🚪 Déconnexion réussie');
    } catch (e) {
      debugPrint('[UniversalAuth] ❌ Erreur déconnexion: $e');
    }
  }

  /// 👤 Utilisateur actuel
  static User? get currentUser => _auth.currentUser;

  /// 📊 Vérifier si connecté
  static bool get isLoggedIn => _auth.currentUser != null;



  /// 📂 Obtenir le type depuis le nom de collection
  static String _getTypeFromCollection(String collection) {
    switch (collection) {
      case 'agents_assurance':
        return 'assureur';
      case 'experts':
        return 'expert';
      case 'conducteurs':
        return 'conducteur';
      default:
        return 'conducteur';
    }
  }

  /// 📂 Obtenir la collection pour un type d'utilisateur
  static String _getCollectionForUserType(String userType) {
    switch (userType) {
      case 'assureur':
        return 'agents_assurance';
      case 'expert':
        return 'experts';
      default:
        return 'conducteurs';
    }
  }
}
