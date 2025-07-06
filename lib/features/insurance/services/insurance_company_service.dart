import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/compagnie_model.dart';
import '../models/agent_model.dart';

/// 🏢 Service de gestion des compagnies d'assurance
class InsuranceCompanyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections Firestore
  static const String _compagniesCollection = 'compagnies_assurance';
  static const String _agencesCollection = 'agences_assurance';
  static const String _agentsCollection = 'agents_assurance';
  static const String _expertsCollection = 'experts_assurance';

  /// 🏢 Créer les compagnies d'assurance principales de Tunisie
  static Future<void> initializeMainCompanies() async {
    debugPrint('[InsuranceService] 🏢 Initialisation des compagnies principales...');

    final companies = [
      {
        'nom': 'STAR Assurances',
        'logo': 'https://example.com/star-logo.png',
        'adresse_siege': 'Avenue Habib Bourguiba, Tunis',
        'telephone': '+216 71 340 000',
        'email': 'contact@star.com.tn',
        'site_web': 'https://www.star.com.tn',
        'numero_agrement': 'AGR-STAR-001',
        'types_assurance': ['Automobile', 'Habitation', 'Vie', 'Santé'],
      },
      {
        'nom': 'Maghrebia Assurances',
        'logo': 'https://example.com/maghrebia-logo.png',
        'adresse_siege': 'Rue de la Liberté, Tunis',
        'telephone': '+216 71 250 000',
        'email': 'contact@maghrebia.com.tn',
        'site_web': 'https://www.maghrebia.com.tn',
        'numero_agrement': 'AGR-MAGH-001',
        'types_assurance': ['Automobile', 'Habitation', 'Vie'],
      },
      {
        'nom': 'Assurances Salim',
        'logo': 'https://example.com/salim-logo.png',
        'adresse_siege': 'Avenue Mohamed V, Tunis',
        'telephone': '+216 71 180 000',
        'email': 'contact@salim.com.tn',
        'site_web': 'https://www.salim.com.tn',
        'numero_agrement': 'AGR-SALIM-001',
        'types_assurance': ['Automobile', 'Habitation'],
      },
      {
        'nom': 'GAT Assurances',
        'logo': 'https://example.com/gat-logo.png',
        'adresse_siege': 'Rue Ibn Khaldoun, Tunis',
        'telephone': '+216 71 290 000',
        'email': 'contact@gat.com.tn',
        'site_web': 'https://www.gat.com.tn',
        'numero_agrement': 'AGR-GAT-001',
        'types_assurance': ['Automobile', 'Transport'],
      },
    ];

    for (final companyData in companies) {
      try {
        // Vérifier si la compagnie existe déjà
        final existingQuery = await _firestore
            .collection(_compagniesCollection)
            .where('nom', isEqualTo: companyData['nom'])
            .get();

        if (existingQuery.docs.isEmpty) {
          // Créer la compagnie
          final compagnie = CompagnieModel(
            id: '', // Sera généré par Firestore
            nom: companyData['nom'] as String,
            logo: companyData['logo'] as String,
            adresseSiege: companyData['adresse_siege'] as String,
            telephone: companyData['telephone'] as String,
            email: companyData['email'] as String,
            siteWeb: companyData['site_web'] as String,
            numeroAgrement: companyData['numero_agrement'] as String,
            typesAssurance: List<String>.from(companyData['types_assurance'] as List),
            dateCreation: DateTime.now(),
            statistiques: {
              'nombre_agences': 0,
              'nombre_agents': 0,
              'nombre_clients': 0,
              'nombre_contrats': 0,
            },
          );

          final docRef = await _firestore
              .collection(_compagniesCollection)
              .add(compagnie.toFirestore());

          debugPrint('[InsuranceService] ✅ Compagnie créée: ${companyData['nom']} (${docRef.id})');
        } else {
          debugPrint('[InsuranceService] ⚠️ Compagnie existe déjà: ${companyData['nom']}');
        }
      } catch (e) {
        debugPrint('[InsuranceService] ❌ Erreur création ${companyData['nom']}: $e');
      }
    }
  }

  /// 🏪 Créer des agences pour chaque compagnie
  static Future<void> createAgenciesForCompanies() async {
    debugPrint('[InsuranceService] 🏪 Création des agences...');

    // Récupérer toutes les compagnies
    final companiesSnapshot = await _firestore.collection(_compagniesCollection).get();

    final gouvernorats = [
      'Tunis', 'Ariana', 'Ben Arous', 'Manouba',
      'Sfax', 'Sousse', 'Monastir', 'Mahdia',
      'Bizerte', 'Nabeul', 'Zaghouan', 'Siliana',
      'Kairouan', 'Kasserine', 'Sidi Bouzid',
      'Gafsa', 'Tozeur', 'Kebili', 'Gabes',
      'Medenine', 'Tataouine', 'Le Kef', 'Jendouba', 'Beja'
    ];

    for (final companyDoc in companiesSnapshot.docs) {
      final compagnieId = companyDoc.id;
      final compagnieNom = companyDoc.data()['nom'] as String;

      // Créer 3-5 agences par compagnie dans différents gouvernorats
      final selectedGouvernorats = gouvernorats.take(5).toList();

      for (int i = 0; i < selectedGouvernorats.length; i++) {
        final gouvernorat = selectedGouvernorats[i];
        
        try {
          // Vérifier si l'agence existe déjà
          final existingQuery = await _firestore
              .collection(_agencesCollection)
              .where('compagnie_id', isEqualTo: compagnieId)
              .where('gouvernorat', isEqualTo: gouvernorat)
              .get();

          if (existingQuery.docs.isEmpty) {
            final agence = AgenceModel(
              id: '', // Sera généré par Firestore
              compagnieId: compagnieId,
              nom: '$compagnieNom - Agence $gouvernorat',
              adresse: 'Avenue Principale, $gouvernorat',
              ville: gouvernorat,
              codePostal: '${1000 + i}',
              gouvernorat: gouvernorat,
              telephone: '+216 ${70 + i} ${100 + i} ${200 + i}',
              email: '${gouvernorat.toLowerCase()}@${compagnieNom.toLowerCase().replaceAll(' ', '')}.tn',
              responsable: 'Responsable $gouvernorat',
              dateCreation: DateTime.now(),
              statistiques: {
                'nombre_agents': 0,
                'nombre_clients': 0,
                'nombre_contrats': 0,
              },
            );

            final docRef = await _firestore
                .collection(_agencesCollection)
                .add(agence.toFirestore());

            debugPrint('[InsuranceService] ✅ Agence créée: ${agence.nom} (${docRef.id})');
          }
        } catch (e) {
          debugPrint('[InsuranceService] ❌ Erreur création agence $gouvernorat pour $compagnieNom: $e');
        }
      }
    }
  }

  /// 📊 Obtenir toutes les compagnies
  static Future<List<CompagnieModel>> getAllCompanies() async {
    try {
      final snapshot = await _firestore
          .collection(_compagniesCollection)
          .where('active', isEqualTo: true)
          .orderBy('nom')
          .get();

      return snapshot.docs
          .map((doc) => CompagnieModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('[InsuranceService] ❌ Erreur récupération compagnies: $e');
      return [];
    }
  }

  /// 🏪 Obtenir les agences d'une compagnie
  static Future<List<AgenceModel>> getAgenciesByCompany(String compagnieId) async {
    try {
      final snapshot = await _firestore
          .collection(_agencesCollection)
          .where('compagnie_id', isEqualTo: compagnieId)
          .where('active', isEqualTo: true)
          .orderBy('nom')
          .get();

      return snapshot.docs
          .map((doc) => AgenceModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('[InsuranceService] ❌ Erreur récupération agences: $e');
      return [];
    }
  }

  /// 👨‍💼 Obtenir les agents d'une agence
  static Future<List<AgentModel>> getAgentsByAgency(String agenceId) async {
    try {
      final snapshot = await _firestore
          .collection(_agentsCollection)
          .where('agence_id', isEqualTo: agenceId)
          .where('account_status', isEqualTo: 'active')
          .orderBy('nom')
          .get();

      return snapshot.docs
          .map((doc) => AgentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('[InsuranceService] ❌ Erreur récupération agents: $e');
      return [];
    }
  }

  /// 📈 Mettre à jour les statistiques d'une compagnie
  static Future<void> updateCompanyStatistics(String compagnieId) async {
    try {
      // Compter les agences
      final agencesSnapshot = await _firestore
          .collection(_agencesCollection)
          .where('compagnie_id', isEqualTo: compagnieId)
          .where('active', isEqualTo: true)
          .get();

      // Compter les agents
      final agentsSnapshot = await _firestore
          .collection(_agentsCollection)
          .where('compagnie_id', isEqualTo: compagnieId)
          .where('account_status', isEqualTo: 'active')
          .get();

      // Mettre à jour les statistiques
      await _firestore
          .collection(_compagniesCollection)
          .doc(compagnieId)
          .update({
        'statistiques.nombre_agences': agencesSnapshot.docs.length,
        'statistiques.nombre_agents': agentsSnapshot.docs.length,
        'date_modification': Timestamp.now(),
      });

      debugPrint('[InsuranceService] ✅ Statistiques mises à jour pour: $compagnieId');
    } catch (e) {
      debugPrint('[InsuranceService] ❌ Erreur mise à jour statistiques: $e');
    }
  }

  /// 🔄 Initialisation complète du système d'assurance
  static Future<Map<String, dynamic>> initializeInsuranceSystem() async {
    debugPrint('[InsuranceService] 🚀 Initialisation complète du système...');

    final results = {
      'compagnies_created': 0,
      'agences_created': 0,
      'errors': <String>[],
    };

    try {
      // 1. Créer les compagnies principales
      await initializeMainCompanies();
      
      // 2. Créer les agences
      await createAgenciesForCompanies();
      
      // 3. Mettre à jour les statistiques
      final companies = await getAllCompanies();
      for (final company in companies) {
        await updateCompanyStatistics(company.id);
      }

      results['compagnies_created'] = companies.length;
      
      debugPrint('[InsuranceService] 🎉 Système d\'assurance initialisé avec succès');
      
    } catch (e) {
      debugPrint('[InsuranceService] ❌ Erreur initialisation système: $e');
      (results['errors'] as List<String>).add('Erreur générale: $e');
    }

    return results;
  }
}
