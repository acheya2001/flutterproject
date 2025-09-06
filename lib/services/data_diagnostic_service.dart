import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 🔍 Service de diagnostic pour analyser les données existantes
class DataDiagnosticService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📊 Analyser toutes les collections et leurs données
  static Future<Map<String, dynamic>> analyzeAllData() async {
    try {
      debugPrint('[DATA_DIAGNOSTIC] 🔍 Analyse des données...');

      final results = await Future.wait([
        _analyzeCompagnies(),
        _analyzeAgences(),
        _analyzeUsers(),
        _analyzeContrats(),
        _analyzeSinistres(),
      ]);

      final analysis = {
        'compagnies': results[0],
        'agences': results[1],
        'users': results[2],
        'contrats': results[3],
        'sinistres': results[4],
        'timestamp': DateTime.now().toIso8601String(),
      };

      debugPrint('[DATA_DIAGNOSTIC] 📊 Analyse terminée');
      return analysis;

    } catch (e) {
      debugPrint('[DATA_DIAGNOSTIC] ❌ Erreur analyse: $e');
      return {'error': e.toString()};
    }
  }

  /// 🏢 Analyser les compagnies
  static Future<Map<String, dynamic>> _analyzeCompagnies() async {
    try {
      // Vérifier les deux collections possibles
      final compagniesSnapshot = await _firestore.collection('compagnies').get();
      final compagniesAssuranceSnapshot = await _firestore.collection('compagnies_assurance').get();

      final compagniesData = compagniesSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['collection'] = 'compagnies';
        return data;
      }).toList();

      final compagniesAssuranceData = compagniesAssuranceSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['collection'] = 'compagnies_assurance';
        return data;
      }).toList();

      debugPrint('[DATA_DIAGNOSTIC] 🏢 Compagnies: ${compagniesData.length} dans "compagnies", ${compagniesAssuranceData.length} dans "compagnies_assurance"');

      return {
        'compagnies': compagniesData,
        'compagnies_assurance': compagniesAssuranceData,
        'total_compagnies': compagniesData.length,
        'total_compagnies_assurance': compagniesAssuranceData.length,
      };

    } catch (e) {
      debugPrint('[DATA_DIAGNOSTIC] ❌ Erreur compagnies: $e');
      return {'error': e.toString()};
    }
  }

  /// 🏪 Analyser les agences
  static Future<Map<String, dynamic>> _analyzeAgences() async {
    try {
      // Vérifier collection principale
      final agencesSnapshot = await _firestore.collection('agences').get();
      
      final agencesData = agencesSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Grouper par compagnieId
      final agencesByCompany = <String, List<Map<String, dynamic>>>{};
      for (final agence in agencesData) {
        final compagnieId = agence['compagnieId'] as String?;
        if (compagnieId != null) {
          agencesByCompany[compagnieId] ??= [];
          agencesByCompany[compagnieId]!.add(agence);
        }
      }

      debugPrint('[DATA_DIAGNOSTIC] 🏪 Agences: ${agencesData.length} total');
      for (final entry in agencesByCompany.entries) {
        debugPrint('[DATA_DIAGNOSTIC] 🏪 Compagnie ${entry.key}: ${entry.value.length} agences');
      }

      return {
        'agences': agencesData,
        'total_agences': agencesData.length,
        'agences_by_company': agencesByCompany,
      };

    } catch (e) {
      debugPrint('[DATA_DIAGNOSTIC] ❌ Erreur agences: $e');
      return {'error': e.toString()};
    }
  }

  /// 👥 Analyser les utilisateurs
  static Future<Map<String, dynamic>> _analyzeUsers() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      
      final userData = usersSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Grouper par rôle
      final usersByRole = <String, List<Map<String, dynamic>>>{};
      final usersByCompany = <String, List<Map<String, dynamic>>>{};

      for (final user in userData) {
        final role = user['role'] as String?;
        final compagnieId = user['compagnieId'] as String?;

        if (role != null) {
          usersByRole[role] ??= [];
          usersByRole[role]!.add(user);
        }

        if (compagnieId != null) {
          usersByCompany[compagnieId] ??= [];
          usersByCompany[compagnieId]!.add(user);
        }
      }

      debugPrint('[DATA_DIAGNOSTIC] 👥 Utilisateurs: ${userData.length} total');
      for (final entry in usersByRole.entries) {
        debugPrint('[DATA_DIAGNOSTIC] 👥 Rôle ${entry.key}: ${entry.value.length} utilisateurs');
      }

      return {
        'users': userData,
        'total_users': userData.length,
        'users_by_role': usersByRole,
        'users_by_company': usersByCompany,
      };

    } catch (e) {
      debugPrint('[DATA_DIAGNOSTIC] ❌ Erreur utilisateurs: $e');
      return {'error': e.toString()};
    }
  }

  /// 📄 Analyser les contrats
  static Future<Map<String, dynamic>> _analyzeContrats() async {
    try {
      // Vérifier les deux collections possibles
      final contratsSnapshot = await _firestore.collection('contrats').get();
      final contratsAssuranceSnapshot = await _firestore.collection('contrats_assurance').get();

      final contratsData = contratsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['collection'] = 'contrats';
        return data;
      }).toList();

      final contratsAssuranceData = contratsAssuranceSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['collection'] = 'contrats_assurance';
        return data;
      }).toList();

      // Grouper par compagnieId
      final contratsByCompany = <String, List<Map<String, dynamic>>>{};
      for (final contrat in [...contratsData, ...contratsAssuranceData]) {
        final compagnieId = contrat['compagnieId'] as String?;
        if (compagnieId != null) {
          contratsByCompany[compagnieId] ??= [];
          contratsByCompany[compagnieId]!.add(contrat);
        }
      }

      debugPrint('[DATA_DIAGNOSTIC] 📄 Contrats: ${contratsData.length} dans "contrats", ${contratsAssuranceData.length} dans "contrats_assurance"');

      return {
        'contrats': contratsData,
        'contrats_assurance': contratsAssuranceData,
        'total_contrats': contratsData.length,
        'total_contrats_assurance': contratsAssuranceData.length,
        'contrats_by_company': contratsByCompany,
      };

    } catch (e) {
      debugPrint('[DATA_DIAGNOSTIC] ❌ Erreur contrats: $e');
      return {'error': e.toString()};
    }
  }

  /// 🚨 Analyser les sinistres
  static Future<Map<String, dynamic>> _analyzeSinistres() async {
    try {
      final sinistresSnapshot = await _firestore.collection('sinistres').get();
      
      final sinistresData = sinistresSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Grouper par compagnieId
      final sinistresByCompany = <String, List<Map<String, dynamic>>>{};
      for (final sinistre in sinistresData) {
        final compagnieId = sinistre['compagnieId'] as String?;
        if (compagnieId != null) {
          sinistresByCompany[compagnieId] ??= [];
          sinistresByCompany[compagnieId]!.add(sinistre);
        }
      }

      debugPrint('[DATA_DIAGNOSTIC] 🚨 Sinistres: ${sinistresData.length} total');

      return {
        'sinistres': sinistresData,
        'total_sinistres': sinistresData.length,
        'sinistres_by_company': sinistresByCompany,
      };

    } catch (e) {
      debugPrint('[DATA_DIAGNOSTIC] ❌ Erreur sinistres: $e');
      return {'error': e.toString()};
    }
  }

  /// 🔍 Analyser les données pour une compagnie spécifique
  static Future<Map<String, dynamic>> analyzeCompanyData(String compagnieId) async {
    try {
      debugPrint('[DATA_DIAGNOSTIC] 🔍 Analyse pour compagnie: $compagnieId');

      // D'abord, analyser TOUTES les données pour voir ce qui existe
      final globalAnalysis = await analyzeAllData();

      final results = await Future.wait([
        _getCompanyAgences(compagnieId),
        _getCompanyAgents(compagnieId),
        _getCompanyContrats(compagnieId),
        _getCompanySinistres(compagnieId),
      ]);

      // Ajouter une analyse globale pour comparaison
      final result = {
        'compagnieId': compagnieId,
        'agences': results[0],
        'agents': results[1],
        'contrats': results[2],
        'sinistres': results[3],
        'globalAnalysis': globalAnalysis,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Log détaillé pour debug
      debugPrint('[DATA_DIAGNOSTIC] 📊 RÉSULTATS POUR COMPAGNIE $compagnieId:');
      debugPrint('[DATA_DIAGNOSTIC] 🏪 Agences trouvées: ${results[0].length}');
      debugPrint('[DATA_DIAGNOSTIC] 👥 Agents trouvés: ${results[1].length}');
      debugPrint('[DATA_DIAGNOSTIC] 📄 Contrats trouvés: ${results[2].length}');
      debugPrint('[DATA_DIAGNOSTIC] 🚨 Sinistres trouvés: ${results[3].length}');

      debugPrint('[DATA_DIAGNOSTIC] 📊 DONNÉES GLOBALES:');
      debugPrint('[DATA_DIAGNOSTIC] 🏪 Total agences: ${globalAnalysis['agences']?['total_agences'] ?? 0}');
      debugPrint('[DATA_DIAGNOSTIC] 👥 Total users: ${globalAnalysis['users']?['total_users'] ?? 0}');
      debugPrint('[DATA_DIAGNOSTIC] 📄 Total contrats: ${(globalAnalysis['contrats']?['total_contrats'] ?? 0) + (globalAnalysis['contrats']?['total_contrats_assurance'] ?? 0)}');

      return result;

    } catch (e) {
      debugPrint('[DATA_DIAGNOSTIC] ❌ Erreur analyse compagnie: $e');
      return {'error': e.toString()};
    }
  }

  static Future<List<Map<String, dynamic>>> _getCompanyAgences(String compagnieId) async {
    final snapshot = await _firestore
        .collection('agences')
        .where('compagnieId', isEqualTo: compagnieId)
        .get();
    
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> _getCompanyAgents(String compagnieId) async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'agent')
        .where('compagnieId', isEqualTo: compagnieId)
        .get();
    
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> _getCompanyContrats(String compagnieId) async {
    // Vérifier les deux collections
    final contrats1 = await _firestore
        .collection('contrats')
        .where('compagnieId', isEqualTo: compagnieId)
        .get();
    
    final contrats2 = await _firestore
        .collection('contrats_assurance')
        .where('compagnieId', isEqualTo: compagnieId)
        .get();

    final allContrats = <Map<String, dynamic>>[];
    
    for (final doc in contrats1.docs) {
      final data = doc.data();
      data['id'] = doc.id;
      data['collection'] = 'contrats';
      allContrats.add(data);
    }
    
    for (final doc in contrats2.docs) {
      final data = doc.data();
      data['id'] = doc.id;
      data['collection'] = 'contrats_assurance';
      allContrats.add(data);
    }

    return allContrats;
  }

  static Future<List<Map<String, dynamic>>> _getCompanySinistres(String compagnieId) async {
    final snapshot = await _firestore
        .collection('sinistres')
        .where('compagnieId', isEqualTo: compagnieId)
        .get();
    
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// 🔍 Diagnostic spécial pour les données créées via Admin Agence
  static Future<Map<String, dynamic>> analyzeAdminAgenceData() async {
    try {
      debugPrint('[DATA_DIAGNOSTIC] 🔍 Analyse des données Admin Agence...');

      // 1. Chercher tous les agents créés par admin_agence
      final agentsAdminAgence = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('createdBy', isEqualTo: 'admin_agence')
          .get();

      debugPrint('[DATA_DIAGNOSTIC] 👥 Agents créés par admin_agence: ${agentsAdminAgence.docs.length}');

      // 2. Chercher tous les agents avec origin admin_agence_creation
      final agentsOriginAgence = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('origin', isEqualTo: 'admin_agence_creation')
          .get();

      debugPrint('[DATA_DIAGNOSTIC] 👥 Agents avec origin admin_agence_creation: ${agentsOriginAgence.docs.length}');

      // 3. Analyser tous les agents pour voir leurs compagnieId
      final allAgents = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .get();

      final agentsByCompany = <String, List<Map<String, dynamic>>>{};
      final agentsByAgence = <String, List<Map<String, dynamic>>>{};

      for (final doc in allAgents.docs) {
        final data = doc.data();
        data['id'] = doc.id;

        final compagnieId = data['compagnieId'] as String?;
        final agenceId = data['agenceId'] as String?;

        if (compagnieId != null) {
          agentsByCompany[compagnieId] ??= [];
          agentsByCompany[compagnieId]!.add(data);
        }

        if (agenceId != null) {
          agentsByAgence[agenceId] ??= [];
          agentsByAgence[agenceId]!.add(data);
        }

        debugPrint('[DATA_DIAGNOSTIC] 👤 Agent ${data['displayName']}: compagnieId=$compagnieId, agenceId=$agenceId, createdBy=${data['createdBy']}');
      }

      // 4. Analyser toutes les agences
      final allAgences = await _firestore.collection('agences').get();

      debugPrint('[DATA_DIAGNOSTIC] 🏪 Total agences: ${allAgences.docs.length}');

      for (final doc in allAgences.docs) {
        final data = doc.data();
        debugPrint('[DATA_DIAGNOSTIC] 🏪 Agence ${data['nom']}: compagnieId=${data['compagnieId']}, id=${doc.id}');
      }

      // 5. Analyser tous les contrats
      final allContrats = await _firestore.collection('contrats').get();
      final allContratsAssurance = await _firestore.collection('contrats_assurance').get();

      debugPrint('[DATA_DIAGNOSTIC] 📄 Total contrats: ${allContrats.docs.length}');
      debugPrint('[DATA_DIAGNOSTIC] 📄 Total contrats_assurance: ${allContratsAssurance.docs.length}');

      return {
        'agentsAdminAgence': agentsAdminAgence.docs.length,
        'agentsOriginAgence': agentsOriginAgence.docs.length,
        'totalAgents': allAgents.docs.length,
        'agentsByCompany': agentsByCompany,
        'agentsByAgence': agentsByAgence,
        'totalAgences': allAgences.docs.length,
        'totalContrats': allContrats.docs.length,
        'totalContratsAssurance': allContratsAssurance.docs.length,
        'timestamp': DateTime.now().toIso8601String(),
      };

    } catch (e) {
      debugPrint('[DATA_DIAGNOSTIC] ❌ Erreur analyse admin agence: $e');
      return {'error': e.toString()};
    }
  }
}
