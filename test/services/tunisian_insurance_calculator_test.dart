import 'package:flutter_test/flutter_test.dart';
import 'package:constat_tunisie/services/tunisian_insurance_calculator.dart';

void main() {
  group('TunisianInsuranceCalculator Tests', () {
    
    test('Calcul prime de base - Voiture standard', () {
      final result = TunisianInsuranceCalculator.calculerPrime(
        typeVehicule: 'voiture',
        puissanceFiscale: 6,
        ageConducteur: 30,
        niveauAntecedents: 'aucun',
        typeCouverture: 'responsabilite_civile',
        zoneGeographique: 'tunis',
        anneeVehicule: 2020,
      );

      expect(result['primeAnnuelle'], isA<int>());
      expect(result['primeAnnuelle'], greaterThan(0));
      expect(result['franchise'], equals(0)); // RC n'a pas de franchise
      expect(result['details'], isA<Map<String, dynamic>>());
    });

    test('Calcul prime - Jeune conducteur (majoration)', () {
      final resultJeune = TunisianInsuranceCalculator.calculerPrime(
        typeVehicule: 'voiture',
        puissanceFiscale: 6,
        ageConducteur: 22, // Jeune conducteur
        niveauAntecedents: 'aucun',
        typeCouverture: 'responsabilite_civile',
        zoneGeographique: 'tunis',
        anneeVehicule: 2020,
      );

      final resultAdulte = TunisianInsuranceCalculator.calculerPrime(
        typeVehicule: 'voiture',
        puissanceFiscale: 6,
        ageConducteur: 35, // Conducteur expérimenté
        niveauAntecedents: 'aucun',
        typeCouverture: 'responsabilite_civile',
        zoneGeographique: 'tunis',
        anneeVehicule: 2020,
      );

      // Le jeune conducteur doit payer plus cher
      expect(resultJeune['primeAnnuelle'], greaterThan(resultAdulte['primeAnnuelle']));
    });

    test('Calcul prime - Tous risques vs RC', () {
      final resultRC = TunisianInsuranceCalculator.calculerPrime(
        typeVehicule: 'voiture',
        puissanceFiscale: 6,
        ageConducteur: 30,
        niveauAntecedents: 'aucun',
        typeCouverture: 'responsabilite_civile',
        zoneGeographique: 'tunis',
        anneeVehicule: 2020,
      );

      final resultTousRisques = TunisianInsuranceCalculator.calculerPrime(
        typeVehicule: 'voiture',
        puissanceFiscale: 6,
        ageConducteur: 30,
        niveauAntecedents: 'aucun',
        typeCouverture: 'tous_risques',
        zoneGeographique: 'tunis',
        anneeVehicule: 2020,
      );

      // Tous risques doit être plus cher que RC
      expect(resultTousRisques['primeAnnuelle'], greaterThan(resultRC['primeAnnuelle']));
      expect(resultTousRisques['franchise'], greaterThan(0));
    });

    test('Calcul prime - Zone géographique', () {
      final resultTunis = TunisianInsuranceCalculator.calculerPrime(
        typeVehicule: 'voiture',
        puissanceFiscale: 6,
        ageConducteur: 30,
        niveauAntecedents: 'aucun',
        typeCouverture: 'responsabilite_civile',
        zoneGeographique: 'tunis',
        anneeVehicule: 2020,
      );

      final resultAutre = TunisianInsuranceCalculator.calculerPrime(
        typeVehicule: 'voiture',
        puissanceFiscale: 6,
        ageConducteur: 30,
        niveauAntecedents: 'aucun',
        typeCouverture: 'responsabilite_civile',
        zoneGeographique: 'autre',
        anneeVehicule: 2020,
      );

      // Tunis doit être plus cher que les autres villes
      expect(resultTunis['primeAnnuelle'], greaterThan(resultAutre['primeAnnuelle']));
    });

    test('Calcul prime - Antécédents d\'accidents', () {
      final resultAucun = TunisianInsuranceCalculator.calculerPrime(
        typeVehicule: 'voiture',
        puissanceFiscale: 6,
        ageConducteur: 30,
        niveauAntecedents: 'aucun',
        typeCouverture: 'responsabilite_civile',
        zoneGeographique: 'tunis',
        anneeVehicule: 2020,
      );

      final resultLourd = TunisianInsuranceCalculator.calculerPrime(
        typeVehicule: 'voiture',
        puissanceFiscale: 6,
        ageConducteur: 30,
        niveauAntecedents: 'lourd',
        typeCouverture: 'responsabilite_civile',
        zoneGeographique: 'tunis',
        anneeVehicule: 2020,
      );

      // Antécédents lourds = prime plus élevée
      expect(resultLourd['primeAnnuelle'], greaterThan(resultAucun['primeAnnuelle']));
    });

    test('Calcul prime - Options supplémentaires', () {
      final resultSansOptions = TunisianInsuranceCalculator.calculerPrime(
        typeVehicule: 'voiture',
        puissanceFiscale: 6,
        ageConducteur: 30,
        niveauAntecedents: 'aucun',
        typeCouverture: 'responsabilite_civile',
        zoneGeographique: 'tunis',
        anneeVehicule: 2020,
        optionsSupplementaires: [],
      );

      final resultAvecOptions = TunisianInsuranceCalculator.calculerPrime(
        typeVehicule: 'voiture',
        puissanceFiscale: 6,
        ageConducteur: 30,
        niveauAntecedents: 'aucun',
        typeCouverture: 'responsabilite_civile',
        zoneGeographique: 'tunis',
        anneeVehicule: 2020,
        optionsSupplementaires: ['bris_de_glace', 'assistance_depannage'],
      );

      // Avec options = plus cher
      expect(resultAvecOptions['primeAnnuelle'], greaterThan(resultSansOptions['primeAnnuelle']));
      expect(resultAvecOptions['coutOptions'], greaterThan(0));
    });

    test('Simulation options - Toutes les couvertures', () {
      final simulation = TunisianInsuranceCalculator.simulerOptions(
        typeVehicule: 'voiture',
        puissanceFiscale: 6,
        ageConducteur: 30,
        niveauAntecedents: 'aucun',
        zoneGeographique: 'tunis',
        anneeVehicule: 2020,
      );

      expect(simulation, isA<Map<String, dynamic>>());
      expect(simulation.containsKey('responsabilite_civile'), isTrue);
      expect(simulation.containsKey('tous_risques'), isTrue);
      
      // Vérifier l'ordre des prix
      final primeRC = simulation['responsabilite_civile']['primeAnnuelle'];
      final primeTousRisques = simulation['tous_risques']['primeAnnuelle'];
      expect(primeTousRisques, greaterThan(primeRC));
    });

    test('Garanties disponibles par type de couverture', () {
      final garantiesRC = TunisianInsuranceCalculator.getGarantiesDisponibles('responsabilite_civile');
      final garantiesTousRisques = TunisianInsuranceCalculator.getGarantiesDisponibles('tous_risques');

      expect(garantiesRC.length, greaterThan(0));
      expect(garantiesTousRisques.length, greaterThan(garantiesRC.length));
      
      // RC doit avoir au moins la responsabilité civile obligatoire
      final rcObligatoire = garantiesRC.firstWhere(
        (g) => g['nom'] == 'Responsabilité Civile' && g['obligatoire'] == true,
      );
      expect(rcObligatoire, isNotNull);
    });

    test('Recommandations générées', () {
      final result = TunisianInsuranceCalculator.calculerPrime(
        typeVehicule: 'voiture',
        puissanceFiscale: 6,
        ageConducteur: 22, // Jeune conducteur
        niveauAntecedents: 'aucun',
        typeCouverture: 'responsabilite_civile',
        zoneGeographique: 'tunis',
        anneeVehicule: 2023, // Véhicule récent
      );

      expect(result['recommandations'], isA<List<String>>());
      expect(result['recommandations'].length, greaterThan(0));
      
      // Doit contenir une recommandation pour jeune conducteur
      final recommandationsText = result['recommandations'].join(' ');
      expect(recommandationsText.toLowerCase(), contains('jeune'));
    });
  });
}
