import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/firebase_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/enums/app_enums.dart';
import '../../../shared/models/user_model.dart';
import '../models/account_request_model.dart';

/// 📋 Service pour gérer les demandes de comptes professionnels
class AccountRequestService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseAuth _auth = FirebaseService.auth;

  /// 📤 Soumettre une nouvelle demande
  Future<void> submitRequest(AccountRequestModel request) async {
    try {
      // Vérifier si une demande existe déjà pour cet email
      final existingRequest = await _firestore
          .collection(AppConstants.accountRequestsCollection)
          .where('email', isEqualTo: request.email)
          .where('status', isEqualTo: RequestStatus.pending.name)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        throw Exception('Une demande est déjà en cours de traitement pour cet email');
      }

      // Vérifier si un utilisateur existe déjà avec cet email
      final existingUser = await _firestore
          .collection(AppConstants.usersCollection)
          .where('email', isEqualTo: request.email)
          .get();

      if (existingUser.docs.isNotEmpty) {
        throw Exception('Un compte existe déjà avec cet email');
      }

      // Créer la demande
      await _firestore
          .collection(AppConstants.accountRequestsCollection)
          .add(request.toFirestore());

      debugPrint('[ACCOUNT_REQUEST_SERVICE] Demande créée pour: ${request.email}');
    } catch (e) {
      debugPrint('[ACCOUNT_REQUEST_SERVICE] Erreur lors de la création: $e');
      rethrow;
    }
  }

  /// 📋 Récupérer toutes les demandes (pour admin)
  Future<List<AccountRequestModel>> getAllRequests() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.accountRequestsCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AccountRequestModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('[ACCOUNT_REQUEST_SERVICE] Erreur lors de la récupération: $e');
      rethrow;
    }
  }

  /// 📋 Récupérer les demandes en attente
  Future<List<AccountRequestModel>> getPendingRequests() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.accountRequestsCollection)
          .where('status', isEqualTo: RequestStatus.pending.name)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AccountRequestModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('[ACCOUNT_REQUEST_SERVICE] Erreur lors de la récupération des demandes en attente: $e');
      rethrow;
    }
  }

  /// ✅ Approuver une demande et créer le compte
  Future<void> approveRequest(String requestId, String adminId) async {
    try {
      // Récupérer la demande
      final requestDoc = await _firestore
          .collection(AppConstants.accountRequestsCollection)
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Demande introuvable');
      }

      final request = AccountRequestModel.fromFirestore(requestDoc);

      if (!request.isPending) {
        throw Exception('Cette demande a déjà été traitée');
      }

      // Créer le compte utilisateur dans Firebase Auth
      final tempPassword = _generateTemporaryPassword();
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: request.email,
        password: tempPassword,
      );

      final userId = userCredential.user!.uid;

      // Créer le modèle utilisateur
      final userModel = UserModel(
        id: userId,
        email: request.email,
        firstName: request.firstName,
        lastName: request.lastName,
        phone: request.phone,
        role: request.accountType.userRole,
        status: AccountStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: adminId,
        cin: request.cin,
        address: request.address,
      );

      // Transaction pour créer l'utilisateur et mettre à jour la demande
      await _firestore.runTransaction((transaction) async {
        // Créer l'utilisateur
        transaction.set(
          _firestore.collection(AppConstants.usersCollection).doc(userId),
          userModel.toFirestore(),
        );

        // Mettre à jour la demande
        transaction.update(
          _firestore.collection(AppConstants.accountRequestsCollection).doc(requestId),
          {
            'status': RequestStatus.approved.name,
            'processedAt': FieldValue.serverTimestamp(),
            'processedBy': adminId,
          },
        );
      });

      // TODO: Envoyer un email avec les informations de connexion
      await _sendApprovalEmail(request, tempPassword);

      debugPrint('[ACCOUNT_REQUEST_SERVICE] Demande approuvée et compte créé: ${request.email}');
    } catch (e) {
      debugPrint('[ACCOUNT_REQUEST_SERVICE] Erreur lors de l\'approbation: $e');
      rethrow;
    }
  }

  /// ❌ Rejeter une demande
  Future<void> rejectRequest(String requestId, String adminId, String reason) async {
    try {
      // Vérifier que la demande existe et est en attente
      final requestDoc = await _firestore
          .collection(AppConstants.accountRequestsCollection)
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Demande introuvable');
      }

      final request = AccountRequestModel.fromFirestore(requestDoc);

      if (!request.isPending) {
        throw Exception('Cette demande a déjà été traitée');
      }

      // Mettre à jour la demande
      await _firestore
          .collection(AppConstants.accountRequestsCollection)
          .doc(requestId)
          .update({
        'status': RequestStatus.rejected.name,
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': adminId,
        'rejectionReason': reason,
      });

      // TODO: Envoyer un email de notification de rejet
      await _sendRejectionEmail(request, reason);

      debugPrint('[ACCOUNT_REQUEST_SERVICE] Demande rejetée: ${request.email}');
    } catch (e) {
      debugPrint('[ACCOUNT_REQUEST_SERVICE] Erreur lors du rejet: $e');
      rethrow;
    }
  }

  /// 🔍 Récupérer une demande par ID
  Future<AccountRequestModel?> getRequestById(String requestId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.accountRequestsCollection)
          .doc(requestId)
          .get();

      if (doc.exists) {
        return AccountRequestModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('[ACCOUNT_REQUEST_SERVICE] Erreur lors de la récupération par ID: $e');
      rethrow;
    }
  }

  /// 📊 Récupérer les statistiques des demandes
  Future<Map<String, int>> getRequestStats() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.accountRequestsCollection)
          .get();

      final requests = snapshot.docs
          .map((doc) => AccountRequestModel.fromFirestore(doc))
          .toList();

      return {
        'total': requests.length,
        'pending': requests.where((r) => r.isPending).length,
        'approved': requests.where((r) => r.isApproved).length,
        'rejected': requests.where((r) => r.isRejected).length,
      };
    } catch (e) {
      debugPrint('[ACCOUNT_REQUEST_SERVICE] Erreur lors de la récupération des stats: $e');
      rethrow;
    }
  }

  /// 🔐 Générer un mot de passe temporaire
  String _generateTemporaryPassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(12, (index) => chars[random % chars.length]).join();
  }

  /// 📧 Envoyer un email d'approbation
  Future<void> _sendApprovalEmail(AccountRequestModel request, String tempPassword) async {
    try {
      // TODO: Implémenter l'envoi d'email avec les informations de connexion
      debugPrint('[ACCOUNT_REQUEST_SERVICE] Email d\'approbation à envoyer à: ${request.email}');
      debugPrint('[ACCOUNT_REQUEST_SERVICE] Mot de passe temporaire: $tempPassword');
    } catch (e) {
      debugPrint('[ACCOUNT_REQUEST_SERVICE] Erreur lors de l\'envoi de l\'email d\'approbation: $e');
    }
  }

  /// 📧 Envoyer un email de rejet
  Future<void> _sendRejectionEmail(AccountRequestModel request, String reason) async {
    try {
      // TODO: Implémenter l'envoi d'email de notification de rejet
      debugPrint('[ACCOUNT_REQUEST_SERVICE] Email de rejet à envoyer à: ${request.email}');
      debugPrint('[ACCOUNT_REQUEST_SERVICE] Raison: $reason');
    } catch (e) {
      debugPrint('[ACCOUNT_REQUEST_SERVICE] Erreur lors de l\'envoi de l\'email de rejet: $e');
    }
  }

  /// 🔄 Stream des demandes en temps réel (pour admin)
  Stream<List<AccountRequestModel>> watchRequests() {
    return _firestore
        .collection(AppConstants.accountRequestsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AccountRequestModel.fromFirestore(doc))
            .toList());
  }

  /// 🔄 Stream des demandes en attente en temps réel
  Stream<List<AccountRequestModel>> watchPendingRequests() {
    return _firestore
        .collection(AppConstants.accountRequestsCollection)
        .where('status', isEqualTo: RequestStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AccountRequestModel.fromFirestore(doc))
            .toList());
  }
}
