import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// 🧪 Service pour créer des données de test pour les agents d'assurance
class AgentTestDataSimple {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 📝 Créer des agents de test dans la base de données
  static Future<void> createTestAgents() async {
    try {
      debugPrint('[AgentTestData] 🧪 Création des agents de test...');

      final testAgents = [
        {
          'email': 'agent@star.tn',
          'password': 'agent123',
          'nom': 'Ben Ali',
          'prenom': 'Ahmed',
          'telephone': '+216 20 123 456',
          'numeroAgent': 'STAR001',
          'compagnie': 'STAR Assurances',
          'agence': 'Agence Tunis Centre',
          'gouvernorat': 'Tunis',
          'poste': 'Agent Commercial',
        },
        {
          'email': 'agent@gat.tn',
          'password': 'agent123',
          'nom': 'Trabelsi',
          'prenom': 'Fatma',
          'telephone': '+216 22 234 567',
          'numeroAgent': 'GAT002',
          'compagnie': 'GAT Assurances',
          'agence': 'Agence Ariana',
          'gouvernorat': 'Ariana',
          'poste': 'Conseiller Clientèle',
        },
        {
          'email': 'agent@bh.tn',
          'password': 'agent123',
          'nom': 'Sassi',
          'prenom': 'Mohamed',
          'telephone': '+216 24 345 678',
          'numeroAgent': 'BH003',
          'compagnie': 'BH Assurances',
          'agence': 'Agence Sousse',
          'gouvernorat': 'Sousse',
          'poste': 'Chargé de Sinistres',
        },
        {
          'email': 'hammami123rahma@gmail.com',
          'password': 'Acheya123',
          'nom': 'Hammami',
          'prenom': 'Rahma',
          'telephone': '+216 26 456 789',
          'numeroAgent': 'STAR004',
          'compagnie': 'STAR Assurances',
          'agence': 'Agence Manouba',
          'gouvernorat': 'Manouba',
          'poste': 'Responsable Agence',
        },
      ];

      for (final agentData in testAgents) {
        await _createSingleTestAgent(agentData);
      }

      debugPrint('[AgentTestData] ✅ Tous les agents de test créés');

    } catch (e) {
      debugPrint('[AgentTestData] ❌ Erreur création agents test: $e');
    }
  }

  /// 👤 Créer un seul agent de test
  static Future<void> _createSingleTestAgent(Map<String, String> agentData) async {
    try {
      final email = agentData['email']!;
      debugPrint('[AgentTestData] 👤 Création agent: $email');

      // Vérifier si l'agent existe déjà
      final existingDoc = await _firestore
          .collection('agents_assurance')
          .where('email', isEqualTo: email)
          .get();

      if (existingDoc.docs.isNotEmpty) {
        debugPrint('[AgentTestData] ⚠️ Agent existe déjà: $email');
        return;
      }

      // Créer le compte Firebase Auth
      UserCredential? userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: agentData['password']!,
        );
      } catch (authError) {
        if (authError.toString().contains('email-already-in-use')) {
          debugPrint('[AgentTestData] ⚠️ Email déjà utilisé, récupération UID...');
          
          // Essayer de se connecter pour récupérer l'UID
          try {
            userCredential = await _auth.signInWithEmailAndPassword(
              email: email,
              password: agentData['password']!,
            );
          } catch (signInError) {
            debugPrint('[AgentTestData] ❌ Impossible de récupérer UID: $signInError');
            return;
          }
        } else {
          debugPrint('[AgentTestData] ❌ Erreur création compte: $authError');
          return;
        }
      }

      if (userCredential?.user == null) {
        debugPrint('[AgentTestData] ❌ Pas d\'utilisateur créé');
        return;
      }

      final userId = userCredential!.user!.uid;
      final now = DateTime.now();

      // Créer le document utilisateur principal
      await _firestore.collection('users').doc(userId).set({
        'uid': userId,
        'email': email,
        'nom': agentData['nom'],
        'prenom': agentData['prenom'],
        'telephone': agentData['telephone'],
        'userType': 'assureur',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Créer le document agent d'assurance
      await _firestore.collection('agents_assurance').doc(userId).set({
        'uid': userId,
        'email': email,
        'nom': agentData['nom'],
        'prenom': agentData['prenom'],
        'telephone': agentData['telephone'],
        'numeroAgent': agentData['numeroAgent'],
        'compagnie': agentData['compagnie'],
        'agence': agentData['agence'],
        'gouvernorat': agentData['gouvernorat'],
        'poste': agentData['poste'],
        'isActive': true,
        'statut': 'actif',
        'dateEmbauche': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userType': 'assureur',
      });

      // Créer le document user_types
      await _firestore.collection('user_types').doc(userId).set({
        'userType': 'assureur',
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[AgentTestData] ✅ Agent créé: ${agentData['prenom']} ${agentData['nom']} ($email)');

    } catch (e) {
      debugPrint('[AgentTestData] ❌ Erreur création agent ${agentData['email']}: $e');
    }
  }

  /// 🗑️ Supprimer tous les agents de test
  static Future<void> deleteTestAgents() async {
    try {
      debugPrint('[AgentTestData] 🗑️ Suppression des agents de test...');

      final testEmails = [
        'agent@star.tn',
        'agent@gat.tn',
        'agent@bh.tn',
        'hammami123rahma@gmail.com',
      ];

      for (final email in testEmails) {
        await _deleteSingleTestAgent(email);
      }

      debugPrint('[AgentTestData] ✅ Tous les agents de test supprimés');

    } catch (e) {
      debugPrint('[AgentTestData] ❌ Erreur suppression agents test: $e');
    }
  }

  /// 🗑️ Supprimer un seul agent de test
  static Future<void> _deleteSingleTestAgent(String email) async {
    try {
      debugPrint('[AgentTestData] 🗑️ Suppression agent: $email');

      // Trouver l'agent dans Firestore
      final agentQuery = await _firestore
          .collection('agents_assurance')
          .where('email', isEqualTo: email)
          .get();

      if (agentQuery.docs.isEmpty) {
        debugPrint('[AgentTestData] ⚠️ Agent non trouvé: $email');
        return;
      }

      final agentDoc = agentQuery.docs.first;
      final userId = agentDoc.id;

      // Supprimer les documents Firestore
      await _firestore.collection('agents_assurance').doc(userId).delete();
      await _firestore.collection('users').doc(userId).delete();
      await _firestore.collection('user_types').doc(userId).delete();

      debugPrint('[AgentTestData] ✅ Agent supprimé: $email');

    } catch (e) {
      debugPrint('[AgentTestData] ❌ Erreur suppression agent $email: $e');
    }
  }

  /// 📊 Lister tous les agents de test
  static Future<void> listTestAgents() async {
    try {
      debugPrint('[AgentTestData] 📊 Liste des agents de test:');

      final snapshot = await _firestore.collection('agents_assurance').get();

      if (snapshot.docs.isEmpty) {
        debugPrint('[AgentTestData] ⚠️ Aucun agent trouvé');
        return;
      }

      for (final doc in snapshot.docs) {
        final data = doc.data();
        debugPrint('[AgentTestData] 👤 ${data['prenom']} ${data['nom']} (${data['email']}) - ${data['compagnie']}');
      }

      debugPrint('[AgentTestData] 📊 Total: ${snapshot.docs.length} agents');

    } catch (e) {
      debugPrint('[AgentTestData] ❌ Erreur liste agents: $e');
    }
  }

  /// 🧪 Tester la connexion d'un agent
  static Future<void> testAgentLogin(String email, String password) async {
    try {
      debugPrint('[AgentTestData] 🧪 Test connexion: $email');

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final agentDoc = await _firestore
            .collection('agents_assurance')
            .doc(userCredential.user!.uid)
            .get();

        if (agentDoc.exists) {
          final data = agentDoc.data()!;
          debugPrint('[AgentTestData] ✅ Connexion réussie: ${data['prenom']} ${data['nom']} - ${data['compagnie']}');
        } else {
          debugPrint('[AgentTestData] ❌ Document agent non trouvé');
        }
      } else {
        debugPrint('[AgentTestData] ❌ Connexion échouée');
      }

    } catch (e) {
      debugPrint('[AgentTestData] ❌ Erreur test connexion: $e');
    }
  }
}
