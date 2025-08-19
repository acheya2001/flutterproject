import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔐 Service d'authentification pour les agents
/// Basé sur le même principe que AdminCompagnieAuthService
class AgentAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔐 Connexion d'agent avec gestion des comptes différés
  static Future<Map<String, dynamic>> loginAgent({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[AGENT_AUTH] 🔐 Tentative connexion: $email');

      // 1. Vérifier si l'utilisateur existe dans Firestore
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .where('role', isEqualTo: 'agent')
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        return {
          'success': false,
          'error': 'Aucun agent trouvé avec cet email',
          'code': 'user-not-found',
        };
      }

      final userDoc = userQuery.docs.first;
      final userData = userDoc.data();
      final userId = userDoc.id;

      // Vérifier si l'agent est actif
      if (userData['isActive'] != true || userData['status'] != 'actif') {
        return {
          'success': false,
          'error': 'Compte désactivé. Contactez votre administrateur.',
          'code': 'account-disabled',
        };
      }

      // 2. Vérifier si le compte Firebase Auth existe
      final firebaseAuthCreated = userData['firebaseAuthCreated'] ?? false;
      
      if (!firebaseAuthCreated) {
        // 🔧 Créer le compte Firebase Auth maintenant (comme pour les admins)
        debugPrint('[AGENT_AUTH] 🔧 Création compte Firebase Auth différé...');
        
        try {
          final userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          // Mettre à jour le document et synchroniser l'UID
          if (userCredential.user!.uid != userId) {
            debugPrint('[AGENT_AUTH] 🔄 Synchronisation UID: $userId → ${userCredential.user!.uid}');

            // Copier les données vers le nouveau document avec l'UID Firebase Auth
            final updatedData = Map<String, dynamic>.from(userData);
            updatedData['uid'] = userCredential.user!.uid;
            updatedData['firebaseAuthCreated'] = true;
            updatedData['firebaseAuthCreatedAt'] = FieldValue.serverTimestamp();
            updatedData['lastLoginAt'] = FieldValue.serverTimestamp();

            await _firestore.collection('users').doc(userCredential.user!.uid).set(updatedData);

            // Supprimer l'ancien document
            await _firestore.collection('users').doc(userId).delete();

            debugPrint('[AGENT_AUTH] ✅ Document agent synchronisé avec UID Firebase Auth');
          } else {
            // Mettre à jour le document existant
            await _firestore.collection('users').doc(userId).update({
              'uid': userCredential.user!.uid,
              'firebaseAuthCreated': true,
              'firebaseAuthCreatedAt': FieldValue.serverTimestamp(),
              'lastLoginAt': FieldValue.serverTimestamp(),
            });
          }

          debugPrint('[AGENT_AUTH] ✅ Compte Firebase Auth créé: ${userCredential.user!.uid}');

          return {
            'success': true,
            'user': userCredential.user,
            'userData': userData,
            'userId': userCredential.user!.uid, // Utiliser l'UID Firebase Auth
            'message': 'Connexion réussie - Compte Firebase Auth créé',
            'firstLogin': true,
          };

        } catch (createError) {
          debugPrint('[AGENT_AUTH] ❌ Erreur création Firebase Auth: $createError');

          // Si l'utilisateur existe déjà, essayer de se connecter (comme pour les admins)
          if (createError.toString().contains('email-already-in-use')) {
            debugPrint('[AGENT_AUTH] 🔄 Email déjà utilisé, tentative connexion...');

            try {
              final userCredential = await _auth.signInWithEmailAndPassword(
                email: email,
                password: password,
              );

              // Mettre à jour le document et synchroniser l'UID
              if (userCredential.user!.uid != userId) {
                debugPrint('[AGENT_AUTH] 🔄 Synchronisation UID: $userId → ${userCredential.user!.uid}');

                // Copier les données vers le nouveau document avec l'UID Firebase Auth
                final updatedData = Map<String, dynamic>.from(userData);
                updatedData['uid'] = userCredential.user!.uid;
                updatedData['firebaseAuthCreated'] = true;
                updatedData['firebaseAuthCreatedAt'] = FieldValue.serverTimestamp();
                updatedData['lastLoginAt'] = FieldValue.serverTimestamp();

                await _firestore.collection('users').doc(userCredential.user!.uid).set(updatedData);

                // Supprimer l'ancien document
                await _firestore.collection('users').doc(userId).delete();

                debugPrint('[AGENT_AUTH] ✅ Document agent synchronisé avec UID Firebase Auth');
              } else {
                // Mettre à jour le document existant
                await _firestore.collection('users').doc(userId).update({
                  'uid': userCredential.user!.uid,
                  'firebaseAuthCreated': true,
                  'firebaseAuthCreatedAt': FieldValue.serverTimestamp(),
                  'lastLoginAt': FieldValue.serverTimestamp(),
                });
              }

              debugPrint('[AGENT_AUTH] ✅ Connexion réussie avec compte existant');

              return {
                'success': true,
                'user': userCredential.user,
                'userData': userData,
                'userId': userCredential.user!.uid, // Utiliser l'UID Firebase Auth
                'message': 'Connexion réussie',
                'firstLogin': false,
              };

            } catch (signInError) {
              debugPrint('[AGENT_AUTH] ❌ Erreur connexion: $signInError');

              // Gestion spéciale pour les erreurs de type casting Firebase
              if (signInError.toString().contains('type cast') ||
                  signInError.toString().contains('PigeonUserDetails')) {
                debugPrint('[AGENT_AUTH] 🔧 Erreur de type casting détectée, connexion probablement réussie');

                // Vérifier si l'utilisateur est connecté malgré l'erreur
                final currentUser = _auth.currentUser;
                if (currentUser != null && currentUser.email == email) {
                  debugPrint('[AGENT_AUTH] ✅ Utilisateur connecté malgré l\'erreur de casting');

                  // Mettre à jour le document et synchroniser l'UID
                  try {
                    // Si l'UID Firebase Auth est différent de l'ID du document, créer un nouveau document
                    if (currentUser.uid != userId) {
                      debugPrint('[AGENT_AUTH] 🔄 Synchronisation UID: $userId → ${currentUser.uid}');

                      // Copier les données vers le nouveau document avec l'UID Firebase Auth
                      final updatedData = Map<String, dynamic>.from(userData);
                      updatedData['uid'] = currentUser.uid;
                      updatedData['firebaseAuthCreated'] = true;
                      updatedData['firebaseAuthCreatedAt'] = FieldValue.serverTimestamp();
                      updatedData['lastLoginAt'] = FieldValue.serverTimestamp();

                      await _firestore.collection('users').doc(currentUser.uid).set(updatedData);

                      // Supprimer l'ancien document
                      await _firestore.collection('users').doc(userId).delete();

                      debugPrint('[AGENT_AUTH] ✅ Document agent synchronisé avec UID Firebase Auth');

                      return {
                        'success': true,
                        'user': currentUser,
                        'userData': updatedData,
                        'userId': currentUser.uid, // Utiliser le nouvel UID
                        'message': 'Connexion réussie',
                        'firstLogin': false,
                      };
                    } else {
                      // Mettre à jour le document existant
                      await _firestore.collection('users').doc(userId).update({
                        'uid': currentUser.uid,
                        'firebaseAuthCreated': true,
                        'firebaseAuthCreatedAt': FieldValue.serverTimestamp(),
                        'lastLoginAt': FieldValue.serverTimestamp(),
                      });

                      return {
                        'success': true,
                        'user': currentUser,
                        'userData': userData,
                        'userId': userId,
                        'message': 'Connexion réussie',
                        'firstLogin': false,
                      };
                    }
                  } catch (updateError) {
                    debugPrint('[AGENT_AUTH] ⚠️ Erreur mise à jour document: $updateError');

                    // Retourner quand même le succès car la connexion Firebase Auth a fonctionné
                    return {
                      'success': true,
                      'user': currentUser,
                      'userData': userData,
                      'userId': currentUser.uid, // Utiliser l'UID Firebase Auth
                      'message': 'Connexion réussie',
                      'firstLogin': false,
                    };
                  }
                }
              }

              // Vérifier si le mot de passe stocké correspond
              final storedPassword = userData['password'];
              if (storedPassword != null && storedPassword == password) {
                return {
                  'success': false,
                  'error': 'Problème technique de connexion. Contactez l\'administrateur.',
                  'code': 'firebase-auth-signin-failed',
                };
              } else {
                return {
                  'success': false,
                  'error': 'Email ou mot de passe incorrect',
                  'code': 'invalid-credentials',
                };
              }
            }
          } else {
            // Autre erreur de création
            final storedPassword = userData['password'];
            if (storedPassword != null && storedPassword == password) {
              return {
                'success': false,
                'error': 'Problème technique lors de la création du compte. Contactez l\'administrateur.',
                'code': 'firebase-auth-creation-failed',
              };
            } else {
              return {
                'success': false,
                'error': 'Email ou mot de passe incorrect',
                'code': 'invalid-credentials',
              };
            }
          }
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

          debugPrint('[AGENT_AUTH] ✅ Connexion normale réussie');

          return {
            'success': true,
            'user': userCredential.user,
            'userData': userData,
            'userId': userId,
            'message': 'Connexion réussie',
            'firstLogin': false,
          };

        } catch (signInError) {
          debugPrint('[AGENT_AUTH] ❌ Erreur connexion: $signInError');

          // Gestion spéciale pour les erreurs de type casting Firebase
          if (signInError.toString().contains('type cast') ||
              signInError.toString().contains('PigeonUserDetails')) {
            debugPrint('[AGENT_AUTH] 🔧 Erreur de type casting détectée, connexion probablement réussie');

            // Vérifier si l'utilisateur est connecté malgré l'erreur
            final currentUser = _auth.currentUser;
            if (currentUser != null && currentUser.email == email) {
              debugPrint('[AGENT_AUTH] ✅ Utilisateur connecté malgré l\'erreur de casting');

              // Mettre à jour le document et synchroniser l'UID
              try {
                // Si l'UID Firebase Auth est différent de l'ID du document, créer un nouveau document
                if (currentUser.uid != userId) {
                  debugPrint('[AGENT_AUTH] 🔄 Synchronisation UID: $userId → ${currentUser.uid}');

                  // Copier les données vers le nouveau document avec l'UID Firebase Auth
                  final updatedData = Map<String, dynamic>.from(userData);
                  updatedData['uid'] = currentUser.uid;
                  updatedData['firebaseAuthCreated'] = true;
                  updatedData['firebaseAuthCreatedAt'] = FieldValue.serverTimestamp();
                  updatedData['lastLoginAt'] = FieldValue.serverTimestamp();

                  await _firestore.collection('users').doc(currentUser.uid).set(updatedData);

                  // Supprimer l'ancien document
                  await _firestore.collection('users').doc(userId).delete();

                  debugPrint('[AGENT_AUTH] ✅ Document agent synchronisé avec UID Firebase Auth');

                  return {
                    'success': true,
                    'user': currentUser,
                    'userData': updatedData,
                    'userId': currentUser.uid, // Utiliser le nouvel UID
                    'message': 'Connexion réussie',
                    'firstLogin': false,
                  };
                } else {
                  // Mettre à jour le document existant
                  await _firestore.collection('users').doc(userId).update({
                    'lastLoginAt': FieldValue.serverTimestamp(),
                  });

                  return {
                    'success': true,
                    'user': currentUser,
                    'userData': userData,
                    'userId': userId,
                    'message': 'Connexion réussie',
                    'firstLogin': false,
                  };
                }
              } catch (updateError) {
                debugPrint('[AGENT_AUTH] ⚠️ Erreur mise à jour document: $updateError');

                // Retourner quand même le succès car la connexion Firebase Auth a fonctionné
                return {
                  'success': true,
                  'user': currentUser,
                  'userData': userData,
                  'userId': currentUser.uid, // Utiliser l'UID Firebase Auth
                  'message': 'Connexion réussie',
                  'firstLogin': false,
                };
              }
            }
          }

          return {
            'success': false,
            'error': 'Email ou mot de passe incorrect',
            'code': 'invalid-credentials',
          };
        }
      }

    } catch (e) {
      debugPrint('[AGENT_AUTH] ❌ Erreur générale: $e');
      return {
        'success': false,
        'error': 'Erreur de connexion. Veuillez réessayer.',
        'code': 'general-error',
      };
    }
  }

  /// 🔓 Déconnexion
  static Future<void> logout() async {
    try {
      await _auth.signOut();
      debugPrint('[AGENT_AUTH] ✅ Déconnexion réussie');
    } catch (e) {
      debugPrint('[AGENT_AUTH] ❌ Erreur déconnexion: $e');
    }
  }

  /// 👤 Obtenir l'utilisateur actuel
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// 📋 Obtenir les données utilisateur depuis Firestore
  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('[AGENT_AUTH] ❌ Erreur récupération données: $e');
      return null;
    }
  }

  /// 🔄 Mettre à jour le mot de passe
  static Future<Map<String, dynamic>> updatePassword({
    required String userId,
    required String newPassword,
  }) async {
    try {
      // Mettre à jour dans Firestore
      await _firestore.collection('users').doc(userId).update({
        'password': newPassword,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour Firebase Auth si le compte existe
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.updatePassword(newPassword);
      }

      return {
        'success': true,
        'message': 'Mot de passe mis à jour avec succès',
      };

    } catch (e) {
      debugPrint('[AGENT_AUTH] ❌ Erreur mise à jour mot de passe: $e');
      return {
        'success': false,
        'error': 'Erreur lors de la mise à jour du mot de passe',
      };
    }
  }
}
