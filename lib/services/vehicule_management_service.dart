import 'package:cloud_firestore/cloud_firestore.dart';

class VehiculeManagementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📋 Récupérer les véhicules d'un conducteur
  static Future<List<Map<String, dynamic>>> getVehiculesByConducteur(String conducteurId) async {
    final List<Map<String, dynamic>> vehicules = [];
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('vehicules')
          .where('conducteurId', isEqualTo: conducteurId)
          .where('status', isEqualTo: 'actif')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ajout de l'ID du document
        vehicules.add(data);
      }
      return vehicules;
    } catch (e) {
      print('❌ Erreur lors de la récupération des véhicules: $e');
      return [];
    }
  }

  /// ➕ Ajouter un nouveau véhicule
  static Future<void> addVehicle(Map<String, dynamic> vehicleData) async {
    try {
      await _firestore.collection('vehicules').add({
        ...vehicleData,
        'status': 'actif',
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Véhicule ajouté avec succès');
    } catch (e) {
      print('❌ Erreur lors de l\'ajout du véhicule: $e');
      throw Exception('Erreur lors de l\'ajout du véhicule');
    }
  }
}
