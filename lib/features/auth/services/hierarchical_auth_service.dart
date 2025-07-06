import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/assureur_model.dart';
import '../../../utils/user_type.dart';

/// 🏢 Service d'authentification hiérarchique pour les assureurs
/// Gère la hiérarchie : Compagnie → Agence → Agent
class HierarchicalAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔐 Connexion d'un agent avec validation hiérarchique
  Future<AssureurModel?> signInAgent({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[HierarchicalAuth] Tentative de connexion agent: $email');

      // 1. Authentification Firebase
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        debugPrint('[HierarchicalAuth] Utilisateur Firebase null');
        return null;
      }

      // 2. Vérifier le type d'utilisateur
      final userTypeDoc = await _firestore.collection('user_types').doc(firebaseUser.uid).get();
      if (!userTypeDoc.exists || userTypeDoc.data()?['type'] != 'assureur') {
        debugPrint('[HierarchicalAuth] Utilisateur non autorisé ou pas un assureur');
        await _auth.signOut();
        throw Exception('Accès non autorisé. Seuls les agents d\'assurance peuvent se connecter ici.');
      }

      // 3. Récupérer les données de l'agent
      final assureurDoc = await _firestore.collection('assureurs').doc(firebaseUser.uid).get();
      if (!assureurDoc.exists) {
        debugPrint('[HierarchicalAuth] Document assureur non trouvé');
        await _auth.signOut();
        throw Exception('Profil agent non trouvé. Contactez votre administrateur.');
      }

      final assureurData = assureurDoc.data()!;
      
      // 4. Valider la hiérarchie (Agence existe et est active)
      final agenceId = assureurData['agence'] as String?;
      if (agenceId == null || agenceId.isEmpty) {
        debugPrint('[HierarchicalAuth] Agent sans agence assignée');
        await _auth.signOut();
        throw Exception('Aucune agence assignée. Contactez votre responsable.');
      }

      final agenceDoc = await _firestore.collection('agences').doc(agenceId).get();
      if (!agenceDoc.exists) {
        debugPrint('[HierarchicalAuth] Agence non trouvée: $agenceId');
        await _auth.signOut();
        throw Exception('Agence non trouvée. Contactez votre administrateur.');
      }

      final agenceData = agenceDoc.data()!;
      if (agenceData['statut'] != 'active') {
        debugPrint('[HierarchicalAuth] Agence inactive: $agenceId');
        await _auth.signOut();
        throw Exception('Agence inactive. Contactez votre responsable.');
      }

      // 5. Valider la compagnie
      final compagnieCode = agenceData['compagnie'] as String;
      final compagnieDoc = await _firestore.collection('insurance_companies').doc(compagnieCode.toLowerCase()).get();
      if (!compagnieDoc.exists) {
        debugPrint('[HierarchicalAuth] Compagnie non trouvée: $compagnieCode');
        await _auth.signOut();
        throw Exception('Compagnie non trouvée. Contactez votre administrateur.');
      }

      final compagnieData = compagnieDoc.data()!;
      if (compagnieData['statut'] != 'active') {
        debugPrint('[HierarchicalAuth] Compagnie inactive: $compagnieCode');
        await _auth.signOut();
        throw Exception('Compagnie inactive. Contactez votre responsable.');
      }

      // 6. Vérifier le statut de l'agent
      if (assureurData['statut'] != 'actif') {
        debugPrint('[HierarchicalAuth] Agent inactif: ${firebaseUser.uid}');
        await _auth.signOut();
        throw Exception('Compte agent inactif. Contactez votre responsable.');
      }

      // 7. Créer le modèle AssureurModel avec toutes les informations hiérarchiques
      final assureurModel = AssureurModel(
        id: firebaseUser.uid,
        email: assureurData['email'] ?? firebaseUser.email ?? '',
        nom: assureurData['nom'] ?? '',
        prenom: assureurData['prenom'] ?? '',
        telephone: assureurData['telephone'] ?? '',
        compagnie: compagnieCode,
        matricule: assureurData['matricule'] ?? '',
        agenceId: agenceId,
        agenceNom: agenceData['nom'] ?? '',
        gouvernorat: agenceData['gouvernorat'] ?? '',
        poste: assureurData['poste'] ?? 'Agent Commercial',
        permissions: List<String>.from(assureurData['permissions'] ?? ['view_contracts', 'create_contracts']),
        dossierIds: List<String>.from(assureurData['dossierIds'] ?? []),
        dateEmbauche: assureurData['date_embauche'] != null 
            ? (assureurData['date_embauche'] as Timestamp).toDate() 
            : null,
        statut: assureurData['statut'] ?? 'actif',
        adresse: assureurData['adresse'],
        createdAt: (assureurData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (assureurData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

      // 8. Mettre à jour la dernière connexion
      await _firestore.collection('assureurs').doc(firebaseUser.uid).update({
        'derniere_connexion': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[HierarchicalAuth] Connexion réussie: ${assureurModel.nomComplet} - ${assureurModel.agenceNom}');
      return assureurModel;

    } catch (e) {
      debugPrint('[HierarchicalAuth] Erreur lors de la connexion: $e');
      rethrow;
    }
  }

  /// 📊 Récupérer les informations hiérarchiques d'un agent
  Future<Map<String, dynamic>> getAgentHierarchy(String agentId) async {
    try {
      final assureurDoc = await _firestore.collection('assureurs').doc(agentId).get();
      if (!assureurDoc.exists) {
        throw Exception('Agent non trouvé');
      }

      final assureurData = assureurDoc.data()!;
      final agenceId = assureurData['agence'] as String;
      
      final agenceDoc = await _firestore.collection('agences').doc(agenceId).get();
      final agenceData = agenceDoc.data()!;
      
      final compagnieCode = agenceData['compagnie'] as String;
      final compagnieDoc = await _firestore.collection('insurance_companies').doc(compagnieCode.toLowerCase()).get();
      final compagnieData = compagnieDoc.data()!;

      return {
        'agent': assureurData,
        'agence': agenceData,
        'compagnie': compagnieData,
        'hierarchy': {
          'compagnie_nom': compagnieData['nom'],
          'agence_nom': agenceData['nom'],
          'gouvernorat': agenceData['gouvernorat'],
          'agent_nom': '${assureurData['prenom']} ${assureurData['nom']}',
          'poste': assureurData['poste'],
        }
      };
    } catch (e) {
      debugPrint('[HierarchicalAuth] Erreur récupération hiérarchie: $e');
      rethrow;
    }
  }

  /// 🏢 Récupérer tous les agents d'une agence
  Future<List<AssureurModel>> getAgentsInAgence(String agenceId) async {
    try {
      final querySnapshot = await _firestore
          .collection('assureurs')
          .where('agence', isEqualTo: agenceId)
          .where('statut', isEqualTo: 'actif')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return AssureurModel.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('[HierarchicalAuth] Erreur récupération agents agence: $e');
      return [];
    }
  }

  /// 🌍 Récupérer toutes les agences d'une compagnie dans un gouvernorat
  Future<List<Map<String, dynamic>>> getAgencesInGouvernorat(String compagnie, String gouvernorat) async {
    try {
      final querySnapshot = await _firestore
          .collection('agences')
          .where('compagnie', isEqualTo: compagnie)
          .where('gouvernorat', isEqualTo: gouvernorat)
          .where('statut', isEqualTo: 'active')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('[HierarchicalAuth] Erreur récupération agences: $e');
      return [];
    }
  }

  /// 🔍 Vérifier les permissions d'un agent
  bool hasPermission(AssureurModel agent, String permission) {
    return agent.permissions.contains(permission) || 
           agent.poste == 'Responsable Agence' || 
           agent.poste == 'Superviseur';
  }

  /// 📈 Récupérer les statistiques d'une agence
  Future<Map<String, int>> getAgenceStats(String agenceId) async {
    try {
      // Nombre d'agents
      final agentsSnapshot = await _firestore
          .collection('assureurs')
          .where('agence', isEqualTo: agenceId)
          .where('statut', isEqualTo: 'actif')
          .get();

      // Nombre de contrats créés par cette agence
      final contractsSnapshot = await _firestore
          .collection('contracts')
          .where('agence.id', isEqualTo: agenceId)
          .get();

      // Contrats actifs
      final activeContractsSnapshot = await _firestore
          .collection('contracts')
          .where('agence.id', isEqualTo: agenceId)
          .where('statut', isEqualTo: 'actif')
          .get();

      return {
        'agents': agentsSnapshot.docs.length,
        'contrats_total': contractsSnapshot.docs.length,
        'contrats_actifs': activeContractsSnapshot.docs.length,
      };
    } catch (e) {
      debugPrint('[HierarchicalAuth] Erreur récupération stats agence: $e');
      return {'agents': 0, 'contrats_total': 0, 'contrats_actifs': 0};
    }
  }
}
