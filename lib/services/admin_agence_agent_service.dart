import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

/// 👥 Service de gestion des agents pour Admin Agence
class AdminAgenceAgentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 👤 Créer un nouvel agent
  static Future<Map<String, dynamic>> createAgent({
    required String agenceId,
    required String agenceNom,
    required String compagnieId,
    required String compagnieNom,
    required String prenom,
    required String nom,
    required String telephone,
    required String cin,
    String? email,
    String? adresse,
  }) async {
    try {
      debugPrint('[ADMIN_AGENCE_AGENT] 👤 Création agent: $prenom $nom');

      // Vérifier si le CIN existe déjà
      final existingCinQuery = await _firestore
          .collection('users')
          .where('cin', isEqualTo: cin)
          .where('role', isEqualTo: 'agent')
          .get();

      if (existingCinQuery.docs.isNotEmpty) {
        return {
          'success': false,
          'error': 'Un agent avec ce CIN existe déjà',
        };
      }

      // Générer l'email si non fourni
      final finalEmail = email ?? _generateAgentEmail(prenom, nom, agenceNom);
      
      // Vérifier si l'email existe déjà
      final existingEmailQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: finalEmail)
          .get();

      if (existingEmailQuery.docs.isNotEmpty) {
        return {
          'success': false,
          'error': 'Un utilisateur avec cet email existe déjà',
        };
      }

      // Générer un mot de passe
      final password = _generatePassword();

      // Générer un UID unique
      final uid = _generateUID();

      // Générer un code agent
      final codeAgent = _generateAgentCode(agenceNom, prenom, nom);

      // Données de l'agent
      final agentData = {
        'uid': uid,
        'email': finalEmail,
        'password': password,
        'prenom': prenom,
        'nom': nom,
        'telephone': telephone,
        'cin': cin,
        'adresse': adresse ?? '',
        'codeAgent': codeAgent,
        'role': 'agent',
        'agenceId': agenceId,
        'agenceNom': agenceNom,
        'compagnieId': compagnieId,
        'compagnieNom': compagnieNom,
        'isActive': true,
        'status': 'actif',
        'firebaseAuthCreated': false,
        'nombreConstats': 0,
        'dernierConstAt': null,
        'created_at': FieldValue.serverTimestamp(),
        'createdBy': 'admin_agence',
        'origin': 'admin_agence_creation',
      };

      // Créer l'agent dans Firestore
      await _firestore.collection('users').doc(uid).set(agentData);

      // Mettre à jour le compteur d'agents dans l'agence
      await _firestore.collection('agences').doc(agenceId).update({
        'nombreAgents': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[ADMIN_AGENCE_AGENT] ✅ Agent créé: $finalEmail');

      return {
        'success': true,
        'email': finalEmail,
        'password': password,
        'agentId': uid,
        'codeAgent': codeAgent,
        'displayName': '$prenom $nom',
        'message': 'Agent créé avec succès',
      };

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_AGENT] ❌ Erreur création agent: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de la création de l\'agent',
      };
    }
  }

  /// 📋 Récupérer les agents d'une agence
  static Future<List<Map<String, dynamic>>> getAgentsByAgence(String agenceId) async {
    try {
      debugPrint('[ADMIN_AGENCE_AGENT] 📋 Récupération agents pour agence: $agenceId');

      final agentsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('agenceId', isEqualTo: agenceId)
          .orderBy('created_at', descending: true)
          .get();

      final agents = agentsQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      debugPrint('[ADMIN_AGENCE_AGENT] ✅ ${agents.length} agents récupérés');
      return agents;

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_AGENT] ❌ Erreur récupération agents: $e');
      return [];
    }
  }

  /// ✏️ Modifier un agent
  static Future<Map<String, dynamic>> updateAgent({
    required String agentId,
    required String prenom,
    required String nom,
    required String telephone,
    required String cin,
    String? email,
    String? adresse,
  }) async {
    try {
      debugPrint('[ADMIN_AGENCE_AGENT] ✏️ Modification agent: $agentId');

      final updateData = {
        'prenom': prenom,
        'nom': nom,
        'telephone': telephone,
        'cin': cin,
        'adresse': adresse ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (email != null && email.isNotEmpty) {
        updateData['email'] = email;
      }

      await _firestore.collection('users').doc(agentId).update(updateData);

      debugPrint('[ADMIN_AGENCE_AGENT] ✅ Agent modifié: $agentId');

      return {
        'success': true,
        'message': 'Agent modifié avec succès',
      };

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_AGENT] ❌ Erreur modification agent: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de la modification de l\'agent',
      };
    }
  }

  /// 🔄 Activer/Désactiver un agent
  static Future<Map<String, dynamic>> toggleAgentStatus(String agentId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(agentId).update({
        'isActive': isActive,
        'status': isActive ? 'actif' : 'inactif',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': isActive ? 'Agent activé' : 'Agent désactivé',
      };

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_AGENT] ❌ Erreur toggle agent: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🔑 Réinitialiser le mot de passe d'un agent
  static Future<Map<String, dynamic>> resetAgentPassword(String agentId) async {
    try {
      debugPrint('[ADMIN_AGENCE_AGENT] 🔑 Réinitialisation mot de passe: $agentId');

      // Générer un nouveau mot de passe
      final newPassword = _generatePassword();

      await _firestore.collection('users').doc(agentId).update({
        'password': newPassword,
        'firebaseAuthCreated': false, // Forcer la recréation du compte Firebase Auth
        'passwordResetAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[ADMIN_AGENCE_AGENT] ✅ Mot de passe réinitialisé: $agentId');

      return {
        'success': true,
        'newPassword': newPassword,
        'message': 'Mot de passe réinitialisé avec succès',
      };

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_AGENT] ❌ Erreur réinitialisation: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de la réinitialisation du mot de passe',
      };
    }
  }

  /// 🗑️ Supprimer un agent
  static Future<Map<String, dynamic>> deleteAgent(String agentId, String agenceId) async {
    try {
      debugPrint('[ADMIN_AGENCE_AGENT] 🗑️ Suppression agent: $agentId');

      // Supprimer l'agent
      await _firestore.collection('users').doc(agentId).delete();

      // Décrémenter le compteur d'agents dans l'agence
      await _firestore.collection('agences').doc(agenceId).update({
        'nombreAgents': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[ADMIN_AGENCE_AGENT] ✅ Agent supprimé: $agentId');

      return {
        'success': true,
        'message': 'Agent supprimé avec succès',
      };

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_AGENT] ❌ Erreur suppression agent: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de la suppression de l\'agent',
      };
    }
  }

  /// 📊 Récupérer les statistiques d'une agence
  static Future<Map<String, dynamic>> getAgenceStats(String agenceId) async {
    try {
      debugPrint('[ADMIN_AGENCE_AGENT] 📊 Récupération stats agence: $agenceId');

      // Compter les agents
      final agentsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('agenceId', isEqualTo: agenceId)
          .get();

      final agentsActifs = agentsQuery.docs.where((doc) => doc.data()['isActive'] == true).length;
      final agentsInactifs = agentsQuery.docs.length - agentsActifs;

      // Compter les constats
      final constatsQuery = await _firestore
          .collection('constats')
          .where('agenceId', isEqualTo: agenceId)
          .get();

      final constatsEnAttente = constatsQuery.docs.where((doc) => doc.data()['statut'] == 'en_attente').length;
      final constatsValides = constatsQuery.docs.where((doc) => doc.data()['statut'] == 'valide').length;

      final stats = {
        'totalAgents': agentsQuery.docs.length,
        'agentsActifs': agentsActifs,
        'agentsInactifs': agentsInactifs,
        'totalConstats': constatsQuery.docs.length,
        'constatsEnAttente': constatsEnAttente,
        'constatsValides': constatsValides,
      };

      debugPrint('[ADMIN_AGENCE_AGENT] ✅ Stats récupérées: $stats');
      return stats;

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_AGENT] ❌ Erreur stats: $e');
      return {
        'totalAgents': 0,
        'agentsActifs': 0,
        'agentsInactifs': 0,
        'totalConstats': 0,
        'constatsEnAttente': 0,
        'constatsValides': 0,
      };
    }
  }

  // Méthodes utilitaires privées
  static String _generateAgentEmail(String prenom, String nom, String agenceNom) {
    final prenomClean = prenom.toLowerCase().replaceAll(' ', '');
    final nomClean = nom.toLowerCase().replaceAll(' ', '');
    final agenceClean = agenceNom.toLowerCase().replaceAll(' ', '').replaceAll('agence', '');
    return '$prenomClean.$nomClean.$agenceClean@agent.tn';
  }

  static String _generateAgentCode(String agenceNom, String prenom, String nom) {
    final agenceCode = agenceNom.substring(0, 3).toUpperCase();
    final prenomCode = prenom.substring(0, 2).toUpperCase();
    final nomCode = nom.substring(0, 2).toUpperCase();
    final random = Random().nextInt(999).toString().padLeft(3, '0');
    return '$agenceCode-$prenomCode$nomCode-$random';
  }

  static String _generatePassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      12, (_) => chars.codeUnitAt(random.nextInt(chars.length))
    ));
  }

  static String _generateUID() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      20, (_) => chars.codeUnitAt(random.nextInt(chars.length))
    ));
  }
}
