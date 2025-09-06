import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ConducteurAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Inscription d'un nouveau conducteur
  static Future<Map<String, dynamic>> registerConducteur({
    required String nom,
    required String prenom,
    required String cin,
    required String telephone,
    required String email,
    required String password,
    required String adresse,
  }) async {
    try {
      debugPrint('[ConducteurAuthService] Début inscription conducteur: $email');

      // Vérifier d'abord si l'email existe déjà
      try {
        final methods = await _auth.fetchSignInMethodsForEmail(email);
        if (methods.isNotEmpty) {
          return {
            'success': false,
            'error': 'Cet email est déjà utilisé',
          };
        }
      } catch (e) {
        debugPrint('[ConducteurAuthService] Erreur vérification email: $e');
      }

      // Créer l'utilisateur dans Firebase Auth avec gestion d'erreur améliorée
      UserCredential? userCredential;
      User? user;

      try {
        // Utiliser une approche plus robuste
        userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

        user = userCredential.user;
        debugPrint('[ConducteurAuthService] Utilisateur créé: ${user?.uid}');

      } catch (authError) {
        debugPrint('[ConducteurAuthService] Erreur création Auth: $authError');

        // Gestion spécifique des erreurs Firebase Auth
        if (authError.toString().contains('PigeonUserDetails')) {
          // Erreur de compatibilité - essayer une approche alternative
          debugPrint('[ConducteurAuthService] Tentative de récupération après erreur Pigeon');

          // Attendre un peu et vérifier si l'utilisateur a été créé malgré l'erreur
          await Future.delayed(const Duration(seconds: 2));

          user = FirebaseAuth.instance.currentUser;
          if (user != null && user.email == email) {
            debugPrint('[ConducteurAuthService] Utilisateur récupéré après erreur: ${user.uid}');
          } else {
            throw Exception('Erreur de compatibilité Firebase. Veuillez réessayer.');
          }
        } else {
          throw authError;
        }
      }

      if (user == null) {
        throw Exception('Erreur lors de la création du compte - utilisateur null');
      }

      // Créer le document conducteur dans Firestore
      final conducteurData = {
        'userId': user.uid,
        'nom': nom,
        'prenom': prenom,
        'cin': cin,
        'telephone': telephone,
        'email': email,
        'adresse': adresse,
        'status': 'pending', // En attente de validation par l'agent
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'vehiculeIds': [],
        'contratIds': [],
      };

      try {
        await _firestore.collection('conducteurs').doc(user.uid).set(conducteurData);
        debugPrint('[ConducteurAuthService] Document Firestore créé avec succès');

        // IMPORTANT: Sauvegarder aussi dans le format du ConducteurWorkaroundService
        // pour assurer la compatibilité avec le système de connexion existant
        await _saveWorkaroundData(user.uid, {
          'nom': nom,
          'prenom': prenom,
          'cin': cin,
          'telephone': telephone,
          'email': email,
          'adresse': adresse,
          'password': password, // Nécessaire pour la connexion offline
        });

      } catch (firestoreError) {
        debugPrint('[ConducteurAuthService] Erreur Firestore: $firestoreError');
        // Supprimer l'utilisateur Auth si Firestore échoue
        await user.delete();
        throw Exception('Erreur lors de la sauvegarde des données: $firestoreError');
      }

      debugPrint('[ConducteurAuthService] Inscription réussie pour: $email');

      return {
        'success': true,
        'userId': user.uid,
        'message': 'Inscription réussie! Votre compte est en attente de validation.',
      };

    } on FirebaseAuthException catch (e) {
      debugPrint('[ConducteurAuthService] Erreur Firebase: ${e.code} - ${e.message}');
      
      String errorMessage = 'Erreur lors de l\'inscription';
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Cet email est déjà utilisé';
          break;
        case 'invalid-email':
          errorMessage = 'Format d\'email invalide';
          break;
        case 'weak-password':
          errorMessage = 'Mot de passe trop faible (min 6 caractères)';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Opération non autorisée';
          break;
        default:
          errorMessage = 'Erreur inconnue: ${e.message}';
      }

      return {
        'success': false,
        'error': errorMessage,
      };

    } catch (e) {
      debugPrint('[ConducteurAuthService] Erreur générale: $e');
      return {
        'success': false,
        'error': 'Erreur lors de l\'inscription: $e',
      };
    }
  }

  /// Méthode alternative d'inscription (en cas d'erreur Pigeon)
  static Future<Map<String, dynamic>> registerConducteurAlternative({
    required String nom,
    required String prenom,
    required String cin,
    required String telephone,
    required String email,
    required String password,
    required String adresse,
  }) async {
    try {
      debugPrint('[ConducteurAuthService] Inscription alternative pour: $email');

      // Créer directement le document dans Firestore avec un ID temporaire
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();

      final conducteurData = {
        'tempId': tempId,
        'nom': nom,
        'prenom': prenom,
        'cin': cin,
        'telephone': telephone,
        'email': email,
        'adresse': adresse,
        'password': password, // Temporaire - sera supprimé après création Auth
        'status': 'pending_auth', // En attente de création Auth
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'vehiculeIds': [],
        'contratIds': [],
      };

      // Sauvegarder temporairement dans Firestore
      await _firestore.collection('conducteurs_temp').doc(tempId).set(conducteurData);

      debugPrint('[ConducteurAuthService] Données temporaires sauvegardées');

      return {
        'success': true,
        'tempId': tempId,
        'message': 'Demande d\'inscription enregistrée. Un administrateur va créer votre compte.',
      };

    } catch (e) {
      debugPrint('[ConducteurAuthService] Erreur inscription alternative: $e');
      return {
        'success': false,
        'error': 'Erreur lors de l\'inscription: $e',
      };
    }
  }

  /// Connexion d'un conducteur
  static Future<Map<String, dynamic>> loginConducteur({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[ConducteurAuthService] Début connexion: $email');

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Erreur lors de la connexion');
      }

      // Vérifier si le conducteur existe dans Firestore
      final conducteurDoc = await _firestore.collection('conducteurs').doc(user.uid).get();
      
      if (!conducteurDoc.exists) {
        await _auth.signOut();
        return {
          'success': false,
          'error': 'Compte conducteur introuvable',
        };
      }

      final conducteurData = conducteurDoc.data();
      final status = conducteurData?['status'] ?? 'pending';

      if (status == 'pending') {
        return {
          'success': false,
          'error': 'Votre compte est en attente de validation par un agent',
        };
      }

      debugPrint('[ConducteurAuthService] Connexion réussie pour: $email');

      return {
        'success': true,
        'userId': user.uid,
        'conducteurData': conducteurData,
      };

    } on FirebaseAuthException catch (e) {
      debugPrint('[ConducteurAuthService] Erreur Firebase: ${e.code} - ${e.message}');
      
      String errorMessage = 'Erreur lors de la connexion';
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Aucun compte trouvé avec cet email';
          break;
        case 'wrong-password':
          errorMessage = 'Mot de passe incorrect';
          break;
        case 'invalid-email':
          errorMessage = 'Format d\'email invalide';
          break;
        case 'user-disabled':
          errorMessage = 'Ce compte a été désactivé';
          break;
        default:
          errorMessage = 'Erreur de connexion: ${e.message}';
      }

      return {
        'success': false,
        'error': errorMessage,
      };

    } catch (e) {
      debugPrint('[ConducteurAuthService] Erreur générale: $e');
      return {
        'success': false,
        'error': 'Erreur lors de la connexion: $e',
      };
    }
  }

  /// Déconnexion
  static Future<void> logout() async {
    await _auth.signOut();
    debugPrint('[ConducteurAuthService] Utilisateur déconnecté');
  }

  /// Récupérer les informations du conducteur
  static Future<Map<String, dynamic>?> getConducteurData(String userId) async {
    try {
      final doc = await _firestore.collection('conducteurs').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('[ConducteurAuthService] Erreur récupération données: $e');
      return null;
    }
  }

  /// Sauvegarder les données dans le format du ConducteurWorkaroundService
  /// pour assurer la compatibilité avec le système de connexion existant
  static Future<void> _saveWorkaroundData(String uid, Map<String, dynamic> userData) async {
    try {
      debugPrint('[ConducteurAuthService] Sauvegarde données compatibilité workaround...');

      final prefs = await SharedPreferences.getInstance();

      // Format attendu par ConducteurWorkaroundService
      final workaroundData = {
        'uid': uid,
        'email': userData['email'],
        'password': userData['password'], // Nécessaire pour connexion offline
        'nom': userData['nom'],
        'prenom': userData['prenom'],
        'cin': userData['cin'],
        'telephone': userData['telephone'],
        'adresse': userData['adresse'],
        'createdAt': DateTime.now().toIso8601String(),
        'role': 'conducteur',
      };

      await prefs.setString('conducteur_$uid', json.encode(workaroundData));
      debugPrint('[ConducteurAuthService] Données workaround sauvegardées pour: $uid');

    } catch (e) {
      debugPrint('[ConducteurAuthService] Erreur sauvegarde workaround: $e');
      // Ne pas faire échouer l'inscription pour cette erreur
    }
  }
}
