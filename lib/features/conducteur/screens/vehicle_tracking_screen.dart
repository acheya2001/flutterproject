import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/vehicle_status_model.dart';
import '../../../services/vehicle_tracking_service.dart';
import 'package:intl/intl.dart';

/// 📊 Écran de suivi des véhicules pour le conducteur
class VehicleTrackingScreen extends StatelessWidget {
  const VehicleTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Suivi de mes demandes'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<VehicleStatusModel>>(
        stream: VehicleTrackingService.streamConducteurVehicleTrackings(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final trackings = snapshot.data ?? [];

          if (trackings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune demande d\'assurance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vos demandes d\'assurance apparaîtront ici',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trackings.length,
            itemBuilder: (context, index) {
              final tracking = trackings[index];
              return _buildTrackingCard(context, tracking);
            },
          );
        },
      ),
    );
  }

  Widget _buildTrackingCard(BuildContext context, VehicleStatusModel tracking) {
    final statusColor = _getStatusColor(tracking.currentStatus);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showTrackingDetails(context, tracking),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec statut
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(tracking.currentStatus),
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tracking.currentStatus,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(tracking.lastUpdated),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Informations véhicule
              Text(
                'Véhicule ID: ${tracking.vehicleId}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Description du statut
              Text(
                VehicleStatus.getStatusDescription(tracking.currentStatus),
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              
              // Agent assigné (si applicable)
              if (tracking.agentNom != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.blue.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Agent: ${tracking.agentNom}',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              
              // Raison de rejet (si applicable)
              if (tracking.rejectionReason != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, size: 16, color: Colors.red.shade600),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Raison: ${tracking.rejectionReason}',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Prochaine étape
              if (VehicleStatus.getNextStep(tracking.currentStatus) != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.arrow_forward, size: 16, color: Colors.green.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Prochaine étape: ${VehicleStatus.getNextStep(tracking.currentStatus)}',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
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

  void _showTrackingDetails(BuildContext context, VehicleStatusModel tracking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Titre
                Text(
                  '📊 Historique détaillé',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Historique
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: tracking.history.length,
                    itemBuilder: (context, index) {
                      final entry = tracking.history[tracking.history.length - 1 - index];
                      final isLast = index == tracking.history.length - 1;
                      
                      return _buildHistoryEntry(entry, isLast);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryEntry(StatusHistoryEntry entry, bool isLast) {
    final statusColor = _getStatusColor(entry.status);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey.shade300,
              ),
          ],
        ),
        
        const SizedBox(width: 16),
        
        // Contenu
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy à HH:mm').format(entry.timestamp),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                if (entry.actorName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Par: ${entry.actorName} (${entry.actorRole})',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (entry.comment != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.comment!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
                if (entry.reason != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Raison: ${entry.reason}',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case VehicleStatus.enAttente:
        return Colors.orange;
      case VehicleStatus.affecteAgent:
        return Colors.blue;
      case VehicleStatus.contratCree:
        return Colors.green;
      case VehicleStatus.documentsRequis:
        return Colors.purple;
      case VehicleStatus.traiteAgent:
        return Colors.teal;
      case VehicleStatus.rejete:
        return Colors.red;
      case VehicleStatus.annule:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case VehicleStatus.enAttente:
        return Icons.hourglass_empty;
      case VehicleStatus.affecteAgent:
        return Icons.assignment_ind;
      case VehicleStatus.contratCree:
        return Icons.check_circle;
      case VehicleStatus.documentsRequis:
        return Icons.description;
      case VehicleStatus.traiteAgent:
        return Icons.done_all;
      case VehicleStatus.rejete:
        return Icons.cancel;
      case VehicleStatus.annule:
        return Icons.block;
      default:
        return Icons.help;
    }
  }
}
