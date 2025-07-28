import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'company_structure_service.dart';
import 'company_management_service.dart';

/// 🏢 Service pour la gestion des Admin Compagnie
class AdminCompagnieService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔐 Générer un mot de passe sécurisé
  static String generateSecurePassword() {
    const String chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    const String symbols = '@#!&*';
    final random = math.Random.secure();

    // Structure: @Assur + 4 chiffres + # + 2 lettres + !
    final year = DateTime.now().year;
    final numbers = List.generate(4, (_) => random.nextInt(10)).join();
    final letters = List.generate(2, (_) => chars[random.nextInt(chars.length)]).join();

    return '@Assur$year#$numbers$letters!';
  }

  /// 👤 Créer un nouveau Admin Compagnie
  static Future<Map<String, dynamic>> createAdminCompagnie({
    required String prenom,
    required String nom,
    required String telephone,
    required String compagnieId,
    required String compagnieNom,
  }) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🏢 Création Admin Compagnie: $prenom $nom');

      // Vérifier que l'utilisateur actuel est bien un Super Admin
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔍 Utilisateur actuel: ${currentUser.uid}');
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔍 Email actuel: ${currentUser.email}');

      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔍 Document existe: ${currentUserDoc.exists}');

      if (currentUserDoc.exists) {
        final userData = currentUserDoc.data();
        debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔍 Role utilisateur: ${userData?['role']}');
        debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔍 Données utilisateur: $userData');
      }

      // Vérification alternative pour le super admin
      bool isSuperAdmin = false;

      if (currentUserDoc.exists) {
        final userData = currentUserDoc.data();
        isSuperAdmin = userData?['role'] == 'super_admin';
      }

      // Vérification alternative par email (pour le compte principal)
      if (!isSuperAdmin && currentUser.email == 'constat.tunisie.app@gmail.com') {
        debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔍 Utilisateur reconnu comme super admin par email');
        isSuperAdmin = true;
      }

      if (!isSuperAdmin) {
        String currentRole = 'document inexistant';
        if (currentUserDoc.exists) {
          final userData = currentUserDoc.data();
          currentRole = userData?['role']?.toString() ?? 'role non défini';
        }
        throw Exception('Seul un Super Admin peut créer des Admin Compagnie. Role actuel: $currentRole');
      }

      // Recherche intelligente de la compagnie avec le nouveau service
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔍 Recherche compagnie ID: $compagnieId');
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔍 Nom compagnie: $compagnieNom');

      var company = await CompanyManagementService.smartFindCompany(compagnieId);

      if (company == null) {
        // Essayer par nom si l'ID ne fonctionne pas
        debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔍 Recherche par nom: $compagnieNom');
        company = await CompanyManagementService.findCompanyByName(compagnieNom);
      }

      if (company == null) {
        throw Exception('Compagnie non trouvée (ID: $compagnieId, Nom: $compagnieNom)');
      }

      // Utiliser l'ID correct de la compagnie trouvée
      compagnieId = company.id;
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ✅ Compagnie trouvée: ${company.nom} (ID: $compagnieId)');

      // 🎯 VÉRIFICATION AMÉLIORÉE : Admin actif uniquement
      bool hasActiveAdmin = false;

      if (company.adminCompagnieId != null && company.adminCompagnieId!.isNotEmpty) {
        try {
          // Vérifier si l'admin existe et est vraiment actif
          final adminDoc = await _firestore
              .collection('users')
              .doc(company.adminCompagnieId!)
              .get();

          if (adminDoc.exists) {
            final adminData = adminDoc.data()!;
            final isActive = adminData['isActive'] ?? false;
            final status = adminData['status'] ?? '';

            hasActiveAdmin = isActive && status == 'actif';

            debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔍 Admin ${company.adminCompagnieNom}: ${hasActiveAdmin ? "ACTIF" : "INACTIF"}');
          } else {
            // L'admin n'existe plus, libérer la compagnie automatiquement
            debugPrint('[ADMIN_COMPAGNIE_SERVICE] ⚠️ Admin ${company.adminCompagnieId} n\'existe plus, libération automatique');

            await _firestore.collection('compagnies').doc(compagnieId).update({
              'adminCompagnieId': FieldValue.delete(),
              'adminCompagnieNom': FieldValue.delete(),
              'adminCompagnieEmail': FieldValue.delete(),
              'adminAssignedAt': FieldValue.delete(),
              'isAvailable': true,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (e) {
          debugPrint('[ADMIN_COMPAGNIE_SERVICE] ❌ Erreur vérification admin: $e');
        }
      }

      if (hasActiveAdmin) {
        throw Exception('Cette compagnie a déjà un administrateur ACTIF assigné: ${company.adminCompagnieNom}');
      }

      // Vérifier qu'il n'y a pas déjà un admin pour cette compagnie
      final existingAdmin = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_compagnie')
          .where('compagnieId', isEqualTo: compagnieId)
          .where('status', isEqualTo: 'actif')
          .get();

      if (existingAdmin.docs.isNotEmpty) {
        throw Exception('Cette compagnie a déjà un Admin Compagnie actif');
      }

      // Générer l'email automatiquement
      final email = await _generateEmail(prenom, nom, compagnieNom);
      
      // Vérifier que l'email n'existe pas déjà
      final existingUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (existingUser.docs.isNotEmpty) {
        throw Exception('Un utilisateur avec cet email existe déjà');
      }

      // Générer un mot de passe sécurisé
      final password = generateSecurePassword();

      // 🔐 ÉTAPE CRITIQUE : Créer le compte Firebase Auth
      UserCredential? userCredential;
      String userId;

      try {
        debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔐 Création compte Firebase Auth...');
        userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Utiliser l'UID généré par Firebase Auth
        userId = userCredential.user!.uid;
        debugPrint('[ADMIN_COMPAGNIE_SERVICE] ✅ Compte Firebase Auth créé: $userId');

      } catch (e) {
        debugPrint('[ADMIN_COMPAGNIE_SERVICE] ❌ Erreur création Firebase Auth: $e');
        throw Exception('Erreur création compte Firebase Auth: $e');
      }

      // Créer le document utilisateur
      final userData = {
        'uid': userId,
        'email': email,
        'prenom': prenom,
        'nom': nom,
        'displayName': '$prenom $nom',
        'telephone': telephone,
        'role': 'admin_compagnie',
        'status': 'actif',
        'isActive': true,
        'isLegitimate': true,
        'compagnieId': compagnieId,
        'compagnieNom': compagnieNom,
        'firebaseAuthCreated': true, // Indique que le compte Firebase Auth existe
        'permissions': [
          'manage_company_data',
          'view_company_stats',
          'manage_company_agents',
          'view_company_reports',
        ],
        'requirePasswordChange': true,
        'password': password, // Temporaire pour transmission
        'temporaryPassword': password,
        'createdBy': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'source': 'super_admin_creation',
        'accountType': 'admin_compagnie',
        'lastLoginAt': null,
        'loginCount': 0,
        'twoFactorEnabled': false,
      };

      // Sauvegarder dans Firestore
      await _firestore.collection('users').doc(userId).set(userData);

      // Mettre à jour la compagnie avec l'admin assigné dans la collection unifiée
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔄 Mise à jour compagnie ID: $compagnieId');
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔄 Admin ID: $userId');
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔄 Admin Email: $email');

      // Mettre à jour directement dans la collection compagnies
      await _firestore.collection('compagnies').doc(compagnieId).update({
        'adminCompagnieId': userId,
        'adminCompagnieNom': '$prenom $nom',
        'adminCompagnieEmail': email,
        'adminAssignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final updateSuccess = await CompanyStructureService.updateCompanyAdmin(
        compagnieId: compagnieId,
        adminId: userId,
        adminNom: '$prenom $nom',
        adminEmail: email,
      );

      if (!updateSuccess) {
        debugPrint('[ADMIN_COMPAGNIE_SERVICE] ⚠️ Échec mise à jour compagnie, mais compte créé');
      }

      // Log de sécurité
      await _logSecurityEvent(
        action: 'admin_compagnie_created',
        targetUserId: userId,
        targetEmail: email,
        performedBy: currentUser.uid,
        details: {
          'prenom': prenom,
          'nom': nom,
          'telephone': telephone,
          'compagnieId': compagnieId,
          'compagnieNom': compagnieNom,
        },
      );

      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ✅ Admin Compagnie créé: $email');

      return {
        'success': true,
        'userId': userId,
        'email': email,
        'password': password,
        'compagnieNom': compagnieNom,
        'displayName': '$prenom $nom',
        'message': 'Admin Compagnie créé avec succès',
      };
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ❌ Erreur création Admin Compagnie: $e');
      
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 📧 Générer l'email automatiquement
  static Future<String> _generateEmail(String prenom, String nom, String compagnieNom) async {
    // Nettoyer les noms (enlever accents, espaces, caractères spéciaux)
    final cleanPrenom = _cleanString(prenom);
    final cleanNom = _cleanString(nom);
    final cleanCompagnie = _cleanString(compagnieNom);

    String baseEmail = '$cleanPrenom.$cleanNom@$cleanCompagnie.com';
    
    // Vérifier si l'email existe déjà
    final existingUser = await _firestore
        .collection('users')
        .where('email', isEqualTo: baseEmail)
        .get();

    if (existingUser.docs.isEmpty) {
      return baseEmail;
    }

    // Si l'email existe, ajouter un chiffre
    int counter = 2;
    String emailWithNumber;
    
    do {
      emailWithNumber = '$cleanPrenom.$cleanNom$counter@$cleanCompagnie.com';
      final existingUserWithNumber = await _firestore
          .collection('users')
          .where('email', isEqualTo: emailWithNumber)
          .get();
      
      if (existingUserWithNumber.docs.isEmpty) {
        return emailWithNumber;
      }
      
      counter++;
    } while (counter <= 99); // Limite de sécurité

    throw Exception('Impossible de générer un email unique');
  }

  /// 🧹 Nettoyer une chaîne pour l'email
  static String _cleanString(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ýÿ]'), 'y')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  /// 🔐 Générer un mot de passe sécurisé
  static String _generateSecurePassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    const specialChars = '!@#\$%^&*';
    const numbers = '0123456789';
    const upperCase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowerCase = 'abcdefghijklmnopqrstuvwxyz';
    
    final random = math.Random.secure();
    
    // Assurer au moins un caractère de chaque type
    String password = '';
    password += upperCase[random.nextInt(upperCase.length)];
    password += lowerCase[random.nextInt(lowerCase.length)];
    password += numbers[random.nextInt(numbers.length)];
    password += specialChars[random.nextInt(specialChars.length)];
    
    // Compléter avec des caractères aléatoires (total 10 caractères)
    for (int i = 4; i < 10; i++) {
      password += chars[random.nextInt(chars.length)];
    }
    
    // Mélanger les caractères
    final passwordList = password.split('');
    passwordList.shuffle(random);
    
    return passwordList.join('');
  }

  /// 🆔 Générer un ID utilisateur unique
  static String _generateUserId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = math.Random().nextInt(999999);
    return 'admin_comp_${timestamp}_$random';
  }

  /// 📝 Logger un événement de sécurité
  static Future<void> _logSecurityEvent({
    required String action,
    String? targetUserId,
    String? targetEmail,
    String? performedBy,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _firestore.collection('security_logs').add({
        'action': action,
        'targetUserId': targetUserId,
        'targetEmail': targetEmail,
        'performedBy': performedBy,
        'performedAt': FieldValue.serverTimestamp(),
        'details': details ?? {},
        'severity': 'medium',
        'category': 'admin_compagnie_management',
        'ipAddress': null,
        'userAgent': null,
      });
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ⚠️ Erreur log sécurité: $e');
    }
  }

  /// 📊 Lister tous les Admin Compagnie
  static Future<List<Map<String, dynamic>>> getAllAdminCompagnie() async {
    try {
      final query = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_compagnie')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        // Ne pas exposer les mots de passe
        data.remove('password');
        data.remove('temporaryPassword');
        return data;
      }).toList();
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ❌ Erreur liste Admin Compagnie: $e');
      rethrow;
    }
  }

  /// 🔒 Désactiver un Admin Compagnie
  static Future<void> deactivateAdminCompagnie(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer les infos de l'admin à désactiver
      final adminDoc = await _firestore.collection('users').doc(userId).get();
      if (!adminDoc.exists) {
        throw Exception('Admin Compagnie non trouvé');
      }

      final adminData = adminDoc.data()!;
      final compagnieId = adminData['compagnieId'];

      // Désactiver l'admin
      await _firestore.collection('users').doc(userId).update({
        'status': 'desactive',
        'isActive': false,
        'deactivatedBy': currentUser.uid,
        'deactivatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour la compagnie
      if (compagnieId != null) {
        await _firestore.collection('compagnies_assurance').doc(compagnieId).update({
          'adminCompagnieId': null,
          'adminCompagnieNom': null,
          'adminCompagnieEmail': null,
          'adminRemovedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Log de sécurité
      await _logSecurityEvent(
        action: 'admin_compagnie_deactivated',
        targetUserId: userId,
        performedBy: currentUser.uid,
      );

      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ✅ Admin Compagnie désactivé: $userId');
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ❌ Erreur désactivation: $e');
      rethrow;
    }
  }

  /// 📊 Récupérer les statistiques d'une compagnie
  static Future<Map<String, dynamic>> getCompagnieStats(String compagnieId) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 📊 Chargement stats pour compagnie: $compagnieId');

      // Compter les agences
      final agencesQuery = await _firestore
          .collection('agences')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();
      final nombreAgences = agencesQuery.docs.length;

      // Compter les admins agence
      final adminsAgenceQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_agence')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();
      final nombreAdminsAgence = adminsAgenceQuery.docs.length;

      // Compter les agents
      final agentsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();
      final nombreAgents = agentsQuery.docs.length;

      // Compter les experts associés
      final expertsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'expert')
          .where('compagniesIds', arrayContains: compagnieId)
          .get();
      final nombreExperts = expertsQuery.docs.length;

      // Compter les sinistres par statut
      final sinistresQuery = await _firestore
          .collection('sinistres')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      int sinistresEnCours = 0;
      int sinistresValides = 0;
      int sinistresRefuses = 0;
      int sinistresTotal = sinistresQuery.docs.length;

      for (final doc in sinistresQuery.docs) {
        final status = doc.data()['status'] as String? ?? '';
        switch (status.toLowerCase()) {
          case 'en_cours':
          case 'en_traitement':
          case 'expert_assigne':
            sinistresEnCours++;
            break;
          case 'valide':
          case 'clos':
            sinistresValides++;
            break;
          case 'refuse':
          case 'rejete':
            sinistresRefuses++;
            break;
        }
      }

      final stats = {
        'nombreAgences': nombreAgences,
        'nombreAdminsAgence': nombreAdminsAgence,
        'nombreAgents': nombreAgents,
        'nombreExperts': nombreExperts,
        'sinistresTotal': sinistresTotal,
        'sinistresEnCours': sinistresEnCours,
        'sinistresValides': sinistresValides,
        'sinistresRefuses': sinistresRefuses,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      };

      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ✅ Stats chargées: $stats');
      return stats;

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ❌ Erreur chargement stats: $e');
      return {
        'nombreAgences': 0,
        'nombreAdminsAgence': 0,
        'nombreAgents': 0,
        'nombreExperts': 0,
        'sinistresTotal': 0,
        'sinistresEnCours': 0,
        'sinistresValides': 0,
        'sinistresRefuses': 0,
        'error': e.toString(),
      };
    }
  }

  /// 🏢 Récupérer les agences d'une compagnie
  static Future<List<Map<String, dynamic>>> getAgences(String compagnieId) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🏢 Chargement agences pour: $compagnieId');

      final query = await _firestore
          .collection('agences')
          .where('compagnieId', isEqualTo: compagnieId)
          .orderBy('createdAt', descending: true)
          .get();

      final agences = <Map<String, dynamic>>[];

      for (final doc in query.docs) {
        final data = doc.data();
        data['id'] = doc.id;

        // Récupérer l'admin de l'agence
        if (data['adminAgenceId'] != null) {
          try {
            final adminDoc = await _firestore
                .collection('users')
                .doc(data['adminAgenceId'])
                .get();

            if (adminDoc.exists) {
              final adminData = adminDoc.data()!;
              data['adminNom'] = '${adminData['prenom']} ${adminData['nom']}';
              data['adminEmail'] = adminData['email'];
              data['adminActif'] = adminData['isActive'] ?? false;
            }
          } catch (e) {
            debugPrint('Erreur récupération admin agence: $e');
          }
        }

        agences.add(data);
      }

      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ✅ ${agences.length} agences chargées');
      return agences;

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ❌ Erreur chargement agences: $e');
      return [];
    }
  }

  /// 👥 Récupérer les agents d'une compagnie
  static Future<List<Map<String, dynamic>>> getAgents(String compagnieId) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 👥 Chargement agents pour: $compagnieId');

      final query = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('compagnieId', isEqualTo: compagnieId)
          .orderBy('createdAt', descending: true)
          .get();

      final agents = <Map<String, dynamic>>[];

      for (final doc in query.docs) {
        final data = doc.data();
        data['id'] = doc.id;

        // Récupérer le nom de l'agence
        if (data['agenceId'] != null) {
          try {
            final agenceDoc = await _firestore
                .collection('agences')
                .doc(data['agenceId'])
                .get();

            if (agenceDoc.exists) {
              data['agenceNom'] = agenceDoc.data()!['nom'];
            }
          } catch (e) {
            debugPrint('Erreur récupération agence: $e');
          }
        }

        agents.add(data);
      }

      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ✅ ${agents.length} agents chargés');
      return agents;

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ❌ Erreur chargement agents: $e');
      return [];
    }
  }

  /// 🧑‍🔬 Récupérer les experts associés à une compagnie
  static Future<List<Map<String, dynamic>>> getExperts(String compagnieId) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🧑‍🔬 Chargement experts pour: $compagnieId');

      final query = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'expert')
          .where('compagniesIds', arrayContains: compagnieId)
          .orderBy('createdAt', descending: true)
          .get();

      final experts = <Map<String, dynamic>>[];

      for (final doc in query.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        experts.add(data);
      }

      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ✅ ${experts.length} experts chargés');
      return experts;

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ❌ Erreur chargement experts: $e');
      return [];
    }
  }

  /// 🚨 Récupérer les sinistres d'une compagnie
  static Future<List<Map<String, dynamic>>> getSinistres(String compagnieId, {String? statusFilter}) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🚨 Chargement sinistres pour: $compagnieId');

      Query query = _firestore
          .collection('sinistres')
          .where('compagnieId', isEqualTo: compagnieId);

      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.where('status', isEqualTo: statusFilter);
      }

      final querySnapshot = await query
          .orderBy('dateDeclaration', descending: true)
          .get();

      final sinistres = <Map<String, dynamic>>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        // Récupérer les informations supplémentaires
        if (data['agenceId'] != null) {
          try {
            final agenceDoc = await _firestore
                .collection('agences')
                .doc(data['agenceId'])
                .get();

            if (agenceDoc.exists) {
              data['agenceNom'] = agenceDoc.data()!['nom'];
            }
          } catch (e) {
            debugPrint('Erreur récupération agence: $e');
          }
        }

        sinistres.add(data);
      }

      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ✅ ${sinistres.length} sinistres chargés');
      return sinistres;

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ❌ Erreur chargement sinistres: $e');
      return [];
    }
  }

  /// 🏢 Créer une nouvelle agence
  static Future<Map<String, dynamic>> creerAgence({
    required String compagnieId,
    required String nom,
    required String adresse,
    required String telephone,
    String? email,
  }) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🏢 Création agence: $nom');

      final agenceData = {
        'nom': nom,
        'adresse': adresse,
        'telephone': telephone,
        'email': email ?? '',
        'compagnieId': compagnieId,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'status': 'active',
      };

      final docRef = await _firestore.collection('agences').add(agenceData);

      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ✅ Agence créée avec ID: ${docRef.id}');

      return {
        'success': true,
        'agenceId': docRef.id,
        'message': 'Agence créée avec succès',
      };

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ❌ Erreur création agence: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de la création de l\'agence',
      };
    }
  }

  /// 👤 Créer un admin agence
  static Future<Map<String, dynamic>> creerAdminAgence({
    required String agenceId,
    required String compagnieId,
    required String nom,
    required String prenom,
    required String email,
  }) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 👤 Création admin agence: $email');

      // Vérifier si l'email existe déjà
      final existingUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (existingUser.docs.isNotEmpty) {
        return {
          'success': false,
          'error': 'Email déjà utilisé',
          'message': 'Cet email est déjà utilisé par un autre utilisateur',
        };
      }

      // Générer un mot de passe temporaire
      final tempPassword = _generateTempPassword();

      final adminData = {
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'role': 'admin_agence',
        'agenceId': agenceId,
        'compagnieId': compagnieId,
        'isActive': true,
        'status': 'actif',
        'tempPassword': tempPassword,
        'mustChangePassword': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'admin_compagnie',
      };

      final docRef = await _firestore.collection('users').add(adminData);

      // Mettre à jour l'agence avec l'ID de l'admin
      await _firestore.collection('agences').doc(agenceId).update({
        'adminAgenceId': docRef.id,
        'adminAgenceNom': '$prenom $nom',
        'adminAgenceEmail': email,
      });

      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ✅ Admin agence créé avec ID: ${docRef.id}');

      return {
        'success': true,
        'adminId': docRef.id,
        'tempPassword': tempPassword,
        'message': 'Admin agence créé avec succès',
      };

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ❌ Erreur création admin agence: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de la création de l\'admin agence',
      };
    }
  }

  /// 🔑 Générer un mot de passe temporaire
  static String _generateTempPassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return 'Temp${random.toString().substring(8)}!';
  }

  /// 🔍 Vérifier et finaliser la création d'un admin compagnie
  static Future<Map<String, dynamic>> verifyAndFinalizeAdminCreation({
    required String email,
    required String prenom,
    required String nom,
    required String telephone,
    required String compagnieId,
    required String compagnieNom,
    required String password,
  }) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔍 Vérification création admin: $email');

      // 1. Chercher l'utilisateur Firebase Auth par email
      String? userId;

      // Essayer de se connecter avec les identifiants pour récupérer l'UID
      try {
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        userId = credential.user?.uid;

        // Se déconnecter immédiatement
        await FirebaseAuth.instance.signOut();

        debugPrint('[ADMIN_COMPAGNIE_SERVICE] ✅ Utilisateur trouvé avec UID: $userId');

      } catch (e) {
        debugPrint('[ADMIN_COMPAGNIE_SERVICE] ❌ Impossible de récupérer l\'UID: $e');
        return {
          'success': false,
          'error': 'Compte créé mais impossible de récupérer l\'UID',
        };
      }

      if (userId == null) {
        return {
          'success': false,
          'error': 'UID non récupéré',
        };
      }

      // 2. Créer le document Firestore
      final userData = {
        'uid': userId,
        'email': email,
        'prenom': prenom,
        'nom': nom,
        'displayName': '$prenom $nom',
        'telephone': telephone,
        'role': 'admin_compagnie',
        'status': 'actif',
        'isActive': true,
        'isLegitimate': true,
        'compagnieId': compagnieId,
        'compagnieNom': compagnieNom,
        'firebaseAuthCreated': true,
        'permissions': [
          'manage_company_data',
          'view_company_stats',
          'manage_company_agents',
          'view_company_reports',
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'super_admin',
        'password': password,
        'requirePasswordChange': false,
        'emailSent': false,
        'emailSentAt': null,
        'emailError': null,
      };

      await _firestore.collection('users').doc(userId).set(userData);
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ✅ Document Firestore créé');

      // 3. Mettre à jour la compagnie
      await _firestore.collection('compagnies').doc(compagnieId).update({
        'adminCompagnieId': userId,
        'adminCompagnieNom': '$prenom $nom',
        'adminCompagnieEmail': email,
        'adminAssignedAt': FieldValue.serverTimestamp(),
        'isAvailable': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ✅ Compagnie mise à jour');

      return {
        'success': true,
        'message': 'Admin compagnie créé avec succès',
        'adminId': userId,
        'password': password,
        'email': email,
        'compagnieId': compagnieId,
        'compagnieNom': compagnieNom,
      };

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ❌ Erreur finalisation: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 👤 Créer un admin compagnie avec Firebase Auth
  static Future<Map<String, dynamic>> creerAdminCompagnie({
    required String compagnieNom,
    required String nom,
    required String prenom,
    required String telephone,
    String? email, // Email optionnel, sera généré si non fourni
  }) async {
    try {
      // Générer l'email si non fourni
      final finalEmail = email ?? await _generateEmail(prenom, nom, compagnieNom);

      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 👤 Création admin compagnie: $finalEmail');

      // 1. Vérifier si l'email existe déjà
      final existingUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: finalEmail)
          .get();

      if (existingUser.docs.isNotEmpty) {
        return {
          'success': false,
          'error': 'Email déjà utilisé',
          'message': 'Cet email est déjà utilisé par un autre utilisateur',
        };
      }

      // 2. Trouver la compagnie par nom
      final compagniesQuery = await _firestore
          .collection('compagnies')
          .where('nom', isEqualTo: compagnieNom)
          .limit(1)
          .get();

      if (compagniesQuery.docs.isEmpty) {
        return {
          'success': false,
          'error': 'Compagnie non trouvée',
          'message': 'Aucune compagnie trouvée avec le nom: $compagnieNom',
        };
      }

      final compagnie = compagniesQuery.docs.first;
      final compagnieId = compagnie.id;

      // 3. Générer un mot de passe sécurisé
      final password = generateSecurePassword();

      // 4. 🔐 ÉTAPE CRITIQUE : Créer le compte Firebase Auth
      String userId;

      try {
        debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔐 Création compte Firebase Auth...');

        // Contournement du bug Firebase Auth Flutter
        UserCredential? userCredential;
        try {
          userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: finalEmail,
            password: password,
          );
          userId = userCredential.user!.uid;
        } catch (authError) {
          debugPrint('[ADMIN_COMPAGNIE_SERVICE] ⚠️ Erreur cast Firebase Auth (bug connu): $authError');

          // Récupérer l'utilisateur actuel (qui a été créé malgré l'erreur)
          await Future.delayed(const Duration(milliseconds: 500)); // Attendre la synchronisation
          final currentUser = FirebaseAuth.instance.currentUser;

          if (currentUser != null && currentUser.email == finalEmail) {
            userId = currentUser.uid;
            debugPrint('[ADMIN_COMPAGNIE_SERVICE] ✅ Utilisateur récupéré après création: $userId');

            // Se déconnecter pour ne pas interférer avec le Super Admin
            await FirebaseAuth.instance.signOut();
          } else {
            throw Exception('Impossible de récupérer l\'utilisateur créé');
          }
        }

        debugPrint('[ADMIN_COMPAGNIE_SERVICE] ✅ Compte Firebase Auth créé: $userId');

      } catch (e) {
        debugPrint('[ADMIN_COMPAGNIE_SERVICE] ❌ Erreur création Firebase Auth: $e');
        return {
          'success': false,
          'error': 'Erreur création compte Firebase Auth: $e',
          'message': 'Impossible de créer le compte de connexion',
        };
      }

      // 5. Créer le document utilisateur dans Firestore
      final userData = {
        'uid': userId,
        'email': finalEmail,
        'prenom': prenom,
        'nom': nom,
        'displayName': '$prenom $nom',
        'telephone': telephone,
        'role': 'admin_compagnie',
        'status': 'actif',
        'isActive': true,
        'isLegitimate': true,
        'compagnieId': compagnieId,
        'compagnieNom': compagnieNom,
        'firebaseAuthCreated': true, // Indique que le compte Firebase Auth existe
        'permissions': [
          'manage_company_data',
          'view_company_stats',
          'manage_company_agents',
          'view_company_reports',
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'super_admin',
        'password': password, // Stocké pour référence (en production, utiliser un hash)
        'requirePasswordChange': false,
        'emailSent': false,
        'emailSentAt': null,
        'emailError': null,
      };

      await _firestore.collection('users').doc(userId).set(userData);
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ✅ Document Firestore créé');

      // 6. Mettre à jour la compagnie avec l'admin
      await _firestore.collection('compagnies').doc(compagnieId).update({
        'adminCompagnieId': userId,
        'adminCompagnieNom': '$prenom $nom',
        'adminCompagnieEmail': finalEmail,
        'adminAssignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ✅ Compagnie mise à jour');

      return {
        'success': true,
        'message': 'Admin compagnie créé avec succès',
        'adminId': userId,
        'password': password,
        'email': finalEmail,
        'compagnieId': compagnieId,
        'compagnieNom': compagnieNom,
      };

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ❌ Erreur création admin compagnie: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de la création de l\'admin compagnie',
      };
    }
  }

  /// 🎯 Méthode hybride optimisée pour créer admin compagnie
  static Future<Map<String, dynamic>> createAdminCompagnieHybrid({
    required String prenom,
    required String nom,
    required String telephone,
    required String compagnieId,
    required String compagnieNom,
  }) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🎯 Création hybride admin compagnie');

      // 1. Essayer d'abord la méthode standard
      try {
        debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔐 Tentative méthode standard...');

        final standardResult = await creerAdminCompagnie(
          prenom: prenom,
          nom: nom,
          telephone: telephone,
          compagnieNom: compagnieNom,
        );

        if (standardResult['success']) {
          debugPrint('[ADMIN_COMPAGNIE_SERVICE] ✅ Méthode standard réussie');
          standardResult['method'] = 'standard';
          standardResult['firebaseAuthReady'] = true;
          return standardResult;
        }

      } catch (e) {
        debugPrint('[ADMIN_COMPAGNIE_SERVICE] ⚠️ Méthode standard échouée: $e');

        // Vérifier si c'est un problème SSL/reCAPTCHA
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('ssl') ||
            errorStr.contains('recaptcha') ||
            errorStr.contains('connection reset') ||
            errorStr.contains('pigeon')) {
          debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔧 Basculement vers méthode alternative');
        } else {
          // Si ce n'est pas un problème SSL, propager l'erreur
          rethrow;
        }
      }

      // 2. Fallback vers la méthode alternative
      return await createAdminCompagnieAlternative(
        prenom: prenom,
        nom: nom,
        telephone: telephone,
        compagnieId: compagnieId,
        compagnieNom: compagnieNom,
      );

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ❌ Erreur création hybride: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de la création hybride',
      };
    }
  }

  /// 🔧 Méthode alternative pour créer admin compagnie (contournement SSL)
  static Future<Map<String, dynamic>> createAdminCompagnieAlternative({
    required String prenom,
    required String nom,
    required String telephone,
    required String compagnieId,
    required String compagnieNom,
  }) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🔧 Création alternative admin compagnie');

      // 1. Générer l'email et le mot de passe
      final email = await _generateEmail(prenom, nom, compagnieNom);
      final password = generateSecurePassword();

      // 2. Créer directement le document Firestore avec un UID généré
      final userId = _firestore.collection('users').doc().id; // Générer un UID unique

      debugPrint('[ADMIN_COMPAGNIE_SERVICE] 🆔 UID généré: $userId');

      // 3. Créer le document utilisateur
      final userData = {
        'uid': userId,
        'email': email,
        'prenom': prenom,
        'nom': nom,
        'displayName': '$prenom $nom',
        'telephone': telephone,
        'role': 'admin_compagnie',
        'status': 'actif',
        'isActive': true,
        'isLegitimate': true,
        'compagnieId': compagnieId,
        'compagnieNom': compagnieNom,
        'firebaseAuthCreated': false, // Sera créé plus tard
        'needsFirebaseAuthCreation': true, // Flag pour création ultérieure
        'permissions': [
          'manage_company_data',
          'view_company_stats',
          'manage_company_agents',
          'view_company_reports',
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'super_admin',
        'password': password,
        'requirePasswordChange': false,
        'emailSent': false,
        'emailSentAt': null,
        'emailError': null,
        'creationMethod': 'alternative', // Marquer comme création alternative
      };

      await _firestore.collection('users').doc(userId).set(userData);
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ✅ Document Firestore créé (méthode alternative)');

      // 4. Mettre à jour la compagnie
      await _firestore.collection('compagnies').doc(compagnieId).update({
        'adminCompagnieId': userId,
        'adminCompagnieNom': '$prenom $nom',
        'adminCompagnieEmail': email,
        'adminAssignedAt': FieldValue.serverTimestamp(),
        'isAvailable': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ✅ Compagnie mise à jour');

      return {
        'success': true,
        'message': 'Admin compagnie créé avec succès (méthode alternative)',
        'adminId': userId,
        'password': password,
        'email': email,
        'compagnieId': compagnieId,
        'compagnieNom': compagnieNom,
        'note': 'Le compte Firebase Auth sera créé lors de la première connexion',
      };

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_SERVICE] ❌ Erreur création alternative: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de la création alternative',
      };
    }
  }
}
