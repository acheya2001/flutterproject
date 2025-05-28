import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../models/conducteur_model.dart';
import '../models/assureur_model.dart';
import '../models/expert_model.dart';
import '../../../utils/user_type.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Méthode pour s'inscrire avec email et mot de passe
  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String telephone,
    required UserType userType,
    String? adresse,
    String? cin,
    String? compagnie,
    String? matricule,
    String? cabinet,
    String? agrement,
  }) async {
    try {
      debugPrint('[AuthService] Starting registration for email: $email, userType: $userType');
      
      // Créer l'utilisateur dans Firebase Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final User? firebaseUser = userCredential.user;
      
      if (firebaseUser == null) {
        debugPrint('[AuthService] Firebase user is null after registration');
        return null;
      }
      
      debugPrint('[AuthService] Firebase user created with ID: ${firebaseUser.uid}');

      // Mettre à jour le profil de l'utilisateur
      await firebaseUser.updateDisplayName('$nom $prenom');
      
      final String userId = firebaseUser.uid;
      final now = DateTime.now();
      
      // Créer un document utilisateur de base
      final userData = {
        'id': userId,
        'email': email,
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'adresse': adresse,
        'type': userType.toString().split('.').last,
        'createdAt': now,
        'updatedAt': now,
      };
      
      await _firestore.collection('users').doc(userId).set(userData);
      
      // Créer un modèle d'utilisateur en fonction du type
      UserModel? user;
      
      debugPrint('[AuthService] Creating user model for type: $userType');
      
      switch (userType) {
        case UserType.conducteur:
          if (cin != null) {
            final conducteurData = {
              'userId': userId,
              'cin': cin,
              'vehiculeIds': <String>[],
              'createdAt': now,
              'updatedAt': now,
            };
            
            await _firestore.collection('conducteurs').doc(userId).set(conducteurData);
            
            user = ConducteurModel(
              id: userId,
              email: email,
              nom: nom,
              prenom: prenom,
              telephone: telephone,
              cin: cin,
              adresse: adresse,
              createdAt: now,
              updatedAt: now,
            );
          }
          break;
          
        case UserType.assureur:
          if (compagnie != null && matricule != null) {
            final assureurData = {
              'userId': userId,
              'compagnie': compagnie,
              'matricule': matricule,
              'dossierIds': <String>[],
              'createdAt': now,
              'updatedAt': now,
            };
            
            await _firestore.collection('assureurs').doc(userId).set(assureurData);
            
            user = AssureurModel(
              id: userId,
              email: email,
              nom: nom,
              prenom: prenom,
              telephone: telephone,
              compagnie: compagnie,
              matricule: matricule,
              adresse: adresse,
              createdAt: now,
              updatedAt: now,
            );
          }
          break;
          
        case UserType.expert:
          if (cabinet != null && agrement != null) {
            final expertData = {
              'userId': userId,
              'cabinet': cabinet,
              'agrement': agrement,
              'expertiseIds': <String>[],
              'createdAt': now,
              'updatedAt': now,
            };
            
            await _firestore.collection('experts').doc(userId).set(expertData);
            
            user = ExpertModel(
              id: userId,
              email: email,
              nom: nom,
              prenom: prenom,
              telephone: telephone,
              cabinet: cabinet,
              agrement: agrement,
              adresse: adresse,
              createdAt: now,
              updatedAt: now,
            );
          }
          break;
      }
      
      // Stocker le type d'utilisateur dans une collection séparée pour faciliter la récupération
      await _firestore.collection('user_types').doc(userId).set({
        'type': userType.toString().split('.').last,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('[AuthService] User type stored in Firestore');
      
      // Assurez-vous que le document user_types est créé
      try {
        final userTypeDoc = await _firestore.collection('user_types').doc(userId).get();
        if (!userTypeDoc.exists) {
          debugPrint('[AuthService] Creating missing user_type document for user: $userId');
          await _firestore.collection('user_types').doc(userId).set({
            'type': userType.toString().split('.').last,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        debugPrint('[AuthService] Error ensuring user_type document exists: $e');
      }
      
      return user;
    } catch (e) {
      debugPrint('[AuthService] Error in registerWithEmailAndPassword: $e');
      
      // Si l'erreur est liée à PigeonUserDetails, essayons de récupérer l'utilisateur
      if (e.toString().contains('PigeonUserDetails')) {
        debugPrint('[AuthService] PigeonUserDetails error detected, attempting to continue');
        
        // Vérifier si l'utilisateur a été créé malgré l'erreur
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          debugPrint('[AuthService] User was created in Firebase Auth: ${currentUser.uid}');
          // Continuer le processus d'inscription
          try {
            final String userId = currentUser.uid;
            final now = DateTime.now();
            
            // Vérifier si le document utilisateur existe déjà
            final userDoc = await _firestore.collection('users').doc(userId).get();
            if (!userDoc.exists) {
              // Créer le document utilisateur
              final userData = {
                'id': userId,
                'email': email,
                'nom': nom,
                'prenom': prenom,
                'telephone': telephone,
                'adresse': adresse,
                'type': userType.toString().split('.').last,
                'createdAt': now,
                'updatedAt': now,
              };
              
              await _firestore.collection('users').doc(userId).set(userData);
            }
            
            // Créer le document spécifique au type d'utilisateur
            UserModel? user;
            
            switch (userType) {
              case UserType.conducteur:
                if (cin != null) {
                  final conducteurDoc = await _firestore.collection('conducteurs').doc(userId).get();
                  if (!conducteurDoc.exists) {
                    final conducteurData = {
                      'userId': userId,
                      'cin': cin,
                      'vehiculeIds': <String>[],
                      'createdAt': now,
                      'updatedAt': now,
                    };
                    
                    await _firestore.collection('conducteurs').doc(userId).set(conducteurData);
                  }
                  
                  user = ConducteurModel(
                    id: userId,
                    email: email,
                    nom: nom,
                    prenom: prenom,
                    telephone: telephone,
                    cin: cin,
                    adresse: adresse,
                    createdAt: now,
                    updatedAt: now,
                  );
                }
                break;
                
              case UserType.assureur:
                if (compagnie != null && matricule != null) {
                  final assureurDoc = await _firestore.collection('assureurs').doc(userId).get();
                  if (!assureurDoc.exists) {
                    final assureurData = {
                      'userId': userId,
                      'compagnie': compagnie,
                      'matricule': matricule,
                      'dossierIds': <String>[],
                      'createdAt': now,
                      'updatedAt': now,
                    };
                    
                    await _firestore.collection('assureurs').doc(userId).set(assureurData);
                  }
                  
                  user = AssureurModel(
                    id: userId,
                    email: email,
                    nom: nom,
                    prenom: prenom,
                    telephone: telephone,
                    compagnie: compagnie,
                    matricule: matricule,
                    adresse: adresse,
                    createdAt: now,
                    updatedAt: now,
                  );
                }
                break;
                
              case UserType.expert:
                if (cabinet != null && agrement != null) {
                  final expertDoc = await _firestore.collection('experts').doc(userId).get();
                  if (!expertDoc.exists) {
                    final expertData = {
                      'userId': userId,
                      'cabinet': cabinet,
                      'agrement': agrement,
                      'expertiseIds': <String>[],
                      'createdAt': now,
                      'updatedAt': now,
                    };
                    
                    await _firestore.collection('experts').doc(userId).set(expertData);
                  }
                  
                  user = ExpertModel(
                    id: userId,
                    email: email,
                    nom: nom,
                    prenom: prenom,
                    telephone: telephone,
                    cabinet: cabinet,
                    agrement: agrement,
                    adresse: adresse,
                    createdAt: now,
                    updatedAt: now,
                  );
                }
                break;
            }
            
            // Stocker le type d'utilisateur
            final userTypeDoc = await _firestore.collection('user_types').doc(userId).get();
            if (!userTypeDoc.exists) {
              await _firestore.collection('user_types').doc(userId).set({
                'type': userType.toString().split('.').last,
                'createdAt': FieldValue.serverTimestamp(),
              });
            }
            
            return user;
          } catch (innerError) {
            debugPrint('[AuthService] Error during recovery: $innerError');
          }
        }
      }
      
      rethrow;
    }
  }

  // Méthode pour se connecter avec email et mot de passe
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[AuthService] Attempting to sign in with email: $email');
      
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final User? firebaseUser = userCredential.user;
      
      if (firebaseUser == null) {
        debugPrint('[AuthService] Firebase user is null after sign in');
        return null;
      }
      
      debugPrint('[AuthService] Successfully signed in user with ID: ${firebaseUser.uid}');
      
      // Récupérer le type d'utilisateur
      final userTypeDoc = await _firestore.collection('user_types').doc(firebaseUser.uid).get();
      
      if (!userTypeDoc.exists) {
        debugPrint('[AuthService] User type document does not exist for user: ${firebaseUser.uid}');
        
        // Essayer de créer le document user_types si l'utilisateur existe dans Firestore
        final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data()!;
          final userType = userData['type'] as String? ?? 'conducteur';
          
          await _firestore.collection('user_types').doc(firebaseUser.uid).set({
            'type': userType,
            'createdAt': FieldValue.serverTimestamp(),
          });
          
          debugPrint('[AuthService] Created missing user_type document with type: $userType');
        } else {
          return null;
        }
      }
      
      final String userTypeString = userTypeDoc.data()?['type'] as String? ?? 'conducteur';
      final UserType userType = UserType.values.firstWhere(
        (type) => type.toString().split('.').last == userTypeString,
        orElse: () => UserType.conducteur,
      );
      
      debugPrint('[AuthService] Retrieved user type: $userType');
      
      // Récupérer les données de l'utilisateur en fonction du type
      UserModel? user;
      
      switch (userType) {
        case UserType.conducteur:
          final conducteurDoc = await _firestore.collection('conducteurs').doc(firebaseUser.uid).get();
          if (conducteurDoc.exists && conducteurDoc.data() != null) {
            final userData = await _firestore.collection('users').doc(firebaseUser.uid).get();
            if (userData.exists && userData.data() != null) {
              final Map<String, dynamic> combinedData = {
                ...userData.data()!,
                ...conducteurDoc.data()!,
              };
              user = ConducteurModel.fromMap(combinedData);
              debugPrint('[AuthService] Retrieved ConducteurModel: ${user.toString()}');
            }
          }
          break;
          
        case UserType.assureur:
          final assureurDoc = await _firestore.collection('assureurs').doc(firebaseUser.uid).get();
          if (assureurDoc.exists && assureurDoc.data() != null) {
            final userData = await _firestore.collection('users').doc(firebaseUser.uid).get();
            if (userData.exists && userData.data() != null) {
              final Map<String, dynamic> combinedData = {
                ...userData.data()!,
                ...assureurDoc.data()!,
              };
              user = AssureurModel.fromMap(combinedData);
              debugPrint('[AuthService] Retrieved AssureurModel: ${user.toString()}');
            }
          }
          break;
          
        case UserType.expert:
          final expertDoc = await _firestore.collection('experts').doc(firebaseUser.uid).get();
          if (expertDoc.exists && expertDoc.data() != null) {
            final userData = await _firestore.collection('users').doc(firebaseUser.uid).get();
            if (userData.exists && userData.data() != null) {
              final Map<String, dynamic> combinedData = {
                ...userData.data()!,
                ...expertDoc.data()!,
              };
              user = ExpertModel.fromMap(combinedData);
              debugPrint('[AuthService] Retrieved ExpertModel: ${user.toString()}');
            }
          }
          break;
      }
      
      return user;
    } catch (e) {
      debugPrint('[AuthService] Error in signInWithEmailAndPassword: $e');
      
      // Si l'erreur est liée à PigeonUserDetails, essayons de récupérer l'utilisateur
      if (e.toString().contains('PigeonUserDetails')) {
        debugPrint('[AuthService] PigeonUserDetails error detected, attempting to continue');
        
        // Vérifier si l'utilisateur est connecté malgré l'erreur
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          debugPrint('[AuthService] User is signed in: ${currentUser.uid}');
          
          try {
            // Récupérer les données de l'utilisateur
            final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
            if (userDoc.exists && userDoc.data() != null) {
              final userData = userDoc.data()!;
              final userTypeString = userData['type'] as String? ?? 'conducteur';
              final UserType userType = UserType.values.firstWhere(
                (type) => type.toString().split('.').last == userTypeString,
                orElse: () => UserType.conducteur,
              );
              
              // Créer un modèle d'utilisateur en fonction du type
              UserModel? user;
              
              switch (userType) {
                case UserType.conducteur:
                  final conducteurDoc = await _firestore.collection('conducteurs').doc(currentUser.uid).get();
                  if (conducteurDoc.exists && conducteurDoc.data() != null) {
                    final Map<String, dynamic> combinedData = {
                      ...userData,
                      ...conducteurDoc.data()!,
                    };
                    user = ConducteurModel.fromMap(combinedData);
                  } else {
                    // Créer un UserModel de base
                    user = UserModel(
                      id: currentUser.uid,
                      email: userData['email'] as String? ?? '',
                      nom: userData['nom'] as String? ?? '',
                      prenom: userData['prenom'] as String? ?? '',
                      telephone: userData['telephone'] as String? ?? '',
                      type: userType,
                      adresse: userData['adresse'] as String?,
                      createdAt: (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                      updatedAt: (userData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                    );
                  }
                  break;
                  
                case UserType.assureur:
                  final assureurDoc = await _firestore.collection('assureurs').doc(currentUser.uid).get();
                  if (assureurDoc.exists && assureurDoc.data() != null) {
                    final Map<String, dynamic> combinedData = {
                      ...userData,
                      ...assureurDoc.data()!,
                    };
                    user = AssureurModel.fromMap(combinedData);
                  } else {
                    // Créer un UserModel de base
                    user = UserModel(
                      id: currentUser.uid,
                      email: userData['email'] as String? ?? '',
                      nom: userData['nom'] as String? ?? '',
                      prenom: userData['prenom'] as String? ?? '',
                      telephone: userData['telephone'] as String? ?? '',
                      type: userType,
                      adresse: userData['adresse'] as String?,
                      createdAt: (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                      updatedAt: (userData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                    );
                  }
                  break;
                  
                case UserType.expert:
                  final expertDoc = await _firestore.collection('experts').doc(currentUser.uid).get();
                  if (expertDoc.exists && expertDoc.data() != null) {
                    final Map<String, dynamic> combinedData = {
                      ...userData,
                      ...expertDoc.data()!,
                    };
                    user = ExpertModel.fromMap(combinedData);
                  } else {
                    // Créer un UserModel de base
                    user = UserModel(
                      id: currentUser.uid,
                      email: userData['email'] as String? ?? '',
                      nom: userData['nom'] as String? ?? '',
                      prenom: userData['prenom'] as String? ?? '',
                      telephone: userData['telephone'] as String? ?? '',
                      type: userType,
                      adresse: userData['adresse'] as String?,
                      createdAt: (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                      updatedAt: (userData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                    );
                  }
                  break;
              }
              
              return user;
            }
          } catch (innerError) {
            debugPrint('[AuthService] Error during recovery: $innerError');
          }
        }
      }
      
      rethrow;
    }
  }

  // Méthode pour récupérer l'utilisateur actuel
  Future<UserModel?> getCurrentUser() async {
    try {
      debugPrint('[AuthService] Getting current user');
      
      final User? firebaseUser = _auth.currentUser;
      
      if (firebaseUser == null) {
        debugPrint('[AuthService] No current user found');
        return null;
      }
      
      debugPrint('[AuthService] Current Firebase user ID: ${firebaseUser.uid}');
      
      // Récupérer le type d'utilisateur
      final userTypeDoc = await _firestore.collection('user_types').doc(firebaseUser.uid).get();
      
      if (!userTypeDoc.exists) {
        debugPrint('[AuthService] User type document does not exist for current user');
        
        // Essayer de créer le document user_types si l'utilisateur existe dans Firestore
        final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data()!;
          final userType = userData['type'] as String? ?? 'conducteur';
          
          await _firestore.collection('user_types').doc(firebaseUser.uid).set({
            'type': userType,
            'createdAt': FieldValue.serverTimestamp(),
          });
          
          debugPrint('[AuthService] Created missing user_type document with type: $userType');
        } else {
          return null;
        }
      }
      
      final String userTypeString = userTypeDoc.data()?['type'] as String? ?? 'conducteur';
      final UserType userType = UserType.values.firstWhere(
        (type) => type.toString().split('.').last == userTypeString,
        orElse: () => UserType.conducteur,
      );
      
      debugPrint('[AuthService] Current user type: $userType');
      
      // Récupérer les données de l'utilisateur en fonction du type
      UserModel? user;
      
      switch (userType) {
        case UserType.conducteur:
          final conducteurDoc = await _firestore.collection('conducteurs').doc(firebaseUser.uid).get();
          if (conducteurDoc.exists && conducteurDoc.data() != null) {
            final userData = await _firestore.collection('users').doc(firebaseUser.uid).get();
            if (userData.exists && userData.data() != null) {
              final Map<String, dynamic> combinedData = {
                ...userData.data()!,
                ...conducteurDoc.data()!,
              };
              user = ConducteurModel.fromMap(combinedData);
              debugPrint('[AuthService] Retrieved current ConducteurModel: ${user.toString()}');
            }
          }
          break;
          
        case UserType.assureur:
          final assureurDoc = await _firestore.collection('assureurs').doc(firebaseUser.uid).get();
          if (assureurDoc.exists && assureurDoc.data() != null) {
            final userData = await _firestore.collection('users').doc(firebaseUser.uid).get();
            if (userData.exists && userData.data() != null) {
              final Map<String, dynamic> combinedData = {
                ...userData.data()!,
                ...assureurDoc.data()!,
              };
              user = AssureurModel.fromMap(combinedData);
              debugPrint('[AuthService] Retrieved current AssureurModel: ${user.toString()}');
            }
          }
          break;
          
        case UserType.expert:
          final expertDoc = await _firestore.collection('experts').doc(firebaseUser.uid).get();
          if (expertDoc.exists && expertDoc.data() != null) {
            final userData = await _firestore.collection('users').doc(firebaseUser.uid).get();
            if (userData.exists && userData.data() != null) {
              final Map<String, dynamic> combinedData = {
                ...userData.data()!,
                ...expertDoc.data()!,
              };
              user = ExpertModel.fromMap(combinedData);
              debugPrint('[AuthService] Retrieved current ExpertModel: ${user.toString()}');
            }
          }
          break;
      }
      
      // Si nous n'avons pas pu récupérer l'utilisateur spécifique, essayons de récupérer l'utilisateur de base
      if (user == null) {
        final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          // Créer un UserModel de base à partir des données Firestore
          final userData = userDoc.data()!;
          user = UserModel(
            id: firebaseUser.uid,
            email: userData['email'] as String? ?? '',
            nom: userData['nom'] as String? ?? '',
            prenom: userData['prenom'] as String? ?? '',
            telephone: userData['telephone'] as String? ?? '',
            type: userType,
            adresse: userData['adresse'] as String?,
            createdAt: (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            updatedAt: (userData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
          debugPrint('[AuthService] Created basic UserModel: ${user.toString()}');
        }
      }
      
      return user;
    } catch (e) {
      debugPrint('[AuthService] Error in getCurrentUser: $e');
      
      // Si l'erreur est liée à PigeonUserDetails, essayons de récupérer l'utilisateur
      if (e.toString().contains('PigeonUserDetails')) {
        debugPrint('[AuthService] PigeonUserDetails error detected, attempting to continue');
        
        // Vérifier si l'utilisateur est connecté
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          debugPrint('[AuthService] User is signed in: ${currentUser.uid}');
          
          try {
            // Récupérer les données de l'utilisateur
            final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
            if (userDoc.exists && userDoc.data() != null) {
              final userData = userDoc.data()!;
              // Créer un UserModel de base
              return UserModel(
                id: currentUser.uid,
                email: userData['email'] as String? ?? '',
                nom: userData['nom'] as String? ?? '',
                prenom: userData['prenom'] as String? ?? '',
                telephone: userData['telephone'] as String? ?? '',
                type: UserType.values.firstWhere(
                  (type) => type.toString().split('.').last == (userData['type'] as String? ?? 'conducteur'),
                  orElse: () => UserType.conducteur,
                ),
                adresse: userData['adresse'] as String?,
                createdAt: (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                updatedAt: (userData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              );
            }
          } catch (innerError) {
            debugPrint('[AuthService] Error during recovery: $innerError');
          }
        }
      }
      
      return null;
    }
  }

  // Méthode pour se déconnecter
  Future<void> signOut() async {
    try {
      debugPrint('[AuthService] Signing out user');
      await _auth.signOut();
      debugPrint('[AuthService] User signed out successfully');
    } catch (e) {
      debugPrint('[AuthService] Error in signOut: $e');
      rethrow;
    }
  }

  // Méthode pour réinitialiser le mot de passe
  Future<void> resetPassword(String email) async {
    try {
      debugPrint('[AuthService] Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('[AuthService] Password reset email sent successfully');
    } catch (e) {
      debugPrint('[AuthService] Error in resetPassword: $e');
      rethrow;
    }
  }

  // Méthode pour vérifier si un utilisateur est connecté
  bool isUserLoggedIn() {
    final bool isLoggedIn = _auth.currentUser != null;
    debugPrint('[AuthService] Is user logged in: $isLoggedIn');
    return isLoggedIn;
  }
}