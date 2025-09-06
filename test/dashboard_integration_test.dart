import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:constat_tunisie/services/vehicule_management_service.dart';
import 'package:constat_tunisie/features/conducteur/screens/modern_conducteur_dashboard.dart';

// Mocks
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference {}
class MockQuery extends Mock implements Query {}
class MockQuerySnapshot extends Mock implements QuerySnapshot {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}

void main() {
  group('Dashboard Integration Test', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockQuery mockQuery;
    late MockQuerySnapshot mockSnapshot;
    late MockDocumentSnapshot mockDocument;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      mockQuery = MockQuery();
      mockSnapshot = MockQuerySnapshot();
      mockDocument = MockDocumentSnapshot();

      // Configuration des mocks
      when(mockFirestore.collection('vehicules')).thenReturn(mockCollection);
      when(mockCollection.where('conducteurId', isEqualTo: 'test-uid'))
          .thenReturn(mockQuery);
      when(mockQuery.where('status', isEqualTo: 'actif')).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([mockDocument]);
      
      // Données de test
      when(mockDocument.data()).thenReturn({
        'numeroImmatriculation': '123-TUN-456',
        'marque': 'Renault',
        'modele': 'Clio',
        'annee': 2020,
        'couleur': 'Bleu',
        'carburant': 'essence',
      });
      when(mockDocument.id).thenReturn('vehicle-123');
    });

    test('getVehiculesByConducteur returns correct data structure', () async {
      // Cette méthode devrait retourner les données dans le format attendu
      final result = await VehiculeManagementService.getVehiculesByConducteur('test-uid');
      
      expect(result, isList);
      expect(result.length, 1);
      expect(result[0]['numeroImmatriculation'], '123-TUN-456');
      expect(result[0]['marque'], 'Renault');
      expect(result[0]['modele'], 'Clio');
      expect(result[0]['id'], 'vehicle-123');
    });

    test('_convertToConducteurVehicleModel converts data correctly', () {
      final dashboard = _ModernConducteurDashboardState();
      
      final testData = {
        'id': 'test-vehicle-id',
        'numeroImmatriculation': '123-TUN-456',
        'marque': 'Renault',
        'modele': 'Clio',
        'annee': 2020,
        'couleur': 'Bleu',
        'carburant': 'essence',
      };

      final result = dashboard._convertToConducteurVehicleModel(testData, 'test-uid');

      expect(result.vehicleId, 'test-vehicle-id');
      expect(result.plate, '123-TUN-456');
      expect(result.brand, 'Renault');
      expect(result.model, 'Clio');
      expect(result.year, 2020);
      expect(result.color, 'Bleu');
      expect(result.fuelType, 'essence');
      expect(result.conducteurUid, 'test-uid');
    });

    test('_convertToConducteurVehicleModel handles missing fields', () {
      final dashboard = _ModernConducteurDashboardState();
      
      final testData = {
        'id': 'test-vehicle-id',
        // Champs manquants
      };

      final result = dashboard._convertToConducteurVehicleModel(testData, 'test-uid');

      expect(result.vehicleId, 'test-vehicle-id');
      expect(result.plate, 'N/A');
      expect(result.brand, 'Marque inconnue');
      expect(result.model, 'Modèle inconnu');
      expect(result.year, greaterThan(2000)); // Année actuelle ou proche
      expect(result.color, 'Non spécifiée');
      expect(result.fuelType, 'essence');
    });
  });
}
