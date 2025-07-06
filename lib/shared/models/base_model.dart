import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

/// 🏗️ Modèle de base pour tous les objets métier
abstract class BaseModel {
  /// Identifiant unique
  String get id;
  
  /// Date de création
  DateTime get createdAt;
  
  /// Date de dernière modification
  DateTime get updatedAt;
  
  /// Utilisateur qui a créé l'objet
  String get createdBy;
  
  /// Utilisateur qui a modifié l'objet en dernier
  String? get updatedBy;
  
  /// Convertit le modèle en Map pour Firestore
  Map<String, dynamic> toFirestore();
  
  /// Crée une copie avec des champs modifiés
  BaseModel copyWith({
    DateTime? updatedAt,
    String? updatedBy,
  });
}

/// 🔧 Utilitaires pour les modèles
class ModelUtils {
  /// Convertit un Timestamp Firestore en DateTime
  static DateTime timestampToDateTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    } else {
      return DateTime.now();
    }
  }
  
  /// Convertit un DateTime en Timestamp pour Firestore
  static Timestamp dateTimeToTimestamp(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }
  
  /// Génère un ID unique
  static String generateId() {
    return FirebaseFirestore.instance.collection('temp').doc().id;
  }
  
  /// Valide un email
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }
  
  /// Valide un numéro de téléphone tunisien
  static bool isValidTunisianPhone(String phone) {
    return RegExp(r'^[0-9]{8}$').hasMatch(phone);
  }
  
  /// Valide un CIN tunisien
  static bool isValidTunisianCIN(String cin) {
    return RegExp(r'^[0-9]{8}$').hasMatch(cin);
  }
  
  /// Formate un nom (première lettre en majuscule)
  static String formatName(String name) {
    if (name.isEmpty) return name;
    return name.trim().split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
  
  /// Génère un matricule unique
  static String generateMatricule(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return '$prefix${timestamp.substring(timestamp.length - 6)}';
  }
}

/// 📍 Modèle pour les coordonnées géographiques
class GeoPoint {
  final double latitude;
  final double longitude;
  
  const GeoPoint({
    required this.latitude,
    required this.longitude,
  });
  
  factory GeoPoint.fromFirestore(dynamic data) {
    if (data is GeoPoint) {
      return GeoPoint(
        latitude: data.latitude,
        longitude: data.longitude,
      );
    } else if (data is Map<String, dynamic>) {
      return GeoPoint(
        latitude: (data['latitude'] as num).toDouble(),
        longitude: (data['longitude'] as num).toDouble(),
      );
    }
    throw ArgumentError('Invalid GeoPoint data: $data');
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
  
  /// Calcule la distance en kilomètres avec un autre point
  double distanceTo(GeoPoint other) {
    const double earthRadius = 6371; // Rayon de la Terre en km
    
    final double lat1Rad = latitude * (3.14159 / 180);
    final double lat2Rad = other.latitude * (3.14159 / 180);
    final double deltaLatRad = (other.latitude - latitude) * (3.14159 / 180);
    final double deltaLngRad = (other.longitude - longitude) * (3.14159 / 180);
    
    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);

    final double c = 2 * math.asin(math.sqrt(a));
    
    return earthRadius * c;
  }
  
  @override
  String toString() => 'GeoPoint($latitude, $longitude)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoPoint &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;
  
  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

/// 📧 Modèle pour les informations de contact
class ContactInfo {
  final String? email;
  final String? phone;
  final String? fax;
  final String? website;
  
  const ContactInfo({
    this.email,
    this.phone,
    this.fax,
    this.website,
  });
  
  factory ContactInfo.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return const ContactInfo();
    
    return ContactInfo(
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      fax: data['fax'] as String?,
      website: data['website'] as String?,
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (fax != null) 'fax': fax,
      if (website != null) 'website': website,
    };
  }
  
  ContactInfo copyWith({
    String? email,
    String? phone,
    String? fax,
    String? website,
  }) {
    return ContactInfo(
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fax: fax ?? this.fax,
      website: website ?? this.website,
    );
  }
}

/// 🏠 Modèle pour les adresses
class Address {
  final String street;
  final String city;
  final String postalCode;
  final String governorate;
  final String country;
  final GeoPoint? coordinates;
  
  const Address({
    required this.street,
    required this.city,
    required this.postalCode,
    required this.governorate,
    this.country = 'Tunisie',
    this.coordinates,
  });
  
  factory Address.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) {
      throw ArgumentError('Address data cannot be null');
    }
    
    return Address(
      street: data['street'] as String? ?? '',
      city: data['city'] as String? ?? '',
      postalCode: data['postalCode'] as String? ?? '',
      governorate: data['governorate'] as String? ?? '',
      country: data['country'] as String? ?? 'Tunisie',
      coordinates: data['coordinates'] != null 
          ? GeoPoint.fromFirestore(data['coordinates'])
          : null,
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'street': street,
      'city': city,
      'postalCode': postalCode,
      'governorate': governorate,
      'country': country,
      if (coordinates != null) 'coordinates': coordinates!.toFirestore(),
    };
  }
  
  /// Retourne l'adresse complète formatée
  String get fullAddress {
    return '$street, $city $postalCode, $governorate, $country';
  }
  
  Address copyWith({
    String? street,
    String? city,
    String? postalCode,
    String? governorate,
    String? country,
    GeoPoint? coordinates,
  }) {
    return Address(
      street: street ?? this.street,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      governorate: governorate ?? this.governorate,
      country: country ?? this.country,
      coordinates: coordinates ?? this.coordinates,
    );
  }
}

/// 📊 Modèle pour les statistiques
class Statistics {
  final int totalCount;
  final int activeCount;
  final int pendingCount;
  final int suspendedCount;
  final DateTime lastUpdated;
  
  const Statistics({
    required this.totalCount,
    required this.activeCount,
    required this.pendingCount,
    required this.suspendedCount,
    required this.lastUpdated,
  });
  
  factory Statistics.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) {
      return Statistics(
        totalCount: 0,
        activeCount: 0,
        pendingCount: 0,
        suspendedCount: 0,
        lastUpdated: DateTime.now(),
      );
    }
    
    return Statistics(
      totalCount: data['totalCount'] as int? ?? 0,
      activeCount: data['activeCount'] as int? ?? 0,
      pendingCount: data['pendingCount'] as int? ?? 0,
      suspendedCount: data['suspendedCount'] as int? ?? 0,
      lastUpdated: ModelUtils.timestampToDateTime(data['lastUpdated']),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'totalCount': totalCount,
      'activeCount': activeCount,
      'pendingCount': pendingCount,
      'suspendedCount': suspendedCount,
      'lastUpdated': ModelUtils.dateTimeToTimestamp(lastUpdated),
    };
  }
  
  /// Calcule le pourcentage d'actifs
  double get activePercentage {
    if (totalCount == 0) return 0.0;
    return (activeCount / totalCount) * 100;
  }
  
  /// Calcule le pourcentage en attente
  double get pendingPercentage {
    if (totalCount == 0) return 0.0;
    return (pendingCount / totalCount) * 100;
  }
}
