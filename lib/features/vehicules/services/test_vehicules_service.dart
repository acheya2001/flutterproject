import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../core/utils/constants.dart';

/// 🧪 Service pour créer des véhicules de test
class TestVehiculesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🚗 Créer des véhicules de test pour l'utilisateur actuel
  Future<void> createTestVehicles() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('[TestVehiculesService] ❌ Utilisateur non authentifié');
        return;
      }

      debugPrint('[TestVehiculesService] 🚗 Création de véhicules de test...');

      debugPrint('[TestVehiculesService] 👤 User ID: ${user.uid}');

      final testVehicles = [
        {
          'client_id': 'test_conducteur_1', // Utiliser l'ID de test
          'assureur_id': 'STAR',
          'numero_contrat': 'STAR-2024-001234',
          'marque': 'Peugeot',
          'modele': '208',
          'annee': 2022,
          'immatriculation': '123 TUN 456',
          'couleur': 'Blanc',
          'numero_chassis': 'VF3XXXXXXXX123456',
          'puissance_fiscale': 7,
          'type_couverture': 'Tous Risques',
          'franchise': 300.0,
          'prime_annuelle': 850.0,
          'valeur_vehicule': 25000,
          'date_debut': Timestamp.fromDate(DateTime(2024, 1, 1)),
          'date_fin': Timestamp.fromDate(DateTime(2024, 12, 31)),
          'statut': 'actif',
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        },
        {
          'client_id': 'test_conducteur_1',
          'assureur_id': 'MAGHREBIA',
          'numero_contrat': 'MAG-2024-005678',
          'marque': 'Renault',
          'modele': 'Clio',
          'annee': 2021,
          'immatriculation': '789 TUN 012',
          'couleur': 'Rouge',
          'numero_chassis': 'VF1XXXXXXXX789012',
          'puissance_fiscale': 6,
          'type_couverture': 'Tiers Complet',
          'franchise': 250.0,
          'prime_annuelle': 650.0,
          'valeur_vehicule': 18000,
          'date_debut': Timestamp.fromDate(DateTime(2024, 3, 15)),
          'date_fin': Timestamp.fromDate(DateTime(2025, 3, 14)),
          'statut': 'actif',
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        },
        {
          'client_id': 'test_conducteur_1',
          'assureur_id': 'GAT',
          'numero_contrat': 'GAT-2024-009876',
          'marque': 'Volkswagen',
          'modele': 'Golf',
          'annee': 2023,
          'immatriculation': '345 TUN 678',
          'couleur': 'Bleu',
          'numero_chassis': 'WVW XXXXXXXX345678',
          'puissance_fiscale': 8,
          'type_couverture': 'Tous Risques',
          'franchise': 400.0,
          'prime_annuelle': 950.0,
          'valeur_vehicule': 32000,
          'date_debut': Timestamp.fromDate(DateTime(2024, 6, 1)),
          'date_fin': Timestamp.fromDate(DateTime(2025, 5, 31)),
          'statut': 'actif',
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        },
      ];

      final batch = _firestore.batch();
      
      for (final vehicleData in testVehicles) {
        final docRef = _firestore.collection(Constants.collectionVehiculesAssures).doc();
        batch.set(docRef, vehicleData);
      }

      await batch.commit();
      
      debugPrint('[TestVehiculesService] ✅ ${testVehicles.length} véhicules de test créés');
      
    } catch (e) {
      debugPrint('[TestVehiculesService] ❌ Erreur: $e');
      rethrow;
    }
  }

  /// 🗑️ Supprimer tous les véhicules de test
  Future<void> deleteTestVehicles() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final query = await _firestore
          .collection(Constants.collectionVehiculesAssures)
          .where('client_id', isEqualTo: user.uid)
          .get();

      final batch = _firestore.batch();
      
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      
      debugPrint('[TestVehiculesService] 🗑️ Véhicules de test supprimés');
      
    } catch (e) {
      debugPrint('[TestVehiculesService] ❌ Erreur suppression: $e');
    }
  }

  /// 📊 Vérifier les véhicules existants
  Future<int> countUserVehicles() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final query = await _firestore
          .collection(Constants.collectionVehiculesAssures)
          .where('client_id', isEqualTo: user.uid)
          .get();

      return query.docs.length;
    } catch (e) {
      debugPrint('[TestVehiculesService] ❌ Erreur comptage: $e');
      return 0;
    }
  }
}
