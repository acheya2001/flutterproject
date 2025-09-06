import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

/// 🤖 Service d'IA pour l'affectation intelligente des contrats aux agents
class AgentAssignmentAIService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🎯 Trouver le meilleur agent pour une demande de contrat
  static Future<Map<String, dynamic>> findBestAgent({
    required String agenceId,
    required Map<String, dynamic> demandeData,
  }) async {
    try {
      print('🤖 IA: Recherche agent pour demande ${demandeData['numero']}');

      // 1. Récupérer tous les agents de l'agence
      final agents = await _getAgentsInAgence(agenceId);
      if (agents.isEmpty) {
        return {
          'success': false,
          'error': 'Aucun agent disponible dans cette agence',
        };
      }

      print('🤖 IA: ${agents.length} agents analysés');

      // 2. Calculer le score pour chaque agent
      final agentScores = <Map<String, dynamic>>[];

      for (final agent in agents) {
        try {
          final score = await _calculateAgentScore(agent, demandeData);
          agentScores.add({
            'agent': agent,
            'score': score,
          });
        } catch (e) {
          print('❌ Erreur calcul score pour ${agent['nom']}: $e');
          // Ajouter quand même avec un score très élevé
          agentScores.add({
            'agent': agent,
            'score': {
              'total': 999.0,
              'charge': 999.0,
              'vitesse': 999.0,
              'qualite': 999.0,
              'specialite': 999.0,
              'details': {},
            },
          });
        }
      }

      // 3. Trier par score (meilleur score = plus bas)
      agentScores.sort((a, b) => a['score']['total'].compareTo(b['score']['total']));

      final bestAgent = agentScores.first;
      final recommendation = _generateRecommendation(bestAgent, agentScores);

      print('🤖 IA: Agent sélectionné - ${bestAgent['agent']['prenom']} ${bestAgent['agent']['nom']}');

      return {
        'success': true,
        'bestAgent': bestAgent['agent'],
        'score': bestAgent['score'],
        'recommendation': recommendation,
        'allScores': agentScores,
      };

    } catch (e) {
      print('❌ Erreur IA affectation: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 👥 Récupérer tous les agents d'une agence
  static Future<List<Map<String, dynamic>>> _getAgentsInAgence(String agenceId) async {
    try {
      print('🔍 IA: Recherche agents pour agence: $agenceId');

      // D'abord chercher dans la collection 'users' avec role 'agent' (SANS filtre statut)
      final usersSnapshot = await _firestore
          .collection('users')
          .where('agenceId', isEqualTo: agenceId)
          .where('role', isEqualTo: 'agent')
          .get();

      List<Map<String, dynamic>> agents = [];

      // Ajouter les agents de la collection 'users'
      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        data['source'] = 'users';
        agents.add(data);
        print('👤 IA: Agent users trouvé: ${data['prenom']} ${data['nom']} - Statut: ${data['statut']}');
      }

      // NE PAS chercher dans 'agents_assurance' car ce sont des agents de test
      print('🤖 IA: ${agents.length} agents trouvés dans users');

      // Si aucun agent trouvé, afficher un message d'erreur détaillé
      if (agents.isEmpty) {
        print('❌ IA: Aucun agent trouvé pour agence $agenceId');

        // Debug: vérifier tous les agents dans users
        final allUsersSnapshot = await _firestore.collection('users').get();
        print('📊 IA Debug: Total users dans la base: ${allUsersSnapshot.docs.length}');

        for (final doc in allUsersSnapshot.docs) {
          final data = doc.data();
          if (data['role'] == 'agent') {
            print('🔍 IA Debug: Agent trouvé - agenceId: ${data['agenceId']}, nom: ${data['prenom']} ${data['nom']}');
          }
        }
      }

      return agents;
    } catch (e) {
      print('❌ Erreur récupération agents: $e');
      return [];
    }
  }

  /// 📊 Calculer le score d'un agent pour une demande
  static Future<Map<String, dynamic>> _calculateAgentScore(
    Map<String, dynamic> agent,
    Map<String, dynamic> demandeData,
  ) async {
    try {
      // Critères de scoring avec pondération
      const double POIDS_CHARGE = 0.4;      // 40% - Charge de travail
      const double POIDS_VITESSE = 0.3;     // 30% - Vitesse de traitement
      const double POIDS_QUALITE = 0.2;     // 20% - Qualité du travail
      const double POIDS_SPECIALITE = 0.1;  // 10% - Spécialité

      // 1. Charge de travail actuelle
      final chargeScore = await _calculateChargeScore(agent['id']);
      
      // 2. Vitesse de traitement
      final vitesseScore = await _calculateVitesseScore(agent['id']);
      
      // 3. Qualité du travail
      final qualiteScore = await _calculateQualiteScore(agent['id']);
      
      // 4. Spécialité (type de véhicule, marque, etc.)
      final specialiteScore = _calculateSpecialiteScore(agent, demandeData);

      // Score total (plus bas = meilleur)
      final totalScore = 
          (chargeScore * POIDS_CHARGE) +
          (vitesseScore * POIDS_VITESSE) +
          (qualiteScore * POIDS_QUALITE) +
          (specialiteScore * POIDS_SPECIALITE);

      return {
        'total': totalScore,
        'charge': chargeScore,
        'vitesse': vitesseScore,
        'qualite': qualiteScore,
        'specialite': specialiteScore,
        'details': {
          'chargeActuelle': await _getChargeActuelle(agent['id']),
          'delaiMoyen': await _getDelaiMoyen(agent['id']),
          'tauxReussite': await _getTauxReussite(agent['id']),
        }
      };
    } catch (e) {
      print('❌ Erreur calcul score agent ${agent['id']}: $e');
      return {
        'total': 999.0, // Score très élevé en cas d'erreur
        'charge': 999.0,
        'vitesse': 999.0,
        'qualite': 999.0,
        'specialite': 999.0,
        'details': {},
      };
    }
  }

  /// ⚖️ Calculer le score de charge de travail
  static Future<double> _calculateChargeScore(String agentId) async {
    try {
      final snapshot = await _firestore
          .collection('demandes_contrats')
          .where('agentId', isEqualTo: agentId)
          .where('statut', whereIn: ['affectee', 'en_cours'])
          .get();

      final charge = snapshot.docs.length;
      
      // Score: 0-5 contrats = 0-1, 6-10 = 1-2, 11+ = 2+
      return charge <= 5 ? charge * 0.2 : (charge <= 10 ? 1 + (charge - 5) * 0.2 : 2 + (charge - 10) * 0.1);
    } catch (e) {
      return 999.0;
    }
  }

  /// ⏳ Calculer le score de vitesse de traitement
  static Future<double> _calculateVitesseScore(String agentId) async {
    try {
      final snapshot = await _firestore
          .collection('demandes_contrats')
          .where('agentId', isEqualTo: agentId)
          .where('statut', isEqualTo: 'contrat_valide')
          .orderBy('dateValidation', descending: true)
          .limit(10)
          .get();

      if (snapshot.docs.isEmpty) return 1.0; // Score neutre pour nouveaux agents

      double totalDelai = 0;
      int count = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final dateAffectation = data['dateAffectation']?.toDate();
        final dateValidation = data['dateValidation']?.toDate();
        
        if (dateAffectation != null && dateValidation != null) {
          final delai = dateValidation.difference(dateAffectation).inDays;
          totalDelai += delai;
          count++;
        }
      }

      if (count == 0) return 1.0;

      final delaiMoyen = totalDelai / count;
      
      // Score: 1 jour = 0.1, 2 jours = 0.3, 3+ jours = 0.5+
      return delaiMoyen <= 1 ? 0.1 : (delaiMoyen <= 2 ? 0.3 : 0.5 + (delaiMoyen - 2) * 0.1);
    } catch (e) {
      return 999.0;
    }
  }

  /// ⭐ Calculer le score de qualité
  static Future<double> _calculateQualiteScore(String agentId) async {
    try {
      final snapshot = await _firestore
          .collection('demandes_contrats')
          .where('agentId', isEqualTo: agentId)
          .orderBy('dateAffectation', descending: true)
          .limit(20)
          .get();

      if (snapshot.docs.isEmpty) return 1.0;

      int totalContrats = snapshot.docs.length;
      int contratsReussis = 0;

      for (final doc in snapshot.docs) {
        final statut = doc.data()['statut'];
        if (statut == 'contrat_valide') {
          contratsReussis++;
        }
      }

      final tauxReussite = contratsReussis / totalContrats;
      
      // Score: 90%+ = 0.1, 80-90% = 0.3, 70-80% = 0.5, <70% = 1.0+
      if (tauxReussite >= 0.9) return 0.1;
      if (tauxReussite >= 0.8) return 0.3;
      if (tauxReussite >= 0.7) return 0.5;
      return 1.0 + (0.7 - tauxReussite) * 2;
    } catch (e) {
      return 999.0;
    }
  }

  /// 🎯 Calculer le score de spécialité
  static double _calculateSpecialiteScore(
    Map<String, dynamic> agent,
    Map<String, dynamic> demandeData,
  ) {
    try {
      double score = 0.5; // Score de base

      // Spécialité par marque de véhicule
      final marqueVehicule = demandeData['marque']?.toString().toLowerCase();
      final specialites = agent['specialites'] as List<dynamic>?;
      
      if (specialites != null && marqueVehicule != null) {
        final hasSpecialite = specialites.any((s) => 
          s.toString().toLowerCase().contains(marqueVehicule));
        if (hasSpecialite) score -= 0.3; // Bonus pour spécialité
      }

      // Bonus pour expérience (années de service)
      final dateEmbauche = agent['dateEmbauche']?.toDate();
      if (dateEmbauche != null) {
        final experience = DateTime.now().difference(dateEmbauche).inDays / 365;
        if (experience > 2) score -= 0.1; // Bonus expérience
        if (experience > 5) score -= 0.1; // Bonus expérience senior
      }

      return score.clamp(0.0, 1.0);
    } catch (e) {
      return 0.5;
    }
  }

  /// 📊 Méthodes utilitaires pour les détails
  static Future<int> _getChargeActuelle(String agentId) async {
    try {
      final snapshot = await _firestore
          .collection('demandes_contrats')
          .where('agentId', isEqualTo: agentId)
          .where('statut', whereIn: ['affectee', 'en_cours'])
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  static Future<double> _getDelaiMoyen(String agentId) async {
    try {
      final snapshot = await _firestore
          .collection('demandes_contrats')
          .where('agentId', isEqualTo: agentId)
          .where('statut', isEqualTo: 'contrat_valide')
          .orderBy('dateValidation', descending: true)
          .limit(10)
          .get();

      if (snapshot.docs.isEmpty) return 0.0;

      double totalDelai = 0;
      int count = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final dateAffectation = data['dateAffectation']?.toDate();
        final dateValidation = data['dateValidation']?.toDate();
        
        if (dateAffectation != null && dateValidation != null) {
          final delai = dateValidation.difference(dateAffectation).inDays;
          totalDelai += delai;
          count++;
        }
      }

      return count > 0 ? totalDelai / count : 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  static Future<double> _getTauxReussite(String agentId) async {
    try {
      final snapshot = await _firestore
          .collection('demandes_contrats')
          .where('agentId', isEqualTo: agentId)
          .orderBy('dateAffectation', descending: true)
          .limit(20)
          .get();

      if (snapshot.docs.isEmpty) return 0.0;

      int totalContrats = snapshot.docs.length;
      int contratsReussis = 0;

      for (final doc in snapshot.docs) {
        final statut = doc.data()['statut'];
        if (statut == 'contrat_valide') {
          contratsReussis++;
        }
      }

      return contratsReussis / totalContrats;
    } catch (e) {
      return 0.0;
    }
  }

  /// 💡 Générer une recommandation textuelle
  static String _generateRecommendation(
    Map<String, dynamic> bestAgent,
    List<Map<String, dynamic>> allScores,
  ) {
    final agent = bestAgent['agent'];
    final score = bestAgent['score'];
    final details = score['details'];

    String recommendation = '🏆 Agent recommandé: ${agent['nom']} ${agent['prenom']}\n\n';
    
    recommendation += '📊 Raisons:\n';
    recommendation += '• Charge actuelle: ${details['chargeActuelle']} contrats\n';
    recommendation += '• Délai moyen: ${details['delaiMoyen'].toStringAsFixed(1)} jours\n';
    recommendation += '• Taux de réussite: ${(details['tauxReussite'] * 100).toStringAsFixed(1)}%\n';
    
    if (allScores.length > 1) {
      final secondBest = allScores[1];
      recommendation += '\n🥈 Alternative: ${secondBest['agent']['nom']} ${secondBest['agent']['prenom']}';
    }

    return recommendation;
  }

  /// 🔄 Affecter automatiquement une demande à un agent
  static Future<Map<String, dynamic>> assignDemandeToAgent({
    required String demandeId,
    required String agentId,
    required Map<String, dynamic> agentData,
    required Map<String, dynamic> scoreData,
  }) async {
    try {
      print('🔄 Affectation demande $demandeId à agent $agentId');

      await _firestore.collection('demandes_contrats').doc(demandeId).update({
        'statut': 'affectee',
        'agentId': agentId,
        'agentNom': '${agentData['prenom']} ${agentData['nom']}',
        'agentEmail': agentData['email'],
        'dateAffectation': FieldValue.serverTimestamp(),
        'scoreIA': scoreData,
        'affectationMode': 'ia_automatique',
      });

      print('✅ Demande affectée avec succès');

      return {
        'success': true,
        'message': 'Demande affectée à ${agentData['prenom']} ${agentData['nom']}',
      };

    } catch (e) {
      print('❌ Erreur affectation: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 📈 Obtenir les statistiques d'équilibrage des agents
  static Future<Map<String, dynamic>> getAgentBalanceStats(String agenceId) async {
    try {
      final agents = await _getAgentsInAgence(agenceId);
      final stats = <Map<String, dynamic>>[];

      for (final agent in agents) {
        final charge = await _getChargeActuelle(agent['id']);
        final delaiMoyen = await _getDelaiMoyen(agent['id']);
        final tauxReussite = await _getTauxReussite(agent['id']);

        stats.add({
          'agent': agent,
          'charge': charge,
          'delaiMoyen': delaiMoyen,
          'tauxReussite': tauxReussite,
        });
      }

      // Trier par charge (équilibrage)
      stats.sort((a, b) => a['charge'].compareTo(b['charge']));

      return {
        'success': true,
        'stats': stats,
        'totalAgents': agents.length,
        'chargeTotal': stats.fold<int>(0, (sum, s) => sum + (s['charge'] as int)),
      };

    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
