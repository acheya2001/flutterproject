import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

/// 🤖 Service d'affectation intelligente des agents
/// Utilise des algorithmes pour suggérer le meilleur agent pour traiter une demande
class IntelligentAgentAssignmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🎯 Suggère le meilleur agent pour traiter une demande
  static Future<Map<String, dynamic>> suggestBestAgent({
    required String agenceId,
    required Map<String, dynamic> demandeData,
  }) async {
    try {
      // 1. Récupérer tous les agents de l'agence
      final agentsSnapshot = await _firestore
          .collection('agents_assurance')
          .where('agenceId', isEqualTo: agenceId)
          .where('statut', isEqualTo: 'actif')
          .get();

      if (agentsSnapshot.docs.isEmpty) {
        return {
          'success': false,
          'error': 'Aucun agent actif trouvé dans cette agence',
        };
      }

      // 2. Calculer le score pour chaque agent
      List<Map<String, dynamic>> agentScores = [];
      
      for (var agentDoc in agentsSnapshot.docs) {
        final agentData = agentDoc.data();
        final agentId = agentDoc.id;
        
        final score = await _calculateAgentScore(
          agentId: agentId,
          agentData: agentData,
          demandeData: demandeData,
        );
        
        agentScores.add({
          'agentId': agentId,
          'agentData': agentData,
          'score': score['totalScore'],
          'details': score['details'],
        });
      }

      // 3. Trier par score décroissant
      agentScores.sort((a, b) => b['score'].compareTo(a['score']));

      // 4. Retourner le meilleur agent avec les détails
      final bestAgent = agentScores.first;
      
      return {
        'success': true,
        'recommendedAgent': bestAgent,
        'allAgents': agentScores,
        'recommendation': _generateRecommendationText(bestAgent),
      };

    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur lors du calcul de suggestion: $e',
      };
    }
  }

  /// 📊 Calcule le score d'un agent basé sur plusieurs critères
  static Future<Map<String, dynamic>> _calculateAgentScore({
    required String agentId,
    required Map<String, dynamic> agentData,
    required Map<String, dynamic> demandeData,
  }) async {
    double totalScore = 0;
    Map<String, dynamic> details = {};

    // 1. Critère: Charge de travail actuelle (40% du score)
    final workloadScore = await _calculateWorkloadScore(agentId);
    totalScore += workloadScore * 0.4;
    details['workload'] = {
      'score': workloadScore,
      'weight': 0.4,
      'description': 'Charge de travail actuelle',
    };

    // 2. Critère: Délai moyen de traitement (30% du score)
    final speedScore = await _calculateSpeedScore(agentId);
    totalScore += speedScore * 0.3;
    details['speed'] = {
      'score': speedScore,
      'weight': 0.3,
      'description': 'Vitesse de traitement',
    };

    // 3. Critère: Taux de satisfaction/qualité (20% du score)
    final qualityScore = await _calculateQualityScore(agentId);
    totalScore += qualityScore * 0.2;
    details['quality'] = {
      'score': qualityScore,
      'weight': 0.2,
      'description': 'Qualité du travail',
    };

    // 4. Critère: Spécialisation (10% du score)
    final specializationScore = _calculateSpecializationScore(agentData, demandeData);
    totalScore += specializationScore * 0.1;
    details['specialization'] = {
      'score': specializationScore,
      'weight': 0.1,
      'description': 'Spécialisation',
    };

    return {
      'totalScore': totalScore,
      'details': details,
    };
  }

  /// ⚖️ Calcule le score basé sur la charge de travail
  static Future<double> _calculateWorkloadScore(String agentId) async {
    try {
      // Compter les contrats actifs de l'agent
      final activeContractsSnapshot = await _firestore
          .collection('insurance_requests')
          .where('assignedAgentId', isEqualTo: agentId)
          .where('statut', whereIn: ['en_attente', 'en_cours', 'approuvee'])
          .get();

      final activeCount = activeContractsSnapshot.docs.length;

      // Score inversé: moins de contrats = meilleur score
      // 0 contrats = 100, 5 contrats = 50, 10+ contrats = 0
      if (activeCount == 0) return 100.0;
      if (activeCount <= 5) return 100.0 - (activeCount * 10);
      return max(0.0, 100.0 - (activeCount * 5));

    } catch (e) {
      return 50.0; // Score neutre en cas d'erreur
    }
  }

  /// ⚡ Calcule le score basé sur la vitesse de traitement
  static Future<double> _calculateSpeedScore(String agentId) async {
    try {
      // Récupérer les contrats traités dans les 30 derniers jours
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final completedContractsSnapshot = await _firestore
          .collection('insurance_requests')
          .where('assignedAgentId', isEqualTo: agentId)
          .where('statut', isEqualTo: 'termine')
          .where('dateTraitement', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      if (completedContractsSnapshot.docs.isEmpty) {
        return 70.0; // Score neutre pour nouveaux agents
      }

      // Calculer le délai moyen
      double totalDays = 0;
      int count = 0;

      for (var doc in completedContractsSnapshot.docs) {
        final data = doc.data();
        final dateCreation = (data['dateCreation'] as Timestamp).toDate();
        final dateTraitement = (data['dateTraitement'] as Timestamp).toDate();
        
        final delai = dateTraitement.difference(dateCreation).inDays;
        totalDays += delai;
        count++;
      }

      final averageDelai = totalDays / count;

      // Score basé sur le délai moyen
      // 1 jour = 100, 3 jours = 70, 7+ jours = 20
      if (averageDelai <= 1) return 100.0;
      if (averageDelai <= 3) return 85.0;
      if (averageDelai <= 5) return 70.0;
      if (averageDelai <= 7) return 50.0;
      return 20.0;

    } catch (e) {
      return 70.0; // Score neutre en cas d'erreur
    }
  }

  /// ⭐ Calcule le score basé sur la qualité
  static Future<double> _calculateQualityScore(String agentId) async {
    try {
      // Récupérer les évaluations de l'agent
      final evaluationsSnapshot = await _firestore
          .collection('agent_evaluations')
          .where('agentId', isEqualTo: agentId)
          .orderBy('dateEvaluation', descending: true)
          .limit(10) // Dernières 10 évaluations
          .get();

      if (evaluationsSnapshot.docs.isEmpty) {
        return 80.0; // Score neutre pour nouveaux agents
      }

      // Calculer la moyenne des évaluations
      double totalRating = 0;
      int count = 0;

      for (var doc in evaluationsSnapshot.docs) {
        final data = doc.data();
        final rating = (data['rating'] as num).toDouble();
        totalRating += rating;
        count++;
      }

      final averageRating = totalRating / count;
      
      // Convertir la note (sur 5) en score (sur 100)
      return (averageRating / 5.0) * 100.0;

    } catch (e) {
      return 80.0; // Score neutre en cas d'erreur
    }
  }

  /// 🎯 Calcule le score basé sur la spécialisation
  static double _calculateSpecializationScore(
    Map<String, dynamic> agentData,
    Map<String, dynamic> demandeData,
  ) {
    try {
      final agentSpecialites = List<String>.from(agentData['specialites'] ?? []);
      final vehiculeType = demandeData['vehicule']?['typeVehicule'] ?? '';
      final contractType = demandeData['typeContrat'] ?? '';

      double score = 50.0; // Score de base

      // Bonus pour spécialisation véhicule
      if (agentSpecialites.contains(vehiculeType)) {
        score += 30.0;
      }

      // Bonus pour spécialisation contrat
      if (agentSpecialites.contains(contractType)) {
        score += 20.0;
      }

      return min(100.0, score);

    } catch (e) {
      return 50.0; // Score neutre en cas d'erreur
    }
  }

  /// 📝 Génère un texte de recommandation
  static String _generateRecommendationText(Map<String, dynamic> bestAgent) {
    final agentData = bestAgent['agentData'];
    final score = bestAgent['score'];
    final details = bestAgent['details'];

    String recommendation = 'Recommandé: ${agentData['prenom']} ${agentData['nom']} ';
    
    if (score >= 90) {
      recommendation += '(Excellent choix - Score: ${score.toInt()}/100)';
    } else if (score >= 75) {
      recommendation += '(Bon choix - Score: ${score.toInt()}/100)';
    } else {
      recommendation += '(Choix acceptable - Score: ${score.toInt()}/100)';
    }

    // Ajouter les points forts
    List<String> strengths = [];
    
    if (details['workload']['score'] >= 80) {
      strengths.add('charge légère');
    }
    if (details['speed']['score'] >= 80) {
      strengths.add('traitement rapide');
    }
    if (details['quality']['score'] >= 80) {
      strengths.add('haute qualité');
    }

    if (strengths.isNotEmpty) {
      recommendation += '\nPoints forts: ${strengths.join(', ')}';
    }

    return recommendation;
  }

  /// 📊 Obtient les statistiques de performance d'une agence
  static Future<Map<String, dynamic>> getAgencyPerformanceStats(String agenceId) async {
    try {
      final agentsSnapshot = await _firestore
          .collection('agents_assurance')
          .where('agenceId', isEqualTo: agenceId)
          .where('statut', isEqualTo: 'actif')
          .get();

      List<Map<String, dynamic>> agentStats = [];
      
      for (var agentDoc in agentsSnapshot.docs) {
        final agentId = agentDoc.id;
        final agentData = agentDoc.data();
        
        // Compter les contrats actifs
        final activeContractsSnapshot = await _firestore
            .collection('insurance_requests')
            .where('assignedAgentId', isEqualTo: agentId)
            .where('statut', whereIn: ['en_attente', 'en_cours'])
            .get();

        // Compter les contrats terminés ce mois
        final thisMonth = DateTime.now();
        final startOfMonth = DateTime(thisMonth.year, thisMonth.month, 1);
        
        final completedThisMonthSnapshot = await _firestore
            .collection('insurance_requests')
            .where('assignedAgentId', isEqualTo: agentId)
            .where('statut', isEqualTo: 'termine')
            .where('dateTraitement', isGreaterThan: Timestamp.fromDate(startOfMonth))
            .get();

        agentStats.add({
          'agentId': agentId,
          'nom': '${agentData['prenom']} ${agentData['nom']}',
          'activeContracts': activeContractsSnapshot.docs.length,
          'completedThisMonth': completedThisMonthSnapshot.docs.length,
          'workloadPercentage': _calculateWorkloadPercentage(
            activeContractsSnapshot.docs.length,
            agentsSnapshot.docs.length,
          ),
        });
      }

      return {
        'success': true,
        'agentStats': agentStats,
        'totalAgents': agentsSnapshot.docs.length,
        'recommendations': _generateBalancingRecommendations(agentStats),
      };

    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur lors du calcul des statistiques: $e',
      };
    }
  }

  /// 📈 Calcule le pourcentage de charge de travail
  static double _calculateWorkloadPercentage(int activeContracts, int totalAgents) {
    if (totalAgents == 0) return 0.0;
    
    // Estimation: charge équilibrée = 5 contrats par agent
    final idealLoad = 5;
    final maxLoad = idealLoad * 2; // 10 contrats = 100%
    
    return min(100.0, (activeContracts / maxLoad) * 100);
  }

  /// 💡 Génère des recommandations d'équilibrage
  static List<String> _generateBalancingRecommendations(List<Map<String, dynamic>> agentStats) {
    List<String> recommendations = [];
    
    // Trouver l'agent le plus chargé et le moins chargé
    agentStats.sort((a, b) => b['activeContracts'].compareTo(a['activeContracts']));
    
    if (agentStats.isNotEmpty) {
      final mostLoaded = agentStats.first;
      final leastLoaded = agentStats.last;
      
      final difference = mostLoaded['activeContracts'] - leastLoaded['activeContracts'];
      
      if (difference > 3) {
        recommendations.add(
          'Déséquilibre détecté: ${mostLoaded['nom']} a ${difference} contrats de plus que ${leastLoaded['nom']}'
        );
        recommendations.add(
          'Recommandation: Affecter les prochaines demandes à ${leastLoaded['nom']}'
        );
      } else {
        recommendations.add('Charge de travail bien équilibrée entre les agents');
      }
    }
    
    return recommendations;
  }
}
