import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sinistre_expert_assignment_service.dart';
import 'admin_agence_expert_service.dart';

/// 🧪 Service de test pour le workflow complet sinistre-expert
class WorkflowTestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🧪 Tester le workflow complet
  static Future<Map<String, dynamic>> testCompleteWorkflow() async {
    final results = <String, dynamic>{
      'success': false,
      'steps': <String, dynamic>{},
      'errors': <String>[],
      'testData': <String, dynamic>{},
    };

    try {
      debugPrint('[WORKFLOW_TEST] 🧪 Début du test du workflow complet');

      // Étape 1: Créer des données de test
      final testData = await _createTestData();
      results['testData'] = testData;
      results['steps']['createTestData'] = {'success': true, 'message': 'Données de test créées'};

      // Étape 2: Tester la création d'expert par admin agence
      await _testExpertCreation(testData);
      results['steps']['expertCreation'] = {'success': true, 'message': 'Expert créé avec succès'};

      // Étape 3: Tester la déclaration de sinistre par conducteur
      final sinistreId = await _testSinistreDeclaration(testData);
      results['steps']['sinistreDeclaration'] = {'success': true, 'message': 'Sinistre déclaré', 'sinistreId': sinistreId};

      // Étape 4: Tester l'assignation d'expert par agent
      final missionId = await _testExpertAssignment(testData, sinistreId);
      results['steps']['expertAssignment'] = {'success': true, 'message': 'Expert assigné', 'missionId': missionId};

      // Étape 5: Tester le démarrage de mission par expert
      await _testMissionStart(testData, missionId);
      results['steps']['missionStart'] = {'success': true, 'message': 'Mission démarrée'};

      // Étape 6: Tester la finalisation de mission par expert
      await _testMissionCompletion(testData, missionId);
      results['steps']['missionCompletion'] = {'success': true, 'message': 'Mission terminée'};

      // Étape 7: Vérifier le suivi par conducteur
      await _testConducteurTracking(testData, sinistreId);
      results['steps']['conducteurTracking'] = {'success': true, 'message': 'Suivi conducteur vérifié'};

      results['success'] = true;
      debugPrint('[WORKFLOW_TEST] ✅ Test du workflow complet réussi');

    } catch (e) {
      debugPrint('[WORKFLOW_TEST] ❌ Erreur dans le test: $e');
      results['errors'].add(e.toString());
    }

    return results;
  }

  /// 📋 Créer des données de test
  static Future<Map<String, dynamic>> _createTestData() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    return {
      'compagnieId': 'test_compagnie_$timestamp',
      'agenceId': 'test_agence_$timestamp',
      'adminAgenceId': 'test_admin_agence_$timestamp',
      'agentId': 'test_agent_$timestamp',
      'expertId': 'test_expert_$timestamp',
      'conducteurId': 'test_conducteur_$timestamp',
      'timestamp': timestamp,
    };
  }

  /// 🔧 Tester la création d'expert
  static Future<void> _testExpertCreation(Map<String, dynamic> testData) async {
    debugPrint('[WORKFLOW_TEST] 🔧 Test création expert...');

    // Simuler la création d'expert par admin agence
    final expertData = {
      'prenom': 'Expert',
      'nom': 'Test',
      'telephone': '+21612345678',
      'cin': '12345678',
      'email': 'expert.test.${testData['timestamp']}@test.tn',
      'adresse': 'Adresse test',
      'specialites': ['automobile', 'incendie'],
      'gouvernoratsIntervention': ['Tunis', 'Ariana'],
      'agenceId': testData['agenceId'],
      'compagnieId': testData['compagnieId'],
    };

    // Créer l'expert dans Firestore directement pour le test
    await _firestore.collection('experts').doc(testData['expertId']).set({
      ...expertData,
      'uid': testData['expertId'],
      'role': 'expert',
      'codeExpert': 'EXP-TEST-${testData['timestamp']}',
      'numeroLicence': 'LIC-${testData['timestamp']}',
      'isActive': true,
      'isDisponible': true,
      'nombreExpertises': 0,
      'expertisesEnCours': 0,
      'noteMoyenne': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
      'isFakeData': true, // Marquer comme données de test
    });

    // Créer aussi dans la collection users
    await _firestore.collection('users').doc(testData['expertId']).set({
      ...expertData,
      'uid': testData['expertId'],
      'role': 'expert',
      'codeExpert': 'EXP-TEST-${testData['timestamp']}',
      'numeroLicence': 'LIC-${testData['timestamp']}',
      'isActive': true,
      'isDisponible': true,
      'createdAt': FieldValue.serverTimestamp(),
      'isFakeData': true,
    });

    debugPrint('[WORKFLOW_TEST] ✅ Expert créé: ${testData['expertId']}');
  }

  /// 📋 Tester la déclaration de sinistre
  static Future<String> _testSinistreDeclaration(Map<String, dynamic> testData) async {
    debugPrint('[WORKFLOW_TEST] 📋 Test déclaration sinistre...');

    final sinistreId = 'test_sinistre_${testData['timestamp']}';
    
    final sinistreData = {
      'numeroSinistre': 'SIN-TEST-${testData['timestamp']}',
      'conducteurId': testData['conducteurId'],
      'agenceId': testData['agenceId'],
      'compagnieId': testData['compagnieId'],
      'typeAccident': 'Collision',
      'dateAccident': Timestamp.now(),
      'heureAccident': '14:30',
      'lieuAccident': 'Avenue Habib Bourguiba, Tunis',
      'gouvernorat': 'Tunis',
      'description': 'Test de collision pour workflow',
      'statut': 'ouvert',
      'degatsEstimes': 2500.0,
      'createdAt': FieldValue.serverTimestamp(),
      'isFakeData': true,
    };

    await _firestore.collection('sinistres').doc(sinistreId).set(sinistreData);

    debugPrint('[WORKFLOW_TEST] ✅ Sinistre déclaré: $sinistreId');
    return sinistreId;
  }

  /// 🎯 Tester l'assignation d'expert
  static Future<String> _testExpertAssignment(Map<String, dynamic> testData, String sinistreId) async {
    debugPrint('[WORKFLOW_TEST] 🎯 Test assignation expert...');

    // Utiliser le service d'assignation
    final assignmentResult = await SinistreExpertAssignmentService.assignExpertToSinistre(
      sinistreId: sinistreId,
      expertId: testData['expertId'],
      agentId: testData['agentId'],
      delaiIntervention: 24,
      commentaire: 'Test d\'assignation automatique',
    );

    if (assignmentResult['success'] == true) {
      final missionId = assignmentResult['missionId'] as String;
      debugPrint('[WORKFLOW_TEST] ✅ Expert assigné, mission: $missionId');
      return missionId;
    } else {
      throw Exception('Échec de l\'assignation: ${assignmentResult['error']}');
    }
  }

  /// ▶️ Tester le démarrage de mission
  static Future<void> _testMissionStart(Map<String, dynamic> testData, String missionId) async {
    debugPrint('[WORKFLOW_TEST] ▶️ Test démarrage mission...');

    await _firestore.collection('missions_expertise').doc(missionId).update({
      'statut': 'en_cours',
      'dateIntervention': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    debugPrint('[WORKFLOW_TEST] ✅ Mission démarrée: $missionId');
  }

  /// ✅ Tester la finalisation de mission
  static Future<void> _testMissionCompletion(Map<String, dynamic> testData, String missionId) async {
    debugPrint('[WORKFLOW_TEST] ✅ Test finalisation mission...');

    await _firestore.collection('missions_expertise').doc(missionId).update({
      'statut': 'terminee',
      'dateCompletion': FieldValue.serverTimestamp(),
      'rapportExpertise': 'Rapport de test - Dégâts mineurs, réparation estimée à 2500 DT',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Libérer l'expert
    await _firestore.collection('experts').doc(testData['expertId']).update({
      'isDisponible': true,
      'expertisesEnCours': FieldValue.increment(-1),
      'nombreExpertises': FieldValue.increment(1),
    });

    await _firestore.collection('users').doc(testData['expertId']).update({
      'isDisponible': true,
      'expertisesEnCours': FieldValue.increment(-1),
      'nombreExpertises': FieldValue.increment(1),
    });

    debugPrint('[WORKFLOW_TEST] ✅ Mission finalisée: $missionId');
  }

  /// 👁️ Tester le suivi par conducteur
  static Future<void> _testConducteurTracking(Map<String, dynamic> testData, String sinistreId) async {
    debugPrint('[WORKFLOW_TEST] 👁️ Test suivi conducteur...');

    // Vérifier que le sinistre a bien été mis à jour
    final sinistreDoc = await _firestore.collection('sinistres').doc(sinistreId).get();
    
    if (!sinistreDoc.exists) {
      throw Exception('Sinistre non trouvé pour le suivi');
    }

    final sinistreData = sinistreDoc.data()!;
    
    if (sinistreData['expertId'] == null) {
      throw Exception('Expert non assigné au sinistre');
    }

    if (sinistreData['statut'] != 'expertise_terminee') {
      debugPrint('[WORKFLOW_TEST] ⚠️ Statut sinistre: ${sinistreData['statut']}');
    }

    debugPrint('[WORKFLOW_TEST] ✅ Suivi conducteur vérifié');
  }

  /// 🧹 Nettoyer les données de test
  static Future<void> cleanupTestData() async {
    debugPrint('[WORKFLOW_TEST] 🧹 Nettoyage des données de test...');

    try {
      // Supprimer les documents de test dans toutes les collections
      final collections = ['users', 'experts', 'sinistres', 'missions_expertise', 'notifications'];
      
      for (final collection in collections) {
        final query = await _firestore
            .collection(collection)
            .where('isFakeData', isEqualTo: true)
            .get();
        
        for (final doc in query.docs) {
          await doc.reference.delete();
        }
        
        debugPrint('[WORKFLOW_TEST] 🧹 Collection $collection nettoyée (${query.docs.length} documents)');
      }

      debugPrint('[WORKFLOW_TEST] ✅ Nettoyage terminé');
    } catch (e) {
      debugPrint('[WORKFLOW_TEST] ❌ Erreur nettoyage: $e');
    }
  }

  /// 📊 Obtenir un rapport de test
  static Future<Map<String, dynamic>> getTestReport() async {
    final collections = ['users', 'experts', 'sinistres', 'missions_expertise'];
    final report = <String, dynamic>{};

    for (final collection in collections) {
      final query = await _firestore
          .collection(collection)
          .where('isFakeData', isEqualTo: true)
          .get();
      
      report[collection] = {
        'count': query.docs.length,
        'documents': query.docs.map((doc) => {
          'id': doc.id,
          'data': doc.data(),
        }).toList(),
      };
    }

    return report;
  }
}
