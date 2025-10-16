import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 📊 Service d'analytiques avancées pour Super Admin
class SuperAdminAnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📈 Obtenir les statistiques globales détaillées
  static Future<Map<String, dynamic>> getDetailedGlobalStats() async {
    try {
      debugPrint('[SUPER_ADMIN_ANALYTICS] 📊 Calcul statistiques détaillées...');

      // Récupérer toutes les données
      final compagniesSnapshot = await _firestore.collection('compagnies').get();
      final agencesSnapshot = await _firestore.collection('agences').get();
      final usersSnapshot = await _firestore.collection('users').get();
      final sinistresSnapshot = await _firestore.collection('sinistres').get();
      final contratsSnapshot = await _firestore.collection('contrats').get();

      // Analyser les compagnies
      final compagniesStats = _analyzeCompagnies(compagniesSnapshot.docs);
      
      // Analyser les utilisateurs
      final usersStats = _analyzeUsers(usersSnapshot.docs);
      
      // Analyser les sinistres
      final sinistresStats = _analyzeSinistres(sinistresSnapshot.docs);
      
      // Analyser les contrats
      final contratsStats = _analyzeContrats(contratsSnapshot.docs);
      
      // Analyser les agences
      final agencesStats = _analyzeAgences(agencesSnapshot.docs);

      // Calculer les tendances (croissance)
      final tendances = await _calculateTendances();

      return {
        'compagnies': compagniesStats,
        'utilisateurs': usersStats,
        'sinistres': sinistresStats,
        'contrats': contratsStats,
        'agences': agencesStats,
        'tendances': tendances,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

    } catch (e) {
      debugPrint('[SUPER_ADMIN_ANALYTICS] ❌ Erreur: $e');
      return {};
    }
  }

  /// 🏢 Analyser les compagnies
  static Map<String, dynamic> _analyzeCompagnies(List<QueryDocumentSnapshot> docs) {
    int total = docs.length;
    int actives = docs.where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'active').length;
    int inactives = total - actives;

    // Compagnies par taille (nombre d'agences)
    Map<String, int> parTaille = {'petite': 0, 'moyenne': 0, 'grande': 0};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final nombreAgences = data['nombreAgences'] ?? 0;

      if (nombreAgences <= 2) {
        parTaille['petite'] = parTaille['petite']! + 1;
      } else if (nombreAgences <= 10) {
        parTaille['moyenne'] = parTaille['moyenne']! + 1;
      } else {
        parTaille['grande'] = parTaille['grande']! + 1;
      }
    }

    return {
      'total': total,
      'actives': actives,
      'inactives': inactives,
      'pourcentageActives': total > 0 ? (actives / total * 100).round() : 0,
      'repartitionParTaille': parTaille,
    };
  }

  /// 👥 Analyser les utilisateurs
  static Map<String, dynamic> _analyzeUsers(List<QueryDocumentSnapshot> docs) {
    Map<String, int> parRole = {};
    Map<String, int> parStatut = {'actif': 0, 'inactif': 0, 'suspendu': 0};
    
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final role = data['role'] ?? 'inconnu';
      final isActive = data['isActive'] == true || data['status'] == 'actif';
      final isSuspended = data['status'] == 'suspendu';
      
      // Compter par rôle
      parRole[role] = (parRole[role] ?? 0) + 1;
      
      // Compter par statut
      if (isSuspended) {
        parStatut['suspendu'] = parStatut['suspendu']! + 1;
      } else if (isActive) {
        parStatut['actif'] = parStatut['actif']! + 1;
      } else {
        parStatut['inactif'] = parStatut['inactif']! + 1;
      }
    }

    return {
      'total': docs.length,
      'repartitionParRole': parRole,
      'repartitionParStatut': parStatut,
      'tauxActivation': docs.isNotEmpty ? (parStatut['actif']! / docs.length * 100).round() : 0,
    };
  }

  /// 🚗 Analyser les sinistres
  static Map<String, dynamic> _analyzeSinistres(List<QueryDocumentSnapshot> docs) {
    Map<String, int> parStatut = {};
    Map<String, int> parMois = {};
    double montantTotal = 0;
    
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final statut = data['status'] ?? 'inconnu';
      final montant = (data['montantEstime'] ?? 0).toDouble();
      
      // Compter par statut
      parStatut[statut] = (parStatut[statut] ?? 0) + 1;
      
      // Additionner les montants
      montantTotal += montant;
      
      // Analyser par mois (si date disponible)
      if (data['dateCreation'] != null) {
        try {
          final date = (data['dateCreation'] as Timestamp).toDate();
          final moisKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
          parMois[moisKey] = (parMois[moisKey] ?? 0) + 1;
        } catch (e) {
          // Ignorer les erreurs de date
        }
      }
    }

    // Debug: Afficher les statuts trouvés
    debugPrint('🚗 Statuts des sinistres trouvés: $parStatut');

    return {
      'total': docs.length,
      'repartitionParStatut': parStatut,
      'evolutionParMois': parMois,
      'montantTotalEstime': montantTotal,
      'montantMoyen': docs.isNotEmpty ? (montantTotal / docs.length).round() : 0,
    };
  }

  /// 📋 Analyser les contrats
  static Map<String, dynamic> _analyzeContrats(List<QueryDocumentSnapshot> docs) {
    Map<String, int> parStatut = {};
    Map<String, int> parType = {};
    
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final statut = data['status'] ?? 'inconnu';
      final type = data['typeContrat'] ?? 'standard';
      
      parStatut[statut] = (parStatut[statut] ?? 0) + 1;
      parType[type] = (parType[type] ?? 0) + 1;
    }

    return {
      'total': docs.length,
      'repartitionParStatut': parStatut,
      'repartitionParType': parType,
    };
  }

  /// 🏪 Analyser les agences
  static Map<String, dynamic> _analyzeAgences(List<QueryDocumentSnapshot> docs) {
    int avecAdmin = docs.where((doc) => (doc.data() as Map<String, dynamic>)['hasAdminAgence'] == true).length;
    int sansAdmin = docs.length - avecAdmin;

    return {
      'total': docs.length,
      'avecAdmin': avecAdmin,
      'sansAdmin': sansAdmin,
      'pourcentageAvecAdmin': docs.isNotEmpty ? (avecAdmin / docs.length * 100).round() : 0,
    };
  }

  /// 📈 Calculer les tendances de croissance
  static Future<Map<String, dynamic>> _calculateTendances() async {
    try {
      final now = DateTime.now();
      final debutMoisActuel = DateTime(now.year, now.month, 1);
      final debutMoisPrecedent = DateTime(now.year, now.month - 1, 1);
      
      // Nouveaux utilisateurs ce mois
      final nouveauxUsersCeMois = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(debutMoisActuel))
          .get();
      
      // Nouveaux utilisateurs mois précédent
      final nouveauxUsersMoisPrecedent = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(debutMoisPrecedent))
          .where('createdAt', isLessThan: Timestamp.fromDate(debutMoisActuel))
          .get();
      
      // Calculer la croissance
      final croissanceUsers = nouveauxUsersMoisPrecedent.docs.isNotEmpty
          ? ((nouveauxUsersCeMois.docs.length - nouveauxUsersMoisPrecedent.docs.length) / nouveauxUsersMoisPrecedent.docs.length * 100).round()
          : 0;

      return {
        'nouveauxUsersCeMois': nouveauxUsersCeMois.docs.length,
        'nouveauxUsersMoisPrecedent': nouveauxUsersMoisPrecedent.docs.length,
        'croissanceUsers': croissanceUsers,
      };
      
    } catch (e) {
      debugPrint('[SUPER_ADMIN_ANALYTICS] ❌ Erreur tendances: $e');
      return {
        'nouveauxUsersCeMois': 0,
        'nouveauxUsersMoisPrecedent': 0,
        'croissanceUsers': 0,
      };
    }
  }

  /// 🏢 Obtenir les statistiques détaillées par compagnie
  static Future<List<Map<String, dynamic>>> getCompagniesDetailedStats() async {
    try {
      final compagniesSnapshot = await _firestore.collection('compagnies').get();
      List<Map<String, dynamic>> compagniesStats = [];

      for (final compagnieDoc in compagniesSnapshot.docs) {
        final compagnieData = compagnieDoc.data();
        final compagnieId = compagnieDoc.id;

        // Statistiques pour cette compagnie
        final stats = await _getStatsForCompagnie(compagnieId);
        
        compagniesStats.add({
          'id': compagnieId,
          'nom': compagnieData['nom'] ?? 'Sans nom',
          'code': compagnieData['code'] ?? 'N/A',
          'status': compagnieData['status'] ?? 'unknown',
          'stats': stats,
        });
      }

      // Trier par nombre d'agents (plus actives en premier)
      compagniesStats.sort((a, b) => (b['stats']['agents'] ?? 0).compareTo(a['stats']['agents'] ?? 0));

      return compagniesStats;
    } catch (e) {
      debugPrint('[SUPER_ADMIN_ANALYTICS] ❌ Erreur stats compagnies: $e');
      return [];
    }
  }

  /// 📊 Obtenir les stats pour une compagnie spécifique
  static Future<Map<String, dynamic>> _getStatsForCompagnie(String compagnieId) async {
    try {
      // Agences de la compagnie
      final agencesSnapshot = await _firestore
          .collection('agences')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      // Agents de la compagnie
      final agentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      // Contrats de la compagnie
      final contratsSnapshot = await _firestore
          .collection('contrats')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      // Sinistres de la compagnie
      final sinistresSnapshot = await _firestore
          .collection('sinistres')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      return {
        'agences': agencesSnapshot.docs.length,
        'agents': agentsSnapshot.docs.length,
        'contrats': contratsSnapshot.docs.length,
        'sinistres': sinistresSnapshot.docs.length,
        'sinistresEnCours': sinistresSnapshot.docs.where((doc) => 
          doc.data()['status'] == 'en_cours' || doc.data()['status'] == 'ouvert'
        ).length,
      };
    } catch (e) {
      debugPrint('[SUPER_ADMIN_ANALYTICS] ❌ Erreur stats compagnie $compagnieId: $e');
      return {
        'agences': 0,
        'agents': 0,
        'contrats': 0,
        'sinistres': 0,
        'sinistresEnCours': 0,
      };
    }
  }
}
