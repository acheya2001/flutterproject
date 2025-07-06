import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 🧪 Script pour créer des utilisateurs de test pour le système d'assurance
class TestUserSetup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 👨‍💼 Créer un agent d'assurance de test
  static Future<Map<String, dynamic>> createTestAgent() async {
    try {
      const email = 'agent.test@star.tn';
      const password = 'Test123456';

      // Vérifier si l'utilisateur existe déjà dans Firestore
      final existingQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      String userId;

      if (existingQuery.docs.isNotEmpty) {
        // Utilisateur existe déjà
        userId = existingQuery.docs.first.id;
        return {
          'success': true,
          'message': 'Agent existant trouvé: $userId',
          'email': email,
          'userId': userId,
          'existing': true,
        };
      }

      // Créer un ID unique pour éviter les conflits
      userId = _firestore.collection('users').doc().id;

      // Créer directement les documents Firestore sans Firebase Auth
      // (Firebase Auth peut causer des problèmes de sérialisation)

      // Créer les documents Firestore étape par étape
      final now = DateTime.now().toIso8601String(); // Utiliser string pour éviter les problèmes de sérialisation

      // 1. Document users
      await _firestore.collection('users').doc(userId).set({
        'email': email,
        'nom': 'Trabelsi',
        'prenom': 'Ahmed',
        'telephone': '+216 98 123 456',
        'adresse': 'Tunis, Tunisie',
        'createdAt': now,
        'updatedAt': now,
      });

      // 2. Document user_types
      await _firestore.collection('user_types').doc(userId).set({
        'type': 'assureur',
        'createdAt': now,
      });

      // 3. Document assureurs
      await _firestore.collection('assureurs').doc(userId).set({
        'compagnie': 'STAR Assurances',
        'agence': 'Tunis Centre',
        'matricule': 'AGT001',
        'zonesGeographiques': ['Tunis', 'Ariana', 'Manouba'],
        'specialites': ['Auto', 'Habitation'],
        'dateEmbauche': now,
        'status': 'actif',
        'createdAt': now,
        'updatedAt': now,
      });

      return {
        'success': true,
        'message': 'Agent de test créé avec succès',
        'email': email,
        'password': password,
        'userId': userId,
      };
    } catch (e, stackTrace) {
      print('❌ Erreur détaillée création agent: $e');
      print('📍 Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Erreur création agent: $e',
        'error': e.toString(),
        'stackTrace': stackTrace.toString(),
      };
    }
  }

  /// 🚗 Créer un conducteur de test
  static Future<Map<String, dynamic>> createTestConducteur() async {
    try {
      const email = 'conducteur.test@email.com';
      const password = 'Test123456';

      // Vérifier si l'utilisateur existe déjà dans Firestore
      final existingQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      String userId;

      if (existingQuery.docs.isNotEmpty) {
        // Utilisateur existe déjà
        userId = existingQuery.docs.first.id;
        return {
          'success': true,
          'message': 'Conducteur existant trouvé: $userId',
          'email': email,
          'userId': userId,
          'existing': true,
        };
      }

      // Créer un ID unique pour éviter les conflits
      userId = _firestore.collection('users').doc().id;

      // Créer les documents Firestore étape par étape
      final now = DateTime.now().toIso8601String();

      // 1. Document users
      await _firestore.collection('users').doc(userId).set({
        'email': email,
        'nom': 'Ben Ali',
        'prenom': 'Mohamed',
        'telephone': '+216 22 987 654',
        'adresse': 'Sfax, Tunisie',
        'createdAt': now,
        'updatedAt': now,
      });

      // 2. Document user_types
      await _firestore.collection('user_types').doc(userId).set({
        'type': 'conducteur',
        'createdAt': now,
      });

      // 3. Document conducteurs
      await _firestore.collection('conducteurs').doc(userId).set({
        'dateNaissance': '1990-05-15',
        'lieuNaissance': 'Sfax',
        'numeroPermis': 'P123456789',
        'dateObtentionPermis': '2010-03-20',
        'categoriePermis': ['B'],
        'profession': 'Ingénieur',
        'situationFamiliale': 'Marié',
        'nombreEnfants': 2,
        'createdAt': now,
        'updatedAt': now,
      });

      return {
        'success': true,
        'message': 'Conducteur de test créé avec succès',
        'email': email,
        'password': password,
        'userId': userId,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur création conducteur: $e',
      };
    }
  }

  /// 🔧 Vérifier si les utilisateurs de test existent
  static Future<Map<String, bool>> checkTestUsers() async {
    try {
      // Vérifier l'agent
      final agentQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: 'agent.test@star.tn')
          .limit(1)
          .get();

      // Vérifier le conducteur
      final conducteurQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: 'conducteur.test@email.com')
          .limit(1)
          .get();

      return {
        'agent': agentQuery.docs.isNotEmpty,
        'conducteur': conducteurQuery.docs.isNotEmpty,
      };
    } catch (e) {
      return {'agent': false, 'conducteur': false};
    }
  }

  /// 🗑️ Supprimer les utilisateurs de test
  static Future<Map<String, dynamic>> deleteTestUsers() async {
    try {
      int deletedCount = 0;

      // Supprimer l'agent
      final agentQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: 'agent.test@star.tn')
          .limit(1)
          .get();

      if (agentQuery.docs.isNotEmpty) {
        final agentId = agentQuery.docs.first.id;
        await _firestore.collection('users').doc(agentId).delete();
        await _firestore.collection('user_types').doc(agentId).delete();
        await _firestore.collection('assureurs').doc(agentId).delete();
        deletedCount++;
      }

      // Supprimer le conducteur
      final conducteurQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: 'conducteur.test@email.com')
          .limit(1)
          .get();

      if (conducteurQuery.docs.isNotEmpty) {
        final conducteurId = conducteurQuery.docs.first.id;
        await _firestore.collection('users').doc(conducteurId).delete();
        await _firestore.collection('user_types').doc(conducteurId).delete();
        await _firestore.collection('conducteurs').doc(conducteurId).delete();
        deletedCount++;
      }

      return {
        'success': true,
        'message': '$deletedCount utilisateurs supprimés',
        'deletedCount': deletedCount,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur suppression: $e',
      };
    }
  }
}

/// 🎯 Widget pour gérer les utilisateurs de test
class TestUserSetupWidget extends StatefulWidget {
  const TestUserSetupWidget({Key? key}) : super(key: key);

  @override
  State<TestUserSetupWidget> createState() => _TestUserSetupWidgetState();
}

class _TestUserSetupWidgetState extends State<TestUserSetupWidget> {
  bool _isLoading = false;
  String _result = '';
  Map<String, bool> _existingUsers = {};

  @override
  void initState() {
    super.initState();
    _checkExistingUsers();
  }

  Future<void> _checkExistingUsers() async {
    final users = await TestUserSetup.checkTestUsers();
    setState(() {
      _existingUsers = users;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Configuration Utilisateurs Test'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎯 Gestion des Comptes de Test',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // État des utilisateurs
            _buildUserStatus(),
            const SizedBox(height: 20),

            // Boutons d'action
            _buildActionButtons(),
            const SizedBox(height: 20),

            // Résultat
            if (_result.isNotEmpty) _buildResult(),

            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📊 État des Comptes', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _existingUsers['agent'] == true ? Icons.check_circle : Icons.cancel,
                  color: _existingUsers['agent'] == true ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                const Text('Agent: agent.test@star.tn'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _existingUsers['conducteur'] == true ? Icons.check_circle : Icons.cancel,
                  color: _existingUsers['conducteur'] == true ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                const Text('Conducteur: conducteur.test@email.com'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _createAgent,
            icon: const Icon(Icons.business),
            label: const Text('Créer Agent de Test'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _createConducteur,
            icon: const Icon(Icons.directions_car),
            label: const Text('Créer Conducteur de Test'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _deleteUsers,
            icon: const Icon(Icons.delete),
            label: const Text('Supprimer Utilisateurs Test'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📋 Résultat', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_result),
          ],
        ),
      ),
    );
  }

  Future<void> _createAgent() async {
    setState(() {
      _isLoading = true;
      _result = '';
    });

    final result = await TestUserSetup.createTestAgent();
    await _checkExistingUsers();

    setState(() {
      _isLoading = false;
      _result = result['message'];
    });
  }

  Future<void> _createConducteur() async {
    setState(() {
      _isLoading = true;
      _result = '';
    });

    final result = await TestUserSetup.createTestConducteur();
    await _checkExistingUsers();

    setState(() {
      _isLoading = false;
      _result = result['message'];
    });
  }

  Future<void> _deleteUsers() async {
    setState(() {
      _isLoading = true;
      _result = '';
    });

    final result = await TestUserSetup.deleteTestUsers();
    await _checkExistingUsers();

    setState(() {
      _isLoading = false;
      _result = result['message'];
    });
  }
}
