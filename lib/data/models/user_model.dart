import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:constat_tunisie/core/enums/user_role.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final UserRole role;
  final String? phoneNumber;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool emailVerified;
  final Map<String, dynamic>? additionalData;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    required this.role,
    this.phoneNumber,
    this.photoURL,
    required this.createdAt,
    this.lastLoginAt,
    this.emailVerified = false,
    this.additionalData,
  });

  // Créer une copie de UserModel avec des modifications
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserRole? role,
    String? phoneNumber,
    String? photoURL,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? emailVerified,
    Map<String, dynamic>? additionalData,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      emailVerified: emailVerified ?? this.emailVerified,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  // Convertir de Firestore à UserModel
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      role: _parseRole(data['role']),
      phoneNumber: data['phoneNumber'],
      photoURL: data['photoURL'],
      createdAt: _parseTimestamp(data['createdAt']) ?? DateTime.now(),
      lastLoginAt: _parseTimestamp(data['lastLoginAt']),
      emailVerified: data['emailVerified'] ?? false,
      additionalData: data['additionalData'],
    );
  }

  // Convertir UserModel en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'emailVerified': emailVerified,
      'additionalData': additionalData,
    };
  }

  // Convertir UserModel en JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLoginAt': lastLoginAt?.millisecondsSinceEpoch,
      'emailVerified': emailVerified,
      'additionalData': additionalData,
    };
  }

  // Convertir JSON en UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      role: _parseRole(json['role']),
      phoneNumber: json['phoneNumber'] as String?,
      photoURL: json['photoURL'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastLoginAt'] as int)
          : null,
      emailVerified: json['emailVerified'] as bool? ?? false,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  // Méthode d'aide pour analyser le rôle
  static UserRole _parseRole(dynamic roleData) {
    if (roleData == null) return UserRole.driver;
    
    if (roleData is String) {
      try {
        return UserRole.values.firstWhere(
          (e) => e.name == roleData,
          orElse: () => UserRole.driver,
        );
      } catch (_) {
        return UserRole.driver;
      }
    }
    
    return UserRole.driver;
  }

  // Méthode d'aide pour analyser les timestamps
  static DateTime? _parseTimestamp(dynamic timestampData) {
    if (timestampData == null) return null;
    
    try {
      if (timestampData is Timestamp) {
        return timestampData.toDate();
      } else if (timestampData is DateTime) {
        return timestampData;
      } else if (timestampData is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestampData);
      } else if (timestampData is String) {
        return DateTime.parse(timestampData);
      }
    } catch (_) {
      // Ignorer l'erreur
    }
    
    return null;
  }
}
