import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../models/professional_request_model_final.dart';

/// 📝 Service pour gérer les demandes de comptes professionnels
class ProfessionalRequestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'professional_account_requests';

  /// 📋 Obtenir toutes les demandes
  static Future<List<ProfessionalRequestModel>> getAllRequests() async {
    try {
      debugPrint('[PROFESSIONAL_REQUEST] 📋 Récupération de toutes les demandes...');
      
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('dateCreation', descending: true)
          .get();

      final requests = querySnapshot.docs
          .map((doc) => ProfessionalRequestModel.fromFirestore(doc))
          .toList();

      debugPrint('[PROFESSIONAL_REQUEST] ✅ ${requests.length} demandes récupérées');
      return requests;

    } catch (e) {
      debugPrint('[PROFESSIONAL_REQUEST] ❌ Erreur récupération demandes: $e');
      return [];
    }
  }

  /// 📋 Obtenir les demandes par statut
  static Future<List<ProfessionalRequestModel>> getRequestsByStatus(String status) async {
    try {
      debugPrint('[PROFESSIONAL_REQUEST] 📋 Récupération demandes statut: $status');
      
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('statut', isEqualTo: status)
          .orderBy('dateCreation', descending: true)
          .get();

      final requests = querySnapshot.docs
          .map((doc) => ProfessionalRequestModel.fromFirestore(doc))
          .toList();

      debugPrint('[PROFESSIONAL_REQUEST] ✅ ${requests.length} demandes trouvées');
      return requests;

    } catch (e) {
      debugPrint('[PROFESSIONAL_REQUEST] ❌ Erreur récupération par statut: $e');
      return [];
    }
  }

  /// 📋 Obtenir les demandes en attente
  static Future<List<ProfessionalRequestModel>> getPendingRequests() async {
    return await getRequestsByStatus('en_attente');
  }

  /// 📋 Stream des demandes en temps réel
  static Stream<List<ProfessionalRequestModel>> getRequestsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('dateCreation', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProfessionalRequestModel.fromFirestore(doc))
            .toList());
  }

  /// 📋 Stream des demandes en attente
  static Stream<List<ProfessionalRequestModel>> getPendingRequestsStream() {
    return _firestore
        .collection(_collection)
        .where('statut', isEqualTo: 'en_attente')
        .orderBy('dateCreation', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProfessionalRequestModel.fromFirestore(doc))
            .toList());
  }

  /// ✅ Approuver une demande
  static Future<bool> approveRequest(
    String requestId,
    String adminId, {
    String? commentaire,
  }) async {
    try {
      debugPrint('[PROFESSIONAL_REQUEST] ✅ Approbation demande: $requestId');

      await _firestore.collection(_collection).doc(requestId).update({
        'statut': 'approuvee',
        'adminId': adminId,
        'dateTraitement': Timestamp.now(),
        'commentaireAdmin': commentaire,
      });

      debugPrint('[PROFESSIONAL_REQUEST] ✅ Demande approuvée avec succès');
      return true;

    } catch (e) {
      debugPrint('[PROFESSIONAL_REQUEST] ❌ Erreur approbation: $e');
      return false;
    }
  }

  /// ❌ Rejeter une demande
  static Future<bool> rejectRequest(
    String requestId,
    String adminId, {
    required String commentaire,
  }) async {
    try {
      debugPrint('[PROFESSIONAL_REQUEST] ❌ Rejet demande: $requestId');

      await _firestore.collection(_collection).doc(requestId).update({
        'statut': 'rejetee',
        'adminId': adminId,
        'dateTraitement': Timestamp.now(),
        'commentaireAdmin': commentaire,
      });

      debugPrint('[PROFESSIONAL_REQUEST] ✅ Demande rejetée avec succès');
      return true;

    } catch (e) {
      debugPrint('[PROFESSIONAL_REQUEST] ❌ Erreur rejet: $e');
      return false;
    }
  }

  /// 👤 Créer un compte utilisateur après approbation
  static Future<Map<String, dynamic>> createUserAccount(ProfessionalRequestModel request) async {
    try {
      debugPrint('[PROFESSIONAL_REQUEST] 👤 Création compte pour: ${request.email}');

      // 1. Générer un mot de passe temporaire
      final temporaryPassword = _generateTemporaryPassword();

      // 2. Créer le compte Firebase Auth
      final auth = FirebaseAuth.instance;
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: request.email,
        password: temporaryPassword,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Erreur lors de la création du compte Firebase Auth');
      }

      // 3. Préparer les données utilisateur
      final userData = {
        'uid': user.uid,
        'email': request.email,
        'nomComplet': request.nomComplet,
        'nom': request.nom,
        'prenom': request.prenom,
        'telephone': request.tel,
        'cin': request.cin,
        'role': request.roleDemande,
        'compagnieAssurance': request.compagnie ?? '',
        'agence': request.nomAgence ?? '',
        'zoneIntervention': request.zoneIntervention ?? '',
        'numAgrement': request.numAgrement ?? '',
        'adresseAgence': request.adresseAgence ?? '',
        'fonction': request.fonction ?? '',
        'ville': request.ville ?? '',
        'dateCreation': Timestamp.now(),
        'isActive': true,
        'isVerified': true,
        'requestId': request.id,
        'mustChangePassword': true, // Forcer le changement de mot de passe à la première connexion
      };

      // 4. Créer dans la collection appropriée selon le rôle
      String collection;
      switch (request.roleDemande) {
        case 'agent_agence':
          collection = 'agents_assurance';
          break;
        case 'expert_auto':
          collection = 'experts';
          break;
        case 'admin_compagnie':
          collection = 'admin_compagnies';
          break;
        case 'admin_agence':
          collection = 'admin_agences';
          break;
        default:
          collection = 'users';
      }

      await _firestore.collection(collection).doc(user.uid).set(userData);

      // 5. Mettre à jour le profil Firebase
      await user.updateDisplayName(request.nomComplet);

      debugPrint('[PROFESSIONAL_REQUEST] ✅ Compte créé avec succès');

      return {
        'success': true,
        'uid': user.uid,
        'email': request.email,
        'temporaryPassword': temporaryPassword,
        'collection': collection,
      };

    } catch (e) {
      debugPrint('[PROFESSIONAL_REQUEST] ❌ Erreur création compte: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🔐 Générer un mot de passe temporaire sécurisé
  static String _generateTemporaryPassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final random = Random();

    // Générer un mot de passe de 12 caractères
    String password = '';
    for (int i = 0; i < 12; i++) {
      password += chars[random.nextInt(chars.length)];
    }

    // S'assurer qu'il contient au moins une majuscule, une minuscule, un chiffre et un caractère spécial
    if (!password.contains(RegExp(r'[A-Z]'))) {
      password = password.replaceRange(0, 1, 'A');
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      password = password.replaceRange(1, 2, 'a');
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      password = password.replaceRange(2, 3, '1');
    }
    if (!password.contains(RegExp(r'[!@#\$%^&*]'))) {
      password = password.replaceRange(3, 4, '!');
    }

    return password;
  }

  /// 📊 Obtenir les statistiques des demandes
  static Future<Map<String, int>> getRequestsStats() async {
    try {
      debugPrint('[PROFESSIONAL_REQUEST] 📊 Récupération statistiques...');

      final futures = await Future.wait([
        _firestore.collection(_collection).where('statut', isEqualTo: 'en_attente').get(),
        _firestore.collection(_collection).where('statut', isEqualTo: 'approuvee').get(),
        _firestore.collection(_collection).where('statut', isEqualTo: 'rejetee').get(),
        _firestore.collection(_collection).where('typeCompte', isEqualTo: 'agent').get(),
        _firestore.collection(_collection).where('typeCompte', isEqualTo: 'expert').get(),
      ]);

      final stats = {
        'en_attente': futures[0].docs.length,
        'approuvees': futures[1].docs.length,
        'rejetees': futures[2].docs.length,
        'agents': futures[3].docs.length,
        'experts': futures[4].docs.length,
        'total': futures[0].docs.length + futures[1].docs.length + futures[2].docs.length,
      };

      debugPrint('[PROFESSIONAL_REQUEST] ✅ Statistiques: $stats');
      return stats;

    } catch (e) {
      debugPrint('[PROFESSIONAL_REQUEST] ❌ Erreur statistiques: $e');
      return {
        'en_attente': 0,
        'approuvees': 0,
        'rejetees': 0,
        'agents': 0,
        'experts': 0,
        'total': 0,
      };
    }
  }

  /// 🔍 Rechercher des demandes
  static Future<List<ProfessionalRequestModel>> searchRequests(String query) async {
    try {
      debugPrint('[PROFESSIONAL_REQUEST] 🔍 Recherche: $query');

      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('dateCreation', descending: true)
          .get();

      final allRequests = querySnapshot.docs
          .map((doc) => ProfessionalRequestModel.fromFirestore(doc))
          .toList();

      // Filtrer localement (Firestore ne supporte pas la recherche textuelle complexe)
      final filteredRequests = allRequests.where((request) {
        final searchTerm = query.toLowerCase();
        return request.nom.toLowerCase().contains(searchTerm) ||
               request.prenom.toLowerCase().contains(searchTerm) ||
               request.email.toLowerCase().contains(searchTerm) ||
               request.telephone.contains(searchTerm) ||
               request.compagnieAssurance.toLowerCase().contains(searchTerm) ||
               request.agence.toLowerCase().contains(searchTerm);
      }).toList();

      debugPrint('[PROFESSIONAL_REQUEST] ✅ ${filteredRequests.length} résultats trouvés');
      return filteredRequests;

    } catch (e) {
      debugPrint('[PROFESSIONAL_REQUEST] ❌ Erreur recherche: $e');
      return [];
    }
  }

  /// 📝 Obtenir une demande par ID
  static Future<ProfessionalRequestModel?> getRequestById(String requestId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(requestId).get();
      
      if (doc.exists) {
        return ProfessionalRequestModel.fromFirestore(doc);
      }
      return null;

    } catch (e) {
      debugPrint('[PROFESSIONAL_REQUEST] ❌ Erreur récupération demande: $e');
      return null;
    }
  }

  /// 🗑️ Supprimer une demande
  static Future<bool> deleteRequest(String requestId) async {
    try {
      await _firestore.collection(_collection).doc(requestId).delete();
      debugPrint('[PROFESSIONAL_REQUEST] ✅ Demande supprimée: $requestId');
      return true;

    } catch (e) {
      debugPrint('[PROFESSIONAL_REQUEST] ❌ Erreur suppression: $e');
      return false;
    }
  }
}
