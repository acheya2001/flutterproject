import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/user_type.dart';

/// 📊 Statuts possibles pour les comptes professionnels
enum AccountStatus {
  pending,    // En attente de validation
  approved,   // Approuvé par l'admin
  rejected,   // Rejeté par l'admin
  suspended,  // Suspendu temporairement
  active,     // Actif et opérationnel
}

/// 🔔 Types de notifications
enum NotificationType {
  accountPending,     // Nouveau compte en attente
  accountApproved,    // Compte approuvé
  accountRejected,    // Compte rejeté
  accountSuspended,   // Compte suspendu
  permissionChanged,  // Permissions modifiées
}

class UserModel {
  final String uid;
  final String email;
  final String nom;
  final String prenom;
  final String telephone;
  final String? adresse;
  final UserType userType;
  final DateTime dateCreation;
  final DateTime? dateModification;

  // 🆕 Nouveau système de statuts
  final AccountStatus accountStatus;
  final String? rejectionReason;
  final DateTime? approvalDate;
  final String? approvedBy;

  // Champs pour la hiérarchie administrative
  final String? compagnieId;
  final String? agenceId;
  final String? matricule;
  final String? poste;

  // 🔐 Système de permissions
  final List<String> permissions;

  UserModel({
    required this.uid,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.telephone,
    this.adresse,
    required this.userType,
    required this.dateCreation,
    this.dateModification,
    this.accountStatus = AccountStatus.active, // Par défaut actif pour conducteurs
    this.rejectionReason,
    this.approvalDate,
    this.approvedBy,
    this.compagnieId,
    this.agenceId,
    this.matricule,
    this.poste,
    this.permissions = const [], // Par défaut vide
  });

  // Créer une copie du modèle avec des modifications
  UserModel copyWith({
    String? uid,
    String? email,
    String? nom,
    String? prenom,
    String? telephone,
    String? adresse,
    UserType? userType,
    DateTime? dateCreation,
    DateTime? dateModification,
    AccountStatus? accountStatus,
    String? rejectionReason,
    DateTime? approvalDate,
    String? approvedBy,
    String? compagnieId,
    String? agenceId,
    String? matricule,
    String? poste,
    List<String>? permissions,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      telephone: telephone ?? this.telephone,
      adresse: adresse ?? this.adresse,
      userType: userType ?? this.userType,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
      accountStatus: accountStatus ?? this.accountStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      approvalDate: approvalDate ?? this.approvalDate,
      approvedBy: approvedBy ?? this.approvedBy,
      compagnieId: compagnieId ?? this.compagnieId,
      agenceId: agenceId ?? this.agenceId,
      matricule: matricule ?? this.matricule,
      poste: poste ?? this.poste,
      permissions: permissions ?? this.permissions,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'adresse': adresse,
      'userType': userType.toString().split('.').last,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'dateModification': dateModification != null
          ? Timestamp.fromDate(dateModification!)
          : null,
      'compagnieId': compagnieId,
      'agenceId': agenceId,
      'matricule': matricule,
      'poste': poste,
      'accountStatus': accountStatus.toString().split('.').last,
      'rejectionReason': rejectionReason,
      'approvalDate': approvalDate != null ? Timestamp.fromDate(approvalDate!) : null,
      'approvedBy': approvedBy,
      'permissions': permissions,
    };
  }

  static UserModel fromFirestore(Map<String, dynamic> map, String docId) {
    final userType = _getUserTypeFromString(map['userType'] as String? ?? 'conducteur');

    return UserModel(
      uid: docId,
      email: map['email'] as String? ?? '',
      nom: map['nom'] as String? ?? '',
      prenom: map['prenom'] as String? ?? '',
      telephone: map['telephone'] as String? ?? '',
      adresse: map['adresse'] as String?,
      userType: userType,
      dateCreation: (map['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateModification: (map['dateModification'] as Timestamp?)?.toDate(),
      compagnieId: map['compagnieId'] as String?,
      agenceId: map['agenceId'] as String?,
      matricule: map['matricule'] as String?,
      poste: map['poste'] as String?,
      accountStatus: _getAccountStatusFromString(map['accountStatus'] as String? ?? 'active'),
      rejectionReason: map['rejectionReason'] as String?,
      approvalDate: (map['approvalDate'] as Timestamp?)?.toDate(),
      approvedBy: map['approvedBy'] as String?,
      permissions: List<String>.from(map['permissions'] ?? []),
    );
  }



  static UserType _getUserTypeFromString(String type) {
    switch (type) {
      case 'conducteur':
        return UserType.conducteur;
      case 'assureur':
        return UserType.assureur;
      case 'expert':
        return UserType.expert;
      case 'admin':
        return UserType.admin;
      default:
        return UserType.conducteur;
    }
  }

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
        return AccountStatus.active;
    }
  }

  // Nom complet de l'utilisateur
  String get nomComplet => '$prenom $nom';

  @override
  String toString() {
    return 'UserModel{uid: $uid, email: $email, nom: $nom, prenom: $prenom, telephone: $telephone, userType: $userType}';
  }

  // Getter pour compatibilité
  String get id => uid;
  UserType get type => userType;
  DateTime get createdAt => dateCreation;
  DateTime? get updatedAt => dateModification;
}