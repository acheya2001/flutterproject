import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/compagnie_assurance_model.dart';
import '../models/agence_model.dart';
import '../models/agent_assurance_model.dart';

/// 🏭 Générateur de données de test pour le secteur de l'assurance
class InsuranceDataGenerator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();

  /// 🏢 Compagnies d'assurance tunisiennes
  static const List<Map<String, dynamic>> _compagnies = [
    {
      'id': 'STAR',
      'nom': 'STAR Assurances',
      'siret': '1234567890123',
      'adresse': 'Avenue Habib Bourguiba, 1000 Tunis',
      'telephone': '+216 71 123 456',
      'email': 'contact@star.tn',
    },
    {
      'id': 'MAGHREBIA',
      'nom': 'Maghrebia Assurances',
      'siret': '2345678901234',
      'adresse': 'Rue de la Liberté, 1002 Tunis',
      'telephone': '+216 71 234 567',
      'email': 'info@maghrebia.tn',
    },
    {
      'id': 'LLOYD',
      'nom': 'Lloyd Tunisien',
      'siret': '3456789012345',
      'adresse': 'Avenue Mohamed V, 1001 Tunis',
      'telephone': '+216 71 345 678',
      'email': 'contact@lloyd.tn',
    },
    {
      'id': 'GAT',
      'nom': 'GAT Assurances',
      'siret': '4567890123456',
      'adresse': 'Rue Ibn Khaldoun, 1003 Tunis',
      'telephone': '+216 71 456 789',
      'email': 'info@gat.tn',
    },
    {
      'id': 'AST',
      'nom': 'Assurances Salim',
      'siret': '5678901234567',
      'adresse': 'Avenue de la République, 1004 Tunis',
      'telephone': '+216 71 567 890',
      'email': 'contact@ast.tn',
    },
  ];

  /// 🏪 Modèles d'agences par gouvernorat
  static const Map<String, List<Map<String, dynamic>>> _agencesParGouvernorat = {
    'Tunis': [
      {'nom': 'Centre Ville', 'code': 'TC', 'adresse': 'Avenue Habib Bourguiba'},
      {'nom': 'Bab Bhar', 'code': 'TB', 'adresse': 'Place Bab Bhar'},
      {'nom': 'Menzah', 'code': 'TM', 'adresse': 'Centre Commercial Menzah'},
    ],
    'Sfax': [
      {'nom': 'Sfax Centre', 'code': 'SC', 'adresse': 'Avenue Hedi Chaker'},
      {'nom': 'Sfax Nord', 'code': 'SN', 'adresse': 'Route de Tunis'},
    ],
    'Sousse': [
      {'nom': 'Sousse Medina', 'code': 'SM', 'adresse': 'Avenue Bourguiba'},
      {'nom': 'Sousse Kantaoui', 'code': 'SK', 'adresse': 'Port El Kantaoui'},
    ],
    'Monastir': [
      {'nom': 'Monastir Centre', 'code': 'MC', 'adresse': 'Avenue de l\'Indépendance'},
    ],
    'Nabeul': [
      {'nom': 'Nabeul Centre', 'code': 'NC', 'adresse': 'Avenue Taieb Mehiri'},
      {'nom': 'Hammamet', 'code': 'NH', 'adresse': 'Avenue de la Paix'},
    ],
  };

  /// 👨‍💼 Noms et prénoms tunisiens
  static const List<String> _prenoms = [
    'Mohamed', 'Ahmed', 'Ali', 'Mahmoud', 'Omar', 'Youssef', 'Karim', 'Sami',
    'Fatma', 'Aisha', 'Khadija', 'Maryam', 'Salma', 'Nour', 'Rahma', 'Ines'
  ];

  static const List<String> _noms = [
    'Ben Ali', 'Trabelsi', 'Bouazizi', 'Chedly', 'Hammami', 'Jebali',
    'Marzouki', 'Essebsi', 'Karoui', 'Belhaj', 'Sfar', 'Gharbi'
  ];

  /// 🎯 Spécialités d'assurance
  static const List<String> _specialites = [
    'automobile', 'habitation', 'vie', 'santé', 'voyage', 'responsabilité_civile'
  ];

  /// 🏗️ Générer toutes les données de test
  static Future<void> generateAllTestData() async {
    print('🚀 Génération des données de test...');
    
    try {
      // 1. Générer les compagnies
      await _generateCompagnies();
      
      // 2. Générer les agences
      await _generateAgences();
      
      // 3. Générer les agents
      await _generateAgents();
      
      print('✅ Génération terminée avec succès !');
    } catch (e) {
      print('❌ Erreur lors de la génération: $e');
      rethrow;
    }
  }

  /// 🏢 Générer les compagnies d'assurance
  static Future<void> _generateCompagnies() async {
    print('📊 Génération des compagnies...');
    
    final batch = _firestore.batch();
    final now = DateTime.now();

    for (final compagnieData in _compagnies) {
      final compagnie = CompagnieAssuranceModel(
        id: compagnieData['id'],
        nom: compagnieData['nom'],
        siret: compagnieData['siret'],
        adresseSiege: compagnieData['adresse'],
        telephone: compagnieData['telephone'],
        email: compagnieData['email'],
        agences: [], // Sera mis à jour après création des agences
        createdAt: now,
        updatedAt: now,
      );

      final docRef = _firestore.collection('compagnies_assurance').doc(compagnie.id);
      batch.set(docRef, compagnie.toFirestore());
    }

    await batch.commit();
    print('✅ ${_compagnies.length} compagnies créées');
  }

  /// 🏪 Générer les agences
  static Future<void> _generateAgences() async {
    print('🏪 Génération des agences...');
    
    int agenceCount = 0;
    
    for (final compagnieData in _compagnies) {
      final compagnieId = compagnieData['id'];
      final List<String> agenceIds = [];
      
      // Créer 2-3 agences par compagnie
      final gouvernorats = _agencesParGouvernorat.keys.take(3).toList();
      
      for (final gouvernorat in gouvernorats) {
        final agencesGouvernorat = _agencesParGouvernorat[gouvernorat]!;
        final agenceTemplate = agencesGouvernorat[_random.nextInt(agencesGouvernorat.length)];
        
        final agenceId = '${compagnieId.toLowerCase()}_${gouvernorat.toLowerCase()}';
        agenceIds.add(agenceId);
        
        final agence = AgenceModel(
          id: agenceId,
          compagnieId: compagnieId,
          nom: '${compagnieData['nom']} ${agenceTemplate['nom']}',
          codeAgence: '${agenceTemplate['code']}${_random.nextInt(100).toString().padLeft(2, '0')}',
          adresse: '${agenceTemplate['adresse']}, $gouvernorat',
          telephone: '+216 ${70 + _random.nextInt(9)} ${_random.nextInt(900) + 100} ${_random.nextInt(900) + 100}',
          email: '${gouvernorat.toLowerCase()}@${compagnieId.toLowerCase()}.tn',
          directeur: DirecteurAgence(
            nom: _noms[_random.nextInt(_noms.length)],
            prenom: _prenoms[_random.nextInt(_prenoms.length)],
            telephone: '+216 ${90 + _random.nextInt(9)} ${_random.nextInt(900) + 100} ${_random.nextInt(900) + 100}',
          ),
          agents: [], // Sera mis à jour après création des agents
          zoneGeographique: [gouvernorat],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore.collection('agences').doc(agenceId).set(agence.toFirestore());
        agenceCount++;
      }
      
      // Mettre à jour la compagnie avec ses agences
      await _firestore.collection('compagnies_assurance').doc(compagnieId).update({
        'agences': agenceIds,
      });
    }
    
    print('✅ $agenceCount agences créées');
  }

  /// 👨‍💼 Générer les agents d'assurance
  static Future<void> _generateAgents() async {
    print('👨‍💼 Génération des agents...');
    
    final agencesSnapshot = await _firestore.collection('agences').get();
    int agentCount = 0;
    
    for (final agenceDoc in agencesSnapshot.docs) {
      final agence = AgenceModel.fromFirestore(agenceDoc);
      final List<String> agentIds = [];
      
      // Créer 2-4 agents par agence
      final nombreAgents = 2 + _random.nextInt(3);
      
      for (int i = 0; i < nombreAgents; i++) {
        final agentId = '${agence.id}_agent_${i + 1}';
        agentIds.add(agentId);
        
        final agent = AgentAssuranceModel(
          id: agentId,
          userId: 'user_$agentId', // Lien fictif vers users
          compagnieId: agence.compagnieId,
          agenceId: agence.id,
          matriculeAgent: '${agence.codeAgence}${(i + 1).toString().padLeft(3, '0')}',
          specialites: _getRandomSpecialites(),
          portefeuilleClients: [], // Sera rempli plus tard
          objectifsMensuels: ObjectifsMensuels(
            nouveauxContrats: 5 + _random.nextInt(16), // 5-20 contrats
            chiffreAffaires: 20000 + _random.nextInt(80000).toDouble(), // 20k-100k TND
          ),
          performance: PerformanceAgent(
            contratsSignes: _random.nextInt(15), // 0-14 contrats
            caRealise: _random.nextInt(70000).toDouble(), // 0-70k TND
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore.collection('agents_assurance').doc(agentId).set(agent.toFirestore());
        agentCount++;
      }
      
      // Mettre à jour l'agence avec ses agents
      await _firestore.collection('agences').doc(agence.id).update({
        'agents': agentIds,
      });
    }
    
    print('✅ $agentCount agents créés');
  }

  /// 🎯 Obtenir des spécialités aléatoires
  static List<String> _getRandomSpecialites() {
    final nombreSpecialites = 1 + _random.nextInt(3); // 1-3 spécialités
    final specialites = List<String>.from(_specialites);
    specialites.shuffle(_random);
    return specialites.take(nombreSpecialites).toList();
  }

  /// 🗑️ Nettoyer toutes les données de test
  static Future<void> clearAllTestData() async {
    print('🗑️ Suppression des données de test...');
    
    final batch = _firestore.batch();
    
    // Supprimer agents
    final agentsSnapshot = await _firestore.collection('agents_assurance').get();
    for (final doc in agentsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    // Supprimer agences
    final agencesSnapshot = await _firestore.collection('agences').get();
    for (final doc in agencesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    // Supprimer compagnies
    final compagniesSnapshot = await _firestore.collection('compagnies_assurance').get();
    for (final doc in compagniesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
    print('✅ Données supprimées');
  }
}
