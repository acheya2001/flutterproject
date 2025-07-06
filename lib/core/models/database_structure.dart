/// 🏗️ Structure complète de la base de données Firebase
/// 
/// Hiérarchie: Compagnies → Agences → Agents → Clients → Contrats → Constats
/// 
/// Collections principales:
/// 1. compagnies_assurance - Les compagnies d'assurance
/// 2. agences_assurance - Les agences de chaque compagnie
/// 3. agents_assurance - Les agents travaillant dans les agences
/// 4. conducteurs - Les clients/conducteurs
/// 5. contrats_assurance - Les contrats d'assurance
/// 6. vehicules_assures - Les véhicules assurés
/// 7. constats_accidents - Les déclarations d'accidents
/// 8. experts - Les experts (peuvent travailler avec plusieurs compagnies)

class DatabaseStructure {
  /// 📋 Collections Firestore
  static const String compagniesAssurance = 'compagnies_assurance';
  static const String agencesAssurance = 'agences_assurance';
  static const String agentsAssurance = 'agents_assurance';
  static const String conducteurs = 'conducteurs';
  static const String contratsAssurance = 'contrats_assurance';
  static const String vehiculesAssures = 'vehicules_assures';
  static const String constatsAccidents = 'constats_accidents';
  static const String experts = 'experts';
  static const String expertsCompagnies = 'experts_compagnies'; // Relation many-to-many

  /// 🏢 Structure Compagnie d'Assurance
  static Map<String, dynamic> compagnieStructure = {
    'id': 'string', // ID unique de la compagnie
    'nom': 'string', // Nom de la compagnie (ex: "STAR Assurances")
    'code': 'string', // Code court (ex: "STAR", "GAT", "BH")
    'logo': 'string?', // URL du logo
    'adresseSiege': 'string', // Adresse du siège social
    'telephone': 'string', // Téléphone principal
    'email': 'string', // Email principal
    'siteWeb': 'string?', // Site web
    'numeroRegistre': 'string', // Numéro de registre de commerce
    'dateCreation': 'timestamp', // Date de création dans le système
    'actif': 'boolean', // Compagnie active ou non
    'statistiques': {
      'nombreAgences': 'number',
      'nombreAgents': 'number',
      'nombreClients': 'number',
      'nombreContrats': 'number',
    },
  };

  /// 🏪 Structure Agence d'Assurance
  static Map<String, dynamic> agenceStructure = {
    'id': 'string', // ID unique de l'agence
    'compagnieId': 'string', // Référence à la compagnie
    'nom': 'string', // Nom de l'agence (ex: "Agence Tunis Centre")
    'code': 'string', // Code de l'agence (ex: "TUN001")
    'adresse': 'string', // Adresse complète
    'gouvernorat': 'string', // Gouvernorat
    'ville': 'string', // Ville
    'codePostal': 'string?', // Code postal
    'telephone': 'string', // Téléphone de l'agence
    'email': 'string', // Email de l'agence
    'responsable': 'string', // Nom du responsable
    'heuresOuverture': 'string', // Heures d'ouverture
    'coordonnees': { // Coordonnées GPS
      'latitude': 'number',
      'longitude': 'number',
    },
    'dateCreation': 'timestamp',
    'actif': 'boolean',
    'statistiques': {
      'nombreAgents': 'number',
      'nombreClients': 'number',
      'nombreContrats': 'number',
    },
  };

  /// 👨‍💼 Structure Agent d'Assurance
  static Map<String, dynamic> agentStructure = {
    'id': 'string', // ID unique (même que Firebase Auth UID)
    'compagnieId': 'string', // Référence à la compagnie
    'agenceId': 'string', // Référence à l'agence
    'email': 'string', // Email de connexion
    'nom': 'string', // Nom de famille
    'prenom': 'string', // Prénom
    'telephone': 'string', // Téléphone
    'numeroAgent': 'string', // Numéro d'agent unique
    'poste': 'string', // Poste occupé (Agent Commercial, Conseiller, etc.)
    'dateEmbauche': 'timestamp', // Date d'embauche
    'statut': 'string', // actif, suspendu, inactif
    'permissions': 'array', // Liste des permissions
    'photo': 'string?', // URL de la photo de profil
    'adresse': 'string?', // Adresse personnelle
    'dateNaissance': 'timestamp?', // Date de naissance
    'cin': 'string?', // Numéro CIN
    'dateCreation': 'timestamp',
    'derniereConnexion': 'timestamp?',
    'statistiques': {
      'nombreClients': 'number',
      'nombreContrats': 'number',
      'chiffreAffaires': 'number',
    },
  };

  /// 🚗 Structure Conducteur/Client
  static Map<String, dynamic> conducteurStructure = {
    'id': 'string', // ID unique (même que Firebase Auth UID)
    'email': 'string', // Email de connexion
    'nom': 'string', // Nom de famille
    'prenom': 'string', // Prénom
    'telephone': 'string', // Téléphone
    'cin': 'string', // Numéro CIN
    'adresse': 'string?', // Adresse
    'dateNaissance': 'timestamp?', // Date de naissance
    'numeroPermis': 'string?', // Numéro de permis de conduire
    'datePermis': 'timestamp?', // Date d'obtention du permis
    'photo': 'string?', // URL de la photo de profil
    'dateCreation': 'timestamp',
    'derniereConnexion': 'timestamp?',
    'statistiques': {
      'nombreVehicules': 'number',
      'nombreContrats': 'number',
      'nombreConstats': 'number',
    },
  };

  /// 📄 Structure Contrat d'Assurance
  static Map<String, dynamic> contratStructure = {
    'id': 'string', // ID unique du contrat
    'numeroContrat': 'string', // Numéro de contrat unique
    'compagnieId': 'string', // Référence à la compagnie
    'agenceId': 'string', // Référence à l'agence
    'agentId': 'string', // Référence à l'agent qui a créé le contrat
    'conducteurId': 'string', // Référence au conducteur/client
    'vehiculeId': 'string', // Référence au véhicule assuré
    'typeContrat': 'string', // responsabilite_civile, tous_risques, etc.
    'dateDebut': 'timestamp', // Date de début de couverture
    'dateFin': 'timestamp', // Date de fin de couverture
    'dateCreation': 'timestamp', // Date de création du contrat
    'statut': 'string', // actif, suspendu, expire, resilie
    'prime': {
      'montantAnnuel': 'number', // Prime annuelle
      'montantMensuel': 'number', // Prime mensuelle
      'devise': 'string', // TND
    },
    'couvertures': 'array', // Liste des couvertures incluses
    'franchises': 'map', // Franchises par type de sinistre
    'documents': 'array', // URLs des documents du contrat
    'historiquePaiements': 'array', // Historique des paiements
    'notes': 'string?', // Notes sur le contrat
  };

  /// 🚙 Structure Véhicule Assuré
  static Map<String, dynamic> vehiculeStructure = {
    'id': 'string', // ID unique du véhicule
    'conducteurId': 'string', // Référence au propriétaire
    'contratId': 'string', // Référence au contrat d'assurance
    'immatriculation': 'string', // Numéro d'immatriculation
    'marque': 'string', // Marque du véhicule
    'modele': 'string', // Modèle du véhicule
    'annee': 'number', // Année de fabrication
    'couleur': 'string', // Couleur du véhicule
    'numeroSerie': 'string', // Numéro de série/châssis
    'typeVehicule': 'string', // voiture, moto, camion, etc.
    'carburant': 'string', // essence, diesel, electrique, etc.
    'puissance': 'number?', // Puissance en chevaux
    'nombrePlaces': 'number?', // Nombre de places
    'valeurVehicule': 'number', // Valeur estimée du véhicule
    'dateAchat': 'timestamp?', // Date d'achat
    'kilometrage': 'number?', // Kilométrage actuel
    'photos': 'array', // URLs des photos du véhicule
    'documents': 'array', // URLs des documents (carte grise, etc.)
    'dateCreation': 'timestamp',
    'statut': 'string', // actif, vendu, accidente, etc.
  };

  /// 📋 Structure Constat d'Accident
  static Map<String, dynamic> constatStructure = {
    'id': 'string', // ID unique du constat
    'numeroConstat': 'string', // Numéro de constat unique
    'dateAccident': 'timestamp', // Date et heure de l'accident
    'lieuAccident': {
      'adresse': 'string',
      'ville': 'string',
      'gouvernorat': 'string',
      'coordonnees': {
        'latitude': 'number',
        'longitude': 'number',
      },
    },
    'vehiculeA': {
      'conducteurId': 'string',
      'vehiculeId': 'string',
      'contratId': 'string',
      'compagnieId': 'string',
      'degats': 'string',
      'pointImpact': 'string',
    },
    'vehiculeB': {
      'conducteurId': 'string?',
      'vehiculeId': 'string?',
      'contratId': 'string?',
      'compagnieId': 'string?',
      'degats': 'string?',
      'pointImpact': 'string?',
    },
    'circonstances': 'array', // Circonstances de l'accident
    'temoins': 'array', // Liste des témoins
    'photos': 'array', // URLs des photos de l'accident
    'croquis': 'string?', // URL du croquis de l'accident
    'rapportPolice': 'boolean', // Y a-t-il un rapport de police
    'numeroRapportPolice': 'string?', // Numéro du rapport de police
    'blesses': 'boolean', // Y a-t-il des blessés
    'degatsMateriels': 'boolean', // Y a-t-il des dégâts matériels
    'statut': 'string', // en_cours, valide, conteste, clos
    'expertiseRequise': 'boolean', // Expertise requise
    'expertId': 'string?', // ID de l'expert assigné
    'dateCreation': 'timestamp',
    'dateModification': 'timestamp?',
  };

  /// 🔍 Structure Expert
  static Map<String, dynamic> expertStructure = {
    'id': 'string', // ID unique (même que Firebase Auth UID)
    'email': 'string', // Email de connexion
    'nom': 'string', // Nom de famille
    'prenom': 'string', // Prénom
    'telephone': 'string', // Téléphone
    'numeroAgrement': 'string', // Numéro d'agrément
    'cabinet': 'string', // Nom du cabinet
    'adresseCabinet': 'string', // Adresse du cabinet
    'specialites': 'array', // Spécialités (automobile, moto, etc.)
    'zoneIntervention': 'array', // Zones géographiques d'intervention
    'tarifs': {
      'tarifHoraire': 'number',
      'tarifDeplacement': 'number',
    },
    'photo': 'string?', // URL de la photo de profil
    'cv': 'string?', // URL du CV
    'certifications': 'array', // Certifications et diplômes
    'dateCreation': 'timestamp',
    'derniereConnexion': 'timestamp?',
    'statut': 'string', // actif, suspendu, inactif
    'statistiques': {
      'nombreExpertises': 'number',
      'notesMoyennes': 'number',
      'tempsReponse': 'number', // En heures
    },
  };

  /// 🔗 Structure Expert-Compagnie (Relation Many-to-Many)
  static Map<String, dynamic> expertCompagnieStructure = {
    'id': 'string', // ID unique de la relation
    'expertId': 'string', // Référence à l'expert
    'compagnieId': 'string', // Référence à la compagnie
    'dateDebut': 'timestamp', // Date de début de collaboration
    'dateFin': 'timestamp?', // Date de fin de collaboration (si applicable)
    'statut': 'string', // actif, suspendu, termine
    'conditions': {
      'tarifNegocie': 'number?', // Tarif négocié spécifique
      'delaiIntervention': 'number', // Délai d'intervention en heures
      'zonesCouvertes': 'array', // Zones géographiques couvertes
    },
    'statistiques': {
      'nombreDossiers': 'number',
      'noteMoyenne': 'number',
      'tempsReponse': 'number',
    },
  };
}
