import 'package:flutter/material.dart';
import '../../../services/agent_notification_service.dart';
import '../../insurance/models/insurance_structure_model.dart';
import '../screens/pending_vehicles_screen.dart';

/// 🔔 Widget de notifications pour les agents
class AgentNotificationWidget extends StatelessWidget {
  final String agentId;
  final String? agencyId;

  const AgentNotificationWidget({
    Key? key,
    required this.agentId,
    this.agencyId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (agencyId == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Badge de véhicules en attente
        _buildPendingVehiclesBadge(context),
        const SizedBox(height: 16),
        
        // Liste des notifications récentes
        _buildRecentNotifications(context),
      ],
    );
  }

  /// 🚗 Badge des véhicules en attente
  Widget _buildPendingVehiclesBadge(BuildContext context) {
    return StreamBuilder<int>(
      stream: AgentNotificationService.streamPendingVehiclesCount(agencyId!),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        
        if (count == 0) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Aucun véhicule en attente',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PendingVehiclesScreen(agencyId: agencyId),
            ),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        count == 1 
                            ? 'Véhicule en attente de validation'
                            : 'Véhicules en attente de validation',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Cliquez pour voir les détails',
                        style: TextStyle(
                          color: Colors.orange.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.orange.shade600,
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 📋 Liste des notifications récentes
  Widget _buildRecentNotifications(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AgentNotificationService.streamAgentNotifications(agentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final notifications = snapshot.data ?? [];
        
        if (notifications.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications récentes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                if (notifications.length > 1)
                  TextButton(
                    onPressed: () => _markAllAsRead(context),
                    child: const Text('Tout marquer comme lu'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...notifications.take(3).map((notification) => 
              _buildNotificationCard(context, notification)
            ).toList(),
          ],
        );
      },
    );
  }

  /// 📄 Carte de notification
  Widget _buildNotificationCard(BuildContext context, Map<String, dynamic> notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active,
            color: Colors.blue.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title'] ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification['message'] ?? '',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _markAsRead(context, notification['id']),
            icon: Icon(
              Icons.close,
              color: Colors.blue.shade600,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Marquer une notification comme lue
  void _markAsRead(BuildContext context, String notificationId) async {
    await AgentNotificationService.markNotificationAsRead(notificationId);
  }

  /// ✅ Marquer toutes les notifications comme lues
  void _markAllAsRead(BuildContext context) async {
    await AgentNotificationService.markAllNotificationsAsRead(agentId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Toutes les notifications ont été marquées comme lues'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
