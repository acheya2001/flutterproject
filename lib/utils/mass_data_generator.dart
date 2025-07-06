import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../features/vehicules/models/vehicule_assure_model.dart';
import '../core/utils/constants.dart';
import 'dart:math';

/// 🏭 Générateur de données massives pour Firebase
class MassDataGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  // 🏢 Compagnies d'assurance tunisiennes
  final List<Map<String, dynamic>> _assureurs = [
    {'id': 'STAR', 'nom': 'STAR Assurances', 'code': 'STAR'},
    {'id': 'MAGHREBIA', 'nom': 'Maghrebia Assurances', 'code': 'MAG'},
    {'id': 'GAT', 'nom': 'GAT Assurances', 'code': 'GAT'},
    {'id': 'LLOYD', 'nom': 'Lloyd Tunisien', 'code': 'LLOYD'},
    {'id': 'ASTREE', 'nom': 'Astrée Assurances', 'code': 'AST'},
    {'id': 'CTAMA', 'nom': 'CTAMA', 'code': 'CTAMA'},
    {'id': 'SALIM', 'nom': 'Salim Assurances', 'code': 'SALIM'},
    {'id': 'ZITOUNA', 'nom': 'Zitouna Takaful', 'code': 'ZIT'},
  ];

  // 🚗 Marques et modèles de voitures populaires en Tunisie
  final Map<String, List<String>> _vehicules = {
    'Peugeot': ['208', '308', '2008', '3008', '5008', '207', '307', '407'],
    'Renault': ['Clio', 'Megane', 'Captur', 'Duster', 'Logan', 'Symbol', 'Fluence'],
    'Volkswagen': ['Golf', 'Polo', 'Passat', 'Tiguan', 'Jetta', 'Touareg'],
    'Citroën': ['C3', 'C4', 'C5', 'Berlingo', 'Picasso', 'DS3', 'DS4'],
    'Fiat': ['Punto', 'Panda', '500', 'Tipo', 'Doblo', 'Bravo'],
    'Hyundai': ['i10', 'i20', 'i30', 'Tucson', 'Santa Fe', 'Accent'],
    'Kia': ['Picanto', 'Rio', 'Cerato', 'Sportage', 'Sorento'],
    'Toyota': ['Yaris', 'Corolla', 'Camry', 'RAV4', 'Land Cruiser'],
    'Nissan': ['Micra', 'Sunny', 'Qashqai', 'X-Trail', 'Patrol'],
    'Ford': ['Fiesta', 'Focus', 'Mondeo', 'Kuga', 'Explorer'],
    'Opel': ['Corsa', 'Astra', 'Insignia', 'Mokka', 'Zafira'],
    'Seat': ['Ibiza', 'Leon', 'Toledo', 'Ateca', 'Alhambra'],
  };

  // 🎨 Couleurs de voitures
  final List<String> _couleurs = [
    'Blanc', 'Noir', 'Gris', 'Rouge', 'Bleu', 'Vert', 'Jaune', 'Orange', 
    'Violet', 'Marron', 'Beige', 'Argent', 'Bronze'
  ];

  // 📍 Gouvernorats tunisiens
  final List<String> _gouvernorats = [
    'Tunis', 'Ariana', 'Ben Arous', 'Manouba', 'Nabeul', 'Zaghouan',
    'Bizerte', 'Béja', 'Jendouba', 'Kef', 'Siliana', 'Sousse',
    'Monastir', 'Mahdia', 'Sfax', 'Kairouan', 'Kasserine', 'Sidi Bouzid',
    'Gabès', 'Medenine', 'Tataouine', 'Gafsa', 'Tozeur', 'Kebili'
  ];

  // 👥 Prénoms tunisiens
  final List<String> _prenomsHommes = [
    'Mohamed', 'Ahmed', 'Ali', 'Mahmoud', 'Omar', 'Youssef', 'Karim', 'Sami',
    'Nabil', 'Tarek', 'Hichem', 'Fares', 'Amine', 'Walid', 'Rami', 'Zied'
  ];

  final List<String> _prenomsFemmes = [
    'Fatma', 'Aicha', 'Salma', 'Nour', 'Ines', 'Mariem', 'Sarra', 'Rim',
    'Nesrine', 'Wafa', 'Samia', 'Leila', 'Amina', 'Dorra', 'Emna', 'Olfa'
  ];

  final List<String> _noms = [
    'Ben Ahmed', 'Ben Ali', 'Ben Salem', 'Trabelsi', 'Bouazizi', 'Khelifi',
    'Mansouri', 'Gharbi', 'Jemli', 'Sassi', 'Mejri', 'Bouzid', 'Hamdi',
    'Kacem', 'Dridi', 'Cherni', 'Abidi', 'Rekik', 'Tlili', 'Ouali'
  ];

  // 🏠 Types de couverture
  final List<String> _typesCouverture = [
    'Responsabilité Civile', 'Tiers Complet', 'Tous Risques', 'Vol et Incendie'
  ];

  /// 🚀 Générer une base de données massive
  Future<void> generateMassiveDatabase({
    int nombreVehicules = 1000,
    int nombreConstats = 200,
    bool showProgress = true,
  }) async {
    try {
      debugPrint('[MassDataGenerator] 🚀 Génération de $nombreVehicules véhicules et $nombreConstats constats...');
      
      if (showProgress) {
        debugPrint('[MassDataGenerator] 📊 Progression: 0%');
      }

      // 1. Créer les compagnies d'assurance
      await _createAssuranceCompanies();
      
      // 2. Générer les véhicules assurés
      final vehiculesIds = await _generateVehicules(nombreVehicules, showProgress);
      
      // 3. Générer les constats
      await _generateConstats(nombreConstats, vehiculesIds, showProgress);
      
      // 4. Générer les analytics
      await _generateAnalytics();

      debugPrint('[MassDataGenerator] ✅ Base de données massive créée avec succès !');
      debugPrint('[MassDataGenerator] 📊 Résumé:');
      debugPrint('[MassDataGenerator]   - ${_assureurs.length} compagnies d\'assurance');
      debugPrint('[MassDataGenerator]   - $nombreVehicules véhicules assurés');
      debugPrint('[MassDataGenerator]   - $nombreConstats constats d\'accident');
      debugPrint('[MassDataGenerator]   - Analytics générées');
      
    } catch (e) {
      debugPrint('[MassDataGenerator] ❌ Erreur lors de la génération: $e');
      rethrow;
    }
  }

  /// 🏢 Créer les compagnies d'assurance
  Future<void> _createAssuranceCompanies() async {
    debugPrint('[MassDataGenerator] 🏢 Création des compagnies d\'assurance...');
    
    for (final assureur in _assureurs) {
      final data = {
        'id': assureur['id'],
        'nom': assureur['nom'],
        'code': assureur['code'],
        'logo_url': 'https://example.com/${assureur['id'].toLowerCase()}_logo.png',
        'contact': {
          'telephone': '+216 71 ${_random.nextInt(900) + 100} ${_random.nextInt(900) + 100}',
          'email': 'contact@${assureur['id'].toLowerCase()}.tn',
          'adresse': '${_random.nextInt(100) + 1} Avenue ${_getRandomElement(_gouvernorats)}, Tunis',
        },
        'agences': _generateAgences(assureur['id'] as String),
        'statistiques': {
          'total_contrats': _random.nextInt(20000) + 5000,
          'constats_traites': _random.nextInt(2000) + 500,
          'montant_total_sinistres': _random.nextInt(5000000) + 1000000,
        },
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('assureurs_compagnies')
          .doc(assureur['id'] as String)
          .set(data);
    }
  }

  /// 🏪 Générer les agences
  List<Map<String, dynamic>> _generateAgences(String assureurId) {
    final nombreAgences = _random.nextInt(5) + 2; // 2-6 agences
    final agences = <Map<String, dynamic>>[];
    
    for (int i = 0; i < nombreAgences; i++) {
      final gouvernorat = _getRandomElement(_gouvernorats);
      agences.add({
        'agence_id': '${assureurId}_${gouvernorat.toUpperCase()}_${i.toString().padLeft(3, '0')}',
        'nom': 'Agence $gouvernorat ${i + 1}',
        'adresse': '${_random.nextInt(200) + 1} Rue ${_getRandomElement(_noms)}, $gouvernorat',
        'responsable': '${_getRandomElement(_prenomsHommes)} ${_getRandomElement(_noms)}',
        'telephone': '+216 ${_random.nextInt(90) + 10} ${_random.nextInt(900) + 100} ${_random.nextInt(900) + 100}',
      });
    }
    
    return agences;
  }

  /// 🚗 Générer les véhicules
  Future<List<String>> _generateVehicules(int nombre, bool showProgress) async {
    debugPrint('[MassDataGenerator] 🚗 Génération de $nombre véhicules...');
    
    final vehiculesIds = <String>[];
    final batch = _firestore.batch();
    int batchCount = 0;
    
    for (int i = 0; i < nombre; i++) {
      final vehiculeData = _generateVehiculeData();
      final docRef = _firestore.collection(Constants.collectionVehiculesAssures).doc();
      
      batch.set(docRef, vehiculeData);
      vehiculesIds.add(docRef.id);
      batchCount++;
      
      // Commit par batch de 500 pour éviter les limites Firestore
      if (batchCount >= 500 || i == nombre - 1) {
        await batch.commit();
        batchCount = 0;
        
        if (showProgress) {
          final progress = ((i + 1) / nombre * 100).round();
          debugPrint('[MassDataGenerator] 📊 Véhicules: $progress% (${i + 1}/$nombre)');
        }
      }
    }
    
    return vehiculesIds;
  }

  /// 🚗 Générer les données d'un véhicule
  Map<String, dynamic> _generateVehiculeData() {
    final assureur = _getRandomElement(_assureurs);
    final marque = _vehicules.keys.elementAt(_random.nextInt(_vehicules.length));
    final modele = _getRandomElement(_vehicules[marque]!);
    final annee = _random.nextInt(15) + 2010; // 2010-2024
    final isHomme = _random.nextBool();
    
    final now = DateTime.now();
    final dateDebut = DateTime(
      now.year - _random.nextInt(3),
      _random.nextInt(12) + 1,
      _random.nextInt(28) + 1,
    );
    final dateFin = DateTime(
      dateDebut.year + 1,
      dateDebut.month,
      dateDebut.day,
    );
    
    final vehicule = VehiculeAssureModel(
      id: '', // Sera généré par Firestore
      assureurId: assureur['id'] as String,
      numeroContrat: '${assureur['code']}-${now.year}-${_random.nextInt(999999).toString().padLeft(6, '0')}',
      proprietaire: ProprietaireInfo(
        userId: 'user_${_random.nextInt(10000).toString().padLeft(4, '0')}',
        nom: _getRandomElement(_noms),
        prenom: isHomme ? _getRandomElement(_prenomsHommes) : _getRandomElement(_prenomsFemmes),
        cin: '${_random.nextInt(90000000) + 10000000}',
        telephone: '+216 ${_random.nextInt(90) + 10} ${_random.nextInt(900) + 100} ${_random.nextInt(900) + 100}',
      ),
      vehicule: VehiculeInfo(
        marque: marque,
        modele: modele,
        annee: annee,
        couleur: _getRandomElement(_couleurs),
        immatriculation: _generateImmatriculation(),
        numeroChassis: _generateNumeroChassis(marque),
        puissanceFiscale: _random.nextInt(15) + 4, // 4-18 CV
      ),
      contrat: ContratInfo(
        dateDebut: dateDebut,
        dateFin: dateFin,
        typeCouverture: _getRandomElement(_typesCouverture),
        franchise: (_random.nextInt(8) + 1) * 50.0, // 50-400 TND
        primeAnnuelle: (_random.nextInt(1000) + 300).toDouble(), // 300-1300 TND
      ),
      statut: dateFin.isAfter(now) ? 'actif' : 'expire',
      historiqueSinistres: _generateHistoriqueSinistres(),
      createdAt: dateDebut,
      updatedAt: now,
    );
    
    return vehicule.toMap();
  }

  /// 🔢 Générer une immatriculation tunisienne
  String _generateImmatriculation() {
    final numero = _random.nextInt(900) + 100; // 100-999
    final lettres = ['TUN', 'TN', 'RS']; // Codes régionaux
    final code = _getRandomElement(lettres);
    final suite = _random.nextInt(900) + 100; // 100-999
    
    return '$numero $code $suite';
  }

  /// 🔧 Générer un numéro de châssis
  String _generateNumeroChassis(String marque) {
    final prefixes = {
      'Peugeot': 'VF3',
      'Renault': 'VF1',
      'Volkswagen': 'WVW',
      'Citroën': 'VF7',
      'Fiat': 'ZFA',
      'Hyundai': 'KMH',
      'Kia': 'KNA',
      'Toyota': 'JTD',
      'Nissan': 'JN1',
      'Ford': 'WF0',
      'Opel': 'W0L',
      'Seat': 'VSS',
    };
    
    final prefix = prefixes[marque] ?? 'XXX';
    final suffix = List.generate(14, (index) => 
        _random.nextBool() ? 
        String.fromCharCode(_random.nextInt(26) + 65) : // A-Z
        _random.nextInt(10).toString() // 0-9
    ).join();
    
    return '$prefix$suffix';
  }

  /// 📋 Générer l'historique des sinistres
  List<SinistreInfo> _generateHistoriqueSinistres() {
    final nombreSinistres = _random.nextInt(4); // 0-3 sinistres
    final sinistres = <SinistreInfo>[];
    
    for (int i = 0; i < nombreSinistres; i++) {
      final date = DateTime.now().subtract(Duration(days: _random.nextInt(1095))); // 3 ans max
      sinistres.add(SinistreInfo(
        date: date,
        numeroSinistre: 'SIN-${date.year}-${_random.nextInt(999999).toString().padLeft(6, '0')}',
        montant: (_random.nextInt(5000) + 200).toDouble(),
        statut: _getRandomElement(['clos', 'en_cours', 'expertise']),
      ));
    }
    
    return sinistres;
  }

  /// 📊 Générer les constats
  Future<void> _generateConstats(int nombre, List<String> vehiculesIds, bool showProgress) async {
    debugPrint('[MassDataGenerator] 📋 Génération de $nombre constats...');
    
    final batch = _firestore.batch();
    int batchCount = 0;
    
    for (int i = 0; i < nombre; i++) {
      final constatData = _generateConstatData(vehiculesIds);
      final docRef = _firestore.collection(Constants.collectionConstats).doc();
      
      batch.set(docRef, constatData);
      batchCount++;
      
      if (batchCount >= 500 || i == nombre - 1) {
        await batch.commit();
        batchCount = 0;
        
        if (showProgress) {
          final progress = ((i + 1) / nombre * 100).round();
          debugPrint('[MassDataGenerator] 📊 Constats: $progress% (${i + 1}/$nombre)');
        }
      }
    }
  }

  /// 📋 Générer les données d'un constat
  Map<String, dynamic> _generateConstatData(List<String> vehiculesIds) {
    final dateAccident = DateTime.now().subtract(Duration(days: _random.nextInt(365)));
    final vehiculeA = _getRandomElement(vehiculesIds);
    final vehiculeB = _getRandomElement(vehiculesIds);
    
    return {
      'id': '', // Sera généré par Firestore
      'date_accident': Timestamp.fromDate(dateAccident),
      'lieu': '${_getRandomElement(_gouvernorats)}, ${_random.nextInt(100) + 1} Rue ${_getRandomElement(_noms)}',
      'vehicules': [vehiculeA, vehiculeB],
      'participants': ['user_${_random.nextInt(10000)}', 'user_${_random.nextInt(10000)}'],
      'statut': _getRandomElement(['brouillon', 'soumis', 'valide', 'traite']),
      'gravite': _getRandomElement(['leger', 'modere', 'grave']),
      'montant_estime': _random.nextInt(8000) + 500,
      'assureur_responsable': _getRandomElement(_assureurs)['id'],
      'expert_assigne': _random.nextBool() ? 'expert_${_random.nextInt(100)}' : null,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  /// 📊 Générer les analytics
  Future<void> _generateAnalytics() async {
    debugPrint('[MassDataGenerator] 📊 Génération des analytics...');
    
    final analytics = {
      'periode': '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}',
      'type': 'global',
      'kpis': {
        'nombre_constats': _random.nextInt(500) + 100,
        'montant_sinistres': _random.nextInt(2000000) + 500000,
        'delai_moyen_traitement': (_random.nextDouble() * 10 + 2).toStringAsFixed(1),
        'taux_satisfaction': (_random.nextDouble() * 2 + 3).toStringAsFixed(1),
        'fraudes_detectees': _random.nextInt(20),
      },
      'tendances': _generateTendances(),
      'zones_accidentogenes': _generateZonesAccidentogenes(),
      'predictions': _generatePredictions(),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection(Constants.collectionAnalytics)
        .doc('global_${DateTime.now().year}_${DateTime.now().month.toString().padLeft(2, '0')}')
        .set(analytics);
  }

  /// 📈 Générer les tendances
  List<Map<String, dynamic>> _generateTendances() {
    final tendances = <Map<String, dynamic>>[];
    final now = DateTime.now();
    
    for (int i = 5; i >= 0; i--) {
      final mois = DateTime(now.year, now.month - i, 1);
      tendances.add({
        'mois': '${mois.year}-${mois.month.toString().padLeft(2, '0')}',
        'nombre': _random.nextInt(200) + 50,
        'montant': _random.nextInt(500000) + 100000,
      });
    }
    
    return tendances;
  }

  /// 🗺️ Générer les zones accidentogènes
  List<Map<String, dynamic>> _generateZonesAccidentogenes() {
    return _gouvernorats.take(8).map((zone) => {
      'zone': zone,
      'accidents': _random.nextInt(50) + 5,
    }).toList();
  }

  /// 🔮 Générer les prédictions
  Map<String, dynamic> _generatePredictions() {
    return {
      'sinistres_prevus_mois_prochain': _random.nextInt(200) + 80,
      'budget_previsionnel': _random.nextInt(600000) + 200000,
      'zones_risque_eleve': _gouvernorats.take(3).toList(),
    };
  }

  /// 🎲 Obtenir un élément aléatoire d'une liste
  T _getRandomElement<T>(List<T> list) {
    return list[_random.nextInt(list.length)];
  }

  /// 🧹 Nettoyer toute la base de données
  Future<void> cleanAllData() async {
    debugPrint('[MassDataGenerator] 🧹 Nettoyage de toute la base de données...');
    
    final collections = [
      Constants.collectionVehiculesAssures,
      Constants.collectionConstats,
      Constants.collectionAnalytics,
      'assureurs_compagnies',
    ];
    
    for (final collection in collections) {
      final snapshot = await _firestore.collection(collection).get();
      final batch = _firestore.batch();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      debugPrint('[MassDataGenerator] ✅ Collection $collection nettoyée');
    }
    
    debugPrint('[MassDataGenerator] 🎉 Base de données complètement nettoyée !');
  }
}
