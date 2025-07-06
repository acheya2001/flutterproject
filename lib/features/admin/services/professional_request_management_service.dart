import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/foundation.dart';
import '../models/professional_request_model_final.dart';
// import '../../../core/services/email_notification_service.dart'; // Remplacé par approval_email_service
import '../../../core/services/approval_email_service.dart';
import 'dart:math';

/// 🔧 Service de gestion des demandes professionnelles pour les admins
class ProfessionalRequestManagementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _requestsCollection = 'demandes_professionnels';
  static const String _usersCollection = 'users';

  /// 📋 Obtenir toutes les demandes en attente
  static Stream<List<ProfessionalRequestModel>> getPendingRequests() {
    return _firestore
        .collection(_requestsCollection)
        .where('status', isEqualTo: 'en_attente')
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => ProfessionalRequestModel.fromFirestore(doc))
              .toList();

          // Trier côté client pour éviter les problèmes d'index
          requests.sort((a, b) => b.envoyeLe.compareTo(a.envoyeLe));
          return requests;
        });
  }

  /// 📋 Obtenir toutes les demandes (avec filtres)
  static Stream<List<ProfessionalRequestModel>> getAllRequests({
    String? status,
    String? role,
    int? limit,
  }) {
    Query query = _firestore.collection(_requestsCollection);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    if (role != null) {
      query = query.where('role_demande', isEqualTo: role);
    }

    // Pas d'orderBy pour éviter les problèmes d'index
    // Le tri sera fait côté client

    return query.snapshots().map((snapshot) {
      var requests = snapshot.docs
          .map((doc) => ProfessionalRequestModel.fromFirestore(doc))
          .toList();

      // Trier côté client par date
      requests.sort((a, b) => b.envoyeLe.compareTo(a.envoyeLe));

      // Appliquer la limite si spécifiée
      if (limit != null && requests.length > limit) {
        requests = requests.take(limit).toList();
      }

      return requests;
    });
  }

  /// ✅ Approuver une demande
  static Future<bool> approveRequest({
    required String requestId,
    required String adminId,
    String? commentaire,
  }) async {
    try {
      debugPrint('[REQUEST_MANAGEMENT] ✅ Approbation demande: $requestId');

      // Récupérer la demande
      final requestDoc = await _firestore
          .collection(_requestsCollection)
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Demande introuvable');
      }

      final request = ProfessionalRequestModel.fromFirestore(requestDoc);

      // Générer un mot de passe temporaire
      final motDePasse = _generateTemporaryPassword();

      // Créer le compte utilisateur
      final userId = await _createUserAccount(request, motDePasse);

      if (userId == null) {
        throw Exception('Erreur lors de la création du compte');
      }

      // Mettre à jour le statut de la demande
      await _firestore.collection(_requestsCollection).doc(requestId).update({
        'status': 'acceptee',
        'approuve_par': adminId,
        'approuve_le': FieldValue.serverTimestamp(),
        'commentaire_admin': commentaire,
        'user_id_cree': userId,
        'mot_de_passe_temporaire': motDePasse,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Envoyer l'email de confirmation avec le nouveau service
      final emailSent = await ApprovalEmailService.sendApprovalEmail(
        toEmail: request.email,
        nomComplet: request.nomComplet,
        role: request.roleFormate,
        motDePasseTemporaire: motDePasse,
      );

      if (!emailSent) {
        debugPrint('[REQUEST_MANAGEMENT] ⚠️ Email non envoyé mais compte créé');
      }

      // Créer une notification pour l'utilisateur
      await _createUserNotification(
        userId: userId,
        title: 'Compte approuvé',
        message: 'Votre demande de compte professionnel a été approuvée. Vérifiez votre email pour les détails de connexion.',
        type: 'account_approved',
      );

      debugPrint('[REQUEST_MANAGEMENT] ✅ Demande approuvée avec succès');
      return true;

    } catch (e) {
      debugPrint('[REQUEST_MANAGEMENT] ❌ Erreur approbation: $e');
      return false;
    }
  }

  /// ❌ Rejeter une demande
  static Future<bool> rejectRequest({
    required String requestId,
    required String adminId,
    required String motifRejet,
    String? commentaire,
  }) async {
    try {
      debugPrint('[REQUEST_MANAGEMENT] ❌ Rejet demande: $requestId');

      // Récupérer la demande
      final requestDoc = await _firestore
          .collection(_requestsCollection)
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Demande introuvable');
      }

      final request = ProfessionalRequestModel.fromFirestore(requestDoc);

      // Mettre à jour le statut de la demande
      await _firestore.collection(_requestsCollection).doc(requestId).update({
        'status': 'rejetee',
        'rejete_par': adminId,
        'rejete_le': FieldValue.serverTimestamp(),
        'motif_rejet': motifRejet,
        'commentaire_admin': commentaire,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Envoyer l'email de rejet avec le nouveau service
      final emailSent = await ApprovalEmailService.sendRejectionEmail(
        toEmail: request.email,
        nomComplet: request.nomComplet,
        role: request.roleFormate,
        motifRejet: motifRejet,
      );

      if (!emailSent) {
        debugPrint('[REQUEST_MANAGEMENT] ⚠️ Email de rejet non envoyé');
      }

      debugPrint('[REQUEST_MANAGEMENT] ✅ Demande rejetée avec succès');
      return true;

    } catch (e) {
      debugPrint('[REQUEST_MANAGEMENT] ❌ Erreur rejet: $e');
      return false;
    }
  }

  /// 👤 Créer un compte utilisateur
  static Future<String?> _createUserAccount(
    ProfessionalRequestModel request,
    String motDePasse,
  ) async {
    try {
      // Créer l'utilisateur dans Firestore (pas dans Auth pour l'instant)
      final userDoc = await _firestore.collection(_usersCollection).add({
        'email': request.email.toLowerCase().trim(),
        'nom_complet': request.nomComplet,
        'telephone': request.tel,
        'cin': request.cin,
        'role': request.roleDemande,
        'status': 'actif',
        'mot_de_passe_temporaire': motDePasse,
        'doit_changer_mot_de_passe': true,
        'created_from_request': true,
        'request_id': request.id,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        
        // Données spécifiques selon le rôle
        if (request.roleDemande == 'agent_agence') ...{
          'nom_agence': request.nomAgence,
          'compagnie': request.compagnie,
          'adresse_agence': request.adresseAgence,
          'ville': request.ville,
        },
        if (request.roleDemande == 'expert_auto') ...{
          'num_agrement': request.numAgrement,
          'compagnie': request.compagnie,
          'zone_intervention': request.zoneIntervention,
          'experience_annees': request.experienceAnnees,
        },
        if (request.roleDemande == 'admin_compagnie') ...{
          'nom_compagnie': request.nomCompagnie,
          'fonction': request.fonction,
          'adresse_siege': request.adresseSiege,
        },
        if (request.roleDemande == 'admin_agence') ...{
          'nom_agence': request.nomAgence,
          'compagnie': request.compagnie,
          'ville': request.ville,
          'adresse_agence': request.adresseAgence,
        },
      });

      return userDoc.id;
    } catch (e) {
      debugPrint('[REQUEST_MANAGEMENT] ❌ Erreur création utilisateur: $e');
      return null;
    }
  }

  /// 🔐 Générer un mot de passe temporaire
  static String _generateTemporaryPassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      12,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }

  /// 🔔 Créer une notification pour l'utilisateur
  static Future<void> _createUserNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      await _firestore.collection('user_notifications').add({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[REQUEST_MANAGEMENT] ❌ Erreur notification: $e');
    }
  }

  /// 📊 Obtenir les statistiques des demandes
  static Future<Map<String, dynamic>> getRequestsStats() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final futures = await Future.wait([
        // Total des demandes
        _firestore.collection(_requestsCollection).get(),
        
        // Demandes en attente
        _firestore
            .collection(_requestsCollection)
            .where('status', isEqualTo: 'en_attente')
            .get(),
        
        // Demandes ce mois
        _firestore
            .collection(_requestsCollection)
            .where('envoye_le', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
            .get(),
      ]);

      final totalDocs = futures[0].docs;
      final pendingDocs = futures[1].docs;
      final thisMonthDocs = futures[2].docs;

      // Calculer les statistiques par statut
      final statusStats = <String, int>{
        'en_attente': 0,
        'acceptee': 0,
        'rejetee': 0,
      };

      // Calculer les statistiques par rôle
      final roleStats = <String, int>{
        'agent_agence': 0,
        'expert_auto': 0,
        'admin_compagnie': 0,
        'admin_agence': 0,
      };

      for (final doc in totalDocs) {
        final data = doc.data();
        final status = data['status'] ?? 'en_attente';
        final role = data['role_demande'] ?? '';

        statusStats[status] = (statusStats[status] ?? 0) + 1;
        roleStats[role] = (roleStats[role] ?? 0) + 1;
      }

      return {
        'total': totalDocs.length,
        'pending': pendingDocs.length,
        'this_month': thisMonthDocs.length,
        'by_status': statusStats,
        'by_role': roleStats,
        'approval_rate': totalDocs.isNotEmpty 
            ? ((statusStats['acceptee'] ?? 0) / totalDocs.length * 100).round()
            : 0,
      };

    } catch (e) {
      debugPrint('[REQUEST_MANAGEMENT] ❌ Erreur statistiques: $e');
      return {
        'total': 0,
        'pending': 0,
        'this_month': 0,
        'by_status': {},
        'by_role': {},
        'approval_rate': 0,
      };
    }
  }

  /// 🔍 Rechercher des demandes
  static Future<List<ProfessionalRequestModel>> searchRequests(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection(_requestsCollection)
          .orderBy('envoye_le', descending: true)
          .get();

      final allRequests = querySnapshot.docs
          .map((doc) => ProfessionalRequestModel.fromFirestore(doc))
          .toList();

      // Filtrer localement (Firestore ne supporte pas la recherche textuelle complexe)
      final filteredRequests = allRequests.where((request) {
        final searchTerm = query.toLowerCase();
        return request.nomComplet.toLowerCase().contains(searchTerm) ||
               request.email.toLowerCase().contains(searchTerm) ||
               request.tel.contains(searchTerm) ||
               request.cin.contains(searchTerm) ||
               request.roleFormate.toLowerCase().contains(searchTerm);
      }).toList();

      return filteredRequests;
    } catch (e) {
      debugPrint('[REQUEST_MANAGEMENT] ❌ Erreur recherche: $e');
      return [];
    }
  }
}
