import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/user_type.dart';

/// 📊 Statut du compte utilisateur
enum AccountStatus {
  pending,   // En attente d'approbation
  active,    // Compte actif
  suspended, // Compte suspendu
  approved,  // Approuvé par l'admin
  rejected,  // Rejeté par l'admin
}

extension AccountStatusExtension on AccountStatus {
  String get value {
    switch (this) {
      case AccountStatus.pending:
        return 'pending';
      case AccountStatus.active:
        return 'active';
      case AccountStatus.suspended:
        return 'suspended';
      case AccountStatus.approved:
        return 'approved';
      case AccountStatus.rejected:
        return 'rejected';
    }
  }

  static AccountStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return AccountStatus.pending;
      case 'active':
        return AccountStatus.active;
      case 'suspended':
        return AccountStatus.suspended;
      case 'approved':
        return AccountStatus.approved;
      case 'rejected':
        return AccountStatus.rejected;
      default:
        return AccountStatus.pending;
    }
  }
}

/// 👤 Modèle utilisateur principal
class UserModel {
  final String uid;
  final String email;
  final String nom;
  final String prenom;
  final String telephone;
  final String adresse;
  final UserType userType;
  final DateTime dateCreation;
  final DateTime dateModification;
  final String? compagnieId;
  final String? agenceId;
  final String? matricule;
  final String? poste;
  final AccountStatus accountStatus;
  final String? rejectionReason;
  final DateTime? approvalDate;
  final String? approvedBy;
  final List<String> permissions;

  const UserModel({
    required this.uid,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.adresse,
    required this.userType,
    required this.dateCreation,
    required this.dateModification,
    this.compagnieId,
    this.agenceId,
    this.matricule,
    this.poste,
    required this.accountStatus,
    this.rejectionReason,
    this.approvalDate,
    this.approvedBy,
    required this.permissions,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'adresse': adresse,
      'userType': userType.toString().split('.').last,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'dateModification': Timestamp.fromDate(dateModification),
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

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final userType = _getUserTypeFromString(map['userType'] as String? ?? 'conducteur');
    
    return UserModel(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      nom: map['nom'] as String? ?? '',
      prenom: map['prenom'] as String? ?? '',
      telephone: map['telephone'] as String? ?? '',
      adresse: map['adresse'] as String? ?? '',
      userType: userType,
      dateCreation: (map['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateModification: (map['dateModification'] as Timestamp?)?.toDate() ?? DateTime.now(),
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

  static UserType _getUserTypeFromString(String value) {
    switch (value.toLowerCase()) {
      case 'conducteur':
        return UserType.conducteur;
      case 'assureur':
        return UserType.assureur;
      case 'expert':
        return UserType.expert;
      case 'admin':
      case 'administrateur':
        return UserType.administrateur;
      default:
        return UserType.conducteur;
    }
  }

  static AccountStatus _getAccountStatusFromString(String value) {
    switch (value.toLowerCase()) {
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
}
