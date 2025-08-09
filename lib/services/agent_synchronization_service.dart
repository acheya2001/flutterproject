import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 🔄 Service de synchronisation des agents entre les collections
/// Maintient la cohérence entre 'users' (admin agence) et 'agents_assurance' (admin compagnie)
class AgentSynchronizationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔄 Synchroniser un agent créé par admin agence vers agents_assurance
  static Future<Map<String, dynamic>> syncAgentFromUsersToAssurance({
    required String agentId,
    required Map<String, dynamic> agentData,
  }) async {
    try {
      debugPrint('[SYNC] 🔄 Synchronisation agent vers agents_assurance: $agentId');

      // Vérifier si l'agent existe déjà dans agents_assurance
      final existingQuery = await _firestore
          .collection('agents_assurance')
          .where('uid', isEqualTo: agentId)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        debugPrint('[SYNC] ⚠️ Agent déjà synchronisé: $agentId');
        return {
          'success': true,
          'message': 'Agent déjà synchronisé',
          'alreadyExists': true,
        };
      }

      // Créer l'entrée dans agents_assurance
      await _firestore.collection('agents_assurance').add({
        'uid': agentId,
        'nom': agentData['nom'],
        'prenom': agentData['prenom'],
        'email': agentData['email'],
        'telephone': agentData['telephone'],
        'agence': agentData['agenceNom'] ?? agentData['agence'],
        'compagnieId': agentData['compagnieId'],
        'statut': 'actif',
        'source': 'admin_agence',
        'syncedFrom': 'users',
        'dateCreation': FieldValue.serverTimestamp(),
        'dateSynchronisation': FieldValue.serverTimestamp(),
      });

      debugPrint('[SYNC] ✅ Agent synchronisé vers agents_assurance: $agentId');

      return {
        'success': true,
        'message': 'Agent synchronisé avec succès',
      };

    } catch (e) {
      debugPrint('[SYNC] ❌ Erreur synchronisation: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🔄 Synchroniser un agent créé par admin compagnie vers users
  static Future<Map<String, dynamic>> syncAgentFromAssuranceToUsers({
    required String agentAssuranceId,
    required Map<String, dynamic> agentData,
  }) async {
    try {
      debugPrint('[SYNC] 🔄 Synchronisation agent vers users: $agentAssuranceId');

      final uid = agentData['uid'] ?? _firestore.collection('users').doc().id;

      // Vérifier si l'agent existe déjà dans users
      final existingDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (existingDoc.exists) {
        debugPrint('[SYNC] ⚠️ Agent déjà synchronisé: $uid');
        return {
          'success': true,
          'message': 'Agent déjà synchronisé',
          'alreadyExists': true,
        };
      }

      // Créer l'entrée dans users
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'nom': agentData['nom'],
        'prenom': agentData['prenom'],
        'email': agentData['email'],
        'telephone': agentData['telephone'],
        'role': 'agent',
        'agenceNom': agentData['agence'],
        'agence': agentData['agence'],
        'compagnieId': agentData['compagnieId'],
        'isActive': true,
        'status': 'actif',
        'source': 'admin_compagnie',
        'syncedFrom': 'agents_assurance',
        'created_at': FieldValue.serverTimestamp(),
        'dateSynchronisation': FieldValue.serverTimestamp(),
        'createdBy': 'admin_compagnie',
        'origin': 'admin_compagnie_creation',
      });

      debugPrint('[SYNC] ✅ Agent synchronisé vers users: $uid');

      return {
        'success': true,
        'message': 'Agent synchronisé avec succès',
        'uid': uid,
      };

    } catch (e) {
      debugPrint('[SYNC] ❌ Erreur synchronisation: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🔄 Synchronisation complète de tous les agents d'une compagnie
  static Future<Map<String, dynamic>> fullSyncCompagnieAgents(String compagnieId) async {
    try {
      debugPrint('[SYNC] 🔄 Synchronisation complète compagnie: $compagnieId');

      int syncedFromUsers = 0;
      int syncedFromAssurance = 0;
      List<String> errors = [];

      // 1. Synchroniser les agents de users vers agents_assurance
      final usersQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      for (var userDoc in usersQuery.docs) {
        final result = await syncAgentFromUsersToAssurance(
          agentId: userDoc.id,
          agentData: userDoc.data(),
        );

        if (result['success'] && !result['alreadyExists']) {
          syncedFromUsers++;
        } else if (!result['success']) {
          errors.add('Users->Assurance: ${result['error']}');
        }
      }

      // 2. Synchroniser les agents de agents_assurance vers users
      final assuranceQuery = await _firestore
          .collection('agents_assurance')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      for (var assuranceDoc in assuranceQuery.docs) {
        final result = await syncAgentFromAssuranceToUsers(
          agentAssuranceId: assuranceDoc.id,
          agentData: assuranceDoc.data(),
        );

        if (result['success'] && !result['alreadyExists']) {
          syncedFromAssurance++;
        } else if (!result['success']) {
          errors.add('Assurance->Users: ${result['error']}');
        }
      }

      debugPrint('[SYNC] ✅ Synchronisation terminée - Users: $syncedFromUsers, Assurance: $syncedFromAssurance');

      return {
        'success': true,
        'syncedFromUsers': syncedFromUsers,
        'syncedFromAssurance': syncedFromAssurance,
        'totalUsers': usersQuery.docs.length,
        'totalAssurance': assuranceQuery.docs.length,
        'errors': errors,
        'message': 'Synchronisation complète terminée',
      };

    } catch (e) {
      debugPrint('[SYNC] ❌ Erreur synchronisation complète: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🔄 Vérifier l'état de synchronisation d'une compagnie
  static Future<Map<String, dynamic>> checkSyncStatus(String compagnieId) async {
    try {
      final usersCount = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('compagnieId', isEqualTo: compagnieId)
          .count()
          .get();

      final assuranceCount = await _firestore
          .collection('agents_assurance')
          .where('compagnieId', isEqualTo: compagnieId)
          .count()
          .get();

      final usersTotal = usersCount.count ?? 0;
      final assuranceTotal = assuranceCount.count ?? 0;

      return {
        'success': true,
        'usersCount': usersTotal,
        'assuranceCount': assuranceTotal,
        'isInSync': usersTotal == assuranceTotal,
        'difference': (usersTotal - assuranceTotal).abs(),
      };

    } catch (e) {
      debugPrint('[SYNC] ❌ Erreur vérification sync: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
