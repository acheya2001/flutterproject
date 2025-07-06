import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔧 Service de configuration Firebase pour réduire les warnings
class FirebaseConfigService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔧 Configurer Firebase pour réduire les warnings
  static Future<void> configureFirebase() async {
    try {
      debugPrint('[FirebaseConfig] 🔧 Configuration Firebase...');

      // Configurer les paramètres Firebase Auth pour réduire les warnings
      await _configureFirebaseAuth();
      
      // Configurer Firestore pour de meilleures performances
      await _configureFirestore();

      debugPrint('[FirebaseConfig] ✅ Configuration Firebase terminée');
    } catch (e) {
      debugPrint('[FirebaseConfig] ⚠️ Erreur configuration Firebase: $e');
    }
  }

  /// 🔐 Configurer Firebase Auth
  static Future<void> _configureFirebaseAuth() async {
    try {
      // Désactiver la persistance automatique pour éviter les conflits
      if (!kIsWeb) {
        await _auth.setPersistence(Persistence.LOCAL);
      }

      // Configurer les paramètres de langue
      _auth.setLanguageCode('fr');

      debugPrint('[FirebaseConfig] 🔐 Firebase Auth configuré');
    } catch (e) {
      debugPrint('[FirebaseConfig] ⚠️ Erreur config Auth: $e');
    }
  }

  /// 🗄️ Configurer Firestore
  static Future<void> _configureFirestore() async {
    try {
      // Activer la persistance hors ligne pour de meilleures performances
      if (!kIsWeb) {
        await _firestore.enablePersistence();
      }

      debugPrint('[FirebaseConfig] 🗄️ Firestore configuré');
    } catch (e) {
      // La persistance peut déjà être activée
      debugPrint('[FirebaseConfig] ℹ️ Persistance Firestore: $e');
    }
  }

  /// 🧹 Nettoyer la session Firebase
  static Future<void> cleanFirebaseSession() async {
    try {
      debugPrint('[FirebaseConfig] 🧹 Nettoyage session Firebase...');
      
      // Déconnexion propre
      await _auth.signOut();
      
      // Attendre que la déconnexion soit effective
      await Future.delayed(const Duration(milliseconds: 500));
      
      debugPrint('[FirebaseConfig] ✅ Session Firebase nettoyée');
    } catch (e) {
      debugPrint('[FirebaseConfig] ⚠️ Erreur nettoyage: $e');
    }
  }

  /// 🔍 Vérifier l'état de la connexion Firebase
  static Future<Map<String, dynamic>> checkFirebaseStatus() async {
    try {
      final user = _auth.currentUser;
      final isConnected = user != null;
      
      return {
        'connected': isConnected,
        'user': user?.email,
        'uid': user?.uid,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'connected': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 🚨 Connexion admin robuste avec gestion d'erreurs
  static Future<Map<String, dynamic>> robustAdminLogin({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[FirebaseConfig] 🚨 Connexion admin robuste: $email');

      // Nettoyer la session avant connexion
      await cleanFirebaseSession();

      // Tentative de connexion avec retry
      UserCredential? credential;
      int attempts = 0;
      const maxAttempts = 3;

      while (attempts < maxAttempts && credential == null) {
        attempts++;
        try {
          debugPrint('[FirebaseConfig] Tentative $attempts/$maxAttempts...');
          
          credential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          
          if (credential.user != null) {
            debugPrint('[FirebaseConfig] ✅ Connexion réussie');
            break;
          }
        } catch (e) {
          debugPrint('[FirebaseConfig] ❌ Tentative $attempts échouée: $e');
          
          if (attempts < maxAttempts) {
            await Future.delayed(Duration(seconds: attempts * 2));
          } else {
            rethrow;
          }
        }
      }

      if (credential?.user == null) {
        throw Exception('Impossible de se connecter après $maxAttempts tentatives');
      }

      return {
        'success': true,
        'user': credential!.user!.email,
        'uid': credential.user!.uid,
        'message': 'Connexion admin réussie',
      };

    } catch (e) {
      debugPrint('[FirebaseConfig] ❌ Erreur connexion admin: $e');
      
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Échec de la connexion admin',
      };
    }
  }

  /// 📊 Obtenir les informations de diagnostic Firebase
  static Map<String, dynamic> getDiagnosticInfo() {
    final user = _auth.currentUser;
    
    return {
      'firebase_auth': {
        'current_user': user?.email,
        'uid': user?.uid,
        'email_verified': user?.emailVerified,
        'creation_time': user?.metadata.creationTime?.toIso8601String(),
        'last_sign_in': user?.metadata.lastSignInTime?.toIso8601String(),
      },
      'app_info': {
        'platform': defaultTargetPlatform.toString(),
        'is_web': kIsWeb,
        'debug_mode': kDebugMode,
        'timestamp': DateTime.now().toIso8601String(),
      },
      'warnings_info': {
        'app_check': 'Non configuré (normal en développement)',
        'recaptcha': 'Non configuré (normal en développement)',
        'locale': 'Peut être null (normal)',
      },
    };
  }
}
