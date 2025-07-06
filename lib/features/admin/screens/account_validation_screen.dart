import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../../auth/models/notification_model.dart';
import '../../auth/services/notification_service.dart';
import '../../auth/models/user_model.dart';

/// 🔍 Écran de validation des comptes professionnels
class AccountValidationScreen extends ConsumerStatefulWidget {
  const AccountValidationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AccountValidationScreen> createState() => _AccountValidationScreenState();
}

class _AccountValidationScreenState extends ConsumerState<AccountValidationScreen> {
  String _selectedFilter = 'pending';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Validation des Comptes',
      ),
      body: Column(
        children: [
          // Filtres
          _buildFilterTabs(),
          
          // Liste des demandes
          Expanded(
            child: _buildRequestsList(),
          ),
        ],
      ),
    );
  }

  /// 📊 Onglets de filtrage
  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildFilterChip('pending', 'En attente', Colors.orange),
          const SizedBox(width: 8),
          _buildFilterChip('approved', 'Approuvés', Colors.green),
          const SizedBox(width: 8),
          _buildFilterChip('rejected', 'Rejetés', Colors.red),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, Color color) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.grey[100],
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  /// 📋 Liste des demandes
  Widget _buildRequestsList() {
    return StreamBuilder<List<ProfessionalAccountRequest>>(
      stream: _selectedFilter == 'pending' 
          ? ProfessionalAccountService.getPendingRequests()
          : _getAllRequestsByStatus(_selectedFilter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[300]),
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

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune demande ${_getStatusLabel(_selectedFilter)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildRequestCard(request);
          },
        );
      },
    );
  }

  /// 🃏 Carte de demande
  Widget _buildRequestCard(ProfessionalAccountRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showRequestDetails(request),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getTypeColor(request.userType),
                    child: Icon(
                      _getTypeIcon(request.userType),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${request.prenom} ${request.nom}',
                          style: const TextStyle(
                            fontSize: 16,
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
                  _buildStatusBadge(request.status),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Informations professionnelles
              if (request.userType == 'assureur') ...[
                _buildInfoRow(Icons.business, 'Compagnie', request.compagnie ?? ''),
                _buildInfoRow(Icons.badge, 'Matricule', request.matricule ?? ''),
                _buildInfoRow(Icons.location_city, 'Gouvernorat', request.gouvernorat ?? ''),
              ],
              
              if (request.userType == 'expert') ...[
                _buildInfoRow(Icons.business_center, 'Cabinet', request.cabinet ?? ''),
                _buildInfoRow(Icons.verified, 'Agrément', request.agrement ?? ''),
              ],
              
              const SizedBox(height: 8),
              
              // Date et actions
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(request.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (request.status == AccountStatus.pending) ...[
                    TextButton.icon(
                      onPressed: () => _rejectRequest(request),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Rejeter'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _approveRequest(request),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approuver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Non renseigné' : value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AccountStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case AccountStatus.pending:
        color = Colors.orange;
        text = 'En attente';
        break;
      case AccountStatus.approved:
        color = Colors.green;
        text = 'Approuvé';
        break;
      case AccountStatus.rejected:
        color = Colors.red;
        text = 'Rejeté';
        break;
      default:
        color = Colors.grey;
        text = 'Inconnu';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getTypeColor(String userType) {
    switch (userType) {
      case 'assureur':
        return Colors.blue;
      case 'expert':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String userType) {
    switch (userType) {
      case 'assureur':
        return Icons.business;
      case 'expert':
        return Icons.assignment_ind;
      default:
        return Icons.person;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'en attente';
      case 'approved':
        return 'approuvées';
      case 'rejected':
        return 'rejetées';
      default:
        return '';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// 📄 Afficher les détails d'une demande
  void _showRequestDetails(ProfessionalAccountRequest request) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            children: [
              // En-tête
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getTypeColor(request.userType),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getTypeIcon(request.userType),
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${request.prenom} ${request.nom}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            request.userType == 'assureur' ? 'Agent d\'Assurance' : 'Expert',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Contenu
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection('📧 Contact', [
                        _buildDetailRow('Email', request.email),
                        _buildDetailRow('Téléphone', request.telephone),
                        _buildDetailRow('Adresse', request.adresse ?? 'Non renseignée'),
                      ]),

                      const SizedBox(height: 20),

                      if (request.userType == 'assureur')
                        _buildDetailSection('🏢 Informations Assurance', [
                          _buildDetailRow('Compagnie', request.compagnie ?? ''),
                          _buildDetailRow('Matricule', request.matricule ?? ''),
                          _buildDetailRow('Gouvernorat', request.gouvernorat ?? ''),
                          _buildDetailRow('Agence préférée', request.agencePreferee ?? 'Aucune préférence'),
                        ]),

                      if (request.userType == 'expert')
                        _buildDetailSection('🔍 Informations Expert', [
                          _buildDetailRow('Cabinet', request.cabinet ?? ''),
                          _buildDetailRow('Agrément', request.agrement ?? ''),
                          _buildDetailRow('Spécialités', request.specialites ?? 'Non renseignées'),
                        ]),

                      const SizedBox(height: 20),

                      if (request.motivationLetter != null && request.motivationLetter!.isNotEmpty)
                        _buildDetailSection('💬 Lettre de motivation', [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              request.motivationLetter!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ]),

                      const SizedBox(height: 20),

                      _buildDetailSection('📊 Statut', [
                        Row(
                          children: [
                            _buildStatusBadge(request.status),
                            const Spacer(),
                            Text(
                              'Demande créée le ${_formatDate(request.createdAt)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ]),
                    ],
                  ),
                ),
              ),

              // Actions
              if (request.status == AccountStatus.pending)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _rejectRequest(request);
                          },
                          icon: const Icon(Icons.close),
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
                          onPressed: () {
                            Navigator.pop(context);
                            _approveRequest(request);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Approuver'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
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
        ...children,
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
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Non renseigné' : value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Approuver une demande
  Future<void> _approveRequest(ProfessionalAccountRequest request) async {
    try {
      // Afficher dialog de confirmation
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Approuver la demande'),
          content: Text(
            'Êtes-vous sûr de vouloir approuver la demande de ${request.prenom} ${request.nom} ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Approuver'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Approuver la demande
        await ProfessionalAccountService.approveRequest(
          requestId: request.id,
          approvedBy: 'admin', // TODO: Récupérer l'ID de l'admin connecté
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Demande approuvée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
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

  /// ❌ Rejeter une demande
  Future<void> _rejectRequest(ProfessionalAccountRequest request) async {
    final reasonController = TextEditingController();

    try {
      // Afficher dialog pour saisir la raison
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Rejeter la demande'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Demande de ${request.prenom} ${request.nom}'),
              const SizedBox(height: 16),
              const Text(
                'Raison du rejet:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Expliquez pourquoi cette demande est rejetée...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isNotEmpty) {
                  Navigator.pop(context, {
                    'confirmed': true,
                    'reason': reasonController.text.trim(),
                  });
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Rejeter'),
            ),
          ],
        ),
      );

      if (result != null && result['confirmed'] == true) {
        // Rejeter la demande
        await ProfessionalAccountService.rejectRequest(
          requestId: request.id,
          rejectedBy: 'admin', // TODO: Récupérer l'ID de l'admin connecté
          reason: result['reason'],
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Demande rejetée'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du rejet: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      reasonController.dispose();
    }
  }

  /// 📊 Obtenir les demandes par statut (pour les filtres autres que pending)
  Stream<List<ProfessionalAccountRequest>> _getAllRequestsByStatus(String status) {
    // TODO: Implémenter la récupération des demandes par statut
    // Pour l'instant, retourner un stream vide
    return Stream.value([]);
  }
}
