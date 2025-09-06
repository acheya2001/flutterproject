import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 🧪 Service pour générer des données de test
class TestDataGeneratorService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🏢 Générer des données de test pour une compagnie
  static Future<void> generateTestDataForCompany(String compagnieId) async {
    if (!kDebugMode) {
      debugPrint('[TEST_DATA] ⚠️ Génération de données de test uniquement en mode debug');
      return;
    }

    try {
      debugPrint('[TEST_DATA] 🧪 Génération de données de test pour compagnie: $compagnieId');

      // 1. Créer des agences de test
      await _createTestAgencies(compagnieId);

      // 2. Créer des agents de test
      await _createTestAgents(compagnieId);

      // 3. Créer des contrats de test
      await _createTestContracts(compagnieId);

      // 4. Créer des sinistres de test
      await _createTestSinistres(compagnieId);

      debugPrint('[TEST_DATA] ✅ Données de test générées avec succès');

    } catch (e) {
      debugPrint('[TEST_DATA] ❌ Erreur génération données de test: $e');
    }
  }

  /// 🏢 Créer des agences de test
  static Future<void> _createTestAgencies(String compagnieId) async {
    final agences = [
      {
        'nom': 'Agence Centre-Ville',
        'adresse': '123 Avenue Habib Bourguiba, Tunis',
        'telephone': '+216 71 123 456',
        'email': 'centre.ville@test.tn',
        'compagnieId': compagnieId,
        'isTestData': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'nom': 'Agence Sfax',
        'adresse': '456 Rue de la République, Sfax',
        'telephone': '+216 74 789 012',
        'email': 'sfax@test.tn',
        'compagnieId': compagnieId,
        'isTestData': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'nom': 'Agence Sousse',
        'adresse': '789 Boulevard du 14 Janvier, Sousse',
        'telephone': '+216 73 345 678',
        'email': 'sousse@test.tn',
        'compagnieId': compagnieId,
        'isTestData': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (final agence in agences) {
      await _firestore.collection('agences').add(agence);
    }

    debugPrint('[TEST_DATA] ✅ ${agences.length} agences de test créées');
  }

  /// 👥 Créer des agents de test
  static Future<void> _createTestAgents(String compagnieId) async {
    final agents = [
      {
        'displayName': 'Ahmed Ben Ali',
        'email': 'ahmed.benali@test.tn',
        'role': 'agent',
        'compagnieId': compagnieId,
        'agenceId': 'agence_centre_ville',
        'isActive': true,
        'isTestData': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'displayName': 'Fatma Trabelsi',
        'email': 'fatma.trabelsi@test.tn',
        'role': 'agent',
        'compagnieId': compagnieId,
        'agenceId': 'agence_sfax',
        'isActive': true,
        'isTestData': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'displayName': 'Mohamed Karray',
        'email': 'mohamed.karray@test.tn',
        'role': 'agent',
        'compagnieId': compagnieId,
        'agenceId': 'agence_sousse',
        'isActive': true,
        'isTestData': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'displayName': 'Leila Mansouri',
        'email': 'leila.mansouri@test.tn',
        'role': 'agent',
        'compagnieId': compagnieId,
        'agenceId': 'agence_centre_ville',
        'isActive': true,
        'isTestData': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'displayName': 'Karim Bouazizi',
        'email': 'karim.bouazizi@test.tn',
        'role': 'agent',
        'compagnieId': compagnieId,
        'agenceId': 'agence_sfax',
        'isActive': false,
        'isTestData': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (final agent in agents) {
      await _firestore.collection('users').add(agent);
    }

    debugPrint('[TEST_DATA] ✅ ${agents.length} agents de test créés');
  }

  /// 📄 Créer des contrats de test
  static Future<void> _createTestContracts(String compagnieId) async {
    final contrats = List.generate(15, (index) => {
      'numeroContrat': 'CT${DateTime.now().millisecondsSinceEpoch}${index.toString().padLeft(3, '0')}',
      'compagnieId': compagnieId,
      'conducteurNom': 'Conducteur Test ${index + 1}',
      'vehiculeMarque': ['Toyota', 'Peugeot', 'Renault', 'Volkswagen', 'BMW'][index % 5],
      'vehiculeModele': 'Modèle ${index + 1}',
      'vehiculeImmatriculation': '${(123 + index).toString()} TUN ${(1000 + index).toString()}',
      'dateDebut': Timestamp.fromDate(DateTime.now().subtract(Duration(days: 30 + index))),
      'dateFin': Timestamp.fromDate(DateTime.now().add(Duration(days: 335 - index))),
      'montantPrime': 500.0 + (index * 50),
      'statut': ['actif', 'suspendu', 'expire'][index % 3],
      'isTestData': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    for (final contrat in contrats) {
      await _firestore.collection('contrats').add(contrat);
    }

    debugPrint('[TEST_DATA] ✅ ${contrats.length} contrats de test créés');
  }

  /// 🚨 Créer des sinistres de test
  static Future<void> _createTestSinistres(String compagnieId) async {
    final sinistres = List.generate(8, (index) => {
      'numeroSinistre': 'SIN${DateTime.now().millisecondsSinceEpoch}${index.toString().padLeft(3, '0')}',
      'compagnieId': compagnieId,
      'dateAccident': Timestamp.fromDate(DateTime.now().subtract(Duration(days: index * 5))),
      'lieuAccident': 'Lieu Test ${index + 1}',
      'typeAccident': ['collision', 'vol', 'incendie', 'vandalisme'][index % 4],
      'montantEstime': 1000.0 + (index * 500),
      'statut': ['en_cours', 'valide', 'refuse'][index % 3],
      'description': 'Description du sinistre test ${index + 1}',
      'isTestData': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    for (final sinistre in sinistres) {
      await _firestore.collection('sinistres').add(sinistre);
    }

    debugPrint('[TEST_DATA] ✅ ${sinistres.length} sinistres de test créés');
  }

  /// 🗑️ Supprimer toutes les données de test
  static Future<void> clearTestData() async {
    if (!kDebugMode) {
      debugPrint('[TEST_DATA] ⚠️ Suppression de données de test uniquement en mode debug');
      return;
    }

    try {
      debugPrint('[TEST_DATA] 🗑️ Suppression des données de test...');

      final collections = ['agences', 'users', 'contrats', 'sinistres'];
      
      for (final collection in collections) {
        final snapshot = await _firestore
            .collection(collection)
            .where('isTestData', isEqualTo: true)
            .get();
        
        for (final doc in snapshot.docs) {
          await doc.reference.delete();
        }
        
        debugPrint('[TEST_DATA] 🗑️ ${snapshot.docs.length} documents supprimés de $collection');
      }

      debugPrint('[TEST_DATA] ✅ Toutes les données de test supprimées');

    } catch (e) {
      debugPrint('[TEST_DATA] ❌ Erreur suppression données de test: $e');
    }
  }

  /// 📊 Vérifier l'existence de données de test
  static Future<bool> hasTestData() async {
    try {
      final snapshot = await _firestore
          .collection('agences')
          .where('isTestData', isEqualTo: true)
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('[TEST_DATA] ❌ Erreur vérification données de test: $e');
      return false;
    }
  }
}
