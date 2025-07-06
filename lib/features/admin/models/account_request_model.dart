import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/enums/app_enums.dart';

/// 📋 Statut d'une demande de compte
enum RequestStatus {
  pending('En attente'),
  approved('Approuvée'),
  rejected('Rejetée'),
  expired('Expirée');

  const RequestStatus(this.displayName);
  final String displayName;

  /// 🎨 Couleur selon le statut
  String get colorHex {
    switch (this) {
      case RequestStatus.pending:
        return '#FFA500'; // Orange
      case RequestStatus.approved:
        return '#10B981'; // Vert
      case RequestStatus.rejected:
        return '#EF4444'; // Rouge
      case RequestStatus.expired:
        return '#6B7280'; // Gris
    }
  }
}

/// 📋 Type de demande de compte professionnel
enum ProfessionalAccountType {
  agent('Agent d\'Assurance'),
  expert('Expert Automobile'),
  companyAdmin('Admin Compagnie'),
  agencyAdmin('Admin Agence');

  const ProfessionalAccountType(this.displayName);
  final String displayName;

  /// 🎭 Convertir vers UserRole
  UserRole get userRole {
    switch (this) {
      case ProfessionalAccountType.agent:
        return UserRole.agent;
      case ProfessionalAccountType.expert:
        return UserRole.expert;
      case ProfessionalAccountType.companyAdmin:
        return UserRole.companyAdmin;
      case ProfessionalAccountType.agencyAdmin:
        return UserRole.agencyAdmin;
    }
  }
}

/// 📋 Modèle de demande de compte professionnel
class AccountRequestModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final String cin;
  final ProfessionalAccountType accountType;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? processedBy;
  final String? rejectionReason;
  final String? notes;
  
  // Informations spécifiques selon le type
  final String? companyName;
  final String? agencyName;
  final String? licenseNumber;
  final String? specialization;
  final String? experience;
  final String? address;
  final String? governorate;
  
  // Documents joints
  final List<String>? documentUrls;
  final Map<String, dynamic>? additionalData;

  const AccountRequestModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.cin,
    required this.accountType,
    required this.status,
    required this.createdAt,
    this.processedAt,
    this.processedBy,
    this.rejectionReason,
    this.notes,
    this.companyName,
    this.agencyName,
    this.licenseNumber,
    this.specialization,
    this.experience,
    this.address,
    this.governorate,
    this.documentUrls,
    this.additionalData,
  });

  /// 🏭 Factory depuis Firestore
  factory AccountRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AccountRequestModel(
      id: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      phone: data['phone'] ?? '',
      cin: data['cin'] ?? '',
      accountType: ProfessionalAccountType.values.firstWhere(
        (type) => type.name == data['accountType'],
        orElse: () => ProfessionalAccountType.agent,
      ),
      status: RequestStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => RequestStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      processedAt: data['processedAt'] != null 
          ? (data['processedAt'] as Timestamp).toDate() 
          : null,
      processedBy: data['processedBy'],
      rejectionReason: data['rejectionReason'],
      notes: data['notes'],
      companyName: data['companyName'],
      agencyName: data['agencyName'],
      licenseNumber: data['licenseNumber'],
      specialization: data['specialization'],
      experience: data['experience'],
      address: data['address'],
      governorate: data['governorate'],
      documentUrls: data['documentUrls'] != null 
          ? List<String>.from(data['documentUrls']) 
          : null,
      additionalData: data['additionalData'],
    );
  }

  /// 🔥 Convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'cin': cin,
      'accountType': accountType.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'processedBy': processedBy,
      'rejectionReason': rejectionReason,
      'notes': notes,
      'companyName': companyName,
      'agencyName': agencyName,
      'licenseNumber': licenseNumber,
      'specialization': specialization,
      'experience': experience,
      'address': address,
      'governorate': governorate,
      'documentUrls': documentUrls,
      'additionalData': additionalData,
    };
  }

  /// 📝 Copier avec modifications
  AccountRequestModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? cin,
    ProfessionalAccountType? accountType,
    RequestStatus? status,
    DateTime? createdAt,
    DateTime? processedAt,
    String? processedBy,
    String? rejectionReason,
    String? notes,
    String? companyName,
    String? agencyName,
    String? licenseNumber,
    String? specialization,
    String? experience,
    String? address,
    String? governorate,
    List<String>? documentUrls,
    Map<String, dynamic>? additionalData,
  }) {
    return AccountRequestModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      cin: cin ?? this.cin,
      accountType: accountType ?? this.accountType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      processedBy: processedBy ?? this.processedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      notes: notes ?? this.notes,
      companyName: companyName ?? this.companyName,
      agencyName: agencyName ?? this.agencyName,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      specialization: specialization ?? this.specialization,
      experience: experience ?? this.experience,
      address: address ?? this.address,
      governorate: governorate ?? this.governorate,
      documentUrls: documentUrls ?? this.documentUrls,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  /// 👤 Nom complet
  String get fullName => '$firstName $lastName';

  /// ⏰ Temps écoulé depuis la création
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} jour(s)';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} heure(s)';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute(s)';
    } else {
      return 'À l\'instant';
    }
  }

  /// 🔍 Vérifier si la demande est en attente
  bool get isPending => status == RequestStatus.pending;

  /// ✅ Vérifier si la demande est approuvée
  bool get isApproved => status == RequestStatus.approved;

  /// ❌ Vérifier si la demande est rejetée
  bool get isRejected => status == RequestStatus.rejected;

  /// ⏰ Vérifier si la demande a expiré
  bool get isExpired => status == RequestStatus.expired;

  /// 🔄 Vérifier si la demande peut être traitée
  bool get canBeProcessed => isPending;

  @override
  String toString() {
    return 'AccountRequestModel(id: $id, email: $email, fullName: $fullName, accountType: ${accountType.displayName}, status: ${status.displayName})';
  }
}
