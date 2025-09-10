import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../conducteur/screens/choix_frequence_paiement_screen.dart';
import '../../../services/paiement_service.dart';
import '../../../services/echeance_notification_service.dart';

/// 👨‍💼 Écran pour l'agent - Gestion des demandes affectées
class AgentRequestsScreen extends StatefulWidget {
  const AgentRequestsScreen({Key? key}) : super(key: key);

  @override
  State<AgentRequestsScreen> createState() => _AgentRequestsScreenState();
}

class _AgentRequestsScreenState extends State<AgentRequestsScreen> {
  String? _currentAgentId;
  String _selectedFilter = 'affectee';

  @override
  void initState() {
    super.initState();
    _getCurrentAgent();
  }

  Future<void> _getCurrentAgent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('🔍 Agent: Recherche agent pour email: ${user.email}');

      // D'abord chercher dans la collection 'users'
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .where('role', isEqualTo: 'agent')
          .limit(1)
          .get();

      if (userDoc.docs.isNotEmpty) {
        if (mounted) setState(() {
          _currentAgentId = userDoc.docs.first.id;
        });
        print('✅ Agent trouvé dans users: $_currentAgentId');

        // Debug: Afficher toutes les demandes pour voir s'il y en a
        await _debugAllDemandes();
        return;
      }

      // Fallback : chercher dans agents_assurance
      final agentDoc = await FirebaseFirestore.instance
          .collection('agents_assurance')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (agentDoc.docs.isNotEmpty) {
        if (mounted) setState(() {
          _currentAgentId = agentDoc.docs.first.id;
        });
        print('✅ Agent trouvé dans agents_assurance: $_currentAgentId');
      } else {
        print('❌ Aucun agent trouvé pour ${user.email}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentAgentId == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Mes Demandes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        centerTitle: true,
        actions: [
          // Bouton notifications agent
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('agentId', isEqualTo: _currentAgentId)
                .snapshots(),
            builder: (context, snapshot) {
              final allNotifications = snapshot.data?.docs ?? [];
              final unreadNotifications = allNotifications.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['agentId'] == _currentAgentId && !(data['lu'] ?? false);
              }).toList();
              final unreadCount = unreadNotifications.length;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () => _showAgentNotifications(),
                    tooltip: 'Notifications',
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.science),
            onPressed: () => _simulerDocumentsCompletes(),
            tooltip: 'Simuler Documents Complétés',
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showMyStats(),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterTab('affectee', 'À traiter', const Color(0xFF3B82F6)),
            const SizedBox(width: 8),
            _buildFilterTab('en_cours', 'En cours', const Color(0xFF8B5CF6)),
            const SizedBox(width: 8),
            _buildFilterTab('documents_manquants', 'Docs ⚠️', const Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            _buildFilterTab('documents_completes', 'Docs ✅', const Color(0xFF10B981)),
            const SizedBox(width: 8),
            _buildFilterTab('frequence_choisie', 'Prêt 💰', const Color(0xFF6366F1)),
            const SizedBox(width: 8),
            _buildFilterTab('contrat_actif', 'Actifs', const Color(0xFF059669)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String value, String label, Color color) {
    final isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                  .where('agentId', isEqualTo: _currentAgentId)
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
    );
  }

  Widget _buildRequestsList() {
    print('🔍 Agent Dashboard: Recherche demandes pour agentId: $_currentAgentId, statut: $_selectedFilter');

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('demandes_contrats')
          .where('agentId', isEqualTo: _currentAgentId)
          .where('statut', isEqualTo: _selectedFilter)
          .snapshots(),
      builder: (context, snapshot) {
        print('📊 Agent Dashboard: Stream builder - hasError: ${snapshot.hasError}, connectionState: ${snapshot.connectionState}');

        if (snapshot.hasError) {
          print('❌ Agent Dashboard: Erreur stream: ${snapshot.error}');
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
        print('📋 Agent Dashboard: ${requests.length} demandes trouvées pour statut $_selectedFilter');

        // Debug: Afficher les détails des demandes trouvées
        for (final doc in requests) {
          final data = doc.data() as Map<String, dynamic>;
          print('  📄 Demande ${doc.id}: agentId=${data['agentId']}, statut=${data['statut']}, numero=${data['numero']}');
        }

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
      case 'affectee':
        message = 'Aucune demande à traiter';
        icon = Icons.assignment;
        break;
      case 'en_cours':
        message = 'Aucune demande en cours de traitement';
        icon = Icons.pending;
        break;
      case 'documents_manquants':
        message = 'Aucun document manquant à traiter';
        icon = Icons.warning;
        break;
      case 'documents_completes':
        message = 'Aucun dossier complet à valider';
        icon = Icons.check_circle_outline;
        break;
      case 'frequence_choisie':
        message = 'Aucun paiement prêt à encaisser';
        icon = Icons.payment;
        break;
      case 'en_attente_paiement':
        message = 'Aucun paiement en attente';
        icon = Icons.schedule;
        break;
      case 'contrat_actif':
        message = 'Aucun contrat actif';
        icon = Icons.verified;
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
    final statut = data['statut'] ?? 'affectee';
    final dateCreation = data['dateCreation'] as Timestamp?;
    final dateAffectation = data['dateAffectation'] as Timestamp?;
    final numero = data['numero'] ?? 'N/A';

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
                      'Demande $numero',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      '${data['prenom'] ?? ''} ${data['nom'] ?? ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${data['marque'] ?? ''} ${data['modele'] ?? ''} - ${data['immatriculation'] ?? ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
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
                  '${data['marque'] ?? 'N/A'} ${data['modele'] ?? ''} (${data['annee'] ?? 'N/A'})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  'Immatriculation: ${data['immatriculation'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Type: ${data['typeVehicule'] ?? 'N/A'} • ${data['carburant'] ?? 'N/A'}',
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
                'Affectée le ${_formatDate(dateAffectation?.toDate())}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildActionButtons(id, data),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String id, Map<String, dynamic> data) {
    final statut = data['statut'] ?? 'affectee';

    switch (statut) {
      case 'affectee':
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewRequestDetails(id, data),
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
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _markDocumentsIncomplete(id, data),
                    icon: const Icon(Icons.warning, size: 18),
                    label: const Text('Docs manquants'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF59E0B),
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _marquerDocumentsCompletes(id, data),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('✅ Documents OK'),
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
            ),
          ],
        );

      case 'en_cours':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _viewRequestDetails(id, data),
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
                onPressed: () => _marquerDocumentsCompletes(id, data),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Valider'),
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

      case 'frequence_choisie':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _viewRequestDetails(id, data),
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
                onPressed: () => _encaisserPaiement(id, data),
                icon: const Icon(Icons.payment, size: 18),
                label: const Text('💰 Encaisser'),
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

      case 'en_attente_paiement':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _viewRequestDetails(id, data),
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
                onPressed: () => _validatePayment(id, data),
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text('Valider Paiement'),
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

      default:
        return OutlinedButton.icon(
          onPressed: () => _viewRequestDetails(id, data),
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
      case 'affectee':
        return const Color(0xFF3B82F6);
      case 'documents_manquants':
        return const Color(0xFFF59E0B);
      case 'en_cours':
        return const Color(0xFF8B5CF6);
      case 'paiement_propose':
        return const Color(0xFF3B82F6);
      case 'en_attente_paiement':
        return const Color(0xFF10B981);
      case 'contrat_actif':
        return const Color(0xFF059669);
      case 'contrat_valide':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String statut) {
    switch (statut.toLowerCase()) {
      case 'affectee':
        return 'À traiter';
      case 'documents_manquants':
        return 'Docs manquants';
      case 'en_cours':
        return 'En cours';
      case 'paiement_propose':
        return 'Paiement proposé';
      case 'en_attente_paiement':
        return 'Attente paiement';
      case 'contrat_actif':
        return 'Contrat actif';
      case 'contrat_valide':
        return 'Terminé';
      default:
        return statut;
    }
  }

  IconData _getStatusIcon(String statut) {
    switch (statut.toLowerCase()) {
      case 'affectee':
        return Icons.assignment;
      case 'documents_manquants':
        return Icons.warning;
      case 'en_cours':
        return Icons.pending;
      case 'paiement_propose':
        return Icons.payment;
      case 'en_attente_paiement':
        return Icons.schedule;
      case 'contrat_actif':
        return Icons.verified;
      case 'contrat_valide':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _finalizeRequest(String requestId, Map<String, dynamic> data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Finaliser la demande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confirmer que tous les documents ont été vérifiés et que le contrat est prêt ?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Le conducteur sera notifié pour prendre rendez-vous à l\'agence.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('Finaliser'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Mettre à jour le statut de la demande
        await FirebaseFirestore.instance
            .collection('demandes_contrats')
            .doc(requestId)
            .update({
          'statut': 'contrat_valide',
          'dateTraitement': FieldValue.serverTimestamp(),
          'traitePar': _currentAgentId,
        });

        // Créer une notification pour le conducteur
        await FirebaseFirestore.instance
            .collection('notifications')
            .add({
          'conducteurId': data['conducteurId'],
          'conducteurEmail': data['email'],
          'type': 'contrat_valide',
          'titre': 'Contrat d\'assurance validé',
          'message': 'Votre contrat d\'assurance a été validé. Prenez rendez-vous à l\'agence pour finaliser.',
          'demandeId': requestId,
          'lu': false,
          'dateCreation': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande finalisée avec succès. Le conducteur a été notifié.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la finalisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewRequestDetails(String requestId, Map<String, dynamic> data) {
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
                      Icons.assignment,
                      color: Color(0xFF3B82F6),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Détails de la demande',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection('Conducteur', [
                        _buildDetailRow('Nom', '${data['prenom'] ?? 'N/A'} ${data['nom'] ?? 'N/A'}'),
                        _buildDetailRow('CIN', data['cin'] ?? 'N/A'),
                        _buildDetailRow('Téléphone', data['telephone'] ?? 'N/A'),
                        _buildDetailRow('Email', data['email'] ?? 'N/A'),
                        _buildDetailRow('Adresse', data['adresse'] ?? 'N/A'),
                      ]),

                      const SizedBox(height: 20),

                      _buildDetailSection('Véhicule', [
                        _buildDetailRow('Marque/Modèle', '${data['marque'] ?? 'N/A'} ${data['modele'] ?? 'N/A'}'),
                        _buildDetailRow('Immatriculation', data['immatriculation'] ?? 'N/A'),
                        _buildDetailRow('Année', data['annee'] ?? 'N/A'),
                        _buildDetailRow('Puissance', '${data['puissance'] ?? 'N/A'} CV'),
                        _buildDetailRow('Type', data['typeVehicule'] ?? 'N/A'),
                        _buildDetailRow('Carburant', data['carburant'] ?? 'N/A'),
                        _buildDetailRow('Usage', data['usage'] ?? 'N/A'),
                      ]),

                      const SizedBox(height: 20),

                      _buildDetailSection('Formule d\'Assurance', [
                        _buildDetailRow('Formule', data['formuleAssuranceLabel'] ?? data['formuleAssurance'] ?? 'N/A'),
                        _buildDetailRow('Compagnie', data['compagnieNom'] ?? 'N/A'),
                        _buildDetailRow('Agence', data['agenceNom'] ?? 'N/A'),
                      ]),

                      const SizedBox(height: 20),

                      _buildDocumentsSection(data, requestId),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Boutons d'action selon le statut
              Column(
                children: [
                  // Boutons spécifiques selon le statut
                  if (data['statut'] == 'documents_completes') ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _validerDossierComplet(context, requestId);
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('✅ Valider Dossier Complet'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _demanderDocumentsSupplementaires(context, requestId);
                        },
                        icon: const Icon(Icons.assignment_late),
                        label: const Text('📋 Demander Documents Supplémentaires'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (data['statut'] == 'en_attente_paiement') ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _ouvrirChoixFrequencePaiement(context, requestId, data);
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('⚙️ Configurer Fréquence Paiement'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (data['statut'] == 'frequence_choisie') ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _encaisserPaiement(requestId, data);
                        },
                        icon: const Icon(Icons.payment),
                        label: const Text('💰 Encaisser Paiement'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Boutons génériques
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Fermer'),
                        ),
                      ),
                      if (data['statut'] == 'affectee') ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _marquerDocumentsCompletes(requestId, data);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Valider Documents'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(Map<String, dynamic> data, String requestId) {
    // Mapping des champs d'images dans les données
    final documentsMap = {
      'cinRectoUrl': 'CIN Recto',
      'cinVersoUrl': 'CIN Verso',
      'permisRectoUrl': 'Permis Recto',
      'permisVersoUrl': 'Permis Verso',
      'carteGriseRectoUrl': 'Carte Grise Recto',
      'carteGriseVersoUrl': 'Carte Grise Verso',
    };

    // Filtrer seulement les documents qui ont une URL
    final availableDocuments = documentsMap.entries
        .where((entry) => data[entry.key] != null && data[entry.key].toString().isNotEmpty)
        .toList();

    if (availableDocuments.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Documents',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[400]),
                const SizedBox(width: 8),
                Text(
                  'Aucun document uploadé',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Documents',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: availableDocuments.map((entry) {
              final urlKey = entry.key;
              final label = entry.value;
              final url = data[urlKey];

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.image,
                      color: url != null ? const Color(0xFF3B82F6) : Colors.grey[400],
                      size: 20
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: url != null ? Colors.green[100] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        url != null ? 'Disponible' : 'Manquant',
                        style: TextStyle(
                          fontSize: 10,
                          color: url != null ? Colors.green[700] : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: url != null ? () => _viewDocument(urlKey, url, demandeId: requestId, demandeData: data) : null,
                      child: const Text('Voir'),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// 📷 Afficher un document/image
  void _viewDocument(String documentType, dynamic documentUrl, {String? demandeId, Map<String, dynamic>? demandeData}) {
    if (documentUrl == null || documentUrl.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Aucune image disponible pour ce document'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // En-tête
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.image, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getDocumentLabel(documentType),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // Image
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildImageWidget(documentUrl.toString()),
                    ),
                  ),
                ),

                // Bouton fermer
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Fermer'),
                      ),
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

  String _getDocumentLabel(String key) {
    switch (key) {
      case 'cinRectoUrl':
        return 'CIN Recto';
      case 'cinVersoUrl':
        return 'CIN Verso';
      case 'permisRectoUrl':
        return 'Permis Recto';
      case 'permisVersoUrl':
        return 'Permis Verso';
      case 'carteGriseRectoUrl':
        return 'Carte Grise Recto';
      case 'carteGriseVersoUrl':
        return 'Carte Grise Verso';
      // Anciens formats pour compatibilité
      case 'cin_recto':
        return 'CIN Recto';
      case 'cin_verso':
        return 'CIN Verso';
      case 'permis_recto':
        return 'Permis Recto';
      case 'permis_verso':
        return 'Permis Verso';
      case 'carte_grise':
        return 'Carte Grise';
      default:
        return key;
    }
  }

  void _showMyStats() {
    // TODO: Implémenter les statistiques de l'agent
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Statistiques de l\'agent - À implémenter')),
    );
  }

  /// 📋 Marquer les documents comme manquants
  Future<void> _markDocumentsIncomplete(String requestId, Map<String, dynamic> data) async {
    final List<String> documentsTypes = [
      'CIN Recto',
      'CIN Verso',
      'Permis Recto',
      'Permis Verso',
      'Carte Grise Recto',
      'Carte Grise Verso',
    ];

    List<String> selectedDocuments = [];

    final result = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Documents Manquants',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sélectionnez les documents manquants ou illisibles :',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...documentsTypes.map((doc) {
                      final isSelected = selectedDocuments.contains(doc);
                      return CheckboxListTile(
                        title: Text(doc),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedDocuments.add(doc);
                            } else {
                              selectedDocuments.remove(doc);
                            }
                          });
                        },
                        activeColor: Colors.orange[700],
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selectedDocuments.isEmpty
                          ? null
                          : () => Navigator.of(context).pop(selectedDocuments),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                        ),
                        child: const Text('Notifier le conducteur'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        child: const Text('Annuler'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      try {
        // Mettre à jour le statut de la demande
        await FirebaseFirestore.instance
            .collection('demandes_contrats')
            .doc(requestId)
            .update({
          'statut': 'documents_manquants',
          'documentsManquants': result,
          'dateDocumentsManquants': FieldValue.serverTimestamp(),
          'agentCommentaire': 'Documents manquants ou illisibles',
        });

        // Créer une notification pour le conducteur
        await FirebaseFirestore.instance
            .collection('notifications')
            .add({
          'conducteurId': data['conducteurId'],
          'conducteurEmail': data['email'],
          'type': 'documents_manquants',
          'titre': 'Documents manquants',
          'message': 'Votre demande ${data['numero']} nécessite des documents supplémentaires : ${result.join(', ')}',
          'demandeId': requestId,
          'documentsManquants': result,
          'dateCreation': FieldValue.serverTimestamp(),
          'lu': false,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Notification envoyée au conducteur pour ${result.length} document(s)'),
            backgroundColor: Colors.orange[700],
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
  }

  /// 💳 Proposer le paiement au conducteur
  Future<void> _proposePayment(String requestId, Map<String, dynamic> data) async {
    try {
      // Mettre à jour le statut pour proposer le paiement
      await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .doc(requestId)
          .update({
        'statut': 'paiement_propose',
        'datePropositionPaiement': FieldValue.serverTimestamp(),
      });

      // Créer notification pour le conducteur
      await FirebaseFirestore.instance
          .collection('notifications')
          .add({
        'conducteurId': data['conducteurId'],
        'conducteurEmail': data['email'],
        'type': 'paiement_propose',
        'titre': 'Paiement proposé',
        'message': 'Votre dossier est validé ! Vous pouvez maintenant choisir votre mode de paiement et finaliser votre contrat.',
        'demandeId': requestId,
        'dateCreation': FieldValue.serverTimestamp(),
        'lu': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Proposition de paiement envoyée au conducteur'),
          backgroundColor: Colors.green,
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

  /// ✅ Valider le paiement effectué en agence
  Future<void> _validatePayment(String requestId, Map<String, dynamic> data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.payment, color: Colors.green[700]),
              const SizedBox(width: 8),
              const Text('Valider le Paiement'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Confirmer que le paiement a été effectué en agence pour :'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📋 Demande ${data['numero']}'),
                    Text('👤 ${data['prenom']} ${data['nom']}'),
                    Text('🚗 ${data['marque']} ${data['modele']}'),
                    if (data['montantParPaiement'] != null)
                      Text('💰 Montant: ${data['montantParPaiement'].toStringAsFixed(0)} DT'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
              ),
              child: const Text('✅ Confirmer Paiement'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        // Générer les dates du contrat
        final now = DateTime.now();
        final dateDebut = now;
        final dateFin = DateTime(now.year + 1, now.month, now.day);

        // Récupérer les informations financières existantes
        final demandeDoc = await FirebaseFirestore.instance
            .collection('demandes_contrats')
            .doc(requestId)
            .get();

        final demandeData = demandeDoc.data()!;

        // Mettre à jour le statut vers contrat actif en préservant les informations financières
        await FirebaseFirestore.instance
            .collection('demandes_contrats')
            .doc(requestId)
            .update({
          'statut': 'contrat_actif',
          'datePaiementValide': FieldValue.serverTimestamp(),
          'dateDebutContrat': Timestamp.fromDate(dateDebut),
          'dateFinContrat': Timestamp.fromDate(dateFin),
          'contratActif': true,
          'datePaiement': FieldValue.serverTimestamp(),
          'agentEncaissement': _currentAgentId,
          // Préserver les informations financières si elles existent
          if (demandeData['primeAnnuelle'] != null) 'primeAnnuelle': demandeData['primeAnnuelle'],
          if (demandeData['franchise'] != null) 'franchise': demandeData['franchise'],
          if (demandeData['montantAPayer'] != null) 'montantAPayer': demandeData['montantAPayer'],
          if (demandeData['frequencePaiement'] != null) 'frequencePaiement': demandeData['frequencePaiement'],
        });

        // Créer le contrat dans une collection séparée
        await FirebaseFirestore.instance
            .collection('contrats')
            .add({
          'demandeId': requestId,
          'conducteurId': data['conducteurId'],
          'conducteurEmail': data['email'],
          'numeroContrat': 'CTR-${DateTime.now().millisecondsSinceEpoch}',
          'vehicule': {
            'marque': data['marque'],
            'modele': data['modele'],
            'immatriculation': data['immatriculation'],
            'annee': data['annee'],
          },
          'formuleAssurance': data['formuleAssurance'],
          'formuleAssuranceLabel': data['formuleAssuranceLabel'],
          'compagnieId': data['compagnieId'],
          'compagnieNom': data['compagnieNom'],
          'agenceId': data['agenceId'],
          'agenceNom': data['agenceNom'],
          'agentId': data['agentId'],
          'montantTotal': data['montantTotal'],
          'frequencePaiement': data['frequencePaiement'],
          'dateDebut': Timestamp.fromDate(dateDebut),
          'dateFin': Timestamp.fromDate(dateFin),
          'statut': 'actif',
          'dateCreation': FieldValue.serverTimestamp(),
        });

        // Notification au conducteur
        await FirebaseFirestore.instance
            .collection('notifications')
            .add({
          'conducteurId': data['conducteurId'],
          'conducteurEmail': data['email'],
          'type': 'contrat_actif',
          'titre': 'Contrat activé !',
          'message': 'Félicitations ! Votre contrat d\'assurance est maintenant actif. Vous pouvez télécharger votre attestation et carte verte.',
          'demandeId': requestId,
          'dateCreation': FieldValue.serverTimestamp(),
          'lu': false,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Paiement validé ! Contrat activé avec succès.'),
            backgroundColor: Colors.green,
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
  }

  /// 🔔 Afficher les notifications de l'agent
  void _showAgentNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '🔔 Mes Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Liste des notifications
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('agentId', isEqualTo: _currentAgentId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final notifications = snapshot.data?.docs ?? [];

                  // Debug: Afficher les notifications reçues
                  print('🔔 Agent $_currentAgentId: ${notifications.length} notifications totales');
                  for (final doc in notifications) {
                    final data = doc.data() as Map<String, dynamic>;
                    print('  - ${data['type']}: ${data['titre']} (agentId: ${data['agentId']})');
                  }

                  // Filtrer et trier par date
                  final filteredNotifications = notifications.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['agentId'] == _currentAgentId;
                  }).toList();

                  print('🎯 Notifications filtrées pour agent $_currentAgentId: ${filteredNotifications.length}');

                  filteredNotifications.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aDate = aData['dateCreation'] as Timestamp?;
                    final bDate = bData['dateCreation'] as Timestamp?;

                    if (aDate == null && bDate == null) return 0;
                    if (aDate == null) return 1;
                    if (bDate == null) return -1;

                    return bDate.compareTo(aDate);
                  });

                  if (filteredNotifications.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Aucune notification', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = filteredNotifications[index];
                      final data = notification.data() as Map<String, dynamic>;

                      return _buildAgentNotificationCard(notification.id, data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentNotificationCard(String notificationId, Map<String, dynamic> data) {
    final isRead = data['lu'] ?? false;
    final type = data['type'] ?? '';
    final titre = data['titre'] ?? 'Notification';
    final message = data['message'] ?? '';
    final dateCreation = data['dateCreation'] as Timestamp?;

    Color cardColor;
    IconData icon;
    Color iconColor;

    switch (type) {
      case 'documents_completes':
        cardColor = Colors.green[50]!;
        icon = Icons.check_circle;
        iconColor = Colors.green[700]!;
        break;
      case 'nouvelle_demande':
        cardColor = Colors.blue[50]!;
        icon = Icons.assignment;
        iconColor = Colors.blue[700]!;
        break;
      default:
        cardColor = Colors.grey[50]!;
        icon = Icons.info;
        iconColor = Colors.grey[700]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _handleAgentNotificationTap(notificationId, data),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRead ? Colors.grey[300]! : iconColor.withOpacity(0.3),
              width: isRead ? 1 : 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titre,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isRead ? Colors.grey[700] : Colors.black87,
                          ),
                        ),
                        if (dateCreation != null)
                          Text(
                            _formatNotificationDate(dateCreation),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: isRead ? Colors.grey[600] : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAgentNotificationTap(String notificationId, Map<String, dynamic> data) async {
    // Marquer comme lu
    if (!(data['lu'] ?? false)) {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'lu': true});
    }

    // Navigation selon le type de notification
    final type = data['type'] ?? '';
    final demandeId = data['demandeId'];

    switch (type) {
      case 'documents_completes':
        // Naviguer vers l'onglet "Docs ✅"
        setState(() => _selectedFilter = 'documents_completes');
        if (demandeId != null) {
          // Optionnel : ouvrir directement les détails
          final demandeDoc = await FirebaseFirestore.instance
              .collection('demandes_contrats')
              .doc(demandeId)
              .get();
          if (demandeDoc.exists) {
            _viewRequestDetails(demandeId, demandeDoc.data()!);
          }
        }
        break;

      case 'frequence_choisie':
        // Naviguer vers l'onglet "Prêt 💰"
        setState(() => _selectedFilter = 'frequence_choisie');
        if (demandeId != null) {
          final demandeDoc = await FirebaseFirestore.instance
              .collection('demandes_contrats')
              .doc(demandeId)
              .get();
          if (demandeDoc.exists) {
            _viewRequestDetails(demandeId, demandeDoc.data()!);
          }
        }
        break;

      default:
        // Pour les autres types, juste naviguer vers l'onglet approprié
        setState(() => _selectedFilter = 'affectee');
        break;
    }
  }

  String _formatNotificationDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  /// 🖼️ Construire le widget d'affichage d'image (local ou réseau)
  Widget _buildImageWidget(String imageUrl) {
    // Vérifier si c'est une image locale
    if (imageUrl.startsWith('file://')) {
      final localPath = imageUrl.substring(7); // Enlever 'file://'
      final file = File(localPath);

      return Container(
        height: 300,
        width: double.infinity,
        child: Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Erreur chargement image locale: $error');
            return _buildDocumentPlaceholder('Image locale non trouvée');
          },
        ),
      );
    }

    // Image réseau
    return Container(
      height: 300,
      width: double.infinity,
      child: Image.network(
        imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('❌ Erreur chargement image réseau: $error');
          print('🔗 URL: $imageUrl');
          return _buildDocumentPlaceholder('Document reçu du conducteur');
        },
      ),
    );
  }

  /// 📄 Widget placeholder pour les documents
  Widget _buildDocumentPlaceholder(String message) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.description,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '📄 $message',
            style: TextStyle(
              color: Colors.blue[700],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Document disponible',
            style: TextStyle(
              color: Colors.blue[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '✅ Reçu avec succès',
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🧪 Tester les notifications agent
  Future<void> _testNotifications() async {
    try {
      print('🧪 Test notifications pour agent $_currentAgentId');

      // Créer une notification de test
      await FirebaseFirestore.instance.collection('notifications').add({
        'agentId': _currentAgentId,
        'type': 'test',
        'titre': 'Test Notification',
        'message': 'Ceci est une notification de test pour vérifier que le système fonctionne.',
        'dateCreation': FieldValue.serverTimestamp(),
        'lu': false,
      });

      // Vérifier les notifications existantes
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('agentId', isEqualTo: _currentAgentId)
          .get();

      print('📊 Total notifications pour agent $_currentAgentId: ${notifications.docs.length}');

      for (final doc in notifications.docs) {
        final data = doc.data();
        print('  - ${data['type']}: ${data['titre']} (lu: ${data['lu']})');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🧪 Test créé ! ${notifications.docs.length} notifications trouvées.'),
          backgroundColor: Colors.blue,
        ),
      );

    } catch (e) {
      print('❌ Erreur test notifications: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// ✅ Valider que le dossier est complet et passer au paiement
  Future<void> _validerDossierComplet(BuildContext context, String demandeId) async {
    try {
      print('✅ Validation dossier complet pour demande $demandeId');

      // Récupérer les infos de la demande
      final demandeDoc = await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .doc(demandeId)
          .get();

      if (!demandeDoc.exists) {
        throw Exception('Demande non trouvée');
      }

      final data = demandeDoc.data()!;
      final conducteurId = data['conducteurId'];
      final numeroContrat = data['numeroContrat'] ?? demandeId;

      // Afficher le dialogue pour saisir les informations financières
      final informationsFinancieres = await _afficherDialogueInformationsFinancieres(context, data);

      if (informationsFinancieres == null) {
        // L'agent a annulé
        return;
      }

      // Mettre à jour le statut avec les informations financières
      await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .doc(demandeId)
          .update({
        'statut': 'en_attente_paiement',
        'dateValidation': FieldValue.serverTimestamp(),
        'agentValidateur': _currentAgentId,
        // Ajouter les informations financières
        'primeAnnuelle': informationsFinancieres['primeAnnuelle'],
        'franchise': informationsFinancieres['franchise'],
        'montantAPayer': informationsFinancieres['montantAPayer'],
        'frequencePaiement': informationsFinancieres['frequencePaiement'],
        'informationsFinancieresDefinies': true,
      });

      // Créer notification pour le conducteur
      await FirebaseFirestore.instance.collection('notifications').add({
        'conducteurId': conducteurId,
        'type': 'paiement_requis',
        'titre': 'Dossier Validé - Paiement Requis',
        'message': 'Votre dossier est complet ! Merci de vous présenter à l\'agence pour choisir votre fréquence de paiement et effectuer le premier paiement.',
        'demandeId': demandeId,
        'numeroContrat': numeroContrat,
        'dateCreation': FieldValue.serverTimestamp(),
        'lu': false,
        'priorite': 'haute',
      });

      print('✅ Notification paiement envoyée au conducteur $conducteurId');

      // Afficher le message AVANT de fermer le dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Dossier validé ! Le conducteur peut maintenant choisir sa fréquence de paiement.'),
          backgroundColor: Colors.green,
        ),
      );

      // Fermer le dialog après un petit délai
      await Future.delayed(const Duration(milliseconds: 500));
      if (context.mounted) {
        Navigator.of(context).pop();
      }

    } catch (e) {
      print('❌ Erreur validation dossier: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 📋 Demander des documents supplémentaires
  Future<void> _demanderDocumentsSupplementaires(BuildContext context, String demandeId) async {
    try {
      print('📋 Demande documents supplémentaires pour: $demandeId');

      // Remettre au statut documents manquants
      await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .doc(demandeId)
          .update({
        'statut': 'documents_manquants',
        'dateRetourDocuments': FieldValue.serverTimestamp(),
        'agentRetour': _currentAgentId,
      });

      // Afficher un message de confirmation AVANT de fermer
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📋 Demande remise en attente de documents. Le conducteur sera notifié.'),
          backgroundColor: Colors.orange,
        ),
      );

      print('✅ Statut mis à jour vers documents_manquants');

      // Fermer le dialog après un petit délai
      await Future.delayed(const Duration(milliseconds: 500));
      if (context.mounted) {
        Navigator.of(context).pop();
      }

    } catch (e) {
      print('❌ Erreur demande documents: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 💰 Confirmer le paiement reçu
  Future<void> _confirmerPaiement(BuildContext context, String demandeId) async {
    try {
      print('💰 Confirmation paiement pour demande $demandeId');

      // Mettre à jour le statut
      await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .doc(demandeId)
          .update({
        'statut': 'paye',
        'datePaiement': FieldValue.serverTimestamp(),
        'agentPaiement': _currentAgentId,
      });

      // Récupérer les infos pour la notification
      final demandeDoc = await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .doc(demandeId)
          .get();

      if (demandeDoc.exists) {
        final data = demandeDoc.data()!;
        final conducteurId = data['conducteurId'];
        final numeroContrat = data['numeroContrat'] ?? demandeId;

        // Notification paiement confirmé
        await FirebaseFirestore.instance.collection('notifications').add({
          'conducteurId': conducteurId,
          'type': 'paiement_confirme',
          'titre': 'Paiement Confirmé',
          'message': 'Votre paiement a été confirmé ! Votre contrat sera activé sous peu. Vous recevrez votre attestation d\'assurance.',
          'demandeId': demandeId,
          'numeroContrat': numeroContrat,
          'dateCreation': FieldValue.serverTimestamp(),
          'lu': false,
          'priorite': 'haute',
        });

        print('✅ Notification paiement confirmé envoyée');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💰 Paiement confirmé ! Vous pouvez maintenant activer le contrat.'),
          backgroundColor: Colors.blue,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (context.mounted) {
        Navigator.of(context).pop();
      }

    } catch (e) {
      print('❌ Erreur confirmation paiement: $e');
    }
  }

  /// 🎯 Activer le contrat définitivement
  Future<void> _activerContrat(BuildContext context, String demandeId) async {
    try {
      print('🎯 Activation contrat pour demande $demandeId');

      final dateDebut = DateTime.now();
      final dateFin = DateTime(dateDebut.year + 1, dateDebut.month, dateDebut.day);

      // Récupérer les informations existantes avant la mise à jour
      final demandeDocBefore = await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .doc(demandeId)
          .get();

      final demandeDataBefore = demandeDocBefore.data()!;

      // Mettre à jour le statut en préservant les informations financières
      await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .doc(demandeId)
          .update({
        'statut': 'contrat_actif',
        'dateActivation': FieldValue.serverTimestamp(),
        'dateDebutContrat': Timestamp.fromDate(dateDebut),
        'dateFinContrat': Timestamp.fromDate(dateFin),
        'agentActivation': _currentAgentId,
        'contratActif': true,
        // Préserver les informations financières si elles existent
        if (demandeDataBefore['primeAnnuelle'] != null) 'primeAnnuelle': demandeDataBefore['primeAnnuelle'],
        if (demandeDataBefore['franchise'] != null) 'franchise': demandeDataBefore['franchise'],
        if (demandeDataBefore['montantAPayer'] != null) 'montantAPayer': demandeDataBefore['montantAPayer'],
        if (demandeDataBefore['frequencePaiement'] != null) 'frequencePaiement': demandeDataBefore['frequencePaiement'],
      });

      // Récupérer les infos pour la notification
      final demandeDoc = await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .doc(demandeId)
          .get();

      if (demandeDoc.exists) {
        final data = demandeDoc.data()!;
        final conducteurId = data['conducteurId'];
        final numeroContrat = data['numeroContrat'] ?? demandeId;

        // Notification contrat activé avec informations de validité
        await FirebaseFirestore.instance.collection('notifications').add({
          'conducteurId': conducteurId,
          'type': 'contrat_active',
          'titre': 'Contrat Activé !',
          'message': 'Félicitations ! Votre contrat d\'assurance est maintenant actif.\n\n📅 Validité: du ${DateFormat('dd/MM/yyyy').format(dateDebut)} au ${DateFormat('dd/MM/yyyy').format(dateFin)}\n🚗 Véhicule: ${data['marque']} ${data['modele']}\n📋 N° Contrat: $numeroContrat\n\nVous pouvez maintenant consulter votre contrat et télécharger votre attestation.',
          'demandeId': demandeId,
          'numeroContrat': numeroContrat,
          'dateCreation': FieldValue.serverTimestamp(),
          'lu': false,
          'priorite': 'haute',
          // Ajouter les informations de validité pour un accès facile
          'validiteDebut': DateFormat('dd/MM/yyyy').format(dateDebut),
          'validiteFin': DateFormat('dd/MM/yyyy').format(dateFin),
          'vehiculeInfo': '${data['marque']} ${data['modele']}',
        });

        print('✅ Notification contrat activé envoyée');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎯 Contrat activé avec succès ! Valable 1 an.'),
          backgroundColor: Colors.purple,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (context.mounted) {
        Navigator.of(context).pop();
      }

    } catch (e) {
      print('❌ Erreur activation contrat: $e');
    }
  }

  /// ⚙️ Ouvrir l'interface de choix de fréquence de paiement
  Future<void> _ouvrirChoixFrequencePaiement(BuildContext context, String demandeId, Map<String, dynamic> demandeData) async {
    try {
      // Naviguer vers l'écran de choix de fréquence
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChoixFrequencePaiementScreen(
            demandeId: demandeId,
            conducteurId: demandeData['conducteurId'] ?? '',
            numeroContrat: demandeData['numeroContrat'] ?? demandeId,
            demandeData: demandeData,
          ),
        ),
      );

      if (result == true) {
        // Rafraîchir l'interface si nécessaire
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('❌ Erreur ouverture choix fréquence: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🧪 Simuler des documents complétés (pour test)
  Future<void> _simulerDocumentsCompletes() async {
    try {
      // Récupérer une demande "affectee" pour la transformer
      final demandesQuery = await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .where('agentId', isEqualTo: _currentAgentId)
          .where('statut', isEqualTo: 'affectee')
          .limit(1)
          .get();

      if (demandesQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Aucune demande "affectee" trouvée pour simulation'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final demandeDoc = demandesQuery.docs.first;

      // Mettre à jour le statut
      await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .doc(demandeDoc.id)
          .update({
        'statut': 'documents_completes',
        'dateDocumentsCompletes': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🧪 Demande ${demandeDoc.id} simulée avec documents complétés !'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Voir',
            textColor: Colors.white,
            onPressed: () {
              setState(() => _selectedFilter = 'documents_completes');
            },
          ),
        ),
      );

    } catch (e) {
      print('❌ Erreur simulation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// ✅ Marquer les documents comme complétés
  Future<void> _marquerDocumentsCompletes(String requestId, Map<String, dynamic> data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 24),
            const SizedBox(width: 12),
            const Text('Documents Complétés'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirmer que tous les documents requis ont été reçus et vérifiés pour :',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${data['prenom'] ?? ''} ${data['nom'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${data['marque'] ?? ''} ${data['modele'] ?? ''} - ${data['immatriculation'] ?? ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Le dossier passera au statut "Documents OK" et sera prêt pour validation.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Confirmer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Mettre à jour le statut de la demande
        await FirebaseFirestore.instance
            .collection('demandes_contrats')
            .doc(requestId)
            .update({
          'statut': 'documents_completes',
          'dateDocumentsCompletes': FieldValue.serverTimestamp(),
          'agentDocuments': _currentAgentId,
        });

        // Créer une notification pour l'agent (pour suivi)
        await FirebaseFirestore.instance
            .collection('notifications')
            .add({
          'agentId': _currentAgentId,
          'type': 'documents_completes',
          'titre': 'Documents Complétés',
          'message': 'Dossier ${data['numero'] ?? requestId} prêt pour validation et paiement.',
          'demandeId': requestId,
          'lu': false,
          'dateCreation': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Documents marqués comme complétés ! Le dossier est prêt pour validation.'),
            backgroundColor: Colors.green,
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
  }

  /// 💰 Encaisser le paiement (pour statut frequence_choisie)
  Future<void> _encaisserPaiement(String requestId, Map<String, dynamic> data) async {
    try {
      // Récupérer le paiement associé
      final paiementId = data['paiementId'];
      if (paiementId == null) {
        throw Exception('Aucun paiement associé trouvé');
      }

      // Récupérer les détails du paiement
      final paiementDoc = await FirebaseFirestore.instance
          .collection('paiements')
          .doc(paiementId)
          .get();

      if (!paiementDoc.exists) {
        throw Exception('Paiement non trouvé');
      }

      final paiementData = paiementDoc.data()!;
      final montant = paiementData['montant'].toDouble();
      final frequence = paiementData['frequencePaiement'];

      // Ouvrir l'interface de validation de paiement
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => _buildPaiementDialog(requestId, data, montant, frequence),
      );

      if (result == true) {
        // Rafraîchir la liste
        if (mounted) setState(() {});
      }
    } catch (e) {
      print('❌ Erreur encaissement: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 💳 Dialog de validation de paiement
  Widget _buildPaiementDialog(String requestId, Map<String, dynamic> data, double montant, String frequence) {
    String modePaiement = 'especes';
    final montantController = TextEditingController(text: montant.toStringAsFixed(2));

    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.payment, color: Colors.green[600], size: 24),
            const SizedBox(width: 12),
            const Text('Encaisser le Paiement'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Infos conducteur
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data['prenom'] ?? ''} ${data['nom'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('CIN: ${data['cin'] ?? 'N/A'}'),
                    Text('Fréquence: ${_getFrequenceLabel(frequence)}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Montant
              TextFormField(
                controller: montantController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Montant reçu (DT)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Mode de paiement
              const Text('Mode de paiement:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...['especes', 'carte_bancaire', 'cheque'].map((mode) => RadioListTile<String>(
                value: mode,
                groupValue: modePaiement,
                onChanged: (value) => setState(() => modePaiement = value!),
                title: Text(_getModePaiementLabel(mode)),
              )).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final montantRecu = double.parse(montantController.text);

                // Valider le paiement
                final success = await PaiementService.validerPaiement(
                  paiementId: data['paiementId'],
                  agentId: _currentAgentId!,
                  modePaiement: modePaiement,
                  montantRecu: montantRecu,
                );

                if (success) {
                  // Mettre à jour le statut de la demande
                  await FirebaseFirestore.instance
                      .collection('demandes_contrats')
                      .doc(requestId)
                      .update({
                    'statut': 'contrat_actif',
                    'datePaiementEffectue': FieldValue.serverTimestamp(),
                    'agentEncaissement': _currentAgentId,
                  });

                  // Notification conducteur avec navigation vers contrat
                  await FirebaseFirestore.instance.collection('notifications').add({
                    'conducteurId': data['conducteurId'],
                    'type': 'contrat_active',
                    'titre': 'Contrat Activé !',
                    'message': 'Félicitations ! Votre contrat d\'assurance est maintenant actif. Votre paiement de ${montantRecu.toStringAsFixed(2)} DT a été confirmé. Cliquez pour voir votre contrat.',
                    'demandeId': requestId,
                    'dateCreation': FieldValue.serverTimestamp(),
                    'lu': false,
                    'priorite': 'haute',
                    'actionType': 'view_contract',
                  });

                  // Créer le prochain paiement automatiquement
                  await EcheanceNotificationService.creerProchainPaiement(data['paiementId']);

                  Navigator.pop(context, true);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Paiement encaissé ! Contrat activé avec succès.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Erreur: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Encaisser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _getFrequenceLabel(String frequence) {
    switch (frequence) {
      case 'annuel': return 'Annuel';
      case 'trimestriel': return 'Trimestriel';
      case 'mensuel': return 'Mensuel';
      default: return frequence;
    }
  }

  String _getModePaiementLabel(String mode) {
    switch (mode) {
      case 'especes': return 'Espèces';
      case 'carte_bancaire': return 'Carte Bancaire';
      case 'cheque': return 'Chèque';
      default: return mode;
    }
  }

  /// 🔍 Debug: Afficher toutes les demandes pour diagnostic
  Future<void> _debugAllDemandes() async {
    try {
      print('🔍 [DEBUG] Recherche de TOUTES les demandes...');

      final allDemandes = await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .get();

      print('📊 [DEBUG] Total demandes dans la collection: ${allDemandes.docs.length}');

      for (final doc in allDemandes.docs) {
        final data = doc.data();
        print('  📄 [DEBUG] Demande ${doc.id}:');
        print('    - agentId: ${data['agentId']}');
        print('    - statut: ${data['statut']}');
        print('    - numero: ${data['numero']}');
        print('    - conducteurId: ${data['conducteurId']}');
        print('    - agenceId: ${data['agenceId']}');
      }

      // Chercher spécifiquement les demandes pour cet agent
      final mesDemandesQuery = await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .where('agentId', isEqualTo: _currentAgentId)
          .get();

      print('🎯 [DEBUG] Demandes pour agent $_currentAgentId: ${mesDemandesQuery.docs.length}');

      for (final doc in mesDemandesQuery.docs) {
        final data = doc.data();
        print('  ✅ [DEBUG] Ma demande ${doc.id}: statut=${data['statut']}, numero=${data['numero']}');
      }

    } catch (e) {
      print('❌ [DEBUG] Erreur debug demandes: $e');
    }
  }

  /// 💰 Afficher le dialogue pour saisir les informations financières
  Future<Map<String, dynamic>?> _afficherDialogueInformationsFinancieres(
    BuildContext context,
    Map<String, dynamic> demandeData
  ) async {
    final primeController = TextEditingController();
    final franchiseController = TextEditingController(text: '200'); // Valeur par défaut
    String frequenceSelectionnee = 'annuel';

    // Calculer une prime suggérée basée sur la formule d'assurance
    double primeSuggeree = 300; // Valeur par défaut
    if (demandeData['formuleAssurance'] != null) {
      switch (demandeData['formuleAssurance']) {
        case 'rc':
          primeSuggeree = 250;
          break;
        case 'rc_vol_incendie':
          primeSuggeree = 450;
          break;
        case 'tous_risques':
          primeSuggeree = 750;
          break;
      }
    }
    primeController.text = primeSuggeree.toString();

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Calculer le montant à payer selon la fréquence
          double primeAnnuelle = double.tryParse(primeController.text) ?? 0;
          double montantAPayer = primeAnnuelle;

          switch (frequenceSelectionnee) {
            case 'mensuel':
              montantAPayer = primeAnnuelle / 12;
              break;
            case 'trimestriel':
              montantAPayer = primeAnnuelle / 4;
              break;
            case 'semestriel':
              montantAPayer = primeAnnuelle / 2;
              break;
            case 'annuel':
              montantAPayer = primeAnnuelle;
              break;
          }

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.monetization_on, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text('Informations Financières'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Véhicule: ${demandeData['marque']} ${demandeData['modele']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Formule: ${demandeData['formuleAssuranceLabel'] ?? 'Non spécifiée'}'),
                  const SizedBox(height: 16),

                  // Prime annuelle
                  TextField(
                    controller: primeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Prime annuelle (TND)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),

                  const SizedBox(height: 16),

                  // Franchise
                  TextField(
                    controller: franchiseController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Franchise (TND)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.money_off),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Fréquence de paiement
                  const Text('Fréquence de paiement suggérée:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: frequenceSelectionnee,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.schedule),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'mensuel', child: Text('Mensuel')),
                      DropdownMenuItem(value: 'trimestriel', child: Text('Trimestriel')),
                      DropdownMenuItem(value: 'semestriel', child: Text('Semestriel')),
                      DropdownMenuItem(value: 'annuel', child: Text('Annuel')),
                    ],
                    onChanged: (value) => setState(() => frequenceSelectionnee = value!),
                  ),

                  const SizedBox(height: 16),

                  // Montant à payer calculé
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
                        const Text('Montant à payer:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${montantAPayer.toStringAsFixed(2)} TND ($frequenceSelectionnee)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  final prime = double.tryParse(primeController.text);
                  final franchise = double.tryParse(franchiseController.text);

                  if (prime == null || prime <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veuillez saisir une prime valide'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context, {
                    'primeAnnuelle': prime,
                    'franchise': franchise ?? 0,
                    'montantAPayer': montantAPayer,
                    'frequencePaiement': frequenceSelectionnee,
                  });
                },
                child: const Text('Valider'),
              ),
            ],
          );
        },
      ),
    );
  }
}

