import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/enums/app_enums.dart';

/// 👤 Modèle utilisateur simple
class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final UserRole role;
  final AccountStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String? updatedBy;
  final String? address;
  final String? profileImageUrl;
  final String? cin;
  final DateTime? lastLoginAt;
  final List<Permission>? permissions;
  final Map<String, dynamic>? metadata;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.updatedBy,
    this.address,
    this.profileImageUrl,
    this.cin,
    this.lastLoginAt,
    this.permissions,
    this.metadata,
  });

  /// Nom complet de l'utilisateur
  String get fullName => '$firstName $lastName';

  /// Initiales de l'utilisateur
  String get initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }

  /// Vérifie si l'utilisateur est actif
  bool get isActive => status == AccountStatus.active;

  /// Vérifie si l'utilisateur est en attente
  bool get isPending => status == AccountStatus.pending;

  /// Vérifie si l'utilisateur est suspendu
  bool get isSuspended => status == AccountStatus.suspended;

  /// Vérifie si l'utilisateur est un administrateur
  bool get isAdmin => role.isAdmin;

  /// Vérifie si l'utilisateur peut gérer d'autres utilisateurs
  bool get canManageUsers => role.canManageUsers;

  /// Vérifie si l'utilisateur a une permission spécifique
  bool hasPermission(Permission permission) {
    return permissions?.contains(permission) ?? false;
  }

  /// Convertit en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'role': role.value,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      if (updatedBy != null) 'updatedBy': updatedBy,
      if (address != null) 'address': address,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (cin != null) 'cin': cin,
      if (lastLoginAt != null) 'lastLoginAt': Timestamp.fromDate(lastLoginAt!),
      if (permissions != null)
        'permissions': permissions!.map((p) => p.value).toList(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Crée un UserModel à partir d'un document Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data, doc.id);
  }

  /// Crée un UserModel à partir d'une Map
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      phone: map['phone'] ?? '',
      role: UserRole.fromString(map['role'] ?? 'driver'),
      status: AccountStatus.fromString(map['status'] ?? 'pending'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
      updatedBy: map['updatedBy'],
      address: map['address'],
      profileImageUrl: map['profileImageUrl'],
      cin: map['cin'],
      lastLoginAt: (map['lastLoginAt'] as Timestamp?)?.toDate(),
      permissions: _parsePermissions(map['permissions']),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Parse les permissions de manière sécurisée
  static List<Permission>? _parsePermissions(dynamic permissionsData) {
    if (permissionsData == null) return null;

    try {
      if (permissionsData is List) {
        return permissionsData
            .map((p) => Permission.fromString(p.toString()))
            .toList();
      }
    } catch (e) {
      debugPrint('[USER_MODEL] Erreur lors du parsing des permissions: $e');
    }

    return null;
  }

  /// Crée une copie avec des champs modifiés
  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    UserRole? role,
    AccountStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? address,
    String? profileImageUrl,
    String? cin,
    DateTime? lastLoginAt,
    List<Permission>? permissions,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      address: address ?? this.address,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      cin: cin ?? this.cin,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      permissions: permissions ?? this.permissions,
      metadata: metadata ?? this.metadata,
    );
  }
}
