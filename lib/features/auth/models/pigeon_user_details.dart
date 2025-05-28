import 'package:flutter/foundation.dart';

class PigeonUserDetails {
  final String? id;
  final String? email;
  final String? displayName;
  final String? phoneNumber;
  final String? photoURL;
  final bool? emailVerified;
  final Map<String, dynamic>? metadata;
  final Map<String, dynamic>? providerData;

  PigeonUserDetails({
    this.id,
    this.email,
    this.displayName,
    this.phoneNumber,
    this.photoURL,
    this.emailVerified,
    this.metadata,
    this.providerData,
  });

  factory PigeonUserDetails.fromMap(Map<String, dynamic> map) {
    try {
      return PigeonUserDetails(
        id: map['id'] as String?,
        email: map['email'] as String?,
        displayName: map['displayName'] as String?,
        phoneNumber: map['phoneNumber'] as String?,
        photoURL: map['photoURL'] as String?,
        emailVerified: map['emailVerified'] as bool?,
        metadata: map['metadata'] as Map<String, dynamic>?,
        providerData: map['providerData'] as Map<String, dynamic>?,
      );
    } catch (e) {
      debugPrint('[PigeonUserDetails] Error in fromMap: $e');
      return PigeonUserDetails();
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'emailVerified': emailVerified,
      'metadata': metadata,
      'providerData': providerData,
    };
  }

  @override
  String toString() {
    return 'PigeonUserDetails(id: $id, email: $email, displayName: $displayName, phoneNumber: $phoneNumber, photoURL: $photoURL, emailVerified: $emailVerified)';
  }

  // Méthode statique pour convertir en toute sécurité différents types en PigeonUserDetails
  static PigeonUserDetails? safeCast(dynamic value) {
    try {
      debugPrint('[PigeonUserDetails] safeCast: attempting to cast value of type ${value.runtimeType}');
      
      if (value == null) {
        debugPrint('[PigeonUserDetails] safeCast: value is null');
        return null;
      }

      if (value is PigeonUserDetails) {
        debugPrint('[PigeonUserDetails] safeCast: value is already PigeonUserDetails');
        return value;
      }

      if (value is Map<String, dynamic>) {
        debugPrint('[PigeonUserDetails] safeCast: converting Map to PigeonUserDetails');
        return PigeonUserDetails.fromMap(value);
      }

      if (value is List) {
        debugPrint('[PigeonUserDetails] safeCast: value is List, length: ${value.length}');
        if (value.isEmpty) {
          return null;
        }
        
        // Si la liste contient un seul élément, essayez de le convertir
        if (value.length == 1) {
          debugPrint('[PigeonUserDetails] safeCast: attempting to convert first list item');
          return safeCast(value[0]);
        }
        
        // Si la liste contient plusieurs éléments, essayez de convertir le premier qui n'est pas null
        for (var item in value) {
          if (item != null) {
            debugPrint('[PigeonUserDetails] safeCast: attempting to convert non-null list item');
            final result = safeCast(item);
            if (result != null) {
              return result;
            }
          }
        }
      }

      debugPrint('[PigeonUserDetails] safeCast: unsupported type: ${value.runtimeType}');
      return null;
    } catch (e) {
      debugPrint('[PigeonUserDetails] Error in safeCast: $e');
      return null;
    }
  }
}