import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


import '../models/agent_validation_model.dart';

/// 📋 Écran de validation des agents d'assurance
class AgentValidationScreen extends StatefulWidget {
  const AgentValidationScreen({super.key});

  @override
  State<AgentValidationScreen> createState() => _AgentValidationScreenState();
}

class _AgentValidationScreenState extends State<AgentValidationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Validation Agents'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'En Attente', icon: Icon(Icons.pending, size: 16)),
            Tab(text: 'Approuvées', icon: Icon(Icons.check_circle, size: 16)),
            Tab(text: 'Rejetées', icon: Icon(Icons.cancel, size: 16)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildValidationList(ValidationStatus.enAttente),
          _buildValidationList(ValidationStatus.approuve),
          _buildValidationList(ValidationStatus.rejete),
        ],
      ),
    );
  }

  Widget _buildValidationList(ValidationStatus status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('agents_validation')
          .where('statut', isEqualTo: status.value)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.green),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Erreur: ${snapshot.error}',
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(status);
        }

        final validations = snapshot.data!.docs
            .map((doc) => AgentValidationModel.fromFirestore(doc))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: validations.length,
          itemBuilder: (context, index) {
            final validation = validations[index];
            return _buildValidationCard(validation);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(ValidationStatus status) {
    String message;
    IconData icon;
    Color color;

    switch (status) {
      case ValidationStatus.enAttente:
        message = 'Aucune demande en attente';
        icon = Icons.pending;
        color = Colors.orange;
        break;
      case ValidationStatus.approuve:
        message = 'Aucune demande approuvée';
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case ValidationStatus.rejete:
        message = 'Aucune demande rejetée';
        icon = Icons.cancel;
        color = Colors.red;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: color.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationCard(AgentValidationModel validation) {
    Color statusColor;
    IconData statusIcon;

    switch (validation.statut) {
      case ValidationStatus.enAttente:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case ValidationStatus.approuve:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case ValidationStatus.rejete:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showValidationDetails(validation),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec statut
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          validation.nomComplet,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          validation.email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      validation.statut.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Informations de la demande
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      Icons.business,
                      validation.compagnieDemandee,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      Icons.location_on,
                      validation.delegation,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      Icons.badge,
                      validation.matriculeAgent,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      Icons.schedule,
                      '${validation.joursDepuisCreation} jours',
                      validation.isUrgente ? Colors.red : Colors.grey,
                    ),
                  ),
                ],
              ),
              
              // Actions pour les demandes en attente
              if (validation.isEnAttente) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveRequest(validation),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Approuver'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _rejectRequest(validation),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Rejeter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
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
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showValidationDetails(AgentValidationModel validation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ValidationDetailsSheet(validation: validation),
    );
  }

  Future<void> _approveRequest(AgentValidationModel validation) async {
    try {
      await FirebaseFirestore.instance
          .collection('agents_validation')
          .doc(validation.id)
          .update({
        'statut': ValidationStatus.approuve.value,
        'admin_validateur': 'current_admin_id', // TODO: Récupérer l'ID de l'admin connecté
        'date_validation': FieldValue.serverTimestamp(),
        'commentaire_admin': 'Demande approuvée',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Demande approuvée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(AgentValidationModel validation) async {
    final reason = await _showRejectDialog();
    if (reason == null || reason.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('agents_validation')
          .doc(validation.id)
          .update({
        'statut': ValidationStatus.rejete.value,
        'admin_validateur': 'current_admin_id', // TODO: Récupérer l'ID de l'admin connecté
        'date_validation': FieldValue.serverTimestamp(),
        'raison_rejet': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Demande rejetée'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raison du rejet'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Expliquez pourquoi cette demande est rejetée...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// 📋 Feuille de détails de validation
class _ValidationDetailsSheet extends StatelessWidget {
  final AgentValidationModel validation;

  const _ValidationDetailsSheet({required this.validation});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Contenu
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  const Text(
                    'Détails de la Demande',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Informations personnelles
                  _buildSection('Informations Personnelles', [
                    _buildDetailRow('Nom complet', validation.nomComplet),
                    _buildDetailRow('Email', validation.email),
                    _buildDetailRow('Téléphone', validation.telephone),
                  ]),
                  
                  const SizedBox(height: 20),
                  
                  // Informations professionnelles
                  _buildSection('Informations Professionnelles', [
                    _buildDetailRow('Compagnie', validation.compagnieDemandee),
                    _buildDetailRow('Agence', validation.agenceDemandee),
                    _buildDetailRow('Matricule', validation.matriculeAgent),
                    _buildDetailRow('Zone', validation.zoneFormatee),
                    _buildDetailRow('Délégation', validation.delegation),
                  ]),
                  
                  const SizedBox(height: 20),
                  
                  // Statut
                  _buildSection('Statut de la Demande', [
                    _buildDetailRow('Statut', validation.statut.name),
                    _buildDetailRow('Date de création', _formatDate(validation.createdAt)),
                    if (validation.dateValidation != null)
                      _buildDetailRow('Date de validation', _formatDate(validation.dateValidation!)),
                    if (validation.commentaireAdmin != null)
                      _buildDetailRow('Commentaire admin', validation.commentaireAdmin!),
                    if (validation.raisonRejet != null)
                      _buildDetailRow('Raison du rejet', validation.raisonRejet!),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
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
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: Color(0xFF6B7280))),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
