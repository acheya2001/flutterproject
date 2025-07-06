import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../models/conducteur_model.dart';
import '../models/assureur_model.dart';
import '../models/expert_model.dart';
import '../../admin/models/admin_model.dart';
import '../../../utils/user_type.dart';
import 'universal_auth_service.dart';

/// 🧹 Service d'authentification propre - Remplace l'ancien AuthService
class CleanAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔐 Connexion avec email et mot de passe
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[CleanAuthService] Connexion: $email');
      
      // Utiliser le service universel
      final result = await UniversalAuthService.signIn(email, password);
      
      if (result['success'] != true) {
        debugPrint('[CleanAuthService] Échec: ${result['error']}');
        return null;
      }
      
      // Convertir en UserModel
      return await _convertToUserModel(result);
      
    } catch (e) {
      debugPrint('[CleanAuthService] Erreur: $e');
      return null;
    }
  }

  /// 📝 Inscription avec email et mot de passe
  Future<UserModel?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String telephone,
    String? adresse,
    UserType userType = UserType.conducteur,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      debugPrint('[CleanAuthService] Inscription: $email ($userType)');
      
      // Utiliser le service universel
      final result = await UniversalAuthService.signUp(
        email: email,
        password: password,
        nom: nom,
        prenom: prenom,
        userType: userType.toString().split('.').last,
        additionalData: {
          'telephone': telephone,
          'adresse': adresse,
          ...?additionalData,
        },
      );
      
      if (result['success'] != true) {
        debugPrint('[CleanAuthService] Échec inscription: ${result['error']}');
        return null;
      }
      
      // Convertir en UserModel
      return await _convertToUserModel(result);
      
    } catch (e) {
      debugPrint('[CleanAuthService] Erreur inscription: $e');
      return null;
    }
  }

  /// 👤 Obtenir l'utilisateur actuel
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('[CleanAuthService] Aucun utilisateur connecté');
        return null;
      }

      debugPrint('[CleanAuthService] Récupération utilisateur: ${user.uid}');
      
      // Utiliser le service universel pour récupérer les données
      final result = await UniversalAuthService.signIn(user.email!, 'dummy');
      
      if (result['success'] == true) {
        return await _convertToUserModel(result);
      }
      
      // Si échec, créer un UserModel basique
      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        nom: 'Utilisateur',
        prenom: 'Firebase',
        telephone: '',
        userType: UserType.conducteur,
        dateCreation: DateTime.now(),
      );
      
    } catch (e) {
      debugPrint('[CleanAuthService] Erreur getCurrentUser: $e');
      return null;
    }
  }

  /// 🚪 Déconnexion
  Future<void> signOut() async {
    try {
      await UniversalAuthService.signOut();
      debugPrint('[CleanAuthService] Déconnexion réussie');
    } catch (e) {
      debugPrint('[CleanAuthService] Erreur déconnexion: $e');
    }
  }

  /// 📊 Vérifier si connecté
  bool isUserLoggedIn() {
    return UniversalAuthService.isLoggedIn;
  }

  /// 👤 Utilisateur Firebase actuel
  User? get currentFirebaseUser => UniversalAuthService.currentUser;

  /// 🔄 Convertir le résultat universel en UserModel
  Future<UserModel?> _convertToUserModel(Map<String, dynamic> result) async {
    try {
      final userType = result['userType'] as String;
      final userData = result['userData'] as Map<String, dynamic>? ?? result;
      
      debugPrint('[CleanAuthService] Conversion: $userType');

      // Ajouter les champs manquants avec gestion sécurisée des dates
      final completeData = {
        'uid': result['uid'],
        'email': result['email'],
        'nom': result['nom'] ?? 'Utilisateur',
        'prenom': result['prenom'] ?? 'Firebase',
        'telephone': userData['telephone'] ?? '',
        'adresse': userData['adresse'],
        'dateCreation': _safeTimestamp(userData['createdAt']),
        'dateModification': _safeTimestamp(userData['updatedAt']),
        'type': userType,
        ...userData,
      };

      // Convertir selon le type
      switch (userType) {
        case 'conducteur':
          return ConducteurModel.fromMap(completeData);
        
        case 'assureur':
          return AssureurModel.fromMap(completeData);
        
        case 'expert':
          return ExpertModel.fromMap(completeData);
        
        case 'admin':
          return AdminModel.fromMap(completeData);
        
        default:
          // Convertir le type string en UserType enum
          final userTypeEnum = UserType.values.firstWhere(
            (type) => type.toString().split('.').last == userType,
            orElse: () => UserType.conducteur,
          );
          
          return UserModel(
            uid: completeData['uid'] as String,
            email: completeData['email'] as String,
            nom: completeData['nom'] as String,
            prenom: completeData['prenom'] as String,
            telephone: completeData['telephone'] as String,
            userType: userTypeEnum,
            adresse: completeData['adresse'] as String?,
            dateCreation: (completeData['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
            dateModification: (completeData['dateModification'] as Timestamp?)?.toDate(),
          );
      }
    } catch (e) {
      debugPrint('[CleanAuthService] Erreur conversion: $e');
      return null;
    }
  }

  /// 🔍 Rechercher un utilisateur par email
  Future<UserModel?> findUserByEmail(String email) async {
    try {
      debugPrint('[CleanAuthService] Recherche utilisateur: $email');
      
      // Rechercher dans toutes les collections
      final collections = ['conducteurs', 'agents_assurance', 'experts', 'admins'];
      
      for (final collection in collections) {
        try {
          final query = await _firestore
              .collection(collection)
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
          
          if (query.docs.isNotEmpty) {
            final doc = query.docs.first;
            final data = doc.data();
            
            return await _convertToUserModel({
              'success': true,
              'uid': doc.id,
              'email': email,
              'userType': data['userType'] ?? _getTypeFromCollection(collection),
              'userData': data,
              ...data,
            });
          }
        } catch (e) {
          debugPrint('[CleanAuthService] Erreur recherche $collection: $e');
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('[CleanAuthService] Erreur findUserByEmail: $e');
      return null;
    }
  }

  /// 📂 Obtenir le type depuis le nom de collection
  String _getTypeFromCollection(String collection) {
    switch (collection) {
      case 'agents_assurance':
        return 'assureur';
      case 'experts':
        return 'expert';
      case 'admins':
        return 'admin';
      case 'conducteurs':
        return 'conducteur';
      default:
        return 'conducteur';
    }
  }

  /// 🧪 Méthodes de compatibilité (pour ne pas casser l'existant)

  // Alias pour compatibilité
  Future<UserModel?> signIn({required String email, required String password}) {
    return signInWithEmailAndPassword(email: email, password: password);
  }

  // Méthode d'inscription complète pour compatibilité
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
  }) {
    return createUserWithEmailAndPassword(
      email: email,
      password: password,
      nom: nom,
      prenom: prenom,
      telephone: telephone,
      adresse: adresse,
      userType: userType,
      additionalData: {
        if (cin != null) 'cin': cin,
        if (compagnie != null) 'compagnie': compagnie,
        if (matricule != null) 'matricule': matricule,
        if (cabinet != null) 'cabinet': cabinet,
        if (agrement != null) 'agrement': agrement,
      },
    );
  }

  // Alias pour compatibilité
  Future<UserModel?> register({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String telephone,
    String? adresse,
    UserType userType = UserType.conducteur,
  }) {
    return createUserWithEmailAndPassword(
      email: email,
      password: password,
      nom: nom,
      prenom: prenom,
      telephone: telephone,
      adresse: adresse,
      userType: userType,
    );
  }

  /// 🔄 Réinitialisation de mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('[CleanAuthService] Email de réinitialisation envoyé: $email');
    } catch (e) {
      debugPrint('[CleanAuthService] Erreur réinitialisation: $e');
      rethrow;
    }
  }

  /// 🛡️ Conversion sécurisée vers Timestamp
  Timestamp _safeTimestamp(dynamic value) {
    try {
      if (value == null) {
        return Timestamp.now();
      } else if (value is Timestamp) {
        return value;
      } else if (value is DateTime) {
        return Timestamp.fromDate(value);
      } else if (value is String) {
        final date = DateTime.tryParse(value);
        return date != null ? Timestamp.fromDate(date) : Timestamp.now();
      } else {
        // Pour FieldValue ou autres types non supportés
        return Timestamp.now();
      }
    } catch (e) {
      debugPrint('[CleanAuthService] Erreur conversion timestamp: $e');
      return Timestamp.now();
    }
  }
}
