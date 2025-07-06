import 'package:flutter/material.dart';
import '../models/hierarchical_structure.dart';
import '../services/hierarchical_admin_service.dart';

/// 📋 Écran de gestion des demandes filtré par admin
class CleanDemandesScreen extends StatefulWidget {
  final AdminUser admin;

  const CleanDemandesScreen({
    super.key,
    required this.admin,
  });

  @override
  State<CleanDemandesScreen> createState() => _CleanDemandesScreenState();
}

class _CleanDemandesScreenState extends State<CleanDemandesScreen> {
  StatutDemande? _filtreStatut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('📋 Demandes d\'Inscription'),
        backgroundColor: _getAdminColor(),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<StatutDemande?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (statut) => setState(() => _filtreStatut = statut),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Toutes les demandes'),
              ),
              const PopupMenuItem(
                value: StatutDemande.enAttente,
                child: Text('En attente'),
              ),
              const PopupMenuItem(
                value: StatutDemande.approuvee,
                child: Text('Approuvées'),
              ),
              const PopupMenuItem(
                value: StatutDemande.rejetee,
                child: Text('Rejetées'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildInfoHeader(),
          Expanded(
            child: StreamBuilder<List<DemandeAgent>>(
              stream: HierarchicalAdminService.getDemandesForAdmin(widget.admin),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
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

                final demandes = snapshot.data ?? [];
                final demandesFiltrees = _filtreStatut == null
                    ? demandes
                    : demandes.where((d) => d.statut == _filtreStatut).toList();

                if (demandesFiltrees.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _filtreStatut == null ? Icons.inbox : Icons.filter_list_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filtreStatut == null
                              ? 'Aucune demande pour le moment'
                              : 'Aucune demande ${_getStatutText(_filtreStatut!)}',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: demandesFiltrees.length,
                  itemBuilder: (context, index) {
                    return _buildDemandeCard(demandesFiltrees[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getAdminColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getAdminColor().withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(_getAdminIcon(), color: _getAdminColor()),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getAdminScope(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getAdminColor(),
                  ),
                ),
                Text(
                  'Vous ne voyez que les demandes de votre ${widget.admin.type == AdminType.agence ? 'agence' : 'compagnie'}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemandeCard(DemandeAgent demande) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getStatutColor(demande.statut).withOpacity(0.1),
                  child: Text(
                    '${demande.prenom[0]}${demande.nom[0]}',
                    style: TextStyle(
                      color: _getStatutColor(demande.statut),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${demande.prenom} ${demande.nom}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        demande.email,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatutChip(demande.statut),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone, demande.telephone),
            _buildInfoRow(Icons.credit_card, 'CIN: ${demande.cin}'),
            _buildInfoRow(Icons.access_time, _formatDate(demande.dateCreation)),
            if (demande.statut == StatutDemande.enAttente) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approuverDemande(demande),
                      icon: const Icon(Icons.check),
                      label: const Text('Approuver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejeterDemande(demande),
                      icon: const Icon(Icons.close),
                      label: const Text('Rejeter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (demande.commentaire != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.comment, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        demande.commentaire!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatutChip(StatutDemande statut) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatutColor(statut).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatutColor(statut).withOpacity(0.3)),
      ),
      child: Text(
        _getStatutText(statut),
        style: TextStyle(
          color: _getStatutColor(statut),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _approuverDemande(DemandeAgent demande) async {
    final success = await HierarchicalAdminService.approuverDemande(
      demande.id,
      widget.admin,
      commentaire: 'Demande approuvée par ${widget.admin.prenom} ${widget.admin.nom}',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✅ Demande approuvée' : '❌ Erreur lors de l\'approbation'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _rejeterDemande(DemandeAgent demande) async {
    final raison = await _showRejectDialog();
    if (raison == null) return;

    final success = await HierarchicalAdminService.rejeterDemande(
      demande.id,
      widget.admin,
      raison,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '❌ Demande rejetée' : '❌ Erreur lors du rejet'),
          backgroundColor: success ? Colors.orange : Colors.red,
        ),
      );
    }
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter la demande'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Raison du rejet',
            hintText: 'Expliquez pourquoi vous rejetez cette demande...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }

  Color _getAdminColor() {
    switch (widget.admin.type) {
      case AdminType.superAdmin:
        return Colors.red;
      case AdminType.compagnie:
        return Colors.blue;
      case AdminType.agence:
        return Colors.green;
    }
  }

  IconData _getAdminIcon() {
    switch (widget.admin.type) {
      case AdminType.superAdmin:
        return Icons.admin_panel_settings;
      case AdminType.compagnie:
        return Icons.business;
      case AdminType.agence:
        return Icons.store;
    }
  }

  String _getAdminScope() {
    switch (widget.admin.type) {
      case AdminType.superAdmin:
        return 'Toutes les demandes du système';
      case AdminType.compagnie:
        return 'Demandes de votre compagnie';
      case AdminType.agence:
        return 'Demandes de votre agence';
    }
  }

  Color _getStatutColor(StatutDemande statut) {
    switch (statut) {
      case StatutDemande.enAttente:
        return Colors.orange;
      case StatutDemande.approuvee:
        return Colors.green;
      case StatutDemande.rejetee:
        return Colors.red;
    }
  }

  String _getStatutText(StatutDemande statut) {
    switch (statut) {
      case StatutDemande.enAttente:
        return 'En attente';
      case StatutDemande.approuvee:
        return 'Approuvée';
      case StatutDemande.rejetee:
        return 'Rejetée';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
