import 'package:cloud_firestore/cloud_firestore.dart';

/// 🏪 Modèle d'agence d'assurance
class AgencyModel {
  final String id;
  final String companyId;
  final String name;
  final String code;
  final String address;
  final String phone;
  final String email;
  final String governorate;
  final String city;
  final String managerName;
  final String managerPhone;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final bool isFakeData;

  const AgencyModel({
    required this.id,
    required this.companyId,
    required this.name,
    required this.code,
    required this.address,
    required this.phone,
    required this.email,
    required this.governorate,
    required this.city,
    required this.managerName,
    required this.managerPhone,
    this.isActive = true,
    required this.createdAt,
    required this.lastUpdatedAt,
    this.isFakeData = false,
  });

  factory AgencyModel.fromMap(Map<String, dynamic> map) {
    return AgencyModel(
      id: map['id'] ?? '',
      companyId: map['companyId'] ?? '',
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      governorate: map['governorate'] ?? '',
      city: map['city'] ?? '',
      managerName: map['managerName'] ?? '',
      managerPhone: map['managerPhone'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdatedAt: (map['lastUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isFakeData: map['isFakeData'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'name': name,
      'code': code,
      'address': address,
      'phone': phone,
      'email': email,
      'governorate': governorate,
      'city': city,
      'managerName': managerName,
      'managerPhone': managerPhone,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
      'isFakeData': isFakeData,
    };
  }

  AgencyModel copyWith({
    String? id,
    String? companyId,
    String? name,
    String? code,
    String? address,
    String? phone,
    String? email,
    String? governorate,
    String? city,
    String? managerName,
    String? managerPhone,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    bool? isFakeData,
  }) {
    return AgencyModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      code: code ?? this.code,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      governorate: governorate ?? this.governorate,
      city: city ?? this.city,
      managerName: managerName ?? this.managerName,
      managerPhone: managerPhone ?? this.managerPhone,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      isFakeData: isFakeData ?? this.isFakeData,
    );
  }
}
