import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/debug_service.dart';
import '../../../services/agent_assignment_ai_service.dart';

/// 📋 Écran de gestion des demandes de contrats pour Admin Agence
class DemandesContratsScreen extends StatefulWidget {
  final String agenceId;
  final Map<String, dynamic> agenceData;

  const DemandesContratsScreen({
    Key? key,
    required this.agenceId,
    required this.agenceData,
  }) : super(key: key);

  @override
  State<DemandesContratsScreen> createState() => _DemandesContratsScreenState();
}

class _DemandesContratsScreenState extends State<DemandesContratsScreen> {
  String _selectedFilter = 'en_attente';

  // Méthode pour construire le stream avec debug
  Stream<QuerySnapshot> _buildDemandesStream() {
    print('🔍 Construction stream pour agence: ${widget.agenceId}, filtre: $_selectedFilter');

    // Debug toutes les demandes au démarrage
    _debugAllDemandes();

    try {
      // Si l'agenceId est vide ou null, chercher toutes les demandes
      if (widget.agenceId.isEmpty) {
        print('⚠️ AgenceId vide - affichage de toutes les demandes');
        return FirebaseFirestore.instance
            .collection('demandes_contrats')
            .where('statut', isEqualTo: _selectedFilter)
            .snapshots();
      }

      // Version temporaire sans orderBy en attendant l'index Firebase
      return FirebaseFirestore.instance
          .collection('demandes_contrats')
          .where('agenceId', isEqualTo: widget.agenceId)
          .where('statut', isEqualTo: _selectedFilter)
          .snapshots();
    } catch (e) {
      print('❌ Erreur construction stream: $e');
      // Fallback: essayer sans le filtre agenceId
      print('🔄 Tentative fallback sans filtre agenceId');
      return FirebaseFirestore.instance
          .collection('demandes_contrats')
          .where('statut', isEqualTo: _selectedFilter)
          .snapshots();
    }
  }

  Future<void> _debugAllDemandes() async {
    try {
      final allDemandes = await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .get();

      print('\n=== 🔍 DEBUG TOUTES DEMANDES ===');
      print('📊 Total demandes: ${allDemandes.docs.length}');
      print('🏢 Agence recherchée: ${widget.agenceId}');
      print('📋 Filtre statut: $_selectedFilter');

      int matchingAgence = 0;
      int matchingStatut = 0;
      int matchingBoth = 0;

      for (final doc in allDemandes.docs) {
        final data = doc.data();
        final agenceId = data['agenceId'] as String?;
        final statut = data['statut'] as String?;

        if (agenceId == widget.agenceId) matchingAgence++;
        if (statut == _selectedFilter) matchingStatut++;
        if (agenceId == widget.agenceId && statut == _selectedFilter) matchingBoth++;

        print('📋 ${doc.id}: agenceId="$agenceId", statut="$statut", numero="${data['numero']}"');
      }

      print('📊 Résumé:');
      print('   - Même agenceId: $matchingAgence');
      print('   - Même statut: $matchingStatut');
      print('   - Les deux: $matchingBoth');
      print('=== FIN DEBUG TOUTES DEMANDES ===\n');
    } catch (e) {
      print('❌ Erreur debug: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Demandes de Contrats',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        actions: [




          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showAgentBalanceStats(),
            tooltip: 'Statistiques agents IA',
          ),

          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('🔄 Rechargement manuel des demandes');
              setState(() {});
            },
            tooltip: 'Recharger',
          ),
        ],
      ),
      body: Column(
        children: [
          // Debug info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.blue[50],
            child: Text(
              'Debug: Agence ID = ${widget.agenceId} | Filtre = $_selectedFilter',
              style: TextStyle(fontSize: 12, color: Colors.blue[700]),
              textAlign: TextAlign.center,
            ),
          ),

          // Filtres
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                _buildFilterChip('en_attente', 'En Attente', Colors.orange),
                const SizedBox(width: 8),
                _buildFilterChip('approuve', 'Approuvées', Colors.green),
                const SizedBox(width: 8),
                _buildFilterChip('rejete', 'Rejetées', Colors.red),
              ],
            ),
          ),
          
          // Liste des demandes
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildDemandesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('❌ Erreur StreamBuilder demandes: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                        const SizedBox(height: 16),
                        Text('Erreur: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final demandes = snapshot.data?.docs ?? [];
                print('📋 Demandes trouvées pour agence ${widget.agenceId}: ${demandes.length}');

                if (demandes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune demande ${_selectedFilter.replaceAll('_', ' ')}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Agence ID: ${widget.agenceId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: demandes.length,
                  itemBuilder: (context, index) {
                    final doc = demandes[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildDemandeCard(doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, Color color) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        print('🔄 Changement filtre: $value (sélectionné: $selected)');
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: color,
      checkmarkColor: Colors.white,
      side: BorderSide(color: color),
    );
  }

  Widget _buildDemandeCard(String id, Map<String, dynamic> data) {
    final dateCreation = data['dateCreation'] as Timestamp?;
    final dateStr = dateCreation?.toDate().toString().substring(0, 16) ?? 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Demande ${data['numero'] ?? id.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(data['statut']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(data['statut']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Informations conducteur
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '${data['prenom'] ?? ''} ${data['nom'] ?? ''}'.trim(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            Row(
              children: [
                const Icon(Icons.email, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  data['email'] ?? 'N/A',
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 4),

            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  data['telephone'] ?? 'N/A',
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Informations véhicule
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Véhicule: ${data['marque'] ?? ''} ${data['modele'] ?? ''}'.trim(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Immatriculation: ${data['immatriculation'] ?? 'N/A'}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                  Text(
                    'Année: ${data['annee'] ?? 'N/A'}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Actions et date
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Créée le $dateStr',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                // Bouton Détails uniquement
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showDemandeDetails(data, id),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Voir Détails'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? statut) {
    switch (statut) {
      case 'en_attente':
        return Colors.orange;
      case 'approuvee':
        return Colors.green;
      case 'rejetee':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String? statut) {
    switch (statut) {
      case 'en_attente':
        return 'En Attente';
      case 'approuvee':
        return 'Approuvée';
      case 'rejetee':
        return 'Rejetée';
      default:
        return 'Inconnu';
    }
  }

  Future<void> _approuverDemande(String demandeId) async {
    try {
      // 1. Récupérer les données de la demande
      final demandeDoc = await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .doc(demandeId)
          .get();

      if (!demandeDoc.exists) {
        throw Exception('Demande introuvable');
      }

      final demandeData = demandeDoc.data()!;

      // 2. Toujours afficher le dialogue de choix d'approbation
      final choice = await _showApprovalChoiceDialog(demandeData);

      // 3. Traiter le choix de l'admin
      switch (choice) {
        case 'approve_manual':
          await _showManualAssignmentDialogSimple(demandeId, demandeData);
          break;
        case 'approve_ai':
          await _approuverAvecIA(demandeId, demandeData);
          break;
        default:
          // Annulé, ne rien faire
          break;
      }

    } catch (e) {
      print('❌ Erreur approbation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🤖 Approuver avec IA
  Future<void> _approuverAvecIA(String demandeId, Map<String, dynamic> demandeData) async {
    try {
      print('🤖 Recherche du meilleur agent avec IA...');
      final iaResult = await AgentAssignmentAIService.findBestAgent(
        agenceId: widget.agenceId,
        demandeData: demandeData,
      );

      if (!iaResult['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${iaResult['error']}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Afficher le dashboard IA avec la recommandation
      final confirmed = await _showIARecommendationDialog(
        demandeData: demandeData,
        iaResult: iaResult,
      );

      if (confirmed == 'approve_ai') {
        // Affecter avec l'IA
        await _approuverEtAffecter(demandeId, demandeData, iaResult);
      }

    } catch (e) {
      print('❌ Erreur IA: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur IA: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 📋 Approuver sans affectation (fallback)
  Future<void> _approuverSansAffectation(String demandeId) async {
    await FirebaseFirestore.instance
        .collection('demandes_contrats')
        .doc(demandeId)
        .update({
      'statut': 'approuvee',
      'dateApprobation': FieldValue.serverTimestamp(),
      'approuvePar': widget.agenceData['nom'] ?? 'Admin Agence',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Demande approuvée (sans affectation automatique)'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// 🤖 Approuver et affecter avec IA
  Future<void> _approuverEtAffecter(
    String demandeId,
    Map<String, dynamic> demandeData,
    Map<String, dynamic> iaResult,
  ) async {
    final bestAgent = iaResult['bestAgent'];
    final score = iaResult['score'];

    // Affecter la demande à l'agent recommandé
    final assignResult = await AgentAssignmentAIService.assignDemandeToAgent(
      demandeId: demandeId,
      agentId: bestAgent['id'],
      agentData: bestAgent,
      scoreData: score,
    );

    if (assignResult['success']) {
      // Mettre à jour aussi le statut d'approbation
      await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .doc(demandeId)
          .update({
        'dateApprobation': FieldValue.serverTimestamp(),
        'approuvePar': widget.agenceData['nom'] ?? 'Admin Agence',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${assignResult['message']} (IA)'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      throw Exception(assignResult['error']);
    }
  }

  Future<void> _rejeterDemande(String demandeId) async {
    try {
      await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .doc(demandeId)
          .update({
        'statut': 'rejetee',
        'dateRejet': FieldValue.serverTimestamp(),
        'rejetePar': widget.agenceData['nom'] ?? 'Admin Agence',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Demande rejetée'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🤖 Afficher la recommandation IA dans une boîte de dialogue
  Future<String?> _showIARecommendationDialog({
    required Map<String, dynamic> demandeData,
    required Map<String, dynamic> iaResult,
  }) async {
    final bestAgent = iaResult['bestAgent'];
    final score = iaResult['score'];
    final recommendation = iaResult['recommendation'];
    final allScores = iaResult['allScores'] as List<Map<String, dynamic>>;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.smart_toy, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text('🤖 Recommandation IA'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Informations de la demande
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📋 Demande ${demandeData['numero']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('🚗 ${demandeData['marque']} ${demandeData['modele']}'),
                      Text('👤 ${demandeData['prenom']} ${demandeData['nom']}'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Recommandation principale
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${bestAgent['prenom']} ${bestAgent['nom']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '📊 Score IA: ${score['total'].toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.green[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '📈 Charge: ${score['details']['chargeActuelle']} contrats',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        '⏱️ Délai moyen: ${score['details']['delaiMoyen'].toStringAsFixed(1)} jours',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        '⭐ Taux réussite: ${(score['details']['tauxReussite'] * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Autres agents (top 3)
                if (allScores.length > 1) ...[
                  const Text(
                    '🥈 Autres agents disponibles:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...allScores.take(3).skip(1).map((agentScore) {
                    final agent = agentScore['agent'];
                    final agentScoreData = agentScore['score'];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${agent['prenom']} ${agent['nom']}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            'Score: ${agentScoreData['total'].toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              child: const Text('❌ Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('approve_only'),
              child: const Text('✅ Approuver seulement'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop('approve_manual'),
              icon: const Icon(Icons.person, size: 16),
              label: const Text('👤 Affecter manuellement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop('approve_ai'),
              icon: const Icon(Icons.smart_toy, size: 16),
              label: const Text('🤖 Affecter IA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  /// 📈 Afficher les statistiques d'équilibrage des agents
  Future<void> _showAgentBalanceStats() async {
    try {
      final stats = await AgentAssignmentAIService.getAgentBalanceStats(widget.agenceId);

      if (!stats['success']) {
        throw Exception(stats['error']);
      }

      final agentStats = stats['stats'] as List<Map<String, dynamic>>;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text('📈 Équilibrage Agents IA'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Résumé global
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📊 Résumé Global',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('👥 Total agents: ${stats['totalAgents']}'),
                        Text('📋 Total contrats: ${stats['chargeTotal']}'),
                        Text('⚖️ Moyenne: ${(stats['chargeTotal'] / stats['totalAgents']).toStringAsFixed(1)} contrats/agent'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Liste des agents
                  const Text(
                    '👥 Détail par Agent:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  ...agentStats.map((agentStat) {
                    final agent = agentStat['agent'];
                    final charge = agentStat['charge'];
                    final delaiMoyen = agentStat['delaiMoyen'];
                    final tauxReussite = agentStat['tauxReussite'];

                    // Couleur selon la charge
                    Color chargeColor = Colors.green;
                    if (charge > 8) chargeColor = Colors.red;
                    else if (charge > 5) chargeColor = Colors.orange;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${agent['prenom']} ${agent['nom']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: chargeColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$charge contrats',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '⏱️ ${delaiMoyen.toStringAsFixed(1)} jours',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              Text(
                                '⭐ ${(tauxReussite * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
            ],
          );
        },
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 👤 Afficher le dialogue d'affectation manuelle
  Future<void> _showManualAssignmentDialog(
    String demandeId,
    Map<String, dynamic> demandeData,
    Map<String, dynamic> iaResult,
  ) async {
    final allScores = iaResult['allScores'] as List<Map<String, dynamic>>;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.person, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Text('👤 Choisir un Agent'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Informations de la demande
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📋 Demande ${demandeData['numero']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('🚗 ${demandeData['marque']} ${demandeData['modele']}'),
                      Text('👤 ${demandeData['prenom']} ${demandeData['nom']}'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  '👥 Sélectionner un agent:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Liste des agents
                ...allScores.map((agentScore) {
                  final agent = agentScore['agent'];
                  final score = agentScore['score'];
                  final details = score['details'];

                  // Couleur selon le score (meilleur = vert)
                  Color cardColor = Colors.grey[50]!;
                  Color borderColor = Colors.grey[300]!;
                  if (agentScore == allScores.first) {
                    cardColor = Colors.green[50]!;
                    borderColor = Colors.green[300]!;
                  } else if (agentScore == allScores[1]) {
                    cardColor = Colors.orange[50]!;
                    borderColor = Colors.orange[300]!;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _approuverEtAffecterAgent(demandeId, agent, score);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${agent['prenom']} ${agent['nom']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (agentScore == allScores.first)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      '🏆 IA',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '📈 ${details['chargeActuelle']} contrats',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                Text(
                                  '⏱️ ${details['delaiMoyen'].toStringAsFixed(1)} jours',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            Text(
                              '⭐ Taux réussite: ${(details['tauxReussite'] * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );
  }

  /// 👤 Approuver et affecter à un agent spécifique
  Future<void> _approuverEtAffecterAgent(
    String demandeId,
    Map<String, dynamic> agent,
    Map<String, dynamic> score,
  ) async {
    try {
      final assignResult = await AgentAssignmentAIService.assignDemandeToAgent(
        demandeId: demandeId,
        agentId: agent['id'],
        agentData: agent,
        scoreData: score,
      );

      if (assignResult['success']) {
        // Mettre à jour aussi le statut d'approbation
        await FirebaseFirestore.instance
            .collection('demandes_contrats')
            .doc(demandeId)
            .update({
          'dateApprobation': FieldValue.serverTimestamp(),
          'approuvePar': widget.agenceData['nom'] ?? 'Admin Agence',
          'affectationMode': 'manuelle',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Demande affectée à ${agent['prenom']} ${agent['nom']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        throw Exception(assignResult['error']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 📋 Afficher les détails complets d'une demande
  void _showDemandeDetails(Map<String, dynamic> data, String demandeId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.blue[50]!,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header moderne
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[700]!, Colors.blue[500]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.description,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Demande ${data['numero'] ?? 'N/A'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${data['prenom'] ?? ''} ${data['nom'] ?? ''}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getStatusColor(data['statut']),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusLabel(data['statut']),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenu avec scroll
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Informations personnelles
                        _buildModernDetailSection(
                          title: 'Informations Personnelles',
                          icon: Icons.person,
                          color: Colors.blue[600]!,
                          items: [
                            _buildDetailItem('Nom complet', '${data['prenom'] ?? ''} ${data['nom'] ?? ''}', Icons.badge),
                            _buildDetailItem('Email', data['email'] ?? 'N/A', Icons.email),
                            _buildDetailItem('Téléphone', data['telephone'] ?? 'N/A', Icons.phone),
                            _buildDetailItem('CIN', data['cin'] ?? 'N/A', Icons.credit_card),
                            _buildDetailItem('Adresse', data['adresse'] ?? 'N/A', Icons.location_on),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Informations véhicule
                        _buildModernDetailSection(
                          title: 'Informations Véhicule',
                          icon: Icons.directions_car,
                          color: Colors.green[600]!,
                          items: [
                            _buildDetailItem('Immatriculation', data['immatriculation'] ?? 'N/A', Icons.confirmation_number),
                            _buildDetailItem('Marque & Modèle', '${data['marque'] ?? 'N/A'} ${data['modele'] ?? ''}', Icons.branding_watermark),
                            _buildDetailItem('Année', data['annee'] ?? 'N/A', Icons.calendar_today),
                            _buildDetailItem('Puissance', '${data['puissance'] ?? 'N/A'} CV', Icons.speed),
                            _buildDetailItem('Type véhicule', data['typeVehicule'] ?? 'N/A', Icons.category),
                            _buildDetailItem('Carburant', data['carburant'] ?? 'N/A', Icons.local_gas_station),
                            _buildDetailItem('Usage', data['usage'] ?? 'N/A', Icons.work),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Documents
                        _buildDocumentsSection(data),

                        const SizedBox(height: 24),

                        // Informations assurance
                        _buildModernDetailSection(
                          title: 'Informations Assurance',
                          icon: Icons.security,
                          color: Colors.orange[600]!,
                          items: [
                            _buildDetailItem('Compagnie', data['compagnieNom'] ?? 'N/A', Icons.business),
                            _buildDetailItem('Agence', data['agenceNom'] ?? 'N/A', Icons.store),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Statut et workflow
                        _buildModernDetailSection(
                          title: 'Statut et Workflow',
                          icon: Icons.timeline,
                          color: Colors.purple[600]!,
                          items: [
                            _buildDetailItem('Date création', _formatDate(data['dateCreation']), Icons.schedule),
                            if (data['dateApprobation'] != null)
                              _buildDetailItem('Date approbation', _formatDate(data['dateApprobation']), Icons.check_circle),
                            if (data['dateAffectation'] != null)
                              _buildDetailItem('Date affectation', _formatDate(data['dateAffectation']), Icons.assignment_ind),
                            if (data['agentNom'] != null)
                              _buildDetailItem('Agent affecté', data['agentNom'], Icons.person_pin),
                            if (data['affectationMode'] != null)
                              _buildDetailItem(
                                'Mode affectation',
                                data['affectationMode'] == 'ia_automatique' ? '🤖 IA Automatique' :
                                data['affectationMode'] == 'manuelle' ? '👤 Manuelle' : data['affectationMode'],
                                Icons.smart_toy
                              ),
                          ],
                        ),

                        // Motif de rejet si présent
                        if (data['motifRejet'] != null && data['motifRejet'].toString().isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildModernDetailSection(
                            title: 'Motif de Rejet',
                            icon: Icons.cancel,
                            color: Colors.red[600]!,
                            items: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red[200]!),
                                ),
                                child: Text(
                                  data['motifRejet'].toString(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Commentaires si présents
                        if (data['commentaires'] != null && data['commentaires'].toString().isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildModernDetailSection(
                            title: 'Commentaires',
                            icon: Icons.comment,
                            color: Colors.teal[600]!,
                            items: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Text(
                                  data['commentaires'].toString(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Actions footer
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          label: const Text('Fermer'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey[400]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      if (data['statut'] == 'en_attente') ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showRejectDialog(demandeId);
                            },
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Rejeter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _approuverDemande(demandeId);
                            },
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Approuver'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 🎨 Construire une section moderne de détails
  Widget _buildModernDetailSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenu
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: items,
            ),
          ),
        ],
      ),
    );
  }

  /// 📄 Construire un item de détail
  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📸 Construire la section des documents
  Widget _buildDocumentsSection(Map<String, dynamic> data) {
    // Debug: afficher toutes les clés disponibles pour les images
    print('🖼️ Clés disponibles pour images: ${data.keys.where((key) => key.toLowerCase().contains('url') || key.toLowerCase().contains('image') || key.toLowerCase().contains('carte') || key.toLowerCase().contains('permis') || key.toLowerCase().contains('cin')).toList()}');

    return _buildModernDetailSection(
      title: 'Documents Uploadés',
      icon: Icons.photo_library,
      color: Colors.indigo[600]!,
      items: [
        // CIN
        _buildDocumentGroup(
          'CIN',
          Icons.credit_card,
          Colors.blue[600]!,
          [
            _buildDocumentItem('CIN Recto', _getImageUrl(data, ['carteIdentite', 'cinRectoUrl', 'cin_recto_url', 'documents.carteIdentite'])),
            _buildDocumentItem('CIN Verso', _getImageUrl(data, ['cinVersoUrl', 'cin_verso_url', 'documents.cinVerso'])),
          ],
        ),

        const SizedBox(height: 16),

        // Permis
        _buildDocumentGroup(
          'Permis de Conduire',
          Icons.drive_eta,
          Colors.green[600]!,
          [
            _buildDocumentItem('Permis Recto', _getImageUrl(data, ['permis', 'permisRectoUrl', 'permis_recto_url', 'documents.permis'])),
            _buildDocumentItem('Permis Verso', _getImageUrl(data, ['permisVersoUrl', 'permis_verso_url', 'documents.permisVerso'])),
          ],
        ),

        const SizedBox(height: 16),

        // Carte Grise
        _buildDocumentGroup(
          'Carte Grise',
          Icons.description,
          Colors.orange[600]!,
          [
            _buildDocumentItem('Carte Grise Recto', _getImageUrl(data, ['carteGrise', 'carteGriseRectoUrl', 'carte_grise_recto_url', 'documents.carteGrise'])),
            _buildDocumentItem('Carte Grise Verso', _getImageUrl(data, ['carteGriseVersoUrl', 'carte_grise_verso_url', 'documents.carteGriseVerso'])),
          ],
        ),
      ],
    );
  }

  /// 🔍 Récupérer l'URL d'une image en essayant plusieurs clés possibles
  String? _getImageUrl(Map<String, dynamic> data, List<String> possibleKeys) {
    for (final key in possibleKeys) {
      if (key.contains('.')) {
        // Clé imbriquée (ex: documents.carteIdentite)
        final parts = key.split('.');
        dynamic value = data;
        for (final part in parts) {
          if (value is Map<String, dynamic> && value.containsKey(part)) {
            value = value[part];
          } else {
            value = null;
            break;
          }
        }
        if (value != null && value.toString().isNotEmpty) {
          return value.toString();
        }
      } else {
        // Clé simple
        if (data.containsKey(key) && data[key] != null && data[key].toString().isNotEmpty) {
          return data[key].toString();
        }
      }
    }
    return null;
  }

  /// 📁 Construire un groupe de documents
  Widget _buildDocumentGroup(String title, IconData icon, Color color, List<Widget> documents) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...documents,
        ],
      ),
    );
  }

  /// 📄 Construire un item de document
  Widget _buildDocumentItem(String name, String? url) {
    final hasDocument = url != null && url.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasDocument ? Colors.green[300]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasDocument ? Icons.check_circle : Icons.cancel,
            color: hasDocument ? Colors.green[600] : Colors.grey[400],
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 12,
                color: hasDocument ? Colors.green[700] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (hasDocument)
            GestureDetector(
              onTap: () => _showImageDialog(url),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Voir',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 🖼️ Afficher une image en plein écran
  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error, color: Colors.white, size: 48),
                            const SizedBox(height: 16),
                            const Text(
                              'Impossible de charger l\'image',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 40,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 📅 Formater une date
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return 'N/A';
      }

      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  /// ❌ Afficher le dialogue de rejet avec raison
  Future<void> _showRejectDialog(String demandeId) async {
    final TextEditingController raisonController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.cancel, color: Colors.red[600], size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Rejeter la Demande',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Veuillez indiquer la raison du rejet :',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: raisonController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Ex: Documents incomplets, informations incorrectes...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuler',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final raison = raisonController.text.trim();
                if (raison.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Veuillez indiquer une raison'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop();
                await _rejeterDemandeAvecRaison(demandeId, raison);
              },
              icon: const Icon(Icons.cancel, size: 16),
              label: const Text('Rejeter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// ❌ Rejeter une demande avec raison
  Future<void> _rejeterDemandeAvecRaison(String demandeId, String raison) async {
    try {
      await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .doc(demandeId)
          .update({
        'statut': 'rejetee',
        'dateRejet': FieldValue.serverTimestamp(),
        'rejetePar': widget.agenceData['nom'] ?? 'Admin Agence',
        'motifRejet': raison,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Demande rejetée avec succès'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🎯 Afficher le dialogue de choix d'approbation
  Future<String?> _showApprovalChoiceDialog(Map<String, dynamic> demandeData) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.check_circle, color: Colors.green[600], size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Approuver la Demande',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations de la demande
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 Demande ${demandeData['numero']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('🚗 ${demandeData['marque']} ${demandeData['modele']}'),
                    Text('👤 ${demandeData['prenom']} ${demandeData['nom']}'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Comment souhaitez-vous affecter cette demande ?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              child: const Text('❌ Annuler'),
            ),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop('approve_ai'),
                icon: const Icon(Icons.smart_toy, size: 18),
                label: const Text('🤖 Approuver + Affecter IA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop('approve_manual'),
                icon: const Icon(Icons.person, size: 18),
                label: const Text('👤 Approuver + Choisir Agent'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 👤 Afficher le dialogue d'affectation manuelle simplifié
  Future<void> _showManualAssignmentDialogSimple(
    String demandeId,
    Map<String, dynamic> demandeData,
  ) async {
    try {
      print('🔍 Recherche agents pour agence: ${widget.agenceId}');

      // Chercher dans la collection 'users' d'abord
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('agenceId', isEqualTo: widget.agenceId)
          .where('role', isEqualTo: 'agent')
          .get();

      List<Map<String, dynamic>> agents = [];

      // Ajouter les agents de la collection 'users' et les activer automatiquement
      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        data['source'] = 'users';

        // Activer automatiquement les agents de la collection users
        if (data['statut'] != 'actif') {
          print('🔄 Activation automatique de l\'agent: ${data['prenom']} ${data['nom']}');
          await FirebaseFirestore.instance
              .collection('users')
              .doc(doc.id)
              .update({'statut': 'actif'});
          data['statut'] = 'actif';
        }

        agents.add(data);
        print('👤 Agent trouvé (users): ${data['prenom']} ${data['nom']} - Statut: ${data['statut']}');
      }

      // NE PAS chercher dans 'agents_assurance' car ce sont des agents de test
      print('🚫 Agents de test (agents_assurance) ignorés');

      // Supprimer les agents de test de la base de données
      await _supprimerAgentsDeTest();

      print('📊 Total agents trouvés: ${agents.length}');

      if (agents.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Aucun agent trouvé pour l\'agence ${widget.agenceId}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.person, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text('👤 Choisir un Agent'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Informations de la demande
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📋 Demande ${demandeData['numero']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('🚗 ${demandeData['marque']} ${demandeData['modele']}'),
                        Text('👤 ${demandeData['prenom']} ${demandeData['nom']}'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    '👥 Sélectionner un agent:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Liste des agents
                  ...agents.map((agent) {
                    // Tous les agents sont maintenant actifs
                    final isActif = true;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () async {
                          Navigator.of(context).pop();
                          await _affecterAgentManuel(demandeId, agent);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue.withOpacity(0.2),
                                child: Text(
                                  '${agent['prenom']?[0] ?? ''}${agent['nom']?[0] ?? ''}',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${agent['prenom'] ?? ''} ${agent['nom'] ?? ''}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green[100],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Actif',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.green[700],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      agent['email'] ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (agent['telephone'] != null)
                                      Text(
                                        agent['telephone'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios,
                                   color: Colors.grey[400], size: 16),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
            ],
          );
        },
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 👤 Affecter un agent manuellement
  Future<void> _affecterAgentManuel(String demandeId, Map<String, dynamic> agent) async {
    try {
      await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .doc(demandeId)
          .update({
        'statut': 'affectee',
        'agentId': agent['id'],
        'agentNom': '${agent['prenom']} ${agent['nom']}',
        'agentEmail': agent['email'],
        'dateAffectation': FieldValue.serverTimestamp(),
        'dateApprobation': FieldValue.serverTimestamp(),
        'approuvePar': widget.agenceData['nom'] ?? 'Admin Agence',
        'affectationMode': 'manuelle',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Demande affectée à ${agent['prenom']} ${agent['nom']}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🗑️ Supprimer les agents de test de la base de données
  Future<void> _supprimerAgentsDeTest() async {
    try {
      // Supprimer les agents de test de la collection agents_assurance
      final agentsTestSnapshot = await FirebaseFirestore.instance
          .collection('agents_assurance')
          .where('isTestData', isEqualTo: true)
          .get();

      if (agentsTestSnapshot.docs.isNotEmpty) {
        print('🗑️ Suppression de ${agentsTestSnapshot.docs.length} agents de test...');

        for (final doc in agentsTestSnapshot.docs) {
          await doc.reference.delete();
          final data = doc.data();
          print('🗑️ Agent de test supprimé: ${data['prenom']} ${data['nom']}');
        }

        print('✅ Tous les agents de test ont été supprimés');
      }
    } catch (e) {
      print('❌ Erreur suppression agents de test: $e');
    }
  }
}
