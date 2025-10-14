import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'constat_agent_notification_service.dart';

/// 🧪 Service de test pour vérifier la gestion des statuts des constats PDF
class ConstatStatusTestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔍 Vérifier le statut d'un constat dans toutes les collections
  static Future<Map<String, dynamic>> verifierStatutConstat(String sessionId) async {
    try {
      debugPrint('🔍 [TEST] Vérification statut pour session: $sessionId');

      final resultats = <String, dynamic>{};

      // 1. Vérifier dans constats_finalises
      final constatDoc = await _firestore
          .collection('constats_finalises')
          .doc(sessionId)
          .get();

      if (constatDoc.exists) {
        final data = constatDoc.data()!;
        resultats['constats_finalises'] = {
          'existe': true,
          'statut': data['statut'],
          'statutSession': data['statutSession'],
          'dateEnvoi': data['dateEnvoi'],
          'expertAssigne': data['expertAssigne'],
          'agentInfo': data['agentInfo'],
        };
      } else {
        resultats['constats_finalises'] = {'existe': false};
      }

      // 2. Vérifier dans sessions_collaboratives
      final sessionDoc = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .get();

      if (sessionDoc.exists) {
        final data = sessionDoc.data()!;
        resultats['sessions_collaboratives'] = {
          'existe': true,
          'statut': data['statut'],
          'statutSession': data['statutSession'],
          'dateFinalisation': data['dateFinalisation'],
        };
      } else {
        resultats['sessions_collaboratives'] = {'existe': false};
      }

      // 3. Vérifier dans agent_constats
      final agentConstatsQuery = await _firestore
          .collection('agent_constats')
          .where('sessionId', isEqualTo: sessionId)
          .get();

      resultats['agent_constats'] = {
        'existe': agentConstatsQuery.docs.isNotEmpty,
        'nombre': agentConstatsQuery.docs.length,
        'documents': agentConstatsQuery.docs.map((doc) => {
          'id': doc.id,
          'statutTraitement': doc.data()['statutTraitement'],
          'agentEmail': doc.data()['agentEmail'],
          'dateCreation': doc.data()['createdAt'],
        }).toList(),
      };

      // 4. Vérifier dans missions_expertise
      final missionsQuery = await _firestore
          .collection('missions_expertise')
          .where('sessionId', isEqualTo: sessionId)
          .get();

      resultats['missions_expertise'] = {
        'existe': missionsQuery.docs.isNotEmpty,
        'nombre': missionsQuery.docs.length,
        'documents': missionsQuery.docs.map((doc) => {
          'id': doc.id,
          'statut': doc.data()['statut'],
          'expertId': doc.data()['expertId'],
          'dateCreation': doc.data()['dateCreation'],
        }).toList(),
      };

      debugPrint('✅ [TEST] Vérification terminée');
      return resultats;

    } catch (e) {
      debugPrint('❌ [TEST] Erreur vérification: $e');
      return {'erreur': e.toString()};
    }
  }

  /// 🔧 Simuler l'envoi d'un constat aux agents
  static Future<Map<String, dynamic>> simulerEnvoiAgent(String sessionId) async {
    try {
      debugPrint('🧪 [TEST] Simulation envoi agent pour session: $sessionId');

      // Mettre à jour le statut dans constats_finalises
      await _firestore.collection('constats_finalises').doc(sessionId).set({
        'sessionId': sessionId,
        'statut': 'envoye',
        'statutSession': 'envoye',
        'dateEnvoi': FieldValue.serverTimestamp(),
        'agentInfo': {
          'agentId': 'test_agent_123',
          'email': 'agent.test@assurance.tn',
          'nom': 'Agent Test',
          'prenom': 'Test',
          'agenceNom': 'Agence Test',
          'compagnieNom': 'Compagnie Test',
        },
        'statutTraitement': 'nouveau',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ [TEST] Statut mis à jour vers "envoye"');
      return {'success': true, 'statut': 'envoye'};

    } catch (e) {
      debugPrint('❌ [TEST] Erreur simulation envoi: $e');
      return {'success': false, 'erreur': e.toString()};
    }
  }

  /// 🔧 Simuler l'assignation d'un expert RÉEL
  static Future<Map<String, dynamic>> simulerAssignationExpert(String sessionId) async {
    try {
      debugPrint('🧪 [TEST] Simulation assignation expert RÉEL pour session: $sessionId');

      // 1. Récupérer un vrai expert disponible de la base de données
      final vraiExpert = await _obtenirVraiExpertDisponible();

      if (vraiExpert == null) {
        debugPrint('⚠️ [TEST] Aucun expert réel disponible - utilisation d\'un expert fictif');
        return await _simulerAvecExpertFictif(sessionId);
      }

      debugPrint('✅ [TEST] Expert réel trouvé: ${vraiExpert['prenom']} ${vraiExpert['nom']} (${vraiExpert['codeExpert']})');

      // 2. Utiliser les vraies données de l'expert
      final expertInfo = {
        'id': vraiExpert['id'] ?? vraiExpert['uid'],
        'nom': vraiExpert['nom'] ?? '',
        'prenom': vraiExpert['prenom'] ?? '',
        'codeExpert': vraiExpert['codeExpert'] ?? 'N/A',
        'telephone': vraiExpert['telephone'] ?? '',
        'email': vraiExpert['email'] ?? '',
      };

      // 3. Utiliser la fonction de mise à jour du statut
      await ConstatAgentNotificationService.mettreAJourStatutExpertAssigne(
        sessionId: sessionId,
        expertInfo: expertInfo,
        missionId: 'mission_test_${DateTime.now().millisecondsSinceEpoch}',
      );

      debugPrint('✅ [TEST] Statut mis à jour vers "expert_assigne" avec expert réel');
      return {'success': true, 'statut': 'expert_assigne', 'expertReel': true, 'expertNom': '${vraiExpert['prenom']} ${vraiExpert['nom']}'};

    } catch (e) {
      debugPrint('❌ [TEST] Erreur simulation assignation: $e');
      return {'success': false, 'erreur': e.toString()};
    }
  }

  /// 🔍 Obtenir un vrai expert disponible de la base de données
  static Future<Map<String, dynamic>?> _obtenirVraiExpertDisponible() async {
    try {
      debugPrint('🔍 [TEST] Recherche d\'un expert réel disponible...');

      // Chercher dans la collection 'users' avec role 'expert'
      final expertsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'expert')
          .where('isActive', isEqualTo: true)
          .where('isDisponible', isEqualTo: true)
          .limit(1)
          .get();

      if (expertsQuery.docs.isNotEmpty) {
        final expertDoc = expertsQuery.docs.first;
        final expertData = expertDoc.data();
        expertData['id'] = expertDoc.id;

        debugPrint('✅ [TEST] Expert trouvé dans users: ${expertData['prenom']} ${expertData['nom']}');
        return expertData;
      }

      // Si pas trouvé dans 'users', chercher dans 'experts'
      final expertsQuery2 = await _firestore
          .collection('experts')
          .where('status', isEqualTo: 'actif')
          .where('disponible', isEqualTo: true)
          .limit(1)
          .get();

      if (expertsQuery2.docs.isNotEmpty) {
        final expertDoc = expertsQuery2.docs.first;
        final expertData = expertDoc.data();
        expertData['id'] = expertDoc.id;

        debugPrint('✅ [TEST] Expert trouvé dans experts: ${expertData['prenom']} ${expertData['nom']}');
        return expertData;
      }

      debugPrint('⚠️ [TEST] Aucun expert réel disponible trouvé');
      return null;

    } catch (e) {
      debugPrint('❌ [TEST] Erreur recherche expert réel: $e');
      return null;
    }
  }

  /// 🎭 Simuler avec expert fictif (fallback)
  static Future<Map<String, dynamic>> _simulerAvecExpertFictif(String sessionId) async {
    debugPrint('🎭 [TEST] Utilisation d\'un expert fictif pour le test');

    final expertInfo = {
      'id': 'expert_test_${DateTime.now().millisecondsSinceEpoch}',
      'nom': 'Expert Test',
      'prenom': 'Jean',
      'codeExpert': 'EXP001',
      'telephone': '+216 20 123 456',
      'email': 'expert.test@example.com',
    };

    await ConstatAgentNotificationService.mettreAJourStatutExpertAssigne(
      sessionId: sessionId,
      expertInfo: expertInfo,
      missionId: 'mission_test_${DateTime.now().millisecondsSinceEpoch}',
    );

    return {'success': true, 'statut': 'expert_assigne', 'expertReel': false, 'expertNom': 'Expert Test (fictif)'};
  }

  /// 📊 Afficher un rapport complet du statut
  static void afficherRapportStatut(Map<String, dynamic> resultats) {
    debugPrint('\n📊 === RAPPORT STATUT CONSTAT ===');
    
    // Constats finalisés
    final constatFinalise = resultats['constats_finalises'];
    if (constatFinalise['existe']) {
      debugPrint('✅ constats_finalises: TROUVÉ');
      debugPrint('   📋 Statut: ${constatFinalise['statut']}');
      debugPrint('   📋 StatutSession: ${constatFinalise['statutSession']}');
      debugPrint('   📤 Date envoi: ${constatFinalise['dateEnvoi']}');
      debugPrint('   👨‍💼 Expert assigné: ${constatFinalise['expertAssigne'] != null}');
    } else {
      debugPrint('❌ constats_finalises: NON TROUVÉ');
    }

    // Sessions collaboratives
    final session = resultats['sessions_collaboratives'];
    if (session['existe']) {
      debugPrint('✅ sessions_collaboratives: TROUVÉ');
      debugPrint('   📋 Statut: ${session['statut']}');
    } else {
      debugPrint('❌ sessions_collaboratives: NON TROUVÉ');
    }

    // Agent constats
    final agentConstats = resultats['agent_constats'];
    debugPrint('📧 agent_constats: ${agentConstats['nombre']} document(s)');

    // Missions expertise
    final missions = resultats['missions_expertise'];
    debugPrint('🔧 missions_expertise: ${missions['nombre']} mission(s)');

    debugPrint('=== FIN RAPPORT ===\n');
  }

  /// 🧪 Test complet du flux de statuts
  static Future<void> testerFluxComplet(String sessionId) async {
    debugPrint('\n🧪 === TEST FLUX COMPLET ===');
    debugPrint('Session ID: $sessionId');

    // 1. État initial
    debugPrint('\n1️⃣ ÉTAT INITIAL');
    var resultats = await verifierStatutConstat(sessionId);
    afficherRapportStatut(resultats);

    // 2. Simuler envoi agent
    debugPrint('\n2️⃣ SIMULATION ENVOI AGENT');
    await simulerEnvoiAgent(sessionId);
    resultats = await verifierStatutConstat(sessionId);
    afficherRapportStatut(resultats);

    // 3. Simuler assignation expert
    debugPrint('\n3️⃣ SIMULATION ASSIGNATION EXPERT');
    await simulerAssignationExpert(sessionId);
    resultats = await verifierStatutConstat(sessionId);
    afficherRapportStatut(resultats);

    debugPrint('✅ === TEST TERMINÉ ===\n');
  }
}
