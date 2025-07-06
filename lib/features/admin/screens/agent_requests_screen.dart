import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../../auth/services/agent_registration_service.dart';
import '../../auth/models/agent_registration_model.dart';

class AgentRequestsScreen extends ConsumerStatefulWidget {
  const AgentRequestsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AgentRequestsScreen> createState() => _AgentRequestsScreenState();
}

class _AgentRequestsScreenState extends ConsumerState<AgentRequestsScreen> {
  List<AgentRegistrationModel> _requests = [];
  Map<String, int> _stats = {};
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 📊 Charger les données
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final requests = await AgentRegistrationService.getPendingRequests();
      final stats = await AgentRegistrationService.getRequestsStats();

      if (mounted) {
        setState(() {
          _requests = requests;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement données: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ✅ Approuver une demande
  Future<void> _approveRequest(AgentRegistrationModel request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Approuver la demande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voulez-vous approuver la demande de :'),
            const SizedBox(height: 8),
            Text(
              '${request.fullName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('${request.compagnie} - ${request.agence}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ Actions qui seront effectuées :',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Création du compte Firebase Auth'),
                  Text('• Enregistrement dans la base de données'),
                  Text('• Envoi d\'un email de confirmation'),
                  Text('• Activation de l\'accès à l\'application'),
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
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approuver'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AgentRegistrationService.approveAgentRequest(
          request.id,
          'admin', // TODO: Récupérer l'ID admin actuel
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Demande de ${request.fullName} approuvée'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData(); // Recharger les données
        }
      } catch (e) {
        debugPrint('Erreur approbation: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de l\'approbation: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// ❌ Rejeter une demande
  Future<void> _rejectRequest(AgentRegistrationModel request) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('❌ Rejeter la demande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rejeter la demande de :'),
            const SizedBox(height: 8),
            Text(
              '${request.fullName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('${request.compagnie} - ${request.agence}'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motif du rejet *',
                hintText: 'Expliquez pourquoi cette demande est rejetée...',
                border: OutlineInputBorder(),
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
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.of(context).pop(true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez saisir un motif'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      try {
        await AgentRegistrationService.rejectAgentRequest(
          request.id,
          'admin', // TODO: Récupérer l'ID admin actuel
          reasonController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Demande de ${request.fullName} rejetée'),
              backgroundColor: Colors.red,
            ),
          );
          _loadData(); // Recharger les données
        }
      } catch (e) {
        debugPrint('Erreur rejet: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors du rejet: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    reasonController.dispose();
  }

  /// 📋 Widget pour afficher une demande
  Widget _buildRequestCard(AgentRegistrationModel request) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec nom et statut
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        request.email,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(int.parse(request.statusColor.substring(1), radix: 16) + 0xFF000000),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${request.statusIcon} ${request.statusFormatted}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Informations professionnelles
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('🏢 Compagnie', request.compagnie),
                  _buildInfoRow('🏪 Agence', request.agence),
                  _buildInfoRow('📍 Gouvernorat', request.gouvernorat),
                  _buildInfoRow('💼 Poste', request.poste),
                  _buildInfoRow('📞 Téléphone', request.telephone),
                  _buildInfoRow('🆔 N° Agent', request.numeroAgent),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Informations de soumission
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Soumis ${request.submissionTimeText}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd/MM/yyyy à HH:mm').format(request.submittedAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Boutons d'action
            if (request.isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectRequest(request),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Rejeter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveRequest(request),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approuver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 📝 Widget pour afficher une ligne d'information
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Demandes d\'Agents',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistiques
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total',
                          _stats['total']?.toString() ?? '0',
                          Colors.blue,
                          Icons.people,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'En attente',
                          _stats['pending']?.toString() ?? '0',
                          Colors.orange,
                          Icons.hourglass_empty,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Approuvés',
                          _stats['approved']?.toString() ?? '0',
                          Colors.green,
                          Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Rejetés',
                          _stats['rejected']?.toString() ?? '0',
                          Colors.red,
                          Icons.cancel,
                        ),
                      ),
                    ],
                  ),
                ),

                // Liste des demandes
                Expanded(
                  child: _requests.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Aucune demande en attente',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            itemCount: _requests.length,
                            itemBuilder: (context, index) {
                              return _buildRequestCard(_requests[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  /// 📊 Widget pour afficher une statistique
  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
