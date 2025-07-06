import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../features/vehicules/models/vehicule_assure_model.dart';
import '../core/utils/constants.dart';

/// 🧪 Créateur de données de test pour le développement
class TestDataCreator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🚗 Crée des véhicules de test pour différents assureurs
  Future<void> createTestVehicules() async {
    try {
      debugPrint('[TestDataCreator] Creating test vehicles...');

      // Véhicules STAR Assurances
      await _createVehicule(
        assureurId: 'STAR',
        numeroContrat: 'STAR-2024-001234',
        proprietaire: ProprietaireInfo(
          userId: 'test_conducteur_1', // Remplacez par un vrai userId
          nom: 'Ben Ahmed',
          prenom: 'Mohamed',
          cin: '12345678',
          telephone: '+216 98 123 456',
        ),
        vehicule: VehiculeInfo(
          marque: 'Peugeot',
          modele: '208',
          annee: 2020,
          couleur: 'Blanc',
          immatriculation: '123 TUN 456',
          numeroChassis: 'VF3208ABC123456',
          puissanceFiscale: 7,
        ),
        contrat: ContratInfo(
          dateDebut: DateTime(2024, 1, 1),
          dateFin: DateTime(2024, 12, 31),
          typeCouverture: 'Tous Risques',
          franchise: 200,
          primeAnnuelle: 850,
        ),
      );

      // Véhicules Maghrebia Assurances
      await _createVehicule(
        assureurId: 'MAGHREBIA',
        numeroContrat: 'MAG-2024-005678',
        proprietaire: ProprietaireInfo(
          userId: 'test_conducteur_1',
          nom: 'Ben Ahmed',
          prenom: 'Mohamed',
          cin: '12345678',
          telephone: '+216 98 123 456',
        ),
        vehicule: VehiculeInfo(
          marque: 'Renault',
          modele: 'Clio',
          annee: 2019,
          couleur: 'Rouge',
          immatriculation: '789 TUN 012',
          numeroChassis: 'VF1CLIO789012345',
          puissanceFiscale: 6,
        ),
        contrat: ContratInfo(
          dateDebut: DateTime(2024, 3, 15),
          dateFin: DateTime(2025, 3, 14),
          typeCouverture: 'Tiers Complet',
          franchise: 150,
          primeAnnuelle: 720,
        ),
      );

      // Véhicule GAT Assurances
      await _createVehicule(
        assureurId: 'GAT',
        numeroContrat: 'GAT-2024-009876',
        proprietaire: ProprietaireInfo(
          userId: 'test_conducteur_2',
          nom: 'Ben Salem',
          prenom: 'Fatma',
          cin: '87654321',
          telephone: '+216 98 765 432',
        ),
        vehicule: VehiculeInfo(
          marque: 'Volkswagen',
          modele: 'Golf',
          annee: 2021,
          couleur: 'Bleu',
          immatriculation: '345 TUN 678',
          numeroChassis: 'WVWGOLF345678901',
          puissanceFiscale: 8,
        ),
        contrat: ContratInfo(
          dateDebut: DateTime(2024, 6, 1),
          dateFin: DateTime(2025, 5, 31),
          typeCouverture: 'Tous Risques',
          franchise: 300,
          primeAnnuelle: 950,
        ),
      );

      // Véhicule avec contrat expiré (pour tester)
      await _createVehicule(
        assureurId: 'STAR',
        numeroContrat: 'STAR-2023-999999',
        proprietaire: ProprietaireInfo(
          userId: 'test_conducteur_1',
          nom: 'Ben Ahmed',
          prenom: 'Mohamed',
          cin: '12345678',
          telephone: '+216 98 123 456',
        ),
        vehicule: VehiculeInfo(
          marque: 'Citroën',
          modele: 'C3',
          annee: 2018,
          couleur: 'Gris',
          immatriculation: '999 TUN 888',
          numeroChassis: 'VF7C3999888777',
          puissanceFiscale: 5,
        ),
        contrat: ContratInfo(
          dateDebut: DateTime(2023, 1, 1),
          dateFin: DateTime(2023, 12, 31), // Expiré
          typeCouverture: 'Tiers',
          franchise: 100,
          primeAnnuelle: 450,
        ),
        statut: 'expire',
      );

      debugPrint('[TestDataCreator] Test vehicles created successfully!');
    } catch (e) {
      debugPrint('[TestDataCreator] Error creating test vehicles: $e');
      rethrow;
    }
  }

  /// 🏢 Crée des compagnies d'assurance de test
  Future<void> createTestAssureurs() async {
    try {
      debugPrint('[TestDataCreator] Creating test insurance companies...');

      final assureurs = [
        {
          'id': 'STAR',
          'nom': 'STAR Assurances',
          'code': 'STAR',
          'logo_url': 'https://example.com/star_logo.png',
          'contact': {
            'telephone': '+216 71 123 456',
            'email': 'contact@star.tn',
            'adresse': 'Avenue Habib Bourguiba, Tunis',
          },
          'agences': [
            {
              'agence_id': 'STAR_TUNIS_001',
              'nom': 'Agence Tunis Centre',
              'adresse': 'Rue de la Liberté, Tunis',
              'responsable': 'Ahmed Ben Ali',
            },
            {
              'agence_id': 'STAR_SFAX_001',
              'nom': 'Agence Sfax',
              'adresse': 'Avenue Hedi Chaker, Sfax',
              'responsable': 'Salma Trabelsi',
            },
          ],
          'statistiques': {
            'total_contrats': 15420,
            'constats_traites': 1250,
            'montant_total_sinistres': 2500000,
          },
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        },
        {
          'id': 'MAGHREBIA',
          'nom': 'Maghrebia Assurances',
          'code': 'MAG',
          'logo_url': 'https://example.com/maghrebia_logo.png',
          'contact': {
            'telephone': '+216 71 789 012',
            'email': 'contact@maghrebia.tn',
            'adresse': 'Avenue Mohamed V, Tunis',
          },
          'agences': [
            {
              'agence_id': 'MAG_TUNIS_001',
              'nom': 'Agence Tunis Lac',
              'adresse': 'Les Berges du Lac, Tunis',
              'responsable': 'Karim Mansouri',
            },
          ],
          'statistiques': {
            'total_contrats': 12800,
            'constats_traites': 980,
            'montant_total_sinistres': 1800000,
          },
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        },
        {
          'id': 'GAT',
          'nom': 'GAT Assurances',
          'code': 'GAT',
          'logo_url': 'https://example.com/gat_logo.png',
          'contact': {
            'telephone': '+216 71 345 678',
            'email': 'contact@gat.tn',
            'adresse': 'Rue Ibn Khaldoun, Tunis',
          },
          'agences': [
            {
              'agence_id': 'GAT_TUNIS_001',
              'nom': 'Agence Tunis Centre',
              'adresse': 'Avenue Bourguiba, Tunis',
              'responsable': 'Nadia Khelifi',
            },
          ],
          'statistiques': {
            'total_contrats': 8500,
            'constats_traites': 650,
            'montant_total_sinistres': 1200000,
          },
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        },
      ];

      for (final assureur in assureurs) {
        await _firestore
            .collection('assureurs_compagnies')
            .doc(assureur['id'] as String)
            .set(assureur);
      }

      debugPrint('[TestDataCreator] Test insurance companies created successfully!');
    } catch (e) {
      debugPrint('[TestDataCreator] Error creating test insurance companies: $e');
      rethrow;
    }
  }

  /// 📊 Crée des données analytics de test
  Future<void> createTestAnalytics() async {
    try {
      debugPrint('[TestDataCreator] Creating test analytics data...');

      final analytics = {
        'periode': '2024-06',
        'type': 'global',
        'kpis': {
          'nombre_constats': 125,
          'montant_sinistres': 350000,
          'delai_moyen_traitement': 5.2,
          'taux_satisfaction': 4.2,
          'fraudes_detectees': 3,
        },
        'tendances': {
          'evolution_sinistres': [
            {'mois': '2024-01', 'nombre': 98, 'montant': 280000},
            {'mois': '2024-02', 'nombre': 110, 'montant': 320000},
            {'mois': '2024-03', 'nombre': 125, 'montant': 350000},
            {'mois': '2024-04', 'nombre': 115, 'montant': 330000},
            {'mois': '2024-05', 'nombre': 130, 'montant': 380000},
            {'mois': '2024-06', 'nombre': 125, 'montant': 350000},
          ],
          'zones_accidentogenes': [
            {'zone': 'Centre Ville Tunis', 'accidents': 45},
            {'zone': 'Autoroute A1', 'accidents': 32},
            {'zone': 'Avenue Habib Bourguiba', 'accidents': 28},
            {'zone': 'Sfax Centre', 'accidents': 20},
          ],
        },
        'predictions': {
          'sinistres_prevus_mois_prochain': 135,
          'budget_previsionnel': 380000,
          'zones_risque_eleve': ['Sfax Centre', 'Sousse Nord'],
        },
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(Constants.collectionAnalytics)
          .doc('global_2024_06')
          .set(analytics);

      debugPrint('[TestDataCreator] Test analytics data created successfully!');
    } catch (e) {
      debugPrint('[TestDataCreator] Error creating test analytics: $e');
      rethrow;
    }
  }

  /// 🚗 Méthode helper pour créer un véhicule
  Future<void> _createVehicule({
    required String assureurId,
    required String numeroContrat,
    required ProprietaireInfo proprietaire,
    required VehiculeInfo vehicule,
    required ContratInfo contrat,
    String statut = 'actif',
    List<SinistreInfo> historiqueSinistres = const [],
  }) async {
    final vehiculeModel = VehiculeAssureModel(
      id: '', // Sera généré par Firestore
      assureurId: assureurId,
      numeroContrat: numeroContrat,
      proprietaire: proprietaire,
      vehicule: vehicule,
      contrat: contrat,
      statut: statut,
      historiqueSinistres: historiqueSinistres,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection(Constants.collectionVehiculesAssures)
        .add(vehiculeModel.toMap());
  }

  /// 🧹 Nettoie toutes les données de test
  Future<void> cleanTestData() async {
    try {
      debugPrint('[TestDataCreator] Cleaning test data...');

      // Supprimer les véhicules de test
      final vehiculesSnapshot = await _firestore
          .collection(Constants.collectionVehiculesAssures)
          .get();

      for (final doc in vehiculesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Supprimer les assureurs de test
      final assureursSnapshot = await _firestore
          .collection('assureurs_compagnies')
          .get();

      for (final doc in assureursSnapshot.docs) {
        await doc.reference.delete();
      }

      // Supprimer les analytics de test
      final analyticsSnapshot = await _firestore
          .collection(Constants.collectionAnalytics)
          .get();

      for (final doc in analyticsSnapshot.docs) {
        await doc.reference.delete();
      }

      debugPrint('[TestDataCreator] Test data cleaned successfully!');
    } catch (e) {
      debugPrint('[TestDataCreator] Error cleaning test data: $e');
      rethrow;
    }
  }

  /// 🚀 Crée toutes les données de test
  Future<void> createAllTestData() async {
    try {
      debugPrint('[TestDataCreator] Creating all test data...');
      
      await createTestAssureurs();
      await createTestVehicules();
      await createTestAnalytics();
      
      debugPrint('[TestDataCreator] All test data created successfully! 🎉');
    } catch (e) {
      debugPrint('[TestDataCreator] Error creating all test data: $e');
      rethrow;
    }
  }
}
