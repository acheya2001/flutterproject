import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/insurance_structure_model.dart';

/// 🌱 Service pour créer des données de test pour les compagnies et agences
class InsuranceDataSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🚀 Méthode rapide pour créer des données de test dans Firestore
  static Future<void> createTestData() async {
    if (!kDebugMode) {
      throw Exception('Les données de test ne peuvent être créées qu\'en mode debug');
    }

    try {
      print('🌱 Création des données de test...');

      // Créer les compagnies directement dans Firestore
      await _createFirestoreTestCompanies();

      // Créer les agences directement dans Firestore
      await _createFirestoreTestAgencies();

      print('✅ Données de test créées avec succès !');
    } catch (e) {
      print('❌ Erreur création données de test: $e');
      rethrow;
    }
  }

  /// 🏢 Créer les compagnies de test dans Firestore
  static Future<void> _createFirestoreTestCompanies() async {
    final companies = [
      {
        'nom': 'STAR Assurances Test',
        'code': 'STAR',
        'description': 'Compagnie de test STAR',
        'website': 'https://star-assurances.tn',
        'telephone': '+216 71 123 456',
        'email': 'contact@star-test.tn',
        'adresse': 'Avenue Habib Bourguiba, Tunis',
        'ville': 'Tunis',
        'codePostal': '1000',
        'pays': 'Tunisie',
        'status': 'actif',
        'isTestData': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'test_seeder',
      },
      {
        'nom': 'GAT Assurances Test',
        'code': 'GAT',
        'description': 'Compagnie de test GAT',
        'website': 'https://gat-assurances.tn',
        'telephone': '+216 71 234 567',
        'email': 'contact@gat-test.tn',
        'adresse': 'Avenue de la Liberté, Tunis',
        'ville': 'Tunis',
        'codePostal': '1002',
        'pays': 'Tunisie',
        'status': 'actif',
        'isTestData': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'test_seeder',
      },
      {
        'nom': 'COMAR Test',
        'code': 'COMAR',
        'description': 'Compagnie de test COMAR',
        'website': 'https://comar.tn',
        'telephone': '+216 71 345 678',
        'email': 'contact@comar-test.tn',
        'adresse': 'Rue de Marseille, Tunis',
        'ville': 'Tunis',
        'codePostal': '1001',
        'pays': 'Tunisie',
        'status': 'actif',
        'isTestData': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'test_seeder',
      },
    ];

    for (int i = 0; i < companies.length; i++) {
      final companyId = 'test_company_$i';
      await _firestore
          .collection('compagnies_assurance')
          .doc(companyId)
          .set(companies[i]);
      print('✅ Compagnie créée: ${companies[i]['nom']}');
    }
  }

  /// 🏪 Créer les agences de test dans Firestore
  static Future<void> _createFirestoreTestAgencies() async {
    final agencies = [
      {
        'nom': 'STAR Tunis Centre',
        'code': 'STC001',
        'compagnieId': 'test_company_0',
        'compagnieNom': 'STAR Assurances Test',
        'adresse': 'Avenue Habib Bourguiba, Centre Ville',
        'ville': 'Tunis',
        'gouvernorat': 'Tunis',
        'codePostal': '1000',
        'telephone': '+216 71 111 111',
        'email': 'tunis.centre@star-test.tn',
        'responsable': 'Ahmed Ben Ali',
        'status': 'actif',
        'isTestData': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'test_seeder',
      },
      {
        'nom': 'STAR Ariana',
        'code': 'SAR001',
        'compagnieId': 'test_company_0',
        'compagnieNom': 'STAR Assurances Test',
        'adresse': 'Centre Commercial Ariana',
        'ville': 'Ariana',
        'gouvernorat': 'Ariana',
        'codePostal': '2080',
        'telephone': '+216 71 222 222',
        'email': 'ariana@star-test.tn',
        'responsable': 'Fatma Trabelsi',
        'status': 'actif',
        'isTestData': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'test_seeder',
      },
      {
        'nom': 'GAT Tunis Belvédère',
        'code': 'GTB001',
        'compagnieId': 'test_company_1',
        'compagnieNom': 'GAT Assurances Test',
        'adresse': 'Avenue de la Liberté, Belvédère',
        'ville': 'Tunis',
        'gouvernorat': 'Tunis',
        'codePostal': '1002',
        'telephone': '+216 71 333 333',
        'email': 'belvedere@gat-test.tn',
        'responsable': 'Mohamed Gharbi',
        'status': 'actif',
        'isTestData': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'test_seeder',
      },
      {
        'nom': 'COMAR Tunis Lac',
        'code': 'CTL001',
        'compagnieId': 'test_company_2',
        'compagnieNom': 'COMAR Test',
        'adresse': 'Les Berges du Lac, Tunis',
        'ville': 'Tunis',
        'gouvernorat': 'Tunis',
        'codePostal': '1053',
        'telephone': '+216 71 555 555',
        'email': 'lac@comar-test.tn',
        'responsable': 'Sami Bouaziz',
        'status': 'actif',
        'isTestData': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'test_seeder',
      },
    ];

    for (int i = 0; i < agencies.length; i++) {
      final agencyId = 'test_agency_$i';
      await _firestore
          .collection('agences_assurance')
          .doc(agencyId)
          .set(agencies[i]);
      print('✅ Agence créée: ${agencies[i]['nom']}');
    }
  }

  /// 🏢 Créer les compagnies d'assurance tunisiennes
  static Future<void> seedInsuranceCompanies() async {
    try {
      final companies = [
        InsuranceCompany(
          companyId: 'star_assurances',
          name: 'STAR Assurances',
          code: 'STAR',
          description: 'Compagnie d\'assurance leader en Tunisie',
          website: 'https://www.star.com.tn',
          phone: '+216 71 123 456',
          email: 'contact@star.com.tn',
          createdAt: DateTime.now(),
          lastUpdatedAt: DateTime.now(),
        ),
        InsuranceCompany(
          companyId: 'gat_assurances',
          name: 'GAT Assurances',
          code: 'GAT',
          description: 'Groupe des Assurances de Tunisie',
          website: 'https://www.gat.com.tn',
          phone: '+216 71 234 567',
          email: 'contact@gat.com.tn',
          createdAt: DateTime.now(),
          lastUpdatedAt: DateTime.now(),
        ),
        InsuranceCompany(
          companyId: 'comar_assurances',
          name: 'COMAR Assurances',
          code: 'COMAR',
          description: 'Compagnie Méditerranéenne d\'Assurance et de Réassurance',
          website: 'https://www.comar.com.tn',
          phone: '+216 71 345 678',
          email: 'contact@comar.com.tn',
          createdAt: DateTime.now(),
          lastUpdatedAt: DateTime.now(),
        ),
        InsuranceCompany(
          companyId: 'maghrebia_assurances',
          name: 'Maghrebia Assurances',
          code: 'MAGHREBIA',
          description: 'Compagnie d\'assurance vie et non-vie',
          website: 'https://www.maghrebia.com.tn',
          phone: '+216 71 456 789',
          email: 'contact@maghrebia.com.tn',
          createdAt: DateTime.now(),
          lastUpdatedAt: DateTime.now(),
        ),
        InsuranceCompany(
          companyId: 'lloyd_tunisien',
          name: 'Lloyd Tunisien',
          code: 'LLOYD',
          description: 'Compagnie d\'assurance internationale',
          website: 'https://www.lloyd.com.tn',
          phone: '+216 71 567 890',
          email: 'contact@lloyd.com.tn',
          createdAt: DateTime.now(),
          lastUpdatedAt: DateTime.now(),
        ),
      ];

      final batch = _firestore.batch();
      for (final company in companies) {
        final docRef = _firestore.collection('compagnies_assurance').doc(company.companyId);
        batch.set(docRef, company.toMap());
      }
      await batch.commit();

      print('✅ Compagnies d\'assurance créées avec succès');
    } catch (e) {
      print('❌ Erreur lors de la création des compagnies: $e');
    }
  }

  /// 🏪 Créer les agences pour chaque compagnie
  static Future<void> seedInsuranceAgencies() async {
    try {
      final agencies = [
        // STAR Assurances
        InsuranceAgency(
          agencyId: 'star_tunis_centre',
          companyId: 'star_assurances',
          name: 'STAR Tunis Centre',
          code: 'TC001',
          address: 'Avenue Habib Bourguiba',
          city: 'Tunis',
          governorate: 'Tunis',
          postalCode: '1000',
          phone: '+216 71 123 001',
          email: 'tunis.centre@star.com.tn',
          managerName: 'Ahmed Ben Ali',
          createdAt: DateTime.now(),
          lastUpdatedAt: DateTime.now(),
        ),
        InsuranceAgency(
          agencyId: 'star_sfax',
          companyId: 'star_assurances',
          name: 'STAR Sfax',
          code: 'SF001',
          address: 'Avenue Hedi Chaker',
          city: 'Sfax',
          governorate: 'Sfax',
          postalCode: '3000',
          phone: '+216 74 123 001',
          email: 'sfax@star.com.tn',
          managerName: 'Fatma Trabelsi',
          createdAt: DateTime.now(),
          lastUpdatedAt: DateTime.now(),
        ),
        InsuranceAgency(
          agencyId: 'star_sousse',
          companyId: 'star_assurances',
          name: 'STAR Sousse',
          code: 'SS001',
          address: 'Avenue Léopold Sédar Senghor',
          city: 'Sousse',
          governorate: 'Sousse',
          postalCode: '4000',
          phone: '+216 73 123 001',
          email: 'sousse@star.com.tn',
          managerName: 'Mohamed Gharbi',
          createdAt: DateTime.now(),
          lastUpdatedAt: DateTime.now(),
        ),

        // GAT Assurances
        InsuranceAgency(
          agencyId: 'gat_tunis_lac',
          companyId: 'gat_assurances',
          name: 'GAT Tunis Lac',
          code: 'TL001',
          address: 'Les Berges du Lac',
          city: 'Tunis',
          governorate: 'Tunis',
          postalCode: '1053',
          phone: '+216 71 234 001',
          email: 'tunis.lac@gat.com.tn',
          managerName: 'Leila Mansouri',
          createdAt: DateTime.now(),
          lastUpdatedAt: DateTime.now(),
        ),
        InsuranceAgency(
          agencyId: 'gat_ariana',
          companyId: 'gat_assurances',
          name: 'GAT Ariana',
          code: 'AR001',
          address: 'Centre Ville Ariana',
          city: 'Ariana',
          governorate: 'Ariana',
          postalCode: '2080',
          phone: '+216 71 234 002',
          email: 'ariana@gat.com.tn',
          managerName: 'Karim Bouazizi',
          createdAt: DateTime.now(),
          lastUpdatedAt: DateTime.now(),
        ),

        // COMAR Assurances
        InsuranceAgency(
          agencyId: 'comar_manouba',
          companyId: 'comar_assurances',
          name: 'COMAR Manouba',
          code: 'MN001',
          address: 'Avenue de la République',
          city: 'Manouba',
          governorate: 'Manouba',
          postalCode: '2010',
          phone: '+216 71 345 001',
          email: 'manouba@comar.com.tn',
          managerName: 'Sonia Khelifi',
          createdAt: DateTime.now(),
          lastUpdatedAt: DateTime.now(),
        ),
        InsuranceAgency(
          agencyId: 'comar_bizerte',
          companyId: 'comar_assurances',
          name: 'COMAR Bizerte',
          code: 'BZ001',
          address: 'Avenue Habib Bourguiba',
          city: 'Bizerte',
          governorate: 'Bizerte',
          postalCode: '7000',
          phone: '+216 72 345 001',
          email: 'bizerte@comar.com.tn',
          managerName: 'Nabil Jemli',
          createdAt: DateTime.now(),
          lastUpdatedAt: DateTime.now(),
        ),

        // Maghrebia Assurances
        InsuranceAgency(
          agencyId: 'maghrebia_nabeul',
          companyId: 'maghrebia_assurances',
          name: 'Maghrebia Nabeul',
          code: 'NB001',
          address: 'Avenue Taïeb Mehiri',
          city: 'Nabeul',
          governorate: 'Nabeul',
          postalCode: '8000',
          phone: '+216 72 456 001',
          email: 'nabeul@maghrebia.com.tn',
          managerName: 'Rim Sassi',
          createdAt: DateTime.now(),
          lastUpdatedAt: DateTime.now(),
        ),

        // Lloyd Tunisien
        InsuranceAgency(
          agencyId: 'lloyd_monastir',
          companyId: 'lloyd_tunisien',
          name: 'Lloyd Monastir',
          code: 'MS001',
          address: 'Avenue de l\'Indépendance',
          city: 'Monastir',
          governorate: 'Monastir',
          postalCode: '5000',
          phone: '+216 73 567 001',
          email: 'monastir@lloyd.com.tn',
          managerName: 'Youssef Hamdi',
          createdAt: DateTime.now(),
          lastUpdatedAt: DateTime.now(),
        ),
      ];

      final batch = _firestore.batch();
      for (final agency in agencies) {
        final docRef = _firestore.collection('agences_assurance').doc(agency.agencyId);
        batch.set(docRef, agency.toMap());
      }
      await batch.commit();

      print('✅ Agences d\'assurance créées avec succès');
    } catch (e) {
      print('❌ Erreur lors de la création des agences: $e');
    }
  }

  /// 👨‍💼 Créer des agents de test
  static Future<void> seedInsuranceAgents() async {
    try {
      final agents = [
        InsuranceAgent(
          agentId: 'agent_star_tc_001',
          agencyId: 'star_tunis_centre',
          companyId: 'star_assurances',
          firstName: 'Ahmed',
          lastName: 'Ben Ali',
          email: 'ahmed.benali@star.com.tn',
          phone: '+216 98 123 001',
          employeeId: 'STAR001',
          role: 'manager',
          createdAt: DateTime.now(),
          lastUpdatedAt: DateTime.now(),
        ),
        InsuranceAgent(
          agentId: 'agent_star_sf_001',
          agencyId: 'star_sfax',
          companyId: 'star_assurances',
          firstName: 'Fatma',
          lastName: 'Trabelsi',
          email: 'fatma.trabelsi@star.com.tn',
          phone: '+216 98 123 002',
          employeeId: 'STAR002',
          role: 'manager',
          createdAt: DateTime.now(),
          lastUpdatedAt: DateTime.now(),
        ),
        InsuranceAgent(
          agentId: 'agent_gat_tl_001',
          agencyId: 'gat_tunis_lac',
          companyId: 'gat_assurances',
          firstName: 'Leila',
          lastName: 'Mansouri',
          email: 'leila.mansouri@gat.com.tn',
          phone: '+216 98 234 001',
          employeeId: 'GAT001',
          role: 'manager',
          createdAt: DateTime.now(),
          lastUpdatedAt: DateTime.now(),
        ),
      ];

      final batch = _firestore.batch();
      for (final agent in agents) {
        final docRef = _firestore.collection('agents_assurance').doc(agent.agentId);
        batch.set(docRef, agent.toMap());
      }
      await batch.commit();

      print('✅ Agents d\'assurance créés avec succès');
    } catch (e) {
      print('❌ Erreur lors de la création des agents: $e');
    }
  }

  /// 🌱 Initialiser toutes les données de test
  static Future<void> seedAllInsuranceData() async {
    print('🌱 Initialisation des données d\'assurance...');
    
    await seedInsuranceCompanies();
    await Future.delayed(const Duration(seconds: 1));
    
    await seedInsuranceAgencies();
    await Future.delayed(const Duration(seconds: 1));
    
    await seedInsuranceAgents();
    
    print('🎉 Toutes les données d\'assurance ont été créées avec succès !');
  }

  /// 🧹 Nettoyer toutes les données de test
  static Future<void> cleanAllInsuranceData() async {
    try {
      print('🧹 Nettoyage des données d\'assurance...');

      // Supprimer les agents
      final agentsSnapshot = await _firestore.collection('agents_assurance').get();
      for (final doc in agentsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Supprimer les agences
      final agenciesSnapshot = await _firestore.collection('agences_assurance').get();
      for (final doc in agenciesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Supprimer les compagnies
      final companiesSnapshot = await _firestore.collection('compagnies_assurance').get();
      for (final doc in companiesSnapshot.docs) {
        await doc.reference.delete();
      }

      print('✅ Données d\'assurance nettoyées avec succès');
    } catch (e) {
      print('❌ Erreur lors du nettoyage: $e');
    }
  }
}
