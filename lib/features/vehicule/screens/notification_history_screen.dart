import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/vehicule_provider.dart';
import '../../auth/providers/auth_provider.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({Key? key}) : super(key: key);

  @override
  State<NotificationHistoryScreen> createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationHistory();
  }

  Future<void> _loadNotificationHistory() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final vehiculeProvider = Provider.of<VehiculeProvider>(context, listen: false);
      
      if (authProvider.currentUser != null) {
        final notifications = await vehiculeProvider.getNotificationHistory(
          authProvider.currentUser!.id,
        );
        
        if (mounted) {
          setState(() {
            _notifications = notifications;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[NotificationHistoryScreen] Building screen, isLoading: $_isLoading, notifications count: ${_notifications.length}');
  
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Historique des notifications',
      ),
      body: _isLoading
          ? const LoadingState(message: 'Chargement de l\'historique...')
          : _notifications.isEmpty
              ? const EmptyState(
                  icon: Icons.notifications_none,
                  title: 'Aucune notification',
                  message: 'Vous n\'avez pas encore reçu de notifications de rappel.',
                )
              : RefreshIndicator(
                  onRefresh: _loadNotificationHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationCard(notification);
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');
    final sentAt = notification['sentAt']?.toDate() ?? DateTime.now();
    final isRead = notification['read'] ?? false;
    final type = notification['type'] ?? '';
    final daysRemaining = notification['daysRemaining'] ?? 0;
    
    IconData icon;
    Color iconColor;
    
    switch (type) {
      case 'insurance_reminder':
        icon = Icons.schedule;
        iconColor = Colors.orange;
        break;
      case 'insurance_expired':
        icon = Icons.error;
        iconColor = Colors.red;
        break;
      case 'insurance_overdue':
        icon = Icons.warning;
        iconColor = Colors.red.shade700;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.blue;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isRead ? Colors.grey.shade300 : Theme.of(context).primaryColor,
          width: isRead ? 0.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _markAsRead(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification['title'] ?? '',
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(sentAt),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
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
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                notification['body'] ?? '',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
              if (daysRemaining > 0)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$daysRemaining jour(s) restant(s)',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markAsRead(Map<String, dynamic> notification) async {
    if (notification['read'] == true) return;
    
    try {
      final vehiculeProvider = Provider.of<VehiculeProvider>(context, listen: false);
      await vehiculeProvider.markNotificationAsRead(notification['id']);
      
      // Mettre à jour localement
      setState(() {
        notification['read'] = true;
      });
    } catch (e) {
      debugPrint('Erreur lors du marquage comme lu: $e');
    }
  }
}
