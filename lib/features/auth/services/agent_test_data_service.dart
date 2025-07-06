import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// 🧪 Service pour créer les données de test pour l'agent
class AgentTestDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🏗️ Créer toutes les données de test nécessaires pour l'agent
  static Future<void> createAgentTestData() async {
    try {
      debugPrint('[AgentTestData] 🏗️ Début création données de test...');

      // 1. Créer le compte Firebase Auth pour l'agent
      await _createAgentAuthAccount();

      // 2. Créer la compagnie d'assurance
      await _createInsuranceCompany();

      // 3. Créer l'agence
      await _createAgency();

      // 4. Créer le profil assureur
      await _createAgentProfile();

      // 5. Créer le document users
      await _createUserDocument();

      debugPrint('[AgentTestData] ✅ Toutes les données de test créées avec succès');
    } catch (e) {
      debugPrint('[AgentTestData] ❌ Erreur création données: $e');
      rethrow;
    }
  }

  /// 👤 Créer le compte Firebase Auth
  static Future<void> _createAgentAuthAccount() async {
    try {
      debugPrint('[AgentTestData] 👤 Création compte Firebase Auth...');

      // Utiliser un email de test unique avec timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final testEmail = 'agent.test.$timestamp@constat-tunisie.app';
      const testPassword = 'TestAgent123!';

      debugPrint('[AgentTestData] 📧 Email de test: $testEmail');

      // Vérifier si déjà connecté avec un compte de test
      final existingUser = _auth.currentUser;
      if (existingUser?.email?.contains('agent.test') == true) {
        debugPrint('[AgentTestData] ✅ Compte de test déjà connecté');
        _testEmail = existingUser!.email!;
        _testPassword = testPassword;
        return;
      }

      // Déconnexion préventive
      await _auth.signOut();

      try {
        // Créer le nouveau compte de test
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );

        debugPrint('[AgentTestData] ✅ Compte Firebase créé: ${userCredential.user?.uid}');

        // Stocker les identifiants pour la connexion
        _testEmail = testEmail;
        _testPassword = testPassword;

      } catch (createError) {
        debugPrint('[AgentTestData] ⚠️ Erreur création (probablement type casting): $createError');

        // Vérifier si l'utilisateur a été créé malgré l'erreur
        await Future.delayed(const Duration(seconds: 2));
        final currentUser = _auth.currentUser;

        if (currentUser != null && currentUser.email == testEmail) {
          debugPrint('[AgentTestData] ✅ Compte créé malgré erreur de type casting');
          _testEmail = testEmail;
          _testPassword = testPassword;
        } else {
          // Essayer avec un compte existant connu
          debugPrint('[AgentTestData] 🔄 Tentative avec compte existant...');
          try {
            await _auth.signInWithEmailAndPassword(
              email: 'hammami123rahma@gmail.com',
              password: 'Acheya123',
            );
            _testEmail = 'hammami123rahma@gmail.com';
            _testPassword = 'Acheya123';
            debugPrint('[AgentTestData] ✅ Connexion compte existant réussie');
          } catch (signInError) {
            debugPrint('[AgentTestData] ❌ Échec connexion compte existant: $signInError');
            // Utiliser des identifiants par défaut
            _testEmail = 'hammami123rahma@gmail.com';
            _testPassword = 'Acheya123';
            debugPrint('[AgentTestData] ⚠️ Utilisation identifiants par défaut');
          }
        }
      }

    } catch (e) {
      debugPrint('[AgentTestData] ❌ Erreur création compte: $e');
      // En cas d'erreur, utiliser des identifiants par défaut
      _testEmail = 'hammami123rahma@gmail.com';
      _testPassword = 'Acheya123';
      debugPrint('[AgentTestData] ⚠️ Fallback vers identifiants par défaut');
    }
  }

  // Variables statiques pour stocker les identifiants de test
  static String? _testEmail;
  static String? _testPassword;

  /// 📋 Récupérer les identifiants de test créés
  static Map<String, String>? getTestCredentials() {
    if (_testEmail != null && _testPassword != null) {
      return {
        'email': _testEmail!,
        'password': _testPassword!,
      };
    }
    return null;
  }

  /// 🏢 Créer la compagnie d'assurance
  static Future<void> _createInsuranceCompany() async {
    try {
      debugPrint('[AgentTestData] 🏢 Création compagnie STAR...');

      await _firestore.collection('insurance_companies').doc('star').set({
        'nom': 'STAR Assurances',
        'code': 'STAR',
        'statut': 'active',
        'adresse': 'Avenue Habib Bourguiba, Tunis',
        'telephone': '+216 71 123 456',
        'email': 'contact@star.tn',
        'site_web': 'www.star.com.tn',
        'logo_url': 'https://example.com/star-logo.png',
        'date_creation': DateTime(2020, 1, 1),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[AgentTestData] ✅ Compagnie STAR créée');
    } catch (e) {
      debugPrint('[AgentTestData] ❌ Erreur création compagnie: $e');
      rethrow;
    }
  }

  /// 🏪 Créer l'agence
  static Future<void> _createAgency() async {
    try {
      debugPrint('[AgentTestData] 🏪 Création agence STAR Tunis...');

      await _firestore.collection('agences').doc('star_tunis_01').set({
        'nom': 'STAR Tunis Centre',
        'compagnie': 'STAR',
        'gouvernorat': 'Tunis',
        'ville': 'Tunis',
        'adresse': 'Avenue Habib Bourguiba, Tunis 1000',
        'telephone': '+216 71 234 567',
        'email': 'tunis@star.tn',
        'responsable': 'Ahmed Ben Ali',
        'nombreAgents': 5,
        'statut': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[AgentTestData] ✅ Agence STAR Tunis créée');
    } catch (e) {
      debugPrint('[AgentTestData] ❌ Erreur création agence: $e');
      rethrow;
    }
  }

  /// 👨‍💼 Créer le profil assureur
  static Future<void> _createAgentProfile() async {
    try {
      debugPrint('[AgentTestData] 👨‍💼 Création profil assureur...');

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      final userEmail = user.email ?? _testEmail ?? 'agent.test@constat-tunisie.app';

      await _firestore.collection('assureurs').doc(user.uid).set({
        'email': userEmail,
        'nom': 'Agent',
        'prenom': 'Test',
        'telephone': '+216 20 123 456',
        'compagnie': 'STAR',
        'matricule': 'STAR001',
        'agence': 'star_tunis_01',
        'agenceNom': 'STAR Tunis Centre',
        'gouvernorat': 'Tunis',
        'poste': 'Agent Commercial',
        'permissions': ['view_contracts', 'create_contracts', 'manage_clients'],
        'dossierIds': [],
        'date_embauche': Timestamp.fromDate(DateTime(2024, 1, 15)),
        'statut': 'actif',
        'adresse': 'Tunis, Tunisie',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'derniere_connexion': null,
      });

      debugPrint('[AgentTestData] ✅ Profil assureur créé pour: $userEmail');
    } catch (e) {
      debugPrint('[AgentTestData] ❌ Erreur création profil: $e');
      rethrow;
    }
  }

  /// 📄 Créer le document users
  static Future<void> _createUserDocument() async {
    try {
      debugPrint('[AgentTestData] 📄 Création document users...');

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      final userEmail = user.email ?? _testEmail ?? 'agent.test@constat-tunisie.app';

      await _firestore.collection('users').doc(user.uid).set({
        'email': userEmail,
        'userType': 'assureur',
        'accountStatus': 'active',
        'nom': 'Agent',
        'prenom': 'Test',
        'telephone': '+216 20 123 456',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[AgentTestData] ✅ Document users créé pour: $userEmail');
    } catch (e) {
      debugPrint('[AgentTestData] ❌ Erreur création document users: $e');
      rethrow;
    }
  }

  /// 🧹 Nettoyer les données de test
  static Future<void> cleanupTestData() async {
    try {
      debugPrint('[AgentTestData] 🧹 Nettoyage données de test...');

      final user = _auth.currentUser;
      if (user != null) {
        // Supprimer les documents Firestore
        await _firestore.collection('assureurs').doc(user.uid).delete();
        await _firestore.collection('users').doc(user.uid).delete();
        
        // Supprimer le compte Firebase Auth
        await user.delete();
      }

      // Supprimer les données partagées
      await _firestore.collection('agences').doc('star_tunis_01').delete();
      await _firestore.collection('insurance_companies').doc('star').delete();

      debugPrint('[AgentTestData] ✅ Nettoyage terminé');
    } catch (e) {
      debugPrint('[AgentTestData] ❌ Erreur nettoyage: $e');
      rethrow;
    }
  }

  /// ✅ Vérifier si les données de test existent
  static Future<bool> checkTestDataExists() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final assureurDoc = await _firestore.collection('assureurs').doc(user.uid).get();
      final companyDoc = await _firestore.collection('insurance_companies').doc('star').get();
      final agencyDoc = await _firestore.collection('agences').doc('star_tunis_01').get();

      return assureurDoc.exists && companyDoc.exists && agencyDoc.exists;
    } catch (e) {
      debugPrint('[AgentTestData] ❌ Erreur vérification: $e');
      return false;
    }
  }
}
