/// 🚗 Constantes pour les véhicules en Tunisie
class VehiculeConstants {
  
  /// Catégories officielles de véhicules en Tunisie
  static const Map<String, String> categoriesVehicules = {
    'VP': 'VP - Véhicule Particulier (voiture personnelle, familiale)',
    'VU': 'VU - Véhicule Utilitaire (camionnettes, fourgonnettes)',
    'PL': 'PL - Poids Lourds (camions, semi-remorques)',
    'MOTO': 'MOTO - Motos, scooters, cyclomoteurs',
    'TAXI': 'TAXI - Taxis individuels ou collectifs',
    'LOUEUR': 'LOUEUR - Véhicule de location courte ou longue durée',
    'BUS': 'BUS/MINIBUS - Transport de personnes (public ou privé)',
    'AMBULANCE': 'AMBULANCE - Véhicule médicalisé ou non',
    'TRACTEUR': 'TRACTEUR - Tracteur routier ou agricole',
    'ENGIN': 'ENGIN SPÉCIAL - Engins de chantier (grue, pelle, etc.)',
    'REMORQUE': 'REMORQUE/SEMI-REMORQUE - Véhicules sans moteur',
    'AUTO_ECOLE': 'AUTO-ÉCOLE - Véhicules d\'apprentissage de la conduite',
    'DIPLOMATIQUE': 'VOITURE DIPLOMATIQUE - Plaques spéciales (CD, CMD)',
    'ADMINISTRATIF': 'VÉHICULE ADMINISTRATIF - État ou collectivité publique',
  };

  /// Types de carburant
  static const List<String> typesCarburant = [
    'Essence',
    'Diesel',
    'Électrique',
    'Hybride',
    'GPL',
    'GNV', // Gaz Naturel Véhicule
  ];

  /// Types d'usage
  static const Map<String, String> typesUsage = {
    'Personnel': 'Personnel - Usage privé',
    'Professionnel': 'Professionnel - Travail',
    'Taxi': 'Taxi - Transport public',
    'Location': 'Location - Véhicule de location',
    'Commercial': 'Commercial - Livraisons/Commerce',
    'Agricole': 'Agricole - Exploitation agricole',
    'Transport': 'Transport - Transport de marchandises',
    'Urgence': 'Urgence - Véhicules d\'urgence',
  };

  /// Catégories de permis de conduire en Tunisie
  static const Map<String, String> categoriesPermis = {
    'A': 'Catégorie A - Motocyclettes',
    'A1': 'Catégorie A1 - Motocyclettes légères',
    'B': 'Catégorie B - Véhicules particuliers',
    'C': 'Catégorie C - Poids lourds',
    'D': 'Catégorie D - Transport de personnes',
    'E': 'Catégorie E - Véhicules avec remorque',
  };

  /// Types d'assurance
  static const List<String> typesAssurance = [
    'Au tiers',
    'Tiers étendu',
    'Tous risques',
    'Vol et incendie',
    'Dommages collision',
  ];

  /// États du compte
  static const List<String> etatsCompte = [
    'Actif',
    'Suspendu',
    'En attente',
    'Bloqué',
  ];

  /// Nombre de places par défaut selon le type de véhicule
  static const Map<String, int> placesParDefaut = {
    'VP': 5,
    'VU': 3,
    'PL': 3,
    'MOTO': 2,
    'TAXI': 5,
    'LOUEUR': 5,
    'BUS': 20,
    'AMBULANCE': 4,
    'TRACTEUR': 2,
    'ENGIN': 2,
    'REMORQUE': 0,
    'AUTO_ECOLE': 5,
    'DIPLOMATIQUE': 5,
    'ADMINISTRATIF': 5,
  };

  /// Couleurs communes des véhicules
  static const List<String> couleursVehicules = [
    'Blanc',
    'Noir',
    'Gris',
    'Argent',
    'Bleu',
    'Rouge',
    'Vert',
    'Jaune',
    'Orange',
    'Marron',
    'Violet',
    'Rose',
    'Beige',
    'Doré',
  ];

  /// Marques de véhicules populaires en Tunisie
  static const List<String> marquesPopulaires = [
    'Renault',
    'Peugeot',
    'Citroën',
    'Volkswagen',
    'Toyota',
    'Hyundai',
    'Kia',
    'Nissan',
    'Ford',
    'Opel',
    'Fiat',
    'Seat',
    'Skoda',
    'Dacia',
    'Suzuki',
    'Mitsubishi',
    'Mazda',
    'Honda',
    'BMW',
    'Mercedes-Benz',
    'Audi',
  ];

  /// Validation des données
  static String? validateImmatriculation(String immatriculation) {
    if (immatriculation.isEmpty) {
      return 'Le numéro d\'immatriculation est obligatoire';
    }
    
    // Format tunisien : XXX TU XXXX ou XXX TUN XXXX
    final regex = RegExp(r'^\d{1,4}\s?(TU|TUN)\s?\d{1,4}$', caseSensitive: false);
    if (!regex.hasMatch(immatriculation.replaceAll(' ', ' '))) {
      return 'Format invalide. Ex: 123 TU 456 ou 1234 TUN 5678';
    }
    
    return null;
  }

  static String? validateVIN(String vin) {
    if (vin.isEmpty) {
      return 'Le numéro de série (VIN) est obligatoire';
    }
    
    if (vin.length != 17) {
      return 'Le VIN doit contenir exactement 17 caractères';
    }
    
    // Caractères interdits dans un VIN
    if (vin.contains(RegExp(r'[IOQ]'))) {
      return 'Le VIN ne peut pas contenir les lettres I, O ou Q';
    }
    
    return null;
  }

  static String? validateCarteGrise(String numeroCarteGrise) {
    if (numeroCarteGrise.isEmpty) {
      return 'Le numéro de carte grise est obligatoire';
    }
    
    if (numeroCarteGrise.length < 6) {
      return 'Le numéro de carte grise doit contenir au moins 6 caractères';
    }
    
    return null;
  }

  static String? validatePermis(String numeroPermis) {
    if (numeroPermis.isEmpty) {
      return 'Le numéro de permis est obligatoire';
    }
    
    if (numeroPermis.length < 6) {
      return 'Le numéro de permis doit contenir au moins 6 caractères';
    }
    
    return null;
  }

  /// Obtenir la description d'une catégorie
  static String getDescriptionCategorie(String categorie) {
    return categoriesVehicules[categorie] ?? 'Catégorie inconnue';
  }

  /// Obtenir le nombre de places par défaut
  static int getPlacesParDefaut(String typeVehicule) {
    return placesParDefaut[typeVehicule] ?? 5;
  }

  /// Vérifier si un véhicule nécessite un permis spécial
  static bool necessitePermisSpecial(String typeVehicule) {
    return ['PL', 'BUS', 'TRACTEUR', 'ENGIN'].contains(typeVehicule);
  }

  /// Obtenir les catégories de permis recommandées pour un type de véhicule
  static List<String> getPermisRecommandes(String typeVehicule) {
    switch (typeVehicule) {
      case 'MOTO':
        return ['A', 'A1'];
      case 'PL':
      case 'TRACTEUR':
        return ['C'];
      case 'BUS':
        return ['D'];
      case 'REMORQUE':
        return ['E'];
      default:
        return ['B'];
    }
  }
}
