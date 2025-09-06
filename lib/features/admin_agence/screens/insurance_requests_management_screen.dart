import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/intelligent_agent_assignment_service.dart';
import 'intelligent_assignment_screen.dart';

/// 📋 Écran de gestion des demandes d'assurance pour l'admin d'agence
class InsuranceRequestsManagementScreen extends StatefulWidget {
  final String agenceId;

  const InsuranceRequestsManagementScreen({
    Key? key,
    required this.agenceId,
  }) : super(key: key);

  @override
  State<InsuranceRequestsManagementScreen> createState() => _InsuranceRequestsManagementScreenState();
}

class _InsuranceRequestsManagementScreenState extends State<InsuranceRequestsManagementScreen> {
  String _selectedFilter = 'en_attente';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Demandes d\'Assurance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showPerformanceStats(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: _buildRequestsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildFilterTab('en_attente', 'En attente', const Color(0xFFF59E0B)),
          const SizedBox(width: 12),
          _buildFilterTab('affectee', 'Affectées', const Color(0xFF3B82F6)),
          const SizedBox(width: 12),
          _buildFilterTab('approuvee', 'Approuvées', const Color(0xFF10B981)),
          const SizedBox(width: 12),
          _buildFilterTab('rejetee', 'Rejetées', const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String value, String label, Color color) {
    final isSelected = _selectedFilter == value;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('demandes_contrats')
                    .where('agenceId', isEqualTo: widget.agenceId)
                    .where('statut', isEqualTo: value)
                    .snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.grey[700],
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? color : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('demandes_contrats')
          .where('agenceId', isEqualTo: widget.agenceId)
          .where('statut', isEqualTo: _selectedFilter)
          .snapshots()
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            ),
          );
        }

        final requests = snapshot.data?.docs ?? [];

        if (requests.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final doc = requests[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildRequestCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;
    
    switch (_selectedFilter) {
      case 'en_attente':
        message = 'Aucune demande en attente';
        icon = Icons.pending_actions;
        break;
      case 'affectee':
        message = 'Aucune demande affectée';
        icon = Icons.assignment_ind;
        break;
      case 'approuvee':
        message = 'Aucune demande approuvée';
        icon = Icons.check_circle;
        break;
      case 'rejetee':
        message = 'Aucune demande rejetée';
        icon = Icons.cancel;
        break;
      default:
        message = 'Aucune demande';
        icon = Icons.inbox;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les nouvelles demandes apparaîtront ici',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(String id, Map<String, dynamic> data) {
    final conducteur = data['conducteur'] ?? {};
    final vehicule = data['vehicule'] ?? {};
    final statut = data['statut'] ?? 'en_attente';
    final dateCreation = data['dateCreation'] as Timestamp?;
    final assignedAgentId = data['assignedAgentId'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(statut).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getStatusIcon(statut),
                  color: _getStatusColor(statut),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${conducteur['prenom'] ?? ''} ${conducteur['nom'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'CIN: ${conducteur['cin'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(statut),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_car, size: 20, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 8),
                    const Text(
                      'Véhicule à assurer',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${vehicule['marque'] ?? 'N/A'} ${vehicule['modele'] ?? ''} (${vehicule['annee'] ?? 'N/A'})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  'Immatriculation: ${vehicule['immatriculation'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Type: ${vehicule['typeVehicule'] ?? 'N/A'} • ${vehicule['carburant'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Demande créée le ${_formatDate(dateCreation?.toDate())}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          if (assignedAgentId != null) ...[
            const SizedBox(height: 8),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('agents_assurance')
                  .doc(assignedAgentId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final agentData = snapshot.data!.data() as Map<String, dynamic>;
                  return Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Affectée à: ${agentData['prenom']} ${agentData['nom']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
          
          const SizedBox(height: 16),
          
          _buildActionButtons(id, data),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String id, Map<String, dynamic> data) {
    final statut = data['statut'] ?? 'en_attente';

    switch (statut) {
      case 'en_attente':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _rejectRequest(id),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Rejeter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _showAssignmentOptions(id, data),
                icon: const Icon(Icons.assignment_ind, size: 18),
                label: const Text('Approuver & Affecter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        );

      case 'affectee':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showRequestDetails(id, data),
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('Voir détails'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF3B82F6),
                  side: const BorderSide(color: Color(0xFF3B82F6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _reassignRequest(id, data),
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('Réaffecter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        );

      default:
        return OutlinedButton.icon(
          onPressed: () => _showRequestDetails(id, data),
          icon: const Icon(Icons.visibility, size: 18),
          label: const Text('Voir détails'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF3B82F6),
            side: const BorderSide(color: Color(0xFF3B82F6)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
    }
  }

  Widget _buildStatusBadge(String statut) {
    Color color = _getStatusColor(statut);
    String text = _getStatusText(statut);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(String statut) {
    switch (statut.toLowerCase()) {
      case 'en_attente':
        return const Color(0xFFF59E0B);
      case 'affectee':
        return const Color(0xFF3B82F6);
      case 'approuvee':
        return const Color(0xFF10B981);
      case 'rejetee':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String statut) {
    switch (statut.toLowerCase()) {
      case 'en_attente':
        return 'En attente';
      case 'affectee':
        return 'Affectée';
      case 'approuvee':
        return 'Approuvée';
      case 'rejetee':
        return 'Rejetée';
      default:
        return statut;
    }
  }

  IconData _getStatusIcon(String statut) {
    switch (statut.toLowerCase()) {
      case 'en_attente':
        return Icons.pending_actions;
      case 'affectee':
        return Icons.assignment_ind;
      case 'approuvee':
        return Icons.check_circle;
      case 'rejetee':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAssignmentOptions(String requestId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Options d\'affectation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.psychology, color: Color(0xFF8B5CF6)),
              ),
              title: const Text('Affectation Intelligente'),
              subtitle: const Text('L\'IA suggère le meilleur agent'),
              onTap: () {
                Navigator.pop(context);
                _useIntelligentAssignment(requestId, data);
              },
            ),

            const Divider(),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person, color: Color(0xFF3B82F6)),
              ),
              title: const Text('Affectation Manuelle'),
              subtitle: const Text('Choisir un agent manuellement'),
              onTap: () {
                Navigator.pop(context);
                _showManualAssignment(requestId, data);
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _useIntelligentAssignment(String requestId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IntelligentAssignmentScreen(
          agenceId: widget.agenceId,
          demandeData: {'id': requestId, ...data},
        ),
      ),
    ).then((result) {
      if (result != null && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Demande affectée avec succès'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    });
  }

  void _showManualAssignment(String requestId, Map<String, dynamic> data) {
    // TODO: Implémenter l'affectation manuelle
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Affectation manuelle - À implémenter'),
        backgroundColor: Color(0xFF3B82F6),
      ),
    );
  }

  void _reassignRequest(String requestId, Map<String, dynamic> data) {
    _showAssignmentOptions(requestId, data);
  }

  Future<void> _rejectRequest(String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rejeter la demande'),
        content: const Text('Êtes-vous sûr de vouloir rejeter cette demande d\'assurance ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('insurance_requests')
            .doc(requestId)
            .update({
          'statut': 'rejetee',
          'dateRejet': FieldValue.serverTimestamp(),
          'rejectedBy': 'admin_agence', // TODO: Récupérer l'ID de l'admin
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande rejetée avec succès'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du rejet: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRequestDetails(String requestId, Map<String, dynamic> data) {
    // TODO: Implémenter les détails de la demande
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Détails de la demande - À implémenter')),
    );
  }

  void _showPerformanceStats() async {
    try {
      final stats = await IntelligentAgentAssignmentService.getAgencyPerformanceStats(widget.agenceId);

      if (stats['success'] == true) {
        _showStatsDialog(stats);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${stats['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des statistiques: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showStatsDialog(Map<String, dynamic> stats) {
    final agentStats = stats['agentStats'] as List<Map<String, dynamic>>;
    final recommendations = stats['recommendations'] as List<String>;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.analytics,
                      color: Color(0xFF3B82F6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Statistiques de Performance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                'Charge de travail par agent',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: ListView.builder(
                  itemCount: agentStats.length,
                  itemBuilder: (context, index) {
                    final agent = agentStats[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  agent['nom'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                Text(
                                  '${agent['activeContracts']} contrats actifs • ${agent['completedThisMonth']} terminés ce mois',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getWorkloadColor(agent['workloadPercentage']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${agent['workloadPercentage'].toInt()}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getWorkloadColor(agent['workloadPercentage']),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              if (recommendations.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Recommandations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                ...recommendations.map((rec) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: Color(0xFFF59E0B),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rec,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getWorkloadColor(double percentage) {
    if (percentage >= 80) return const Color(0xFFEF4444);
    if (percentage >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }
}
