import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/hierarchical_structure.dart';

/// 🏢 Service de gestion hiérarchique des admins
class HierarchicalAdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections Firestore
  static const String _compagniesCollection = 'compagnies_assurance';
  static const String _agencesCollection = 'agences_assurance';
  static const String _adminsCollection = 'admins_users';
  static const String _demandesCollection = 'demandes_agents';

  /// 🔍 Obtenir l'admin connecté actuel
  static Future<AdminUser?> getCurrentAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore
          .collection(_adminsCollection)
          .doc(user.uid)
          .get();

      if (doc.exists) {
        return AdminUser.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Erreur getCurrentAdmin: $e');
      return null;
    }
  }

  /// 📊 Obtenir les statistiques pour un admin
  static Future<Map<String, int>> getAdminStats(AdminUser admin) async {
    try {
      Query demandesQuery = _firestore.collection(_demandesCollection);
      Query agentsQuery = _firestore.collection('agents_assurance');

      // Filtrer selon le type d'admin
      switch (admin.type) {
        case AdminType.superAdmin:
          // Super admin voit tout
          break;
        case AdminType.compagnie:
          demandesQuery = demandesQuery.where('compagnieId', isEqualTo: admin.compagnieId);
          agentsQuery = agentsQuery.where('compagnieId', isEqualTo: admin.compagnieId);
          break;
        case AdminType.agence:
          demandesQuery = demandesQuery
              .where('compagnieId', isEqualTo: admin.compagnieId)
              .where('agenceId', isEqualTo: admin.agenceId);
          agentsQuery = agentsQuery
              .where('compagnieId', isEqualTo: admin.compagnieId)
              .where('agenceId', isEqualTo: admin.agenceId);
          break;
      }

      // Compter les demandes
      final demandesSnapshot = await demandesQuery.get();
      final agentsSnapshot = await agentsQuery.get();

      final demandesEnAttente = demandesSnapshot.docs
          .where((doc) => doc.data() is Map && (doc.data() as Map)['statut'] == 'enAttente')
          .length;

      final demandesApprouvees = demandesSnapshot.docs
          .where((doc) => doc.data() is Map && (doc.data() as Map)['statut'] == 'approuvee')
          .length;

      return {
        'totalDemandes': demandesSnapshot.docs.length,
        'demandesEnAttente': demandesEnAttente,
        'demandesApprouvees': demandesApprouvees,
        'totalAgents': agentsSnapshot.docs.length,
      };
    } catch (e) {
      print('❌ Erreur getAdminStats: $e');
      return {
        'totalDemandes': 0,
        'demandesEnAttente': 0,
        'demandesApprouvees': 0,
        'totalAgents': 0,
      };
    }
  }

  /// 📋 Obtenir les demandes pour un admin
  static Stream<List<DemandeAgent>> getDemandesForAdmin(AdminUser admin) {
    Query query = _firestore.collection(_demandesCollection);

    // Filtrer selon le type d'admin
    switch (admin.type) {
      case AdminType.superAdmin:
        // Super admin voit toutes les demandes
        break;
      case AdminType.compagnie:
        query = query.where('compagnieId', isEqualTo: admin.compagnieId);
        break;
      case AdminType.agence:
        query = query
            .where('compagnieId', isEqualTo: admin.compagnieId)
            .where('agenceId', isEqualTo: admin.agenceId);
        break;
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return DemandeAgent.fromMap(data);
      }).toList();
    });
  }

  /// ✅ Approuver une demande
  static Future<bool> approuverDemande(String demandeId, AdminUser admin, {String? commentaire}) async {
    try {
      // Vérifier que l'admin peut traiter cette demande
      final demandeDoc = await _firestore.collection(_demandesCollection).doc(demandeId).get();
      if (!demandeDoc.exists) return false;

      final demande = DemandeAgent.fromMap(demandeDoc.data()!);
      if (!admin.canManageRequest(demande.compagnieId, demande.agenceId)) {
        print('❌ Admin non autorisé à traiter cette demande');
        return false;
      }

      // Mettre à jour la demande
      await _firestore.collection(_demandesCollection).doc(demandeId).update({
        'statut': 'approuvee',
        'adminTraitantId': admin.id,
        'dateTraitement': DateTime.now().millisecondsSinceEpoch,
        'commentaire': commentaire,
      });

      // Créer le compte agent
      await _createAgentAccount(demande);

      return true;
    } catch (e) {
      print('❌ Erreur approuverDemande: $e');
      return false;
    }
  }

  /// ❌ Rejeter une demande
  static Future<bool> rejeterDemande(String demandeId, AdminUser admin, String raison) async {
    try {
      // Vérifier que l'admin peut traiter cette demande
      final demandeDoc = await _firestore.collection(_demandesCollection).doc(demandeId).get();
      if (!demandeDoc.exists) return false;

      final demande = DemandeAgent.fromMap(demandeDoc.data()!);
      if (!admin.canManageRequest(demande.compagnieId, demande.agenceId)) {
        print('❌ Admin non autorisé à traiter cette demande');
        return false;
      }

      // Mettre à jour la demande
      await _firestore.collection(_demandesCollection).doc(demandeId).update({
        'statut': 'rejetee',
        'adminTraitantId': admin.id,
        'dateTraitement': DateTime.now().millisecondsSinceEpoch,
        'commentaire': raison,
      });

      return true;
    } catch (e) {
      print('❌ Erreur rejeterDemande: $e');
      return false;
    }
  }

  /// 👤 Créer un compte agent après approbation
  static Future<void> _createAgentAccount(DemandeAgent demande) async {
    try {
      // Créer le document agent
      await _firestore.collection('agents_assurance').doc(demande.id).set({
        'id': demande.id,
        'nom': demande.nom,
        'prenom': demande.prenom,
        'email': demande.email,
        'telephone': demande.telephone,
        'cin': demande.cin,
        'compagnieId': demande.compagnieId,
        'agenceId': demande.agenceId,
        'dateCreation': DateTime.now().millisecondsSinceEpoch,
        'active': true,
        'role': 'agent_assurance',
      });

      print('✅ Compte agent créé pour: ${demande.email}');
    } catch (e) {
      print('❌ Erreur _createAgentAccount: $e');
    }
  }

  /// 🏢 Obtenir les compagnies
  static Future<List<CompagnieAssurance>> getCompagnies() async {
    try {
      final snapshot = await _firestore.collection(_compagniesCollection).get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CompagnieAssurance.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ Erreur getCompagnies: $e');
      return [];
    }
  }

  /// 🏪 Obtenir les agences d'une compagnie
  static Future<List<AgenceAssurance>> getAgences(String compagnieId) async {
    try {
      final snapshot = await _firestore
          .collection(_agencesCollection)
          .where('compagnieId', isEqualTo: compagnieId)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return AgenceAssurance.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ Erreur getAgences: $e');
      return [];
    }
  }

  /// 🔐 Connexion admin
  static Future<AdminUser?> loginAdmin(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return await getCurrentAdmin();
      }
      return null;
    } catch (e) {
      print('❌ Erreur loginAdmin: $e');
      return null;
    }
  }

  /// 📤 Déconnexion
  static Future<void> logout() async {
    await _auth.signOut();
  }
}
