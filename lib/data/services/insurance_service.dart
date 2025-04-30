import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../models/insurance_model.dart';

class InsuranceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _agencesCollection => _firestore.collection('agences');
  CollectionReference get _contratsCollection => _firestore.collection('contrats');
  CollectionReference get _constatsCollection => _firestore.collection('constats');

  // Obtenir les détails d'une compagnie d'assurance
  Future<InsuranceCompany?> getInsuranceCompany(String insuranceId) async {
    try {
      final doc = await _usersCollection.doc(insuranceId).get();
      if (doc.exists && doc.data() != null) {
        return InsuranceCompany.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      _logger.e('Erreur lors de la récupération de la compagnie d\'assurance: $e');
      rethrow;
    }
  }

  // Obtenir toutes les compagnies d'assurance
  Future<List<InsuranceCompany>> getAllInsuranceCompanies() async {
    try {
      final snapshot = await _usersCollection
          .where('role', isEqualTo: 'assurance')
          .where('isActive', isEqualTo: true)
          .get();
      
      return snapshot.docs
          .map((doc) => InsuranceCompany.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Erreur lors de la récupération des compagnies d\'assurance: $e');
      rethrow;
    }
  }

  // Obtenir les agences d'une compagnie d'assurance
  Future<List<InsuranceAgency>> getAgenciesByInsurance(String insuranceId) async {
    try {
      final snapshot = await _agencesCollection
          .where('assuranceId', isEqualTo: insuranceId)
          .where('isActive', isEqualTo: true)
          .get();
      
      return snapshot.docs
          .map((doc) => InsuranceAgency.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Erreur lors de la récupération des agences: $e');
      rethrow;
    }
  }

  // Obtenir les contrats d'un conducteur
  Future<List<InsuranceContract>> getDriverContracts(String driverId) async {
    try {
      final snapshot = await _contratsCollection
          .where('conducteurId', isEqualTo: driverId)
          .orderBy('dateDebut', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => InsuranceContract.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Erreur lors de la récupération des contrats: $e');
      rethrow;
    }
  }

  // Obtenir les contrats actifs d'un conducteur
  Future<List<InsuranceContract>> getActiveDriverContracts(String driverId) async {
    try {
      final now = Timestamp.fromDate(DateTime.now());
      
      final snapshot = await _contratsCollection
          .where('conducteurId', isEqualTo: driverId)
          .where('dateFin', isGreaterThan: now)
          .where('statut', isEqualTo: 'actif')
          .get();
      
      return snapshot.docs
          .map((doc) => InsuranceContract.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Erreur lors de la récupération des contrats actifs: $e');
      rethrow;
    }
  }

  // Vérifier si un véhicule a un contrat d'assurance actif
  Future<bool> hasActiveInsurance(String vehicleId) async {
    try {
      final now = Timestamp.fromDate(DateTime.now());
      
      final snapshot = await _contratsCollection
          .where('vehiculeId', isEqualTo: vehicleId)
          .where('dateFin', isGreaterThan: now)
          .where('statut', isEqualTo: 'actif')
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      _logger.e('Erreur lors de la vérification de l\'assurance: $e');
      rethrow;
    }
  }

  // Obtenir le contrat actif d'un véhicule
  Future<InsuranceContract?> getActiveVehicleContract(String vehicleId) async {
    try {
      final now = Timestamp.fromDate(DateTime.now());
      
      final snapshot = await _contratsCollection
          .where('vehiculeId', isEqualTo: vehicleId)
          .where('dateFin', isGreaterThan: now)
          .where('statut', isEqualTo: 'actif')
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return InsuranceContract.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      _logger.e('Erreur lors de la récupération du contrat actif: $e');
      rethrow;
    }
  }

  // Créer un nouveau contrat d'assurance
  Future<String> createContract(InsuranceContract contract) async {
    try {
      final docRef = await _contratsCollection.add(contract.toFirestore());
      
      // Mettre à jour le véhicule avec l'ID du contrat actif
      await _firestore.collection('vehicules').doc(contract.vehicleId).update({
        'contratActifId': docRef.id,
        'updatedAt': Timestamp.now(),
      });
      
      return docRef.id;
    } catch (e) {
      _logger.e('Erreur lors de la création du contrat: $e');
      rethrow;
    }
  }

  // Obtenir les constats liés à une compagnie d'assurance
  Future<List<DocumentSnapshot>> getInsuranceReports(String insuranceId) async {
    try {
      // Constats où l'assurance est impliquée dans la partie A
      final snapshotA = await _constatsCollection
          .where('partieA.assuranceId', isEqualTo: insuranceId)
          .orderBy('date', descending: true)
          .get();
      
      // Constats où l'assurance est impliquée dans la partie B
      final snapshotB = await _constatsCollection
          .where('partieB.assuranceId', isEqualTo: insuranceId)
          .orderBy('date', descending: true)
          .get();
      
      // Combiner les résultats (en évitant les doublons)
      final Set<String> uniqueIds = {};
      final List<DocumentSnapshot> result = [];
      
      for (var doc in [...snapshotA.docs, ...snapshotB.docs]) {
        if (!uniqueIds.contains(doc.id)) {
          uniqueIds.add(doc.id);
          result.add(doc);
        }
      }
      
      // Trier par date (plus récent en premier)
      result.sort((a, b) {
        final dateA = (a.data() as Map<String, dynamic>)['date'] as Timestamp;
        final dateB = (b.data() as Map<String, dynamic>)['date'] as Timestamp;
        return dateB.compareTo(dateA);
      });
      
      return result;
    } catch (e) {
      _logger.e('Erreur lors de la récupération des constats: $e');
      rethrow;
    }
  }

  // Créer une nouvelle agence d'assurance
  Future<String> createAgency(InsuranceAgency agency) async {
    try {
      final docRef = await _agencesCollection.add(agency.toFirestore());
      
      // Mettre à jour la compagnie d'assurance avec l'ID de la nouvelle agence
      await _usersCollection.doc(agency.insuranceId).update({
        'agencyIds': FieldValue.arrayUnion([docRef.id]),
        'updatedAt': Timestamp.now(),
      });
      
      return docRef.id;
    } catch (e) {
      _logger.e('Erreur lors de la création de l\'agence: $e');
      rethrow;
    }
  }

  // Mettre à jour une agence d'assurance
  Future<void> updateAgency(String agencyId, Map<String, dynamic> data) async {
    try {
      await _agencesCollection.doc(agencyId).update({
        ...data,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      _logger.e('Erreur lors de la mise à jour de l\'agence: $e');
      rethrow;
    }
  }

  // Mettre à jour un contrat d'assurance
  Future<void> updateContract(String contractId, Map<String, dynamic> data) async {
    try {
      await _contratsCollection.doc(contractId).update({
        ...data,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      _logger.e('Erreur lors de la mise à jour du contrat: $e');
      rethrow;
    }
  }

  // Résilier un contrat d'assurance
  Future<void> terminateContract(String contractId, String reason) async {
    try {
      await _contratsCollection.doc(contractId).update({
        'statut': 'résilié',
        'raisonResiliation': reason,
        'dateResiliation': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      
      // Récupérer le contrat pour obtenir l'ID du véhicule
      final contractDoc = await _contratsCollection.doc(contractId).get();
      final vehicleId = (contractDoc.data() as Map<String, dynamic>)['vehiculeId'];
      
      // Mettre à jour le véhicule pour supprimer la référence au contrat actif
      await _firestore.collection('vehicules').doc(vehicleId).update({
        'contratActifId': null,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      _logger.e('Erreur lors de la résiliation du contrat: $e');
      rethrow;
    }
  }
}