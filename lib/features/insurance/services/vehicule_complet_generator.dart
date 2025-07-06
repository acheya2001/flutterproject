import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/vehicule_complet_model.dart';

/// 🏗️ Générateur de données complètes pour véhicules avec structure d'assurance
class VehiculeCompletGenerator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();

  /// 🚀 Générer toute la structure d'assurance tunisienne
  static Future<void> generateCompleteInsuranceStructure() async {
    debugPrint('🚀 Génération structure d\'assurance complète...');
    
    try {
      // 1. Générer les compagnies d'assurance
      await _generateCompagniesAssurance();
      
      // 2. Générer les agences
      await _generateAgences();
      
      // 3. Générer les agents
      await _generateAgents();
      
      // 4. Générer les véhicules complets
      await _generateVehiculesComplets();
      
      debugPrint('✅ Structure d\'assurance générée avec succès !');
      
    } catch (e) {
      debugPrint('❌ Erreur génération structure: $e');
      rethrow;
    }
  }

  /// 🏢 Générer les compagnies d'assurance tunisiennes
  static Future<void> _generateCompagniesAssurance() async {
    debugPrint('🏢 Génération compagnies d\'assurance...');
    
    final compagnies = [
      {
        'id': 'STAR',
        'nom': 'STAR Assurances',
        'code': 'STAR',
        'siret': '12345678901234',
        'adresse_siege': 'Avenue Habib Bourguiba, Tunis',
        'telephone': '+216 71 123 456',
        'email': 'contact@star.tn',
        'logo_url': 'https://example.com/star-logo.png',
        'date_creation': DateTime(1960, 1, 1),
        'capital_social': 50000000.0,
        'total_vehicules': 125000,
        'total_contrats': 98000,
        'chiffre_affaires_annuel': 180000000.0,
      },
      {
        'id': 'MAGHREBIA',
        'nom': 'Maghrebia Assurances',
        'code': 'MAGHREBIA',
        'siret': '23456789012345',
        'adresse_siege': 'Avenue de la Liberté, Tunis',
        'telephone': '+216 71 234 567',
        'email': 'contact@maghrebia.tn',
        'logo_url': 'https://example.com/maghrebia-logo.png',
        'date_creation': DateTime(1962, 3, 15),
        'capital_social': 45000000.0,
        'total_vehicules': 110000,
        'total_contrats': 85000,
        'chiffre_affaires_annuel': 165000000.0,
      },
      {
        'id': 'LLOYD',
        'nom': 'Lloyd Tunisien',
        'code': 'LLOYD',
        'siret': '34567890123456',
        'adresse_siege': 'Rue de Marseille, Tunis',
        'telephone': '+216 71 345 678',
        'email': 'contact@lloyd.tn',
        'logo_url': 'https://example.com/lloyd-logo.png',
        'date_creation': DateTime(1958, 6, 20),
        'capital_social': 40000000.0,
        'total_vehicules': 95000,
        'total_contrats': 72000,
        'chiffre_affaires_annuel': 145000000.0,
      },
      {
        'id': 'GAT',
        'nom': 'GAT Assurances',
        'code': 'GAT',
        'siret': '45678901234567',
        'adresse_siege': 'Avenue Mohamed V, Tunis',
        'telephone': '+216 71 456 789',
        'email': 'contact@gat.tn',
        'logo_url': 'https://example.com/gat-logo.png',
        'date_creation': DateTime(1965, 9, 10),
        'capital_social': 35000000.0,
        'total_vehicules': 80000,
        'total_contrats': 65000,
        'chiffre_affaires_annuel': 125000000.0,
      },
      {
        'id': 'AST',
        'nom': 'Assurances Salim',
        'code': 'AST',
        'siret': '56789012345678',
        'adresse_siege': 'Rue Ibn Khaldoun, Tunis',
        'telephone': '+216 71 567 890',
        'email': 'contact@ast.tn',
        'logo_url': 'https://example.com/ast-logo.png',
        'date_creation': DateTime(1970, 12, 5),
        'capital_social': 30000000.0,
        'total_vehicules': 70000,
        'total_contrats': 55000,
        'chiffre_affaires_annuel': 110000000.0,
      },
    ];

    final batch = _firestore.batch();
    final now = DateTime.now();

    for (final compagnieData in compagnies) {
      final compagnieDoc = {
        'nom': compagnieData['nom'],
        'siret': compagnieData['siret'],
        'adresse_siege': compagnieData['adresse_siege'],
        'telephone': compagnieData['telephone'],
        'email': compagnieData['email'],
        'logo_url': compagnieData['logo_url'],
        'date_creation': Timestamp.fromDate(compagnieData['date_creation'] as DateTime),
        'capital_social': compagnieData['capital_social'],
        'agences': [], // Sera rempli après génération des agences
        'total_vehicules': compagnieData['total_vehicules'],
        'total_contrats': compagnieData['total_contrats'],
        'chiffre_affaires_annuel': compagnieData['chiffre_affaires_annuel'],
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      batch.set(
        _firestore.collection('compagnies_assurance').doc(compagnieData['id'] as String),
        compagnieDoc,
      );
    }

    await batch.commit();
    debugPrint('✅ 5 compagnies d\'assurance créées');
  }

  /// 🏪 Générer les agences d'assurance
  static Future<void> _generateAgences() async {
    debugPrint('🏪 Génération agences d\'assurance...');
    
    final agencesData = [
      // STAR
      {'compagnie': 'STAR', 'gouvernorat': 'Tunis', 'delegation': 'Centre Ville', 'code': 'TUN001'},
      {'compagnie': 'STAR', 'gouvernorat': 'Sfax', 'delegation': 'Sfax Nord', 'code': 'SFX001'},
      {'compagnie': 'STAR', 'gouvernorat': 'Sousse', 'delegation': 'Sousse Centre', 'code': 'SOU001'},
      
      // MAGHREBIA
      {'compagnie': 'MAGHREBIA', 'gouvernorat': 'Tunis', 'delegation': 'Lac 2', 'code': 'TUN002'},
      {'compagnie': 'MAGHREBIA', 'gouvernorat': 'Sfax', 'delegation': 'Sfax Sud', 'code': 'SFX002'},
      {'compagnie': 'MAGHREBIA', 'gouvernorat': 'Monastir', 'delegation': 'Monastir Centre', 'code': 'MON001'},
      
      // LLOYD
      {'compagnie': 'LLOYD', 'gouvernorat': 'Tunis', 'delegation': 'Manouba', 'code': 'TUN003'},
      {'compagnie': 'LLOYD', 'gouvernorat': 'Nabeul', 'delegation': 'Nabeul Centre', 'code': 'NAB001'},
      {'compagnie': 'LLOYD', 'gouvernorat': 'Bizerte', 'delegation': 'Bizerte Nord', 'code': 'BIZ001'},
      
      // GAT
      {'compagnie': 'GAT', 'gouvernorat': 'Tunis', 'delegation': 'Ariana', 'code': 'TUN004'},
      {'compagnie': 'GAT', 'gouvernorat': 'Gabès', 'delegation': 'Gabès Centre', 'code': 'GAB001'},
      {'compagnie': 'GAT', 'gouvernorat': 'Kairouan', 'delegation': 'Kairouan Centre', 'code': 'KAI001'},
      
      // AST
      {'compagnie': 'AST', 'gouvernorat': 'Tunis', 'delegation': 'Ben Arous', 'code': 'TUN005'},
      {'compagnie': 'AST', 'gouvernorat': 'Médenine', 'delegation': 'Médenine Centre', 'code': 'MED001'},
      {'compagnie': 'AST', 'gouvernorat': 'Gafsa', 'delegation': 'Gafsa Centre', 'code': 'GAF001'},
    ];

    final batch = _firestore.batch();
    final now = DateTime.now();

    for (int i = 0; i < agencesData.length; i++) {
      final agenceData = agencesData[i];
      final agenceId = 'agence_${agenceData['code']?.toLowerCase()}';
      
      final agenceDoc = {
        'compagnie_id': agenceData['compagnie'],
        'nom': '${agenceData['compagnie']} ${agenceData['gouvernorat']} ${agenceData['delegation']}',
        'code_agence': agenceData['code'],
        'gouvernorat': agenceData['gouvernorat'],
        'delegation': agenceData['delegation'],
        'adresse': '${_random.nextInt(200) + 1} Avenue ${_generateStreetName()}, ${agenceData['gouvernorat']}',
        'telephone': '+216 ${70 + _random.nextInt(9)} ${_random.nextInt(900) + 100} ${_random.nextInt(900) + 100}',
        'directeur': {
          'nom': _generateNom(),
          'prenom': _generatePrenom(),
          'telephone': '+216 ${20 + _random.nextInt(9)} ${_random.nextInt(900) + 100} ${_random.nextInt(900) + 100}',
          'email': 'directeur.${agenceData['code']?.toLowerCase()}@${agenceData['compagnie']?.toLowerCase()}.tn',
        },
        'agents_ids': [], // Sera rempli après génération des agents
        'zone_couverture': [agenceData['gouvernorat'], agenceData['delegation']],
        'vehicules_geres': 3000 + _random.nextInt(5000),
        'contrats_actifs': 2500 + _random.nextInt(4000),
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      batch.set(
        _firestore.collection('agences').doc(agenceId),
        agenceDoc,
      );
    }

    await batch.commit();
    debugPrint('✅ 15 agences créées');
  }

  /// 👨‍💼 Générer les agents d'assurance
  static Future<void> _generateAgents() async {
    debugPrint('👨‍💼 Génération agents d\'assurance...');
    
    // Récupérer les agences créées
    final agencesSnapshot = await _firestore.collection('agences').get();
    
    final batch = _firestore.batch();
    final now = DateTime.now();
    int agentCounter = 1;

    for (final agenceDoc in agencesSnapshot.docs) {
      final agenceData = agenceDoc.data();
      final nombreAgents = 2 + _random.nextInt(4); // 2-5 agents par agence

      for (int i = 0; i < nombreAgents; i++) {
        final agentId = 'agent_${agentCounter.toString().padLeft(3, '0')}';
        
        final agentDoc = {
          'user_id': 'user_$agentId', // Sera lié lors de l'inscription
          'compagnie_id': agenceData['compagnie_id'],
          'agence_id': agenceDoc.id,
          'matricule_agent': 'AG${agentCounter.toString().padLeft(4, '0')}',
          'nom': _generateNom(),
          'prenom': _generatePrenom(),
          'cin': _generateCin(),
          'telephone': '+216 ${20 + _random.nextInt(9)} ${_random.nextInt(900) + 100} ${_random.nextInt(900) + 100}',
          'email': 'agent$agentCounter@${agenceData['compagnie_id'].toString().toLowerCase()}.tn',
          'date_embauche': Timestamp.fromDate(DateTime.now().subtract(Duration(days: _random.nextInt(1825)))), // 0-5 ans
          'statut': 'actif',
          'portefeuille': {
            'vehicules_geres': 150 + _random.nextInt(300),
            'contrats_actifs': 120 + _random.nextInt(250),
            'chiffre_affaires': 800000 + _random.nextInt(1200000).toDouble(),
          },
          'zone_responsabilite': [agenceData['delegation']],
          'permissions': ['creer_contrat', 'modifier_contrat', 'valider_sinistre'],
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        };

        batch.set(
          _firestore.collection('agents_assurance').doc(agentId),
          agentDoc,
        );

        agentCounter++;
      }
    }

    await batch.commit();
    debugPrint('✅ ${agentCounter - 1} agents créés');
  }

  /// 🚗 Générer les véhicules complets avec toutes les informations
  static Future<void> _generateVehiculesComplets() async {
    debugPrint('🚗 Génération véhicules complets...');
    
    final marques = ['Peugeot', 'Renault', 'Citroën', 'Volkswagen', 'Toyota', 'Hyundai', 'Kia', 'Nissan', 'Ford', 'Opel'];
    final modeles = {
      'Peugeot': ['208', '308', '3008', '5008', '2008'],
      'Renault': ['Clio', 'Megane', 'Captur', 'Kadjar', 'Scenic'],
      'Citroën': ['C3', 'C4', 'C5 Aircross', 'Berlingo', 'Picasso'],
      'Volkswagen': ['Golf', 'Polo', 'Tiguan', 'Passat', 'T-Cross'],
      'Toyota': ['Yaris', 'Corolla', 'RAV4', 'C-HR', 'Prius'],
    };
    
    final compagnies = ['STAR', 'MAGHREBIA', 'LLOYD', 'GAT', 'AST'];
    final couleurs = ['Blanc', 'Noir', 'Gris', 'Rouge', 'Bleu', 'Argent'];
    final typesCouverture = ['Tiers', 'Tiers+', 'Tous risques'];
    final relations = ['proprietaire', 'conjoint', 'enfant', 'autre'];

    final batch = _firestore.batch();
    final now = DateTime.now();

    for (int i = 0; i < 500; i++) {
      final marque = marques[_random.nextInt(marques.length)];
      final modele = modeles[marque]?[_random.nextInt(modeles[marque]!.length)] ?? 'Modèle';
      final compagnie = compagnies[_random.nextInt(compagnies.length)];
      final annee = 2015 + _random.nextInt(9);
      
      final vehiculeId = _firestore.collection('vehicules_complets').doc().id;
      
      // Générer le propriétaire
      final proprietaire = ProprietaireVehiculeModel(
        nom: _generateNom(),
        prenom: _generatePrenom(),
        cin: _generateCin(),
        telephone: _generateTelephone(),
        adresse: _generateAdresse(),
        dateNaissance: DateTime(1960 + _random.nextInt(40), 1 + _random.nextInt(12), 1 + _random.nextInt(28)),
      );

      // Générer le contrat
      final dateDebut = DateTime(now.year, 1 + _random.nextInt(12), 1 + _random.nextInt(28));
      final contrat = ContratAssuranceCompletModel(
        numeroContrat: '$compagnie-${now.year}-${(i + 1).toString().padLeft(6, '0')}',
        compagnieId: compagnie,
        agenceId: 'agence_${compagnie.toLowerCase()}001', // Simplification
        agentGestionnaire: 'agent_${_random.nextInt(50) + 1}',
        typeCouverture: typesCouverture[_random.nextInt(typesCouverture.length)],
        dateDebut: dateDebut,
        dateFin: DateTime(dateDebut.year + 1, dateDebut.month, dateDebut.day),
        primeAnnuelle: 800 + _random.nextInt(1200).toDouble(),
        franchise: 200 + _random.nextInt(300).toDouble(),
        statut: 'actif',
      );

      // Générer les conducteurs autorisés
      final conducteursAutorises = <ConducteurAutoriseModel>[
        ConducteurAutoriseModel(
          conducteurEmail: '${proprietaire.prenom.toLowerCase()}.${proprietaire.nom.toLowerCase()}@gmail.com',
          relation: 'proprietaire',
          dateAutorisation: dateDebut,
          permisNumero: _generatePermisNumero(),
          permisDateObtention: DateTime(1990 + _random.nextInt(20), 1 + _random.nextInt(12), 1 + _random.nextInt(28)),
          droits: ['conduire', 'declarer_sinistre'],
        ),
      ];

      // Ajouter parfois un deuxième conducteur
      if (_random.nextDouble() < 0.3) {
        conducteursAutorises.add(
          ConducteurAutoriseModel(
            conducteurEmail: 'conducteur${i + 500}@gmail.com',
            relation: relations[_random.nextInt(relations.length)],
            dateAutorisation: dateDebut.add(Duration(days: _random.nextInt(365))),
            permisNumero: _generatePermisNumero(),
            permisDateObtention: DateTime(1995 + _random.nextInt(15), 1 + _random.nextInt(12), 1 + _random.nextInt(28)),
            droits: ['conduire'],
          ),
        );
      }

      final vehicule = VehiculeCompletModel(
        id: vehiculeId,
        immatriculation: _generateImmatriculation(),
        marque: marque,
        modele: modele,
        annee: annee,
        couleur: couleurs[_random.nextInt(couleurs.length)],
        numeroChassis: _generateNumeroChassis(),
        puissanceFiscale: 4 + _random.nextInt(8),
        typeCarburant: _random.nextBool() ? 'Essence' : 'Diesel',
        nombrePlaces: 5,
        proprietaire: proprietaire,
        contrat: contrat,
        conducteursAutorises: conducteursAutorises,
        historiqueSinistres: [],
        derniereMiseAJour: now,
        createdAt: now,
        updatedAt: now,
      );

      batch.set(
        _firestore.collection('vehicules_complets').doc(vehiculeId),
        vehicule.toFirestore(),
      );

      // Commit par batch de 100
      if ((i + 1) % 100 == 0) {
        await batch.commit();
        debugPrint('✅ ${i + 1} véhicules créés');
      }
    }

    // Commit final
    await batch.commit();
    debugPrint('✅ 500 véhicules complets créés');
  }

  // Méthodes utilitaires
  static String _generateImmatriculation() {
    final numbers = _random.nextInt(999) + 1;
    final region = ['TUN', 'SFX', 'SOU', 'BIZ', 'GAB'][_random.nextInt(5)];
    final suffix = _random.nextInt(999) + 1;
    return '${numbers.toString().padLeft(3, '0')} $region ${suffix.toString().padLeft(3, '0')}';
  }

  static String _generateNumeroChassis() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(17, (index) => chars[_random.nextInt(chars.length)]).join();
  }

  static String _generateCin() {
    return (10000000 + _random.nextInt(90000000)).toString();
  }

  static String _generateTelephone() {
    final prefixes = ['20', '21', '22', '23', '24', '25', '26', '27', '28', '29'];
    final prefix = prefixes[_random.nextInt(prefixes.length)];
    final number = _random.nextInt(999999).toString().padLeft(6, '0');
    return '+216 $prefix $number';
  }

  static String _generatePermisNumero() {
    return (100000 + _random.nextInt(900000)).toString();
  }

  static String _generateNom() {
    final noms = [
      'Ben Ali', 'Trabelsi', 'Bouazizi', 'Chedly', 'Hammami', 'Jebali',
      'Marzouki', 'Essebsi', 'Karoui', 'Belhaj', 'Sfar', 'Gharbi',
      'Nasri', 'Khelifi', 'Mansouri', 'Agrebi', 'Dridi', 'Mejri'
    ];
    return noms[_random.nextInt(noms.length)];
  }

  static String _generatePrenom() {
    final prenoms = [
      'Mohamed', 'Ahmed', 'Ali', 'Mahmoud', 'Omar', 'Youssef', 'Karim', 'Sami',
      'Fatma', 'Aisha', 'Khadija', 'Maryam', 'Salma', 'Nour', 'Rahma', 'Ines',
      'Amira', 'Yasmine', 'Dorra', 'Emna', 'Hajer', 'Rim', 'Sarra', 'Wiem'
    ];
    return prenoms[_random.nextInt(prenoms.length)];
  }

  static String _generateStreetName() {
    final rues = [
      'Habib Bourguiba', 'de la Liberté', 'Mohamed V', 'Ibn Khaldoun', 
      'de la République', 'de la Paix', 'Hedi Chaker', 'Mongi Bali'
    ];
    return rues[_random.nextInt(rues.length)];
  }

  static String _generateAdresse() {
    final numero = _random.nextInt(200) + 1;
    final rue = _generateStreetName();
    final villes = ['Tunis', 'Sfax', 'Sousse', 'Bizerte', 'Gabès', 'Monastir'];
    final ville = villes[_random.nextInt(villes.length)];
    
    return '$numero Avenue $rue, $ville';
  }
}
