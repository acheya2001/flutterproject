import 'dart:math';
import '../models/tunisian_insurance_models.dart';

/// 🧮 Service de calcul de prime d'assurance selon les règles tunisiennes
class TunisianInsuranceCalculator {
  
  /// 📊 Tarifs de base par type de véhicule (en TND)
  static const Map<String, double> _tarifBaseParType = {
    'voiture': 180.0,
    'camionnette': 250.0,
    'camion': 400.0,
    'moto': 120.0,
    'scooter': 80.0,
    'tracteur': 300.0,
    'remorque': 150.0,
  };

  /// 🔢 Coefficients par puissance fiscale
  static const Map<int, double> _coefficientPuissance = {
    4: 1.0,   // 4 CV
    5: 1.1,   // 5 CV
    6: 1.2,   // 6 CV
    7: 1.3,   // 7 CV
    8: 1.4,   // 8 CV
    9: 1.5,   // 9 CV
    10: 1.6,  // 10 CV
    11: 1.7,  // 11 CV et plus
  };

  /// 👤 Coefficients par âge du conducteur
  static const Map<String, double> _coefficientAge = {
    'jeune': 1.5,      // 18-25 ans
    'moyen': 1.0,      // 26-55 ans
    'senior': 1.2,     // 56+ ans
  };

  /// 📈 Coefficients par antécédents
  static const Map<String, double> _coefficientAntecedents = {
    'aucun': 1.0,           // Aucun accident
    'leger': 1.2,           // 1 accident léger
    'moyen': 1.4,           // 2-3 accidents ou 1 grave
    'lourd': 1.8,           // 4+ accidents ou multiples graves
  };

  /// 🛡️ Tarifs par type de couverture
  static const Map<String, double> _coefficientCouverture = {
    'responsabilite_civile': 1.0,     // RC obligatoire
    'tiers_collision': 1.3,           // RC + collision
    'vol_incendie': 1.5,              // RC + vol + incendie
    'tous_risques': 2.0,              // Couverture complète
    'tous_risques_premium': 2.5,     // Tous risques + options
  };

  /// 🏙️ Coefficients par zone géographique
  static const Map<String, double> _coefficientZone = {
    'tunis': 1.2,          // Grand Tunis
    'sfax': 1.1,           // Sfax
    'sousse': 1.1,         // Sousse
    'gabes': 1.0,          // Gabès
    'kairouan': 0.9,       // Kairouan
    'gafsa': 0.9,          // Gafsa
    'autre': 0.8,          // Autres villes
  };

  /// 💰 Calculer la prime d'assurance
  static Map<String, dynamic> calculerPrime({
    required String typeVehicule,
    required int puissanceFiscale,
    required int ageConducteur,
    required String niveauAntecedents,
    required String typeCouverture,
    required String zoneGeographique,
    required int anneeVehicule,
    List<String> optionsSupplementaires = const [],
  }) {
    
    // 1. Tarif de base selon le type de véhicule
    double tarifBase = _tarifBaseParType[typeVehicule.toLowerCase()] ?? 200.0;
    
    // 2. Coefficient puissance fiscale
    double coeffPuissance = _getCoeffPuissance(puissanceFiscale);
    
    // 3. Coefficient âge conducteur
    double coeffAge = _getCoeffAge(ageConducteur);
    
    // 4. Coefficient antécédents
    double coeffAntecedents = _coefficientAntecedents[niveauAntecedents] ?? 1.0;
    
    // 5. Coefficient type de couverture
    double coeffCouverture = _coefficientCouverture[typeCouverture] ?? 1.0;
    
    // 6. Coefficient zone géographique
    double coeffZone = _coefficientZone[zoneGeographique.toLowerCase()] ?? 1.0;
    
    // 7. Coefficient âge du véhicule
    double coeffAgeVehicule = _getCoeffAgeVehicule(anneeVehicule);
    
    // 8. Calcul de base
    double primeBase = tarifBase * coeffPuissance * coeffAge * 
                       coeffAntecedents * coeffCouverture * 
                       coeffZone * coeffAgeVehicule;
    
    // 9. Options supplémentaires
    double coutOptions = _calculerCoutOptions(optionsSupplementaires, primeBase);
    
    // 10. Prime totale
    double primeAnnuelle = primeBase + coutOptions;
    
    // 11. Taxes et frais (environ 15% en Tunisie)
    double taxes = primeAnnuelle * 0.15;
    double primeFinale = primeAnnuelle + taxes;
    
    // 12. Franchise selon la couverture
    double franchise = _calculerFranchise(typeCouverture, primeFinale);
    
    return {
      'primeBase': primeBase.round(),
      'coutOptions': coutOptions.round(),
      'taxes': taxes.round(),
      'primeAnnuelle': primeFinale.round(),
      'franchise': franchise.round(),
      'paiementMensuel': (primeFinale / 12).round(),
      'paiementTrimestriel': (primeFinale / 4).round(),
      'paiementSemestriel': (primeFinale / 2).round(),
      'details': {
        'tarifBase': tarifBase,
        'coeffPuissance': coeffPuissance,
        'coeffAge': coeffAge,
        'coeffAntecedents': coeffAntecedents,
        'coeffCouverture': coeffCouverture,
        'coeffZone': coeffZone,
        'coeffAgeVehicule': coeffAgeVehicule,
      },
      'recommandations': _genererRecommandations(
        typeCouverture, 
        ageConducteur, 
        anneeVehicule,
        niveauAntecedents
      ),
    };
  }

  /// 🔢 Obtenir le coefficient de puissance
  static double _getCoeffPuissance(int puissance) {
    if (puissance <= 4) return _coefficientPuissance[4]!;
    if (puissance >= 11) return _coefficientPuissance[11]!;
    return _coefficientPuissance[puissance] ?? 1.0;
  }

  /// 👤 Obtenir le coefficient d'âge
  static double _getCoeffAge(int age) {
    if (age <= 25) return _coefficientAge['jeune']!;
    if (age <= 55) return _coefficientAge['moyen']!;
    return _coefficientAge['senior']!;
  }

  /// 🚗 Coefficient selon l'âge du véhicule
  static double _getCoeffAgeVehicule(int annee) {
    int age = DateTime.now().year - annee;
    if (age <= 2) return 1.0;      // Véhicule neuf
    if (age <= 5) return 0.95;     // Véhicule récent
    if (age <= 10) return 0.9;     // Véhicule moyen
    if (age <= 15) return 0.85;    // Véhicule ancien
    return 0.8;                    // Véhicule très ancien
  }

  /// 🛡️ Calculer le coût des options
  static double _calculerCoutOptions(List<String> options, double primeBase) {
    double cout = 0.0;
    
    for (String option in options) {
      switch (option.toLowerCase()) {
        case 'bris_de_glace':
          cout += primeBase * 0.05;
          break;
        case 'assistance_depannage':
          cout += 50.0;
          break;
        case 'vehicule_remplacement':
          cout += primeBase * 0.08;
          break;
        case 'protection_juridique':
          cout += 30.0;
          break;
        case 'conducteur_novice':
          cout += primeBase * 0.1;
          break;
        case 'usage_professionnel':
          cout += primeBase * 0.15;
          break;
      }
    }
    
    return cout;
  }

  /// 💸 Calculer la franchise
  static double _calculerFranchise(String typeCouverture, double prime) {
    switch (typeCouverture) {
      case 'responsabilite_civile':
        return 0.0; // Pas de franchise pour RC
      case 'tiers_collision':
        return min(200.0, prime * 0.1);
      case 'vol_incendie':
        return min(300.0, prime * 0.12);
      case 'tous_risques':
        return min(500.0, prime * 0.15);
      case 'tous_risques_premium':
        return min(400.0, prime * 0.12);
      default:
        return 0.0;
    }
  }

  /// 💡 Générer des recommandations
  static List<String> _genererRecommandations(
    String typeCouverture, 
    int ageConducteur, 
    int anneeVehicule,
    String antecedents
  ) {
    List<String> recommandations = [];
    
    int ageVehicule = DateTime.now().year - anneeVehicule;
    
    // Recommandations selon l'âge du conducteur
    if (ageConducteur <= 25) {
      recommandations.add("💡 Jeune conducteur : Considérez une formation de conduite défensive pour réduire votre prime");
    }
    
    // Recommandations selon l'âge du véhicule
    if (ageVehicule <= 3 && typeCouverture == 'responsabilite_civile') {
      recommandations.add("🚗 Véhicule récent : Tous risques recommandé pour protéger votre investissement");
    }
    
    if (ageVehicule > 10 && typeCouverture == 'tous_risques') {
      recommandations.add("💰 Véhicule ancien : RC + Vol/Incendie peut être plus économique");
    }
    
    // Recommandations selon les antécédents
    if (antecedents != 'aucun') {
      recommandations.add("⚠️ Améliorez votre bonus-malus en conduisant prudemment");
    }
    
    // Recommandations générales
    recommandations.add("📱 Installez un système antivol pour réduire votre prime");
    recommandations.add("🏠 Garez votre véhicule dans un garage sécurisé si possible");
    
    return recommandations;
  }

  /// 📋 Obtenir les garanties disponibles par type de couverture
  static List<Map<String, dynamic>> getGarantiesDisponibles(String typeCouverture) {
    switch (typeCouverture) {
      case 'responsabilite_civile':
        return [
          {'nom': 'Responsabilité Civile', 'obligatoire': true, 'description': 'Dommages causés aux tiers'},
          {'nom': 'Défense Recours', 'obligatoire': true, 'description': 'Assistance juridique de base'},
        ];
      
      case 'tiers_collision':
        return [
          {'nom': 'Responsabilité Civile', 'obligatoire': true, 'description': 'Dommages causés aux tiers'},
          {'nom': 'Défense Recours', 'obligatoire': true, 'description': 'Assistance juridique'},
          {'nom': 'Collision', 'obligatoire': false, 'description': 'Dommages en cas de collision'},
        ];
      
      case 'vol_incendie':
        return [
          {'nom': 'Responsabilité Civile', 'obligatoire': true, 'description': 'Dommages causés aux tiers'},
          {'nom': 'Vol', 'obligatoire': false, 'description': 'Vol du véhicule ou d\'équipements'},
          {'nom': 'Incendie', 'obligatoire': false, 'description': 'Dommages par le feu'},
          {'nom': 'Catastrophes Naturelles', 'obligatoire': false, 'description': 'Inondations, grêle, etc.'},
        ];
      
      case 'tous_risques':
        return [
          {'nom': 'Responsabilité Civile', 'obligatoire': true, 'description': 'Dommages causés aux tiers'},
          {'nom': 'Dommages Collision', 'obligatoire': false, 'description': 'Tous dommages matériels'},
          {'nom': 'Vol', 'obligatoire': false, 'description': 'Vol du véhicule'},
          {'nom': 'Incendie', 'obligatoire': false, 'description': 'Dommages par le feu'},
          {'nom': 'Bris de Glace', 'obligatoire': false, 'description': 'Pare-brise et vitres'},
          {'nom': 'Catastrophes Naturelles', 'obligatoire': false, 'description': 'Événements climatiques'},
        ];
      
      default:
        return [];
    }
  }

  /// 🎯 Simuler différentes options de couverture
  static Map<String, dynamic> simulerOptions({
    required String typeVehicule,
    required int puissanceFiscale,
    required int ageConducteur,
    required String niveauAntecedents,
    required String zoneGeographique,
    required int anneeVehicule,
  }) {
    Map<String, dynamic> simulations = {};
    
    for (String typeCouverture in _coefficientCouverture.keys) {
      simulations[typeCouverture] = calculerPrime(
        typeVehicule: typeVehicule,
        puissanceFiscale: puissanceFiscale,
        ageConducteur: ageConducteur,
        niveauAntecedents: niveauAntecedents,
        typeCouverture: typeCouverture,
        zoneGeographique: zoneGeographique,
        anneeVehicule: anneeVehicule,
      );
    }
    
    return simulations;
  }
}
