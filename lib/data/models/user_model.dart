import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:constat_tunisie/data/enums/user_role.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String? phoneNumber;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool emailVerified;
  final Map<String, dynamic>? profileData;
  final Map<String, dynamic>? additionalData;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.phoneNumber,
    this.photoURL,
    required this.createdAt,
    this.lastLoginAt,
    this.emailVerified = false,
    this.profileData,
    this.additionalData,
  });

  // Créer une copie de l'objet avec des valeurs modifiées
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
    Map<String, dynamic>? profileData,
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
      profileData: profileData ?? this.profileData,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  // Convertir l'objet en Map pour JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role.toString(),
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'emailVerified': emailVerified,
      'profileData': profileData,
      'additionalData': additionalData,
    };
  }

  // Créer un objet à partir d'un Map JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      email: json['email'],
      displayName: json['displayName'],
      role: _parseUserRole(json['role']),
      phoneNumber: json['phoneNumber'],
      photoURL: json['photoURL'],
      createdAt: _parseDateTime(json['createdAt']),
      lastLoginAt: json['lastLoginAt'] != null ? _parseDateTime(json['lastLoginAt']) : null,
      emailVerified: json['emailVerified'] ?? false,
      profileData: json['profileData'],
      additionalData: json['additionalData'],
    );
  }

  // Créer un objet à partir d'un DocumentSnapshot Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: _parseUserRole(data['role'] ?? ''),
      phoneNumber: data['phoneNumber'],
      photoURL: data['photoURL'],
      createdAt: _parseTimestamp(data['createdAt']),
      lastLoginAt: data['lastLoginAt'] != null ? _parseTimestamp(data['lastLoginAt']) : null,
      emailVerified: data['emailVerified'] ?? false,
      profileData: data['profileData'],
      additionalData: data['additionalData'],
    );
  }

  // Convertir l'objet en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role.toString(),
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'emailVerified': emailVerified,
      'profileData': profileData,
      'additionalData': additionalData,
    };
  }

  // Convertir la chaîne de rôle en enum UserRole
  static UserRole _parseUserRole(String roleStr) {
    if (roleStr.contains('driver')) {
      return UserRole.driver;
    } else if (roleStr.contains('insurance')) {
      return UserRole.insurance;
    } else if (roleStr.contains('expert')) {
      return UserRole.expert;
    } else if (roleStr.contains('admin')) {
      return UserRole.admin;
    }
    return UserRole.driver; // Valeur par défaut
  }

  // Convertir un Timestamp ou une chaîne en DateTime
  static DateTime _parseDateTime(dynamic date) {
    if (date is Timestamp) {
      return date.toDate();
    } else if (date is String) {
      return DateTime.parse(date);
    }
    return DateTime.now(); // Valeur par défaut
  }

  // Convertir un Timestamp en DateTime
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return DateTime.now(); // Valeur par défaut
  }
}