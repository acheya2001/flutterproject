import 'package:cloud_firestore/cloud_firestore.dart';

class InsuranceCompany {
  final String id;
  final String name;
  final String code; // Code unique de l'assurance
  final String email;
  final String phone;
  final String address;
  final String logo;
  final String website;
  final String registrationNumber; // Numéro de registre de commerce
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> agencyIds; // IDs des agences liées

  InsuranceCompany({
    required this.id,
    required this.name,
    required this.code,
    required this.email,
    required this.phone,
    required this.address,
    required this.logo,
    required this.website,
    required this.registrationNumber,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.agencyIds,
  });

  // Convertir un document Firestore en InsuranceCompany
  factory InsuranceCompany.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InsuranceCompany(
      id: doc.id,
      name: data['nomSociete'] ?? '',
      code: data['codeAssurance'] ?? '',
      email: data['email'] ?? '',
      phone: data['phoneNumber'] ?? '',
      address: data['profileData']['adresse'] ?? '',
      logo: data['profileData']['logo'] ?? '',
      website: data['profileData']['siteWeb'] ?? '',
      registrationNumber: data['profileData']['registreCommerce'] ?? '',
      isActive: data['isActive'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      agencyIds: List<String>.from(data['agencyIds'] ?? []),
    );
  }

  // Convertir l'objet InsuranceCompany en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nomSociete': name,
      'codeAssurance': code,
      'email': email,
      'phoneNumber': phone,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'agencyIds': agencyIds,
      'role': 'assurance',
      'profileData': {
        'adresse': address,
        'logo': logo,
        'siteWeb': website,
        'registreCommerce': registrationNumber,
      }
    };
  }
}

class InsuranceAgency {
  final String id;
  final String name;
  final String code; // Code unique de l'agence
  final String address;
  final String phone;
  final String email;
  final String insuranceId; // ID de la compagnie d'assurance parente
  final String managerName;
  final GeoPoint location;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  InsuranceAgency({
    required this.id,
    required this.name,
    required this.code,
    required this.address,
    required this.phone,
    required this.email,
    required this.insuranceId,
    required this.managerName,
    required this.location,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convertir un document Firestore en InsuranceAgency
  factory InsuranceAgency.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InsuranceAgency(
      id: doc.id,
      name: data['nom'] ?? '',
      code: data['codeAgence'] ?? '',
      address: data['adresse'] ?? '',
      phone: data['telephone'] ?? '',
      email: data['email'] ?? '',
      insuranceId: data['assuranceId'] ?? '',
      managerName: data['responsable'] ?? '',
      location: data['coordonnees'] ?? const GeoPoint(0, 0),
      isActive: data['isActive'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convertir l'objet InsuranceAgency en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nom': name,
      'codeAgence': code,
      'adresse': address,
      'telephone': phone,
      'email': email,
      'assuranceId': insuranceId,
      'responsable': managerName,
      'coordonnees': location,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class InsuranceContract {
  final String id;
  final String number; // Numéro de police
  final String vehicleId;
  final String driverId;
  final String insuranceId;
  final String agencyId;
  final DateTime startDate;
  final DateTime endDate;
  final String type; // tous risques, tiers, etc.
  final double coverageAmount;
  final double premium;
  final String status; // actif, expiré, résilié
  final Map<String, String> documents; // URLs des documents
  final DateTime createdAt;
  final DateTime updatedAt;

  InsuranceContract({
    required this.id,
    required this.number,
    required this.vehicleId,
    required this.driverId,
    required this.insuranceId,
    required this.agencyId,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.coverageAmount,
    required this.premium,
    required this.status,
    required this.documents,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convertir un document Firestore en InsuranceContract
  factory InsuranceContract.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InsuranceContract(
      id: doc.id,
      number: data['numero'] ?? '',
      vehicleId: data['vehiculeId'] ?? '',
      driverId: data['conducteurId'] ?? '',
      insuranceId: data['assuranceId'] ?? '',
      agencyId: data['agenceId'] ?? '',
      startDate: (data['dateDebut'] as Timestamp).toDate(),
      endDate: (data['dateFin'] as Timestamp).toDate(),
      type: data['typeContrat'] ?? '',
      coverageAmount: (data['montantCouverture'] ?? 0).toDouble(),
      premium: (data['prime'] ?? 0).toDouble(),
      status: data['statut'] ?? 'inactif',
      documents: Map<String, String>.from(data['documents'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convertir l'objet InsuranceContract en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'numero': number,
      'vehiculeId': vehicleId,
      'conducteurId': driverId,
      'assuranceId': insuranceId,
      'agenceId': agencyId,
      'dateDebut': Timestamp.fromDate(startDate),
      'dateFin': Timestamp.fromDate(endDate),
      'typeContrat': type,
      'montantCouverture': coverageAmount,
      'prime': premium,
      'statut': status,
      'documents': documents,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Vérifier si le contrat est actif à une date donnée
  bool isActiveAt(DateTime date) {
    return date.isAfter(startDate) && date.isBefore(endDate) && status == 'actif';
  }
}