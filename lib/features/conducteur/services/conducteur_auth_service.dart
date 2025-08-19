import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/conducteur_profile_model.dart';
import '../models/conducteur_vehicle_model.dart';
import '../../admin/models/company_model.dart';
import '../../admin/models/agency_model.dart';

/// 🔐 Service d'authentification et gestion profil conducteur
class ConducteurAuthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const Uuid _uuid = Uuid();

  /// Inscription d'un nouveau conducteur
  static Future<String> registerConducteur({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String cin,
    required String phone,
    required ConducteurAddress address,
    required DateTime dateOfBirth,
    File? carteIdentiteFile,
    File? permisConduireFile,
    File? profileImageFile,
  }) async {
    try {
      // Créer le compte Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Uploader les documents
      final documents = <ConducteurDocument>[];
      
      if (carteIdentiteFile != null) {
        final carteIdentiteDoc = await _uploadDocument(
          uid, 
          carteIdentiteFile, 
          'carte_identite'
        );
        documents.add(carteIdentiteDoc);
      }

      if (permisConduireFile != null) {
        final permisDoc = await _uploadDocument(
          uid, 
          permisConduireFile, 
          'permis_conduire'
        );
        documents.add(permisDoc);
      }

      // Uploader photo de profil
      String? profileImageUrl;
      if (profileImageFile != null) {
        profileImageUrl = await _uploadProfileImage(uid, profileImageFile);
      }

      // Créer le profil conducteur
      final profile = ConducteurProfileModel(
        uid: uid,
        firstName: firstName,
        lastName: lastName,
        cin: cin,
        email: email,
        phone: phone,
        address: address,
        dateOfBirth: dateOfBirth,
        profileImageUrl: profileImageUrl,
        documents: documents,
        createdAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
        isProfileComplete: _isProfileComplete(documents),
      );

      // Sauvegarder dans Firestore
      await _firestore
          .collection('conducteurs')
          .doc(uid)
          .set(profile.toMap());

      // Mettre à jour le displayName Firebase
      await userCredential.user!.updateDisplayName('$firstName $lastName');

      // Log d'audit
      await _logAudit(
        action: 'conducteur_registered',
        actorUid: uid,
        targetId: uid,
        data: {
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
          'documentsCount': documents.length,
        },
      );

      return uid;
    } catch (e) {
      throw Exception('Erreur lors de l\'inscription: $e');
    }
  }

  /// Récupérer le profil d'un conducteur
  static Future<ConducteurProfileModel?> getConducteurProfile(String uid) async {
    try {
      final doc = await _firestore.collection('conducteurs').doc(uid).get();
      if (doc.exists) {
        return ConducteurProfileModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du profil: $e');
    }
  }

  /// Mettre à jour le profil conducteur
  static Future<void> updateConducteurProfile(ConducteurProfileModel profile) async {
    try {
      await _firestore
          .collection('conducteurs')
          .doc(profile.uid)
          .update(profile.copyWith(
            lastUpdatedAt: DateTime.now(),
            isProfileComplete: _isProfileComplete(profile.documents),
          ).toMap());

      await _logAudit(
        action: 'conducteur_profile_updated',
        actorUid: profile.uid,
        targetId: profile.uid,
        data: {'updatedFields': 'profile_info'},
      );
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  /// Ajouter un document au profil
  static Future<void> addDocumentToProfile({
    required String uid,
    required File file,
    required String documentType,
  }) async {
    try {
      final document = await _uploadDocument(uid, file, documentType);
      
      await _firestore.collection('conducteurs').doc(uid).update({
        'documents': FieldValue.arrayUnion([document.toMap()]),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
        'isProfileComplete': _isProfileComplete([document]), // Recalculer
      });

      await _logAudit(
        action: 'document_added',
        actorUid: uid,
        targetId: uid,
        data: {'documentType': documentType, 'fileName': document.fileName},
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du document: $e');
    }
  }

  /// Récupérer les compagnies d'assurance disponibles
  static Future<List<CompanyModel>> getAvailableCompanies() async {
    try {
      final snapshot = await _firestore
          .collection('compagnies_assurance')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => CompanyModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des compagnies: $e');
    }
  }

  /// Récupérer les agences d'une compagnie
  static Future<List<AgencyModel>> getAgenciesByCompany(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('compagnies_assurance')
          .doc(companyId)
          .collection('agences')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => AgencyModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des agences: $e');
    }
  }

  /// Ajouter un véhicule au conducteur
  static Future<String> addVehicleToConducteur({
    required String conducteurUid,
    // Informations véhicule
    required String plate,
    required String brand,
    required String model,
    required int year,
    required String color,
    required String carteGriseNumber,
    String? vin,
    required String fuelType,
    DateTime? firstRegistrationDate,
    // Informations conducteur
    required String conducteurNom,
    required String conducteurPrenom,
    required String conducteurAddress,
    required String conducteurPhone,
    required String conducteurEmail,
    required String permisNumber,
    DateTime? permisDeliveryDate,
    // Propriétaire
    required bool isConducteurOwner,
    VehicleOwner? owner,
    // Documents
    File? carteGriseFile,
    File? permisFile,
    File? carteIdentiteFile,
    List<File>? vehiclePhotos,
    // Assurance
    String? companyId,
    String? agencyId,
    String? contractNumber,
    DateTime? contractStartDate,
    DateTime? contractEndDate,
  }) async {
    try {
      final vehicleId = _uuid.v4();
      final documents = <VehicleDocument>[];

      // Upload des documents
      if (carteGriseFile != null) {
        final carteGriseDoc = await _uploadVehicleDocument(
          conducteurUid,
          vehicleId,
          carteGriseFile,
          'carte_grise',
        );
        documents.add(carteGriseDoc);
      }

      if (permisFile != null) {
        final permisDoc = await _uploadVehicleDocument(
          conducteurUid,
          vehicleId,
          permisFile,
          'permis_conduire',
        );
        documents.add(permisDoc);
      }

      if (carteIdentiteFile != null) {
        final carteIdentiteDoc = await _uploadVehicleDocument(
          conducteurUid,
          vehicleId,
          carteIdentiteFile,
          'carte_identite',
        );
        documents.add(carteIdentiteDoc);
      }

      // Upload des photos du véhicule
      if (vehiclePhotos != null && vehiclePhotos.isNotEmpty) {
        for (int i = 0; i < vehiclePhotos.length; i++) {
          final photoDoc = await _uploadVehicleDocument(
            conducteurUid,
            vehicleId,
            vehiclePhotos[i],
            'photo_vehicule_$i',
          );
          documents.add(photoDoc);
        }
      }

      // Créer le contrat si les infos sont fournies
      final contracts = <VehicleContract>[];
      if (companyId != null && agencyId != null && contractNumber != null) {
        // Récupérer les noms de la compagnie et agence
        final companyDoc = await _firestore
            .collection('compagnies_assurance')
            .doc(companyId)
            .get();
        final agencyDoc = await _firestore
            .collection('compagnies_assurance')
            .doc(companyId)
            .collection('agences')
            .doc(agencyId)
            .get();

        if (companyDoc.exists && agencyDoc.exists) {
          final contract = VehicleContract(
            contractId: _uuid.v4(),
            contractNumber: contractNumber,
            companyId: companyId,
            companyName: companyDoc.data()!['name'],
            agencyId: agencyId,
            agencyName: agencyDoc.data()!['name'],
            startDate: contractStartDate ?? DateTime.now(),
            endDate: contractEndDate ?? DateTime.now().add(const Duration(days: 365)),
            isActive: true,
          );
          contracts.add(contract);
        }
      }

      // Créer le véhicule avec toutes les informations
      final vehicle = ConducteurVehicleModel(
        vehicleId: vehicleId,
        conducteurUid: conducteurUid,
        // Informations véhicule
        plate: plate,
        brand: brand,
        model: model,
        year: year,
        vin: vin,
        color: color,
        carteGriseNumber: carteGriseNumber,
        fuelType: fuelType,
        firstRegistrationDate: firstRegistrationDate,
        // Informations conducteur
        conducteurNom: conducteurNom,
        conducteurPrenom: conducteurPrenom,
        conducteurAddress: conducteurAddress,
        conducteurPhone: conducteurPhone,
        conducteurEmail: conducteurEmail,
        permisNumber: permisNumber,
        permisDeliveryDate: permisDeliveryDate,
        // Propriétaire
        isConducteurOwner: isConducteurOwner,
        owner: owner,
        // Documents et contrats
        contracts: contracts,
        documents: documents,
        // Métadonnées
        createdAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
      );

      // Sauvegarder dans Firestore
      await _firestore
          .collection('conducteurs')
          .doc(conducteurUid)
          .collection('vehicles')
          .doc(vehicleId)
          .set(vehicle.toMap());

      await _logAudit(
        action: 'vehicle_added',
        actorUid: conducteurUid,
        targetId: vehicleId,
        data: {
          'plate': plate,
          'brand': brand,
          'model': model,
          'hasContract': contracts.isNotEmpty,
        },
      );

      return vehicleId;
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du véhicule: $e');
    }
  }

  /// Récupérer les véhicules d'un conducteur
  static Future<List<ConducteurVehicleModel>> getConducteurVehicles(String conducteurUid) async {
    try {
      print('🔍 [GET_VEHICLES] Recherche véhicules pour conducteur: $conducteurUid');

      // Essayer d'abord dans la collection 'conducteurs/{uid}/vehicles'
      // Requête simplifiée sans orderBy pour éviter l'erreur d'index
      final conducteurSnapshot = await _firestore
          .collection('conducteurs')
          .doc(conducteurUid)
          .collection('vehicles')
          .where('isActive', isEqualTo: true)
          .get();

      print('🔍 [GET_VEHICLES] Documents dans conducteurs/vehicles: ${conducteurSnapshot.docs.length}');

      // Si pas de véhicules dans conducteurs/vehicles, chercher dans 'vehicules'
      QuerySnapshot snapshot;
      if (conducteurSnapshot.docs.isEmpty) {
        print('🔍 [GET_VEHICLES] Recherche dans collection vehicules...');
        snapshot = await _firestore
            .collection('vehicules')
            .where('conducteurId', isEqualTo: conducteurUid)
            .get();
        print('🔍 [GET_VEHICLES] Documents dans vehicules: ${snapshot.docs.length}');
      } else {
        snapshot = conducteurSnapshot;
      }

      print('🔍 [GET_VEHICLES] Documents trouvés: ${snapshot.docs.length}');

      final vehicles = <ConducteurVehicleModel>[];

      for (final doc in snapshot.docs) {
        try {
          print('🔍 [GET_VEHICLES] Document ID: ${doc.id}');

          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            print('❌ [GET_VEHICLES] Document ${doc.id} a des données nulles');
            continue;
          }

          print('🔍 [GET_VEHICLES] Data keys: ${data.keys.toList()}');

          ConducteurVehicleModel vehicle;

          // Vérifier si c'est un modèle Vehicule (collection vehicules) ou ConducteurVehicleModel
          if (data.containsKey('marque') && data.containsKey('numeroImmatriculation')) {
            // C'est un modèle Vehicule, convertir en ConducteurVehicleModel
            print('🔍 [GET_VEHICLES] Conversion Vehicule -> ConducteurVehicleModel');
            vehicle = _convertVehiculeToModel(doc.id, data);
          } else {
            // C'est déjà un ConducteurVehicleModel
            print('🔍 [GET_VEHICLES] Parsing ConducteurVehicleModel direct');
            vehicle = ConducteurVehicleModel.fromMap(data);
          }

          vehicles.add(vehicle);
          print('🔍 [GET_VEHICLES] Véhicule ajouté: ${vehicle.brand} ${vehicle.model} (${vehicle.plate})');

        } catch (e) {
          print('❌ [GET_VEHICLES] Erreur parsing véhicule ${doc.id}: $e');
        }
      }

      print('🔍 [GET_VEHICLES] Total véhicules récupérés: ${vehicles.length}');
      return vehicles;

    } catch (e) {
      print('❌ [GET_VEHICLES] Erreur lors de la récupération: $e');
      throw Exception('Erreur lors de la récupération des véhicules: $e');
    }
  }

  /// Convertir un modèle Vehicule en ConducteurVehicleModel
  static ConducteurVehicleModel _convertVehiculeToModel(String vehicleId, Map<String, dynamic> data) {
    return ConducteurVehicleModel(
      vehicleId: vehicleId,
      conducteurUid: data['conducteurId'] ?? '',
      // Informations véhicule (mapping des champs)
      plate: data['numeroImmatriculation'] ?? '',
      brand: data['marque'] ?? '',
      model: data['modele'] ?? '',
      year: data['annee'] ?? DateTime.now().year,
      vin: data['numeroSerie'],
      color: data['couleur'] ?? '',
      carteGriseNumber: data['numeroCarteGrise'] ?? '',
      fuelType: data['carburant'] ?? 'essence',
      firstRegistrationDate: _parseDate(data['datePremiereImmatriculation']),
      // Informations conducteur
      conducteurNom: data['nomProprietaire'] ?? '',
      conducteurPrenom: data['prenomProprietaire'] ?? '',
      conducteurAddress: data['adresseProprietaire'] ?? '',
      conducteurPhone: '', // Pas disponible dans Vehicule
      conducteurEmail: '', // Pas disponible dans Vehicule
      permisNumber: data['numeroPermis'] ?? '',
      permisDeliveryDate: _parseDate(data['dateObtentionPermis']),
      // Propriétaire (toujours true pour ce modèle)
      isConducteurOwner: true,
      // Documents et contrats (vides pour l'instant)
      contracts: [],
      documents: [],
      // Métadonnées
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      lastUpdatedAt: _parseDate(data['updatedAt']) ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      isFakeData: false,
    );
  }

  /// Utilitaire pour parser les dates qui peuvent être Timestamp ou String
  static DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;

    try {
      if (dateValue is Timestamp) {
        return dateValue.toDate();
      } else if (dateValue is String) {
        return DateTime.parse(dateValue);
      } else {
        print('⚠️ [PARSE_DATE] Type de date non supporté: ${dateValue.runtimeType}');
        return null;
      }
    } catch (e) {
      print('❌ [PARSE_DATE] Erreur parsing date: $e');
      return null;
    }
  }

  /// Méthodes privées
  static Future<ConducteurDocument> _uploadDocument(
    String uid,
    File file,
    String documentType,
  ) async {
    final documentId = _uuid.v4();
    final fileName = '${documentType}_${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}';
    final storagePath = 'conducteurs/$uid/documents/$fileName';

    final ref = _storage.ref().child(storagePath);
    await ref.putFile(file);
    final downloadUrl = await ref.getDownloadURL();

    return ConducteurDocument(
      id: documentId,
      type: documentType,
      fileName: fileName,
      storagePath: storagePath,
      downloadUrl: downloadUrl,
      uploadedAt: DateTime.now(),
    );
  }

  static Future<VehicleDocument> _uploadVehicleDocument(
    String conducteurUid,
    String vehicleId,
    File file,
    String documentType,
  ) async {
    final documentId = _uuid.v4();
    final fileName = '${documentType}_${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}';
    final storagePath = 'conducteurs/$conducteurUid/vehicles/$vehicleId/documents/$fileName';

    final ref = _storage.ref().child(storagePath);
    await ref.putFile(file);
    final downloadUrl = await ref.getDownloadURL();

    return VehicleDocument(
      id: documentId,
      type: documentType,
      fileName: fileName,
      storagePath: storagePath,
      downloadUrl: downloadUrl,
      uploadedAt: DateTime.now(),
    );
  }

  static Future<String> _uploadProfileImage(String uid, File file) async {
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}';
    final storagePath = 'conducteurs/$uid/profile/$fileName';

    final ref = _storage.ref().child(storagePath);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  static bool _isProfileComplete(List<ConducteurDocument> documents) {
    final hasCarteIdentite = documents.any((doc) => doc.type == 'carte_identite');
    final hasPermisConduire = documents.any((doc) => doc.type == 'permis_conduire');
    return hasCarteIdentite && hasPermisConduire;
  }

  /// Obtenir les véhicules d'un conducteur
  static Future<List<ConducteurVehicleModel>> getVehicles(String conducteurUid) async {
    try {
      final querySnapshot = await _firestore
          .collection('conducteurs')
          .doc(conducteurUid)
          .collection('vehicles')
          .get();

      return querySnapshot.docs
          .map((doc) => ConducteurVehicleModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des véhicules: $e');
    }
  }



  static Future<void> _logAudit({
    required String action,
    required String actorUid,
    required String targetId,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection('audit_logs').add({
      'action': action,
      'actorUid': actorUid,
      'targetId': targetId,
      'data': data,
      'timestamp': FieldValue.serverTimestamp(),
      'userType': 'conducteur',
    });
  }
}
