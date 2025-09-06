import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 👤 Service pour récupérer les informations du profil utilisateur
class UserProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 📋 Récupérer les informations complètes de l'utilisateur connecté
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // 1. Essayer dans la collection 'users'
      var userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        return {
          'uid': user.uid,
          'email': user.email ?? data['email'] ?? '',
          'nom': data['nom'] ?? data['lastName'] ?? '',
          'prenom': data['prenom'] ?? data['firstName'] ?? '',
          'telephone': data['telephone'] ?? data['phone'] ?? '',
          'cin': data['cin'] ?? '',
          'adresse': data['adresse'] ?? data['address'] ?? '',
          'source': 'users_collection',
        };
      }

      // 2. Essayer dans la collection 'conducteurs'
      userDoc = await _firestore.collection('conducteurs').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        return {
          'uid': user.uid,
          'email': user.email ?? data['email'] ?? '',
          'nom': data['nom'] ?? data['lastName'] ?? '',
          'prenom': data['prenom'] ?? data['firstName'] ?? '',
          'telephone': data['telephone'] ?? data['phone'] ?? '',
          'cin': data['cin'] ?? '',
          'adresse': data['adresse'] ?? data['address'] ?? '',
          'source': 'conducteurs_collection',
        };
      }

      // 3. Essayer par email dans 'conducteurs'
      if (user.email != null) {
        final query = await _firestore
            .collection('conducteurs')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final data = query.docs.first.data();
          return {
            'uid': user.uid,
            'email': user.email ?? data['email'] ?? '',
            'nom': data['nom'] ?? data['lastName'] ?? '',
            'prenom': data['prenom'] ?? data['firstName'] ?? '',
            'telephone': data['telephone'] ?? data['phone'] ?? '',
            'cin': data['cin'] ?? '',
            'adresse': data['adresse'] ?? data['address'] ?? '',
            'source': 'conducteurs_by_email',
          };
        }
      }

      // 4. Essayer dans SharedPreferences
      final localData = await _getLocalUserData(user.uid);
      if (localData != null) {
        return localData;
      }

      // 5. Créer un profil basique
      return _createBasicProfile(user);

    } catch (e) {
      print('❌ Erreur récupération profil utilisateur: $e');
      return null;
    }
  }

  /// 📱 Récupérer les données locales
  static Future<Map<String, dynamic>?> _getLocalUserData(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Essayer avec l'UID spécifique
      final userKey = 'conducteur_$uid';
      String? dataString = prefs.getString(userKey);
      
      if (dataString != null) {
        final userData = json.decode(dataString) as Map<String, dynamic>;
        return {
          'uid': uid,
          'email': userData['email'] ?? '',
          'nom': userData['nom'] ?? '',
          'prenom': userData['prenom'] ?? '',
          'telephone': userData['telephone'] ?? '',
          'cin': userData['cin'] ?? '',
          'adresse': userData['adresse'] ?? '',
          'source': 'local_storage',
        };
      }

      // Essayer de trouver par email
      final user = _auth.currentUser;
      if (user?.email != null) {
        final keys = prefs.getKeys().where((k) => k.startsWith('conducteur_')).toList();
        
        for (final key in keys) {
          dataString = prefs.getString(key);
          if (dataString != null) {
            final userData = json.decode(dataString) as Map<String, dynamic>;
            if (userData['email'] == user!.email) {
              return {
                'uid': uid,
                'email': userData['email'] ?? '',
                'nom': userData['nom'] ?? '',
                'prenom': userData['prenom'] ?? '',
                'telephone': userData['telephone'] ?? '',
                'cin': userData['cin'] ?? '',
                'adresse': userData['adresse'] ?? '',
                'source': 'local_storage_by_email',
              };
            }
          }
        }
      }

      return null;
    } catch (e) {
      print('❌ Erreur récupération données locales: $e');
      return null;
    }
  }

  /// 🆕 Créer un profil basique
  static Map<String, dynamic> _createBasicProfile(User user) {
    return {
      'uid': user.uid,
      'email': user.email ?? '',
      'nom': 'Conducteur',
      'prenom': user.displayName ?? 'Utilisateur',
      'telephone': '+216 XX XXX XXX',
      'cin': '',
      'adresse': '',
      'source': 'basic_profile',
    };
  }

  /// 💾 Sauvegarder le profil localement
  static Future<void> saveProfileLocally(Map<String, dynamic> profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = 'conducteur_${profile['uid']}';
      await prefs.setString(userKey, json.encode(profile));
      print('✅ Profil sauvegardé localement');
    } catch (e) {
      print('❌ Erreur sauvegarde profil local: $e');
    }
  }

  /// 🔄 Mettre à jour le profil utilisateur
  static Future<bool> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Mettre à jour dans Firestore
      await _firestore.collection('users').doc(user.uid).set(updates, SetOptions(merge: true));
      
      // Mettre à jour localement
      final currentProfile = await getCurrentUserProfile();
      if (currentProfile != null) {
        final updatedProfile = {...currentProfile, ...updates};
        await saveProfileLocally(updatedProfile);
      }

      return true;
    } catch (e) {
      print('❌ Erreur mise à jour profil: $e');
      return false;
    }
  }

  /// 📧 Récupérer l'email de l'utilisateur
  static String getCurrentUserEmail() {
    final user = _auth.currentUser;
    return user?.email ?? '';
  }

  /// 👤 Récupérer le nom complet de l'utilisateur
  static Future<String> getCurrentUserFullName() async {
    final profile = await getCurrentUserProfile();
    if (profile != null) {
      final prenom = profile['prenom'] ?? '';
      final nom = profile['nom'] ?? '';
      return '$prenom $nom'.trim();
    }
    return 'Utilisateur';
  }

  /// 📞 Récupérer le téléphone de l'utilisateur
  static Future<String> getCurrentUserPhone() async {
    final profile = await getCurrentUserProfile();
    return profile?['telephone'] ?? '+216 XX XXX XXX';
  }

  /// 🆔 Récupérer l'UID de l'utilisateur
  static String getCurrentUserId() {
    final user = _auth.currentUser;
    return user?.uid ?? '';
  }

  /// ✅ Vérifier si l'utilisateur est connecté
  static bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  /// 🔍 Rechercher un utilisateur par email
  static Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    try {
      // Chercher dans 'users'
      var query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.data();
      }

      // Chercher dans 'conducteurs'
      query = await _firestore
          .collection('conducteurs')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.data();
      }

      return null;
    } catch (e) {
      print('❌ Erreur recherche utilisateur par email: $e');
      return null;
    }
  }
}
