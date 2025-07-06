import 'package:cloud_firestore/cloud_firestore.dart';

/// 🏢 Service de gestion de la hiérarchie des assurances tunisiennes
class InsuranceHierarchyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🏢 Compagnies d'assurance tunisiennes
  static const Map<String, Map<String, dynamic>> tunisianInsuranceCompanies = {
    'STAR': {
      'nom': 'STAR Assurances',
      'code': 'STA',
      'logo': 'assets/logos/star.png',
      'couleur': '#1976D2',
      'telephone': '+216 71 123 456',
      'email': 'contact@star.tn',
      'siteWeb': 'www.star.tn',
    },
    'GAT': {
      'nom': 'Générale Arabe Tunisienne d\'Assurances',
      'code': 'GAT',
      'logo': 'assets/logos/gat.png',
      'couleur': '#4CAF50',
      'telephone': '+216 71 234 567',
      'email': 'contact@gat.tn',
      'siteWeb': 'www.gat.tn',
    },
    'BH': {
      'nom': 'BH Assurance',
      'code': 'BHA',
      'logo': 'assets/logos/bh.png',
      'couleur': '#FF9800',
      'telephone': '+216 71 345 678',
      'email': 'contact@bh.tn',
      'siteWeb': 'www.bh.tn',
    },
    'MAGHREBIA': {
      'nom': 'Maghrebia Assurances',
      'code': 'MAG',
      'logo': 'assets/logos/maghrebia.png',
      'couleur': '#9C27B0',
      'telephone': '+216 71 456 789',
      'email': 'contact@maghrebia.tn',
      'siteWeb': 'www.maghrebia.tn',
    },
    'LLOYD': {
      'nom': 'Lloyd Tunisien',
      'code': 'LLO',
      'logo': 'assets/logos/lloyd.png',
      'couleur': '#F44336',
      'telephone': '+216 71 567 890',
      'email': 'contact@lloyd.tn',
      'siteWeb': 'www.lloyd.tn',
    },
  };

  /// 🗺️ Gouvernorats tunisiens
  static const List<String> tunisianGovernorates = [
    'Tunis', 'Ariana', 'Ben Arous', 'Manouba',
    'Nabeul', 'Zaghouan', 'Bizerte',
    'Béja', 'Jendouba', 'Kef', 'Siliana',
    'Sousse', 'Monastir', 'Mahdia', 'Sfax', 'Kairouan', 'Kasserine', 'Sidi Bouzid',
    'Gabès', 'Médenine', 'Tataouine', 'Gafsa', 'Tozeur', 'Kébili'
  ];

  /// 🏢 Initialiser la structure hiérarchique complète
  static Future<void> initializeInsuranceHierarchy() async {
    try {
      print('🏗️ [HIERARCHY] Initialisation de la hiérarchie des assurances...');

      for (final companyEntry in tunisianInsuranceCompanies.entries) {
        final companyCode = companyEntry.key;
        final companyData = companyEntry.value;

        // 1. Créer la compagnie
        await _firestore
            .collection('insurance_companies')
            .doc(companyCode)
            .set({
          ...companyData,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 2. Créer les gouvernorats pour cette compagnie
        for (final gouvernorat in tunisianGovernorates) {
          await _createGouvernoratStructure(companyCode, gouvernorat);
        }
      }

      print('✅ [HIERARCHY] Hiérarchie initialisée avec succès');
    } catch (e) {
      print('❌ [HIERARCHY] Erreur initialisation: $e');
      rethrow;
    }
  }

  /// 🗺️ Créer la structure d'un gouvernorat
  static Future<void> _createGouvernoratStructure(
    String companyCode,
    String gouvernorat,
  ) async {
    try {
      // Créer le document gouvernorat
      final gouvernoratRef = _firestore
          .collection('insurance_companies')
          .doc(companyCode)
          .collection('gouvernorats')
          .doc(gouvernorat);

      await gouvernoratRef.set({
        'nom': gouvernorat,
        'code': gouvernorat.toUpperCase().replaceAll(' ', '_'),
        'compagnie': companyCode,
        'nombreAgences': 0,
        'nombreAgents': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Créer des agences d'exemple pour ce gouvernorat
      await _createSampleAgencies(companyCode, gouvernorat);
    } catch (e) {
      print('❌ [HIERARCHY] Erreur création gouvernorat $gouvernorat: $e');
    }
  }

  /// 🏪 Créer des agences d'exemple
  static Future<void> _createSampleAgencies(
    String companyCode,
    String gouvernorat,
  ) async {
    try {
      final agencesData = _getAgenciesForGouvernorat(gouvernorat);

      for (int i = 0; i < agencesData.length; i++) {
        final agenceData = agencesData[i];
        final agenceId = '${companyCode}_${gouvernorat}_AGE${i + 1}';

        final agenceRef = _firestore
            .collection('insurance_companies')
            .doc(companyCode)
            .collection('gouvernorats')
            .doc(gouvernorat)
            .collection('agences')
            .doc(agenceId);

        await agenceRef.set({
          'nom': agenceData['nom'],
          'code': agenceId,
          'adresse': agenceData['adresse'],
          'ville': gouvernorat,
          'telephone': agenceData['telephone'],
          'email': agenceData['email'],
          'responsable': agenceData['responsable'],
          'compagnie': companyCode,
          'gouvernorat': gouvernorat,
          'nombreAgents': 0,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Créer des agents d'exemple pour cette agence
        await _createSampleAgents(companyCode, gouvernorat, agenceId);
      }
    } catch (e) {
      print('❌ [HIERARCHY] Erreur création agences: $e');
    }
  }

  /// 👨‍💼 Créer des agents d'exemple
  static Future<void> _createSampleAgents(
    String companyCode,
    String gouvernorat,
    String agenceId,
  ) async {
    try {
      final agentsData = [
        {
          'nom': 'Ben Ali',
          'prenom': 'Ahmed',
          'matricule': '${agenceId}_AGT001',
          'telephone': '+216 98 123 456',
          'email': 'ahmed.benali@${companyCode.toLowerCase()}.tn',
        },
        {
          'nom': 'Trabelsi',
          'prenom': 'Fatma',
          'matricule': '${agenceId}_AGT002',
          'telephone': '+216 98 234 567',
          'email': 'fatma.trabelsi@${companyCode.toLowerCase()}.tn',
        },
      ];

      for (final agentData in agentsData) {
        final agentId = agentData['matricule'];

        await _firestore
            .collection('insurance_companies')
            .doc(companyCode)
            .collection('gouvernorats')
            .doc(gouvernorat)
            .collection('agences')
            .doc(agenceId)
            .collection('agents')
            .doc(agentId)
            .set({
          ...agentData,
          'compagnie': companyCode,
          'gouvernorat': gouvernorat,
          'agence': agenceId,
          'status': 'actif',
          'dateEmbauche': FieldValue.serverTimestamp(),
          'specialites': ['Auto', 'Habitation'],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('❌ [HIERARCHY] Erreur création agents: $e');
    }
  }

  /// 🏪 Obtenir les agences pour un gouvernorat
  static List<Map<String, String>> _getAgenciesForGouvernorat(String gouvernorat) {
    switch (gouvernorat) {
      case 'Tunis':
        return [
          {
            'nom': 'Agence Centre Ville',
            'adresse': 'Avenue Habib Bourguiba, Tunis',
            'telephone': '+216 71 123 001',
            'email': 'tunis.centre@example.tn',
            'responsable': 'Mohamed Sassi',
          },
          {
            'nom': 'Agence Bab Bhar',
            'adresse': 'Place Bab Bhar, Tunis',
            'telephone': '+216 71 123 002',
            'email': 'tunis.babbhar@example.tn',
            'responsable': 'Leila Karray',
          },
        ];
      case 'Manouba':
        return [
          {
            'nom': 'Agence Manouba Centre',
            'adresse': 'Avenue de la République, Manouba',
            'telephone': '+216 71 234 001',
            'email': 'manouba.centre@example.tn',
            'responsable': 'Karim Bouaziz',
          },
          {
            'nom': 'Agence Oued Ellil',
            'adresse': 'Route de Bizerte, Oued Ellil',
            'telephone': '+216 71 234 002',
            'email': 'manouba.ouedellil@example.tn',
            'responsable': 'Sonia Gharbi',
          },
        ];
      case 'Ariana':
        return [
          {
            'nom': 'Agence Ariana Ville',
            'adresse': 'Avenue de la Liberté, Ariana',
            'telephone': '+216 71 345 001',
            'email': 'ariana.ville@example.tn',
            'responsable': 'Nabil Jemli',
          },
        ];
      default:
        return [
          {
            'nom': 'Agence $gouvernorat Centre',
            'adresse': 'Centre ville, $gouvernorat',
            'telephone': '+216 71 000 001',
            'email': '${gouvernorat.toLowerCase()}.centre@example.tn',
            'responsable': 'Responsable $gouvernorat',
          },
        ];
    }
  }

  /// 🔍 Obtenir les compagnies
  static Future<List<Map<String, dynamic>>> getCompanies() async {
    try {
      final snapshot = await _firestore.collection('insurance_companies').get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('❌ [HIERARCHY] Erreur récupération compagnies: $e');
      return [];
    }
  }

  /// 🗺️ Obtenir les gouvernorats d'une compagnie
  static Future<List<Map<String, dynamic>>> getGouvernorats(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('insurance_companies')
          .doc(companyId)
          .collection('gouvernorats')
          .get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('❌ [HIERARCHY] Erreur récupération gouvernorats: $e');
      return [];
    }
  }

  /// 🏪 Obtenir les agences d'un gouvernorat
  static Future<List<Map<String, dynamic>>> getAgences(
    String companyId,
    String gouvernoratId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('insurance_companies')
          .doc(companyId)
          .collection('gouvernorats')
          .doc(gouvernoratId)
          .collection('agences')
          .get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('❌ [HIERARCHY] Erreur récupération agences: $e');
      return [];
    }
  }

  /// 👨‍💼 Obtenir les agents d'une agence
  static Future<List<Map<String, dynamic>>> getAgents(
    String companyId,
    String gouvernoratId,
    String agenceId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('insurance_companies')
          .doc(companyId)
          .collection('gouvernorats')
          .doc(gouvernoratId)
          .collection('agences')
          .doc(agenceId)
          .collection('agents')
          .get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('❌ [HIERARCHY] Erreur récupération agents: $e');
      return [];
    }
  }
}
