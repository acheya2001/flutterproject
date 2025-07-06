import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import 'email_service.dart';
import '../../../core/services/firebase_email_service.dart';

/// 🔔 Service de gestion des notifications
class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'notifications';

  /// Créer une notification
  static Future<void> createNotification({
    required String recipientId,
    String? senderId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic> data = const {},
  }) async {
    try {
      final notification = NotificationModel(
        id: '', // Sera généré par Firestore
        recipientId: recipientId,
        senderId: senderId,
        type: type,
        title: title,
        message: message,
        data: data,
        createdAt: DateTime.now(),
      );

      await _firestore.collection(_collection).add(notification.toFirestore());
      debugPrint('✅ Notification créée pour $recipientId: $title');
    } catch (e) {
      debugPrint('❌ Erreur création notification: $e');
      rethrow;
    }
  }

  /// Obtenir les notifications d'un utilisateur
  static Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection(_collection)
        .where('recipientId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  /// Marquer une notification comme lue
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).update({
        'isRead': true,
        'readAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('❌ Erreur marquage notification: $e');
      rethrow;
    }
  }

  /// Marquer toutes les notifications comme lues
  static Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection(_collection)
          .where('recipientId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('❌ Erreur marquage toutes notifications: $e');
      rethrow;
    }
  }

  /// Obtenir le nombre de notifications non lues
  static Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection(_collection)
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Supprimer une notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).delete();
    } catch (e) {
      debugPrint('❌ Erreur suppression notification: $e');
      rethrow;
    }
  }

  /// Notifications spécifiques pour les comptes professionnels

  /// Notifier l'admin d'une nouvelle demande de compte
  static Future<void> notifyAdminNewAccountRequest({
    required String requestId,
    required String applicantName,
    required String applicantEmail,
    required String userType,
  }) async {
    // Obtenir tous les admins
    final admins = await _firestore
        .collection('users')
        .where('userType', isEqualTo: 'admin')
        .get();

    final adminEmails = <String>[];

    for (final admin in admins.docs) {
      final adminData = admin.data() as Map<String, dynamic>;
      final adminEmail = adminData['email'] as String?;

      if (adminEmail != null) {
        adminEmails.add(adminEmail);
      }

      await createNotification(
        recipientId: admin.id,
        type: NotificationType.accountPending,
        title: '🆕 Nouvelle demande de compte',
        message: '$applicantName ($userType) a demandé la création d\'un compte professionnel.',
        data: {
          'requestId': requestId,
          'applicantEmail': applicantEmail,
          'userType': userType,
          'action': 'review_account_request',
        },
      );
    }

    // Envoyer les emails aux admins
    if (adminEmails.isNotEmpty) {
      await EmailService.sendNewRequestNotificationToAdmins(
        applicantName: applicantName,
        applicantEmail: applicantEmail,
        userType: userType,
        adminEmails: adminEmails,
      );
    }
  }

  /// Notifier l'utilisateur de l'approbation de son compte
  static Future<void> notifyAccountApproved({
    required String userId,
    required String approvedBy,
  }) async {
    print('🔍 DEBUG: notifyAccountApproved - userId: $userId, approvedBy: $approvedBy');

    // Créer la notification
    await createNotification(
      recipientId: userId,
      senderId: approvedBy,
      type: NotificationType.accountApproved,
      title: '✅ Compte approuvé',
      message: 'Félicitations ! Votre compte professionnel a été approuvé. Vous pouvez maintenant vous connecter.',
      data: {
        'action': 'account_approved',
        'approvedBy': approvedBy,
      },
    );

    // Envoyer l'email de confirmation
    try {
      print('🔍 DEBUG: Recherche utilisateur dans collection users...');
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        print('✅ DEBUG: Utilisateur trouvé dans users');
        final userData = userDoc.data()!;
        final userEmail = userData['email'] as String?;
        final userName = '${userData['prenom']} ${userData['nom']}';
        final userType = userData['userType'] as String?;

        print('🔍 DEBUG: Email: $userEmail, Nom: $userName, Type: $userType');

        if (userEmail != null && userType != null) {
          print('🔍 DEBUG: Envoi email d\'approbation...');
          final emailSent = await EmailService.sendAccountApprovedEmail(
            to: userEmail,
            userName: userName,
            userType: userType,
          );
          print(emailSent ? '✅ DEBUG: Email envoyé avec succès' : '❌ DEBUG: Échec envoi email');
        } else {
          print('❌ DEBUG: Email ou type utilisateur manquant');
        }
      } else {
        print('❌ DEBUG: Utilisateur non trouvé dans collection users');
        // L'utilisateur n'existe pas encore, essayons de récupérer les infos depuis la demande
        await _sendEmailFromRequest(userId, approvedBy);
      }
    } catch (e) {
      print('❌ DEBUG: Erreur envoi email approbation: $e');
      debugPrint('❌ Erreur envoi email approbation: $e');
    }
  }

  /// Envoyer email en utilisant les données de la demande avec FirebaseEmailService
  static Future<void> _sendEmailFromRequest(String requestId, String approvedBy) async {
    try {
      print('🔍 DEBUG: Récupération données depuis professional_account_requests...');
      final requestDoc = await _firestore.collection('professional_account_requests').doc(requestId).get();

      if (requestDoc.exists) {
        final requestData = requestDoc.data()!;
        final userEmail = requestData['email'] as String?;
        final userName = '${requestData['prenom']} ${requestData['nom']}';
        final userType = requestData['userType'] as String?;

        print('🔍 DEBUG: Données demande - Email: $userEmail, Nom: $userName, Type: $userType');

        if (userEmail != null && userType != null) {
          print('🔍 DEBUG: 🔥 Envoi email d\'approbation via FirebaseEmailService (même méthode que les invitations)...');

          // Utiliser la même méthode que les invitations collaboratives
          final emailSent = await _sendApprovalEmailViaFirebase(
            email: userEmail,
            userName: userName,
            userType: userType,
          );

          print(emailSent ? '✅ DEBUG: Email d\'approbation envoyé via Firebase' : '❌ DEBUG: Échec envoi email Firebase');
        }
      } else {
        print('❌ DEBUG: Demande non trouvée');
      }
    } catch (e) {
      print('❌ DEBUG: Erreur récupération données demande: $e');
    }
  }

  /// 📧 Envoyer email d'approbation via FirebaseEmailService (méthode dédiée)
  static Future<bool> _sendApprovalEmailViaFirebase({
    required String email,
    required String userName,
    required String userType,
  }) async {
    try {
      print('📧 DEBUG: Envoi email d\'approbation via méthode dédiée...');

      // Utiliser la méthode spécifique pour les notifications de compte
      final success = await FirebaseEmailService.envoyerNotificationCompte(
        email: email,
        userName: userName,
        userType: userType,
        isApproved: true,
      );

      print(success ? '✅ DEBUG: Email d\'approbation envoyé' : '❌ DEBUG: Échec envoi email');
      return success;
    } catch (e) {
      print('❌ DEBUG: Erreur envoi email: $e');
      return false;
    }
  }

  /// Notifier l'utilisateur du rejet de son compte
  static Future<void> notifyAccountRejected({
    required String userId,
    required String rejectedBy,
    required String reason,
  }) async {
    print('🔍 DEBUG: notifyAccountRejected - userId: $userId, reason: $reason');

    // Créer la notification
    await createNotification(
      recipientId: userId,
      senderId: rejectedBy,
      type: NotificationType.accountRejected,
      title: '❌ Compte rejeté',
      message: 'Votre demande de compte professionnel a été rejetée. Raison: $reason',
      data: {
        'action': 'account_rejected',
        'rejectedBy': rejectedBy,
        'reason': reason,
      },
    );

    // Envoyer l'email de rejet
    try {
      print('🔍 DEBUG: Recherche utilisateur pour email de rejet...');
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        print('✅ DEBUG: Utilisateur trouvé dans users');
        final userData = userDoc.data()!;
        final userEmail = userData['email'] as String?;
        final userName = '${userData['prenom']} ${userData['nom']}';
        final userType = userData['userType'] as String?;

        if (userEmail != null && userType != null) {
          print('🔍 DEBUG: Envoi email de rejet...');
          final emailSent = await _sendRejectionEmailViaFirebase(
            email: userEmail,
            userName: userName,
            userType: userType,
            reason: reason,
          );
          print(emailSent ? '✅ DEBUG: Email de rejet envoyé' : '❌ DEBUG: Échec envoi email rejet');
        }
      } else {
        print('❌ DEBUG: Utilisateur non trouvé, envoi depuis demande...');
        await _sendRejectionEmailFromRequest(userId, rejectedBy, reason);
      }
    } catch (e) {
      print('❌ DEBUG: Erreur envoi email rejet: $e');
      debugPrint('❌ Erreur envoi email rejet: $e');
    }
  }

  /// 📧 Envoyer email de rejet via FirebaseEmailService
  static Future<bool> _sendRejectionEmailViaFirebase({
    required String email,
    required String userName,
    required String userType,
    required String reason,
  }) async {
    try {
      print('📧 DEBUG: Envoi email de rejet via méthode dédiée...');

      // Utiliser la méthode spécifique pour les notifications de compte
      final success = await FirebaseEmailService.envoyerNotificationCompte(
        email: email,
        userName: userName,
        userType: userType,
        isApproved: false,
        rejectionReason: reason,
      );

      return success;
    } catch (e) {
      print('❌ DEBUG: Erreur envoi email rejet: $e');
      return false;
    }
  }

  /// Envoyer email de rejet depuis les données de la demande
  static Future<void> _sendRejectionEmailFromRequest(String requestId, String rejectedBy, String reason) async {
    try {
      print('🔍 DEBUG: Récupération données demande pour email de rejet...');
      final requestDoc = await _firestore.collection('professional_account_requests').doc(requestId).get();

      if (requestDoc.exists) {
        final requestData = requestDoc.data()!;
        final userEmail = requestData['email'] as String?;
        final userName = '${requestData['prenom']} ${requestData['nom']}';
        final userType = requestData['userType'] as String?;

        if (userEmail != null && userType != null) {
          print('🔍 DEBUG: Envoi email de rejet depuis données demande...');
          final emailSent = await _sendRejectionEmailViaFirebase(
            email: userEmail,
            userName: userName,
            userType: userType,
            reason: reason,
          );
          print(emailSent ? '✅ DEBUG: Email de rejet envoyé depuis demande' : '❌ DEBUG: Échec envoi email rejet depuis demande');
        }
      }
    } catch (e) {
      print('❌ DEBUG: Erreur récupération données demande pour rejet: $e');
    }
  }

  /// Notifier l'utilisateur de la suspension de son compte
  static Future<void> notifyAccountSuspended({
    required String userId,
    required String suspendedBy,
    required String reason,
  }) async {
    await createNotification(
      recipientId: userId,
      senderId: suspendedBy,
      type: NotificationType.accountSuspended,
      title: '⚠️ Compte suspendu',
      message: 'Votre compte a été temporairement suspendu. Raison: $reason',
      data: {
        'action': 'account_suspended',
        'suspendedBy': suspendedBy,
        'reason': reason,
      },
    );
  }

  /// Notifier l'utilisateur du changement de permissions
  static Future<void> notifyPermissionChanged({
    required String userId,
    required String changedBy,
    required List<String> newPermissions,
  }) async {
    await createNotification(
      recipientId: userId,
      senderId: changedBy,
      type: NotificationType.permissionChanged,
      title: '🔧 Permissions modifiées',
      message: 'Vos permissions ont été mises à jour par un administrateur.',
      data: {
        'action': 'permissions_changed',
        'changedBy': changedBy,
        'newPermissions': newPermissions,
      },
    );
  }
}

/// 📋 Service de gestion des demandes de comptes professionnels
class ProfessionalAccountService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'professional_account_requests';

  /// Vérifier si un email existe déjà dans le système
  static Future<bool> emailExists(String email) async {
    try {
      print('🔍 DEBUG: Vérification unicité email: $email');

      // Vérifier dans les utilisateurs existants
      final usersQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();

      if (usersQuery.docs.isNotEmpty) {
        print('❌ DEBUG: Email trouvé dans users');
        return true;
      }

      // Vérifier dans les demandes en attente
      final requestsQuery = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email.toLowerCase().trim())
          .where('status', whereIn: ['pending', 'approved'])
          .limit(1)
          .get();

      if (requestsQuery.docs.isNotEmpty) {
        print('❌ DEBUG: Email trouvé dans demandes en attente/approuvées');
        return true;
      }

      print('✅ DEBUG: Email disponible');
      return false;
    } catch (e) {
      print('❌ DEBUG: Erreur vérification email: $e');
      return false; // En cas d'erreur, on autorise (pour ne pas bloquer)
    }
  }

  /// Créer une demande de compte professionnel
  static Future<String> createAccountRequest(ProfessionalAccountRequest request) async {
    try {
      print('🔍 DEBUG: ProfessionalAccountService.createAccountRequest() - Début');
      print('🔍 DEBUG: Collection: $_collection');
      print('🔍 DEBUG: Request email: ${request.email}');
      print('🔍 DEBUG: Request userType: ${request.userType}');

      // Vérifier l'unicité de l'email
      print('🔍 DEBUG: Vérification unicité email...');
      final emailAlreadyExists = await emailExists(request.email);
      if (emailAlreadyExists) {
        throw Exception('Un compte avec cet email existe déjà ou une demande est en cours de traitement');
      }
      print('✅ DEBUG: Email unique confirmé');

      print('🔍 DEBUG: Conversion vers Firestore...');
      final firestoreData = request.toFirestore();
      print('🔍 DEBUG: Données Firestore créées: ${firestoreData.keys.toList()}');

      print('🔍 DEBUG: Ajout à Firestore...');
      final docRef = await _firestore.collection(_collection).add(firestoreData);
      print('✅ DEBUG: Document créé avec ID: ${docRef.id}');

      // Notifier les admins
      print('🔍 DEBUG: Notification des admins...');
      await NotificationService.notifyAdminNewAccountRequest(
        requestId: docRef.id,
        applicantName: '${request.prenom} ${request.nom}',
        applicantEmail: request.email,
        userType: request.userType,
      );
      print('✅ DEBUG: Admins notifiés');

      debugPrint('✅ Demande de compte créée: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ DEBUG: Erreur dans createAccountRequest: $e');
      print('❌ DEBUG: Type d\'erreur: ${e.runtimeType}');
      debugPrint('❌ Erreur création demande: $e');
      rethrow;
    }
  }

  /// Obtenir toutes les demandes en attente
  static Stream<List<ProfessionalAccountRequest>> getPendingRequests() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProfessionalAccountRequest.fromFirestore(doc))
            .toList());
  }

  /// Obtenir une demande par ID
  static Future<ProfessionalAccountRequest?> getRequestById(String requestId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(requestId).get();
      if (doc.exists) {
        return ProfessionalAccountRequest.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur récupération demande: $e');
      return null;
    }
  }

  /// Approuver une demande
  static Future<void> approveRequest({
    required String requestId,
    required String approvedBy,
  }) async {
    try {
      await _firestore.collection(_collection).doc(requestId).update({
        'status': 'approved',
        'reviewedAt': Timestamp.fromDate(DateTime.now()),
        'reviewedBy': approvedBy,
      });

      // Obtenir la demande pour notifier l'utilisateur
      final request = await getRequestById(requestId);
      if (request != null) {
        await NotificationService.notifyAccountApproved(
          userId: request.userId,
          approvedBy: approvedBy,
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur approbation demande: $e');
      rethrow;
    }
  }

  /// Rejeter une demande
  static Future<void> rejectRequest({
    required String requestId,
    required String rejectedBy,
    required String reason,
  }) async {
    try {
      await _firestore.collection(_collection).doc(requestId).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'reviewedAt': Timestamp.fromDate(DateTime.now()),
        'reviewedBy': rejectedBy,
      });

      // Obtenir la demande pour notifier l'utilisateur
      final request = await getRequestById(requestId);
      if (request != null) {
        await NotificationService.notifyAccountRejected(
          userId: request.userId,
          rejectedBy: rejectedBy,
          reason: reason,
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur rejet demande: $e');
      rethrow;
    }
  }
}
