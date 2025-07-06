import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
// import '../models/assurance_data_model.dart'; // Import inutilisé
import '../../../core/utils/constants.dart';
import 'dart:math';

/// 🏭 Service de génération automatique de données d'assurance
class AutoDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  /// 🚀 Générer automatiquement toutes les données d'assurance
  Future<void> generateAllInsuranceData({
    int nombreVehicules = 2000,
    int nombreConstats = 500,
    int nombreClients = 1500,
    bool showProgress = true,
  }) async {
    try {
      debugPrint('[AutoDataService] 🚀 Génération automatique démarrée...');

      // Vérifier l'authentification
      await _ensureAuthenticated();

      // 1. Créer les compagnies d'assurance
      await _createInsuranceCompanies();
      
      // 2. Générer les clients
      final clientsIds = await _generateClients(nombreClients, showProgress);
      
      // 3. Générer les véhicules assurés
      final vehiculesIds = await _generateInsuredVehicles(nombreVehicules, clientsIds, showProgress);
      
      // 4. Générer les constats
      await _generateAccidentReports(nombreConstats, vehiculesIds, clientsIds, showProgress);
      
      // 5. Générer les statistiques
      await _generateInsuranceStats();
      
      // 6. Créer les utilisateurs assureurs
      await _createInsuranceUsers();

      debugPrint('[AutoDataService] ✅ Génération automatique terminée !');
      debugPrint('[AutoDataService] 📊 Résumé:');
      debugPrint('[AutoDataService]   - 8 compagnies d\'assurance');
      debugPrint('[AutoDataService]   - $nombreClients clients');
      debugPrint('[AutoDataService]   - $nombreVehicules véhicules assurés');
      debugPrint('[AutoDataService]   - $nombreConstats constats');
      debugPrint('[AutoDataService]   - Statistiques BI générées');
      
    } catch (e) {
      debugPrint('[AutoDataService] ❌ Erreur: $e');
      rethrow;
    }
  }

  /// 🏢 Créer les compagnies d'assurance
  Future<void> _createInsuranceCompanies() async {
    debugPrint('[AutoDataService] 🏢 Création des compagnies...');
    
    final companies = [
      {
        'id': 'STAR',
        'nom': 'STAR Assurances',
        'code': 'STAR',
        'couleur': '#FF5722',
        'logo': 'star_logo.png',
        'slogan': 'Votre étoile protectrice',
        'siege_social': 'Avenue Habib Bourguiba, Tunis',
        'telephone': '+216 71 123 456',
        'email': 'contact@star.tn',
        'site_web': 'www.star.tn',
        'capital': 50000000,
        'agrement': 'AGR-STAR-2020',
        'date_creation': DateTime(1995, 3, 15),
      },
      {
        'id': 'MAGHREBIA',
        'nom': 'Maghrebia Assurances',
        'code': 'MAG',
        'couleur': '#2196F3',
        'logo': 'maghrebia_logo.png',
        'slogan': 'L\'assurance de confiance',
        'siege_social': 'Avenue Mohamed V, Tunis',
        'telephone': '+216 71 789 012',
        'email': 'contact@maghrebia.tn',
        'site_web': 'www.maghrebia.tn',
        'capital': 45000000,
        'agrement': 'AGR-MAG-2018',
        'date_creation': DateTime(1992, 8, 20),
      },
      {
        'id': 'GAT',
        'nom': 'GAT Assurances',
        'code': 'GAT',
        'couleur': '#4CAF50',
        'logo': 'gat_logo.png',
        'slogan': 'Garantie et transparence',
        'siege_social': 'Rue Ibn Khaldoun, Tunis',
        'telephone': '+216 71 345 678',
        'email': 'contact@gat.tn',
        'site_web': 'www.gat.tn',
        'capital': 40000000,
        'agrement': 'AGR-GAT-2019',
        'date_creation': DateTime(1998, 12, 10),
      },
      {
        'id': 'LLOYD',
        'nom': 'Lloyd Tunisien',
        'code': 'LLOYD',
        'couleur': '#9C27B0',
        'logo': 'lloyd_logo.png',
        'slogan': 'Excellence et innovation',
        'siege_social': 'Les Berges du Lac, Tunis',
        'telephone': '+216 71 456 789',
        'email': 'contact@lloyd.tn',
        'site_web': 'www.lloyd.tn',
        'capital': 60000000,
        'agrement': 'AGR-LLOYD-2017',
        'date_creation': DateTime(1985, 6, 5),
      },
      {
        'id': 'ASTREE',
        'nom': 'Astrée Assurances',
        'code': 'AST',
        'couleur': '#FF9800',
        'logo': 'astree_logo.png',
        'slogan': 'Votre avenir assuré',
        'siege_social': 'Avenue de la Liberté, Tunis',
        'telephone': '+216 71 567 890',
        'email': 'contact@astree.tn',
        'site_web': 'www.astree.tn',
        'capital': 35000000,
        'agrement': 'AGR-AST-2021',
        'date_creation': DateTime(2001, 4, 18),
      },
      {
        'id': 'CTAMA',
        'nom': 'CTAMA',
        'code': 'CTAMA',
        'couleur': '#607D8B',
        'logo': 'ctama_logo.png',
        'slogan': 'Compagnie Tunisienne d\'Assurance',
        'siege_social': 'Avenue Bourguiba, Tunis',
        'telephone': '+216 71 678 901',
        'email': 'contact@ctama.tn',
        'site_web': 'www.ctama.tn',
        'capital': 42000000,
        'agrement': 'AGR-CTAMA-2016',
        'date_creation': DateTime(1990, 11, 25),
      },
      {
        'id': 'SALIM',
        'nom': 'Salim Assurances',
        'code': 'SALIM',
        'couleur': '#795548',
        'logo': 'salim_logo.png',
        'slogan': 'Sécurité et sérénité',
        'siege_social': 'Rue de Marseille, Tunis',
        'telephone': '+216 71 789 012',
        'email': 'contact@salim.tn',
        'site_web': 'www.salim.tn',
        'capital': 38000000,
        'agrement': 'AGR-SALIM-2020',
        'date_creation': DateTime(2005, 9, 12),
      },
      {
        'id': 'ZITOUNA',
        'nom': 'Zitouna Takaful',
        'code': 'ZIT',
        'couleur': '#009688',
        'logo': 'zitouna_logo.png',
        'slogan': 'Assurance islamique de confiance',
        'siege_social': 'Avenue Hedi Chaker, Tunis',
        'telephone': '+216 71 890 123',
        'email': 'contact@zitouna.tn',
        'site_web': 'www.zitouna.tn',
        'capital': 30000000,
        'agrement': 'AGR-ZIT-2022',
        'date_creation': DateTime(2010, 2, 28),
      },
    ];

    for (final company in companies) {
      // Générer les agences pour chaque compagnie
      final agences = await _generateAgencesForCompany(company['id'] as String);
      
      final companyData = {
        ...company,
        'agences': agences,
        'statistiques': _generateCompanyStats(),
        'produits': _generateInsuranceProducts(),
        'tarifs': _generateTarifs(),
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('assureurs_compagnies')
          .doc(company['id'] as String)
          .set(companyData);
    }
  }

  /// 🏪 Générer les agences pour une compagnie
  Future<List<Map<String, dynamic>>> _generateAgencesForCompany(String companyId) async {
    final gouvernorats = [
      'Tunis', 'Ariana', 'Ben Arous', 'Manouba', 'Nabeul', 'Zaghouan',
      'Bizerte', 'Béja', 'Jendouba', 'Kef', 'Siliana', 'Sousse',
      'Monastir', 'Mahdia', 'Sfax', 'Kairouan', 'Kasserine', 'Sidi Bouzid',
      'Gabès', 'Medenine', 'Tataouine', 'Gafsa', 'Tozeur', 'Kebili'
    ];

    final agences = <Map<String, dynamic>>[];
    final nombreAgences = _random.nextInt(8) + 5; // 5-12 agences par compagnie

    for (int i = 0; i < nombreAgences; i++) {
      final gouvernorat = gouvernorats[_random.nextInt(gouvernorats.length)];
      
      agences.add({
        'id': '${companyId}_${gouvernorat.toUpperCase()}_${(i + 1).toString().padLeft(3, '0')}',
        'nom': 'Agence $gouvernorat ${i + 1}',
        'adresse': '${_random.nextInt(200) + 1} ${_getRandomStreet()}, $gouvernorat',
        'gouvernorat': gouvernorat,
        'telephone': '+216 ${_random.nextInt(90) + 10} ${_random.nextInt(900) + 100} ${_random.nextInt(900) + 100}',
        'email': '${gouvernorat.toLowerCase()}@${companyId.toLowerCase()}.tn',
        'responsable': _generateRandomName(),
        'horaires': {
          'lundi_vendredi': '08:00 - 17:00',
          'samedi': '08:00 - 12:00',
          'dimanche': 'Fermé',
        },
        'services': _generateAgenceServices(),
        'coordonnees': {
          'latitude': _generateLatitude(),
          'longitude': _generateLongitude(),
        },
        'created_at': FieldValue.serverTimestamp(),
      });
    }

    return agences;
  }

  /// 👥 Générer les clients
  Future<List<String>> _generateClients(int nombre, bool showProgress) async {
    debugPrint('[AutoDataService] 👥 Génération de $nombre clients...');
    
    final clientsIds = <String>[];
    final batch = _firestore.batch();
    int batchCount = 0;
    
    for (int i = 0; i < nombre; i++) {
      final clientData = _generateClientData();
      final docRef = _firestore.collection('clients_assurance').doc();
      
      batch.set(docRef, clientData);
      clientsIds.add(docRef.id);
      batchCount++;
      
      if (batchCount >= 500 || i == nombre - 1) {
        await batch.commit();
        batchCount = 0;
        
        if (showProgress) {
          final progress = ((i + 1) / nombre * 100).round();
          debugPrint('[AutoDataService] 📊 Clients: $progress% (${i + 1}/$nombre)');
        }
      }
    }
    
    return clientsIds;
  }

  /// 🚗 Générer les véhicules assurés
  Future<List<String>> _generateInsuredVehicles(int nombre, List<String> clientsIds, bool showProgress) async {
    debugPrint('[AutoDataService] 🚗 Génération de $nombre véhicules assurés...');
    
    final vehiculesIds = <String>[];
    final batch = _firestore.batch();
    int batchCount = 0;
    
    for (int i = 0; i < nombre; i++) {
      final vehiculeData = _generateInsuredVehicleData(clientsIds);
      final docRef = _firestore.collection(Constants.collectionVehiculesAssures).doc();
      
      batch.set(docRef, vehiculeData);
      vehiculesIds.add(docRef.id);
      batchCount++;
      
      if (batchCount >= 500 || i == nombre - 1) {
        await batch.commit();
        batchCount = 0;
        
        if (showProgress) {
          final progress = ((i + 1) / nombre * 100).round();
          debugPrint('[AutoDataService] 📊 Véhicules: $progress% (${i + 1}/$nombre)');
        }
      }
    }
    
    return vehiculesIds;
  }

  /// 📋 Générer les constats
  Future<void> _generateAccidentReports(int nombre, List<String> vehiculesIds, List<String> clientsIds, bool showProgress) async {
    debugPrint('[AutoDataService] 📋 Génération de $nombre constats...');
    
    final batch = _firestore.batch();
    int batchCount = 0;
    
    for (int i = 0; i < nombre; i++) {
      final constatData = _generateAccidentReportData(vehiculesIds, clientsIds);
      final docRef = _firestore.collection(Constants.collectionConstats).doc();
      
      batch.set(docRef, constatData);
      batchCount++;
      
      if (batchCount >= 500 || i == nombre - 1) {
        await batch.commit();
        batchCount = 0;
        
        if (showProgress) {
          final progress = ((i + 1) / nombre * 100).round();
          debugPrint('[AutoDataService] 📊 Constats: $progress% (${i + 1}/$nombre)');
        }
      }
    }
  }

  /// 📊 Générer les statistiques d'assurance
  Future<void> _generateInsuranceStats() async {
    debugPrint('[AutoDataService] 📊 Génération des statistiques...');
    
    final stats = {
      'periode': '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}',
      'kpis_globaux': {
        'chiffre_affaires': _random.nextInt(50000000) + 20000000,
        'nombre_contrats_actifs': _random.nextInt(50000) + 20000,
        'nombre_sinistres': _random.nextInt(5000) + 1000,
        'ratio_sinistralite': (_random.nextDouble() * 30 + 40).toStringAsFixed(2),
        'satisfaction_client': (_random.nextDouble() * 2 + 3).toStringAsFixed(1),
        'delai_moyen_indemnisation': _random.nextInt(15) + 5,
      },
      'repartition_par_compagnie': _generateCompanyDistribution(),
      'evolution_mensuelle': _generateMonthlyEvolution(),
      'zones_risque': _generateRiskZones(),
      'predictions': _generatePredictions(),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection(Constants.collectionAnalytics)
        .doc('assurance_stats_${DateTime.now().year}_${DateTime.now().month}')
        .set(stats);
  }

  /// 👨‍💼 Créer les utilisateurs assureurs
  Future<void> _createInsuranceUsers() async {
    debugPrint('[AutoDataService] 👨‍💼 Création des utilisateurs assureurs...');
    
    final companies = ['STAR', 'MAGHREBIA', 'GAT', 'LLOYD', 'ASTREE', 'CTAMA', 'SALIM', 'ZITOUNA'];
    
    for (final company in companies) {
      // Créer 2-3 utilisateurs par compagnie
      final nombreUsers = _random.nextInt(2) + 2;
      
      for (int i = 0; i < nombreUsers; i++) {
        final userData = {
          'id': 'assureur_${company.toLowerCase()}_${i + 1}',
          'email': 'assureur${i + 1}@${company.toLowerCase()}.tn',
          'nom': _getRandomLastName(),
          'prenom': _getRandomFirstName(),
          'telephone': '+216 ${_random.nextInt(90) + 10} ${_random.nextInt(900) + 100} ${_random.nextInt(900) + 100}',
          'compagnie': company,
          'poste': _getRandomPosition(),
          'agence_id': '${company}_TUNIS_001',
          'permissions': _generateUserPermissions(),
          'statut': 'actif',
          'date_embauche': _generateRandomDate(2020, 2024),
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        };

        await _firestore
            .collection('users_assureurs')
            .doc(userData['id'] as String)
            .set(userData);
      }
    }
  }

  // ========== MÉTHODES HELPER ==========

  /// 🔐 S'assurer que l'utilisateur est authentifié
  Future<void> _ensureAuthenticated() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('[AutoDataService] 🔐 Authentification anonyme...');
      await FirebaseAuth.instance.signInAnonymously();
      debugPrint('[AutoDataService] ✅ Authentifié anonymement');
    } else {
      debugPrint('[AutoDataService] ✅ Utilisateur déjà authentifié: ${user.uid}');
    }
  }

  Map<String, dynamic> _generateCompanyStats() {
    return {
      'total_contrats': _random.nextInt(15000) + 5000,
      'contrats_actifs': _random.nextInt(12000) + 4000,
      'sinistres_annee': _random.nextInt(800) + 200,
      'chiffre_affaires': _random.nextInt(10000000) + 2000000,
      'ratio_sinistralite': (_random.nextDouble() * 20 + 30).toStringAsFixed(2),
    };
  }

  List<Map<String, dynamic>> _generateInsuranceProducts() {
    return [
      {'nom': 'Responsabilité Civile', 'prix_base': 180, 'description': 'Couverture minimale obligatoire'},
      {'nom': 'Tiers Complet', 'prix_base': 350, 'description': 'RC + Vol + Incendie + Bris de glace'},
      {'nom': 'Tous Risques', 'prix_base': 650, 'description': 'Couverture complète tous dommages'},
      {'nom': 'Conducteur', 'prix_base': 120, 'description': 'Protection du conducteur'},
    ];
  }

  Map<String, dynamic> _generateTarifs() {
    return {
      'jeune_conducteur': 1.5,
      'conducteur_experimente': 1.0,
      'senior': 1.2,
      'malus': 2.0,
      'bonus_max': 0.5,
      'franchise_mini': 100,
      'franchise_maxi': 500,
    };
  }

  List<String> _generateAgenceServices() {
    final services = [
      'Souscription contrats', 'Déclaration sinistres', 'Expertise véhicules',
      'Conseil personnalisé', 'Assistance 24h/24', 'Renouvellement automatique'
    ];
    return services.take(_random.nextInt(4) + 3).toList();
  }

  String _getRandomStreet() {
    final streets = [
      'Avenue Habib Bourguiba', 'Rue de la République', 'Avenue Mohamed V',
      'Rue Ibn Khaldoun', 'Avenue de la Liberté', 'Rue de Marseille',
      'Avenue Hedi Chaker', 'Rue du Lac', 'Avenue de Carthage'
    ];
    return streets[_random.nextInt(streets.length)];
  }

  String _generateRandomName() {
    final prenoms = ['Ahmed', 'Mohamed', 'Ali', 'Fatma', 'Aicha', 'Salma', 'Karim', 'Nour'];
    final noms = ['Ben Ahmed', 'Trabelsi', 'Khelifi', 'Mansouri', 'Gharbi', 'Sassi'];
    return '${prenoms[_random.nextInt(prenoms.length)]} ${noms[_random.nextInt(noms.length)]}';
  }

  String _getRandomFirstName() {
    final prenoms = ['Ahmed', 'Mohamed', 'Ali', 'Karim', 'Sami', 'Fatma', 'Aicha', 'Salma', 'Nour', 'Ines'];
    return prenoms[_random.nextInt(prenoms.length)];
  }

  String _getRandomLastName() {
    final noms = ['Ben Ahmed', 'Trabelsi', 'Khelifi', 'Mansouri', 'Gharbi', 'Sassi', 'Mejri', 'Dridi'];
    return noms[_random.nextInt(noms.length)];
  }

  String _getRandomPosition() {
    final postes = ['Gestionnaire Sinistres', 'Conseiller Commercial', 'Expert Auto', 'Responsable Agence'];
    return postes[_random.nextInt(postes.length)];
  }

  List<String> _generateUserPermissions() {
    final permissions = ['consulter_contrats', 'gerer_sinistres', 'valider_expertises', 'generer_rapports'];
    return permissions.take(_random.nextInt(3) + 2).toList();
  }

  double _generateLatitude() => 33.0 + _random.nextDouble() * 4.0; // Tunisie: 33-37°N
  double _generateLongitude() => 8.0 + _random.nextDouble() * 3.0; // Tunisie: 8-11°E

  DateTime _generateRandomDate(int startYear, int endYear) {
    final start = DateTime(startYear);
    final end = DateTime(endYear);
    final diff = end.difference(start).inDays;
    return start.add(Duration(days: _random.nextInt(diff)));
  }

  Map<String, dynamic> _generateClientData() {
    // Implémentation des données client
    return {
      'nom': _getRandomLastName(),
      'prenom': _getRandomFirstName(),
      'cin': '${_random.nextInt(90000000) + 10000000}',
      'telephone': '+216 ${_random.nextInt(90) + 10} ${_random.nextInt(900) + 100} ${_random.nextInt(900) + 100}',
      'email': '${_getRandomFirstName().toLowerCase()}@email.com',
      'adresse': '${_random.nextInt(200) + 1} ${_getRandomStreet()}',
      'date_naissance': _generateRandomDate(1960, 2000),
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _generateInsuredVehicleData(List<String> clientsIds) {
    // Implémentation des données véhicule assuré
    final companies = ['STAR', 'MAGHREBIA', 'GAT', 'LLOYD', 'ASTREE', 'CTAMA', 'SALIM', 'ZITOUNA'];
    final marques = ['Peugeot', 'Renault', 'Volkswagen', 'Citroën', 'Fiat', 'Hyundai'];
    
    return {
      'client_id': clientsIds[_random.nextInt(clientsIds.length)],
      'assureur_id': companies[_random.nextInt(companies.length)],
      'numero_contrat': 'CTR-${DateTime.now().year}-${_random.nextInt(999999).toString().padLeft(6, '0')}',
      'marque': marques[_random.nextInt(marques.length)],
      'modele': 'Modèle ${_random.nextInt(10) + 1}',
      'immatriculation': '${_random.nextInt(900) + 100} TUN ${_random.nextInt(900) + 100}',
      'annee': _random.nextInt(15) + 2010,
      'valeur_vehicule': _random.nextInt(50000) + 10000,
      'type_couverture': ['RC', 'Tiers Complet', 'Tous Risques'][_random.nextInt(3)],
      'prime_annuelle': _random.nextInt(1000) + 300,
      'franchise': _random.nextInt(400) + 100,
      'date_debut': _generateRandomDate(2023, 2024),
      'date_fin': _generateRandomDate(2024, 2025),
      'statut': 'actif',
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _generateAccidentReportData(List<String> vehiculesIds, List<String> clientsIds) {
    return {
      'vehicule_id': vehiculesIds[_random.nextInt(vehiculesIds.length)],
      'client_id': clientsIds[_random.nextInt(clientsIds.length)],
      'date_accident': _generateRandomDate(2024, 2024),
      'lieu_accident': '${_getRandomStreet()}, Tunis',
      'description': 'Accident de circulation',
      'montant_estime': _random.nextInt(8000) + 500,
      'statut': ['en_attente', 'en_cours', 'clos'][_random.nextInt(3)],
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _generateCompanyDistribution() {
    return {
      'STAR': _random.nextInt(20) + 15,
      'MAGHREBIA': _random.nextInt(20) + 12,
      'GAT': _random.nextInt(15) + 10,
      'LLOYD': _random.nextInt(15) + 8,
    };
  }

  List<Map<String, dynamic>> _generateMonthlyEvolution() {
    final evolution = <Map<String, dynamic>>[];
    for (int i = 11; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i * 30));
      evolution.add({
        'mois': '${date.year}-${date.month.toString().padLeft(2, '0')}',
        'contrats': _random.nextInt(500) + 200,
        'sinistres': _random.nextInt(100) + 20,
        'chiffre_affaires': _random.nextInt(2000000) + 500000,
      });
    }
    return evolution;
  }

  List<Map<String, dynamic>> _generateRiskZones() {
    final zones = ['Tunis Centre', 'Sfax', 'Sousse', 'Nabeul', 'Bizerte'];
    return zones.map((zone) => {
      'zone': zone,
      'niveau_risque': _random.nextInt(5) + 1,
      'nombre_sinistres': _random.nextInt(100) + 10,
    }).toList();
  }

  Map<String, dynamic> _generatePredictions() {
    return {
      'sinistres_prevus_trimestre': _random.nextInt(500) + 200,
      'croissance_contrats': (_random.nextDouble() * 10 + 5).toStringAsFixed(1),
      'zones_attention': ['Tunis Centre', 'Autoroute A1'],
    };
  }
}
