import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 🚗 Service de contournement pour les conducteurs
/// Solution définitive qui contourne le bug PigeonUserDetails
class ConducteurWorkaroundService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 📝 Inscription avec contournement du bug Firebase
  static Future<Map<String, dynamic>> inscrireConducteur({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String telephone,
    required String cin,
    String adresse = '',
  }) async {
    try {
      print('[CONDUCTEUR_WORKAROUND] 🚀 Début inscription...');
      print('[CONDUCTEUR_WORKAROUND] 📧 Email: $email');

      User? user;
      String? uid;

      try {
        // Tentative de création normale
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = userCredential.user;
        uid = user?.uid;
        print('[CONDUCTEUR_WORKAROUND] ✅ Création normale réussie: $uid');
      } catch (e) {
        print('[CONDUCTEUR_WORKAROUND] ⚠️ Création normale échouée: $e');
        
        // Si erreur PigeonUserDetails, essayer de récupérer l'utilisateur actuel
        if (e.toString().contains('PigeonUserDetails')) {
          print('[CONDUCTEUR_WORKAROUND] 🔧 Bug PigeonUserDetails détecté, contournement...');
          
          // Attendre un peu pour que Firebase se stabilise
          await Future.delayed(const Duration(milliseconds: 1000));
          
          // Essayer de récupérer l'utilisateur actuel
          user = _auth.currentUser;
          uid = user?.uid;
          
          if (user != null) {
            print('[CONDUCTEUR_WORKAROUND] ✅ Utilisateur récupéré via contournement: $uid');
          } else {
            // Dernière tentative : essayer de se connecter avec les identifiants
            try {
              final loginCredential = await _auth.signInWithEmailAndPassword(
                email: email,
                password: password,
              );
              user = loginCredential.user;
              uid = user?.uid;
              print('[CONDUCTEUR_WORKAROUND] ✅ Utilisateur récupéré via connexion: $uid');
            } catch (loginError) {
              print('[CONDUCTEUR_WORKAROUND] ❌ Échec connexion: $loginError');
              throw Exception('Impossible de créer ou récupérer le compte');
            }
          }
        } else {
          // Autre erreur, la relancer
          rethrow;
        }
      }

      if (user == null || uid == null) {
        throw Exception('Utilisateur non créé ou récupéré');
      }

      print('[CONDUCTEUR_WORKAROUND] 👤 Utilisateur final: $uid');

      // Mettre à jour le profil (avec gestion d'erreur)
      try {
        await user.updateDisplayName('$prenom $nom');
        print('[CONDUCTEUR_WORKAROUND] ✅ Profil mis à jour');
      } catch (profileError) {
        print('[CONDUCTEUR_WORKAROUND] ⚠️ Erreur mise à jour profil: $profileError');
        // Continuer même si la mise à jour du profil échoue
      }

      // Sauvegarder les données localement
      final prefs = await SharedPreferences.getInstance();
      final userData = {
        'uid': uid,
        'email': email,
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'cin': cin,
        'adresse': adresse,
        'userType': 'conducteur',
        'createdAt': DateTime.now().toIso8601String(),
        'method': 'workaround',
      };

      await prefs.setString('conducteur_$uid', json.encode(userData));
      print('[CONDUCTEUR_WORKAROUND] ✅ Données sauvegardées localement');

      // Déconnecter pour forcer une nouvelle connexion
      try {
        await _auth.signOut();
        print('[CONDUCTEUR_WORKAROUND] ✅ Déconnexion réussie');
      } catch (signOutError) {
        print('[CONDUCTEUR_WORKAROUND] ⚠️ Erreur déconnexion: $signOutError');
        // Continuer même si la déconnexion échoue
      }

      return {
        'success': true,
        'uid': uid,
        'message': 'Inscription réussie ! Vous pouvez maintenant vous connecter.',
      };

    } on FirebaseAuthException catch (e) {
      print('[CONDUCTEUR_WORKAROUND] ❌ Erreur Firebase Auth: ${e.code}');
      
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Cet email est déjà utilisé';
          break;
        case 'weak-password':
          errorMessage = 'Mot de passe trop faible (minimum 6 caractères)';
          break;
        case 'invalid-email':
          errorMessage = 'Format d\'email invalide';
          break;
        default:
          errorMessage = 'Erreur d\'inscription: ${e.message}';
      }

      return {
        'success': false,
        'error': errorMessage,
      };

    } catch (e) {
      print('[CONDUCTEUR_WORKAROUND] ❌ Erreur générale: $e');
      return {
        'success': false,
        'error': 'Erreur inattendue: $e',
      };
    }
  }

  /// 🔐 Connexion avec contournement
  static Future<Map<String, dynamic>> connecterConducteur({
    required String email,
    required String password,
  }) async {
    try {
      print('[CONDUCTEUR_WORKAROUND] 🔐 Connexion: $email');

      User? user;
      String? uid;

      try {
        // Tentative de connexion normale
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = userCredential.user;
        uid = user?.uid;
        print('[CONDUCTEUR_WORKAROUND] ✅ Connexion normale réussie: $uid');
      } catch (e) {
        print('[CONDUCTEUR_WORKAROUND] ⚠️ Connexion normale échouée: $e');

        // Si erreur PigeonUserDetails, essayer de récupérer l'utilisateur actuel
        if (e.toString().contains('PigeonUserDetails')) {
          print('[CONDUCTEUR_WORKAROUND] 🔧 Bug PigeonUserDetails détecté lors de la connexion, contournement...');

          // Attendre un peu pour que Firebase se stabilise
          await Future.delayed(const Duration(milliseconds: 1000));

          // Essayer de récupérer l'utilisateur actuel
          user = _auth.currentUser;
          uid = user?.uid;

          if (user != null && user.email == email) {
            print('[CONDUCTEUR_WORKAROUND] ✅ Utilisateur récupéré via contournement: $uid');
          } else {
            print('[CONDUCTEUR_WORKAROUND] ❌ Utilisateur actuel ne correspond pas ou absent');
            return {
              'success': false,
              'error': 'Impossible de se connecter. Veuillez réessayer.',
            };
          }
        } else {
          // Autre erreur, la relancer
          rethrow;
        }
      }

      if (user == null || uid == null) {
        return {
          'success': false,
          'error': 'Erreur de connexion',
        };
      }

      print('[CONDUCTEUR_WORKAROUND] ✅ Connexion finale réussie: $uid');

      // Récupérer les données locales
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString('conducteur_${user.uid}');
      
      Map<String, dynamic> userData;
      
      if (dataString != null) {
        userData = json.decode(dataString);
        print('[CONDUCTEUR_WORKAROUND] ✅ Données locales trouvées');
      } else {
        // Créer un profil basique
        userData = {
          'uid': user.uid,
          'email': user.email ?? email,
          'nom': '',
          'prenom': user.displayName ?? 'Conducteur',
          'telephone': '',
          'cin': '',
          'adresse': '',
          'userType': 'conducteur',
          'createdAt': DateTime.now().toIso8601String(),
          'method': 'basic',
        };
        
        await prefs.setString('conducteur_${user.uid}', json.encode(userData));
        print('[CONDUCTEUR_WORKAROUND] ✅ Profil basique créé');
      }

      return {
        'success': true,
        'user': user,
        'userData': userData,
        'role': 'conducteur',
      };

    } on FirebaseAuthException catch (e) {
      print('[CONDUCTEUR_WORKAROUND] ❌ Erreur connexion: ${e.code}');
      
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Aucun utilisateur trouvé avec cet email';
          break;
        case 'wrong-password':
          errorMessage = 'Mot de passe incorrect';
          break;
        case 'invalid-email':
          errorMessage = 'Format d\'email invalide';
          break;
        default:
          errorMessage = 'Erreur de connexion: ${e.message}';
      }

      return {
        'success': false,
        'error': errorMessage,
      };

    } catch (e) {
      print('[CONDUCTEUR_WORKAROUND] ❌ Erreur: $e');
      return {
        'success': false,
        'error': 'Erreur de connexion: $e',
      };
    }
  }

  /// 🚪 Déconnexion
  static Future<void> deconnecter() async {
    try {
      await _auth.signOut();
      print('[CONDUCTEUR_WORKAROUND] ✅ Déconnexion réussie');
    } catch (e) {
      print('[CONDUCTEUR_WORKAROUND] ⚠️ Erreur déconnexion: $e');
    }
  }

  /// 👤 Obtenir l'utilisateur actuel
  static User? obtenirUtilisateurActuel() {
    return _auth.currentUser;
  }

  /// 🔐 Connexion alternative sans Firebase Auth (mode offline)
  static Future<Map<String, dynamic>> connecterConducteurOffline({
    required String email,
    required String password,
  }) async {
    try {
      print('[CONDUCTEUR_WORKAROUND] 🔐 Connexion offline: $email');

      // Rechercher dans les données locales
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('conducteur_'));

      for (final key in keys) {
        final dataString = prefs.getString(key);
        if (dataString != null) {
          final userData = json.decode(dataString) as Map<String, dynamic>;

          if (userData['email'] == email) {
            print('[CONDUCTEUR_WORKAROUND] ✅ Utilisateur trouvé localement: ${userData['uid']}');

            // Créer un utilisateur fictif pour la compatibilité
            return {
              'success': true,
              'user': null, // Pas d'objet User Firebase
              'userData': userData,
              'role': 'conducteur',
              'mode': 'offline',
            };
          }
        }
      }

      return {
        'success': false,
        'error': 'Aucun compte trouvé avec cet email',
      };

    } catch (e) {
      print('[CONDUCTEUR_WORKAROUND] ❌ Erreur connexion offline: $e');
      return {
        'success': false,
        'error': 'Erreur de connexion offline: $e',
      };
    }
  }

  /// 🔐 Connexion hybride (essaie Firebase puis offline)
  static Future<Map<String, dynamic>> connecterConducteurHybride({
    required String email,
    required String password,
  }) async {
    try {
      print('[CONDUCTEUR_WORKAROUND] 🔄 Tentative connexion hybride...');

      // Essayer d'abord la connexion normale
      final result = await connecterConducteur(
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        print('[CONDUCTEUR_WORKAROUND] ✅ Connexion Firebase réussie');
        return result;
      }

      print('[CONDUCTEUR_WORKAROUND] ⚠️ Connexion Firebase échouée, essai offline...');

      // Si échec, essayer la connexion offline
      final offlineResult = await connecterConducteurOffline(
        email: email,
        password: password,
      );

      if (offlineResult['success'] == true) {
        print('[CONDUCTEUR_WORKAROUND] ✅ Connexion offline réussie');
        return offlineResult;
      }

      // Si les deux échouent, retourner l'erreur Firebase
      return result;

    } catch (e) {
      print('[CONDUCTEUR_WORKAROUND] ❌ Erreur connexion hybride: $e');
      return {
        'success': false,
        'error': 'Erreur de connexion: $e',
      };
    }
  }
}
