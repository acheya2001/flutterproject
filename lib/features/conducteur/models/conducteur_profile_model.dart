import 'package:cloud_firestore/cloud_firestore.dart';

/// 📄 Document du conducteur
class ConducteurDocument {
  final String id;
  final String type; // 'carte_identite', 'permis_conduire'
  final String fileName;
  final String storagePath;
  final String downloadUrl;
  final DateTime uploadedAt;
  final bool isVerified;

  const ConducteurDocument({
    required this.id,
    required this.type,
    required this.fileName,
    required this.storagePath,
    required this.downloadUrl,
    required this.uploadedAt,
    this.isVerified = false,
  });

  factory ConducteurDocument.fromMap(Map<String, dynamic> map) {
    return ConducteurDocument(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      fileName: map['fileName'] ?? '',
      storagePath: map['storagePath'] ?? '',
      downloadUrl: map['downloadUrl'] ?? '',
      uploadedAt: (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerified: map['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'fileName': fileName,
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'isVerified': isVerified,
    };
  }
}

/// 🏠 Adresse du conducteur
class ConducteurAddress {
  final String street;
  final String city;
  final String postalCode;
  final String governorate;
  final String country;

  const ConducteurAddress({
    required this.street,
    required this.city,
    required this.postalCode,
    required this.governorate,
    this.country = 'Tunisie',
  });

  factory ConducteurAddress.fromMap(Map<String, dynamic> map) {
    return ConducteurAddress(
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      postalCode: map['postalCode'] ?? '',
      governorate: map['governorate'] ?? '',
      country: map['country'] ?? 'Tunisie',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'city': city,
      'postalCode': postalCode,
      'governorate': governorate,
      'country': country,
    };
  }

  String get fullAddress => '$street, $city $postalCode, $governorate, $country';
}

/// 🪪 Permis de conduire
class DrivingLicense {
  final String licenseNumber;
  final String category;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String issuingAuthority;

  const DrivingLicense({
    required this.licenseNumber,
    required this.category,
    required this.issueDate,
    required this.expiryDate,
    required this.issuingAuthority,
  });

  factory DrivingLicense.fromMap(Map<String, dynamic> map) {
    return DrivingLicense(
      licenseNumber: map['licenseNumber'] ?? '',
      category: map['category'] ?? '',
      issueDate: (map['issueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      issuingAuthority: map['issuingAuthority'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'licenseNumber': licenseNumber,
      'category': category,
      'issueDate': Timestamp.fromDate(issueDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'issuingAuthority': issuingAuthority,
    };
  }

  bool get isValid => expiryDate.isAfter(DateTime.now());
}

/// 👤 Profil complet du conducteur
class ConducteurProfileModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String cin;
  final String email;
  final String phone;
  final ConducteurAddress address;
  final DateTime dateOfBirth;
  final String? profileImageUrl;
  final List<ConducteurDocument> documents;
  final DrivingLicense? drivingLicense;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final bool isProfileComplete;
  final bool isVerified;
  final bool isFakeData;

  const ConducteurProfileModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.cin,
    required this.email,
    required this.phone,
    required this.address,
    required this.dateOfBirth,
    this.profileImageUrl,
    required this.documents,
    this.drivingLicense,
    required this.createdAt,
    required this.lastUpdatedAt,
    required this.isProfileComplete,
    this.isVerified = false,
    this.isFakeData = false,
  });

  factory ConducteurProfileModel.fromMap(Map<String, dynamic> map) {
    return ConducteurProfileModel(
      uid: map['uid'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      cin: map['cin'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: ConducteurAddress.fromMap(map['address'] ?? {}),
      dateOfBirth: (map['dateOfBirth'] as Timestamp?)?.toDate() ?? DateTime.now(),
      profileImageUrl: map['profileImageUrl'],
      documents: (map['documents'] as List?)
          ?.map((doc) => ConducteurDocument.fromMap(doc))
          .toList() ?? [],
      drivingLicense: map['drivingLicense'] != null
          ? DrivingLicense.fromMap(map['drivingLicense'])
          : null,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdatedAt: (map['lastUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isProfileComplete: map['isProfileComplete'] ?? false,
      isVerified: map['isVerified'] ?? false,
      isFakeData: map['isFakeData'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'cin': cin,
      'email': email,
      'phone': phone,
      'address': address.toMap(),
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'profileImageUrl': profileImageUrl,
      'documents': documents.map((doc) => doc.toMap()).toList(),
      'drivingLicense': drivingLicense?.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
      'isProfileComplete': isProfileComplete,
      'isVerified': isVerified,
      'isFakeData': isFakeData,
    };
  }

  String get fullName => '$firstName $lastName';
  
  bool get hasCarteIdentite => documents.any((doc) => doc.type == 'carte_identite');
  bool get hasPermisConduire => documents.any((doc) => doc.type == 'permis_conduire');
  
  ConducteurDocument? getDocument(String type) {
    try {
      return documents.firstWhere((doc) => doc.type == type);
    } catch (e) {
      return null;
    }
  }

  ConducteurProfileModel copyWith({
    String? uid,
    String? firstName,
    String? lastName,
    String? cin,
    String? email,
    String? phone,
    ConducteurAddress? address,
    DateTime? dateOfBirth,
    String? profileImageUrl,
    List<ConducteurDocument>? documents,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    bool? isProfileComplete,
    bool? isVerified,
    bool? isFakeData,
  }) {
    return ConducteurProfileModel(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      cin: cin ?? this.cin,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      documents: documents ?? this.documents,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      isVerified: isVerified ?? this.isVerified,
      isFakeData: isFakeData ?? this.isFakeData,
    );
  }
}
