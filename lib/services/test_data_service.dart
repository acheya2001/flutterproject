import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/tunisian_insurance_models.dart';
import 'dart:math';

/// 🧪 Service pour générer des données de test
class TestDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();

  /// 🏢 Créer des compagnies d'assurance de test
  static Future<void> createTestCompagnies() async {
    if (!kDebugMode) return; // Seulement en mode debug

    final compagnies = [
      {
        'nom': 'COMAR Assurances',
        'code': 'COMAR',
        'adresseSiege': 'Avenue Habib Bourguiba, Tunis',
        'telephone': '+216 71 123 456',
        'email': 'contact@comar.com.tn',
        'numeroAgrement': 'AGR-COMAR-001',
        'isActive': true,
        'dateCreation': Timestamp.now(),
        'typesAssurance': ['auto', 'habitation', 'vie'],
        'tarifBase': {
          'voiture': 180.0,
          'camionnette': 250.0,
          'moto': 120.0,
        },
        'isFakeData': true,
      },
      {
        'nom': 'STAR Assurances',
        'code': 'STAR',
        'adresseSiege': 'Rue de la Liberté, Sfax',
        'telephone': '+216 74 987 654',
        'email': 'info@star.com.tn',
        'numeroAgrement': 'AGR-STAR-002',
        'isActive': true,
        'dateCreation': Timestamp.now(),
        'typesAssurance': ['auto', 'transport', 'maritime'],
        'tarifBase': {
          'voiture': 175.0,
          'camionnette': 245.0,
          'moto': 115.0,
        },
        'isFakeData': true,
      },
      {
        'nom': 'GAT Assurances',
        'code': 'GAT',
        'adresseSiege': 'Boulevard du 14 Janvier, Sousse',
        'telephone': '+216 73 555 777',
        'email': 'service@gat.com.tn',
        'numeroAgrement': 'AGR-GAT-003',
        'isActive': true,
        'dateCreation': Timestamp.now(),
        'typesAssurance': ['auto', 'sante', 'accident'],
        'tarifBase': {
          'voiture': 185.0,
          'camionnette': 255.0,
          'moto': 125.0,
        },
        'isFakeData': true,
      },
    ];

    for (var compagnie in compagnies) {
      await _firestore.collection('compagnies_assurance').add(compagnie);
      debugPrint('✅ Compagnie créée: ${compagnie['nom']}');
    }
  }

  /// 🏪 Créer des agences de test
  static Future<void> createTestAgences(String compagnieId) async {
    if (!kDebugMode) return;

    final agences = [
      {
        'compagnieId': compagnieId,
        'nom': 'Agence Centre Ville',
        'code': 'AGE-CV-001',
        'adresse': 'Avenue Bourguiba, Centre Ville',
        'ville': 'Tunis',
        'telephone': '+216 71 111 222',
        'email': 'centerville@agence.tn',
        'agentGeneralId': 'agent_general_1',
        'agentGeneralNom': 'Ahmed Ben Ali',
        'isActive': true,
        'dateCreation': Timestamp.now(),
        'statistiques': {
          'contratsActifs': 150,
          'chiffreAffaires': 75000,
          'tauxRenouvellement': 85,
        },
        'isFakeData': true,
      },
      {
        'compagnieId': compagnieId,
        'nom': 'Agence Manouba',
        'code': 'AGE-MAN-002',
        'adresse': 'Route de Bizerte, Manouba',
        'ville': 'Manouba',
        'telephone': '+216 71 333 444',
        'email': 'manouba@agence.tn',
        'agentGeneralId': 'agent_general_2',
        'agentGeneralNom': 'Fatma Trabelsi',
        'isActive': true,
        'dateCreation': Timestamp.now(),
        'statistiques': {
          'contratsActifs': 95,
          'chiffreAffaires': 48000,
          'tauxRenouvellement': 78,
        },
        'isFakeData': true,
      },
    ];

    for (var agence in agences) {
      await _firestore.collection('agences_assurance').add(agence);
      debugPrint('✅ Agence créée: ${agence['nom']}');
    }
  }

  /// 👨‍💼 Créer des agents de test
  static Future<void> createTestAgents(String compagnieId, String agenceId) async {
    if (!kDebugMode) return;

    final agents = [
      {
        'compagnieId': compagnieId,
        'agenceId': agenceId,
        'nom': 'Bouazizi',
        'prenom': 'Mohamed',
        'cin': '12345678',
        'telephone': '+216 98 123 456',
        'email': 'mohamed.bouazizi@agent.tn',
        'adresse': 'Rue de la Paix, Tunis',
        'numeroLicence': 'LIC-001-2024',
        'dateEmbauche': Timestamp.now(),
        'isActive': true,
        'permissions': {
          'creerContrat': true,
          'encaisserPaiement': true,
          'genererDocuments': true,
          'traiterRenouvellement': true,
        },
        'statistiques': {
          'contratsCreesAnnee': 45,
          'chiffreAffairesAnnee': 22500,
          'tauxRenouvellement': 82,
        },
        'isFakeData': true,
      },
      {
        'compagnieId': compagnieId,
        'agenceId': agenceId,
        'nom': 'Karray',
        'prenom': 'Leila',
        'cin': '87654321',
        'telephone': '+216 97 987 654',
        'email': 'leila.karray@agent.tn',
        'adresse': 'Avenue de la République, Ariana',
        'numeroLicence': 'LIC-002-2024',
        'dateEmbauche': Timestamp.now(),
        'isActive': true,
        'permissions': {
          'creerContrat': true,
          'encaisserPaiement': true,
          'genererDocuments': true,
          'traiterRenouvellement': false,
        },
        'statistiques': {
          'contratsCreesAnnee': 32,
          'chiffreAffairesAnnee': 16800,
          'tauxRenouvellement': 75,
        },
        'isFakeData': true,
      },
    ];

    for (var agent in agents) {
      await _firestore.collection('agents_assurance').add(agent);
      debugPrint('✅ Agent créé: ${agent['prenom']} ${agent['nom']}');
    }
  }

  /// 🚗 Créer des véhicules de test
  static Future<void> createTestVehicules(String conducteurId) async {
    if (!kDebugMode) return;

    final vehicules = [
      {
        'conducteurId': conducteurId,
        'numeroImmatriculation': '123 TUN 456',
        'numeroCarteGrise': 'CG-2024-001234',
        'marque': 'Toyota',
        'modele': 'Corolla',
        'annee': 2020,
        'couleur': 'Blanc',
        'typeVehicule': 'voiture',
        'puissanceFiscale': 6,
        'carburant': 'Essence',
        'numeroSerie': 'VIN123456789',
        'datePremiereImmatriculation': Timestamp.fromDate(DateTime(2020, 3, 15)),
        'proprietaire': {
          'nom': 'Ben Salem',
          'prenom': 'Karim',
          'cin': '11223344',
          'adresse': 'Rue des Oliviers, Tunis',
          'telephone': '+216 98 111 222',
        },
        'isActive': true,
        'dateCreation': Timestamp.now(),
        'isFakeData': true,
      },
      {
        'conducteurId': conducteurId,
        'numeroImmatriculation': '789 TUN 012',
        'numeroCarteGrise': 'CG-2024-005678',
        'marque': 'Peugeot',
        'modele': '208',
        'annee': 2019,
        'couleur': 'Rouge',
        'typeVehicule': 'voiture',
        'puissanceFiscale': 5,
        'carburant': 'Essence',
        'numeroSerie': 'VIN987654321',
        'datePremiereImmatriculation': Timestamp.fromDate(DateTime(2019, 7, 22)),
        'proprietaire': {
          'nom': 'Jemli',
          'prenom': 'Sarra',
          'cin': '55667788',
          'adresse': 'Avenue Habib Bourguiba, Sfax',
          'telephone': '+216 97 333 444',
        },
        'isActive': true,
        'dateCreation': Timestamp.now(),
        'isFakeData': true,
      },
    ];

    for (var vehicule in vehicules) {
      await _firestore.collection('vehicules_assures').add(vehicule);
      debugPrint('✅ Véhicule créé: ${vehicule['marque']} ${vehicule['modele']}');
    }
  }

  /// 📋 Créer des contrats de test
  static Future<void> createTestContrats({
    required String vehiculeId,
    required String conducteurId,
    required String agentId,
    required String agenceId,
    required String compagnieId,
  }) async {
    if (!kDebugMode) return;

    final contrats = [
      {
        'numeroContrat': 'CTR-2024-${_random.nextInt(999999).toString().padLeft(6, '0')}',
        'vehiculeId': vehiculeId,
        'conducteurId': conducteurId,
        'agentId': agentId,
        'agenceId': agenceId,
        'compagnieId': compagnieId,
        'typeCouverture': 'tous_risques',
        'garanties': ['Responsabilité Civile', 'Dommages Collision', 'Vol', 'Incendie'],
        'primeAnnuelle': 450.0,
        'franchise': 200.0,
        'dateDebut': Timestamp.fromDate(DateTime.now()),
        'dateFin': Timestamp.fromDate(DateTime.now().add(const Duration(days: 365))),
        'dateEcheance': Timestamp.fromDate(DateTime.now().add(const Duration(days: 335))),
        'statut': 'actif',
        'paiement': {
          'typePaiement': 'especes',
          'frequence': 'annuel',
          'montantPaye': 450.0,
          'datePaiement': Timestamp.now(),
        },
        'documents': {
          'policeGeneree': true,
          'quittanceGeneree': true,
          'macaronGenere': true,
        },
        'dateCreation': Timestamp.now(),
        'isFakeData': true,
      },
      {
        'numeroContrat': 'CTR-2024-${_random.nextInt(999999).toString().padLeft(6, '0')}',
        'vehiculeId': vehiculeId,
        'conducteurId': conducteurId,
        'agentId': agentId,
        'agenceId': agenceId,
        'compagnieId': compagnieId,
        'typeCouverture': 'responsabilite_civile',
        'garanties': ['Responsabilité Civile', 'Défense Recours'],
        'primeAnnuelle': 180.0,
        'franchise': 0.0,
        'dateDebut': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 300))),
        'dateFin': Timestamp.fromDate(DateTime.now().add(const Duration(days: 65))),
        'dateEcheance': Timestamp.fromDate(DateTime.now().add(const Duration(days: 35))),
        'statut': 'actif',
        'paiement': {
          'typePaiement': 'carte_bancaire',
          'frequence': 'annuel',
          'montantPaye': 180.0,
          'datePaiement': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 300))),
        },
        'documents': {
          'policeGeneree': true,
          'quittanceGeneree': true,
          'macaronGenere': true,
        },
        'dateCreation': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 300))),
        'isFakeData': true,
      },
    ];

    for (var contrat in contrats) {
      await _firestore.collection('contrats_assurance').add(contrat);
      debugPrint('✅ Contrat créé: ${contrat['numeroContrat']}');
    }
  }

  /// 🧪 Créer un jeu de données complet pour les tests
  static Future<Map<String, String>> createCompleteTestDataSet() async {
    if (!kDebugMode) {
      debugPrint('❌ Génération de données de test disponible uniquement en mode debug');
      return {};
    }

    try {
      debugPrint('🧪 Début génération données de test...');

      // 1. Créer les compagnies
      await createTestCompagnies();
      
      // 2. Récupérer l'ID de la première compagnie créée
      final compagniesQuery = await _firestore
          .collection('compagnies_assurance')
          .where('isFakeData', isEqualTo: true)
          .limit(1)
          .get();
      
      if (compagniesQuery.docs.isEmpty) {
        throw Exception('Aucune compagnie de test trouvée');
      }
      
      final compagnieId = compagniesQuery.docs.first.id;
      
      // 3. Créer les agences
      await createTestAgences(compagnieId);
      
      // 4. Récupérer l'ID de la première agence créée
      final agencesQuery = await _firestore
          .collection('agences_assurance')
          .where('compagnieId', isEqualTo: compagnieId)
          .where('isFakeData', isEqualTo: true)
          .limit(1)
          .get();
      
      final agenceId = agencesQuery.docs.first.id;
      
      // 5. Créer les agents
      await createTestAgents(compagnieId, agenceId);
      
      // 6. Récupérer l'ID du premier agent créé
      final agentsQuery = await _firestore
          .collection('agents_assurance')
          .where('agenceId', isEqualTo: agenceId)
          .where('isFakeData', isEqualTo: true)
          .limit(1)
          .get();
      
      final agentId = agentsQuery.docs.first.id;
      
      // 7. Créer un conducteur de test
      const conducteurId = 'test_conducteur_001';
      await _firestore.collection('conducteurs').doc(conducteurId).set({
        'nom': 'Testeur',
        'prenom': 'Test',
        'cin': '99887766',
        'telephone': '+216 99 999 999',
        'email': 'test@conducteur.tn',
        'adresse': 'Adresse de test, Tunis',
        'dateNaissance': Timestamp.fromDate(DateTime(1990, 5, 15)),
        'numeroPermis': 'PERMIS-TEST-001',
        'dateCreation': Timestamp.now(),
        'isFakeData': true,
      });
      
      // 8. Créer les véhicules
      await createTestVehicules(conducteurId);
      
      // 9. Récupérer l'ID du premier véhicule créé
      final vehiculesQuery = await _firestore
          .collection('vehicules_assures')
          .where('conducteurId', isEqualTo: conducteurId)
          .where('isFakeData', isEqualTo: true)
          .limit(1)
          .get();
      
      final vehiculeId = vehiculesQuery.docs.first.id;
      
      // 10. Créer les contrats
      await createTestContrats(
        vehiculeId: vehiculeId,
        conducteurId: conducteurId,
        agentId: agentId,
        agenceId: agenceId,
        compagnieId: compagnieId,
      );

      debugPrint('✅ Génération données de test terminée avec succès !');
      
      return {
        'compagnieId': compagnieId,
        'agenceId': agenceId,
        'agentId': agentId,
        'conducteurId': conducteurId,
        'vehiculeId': vehiculeId,
      };
      
    } catch (e) {
      debugPrint('❌ Erreur génération données de test: $e');
      return {};
    }
  }

  /// 🗑️ Nettoyer toutes les données de test
  static Future<void> cleanupTestData() async {
    if (!kDebugMode) return;

    try {
      debugPrint('🗑️ Nettoyage des données de test...');

      final collections = [
        'compagnies_assurance',
        'agences_assurance',
        'agents_assurance',
        'vehicules_assures',
        'contrats_assurance',
        'conducteurs',
        'paiements_assurance',
        'polices_assurance',
        'quittances_paiement',
        'macarons_assurance',
      ];

      for (String collection in collections) {
        final query = await _firestore
            .collection(collection)
            .where('isFakeData', isEqualTo: true)
            .get();

        for (var doc in query.docs) {
          await doc.reference.delete();
        }
        
        debugPrint('✅ Collection $collection nettoyée (${query.docs.length} documents)');
      }

      debugPrint('✅ Nettoyage terminé !');
      
    } catch (e) {
      debugPrint('❌ Erreur nettoyage données de test: $e');
    }
  }

  /// 📊 Afficher les statistiques des données de test
  static Future<void> showTestDataStats() async {
    if (!kDebugMode) return;

    try {
      final collections = [
        'compagnies_assurance',
        'agences_assurance', 
        'agents_assurance',
        'vehicules_assures',
        'contrats_assurance',
      ];

      debugPrint('📊 Statistiques des données de test:');
      
      for (String collection in collections) {
        final query = await _firestore
            .collection(collection)
            .where('isFakeData', isEqualTo: true)
            .get();
        
        debugPrint('   $collection: ${query.docs.length} documents');
      }
      
    } catch (e) {
      debugPrint('❌ Erreur affichage statistiques: $e');
    }
  }
}
