import 'package:flutter_test/flutter_test.dart';
import 'package:constat_tunisie/services/vehicule_management_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VehiculeManagementService', () {
    test('getVehiculesByConducteur returns empty list for invalid conducteurId', () async {
      // Arrange
      final conducteurId = 'invalid_id';

      // Act
      final vehicles = await VehiculeManagementService.getVehiculesByConducteur(conducteurId);

      // Assert
      expect(vehicles, isEmpty);
    });

    test('getVehiculesByConducteur handles errors gracefully', () async {
      // Arrange
      final conducteurId = 'test_error_id';

      // Act
      final vehicles = await VehiculeManagementService.getVehiculesByConducteur(conducteurId);

      // Assert
      expect(vehicles, isEmpty);
    });
  });
}
