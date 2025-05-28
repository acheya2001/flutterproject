import 'package:flutter/foundation.dart';
import '../features/auth/models/pigeon_user_details.dart';

class PigeonService {
  // Convertit en toute sécurité un objet en PigeonUserDetails
  static PigeonUserDetails? convertToPigeonUserDetails(dynamic value) {
    try {
      debugPrint('[PigeonService] Converting to PigeonUserDetails: ${value.runtimeType}');
      
      return PigeonUserDetails.safeCast(value);
    } catch (e) {
      debugPrint('[PigeonService] Error converting to PigeonUserDetails: $e');
      return null;
    }
  }

  // Méthode utilitaire pour afficher le contenu d'un objet pour le débogage
  static void debugObject(String tag, dynamic object) {
    try {
      if (object == null) {
        debugPrint('[$tag] Object is null');
        return;
      }

      debugPrint('[$tag] Object type: ${object.runtimeType}');
      
      if (object is Map) {
        debugPrint('[$tag] Map content:');
        object.forEach((key, value) {
          debugPrint('[$tag]   $key: $value (${value?.runtimeType})');
        });
      } else if (object is List) {
        debugPrint('[$tag] List content (length: ${object.length}):');
        for (int i = 0; i < object.length; i++) {
          debugPrint('[$tag]   [$i]: ${object[i]} (${object[i]?.runtimeType})');
        }
      } else {
        debugPrint('[$tag] Object toString: $object');
      }
    } catch (e) {
      debugPrint('[$tag] Error debugging object: $e');
    }
  }
}