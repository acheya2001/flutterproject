import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 🔐 Service d'authentification Firebase
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🚀 Initialiser un super admin par défaut (pour les tests)
  static Future<void> initializeSuperAdmin() async {
    try {
      const superAdminEmail = 'constat.tunisie.app@gmail.com';
      const superAdminPassword = 'Acheya123';

      // Vérifier si le super admin existe déjà
      final existingUsers = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'super_admin')
          .get();

      if (existingUsers.docs.isEmpty) {
        debugPrint('[AUTH_SERVICE] 🔧 Création du super admin par défaut...');

        // Créer le compte Firebase Auth
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: superAdminEmail,
          password: superAdminPassword,
        );

        if (userCredential.user != null) {
          // Créer le profil dans Firestore
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'uid': userCredential.user!.uid,
            'email': superAdminEmail,
            'role': 'super_admin',
            'firstName': 'Super',
            'lastName': 'Admin',
            'status': 'active',
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': 'system',
            'permissions': [
              'create_companies',
              'manage_users',
              'view_all_data',
              'system_admin',
            ],
          });

          debugPrint('[AUTH_SERVICE] ✅ Super admin créé avec succès');
          debugPrint('[AUTH_SERVICE] 📧 Email: $superAdminEmail');
          debugPrint('[AUTH_SERVICE] 🔑 Mot de passe: $superAdminPassword');
        }
      } else {
        debugPrint('[AUTH_SERVICE] ℹ️ Super admin déjà existant');
      }
    } catch (e) {
      debugPrint('[AUTH_SERVICE] ❌ Erreur lors de l\'initialisation du super admin: $e');
    }
  }

  /// 🔐 Connexion utilisateur
  static Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AUTH_SERVICE] ❌ Erreur de connexion: ${e.code}');
      rethrow;
    }
  }

  /// 👤 Obtenir le profil utilisateur
  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('[AUTH_SERVICE] ❌ Erreur lors de la récupération du profil: $e');
      return null;
    }
  }

  /// 🚪 Déconnexion
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// 🔒 Vérifier le statut du compte utilisateur
  static Future<Map<String, dynamic>> checkAccountStatus(Map<String, dynamic> userData) async {
    try {
      final role = userData['role'];
      final isActive = userData['isActive'];

      debugPrint('[AUTH_SERVICE] 🔍 Vérification statut pour rôle: $role, isActive: $isActive');

      // 1. Vérification du statut direct de l'utilisateur
      if (isActive == false) {
        return {
          'isActive': false,
          'reason': 'user_disabled',
          'message': '🚫 Votre compte a été désactivé par un administrateur.\n\n'
                    'Contactez votre responsable pour plus d\'informations.',
        };
      }

      // 2. Vérifications spécifiques selon le rôle
      switch (role) {
        case 'super_admin':
          // Super admin toujours autorisé s'il est actif
          return {'isActive': true};

        case 'admin_compagnie':
          return await _checkAdminCompagnieStatus(userData);

        case 'admin_agence':
          return await _checkAdminAgenceStatus(userData);

        case 'agent':
          return await _checkAgentStatus(userData);

        case 'expert':
          return await _checkExpertStatus(userData);

        case 'conducteur':
          return await _checkConducteurStatus(userData);

        default:
          return {
            'isActive': false,
            'reason': 'unknown_role',
            'message': '🚫 Rôle utilisateur non reconnu.\n\n'
                      'Contactez l\'administrateur système.',
          };
      }
    } catch (e) {
      debugPrint('[AUTH_SERVICE] ❌ Erreur vérification statut: $e');
      return {
        'isActive': false,
        'reason': 'check_error',
        'message': '🚫 Erreur lors de la vérification du compte.\n\n'
                  'Veuillez réessayer ou contacter le support.',
      };
    }
  }

  /// 🏢 Vérifier le statut d'un admin compagnie
  static Future<Map<String, dynamic>> _checkAdminCompagnieStatus(Map<String, dynamic> userData) async {
    try {
      final compagnieId = userData['compagnieId'];

      if (compagnieId == null) {
        return {
          'isActive': false,
          'reason': 'no_company',
          'message': '🚫 Aucune compagnie associée à votre compte.\n\n'
                    'Contactez le super administrateur.',
        };
      }

      // Vérifier le statut de la compagnie
      final compagnieDoc = await _firestore
          .collection('compagnies')
          .doc(compagnieId)
          .get();

      if (!compagnieDoc.exists) {
        return {
          'isActive': false,
          'reason': 'company_not_found',
          'message': '🚫 Votre compagnie n\'existe plus dans le système.\n\n'
                    'Contactez le super administrateur.',
        };
      }

      final compagnieData = compagnieDoc.data()!;
      final compagnieStatut = compagnieData['statut'];

      if (compagnieStatut == 'inactif' || compagnieStatut == 'suspendu') {
        return {
          'isActive': false,
          'reason': 'company_disabled',
          'message': '🚫 Votre compagnie a été ${compagnieStatut == 'suspendu' ? 'suspendue' : 'désactivée'}.\n\n'
                    'Contactez le super administrateur pour plus d\'informations.',
        };
      }

      return {'isActive': true};
    } catch (e) {
      debugPrint('[AUTH_SERVICE] ❌ Erreur vérification admin compagnie: $e');
      return {
        'isActive': false,
        'reason': 'check_error',
        'message': '🚫 Erreur lors de la vérification de votre compagnie.\n\n'
                  'Veuillez réessayer.',
      };
    }
  }

  /// 🏪 Vérifier le statut d'un admin agence
  static Future<Map<String, dynamic>> _checkAdminAgenceStatus(Map<String, dynamic> userData) async {
    try {
      final agenceId = userData['agenceId'];
      final compagnieId = userData['compagnieId'];

      if (agenceId == null || compagnieId == null) {
        return {
          'isActive': false,
          'reason': 'no_agency',
          'message': '🚫 Aucune agence associée à votre compte.\n\n'
                    'Contactez votre admin compagnie.',
        };
      }

      // Vérifier d'abord la compagnie
      final compagnieStatus = await _checkAdminCompagnieStatus(userData);
      if (!compagnieStatus['isActive']) {
        return compagnieStatus;
      }

      // Vérifier le statut de l'agence
      final agenceDoc = await _firestore
          .collection('agences')
          .doc(agenceId)
          .get();

      if (!agenceDoc.exists) {
        return {
          'isActive': false,
          'reason': 'agency_not_found',
          'message': '🚫 Votre agence n\'existe plus dans le système.\n\n'
                    'Contactez votre admin compagnie.',
        };
      }

      final agenceData = agenceDoc.data()!;
      final agenceActive = agenceData['isActive'];

      if (agenceActive == false) {
        return {
          'isActive': false,
          'reason': 'agency_disabled',
          'message': '🚫 Votre agence a été désactivée.\n\n'
                    'Contactez votre admin compagnie pour plus d\'informations.',
        };
      }

      return {'isActive': true};
    } catch (e) {
      debugPrint('[AUTH_SERVICE] ❌ Erreur vérification admin agence: $e');
      return {
        'isActive': false,
        'reason': 'check_error',
        'message': '🚫 Erreur lors de la vérification de votre agence.\n\n'
                  'Veuillez réessayer.',
      };
    }
  }

  /// 👨‍💼 Vérifier le statut d'un agent
  static Future<Map<String, dynamic>> _checkAgentStatus(Map<String, dynamic> userData) async {
    // Même vérification que l'admin agence
    return await _checkAdminAgenceStatus(userData);
  }

  /// 👨‍🔧 Vérifier le statut d'un expert
  static Future<Map<String, dynamic>> _checkExpertStatus(Map<String, dynamic> userData) async {
    try {
      // Vérifier les deux formats possibles de champs compagnies
      final compagniesAssociees = userData['compagniesAssociees'] as List?;
      final compagniesPartenaires = userData['compagniesPartenaires'] as List?;
      final compagnieId = userData['compagnieId'] as String?;

      // Construire la liste des compagnies à vérifier
      List<String> compagniesToCheck = [];

      if (compagniesAssociees != null && compagniesAssociees.isNotEmpty) {
        compagniesToCheck.addAll(compagniesAssociees.cast<String>());
      }

      if (compagniesPartenaires != null && compagniesPartenaires.isNotEmpty) {
        compagniesToCheck.addAll(compagniesPartenaires.cast<String>());
      }

      if (compagnieId != null && compagnieId.isNotEmpty) {
        compagniesToCheck.add(compagnieId);
      }

      // Supprimer les doublons
      compagniesToCheck = compagniesToCheck.toSet().toList();

      debugPrint('[AUTH_SERVICE] 🔍 Expert - Données utilisateur: ${userData.keys.toList()}');
      debugPrint('[AUTH_SERVICE] 🔍 Expert - compagniesAssociees: $compagniesAssociees');
      debugPrint('[AUTH_SERVICE] 🔍 Expert - compagniesPartenaires: $compagniesPartenaires');
      debugPrint('[AUTH_SERVICE] 🔍 Expert - compagnieId: $compagnieId');
      debugPrint('[AUTH_SERVICE] 🔍 Expert - Compagnies à vérifier: $compagniesToCheck');

      if (compagniesToCheck.isEmpty) {
        return {
          'isActive': false,
          'reason': 'no_companies',
          'message': '🚫 Aucune compagnie associée à votre compte d\'expert.\n\n'
                    'Contactez le super administrateur.',
        };
      }

      // Vérifier qu'au moins une compagnie est active
      bool hasActiveCompany = false;
      for (String compagnieIdToCheck in compagniesToCheck) {
        try {
          // Essayer d'abord dans compagnies_assurance, puis dans compagnies
          DocumentSnapshot compagnieDoc = await _firestore
              .collection('compagnies_assurance')
              .doc(compagnieIdToCheck)
              .get();

          if (!compagnieDoc.exists) {
            compagnieDoc = await _firestore
                .collection('compagnies')
                .doc(compagnieIdToCheck)
                .get();
          }

          if (compagnieDoc.exists) {
            final compagnieData = compagnieDoc.data();
            if (compagnieData != null) {
              final dataMap = compagnieData as Map<String, dynamic>;
              final statut = dataMap['statut'] ?? 'actif';
              debugPrint('[AUTH_SERVICE] 🏢 Compagnie $compagnieIdToCheck - Statut: $statut');

              if (statut == 'actif' || statut == 'active') {
                hasActiveCompany = true;
                break;
              }
            }
          } else {
            debugPrint('[AUTH_SERVICE] ⚠️ Compagnie $compagnieIdToCheck non trouvée');
          }
        } catch (e) {
          debugPrint('[AUTH_SERVICE] ⚠️ Erreur vérification compagnie $compagnieIdToCheck: $e');
        }
      }

      if (!hasActiveCompany) {
        return {
          'isActive': false,
          'reason': 'no_active_companies',
          'message': '🚫 Aucune de vos compagnies associées n\'est active.\n\n'
                    'Contactez le super administrateur.',
        };
      }

      debugPrint('[AUTH_SERVICE] ✅ Expert - Au moins une compagnie active trouvée');
      return {'isActive': true};
    } catch (e) {
      debugPrint('[AUTH_SERVICE] ❌ Erreur vérification expert: $e');
      return {
        'isActive': false,
        'reason': 'check_error',
        'message': '🚫 Erreur lors de la vérification de votre statut d\'expert.\n\n'
                  'Veuillez réessayer.',
      };
    }
  }

  /// 🚗 Vérifier le statut d'un conducteur
  static Future<Map<String, dynamic>> _checkConducteurStatus(Map<String, dynamic> userData) async {
    // Les conducteurs sont généralement toujours autorisés s'ils sont actifs
    return {'isActive': true};
  }

  /// 👥 Créer un utilisateur avec rôle
  static Future<String?> createUserWithRole({
    required String email,
    required String password,
    required String role,
    required String firstName,
    required String lastName,
    String? compagnieId,
    String? agenceId,
  }) async {
    try {
      // Créer le compte Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Créer le profil dans Firestore
        final userData = {
          'uid': userCredential.user!.uid,
          'email': email,
          'role': role,
          'firstName': firstName,
          'lastName': lastName,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': _auth.currentUser?.uid ?? 'system',
        };

        // Ajouter les IDs de compagnie/agence si fournis
        if (compagnieId != null) userData['compagnieId'] = compagnieId;
        if (agenceId != null) userData['agenceId'] = agenceId;

        await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);

        debugPrint('[AUTH_SERVICE] ✅ Utilisateur créé: $email ($role)');
        return userCredential.user!.uid;
      }
    } catch (e) {
      debugPrint('[AUTH_SERVICE] ❌ Erreur lors de la création de l\'utilisateur: $e');
      rethrow;
    }
    return null;
  }

  /// 🏢 Créer une compagnie d'assurance
  static Future<String?> createCompany({
    required String nom,
    required String adresse,
    required String telephone,
    required String email,
  }) async {
    try {
      // Générer un ID unique pour la compagnie
      final compagnieRef = _firestore.collection('compagnies').doc();
      
      await compagnieRef.set({
        'id': compagnieRef.id,
        'nom': nom,
        'adresse': adresse,
        'telephone': telephone,
        'email': email,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser?.uid ?? 'system',
      });

      debugPrint('[AUTH_SERVICE] ✅ Compagnie créée: $nom');
      return compagnieRef.id;
    } catch (e) {
      debugPrint('[AUTH_SERVICE] ❌ Erreur lors de la création de la compagnie: $e');
      rethrow;
    }
  }

  /// 📊 Obtenir les statistiques
  static Future<Map<String, int>> getSystemStats() async {
    try {
      final compagniesSnapshot = await _firestore.collection('compagnies').get();
      final usersSnapshot = await _firestore.collection('users').get();
      final agencesSnapshot = await _firestore.collection('agences').get();

      return {
        'compagnies': compagniesSnapshot.docs.length,
        'users': usersSnapshot.docs.length,
        'agences': agencesSnapshot.docs.length,
        'agents': usersSnapshot.docs.where((doc) => doc.data()['role'] == 'agent_agence').length,
        'experts': usersSnapshot.docs.where((doc) => doc.data()['role'] == 'expert_auto').length,
        'conducteurs': usersSnapshot.docs.where((doc) => doc.data()['role'] == 'conducteur').length,
        'admin_compagnie': usersSnapshot.docs.where((doc) => doc.data()['role'] == 'admin_compagnie').length,
        'admin_agence': usersSnapshot.docs.where((doc) => doc.data()['role'] == 'admin_agence').length,
      };
    } catch (e) {
      debugPrint('[AUTH_SERVICE] ❌ Erreur lors de la récupération des statistiques: $e');
      return {};
    }
  }

  /// 🔍 Vérifier les permissions utilisateur
  static Future<bool> hasPermission(String permission) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final role = userData['role'] as String?;
      final permissions = userData['permissions'] as List<dynamic>?;

      // Super admin a toutes les permissions
      if (role == 'super_admin') return true;

      // Vérifier les permissions spécifiques
      return permissions?.contains(permission) ?? false;
    } catch (e) {
      debugPrint('[AUTH_SERVICE] ❌ Erreur lors de la vérification des permissions: $e');
      return false;
    }
  }
}
