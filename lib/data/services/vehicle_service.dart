import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import '../models/vehicle_model.dart';

class VehicleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Logger _logger = Logger();

  // Collection reference
  CollectionReference get _vehiculesCollection => _firestore.collection('vehicules');

  // Obtenir tous les véhicules d'un conducteur
  Future<List<VehicleModel>> getDriverVehicles(String driverId) async {
    try {
      final snapshot = await _vehiculesCollection
          .where('proprietaireId', isEqualTo: driverId)
          .get();
      
      return snapshot.docs
          .map((doc) => VehicleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Erreur lors de la récupération des véhicules: $e');
      rethrow;
    }
  }

  // Obtenir un véhicule par son ID
  Future<VehicleModel?> getVehicleById(String vehicleId) async {
    try {
      final doc = await _vehiculesCollection.doc(vehicleId).get();
      if (doc.exists) {
        return VehicleModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      _logger.e('Erreur lors de la récupération du véhicule: $e');
      rethrow;
    }
  }

  // Créer un nouveau véhicule
  Future<String> createVehicle(VehicleModel vehicle) async {
    try {
      final docRef = await _vehiculesCollection.add(vehicle.toFirestore());
      return docRef.id;
    } catch (e) {
      _logger.e('Erreur lors de la création du véhicule: $e');
      rethrow;
    }
  }

  // Mettre à jour un véhicule
  Future<void> updateVehicle(String vehicleId, Map<String, dynamic> data) async {
    try {
      await _vehiculesCollection.doc(vehicleId).update({
        ...data,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      _logger.e('Erreur lors de la mise à jour du véhicule: $e');
      rethrow;
    }
  }

  // Supprimer un véhicule
  Future<void> deleteVehicle(String vehicleId) async {
    try {
      // Vérifier si le véhicule a des contrats associés
      final contratsSnapshot = await _firestore.collection('contrats')
          .where('vehiculeId', isEqualTo: vehicleId)
          .get();
      
      if (contratsSnapshot.docs.isNotEmpty) {
        throw Exception('Ce véhicule a des contrats associés et ne peut pas être supprimé.');
      }
      
      // Supprimer les photos du véhicule dans Storage
      final vehicleDoc = await _vehiculesCollection.doc(vehicleId).get();
      final vehicleData = vehicleDoc.data() as Map<String, dynamic>;
      final photos = List<String>.from(vehicleData['photos'] ?? []);
      
      for (var photoUrl in photos) {
        try {
          await _storage.refFromURL(photoUrl).delete();
        } catch (e) {
          _logger.w('Impossible de supprimer la photo: $photoUrl - $e');
        }
      }
      
      // Supprimer le document du véhicule
      await _vehiculesCollection.doc(vehicleId).delete();
    } catch (e) {
      _logger.e('Erreur lors de la suppression du véhicule: $e');
      rethrow;
    }
  }

  // Télécharger une photo de véhicule
  Future<String> uploadVehiclePhoto(String vehicleId, File photo) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('vehicles/$vehicleId/$fileName');
      
      // Télécharger la photo
      final uploadTask = await storageRef.putFile(photo);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      // Mettre à jour le document du véhicule avec la nouvelle photo
      await _vehiculesCollection.doc(vehicleId).update({
        'photos': FieldValue.arrayUnion([downloadUrl]),
        'updatedAt': Timestamp.now(),
      });
      
      return downloadUrl;
    } catch (e) {
      _logger.e('Erreur lors du téléchargement de la photo: $e');
      rethrow;
    }
  }

  // Supprimer une photo de véhicule
  Future<void> deleteVehiclePhoto(String vehicleId, String photoUrl) async {
    try {
      // Supprimer la photo dans Storage
      await _storage.refFromURL(photoUrl).delete();
      
      // Mettre à jour le document du véhicule
      await _vehiculesCollection.doc(vehicleId).update({
        'photos': FieldValue.arrayRemove([photoUrl]),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      _logger.e('Erreur lors de la suppression de la photo: $e');
      rethrow;
    }
  }
}