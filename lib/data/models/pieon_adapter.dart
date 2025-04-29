import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:constat_tunisie/core/enums/user_role.dart';
import 'package:constat_tunisie/data/models/user_model.dart';
import 'package:logger/logger.dart';

/// Classe d'adaptation pour PieonUserDetails - Version simplifiée
class PieonUserDetails {
  final Logger _logger = Logger();
  
  final String uid;
  final String email;
  final String? displayName;
  final String? role;
  final String? phoneNumber;
  final String? photoURL;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic>? additionalData;

  /// Constructeur principal
  PieonUserDetails({
    required this.uid,
    required this.email,
    this.displayName,
    this.role,
    this.phoneNumber,
    this.photoURL,
    this.createdAt,
    this.lastLoginAt,
    this.additionalData,
  });

  /// Constructeur par défaut avec des valeurs minimales
  factory PieonUserDetails.defaultUser(String uid, String email) {
    return PieonUserDetails(
      uid: uid,
      email: email,
      role: UserRole.driver.name,
    );
  }

  /// Convertir de UserModel à PieonUserDetails
  factory PieonUserDetails.fromUserModel(UserModel user) {
    return PieonUserDetails(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      role: user.role.name,
      phoneNumber: user.phoneNumber,
      photoURL: user.photoURL,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
      additionalData: user.additionalData,
    );
  }

  /// Convertir de Map<String, dynamic> à PieonUserDetails
  factory PieonUserDetails.fromMap(Map<String, dynamic> map) {
    return PieonUserDetails(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String?,
      role: map['role'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      photoURL: map['photoURL'] as String?,
      createdAt: _parseTimestamp(map['createdAt']),
      lastLoginAt: _parseTimestamp(map['lastLoginAt']),
      additionalData: map['additionalData'] as Map<String, dynamic>?,
    );
  }

  /// Convertir de PieonUserDetails à UserModel
  UserModel toUserModel() {
    try {
      return UserModel(
        uid: uid,
        email: email,
        displayName: displayName,
        phoneNumber: phoneNumber,
        role: _parseRole(role),
        photoURL: photoURL,
        createdAt: createdAt ?? DateTime.now(),
        lastLoginAt: lastLoginAt,
        additionalData: additionalData,
      );
    } catch (e) {
      _logger.e('Erreur lors de la conversion PieonUserDetails -> UserModel: $e');
      // Retourner un modèle par défaut en cas d'erreur
      return UserModel(
        uid: uid,
        email: email,
        role: UserRole.driver,
        createdAt: DateTime.now(),
      );
    }
  }

  /// Convertir PieonUserDetails en Map<String, dynamic>
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'additionalData': additionalData,
    };
  }

  /// Méthode d'aide pour analyser le rôle
  static UserRole _parseRole(String? roleStr) {
    if (roleStr == null || roleStr.isEmpty) {
      return UserRole.driver;
    }

    try {
      return UserRole.values.firstWhere(
        (e) => e.name == roleStr,
        orElse: () => UserRole.driver,
      );
    } catch (e) {
      return UserRole.driver;
    }
  }

  /// Méthode d'aide pour analyser les timestamps
  static DateTime? _parseTimestamp(dynamic timestampData) {
    if (timestampData == null) {
      return null;
    }

    try {
      if (timestampData is Timestamp) {
        return timestampData.toDate();
      } else if (timestampData is DateTime) {
        return timestampData;
      } else if (timestampData is int) {
        // Timestamp en millisecondes
        return DateTime.fromMillisecondsSinceEpoch(timestampData);
      } else if (timestampData is String) {
        // Essayer de parser une chaîne de date
        return DateTime.parse(timestampData);
      }
    } catch (e) {
      // Ignorer l'erreur
    }

    return null;
  }
}

// SUPPRESSION DES EXTENSIONS PROBLÉMATIQUES
