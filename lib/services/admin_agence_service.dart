import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

/// 🏢 Service de gestion pour Admin Agence
/// Gère toutes les opérations spécifiques à l'admin agence
class AdminAgenceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🏢 Récupérer les informations de l'agence de l'admin connecté
  static Future<Map<String, dynamic>?> getAgenceInfo(String adminId) async {
    try {
      debugPrint('[ADMIN_AGENCE] 🏢 Récupération infos agence pour admin: $adminId');

      // Récupérer les infos de l'admin pour avoir l'agenceId
      final adminDoc = await _firestore.collection('users').doc(adminId).get();
      if (!adminDoc.exists) {
        debugPrint('[ADMIN_AGENCE] ❌ Admin non trouvé: $adminId');
        return null;
      }

      final adminData = adminDoc.data()!;
      debugPrint('[ADMIN_AGENCE] 📋 Données admin: ${adminData.keys.toList()}');

      final agenceId = adminData['agenceId'];
      debugPrint('[ADMIN_AGENCE] 🔍 AgenceId trouvé: $agenceId');

      if (agenceId == null) {
        debugPrint('[ADMIN_AGENCE] ❌ Admin sans agence assignée: $adminId');
        // Essayons de chercher par email dans les agences
        return await _findAgenceByAdminEmail(adminData['email']);
      }

      // Récupérer les informations de l'agence
      final agenceDoc = await _firestore.collection('agences').doc(agenceId).get();
      if (!agenceDoc.exists) {
        debugPrint('[ADMIN_AGENCE] ❌ Agence non trouvée: $agenceId');
        // Essayons de chercher par email dans les agences
        return await _findAgenceByAdminEmail(adminData['email']);
      }

      final agenceData = agenceDoc.data()!;
      agenceData['id'] = agenceDoc.id;

      // Récupérer les informations de la compagnie mère
      final compagnieId = agenceData['compagnieId'];
      debugPrint('[ADMIN_AGENCE] 🏢 CompagnieId trouvé: $compagnieId');

      if (compagnieId != null) {
        final compagnieDoc = await _firestore.collection('compagnies_assurance').doc(compagnieId).get();
        debugPrint('[ADMIN_AGENCE] 🔍 Compagnie doc exists: ${compagnieDoc.exists}');

        if (compagnieDoc.exists) {
          final compagnieData = compagnieDoc.data()!;
          agenceData['compagnieInfo'] = compagnieData;
          debugPrint('[ADMIN_AGENCE] ✅ Compagnie trouvée: ${compagnieData['nom']}');
        } else {
          debugPrint('[ADMIN_AGENCE] ❌ Compagnie non trouvée: $compagnieId');
        }
      } else {
        debugPrint('[ADMIN_AGENCE] ❌ Aucun compagnieId dans l\'agence');
      }

      debugPrint('[ADMIN_AGENCE] ✅ Infos agence récupérées: ${agenceData['nom']}');
      return agenceData;

    } catch (e) {
      debugPrint('[ADMIN_AGENCE] ❌ Erreur récupération agence: $e');
      return null;
    }
  }

  /// 🔍 Chercher une agence par email de l'admin
  static Future<Map<String, dynamic>?> _findAgenceByAdminEmail(String? email) async {
    if (email == null) return null;

    try {
      debugPrint('[ADMIN_AGENCE] 🔍 Recherche agence par email: $email');

      // Chercher dans toutes les agences
      final agencesQuery = await _firestore.collection('agences').get();

      for (final agenceDoc in agencesQuery.docs) {
        final agenceData = agenceDoc.data();

        // Vérifier si l'email correspond à l'admin de cette agence
        if (agenceData['adminEmail'] == email ||
            agenceData['email'] == email ||
            agenceData['contactEmail'] == email) {

          agenceData['id'] = agenceDoc.id;

          // Récupérer les informations de la compagnie mère
          final compagnieId = agenceData['compagnieId'];
          if (compagnieId != null) {
            final compagnieDoc = await _firestore.collection('compagnies_assurance').doc(compagnieId).get();
            if (compagnieDoc.exists) {
              agenceData['compagnieInfo'] = compagnieDoc.data();
            }
          }

          debugPrint('[ADMIN_AGENCE] ✅ Agence trouvée par email: ${agenceData['nom']}');
          return agenceData;
        }
      }

      debugPrint('[ADMIN_AGENCE] ❌ Aucune agence trouvée pour email: $email');
      return null;

    } catch (e) {
      debugPrint('[ADMIN_AGENCE] ❌ Erreur recherche par email: $e');
      return null;
    }
  }

  /// ✏️ Modifier les informations de l'agence
  static Future<Map<String, dynamic>> updateAgenceInfo({
    required String agenceId,
    required String nom,
    required String adresse,
    required String telephone,
    String? email,
    String? description,
  }) async {
    try {
      debugPrint('[ADMIN_AGENCE] ✏️ Modification agence: $agenceId');

      await _firestore.collection('agences').doc(agenceId).update({
        'nom': nom,
        'adresse': adresse,
        'telephone': telephone,
        'email': email,
        'description': description,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastModifiedBy': 'admin_agence',
      });

      debugPrint('[ADMIN_AGENCE] ✅ Agence modifiée avec succès');
      return {
        'success': true,
        'message': 'Informations de l\'agence mises à jour avec succès',
      };

    } catch (e) {
      debugPrint('[ADMIN_AGENCE] ❌ Erreur modification agence: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de la modification de l\'agence',
      };
    }
  }

  /// 👥 Récupérer tous les agents de l'agence
  static Future<List<Map<String, dynamic>>> getAgentsOfAgence(String agenceId) async {
    try {
      debugPrint('[ADMIN_AGENCE] 👥 Récupération agents pour agence: $agenceId');

      final agentsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('agenceId', isEqualTo: agenceId)
          .get();

      List<Map<String, dynamic>> agents = [];
      for (var doc in agentsQuery.docs) {
        final agentData = doc.data();
        agentData['id'] = doc.id;
        agents.add(agentData);
      }

      debugPrint('[ADMIN_AGENCE] ✅ ${agents.length} agents récupérés');
      return agents;

    } catch (e) {
      debugPrint('[ADMIN_AGENCE] ❌ Erreur récupération agents: $e');
      return [];
    }
  }

  /// ➕ Créer un nouvel agent
  static Future<Map<String, dynamic>> createAgent({
    required String agenceId,
    required String agenceNom,
    required String compagnieId,
    required String compagnieNom,
    required String prenom,
    required String nom,
    required String email,
    required String telephone,
    String? cin,
    String? adresse,
  }) async {
    try {
      debugPrint('[ADMIN_AGENCE] ➕ Création agent pour agence: $agenceNom');

      // Vérifier si l'email existe déjà
      final existingUserQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existingUserQuery.docs.isNotEmpty) {
        return {
          'success': false,
          'error': 'Email déjà utilisé',
          'message': 'Cette adresse email est déjà utilisée par un autre utilisateur',
        };
      }

      // Générer un mot de passe automatique
      final password = _generatePassword();

      // Créer une référence de document pour auto-générer l'ID
      final docRef = _firestore.collection('users').doc();
      final uid = docRef.id;

      // Données de l'agent
      final agentData = {
        'uid': uid,
        'email': email,
        'password': password,
        'prenom': prenom,
        'nom': nom,
        'displayName': '$prenom $nom',
        'telephone': telephone,
        'cin': cin,
        'adresse': adresse,
        'role': 'agent',
        'agenceId': agenceId,
        'agenceNom': agenceNom,
        'compagnieId': compagnieId,
        'compagnieNom': compagnieNom,
        'isActive': true,
        'status': 'actif',
        'firebaseAuthCreated': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'origin': 'admin_agence_creation',
        'createdBy': 'admin_agence',
        'createdByRole': 'admin_agence',
      };

      // Créer l'agent dans Firestore
      await docRef.set(agentData);

      debugPrint('[ADMIN_AGENCE] ✅ Agent créé avec succès: $email');
      return {
        'success': true,
        'message': 'Agent créé avec succès',
        'email': email,
        'password': password,
        'displayName': '$prenom $nom',
        'agentId': uid,
      };

    } catch (e) {
      debugPrint('[ADMIN_AGENCE] ❌ Erreur création agent: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de la création de l\'agent',
      };
    }
  }

  /// ✏️ Modifier un agent
  static Future<Map<String, dynamic>> updateAgent({
    required String agentId,
    required String prenom,
    required String nom,
    required String email,
    required String telephone,
    String? cin,
    String? adresse,
  }) async {
    try {
      debugPrint('[ADMIN_AGENCE] ✏️ Modification agent: $agentId');

      // Vérifier si l'email existe déjà (sauf pour cet agent)
      final existingUserQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      for (var doc in existingUserQuery.docs) {
        if (doc.id != agentId) {
          return {
            'success': false,
            'error': 'Email déjà utilisé',
            'message': 'Cette adresse email est déjà utilisée par un autre utilisateur',
          };
        }
      }

      await _firestore.collection('users').doc(agentId).update({
        'prenom': prenom,
        'nom': nom,
        'displayName': '$prenom $nom',
        'email': email,
        'telephone': telephone,
        'cin': cin,
        'adresse': adresse,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[ADMIN_AGENCE] ✅ Agent modifié avec succès');
      return {
        'success': true,
        'message': 'Agent modifié avec succès',
      };

    } catch (e) {
      debugPrint('[ADMIN_AGENCE] ❌ Erreur modification agent: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de la modification de l\'agent',
      };
    }
  }

  /// 🔄 Activer/Désactiver un agent
  static Future<Map<String, dynamic>> toggleAgentStatus({
    required String agentId,
    required bool newStatus,
    String? reason,
  }) async {
    try {
      debugPrint('[ADMIN_AGENCE] 🔄 Changement statut agent: $agentId -> $newStatus');

      await _firestore.collection('users').doc(agentId).update({
        'isActive': newStatus,
        'status': newStatus ? 'actif' : 'inactif',
        'statusChangedAt': FieldValue.serverTimestamp(),
        'statusChangeReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[ADMIN_AGENCE] ✅ Statut agent modifié avec succès');
      return {
        'success': true,
        'message': newStatus 
            ? 'Agent activé avec succès' 
            : 'Agent désactivé avec succès',
      };

    } catch (e) {
      debugPrint('[ADMIN_AGENCE] ❌ Erreur changement statut: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors du changement de statut',
      };
    }
  }

  /// 🗑️ Supprimer un agent
  static Future<Map<String, dynamic>> deleteAgent(String agentId) async {
    try {
      debugPrint('[ADMIN_AGENCE] 🗑️ Suppression agent: $agentId');

      await _firestore.collection('users').doc(agentId).delete();

      debugPrint('[ADMIN_AGENCE] ✅ Agent supprimé avec succès');
      return {
        'success': true,
        'message': 'Agent supprimé avec succès',
      };

    } catch (e) {
      debugPrint('[ADMIN_AGENCE] ❌ Erreur suppression agent: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de la suppression de l\'agent',
      };
    }
  }

  /// 📊 Récupérer les statistiques de l'agence
  static Future<Map<String, dynamic>> getAgenceStats(String agenceId) async {
    try {
      debugPrint('[ADMIN_AGENCE] 📊 Récupération stats agence: $agenceId');

      // Compter les agents avec logs détaillés
      debugPrint('[ADMIN_AGENCE] 🔍 Recherche agents avec agenceId: $agenceId');

      final agentsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('agenceId', isEqualTo: agenceId)
          .get();

      debugPrint('[ADMIN_AGENCE] 📊 Agents trouvés: ${agentsQuery.docs.length}');

      // Afficher les détails de chaque agent trouvé
      for (var doc in agentsQuery.docs) {
        final data = doc.data();
        debugPrint('[ADMIN_AGENCE] 👤 Agent: ${data['email']} - AgenceId: ${data['agenceId']} - Role: ${data['role']}');
      }

      final totalAgents = agentsQuery.docs.length;
      final activeAgents = agentsQuery.docs.where((doc) => doc.data()['isActive'] == true).length;
      final inactiveAgents = totalAgents - activeAgents;

      debugPrint('[ADMIN_AGENCE] 📈 Stats calculées: Total=$totalAgents, Actifs=$activeAgents, Inactifs=$inactiveAgents');

      // Debug supplémentaire : vérifier tous les utilisateurs de cette agence
      final allUsersQuery = await _firestore
          .collection('users')
          .where('agenceId', isEqualTo: agenceId)
          .get();

      debugPrint('[ADMIN_AGENCE] 🔍 Tous les utilisateurs avec agenceId $agenceId: ${allUsersQuery.docs.length}');
      for (var doc in allUsersQuery.docs) {
        final data = doc.data();
        debugPrint('[ADMIN_AGENCE] 👤 User: ${data['email']} - Role: ${data['role']} - AgenceId: ${data['agenceId']}');
      }

      // Récupérer les dernières actions (derniers agents créés)
      final recentAgentsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('agenceId', isEqualTo: agenceId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      List<Map<String, dynamic>> recentActions = [];
      for (var doc in recentAgentsQuery.docs) {
        final data = doc.data();
        recentActions.add({
          'type': 'agent_created',
          'description': 'Agent ${data['prenom']} ${data['nom']} créé',
          'timestamp': data['createdAt'],
          'agentName': '${data['prenom']} ${data['nom']}',
        });
      }

      final stats = {
        'totalAgents': totalAgents,
        'activeAgents': activeAgents,
        'inactiveAgents': inactiveAgents,
        'recentActions': recentActions,
      };

      debugPrint('[ADMIN_AGENCE] ✅ Stats récupérées: $totalAgents agents');
      return stats;

    } catch (e) {
      debugPrint('[ADMIN_AGENCE] ❌ Erreur récupération stats: $e');
      return {
        'totalAgents': 0,
        'activeAgents': 0,
        'inactiveAgents': 0,
        'recentActions': [],
      };
    }
  }

  /// 👥 Récupérer la liste des agents d'une agence
  static Future<List<Map<String, dynamic>>> getAgenceAgents(String agenceId) async {
    try {
      debugPrint('[ADMIN_AGENCE] 👥 Récupération agents pour agence: $agenceId');

      final agentsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('agenceId', isEqualTo: agenceId)
          .where('statut', isEqualTo: 'actif')
          .get();

      final agents = <Map<String, dynamic>>[];

      for (final doc in agentsQuery.docs) {
        final agentData = doc.data();
        agentData['id'] = doc.id;
        agents.add(agentData);
      }

      debugPrint('[ADMIN_AGENCE] ✅ ${agents.length} agents trouvés pour agence $agenceId');
      return agents;

    } catch (e) {
      debugPrint('[ADMIN_AGENCE] ❌ Erreur récupération agents: $e');
      return [];
    }
  }

  /// 🔑 Générer un mot de passe automatique
  static String _generatePassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      8, (_) => chars.codeUnitAt(random.nextInt(chars.length))
    ));
  }
}
