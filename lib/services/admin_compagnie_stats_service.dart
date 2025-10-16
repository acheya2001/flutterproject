import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// 📊 Service de statistiques spécifique pour Admin Compagnie
/// Filtre toutes les données selon la compagnie de l'admin connecté
class AdminCompagnieStatsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📊 Récupérer les statistiques complètes de la compagnie de l'admin
  static Future<Map<String, dynamic>> getMyCompagnieStatistics(String compagnieId, [Map<String, dynamic>? userData]) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_STATS] 📊 Récupération stats pour compagnie: $compagnieId');

      // Si compagnieId est vide, essayer de le détecter depuis userData ou automatiquement
      String actualCompagnieId = compagnieId;
      if (compagnieId.isEmpty) {
        if (userData != null) {
          actualCompagnieId = userData['compagnieId'] ?? userData['adminCompagnieId'] ?? '';
          debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 CompagnieId depuis userData: $actualCompagnieId');
        }

        if (actualCompagnieId.isEmpty) {
          actualCompagnieId = await _detectCompagnieId();
          debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 CompagnieId détecté automatiquement: $actualCompagnieId');
        }
      }

      final results = await Future.wait([
        _getCompagnieOverview(actualCompagnieId),
        _getAgencesStats(actualCompagnieId),
        _getFinancialStats(actualCompagnieId),
        _getAgentsStats(actualCompagnieId),
        _getContractsStats(actualCompagnieId),
      ]);

      final statistics = {
        'overview': results[0],
        'agences': results[1],
        'financial': results[2],
        'agents': results[3],
        'contracts': results[4],
        'detectedCompagnieId': actualCompagnieId,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      debugPrint('[ADMIN_COMPAGNIE_STATS] ✅ Statistiques récupérées avec succès');
      return statistics;

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_STATS] ❌ Erreur récupération statistiques: $e');
      return _getEmptyStatistics();
    }
  }

  /// 🔍 Détecter automatiquement le compagnieId basé sur les données existantes
  static Future<String> _detectCompagnieId() async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 Détection automatique du compagnieId...');

      // 1. Chercher les agences avec le plus de données
      final agencesSnapshot = await _firestore.collection('agences').get();
      final compagnieStats = <String, int>{};

      for (final doc in agencesSnapshot.docs) {
        final data = doc.data();
        final compagnieId = data['compagnieId'] as String?;
        if (compagnieId != null && compagnieId.isNotEmpty) {
          compagnieStats[compagnieId] = (compagnieStats[compagnieId] ?? 0) + 1;
        }
      }

      // 2. Chercher les agents pour confirmer
      final agentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .get();

      for (final doc in agentsSnapshot.docs) {
        final data = doc.data();
        final compagnieId = data['compagnieId'] as String?;
        if (compagnieId != null && compagnieId.isNotEmpty) {
          compagnieStats[compagnieId] = (compagnieStats[compagnieId] ?? 0) + 1;
        }
      }

      // 3. Prendre le compagnieId avec le plus de données
      if (compagnieStats.isNotEmpty) {
        final bestCompagnieId = compagnieStats.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;

        debugPrint('[ADMIN_COMPAGNIE_STATS] 🎯 CompagnieId détecté: $bestCompagnieId (${compagnieStats[bestCompagnieId]} éléments)');
        return bestCompagnieId;
      }

      debugPrint('[ADMIN_COMPAGNIE_STATS] ⚠️ Aucun compagnieId détecté');
      return '';

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_STATS] ❌ Erreur détection compagnieId: $e');
      return '';
    }
  }

  /// 🏢 Vue d'ensemble de la compagnie
  static Future<Map<String, dynamic>> _getCompagnieOverview(String compagnieId) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 Overview pour compagnie: $compagnieId');
      debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 CompagnieId type: ${compagnieId.runtimeType}');
      debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 CompagnieId isEmpty: ${compagnieId.isEmpty}');

      // Récupérer les données de la compagnie (essayer les deux collections)
      Map<String, dynamic> compagnieData = {};

      // Essayer d'abord 'compagnies_assurance'
      var compagnieDoc = await _firestore.collection('compagnies_assurance').doc(compagnieId).get();
      if (compagnieDoc.exists) {
        compagnieData = compagnieDoc.data()!;
        debugPrint('[ADMIN_COMPAGNIE_STATS] ✅ Compagnie trouvée dans "compagnies_assurance"');
      } else {
        // Essayer 'compagnies'
        compagnieDoc = await _firestore.collection('compagnies').doc(compagnieId).get();
        if (compagnieDoc.exists) {
          compagnieData = compagnieDoc.data()!;
          debugPrint('[ADMIN_COMPAGNIE_STATS] ✅ Compagnie trouvée dans "compagnies"');
        } else {
          debugPrint('[ADMIN_COMPAGNIE_STATS] ⚠️ Compagnie non trouvée dans aucune collection');
        }
      }

      // Compter les agences (essayer plusieurs stratégies)
      var agencesSnapshot = await _firestore
          .collection('agences')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      if (agencesSnapshot.docs.isEmpty) {
        // Essayer avec la sous-collection
        agencesSnapshot = await _firestore
            .collection('compagnies_assurance')
            .doc(compagnieId)
            .collection('agences')
            .get();
        debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 Agences via sous-collection: ${agencesSnapshot.docs.length}');
      } else {
        debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 Agences via collection principale: ${agencesSnapshot.docs.length}');
      }

      // Compter les agents
      final agentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 Agents trouvés: ${agentsSnapshot.docs.length}');

      // Compter les contrats
      final contratsSnapshot = await _firestore
          .collection('contrats')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 Contrats trouvés: ${contratsSnapshot.docs.length}');

      // Compter les sinistres (essayer plusieurs collections)
      var sinistresSnapshot = await _firestore
          .collection('sinistres')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 Sinistres dans collection "sinistres": ${sinistresSnapshot.docs.length}');

      // Si aucun sinistre trouvé, essayer avec constats
      if (sinistresSnapshot.docs.isEmpty) {
        sinistresSnapshot = await _firestore
            .collection('constats')
            .where('compagnieId', isEqualTo: compagnieId)
            .get();
        debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 Sinistres dans collection "constats": ${sinistresSnapshot.docs.length}');
      }

      // Debug: Afficher quelques documents pour vérifier la structure
      if (sinistresSnapshot.docs.isNotEmpty) {
        final firstDoc = sinistresSnapshot.docs.first.data() as Map<String, dynamic>;
        debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 Premier sinistre structure: ${firstDoc.keys.toList()}');
        debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 Premier sinistre compagnieId: ${firstDoc['compagnieId']}');
      }

      debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 Total sinistres trouvés: ${sinistresSnapshot.docs.length}');

      final result = {
        'compagnieData': compagnieData,
        'totalAgences': agencesSnapshot.docs.length,
        'totalAgents': agentsSnapshot.docs.length,
        'totalContrats': contratsSnapshot.docs.length,
        'totalSinistres': sinistresSnapshot.docs.length,
      };

      debugPrint('[ADMIN_COMPAGNIE_STATS] 📊 Résultat overview: $result');
      return result;

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_STATS] ❌ Erreur overview: $e');
      return {
        'compagnieData': {},
        'totalAgences': 0,
        'totalAgents': 0,
        'totalContrats': 0,
        'totalSinistres': 0,
      };
    }
  }

  /// 🏢 Statistiques détaillées des agences
  static Future<List<Map<String, dynamic>>> _getAgencesStats(String compagnieId) async {
    try {
      final agencesSnapshot = await _firestore
          .collection('agences')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      List<Map<String, dynamic>> agencesStats = [];

      for (var agenceDoc in agencesSnapshot.docs) {
        final agenceData = agenceDoc.data();
        final agenceId = agenceDoc.id;

        debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 Agence $agenceId données: ${agenceData.keys.toList()}');

        // Compter les agents de cette agence
        final agentsSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'agent')
            .where('agenceId', isEqualTo: agenceId)
            .get();

        // Compter les contrats de cette agence
        final contratsSnapshot = await _firestore
            .collection('contrats')
            .where('agenceId', isEqualTo: agenceId)
            .get();

        // Calculer les primes totales
        double totalPrimes = 0;
        int contratsActifs = 0;
        for (var contratDoc in contratsSnapshot.docs) {
          final contratData = contratDoc.data();
          final prime = (contratData['primeAnnuelle'] ?? contratData['primeAssurance'] ?? 0).toDouble();
          totalPrimes += prime;
          
          final statut = contratData['statut']?.toString().toLowerCase() ?? '';
          if (statut == 'actif') contratsActifs++;
        }

        // Vérifier s'il y a un admin agence
        final adminAgenceSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'admin_agence')
            .where('agenceId', isEqualTo: agenceId)
            .where('isActive', isEqualTo: true)
            .get();

        // Essayer plusieurs champs pour la ville
        final ville = agenceData['ville'] ??
                     agenceData['city'] ??
                     agenceData['gouvernorat'] ??
                     agenceData['region'] ??
                     agenceData['localisation'] ??
                     'Ville non définie';

        agencesStats.add({
          'id': agenceId,
          'nom': agenceData['nom'] ?? 'Agence inconnue',
          'ville': ville,
          'adresse': agenceData['adresse'] ?? '',
          'telephone': agenceData['telephone'] ?? '',
          'email': agenceData['email'] ?? '',
          'totalAgents': agentsSnapshot.docs.length,
          'totalContrats': contratsSnapshot.docs.length,
          'contratsActifs': contratsActifs,
          'totalPrimes': totalPrimes,
          'hasAdminAgence': adminAgenceSnapshot.docs.isNotEmpty,
          'adminAgenceNom': adminAgenceSnapshot.docs.isNotEmpty
              ? '${adminAgenceSnapshot.docs.first.data()['prenom']} ${adminAgenceSnapshot.docs.first.data()['nom']}'
              : null,
          'performanceScore': _calculateAgencePerformanceScore(
            contratsSnapshot.docs.length,
            contratsActifs,
            agentsSnapshot.docs.length,
          ),
        });

        debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 Agence ${agenceData['nom']}: ville="$ville", contrats=${contratsSnapshot.docs.length}, agents=${agentsSnapshot.docs.length}');
      }

      // Trier par performance
      agencesStats.sort((a, b) => (b['performanceScore'] as double).compareTo(a['performanceScore'] as double));

      return agencesStats;

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_STATS] ❌ Erreur agences stats: $e');
      return [];
    }
  }

  /// 💰 Statistiques financières
  static Future<Map<String, dynamic>> _getFinancialStats(String compagnieId) async {
    try {
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 1);
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      final thisYear = DateTime(now.year, 1, 1);

      final contratsSnapshot = await _firestore
          .collection('contrats')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      double totalPrimes = 0;
      double primesThisMonth = 0;
      double primesLastMonth = 0;
      double primesThisYear = 0;

      for (var doc in contratsSnapshot.docs) {
        final data = doc.data();
        final prime = (data['primeAnnuelle'] ?? data['primeAssurance'] ?? 0).toDouble();
        final dateCreation = (data['createdAt'] as Timestamp?)?.toDate() ?? 
                           (data['dateDebut'] as Timestamp?)?.toDate();

        totalPrimes += prime;

        if (dateCreation != null) {
          if (dateCreation.isAfter(thisYear)) {
            primesThisYear += prime;
          }
          if (dateCreation.isAfter(thisMonth)) {
            primesThisMonth += prime;
          }
          if (dateCreation.isAfter(lastMonth) && dateCreation.isBefore(thisMonth)) {
            primesLastMonth += prime;
          }
        }
      }

      double financialGrowthRate = 0;
      if (primesLastMonth > 0) {
        financialGrowthRate = ((primesThisMonth - primesLastMonth) / primesLastMonth) * 100;
      }

      return {
        'totalPrimes': totalPrimes,
        'primesThisMonth': primesThisMonth,
        'primesLastMonth': primesLastMonth,
        'primesThisYear': primesThisYear,
        'financialGrowthRate': financialGrowthRate,
        'averagePrime': contratsSnapshot.docs.isNotEmpty ? totalPrimes / contratsSnapshot.docs.length : 0,
      };

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_STATS] ❌ Erreur financial stats: $e');
      return {
        'totalPrimes': 0,
        'primesThisMonth': 0,
        'primesLastMonth': 0,
        'primesThisYear': 0,
        'financialGrowthRate': 0,
        'averagePrime': 0,
      };
    }
  }

  /// 👥 Statistiques des agents
  static Future<Map<String, dynamic>> _getAgentsStats(String compagnieId) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 Recherche agents pour compagnie: $compagnieId');

      // Rechercher les agents avec différentes stratégies
      var agentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 Agents trouvés avec compagnieId: ${agentsSnapshot.docs.length}');

      // Si aucun agent trouvé, essayer sans compagnieId pour voir tous les agents
      if (agentsSnapshot.docs.isEmpty) {
        final allAgentsSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'agent')
            .get();

        debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 Total agents dans la base: ${allAgentsSnapshot.docs.length}');

        // Afficher les compagnieId des agents existants
        for (final doc in allAgentsSnapshot.docs) {
          final data = doc.data();
          debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 Agent ${data['displayName']}: compagnieId=${data['compagnieId']}');
        }
      }

      int totalAgents = agentsSnapshot.docs.length;
      int activeAgents = 0;
      List<Map<String, dynamic>> agentPerformance = [];

      for (var agentDoc in agentsSnapshot.docs) {
        final agentData = agentDoc.data();
        final agentId = agentDoc.id;
        final isActive = agentData['isActive'] ?? false;

        if (isActive) activeAgents++;

        // Compter les contrats de cet agent (vérifier les deux collections)
        var agentContracts = await _firestore
            .collection('contrats')
            .where('agentId', isEqualTo: agentId)
            .get();

        // Si aucun contrat trouvé, essayer l'autre collection
        if (agentContracts.docs.isEmpty) {
          agentContracts = await _firestore
              .collection('contrats_assurance')
              .where('agentId', isEqualTo: agentId)
              .get();
        }

        agentPerformance.add({
          'agentId': agentId,
          'nom': '${agentData['prenom']} ${agentData['nom']}',
          'agenceId': agentData['agenceId'] ?? '',
          'agenceNom': agentData['agenceNom'] ?? 'Agence inconnue',
          'contractsCount': agentContracts.docs.length,
          'isActive': isActive,
        });
      }

      // Trier par performance
      agentPerformance.sort((a, b) => (b['contractsCount'] as int).compareTo(a['contractsCount'] as int));

      debugPrint('[ADMIN_COMPAGNIE_STATS] 📊 Agents stats: total=$totalAgents, actifs=$activeAgents');

      return {
        'totalAgents': totalAgents,
        'activeAgents': activeAgents,
        'inactiveAgents': totalAgents - activeAgents,
        'topPerformers': agentPerformance.take(5).toList(),
        'allAgents': agentPerformance,
      };

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_STATS] ❌ Erreur agents stats: $e');
      return {
        'totalAgents': 0,
        'activeAgents': 0,
        'inactiveAgents': 0,
        'topPerformers': [],
        'allAgents': [],
      };
    }
  }

  /// 📄 Statistiques des contrats
  static Future<Map<String, dynamic>> _getContractsStats(String compagnieId) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 Recherche contrats pour compagnie: $compagnieId');

      // Rechercher dans les deux collections possibles
      var contratsSnapshot = await _firestore
          .collection('contrats')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 Contrats trouvés dans "contrats": ${contratsSnapshot.docs.length}');

      // Si aucun contrat trouvé, essayer l'autre collection
      if (contratsSnapshot.docs.isEmpty) {
        contratsSnapshot = await _firestore
            .collection('contrats_assurance')
            .where('compagnieId', isEqualTo: compagnieId)
            .get();

        debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 Contrats trouvés dans "contrats_assurance": ${contratsSnapshot.docs.length}');
      }

      // Si toujours aucun contrat, vérifier tous les contrats pour debug
      if (contratsSnapshot.docs.isEmpty) {
        final allContratsSnapshot = await _firestore.collection('contrats').get();
        debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 Total contrats dans "contrats": ${allContratsSnapshot.docs.length}');

        for (final doc in allContratsSnapshot.docs.take(5)) {
          final data = doc.data();
          debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 Contrat ${doc.id}: compagnieId=${data['compagnieId']}');
        }

        // Essayer de trouver des contrats avec d'autres critères
        final contratsWithoutCompagnieId = await _firestore
            .collection('contrats')
            .where('agentId', isNotEqualTo: '')
            .get();

        debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 Contrats avec agentId: ${contratsWithoutCompagnieId.docs.length}');

        // Vérifier si les agents de cette compagnie ont des contrats
        final agentsSnapshot = await _firestore
            .collection('users')
            .where('role', whereIn: ['agent', 'agent_agence', 'agent_assurance'])
            .where('compagnieId', isEqualTo: compagnieId)
            .get();

        debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 Agents de la compagnie: ${agentsSnapshot.docs.length}');

        // Chercher les contrats par agentId
        for (final agentDoc in agentsSnapshot.docs) {
          final agentContracts = await _firestore
              .collection('contrats')
              .where('agentId', isEqualTo: agentDoc.id)
              .get();

          if (agentContracts.docs.isNotEmpty) {
            debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 Agent ${agentDoc.id} a ${agentContracts.docs.length} contrats');
            // Ajouter ces contrats à notre snapshot
            contratsSnapshot = agentContracts;
            break;
          }
        }
      }

      int total = contratsSnapshot.docs.length;
      int actifs = 0;
      int expires = 0;
      int suspendus = 0;
      int expiringThisMonth = 0;

      final now = DateTime.now();
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 Analyse de ${contratsSnapshot.docs.length} contrats...');

      for (var doc in contratsSnapshot.docs) {
        final data = doc.data();
        final statut = data['statut']?.toString().toLowerCase() ?? '';
        final status = data['status']?.toString().toLowerCase() ?? '';
        final dateFin = (data['dateFin'] as Timestamp?)?.toDate();
        final dateExpiration = (data['dateExpiration'] as Timestamp?)?.toDate();
        final dateFinEffective = dateFin ?? dateExpiration;

        debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 Contrat ${doc.id}: statut="$statut", status="$status", dateFin=$dateFin, dateExpiration=$dateExpiration');

        // Logique améliorée pour déterminer le statut
        String statutEffectif = statut.isNotEmpty ? statut : status;

        // Si aucun statut défini, considérer comme actif si pas expiré
        if (statutEffectif.isEmpty) {
          if (dateFinEffective != null && dateFinEffective.isBefore(now)) {
            statutEffectif = 'expiré';
          } else {
            statutEffectif = 'actif'; // Par défaut, considérer comme actif
          }
        }

        debugPrint('[ADMIN_COMPAGNIE_STATS] 🔍 Contrat ${doc.id}: statutEffectif="$statutEffectif", dateFinEffective=$dateFinEffective');

        switch (statutEffectif) {
          case 'actif':
          case 'active':
          case 'en_cours':
          case 'valide':
            actifs++;
            debugPrint('[ADMIN_COMPAGNIE_STATS] ✅ Contrat ${doc.id}: ACTIF (statut: "$statutEffectif")');
            if (dateFinEffective != null && dateFinEffective.isBefore(endOfMonth) && dateFinEffective.isAfter(now)) {
              expiringThisMonth++;
            }
            break;
          case 'expiré':
          case 'expire':
          case 'expired':
          case 'terminé':
            expires++;
            debugPrint('[ADMIN_COMPAGNIE_STATS] ❌ Contrat ${doc.id}: EXPIRÉ (statut: "$statutEffectif")');
            break;
          case 'suspendu':
          case 'inactif':
          case 'suspended':
          case 'annulé':
            suspendus++;
            debugPrint('[ADMIN_COMPAGNIE_STATS] ⏸️ Contrat ${doc.id}: SUSPENDU (statut: "$statutEffectif")');
            break;
          default:
            // Si statut inconnu mais pas expiré, considérer comme actif
            if (dateFinEffective == null || dateFinEffective.isAfter(now)) {
              actifs++;
              debugPrint('[ADMIN_COMPAGNIE_STATS] ✅ Contrat ${doc.id}: statut inconnu "$statutEffectif" -> considéré ACTIF');
            } else {
              expires++;
              debugPrint('[ADMIN_COMPAGNIE_STATS] ❌ Contrat ${doc.id}: statut inconnu "$statutEffectif" mais expiré -> considéré EXPIRÉ');
            }
            break;
        }
      }

      double growthRate = total > 0 ? (actifs / total * 100) - 85 : 0;

      debugPrint('[ADMIN_COMPAGNIE_STATS] 📊 Contrats stats: total=$total, actifs=$actifs, expires=$expires, suspendus=$suspendus');

      final contractsResult = {
        'total': total,
        'actifs': actifs,
        'expires': expires,
        'suspendus': suspendus,
        'expiringThisMonth': expiringThisMonth,
        'growthRate': growthRate,
        'activePercentage': total > 0 ? (actifs / total * 100) : 0,
      };

      debugPrint('[ADMIN_COMPAGNIE_STATS] 📊 Contrats result: $contractsResult');

      return contractsResult;

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_STATS] ❌ Erreur contracts stats: $e');
      return {
        'total': 0,
        'actifs': 0,
        'expires': 0,
        'suspendus': 0,
        'expiringThisMonth': 0,
        'growthRate': 0,
        'activePercentage': 0,
      };
    }
  }

  /// 📊 Calculer le score de performance d'une agence
  static double _calculateAgencePerformanceScore(int totalContrats, int contratsActifs, int totalAgents) {
    if (totalAgents == 0) return 0;

    double contratsPerAgent = totalContrats / totalAgents;
    double activeRate = totalContrats > 0 ? (contratsActifs / totalContrats) : 0;

    return (contratsPerAgent * 0.6) + (activeRate * 40);
  }

  /// 📊 Statistiques vides par défaut
  static Map<String, dynamic> _getEmptyStatistics() {
    return {
      'overview': {
        'compagnieData': {},
        'totalAgences': 0,
        'totalAgents': 0,
        'totalContrats': 0,
        'totalSinistres': 0,
      },
      'agences': [],
      'financial': {
        'totalPrimes': 0,
        'primesThisMonth': 0,
        'primesLastMonth': 0,
        'primesThisYear': 0,
        'financialGrowthRate': 0,
        'averagePrime': 0,
      },
      'agents': {
        'totalAgents': 0,
        'activeAgents': 0,
        'inactiveAgents': 0,
        'topPerformers': [],
        'allAgents': [],
      },
      'contracts': {
        'total': 0,
        'actifs': 0,
        'expires': 0,
        'suspendus': 0,
        'expiringThisMonth': 0,
        'growthRate': 0,
        'activePercentage': 0,
      },
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }
}
