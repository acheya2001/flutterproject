import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

/// 🔔 Modèle pour les notifications système
class NotificationModel {
  final String id;
  final String recipientId; // ID de l'utilisateur qui reçoit la notification
  final String? senderId; // ID de l'utilisateur qui a déclenché la notification
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic> data; // Données supplémentaires
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationModel({
    required this.id,
    required this.recipientId,
    this.senderId,
    required this.type,
    required this.title,
    required this.message,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  /// Créer une notification depuis Firestore
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      recipientId: data['recipientId'] ?? '',
      senderId: data['senderId'],
      type: _getNotificationTypeFromString(data['type'] ?? ''),
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: data['readAt'] != null ? (data['readAt'] as Timestamp).toDate() : null,
    );
  }

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'recipientId': recipientId,
      'senderId': senderId,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }

  /// Marquer comme lue
  NotificationModel markAsRead() {
    return copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
  }

  /// Copier avec modifications
  NotificationModel copyWith({
    String? id,
    String? recipientId,
    String? senderId,
    NotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  /// Convertir string en NotificationType
  static NotificationType _getNotificationTypeFromString(String type) {
    switch (type) {
      case 'accountPending':
        return NotificationType.accountPending;
      case 'accountApproved':
        return NotificationType.accountApproved;
      case 'accountRejected':
        return NotificationType.accountRejected;
      case 'accountSuspended':
        return NotificationType.accountSuspended;
      case 'permissionChanged':
        return NotificationType.permissionChanged;
      default:
        return NotificationType.accountPending;
    }
  }

  /// Obtenir l'icône pour le type de notification
  String get iconData {
    switch (type) {
      case NotificationType.accountPending:
        return '⏳';
      case NotificationType.accountApproved:
        return '✅';
      case NotificationType.accountRejected:
        return '❌';
      case NotificationType.accountSuspended:
        return '⚠️';
      case NotificationType.permissionChanged:
        return '🔧';
    }
  }

  /// Obtenir la couleur pour le type de notification
  String get colorCode {
    switch (type) {
      case NotificationType.accountPending:
        return '#FFA726'; // Orange
      case NotificationType.accountApproved:
        return '#66BB6A'; // Vert
      case NotificationType.accountRejected:
        return '#EF5350'; // Rouge
      case NotificationType.accountSuspended:
        return '#FF7043'; // Rouge-orange
      case NotificationType.permissionChanged:
        return '#42A5F5'; // Bleu
    }
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, type: $type, title: $title, isRead: $isRead)';
  }
}

/// 📊 Modèle pour les demandes de compte professionnel
class ProfessionalAccountRequest {
  final String id;
  final String userId;
  final String email;
  final String nom;
  final String prenom;
  final String telephone;
  final String? adresse;
  final String userType; // 'assureur' ou 'expert'
  
  // Champs spécifiques aux assureurs
  final String? compagnie;
  final String? matricule;
  final String? gouvernorat;
  final String? agencePreferee;
  
  // Champs spécifiques aux experts
  final String? cabinet;
  final String? agrement;
  final String? specialites;
  
  // Documents justificatifs
  final List<String> documentsUrls;
  final String? motivationLetter;
  
  // Statut de la demande
  final AccountStatus status;
  final String? rejectionReason;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final DateTime createdAt;

  const ProfessionalAccountRequest({
    required this.id,
    required this.userId,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.telephone,
    this.adresse,
    required this.userType,
    this.compagnie,
    this.matricule,
    this.gouvernorat,
    this.agencePreferee,
    this.cabinet,
    this.agrement,
    this.specialites,
    this.documentsUrls = const [],
    this.motivationLetter,
    this.status = AccountStatus.pending,
    this.rejectionReason,
    this.reviewedAt,
    this.reviewedBy,
    required this.createdAt,
  });

  /// Créer depuis Firestore
  factory ProfessionalAccountRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProfessionalAccountRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      email: data['email'] ?? '',
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      telephone: data['telephone'] ?? '',
      adresse: data['adresse'],
      userType: data['userType'] ?? '',
      compagnie: data['compagnie'],
      matricule: data['matricule'],
      gouvernorat: data['gouvernorat'],
      agencePreferee: data['agencePreferee'],
      cabinet: data['cabinet'],
      agrement: data['agrement'],
      specialites: data['specialites'],
      documentsUrls: List<String>.from(data['documentsUrls'] ?? []),
      motivationLetter: data['motivationLetter'],
      status: _getAccountStatusFromString(data['status'] ?? 'pending'),
      rejectionReason: data['rejectionReason'],
      reviewedAt: data['reviewedAt'] != null ? (data['reviewedAt'] as Timestamp).toDate() : null,
      reviewedBy: data['reviewedBy'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    print('🔍 DEBUG: ProfessionalAccountRequest.toFirestore() - Début');
    print('🔍 DEBUG: userId: $userId');
    print('🔍 DEBUG: email: $email');
    print('🔍 DEBUG: userType: $userType');

    try {
      final data = {
        'userId': userId,
        'email': email,
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'adresse': adresse,
        'userType': userType,
        'compagnie': compagnie,
        'matricule': matricule,
        'gouvernorat': gouvernorat,
        'agencePreferee': agencePreferee,
        'cabinet': cabinet,
        'agrement': agrement,
        'specialites': specialites,
        'documentsUrls': documentsUrls,
        'motivationLetter': motivationLetter,
        'status': status.toString().split('.').last,
        'rejectionReason': rejectionReason,
        'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
        'reviewedBy': reviewedBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };

      print('✅ DEBUG: toFirestore() terminé avec succès');
      return data;
    } catch (e) {
      print('❌ DEBUG: Erreur dans toFirestore(): $e');
      rethrow;
    }
  }

  /// Convertir string en AccountStatus
  static AccountStatus _getAccountStatusFromString(String status) {
    switch (status) {
      case 'pending':
        return AccountStatus.pending;
      case 'approved':
        return AccountStatus.approved;
      case 'rejected':
        return AccountStatus.rejected;
      case 'suspended':
        return AccountStatus.suspended;
      case 'active':
        return AccountStatus.active;
      default:
        return AccountStatus.pending;
    }
  }

  @override
  String toString() {
    return 'ProfessionalAccountRequest(id: $id, email: $email, userType: $userType, status: $status)';
  }
}
