import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// 🔐 Service d'authentification spécialisé pour les admins compagnie
class AdminCompagnieAuthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔐 Connexion d'admin compagnie avec gestion des comptes différés
  static Future<Map<String, dynamic>> loginAdminCompagnie({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_AUTH] 🔐 Tentative connexion: $email');

      // 1. Vérifier si l'utilisateur existe dans Firestore
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .where('role', isEqualTo: 'admin_compagnie')
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        return {
          'success': false,
          'error': 'Aucun admin compagnie trouvé avec cet email',
          'code': 'user-not-found',
        };
      }

      final userDoc = userQuery.docs.first;
      final userData = userDoc.data();
      final userId = userDoc.id;

      // Vérifier si l'admin est actif
      if (userData['isActive'] != true || userData['status'] != 'actif') {
        return {
          'success': false,
          'error': 'Compte désactivé. Contactez l\'administrateur.',
          'code': 'account-disabled',
        };
      }

      // 2. Vérifier si le compte Firebase Auth existe
      final firebaseAuthCreated = userData['firebaseAuthCreated'] ?? false;
      
      if (!firebaseAuthCreated) {
        // 🔧 Créer le compte Firebase Auth maintenant
        debugPrint('[ADMIN_COMPAGNIE_AUTH] 🔧 Création compte Firebase Auth différé...');
        
        try {
          final userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          // Mettre à jour le document avec l'UID Firebase Auth
          await _firestore.collection('users').doc(userId).update({
            'uid': userCredential.user!.uid,
            'firebaseAuthCreated': true,
            'firebaseAuthCreatedAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
          });

          debugPrint('[ADMIN_COMPAGNIE_AUTH] ✅ Compte Firebase Auth créé: ${userCredential.user!.uid}');

          return {
            'success': true,
            'user': userCredential.user,
            'userData': userData,
            'userId': userId,
            'message': 'Connexion réussie - Compte Firebase Auth créé',
            'firstLogin': true,
          };

        } catch (authError) {
          debugPrint('[ADMIN_COMPAGNIE_AUTH] ❌ Erreur création Firebase Auth: $authError');
          
          // Si l'utilisateur existe déjà, essayer de se connecter
          if (authError.toString().contains('email-already-in-use')) {
            debugPrint('[ADMIN_COMPAGNIE_AUTH] 🔄 Email déjà utilisé, tentative connexion...');
            
            try {
              final userCredential = await _auth.signInWithEmailAndPassword(
                email: email,
                password: password,
              );

              // Mettre à jour le document
              await _firestore.collection('users').doc(userId).update({
                'uid': userCredential.user!.uid,
                'firebaseAuthCreated': true,
                'firebaseAuthCreatedAt': FieldValue.serverTimestamp(),
                'lastLoginAt': FieldValue.serverTimestamp(),
              });

              return {
                'success': true,
                'user': userCredential.user,
                'userData': userData,
                'userId': userId,
                'message': 'Connexion réussie',
                'firstLogin': false,
              };

            } catch (signInError) {
              return {
                'success': false,
                'error': 'Mot de passe incorrect',
                'code': 'wrong-password',
              };
            }
          }

          return {
            'success': false,
            'error': 'Erreur lors de la création du compte: $authError',
            'code': 'auth-creation-failed',
          };
        }
      } else {
        // 3. Connexion normale avec Firebase Auth existant
        try {
          final userCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          // Mettre à jour la dernière connexion
          await _firestore.collection('users').doc(userId).update({
            'lastLoginAt': FieldValue.serverTimestamp(),
          });

          debugPrint('[ADMIN_COMPAGNIE_AUTH] ✅ Connexion normale réussie');

          return {
            'success': true,
            'user': userCredential.user,
            'userData': userData,
            'userId': userId,
            'message': 'Connexion réussie',
            'firstLogin': false,
          };

        } catch (signInError) {
          debugPrint('[ADMIN_COMPAGNIE_AUTH] ❌ Erreur connexion: $signInError');
          
          return {
            'success': false,
            'error': 'Email ou mot de passe incorrect',
            'code': 'invalid-credentials',
          };
        }
      }

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_AUTH] ❌ Erreur générale: $e');
      return {
        'success': false,
        'error': 'Erreur de connexion: $e',
        'code': 'general-error',
      };
    }
  }

  /// 📊 Obtenir les informations de l'admin compagnie connecté
  static Future<Map<String, dynamic>?> getCurrentAdminCompagnieInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data()!;
      if (userData['role'] != 'admin_compagnie') return null;

      return {
        'uid': user.uid,
        'email': user.email,
        'userData': userData,
        'compagnieId': userData['compagnieId'],
        'compagnieNom': userData['compagnieNom'],
      };

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_AUTH] ❌ Erreur info admin: $e');
      return null;
    }
  }

  /// 🚪 Déconnexion
  static Future<void> logout() async {
    try {
      await _auth.signOut();
      debugPrint('[ADMIN_COMPAGNIE_AUTH] ✅ Déconnexion réussie');
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_AUTH] ❌ Erreur déconnexion: $e');
    }
  }

  /// 🔍 Vérifier si un admin compagnie est connecté
  static bool isAdminCompagnieLoggedIn() {
    return _auth.currentUser != null;
  }

  /// 📧 Réinitialiser le mot de passe
  static Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Email de réinitialisation envoyé',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur lors de l\'envoi: $e',
      };
    }
  }
}
