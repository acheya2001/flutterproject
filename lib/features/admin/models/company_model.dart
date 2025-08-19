import 'package:cloud_firestore/cloud_firestore.dart';

/// 🏢 Modèle de compagnie d'assurance
class CompanyModel {
  final String id;
  final String name;
  final String code;
  final String address;
  final String phone;
  final String email;
  final String governorate;
  final String agrementNumber;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final bool isFakeData;

  const CompanyModel({
    required this.id,
    required this.name,
    required this.code,
    required this.address,
    required this.phone,
    required this.email,
    required this.governorate,
    required this.agrementNumber,
    this.isActive = true,
    required this.createdAt,
    required this.lastUpdatedAt,
    this.isFakeData = false,
  });

  factory CompanyModel.fromMap(Map<String, dynamic> map) {
    return CompanyModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      governorate: map['governorate'] ?? '',
      agrementNumber: map['agrementNumber'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdatedAt: (map['lastUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isFakeData: map['isFakeData'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'address': address,
      'phone': phone,
      'email': email,
      'governorate': governorate,
      'agrementNumber': agrementNumber,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
      'isFakeData': isFakeData,
    };
  }

  CompanyModel copyWith({
    String? id,
    String? name,
    String? code,
    String? address,
    String? phone,
    String? email,
    String? governorate,
    String? agrementNumber,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    bool? isFakeData,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      governorate: governorate ?? this.governorate,
      agrementNumber: agrementNumber ?? this.agrementNumber,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      isFakeData: isFakeData ?? this.isFakeData,
    );
  }
}
