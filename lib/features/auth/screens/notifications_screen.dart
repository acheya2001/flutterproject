import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';
import '../providers/auth_provider.dart';

/// 🔔 Écran des notifications
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentUser = authState.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Utilisateur non connecté'),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Notifications',
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: () => _markAllAsRead(currentUser.uid),
            tooltip: 'Marquer tout comme lu',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          _buildFilterTabs(),
          
          // Liste des notifications
          Expanded(
            child: _buildNotificationsList(currentUser.uid),
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
          _buildFilterChip('all', 'Toutes', Colors.blue),
          const SizedBox(width: 8),
          _buildFilterChip('unread', 'Non lues', Colors.orange),
          const SizedBox(width: 8),
          _buildFilterChip('read', 'Lues', Colors.grey),
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
      selectedColor: color.withValues(alpha: 0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  /// 📋 Liste des notifications
  Widget _buildNotificationsList(String userId) {
    return StreamBuilder<List<NotificationModel>>(
      stream: NotificationService.getUserNotifications(userId),
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

        final allNotifications = snapshot.data ?? [];
        final filteredNotifications = _filterNotifications(allNotifications);

        if (filteredNotifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _getEmptyMessage(),
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
          itemCount: filteredNotifications.length,
          itemBuilder: (context, index) {
            final notification = filteredNotifications[index];
            return _buildNotificationCard(notification);
          },
        );
      },
    );
  }

  /// 🃏 Carte de notification
  Widget _buildNotificationCard(NotificationModel notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: notification.isRead ? 1 : 3,
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: notification.isRead 
                ? null 
                : Border.all(color: Colors.blue[200]!, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getNotificationColor(notification.type),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        notification.iconData,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: notification.isRead 
                                ? FontWeight.normal 
                                : FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatDate(notification.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Message
              Text(
                notification.message,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
              
              // Actions si nécessaire
              if (notification.data.containsKey('action'))
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _buildNotificationActions(notification),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎬 Actions de notification
  Widget _buildNotificationActions(NotificationModel notification) {
    final action = notification.data['action'] as String?;
    
    switch (action) {
      case 'review_account_request':
        return ElevatedButton.icon(
          onPressed: () => _navigateToAccountValidation(notification),
          icon: const Icon(Icons.visibility, size: 16),
          label: const Text('Voir la demande'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
          ),
        );
      
      case 'account_approved':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600], size: 16),
              const SizedBox(width: 8),
              const Text(
                'Votre compte a été approuvé !',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      
      case 'account_rejected':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.cancel, color: Colors.red[600], size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Demande rejetée',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (notification.data.containsKey('reason'))
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Raison: ${notification.data['reason']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[700],
                    ),
                  ),
                ),
            ],
          ),
        );
      
      default:
        return const SizedBox.shrink();
    }
  }

  /// 🔍 Filtrer les notifications
  List<NotificationModel> _filterNotifications(List<NotificationModel> notifications) {
    switch (_selectedFilter) {
      case 'unread':
        return notifications.where((n) => !n.isRead).toList();
      case 'read':
        return notifications.where((n) => n.isRead).toList();
      default:
        return notifications;
    }
  }

  /// 📅 Formater la date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jour(s)';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// 🎨 Couleur par type de notification
  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.accountPending:
        return Colors.orange[100]!;
      case NotificationType.accountApproved:
        return Colors.green[100]!;
      case NotificationType.accountRejected:
        return Colors.red[100]!;
      case NotificationType.accountSuspended:
        return Colors.red[100]!;
      case NotificationType.permissionChanged:
        return Colors.blue[100]!;
    }
  }

  /// 📝 Message vide selon le filtre
  String _getEmptyMessage() {
    switch (_selectedFilter) {
      case 'unread':
        return 'Aucune notification non lue';
      case 'read':
        return 'Aucune notification lue';
      default:
        return 'Aucune notification';
    }
  }

  /// 👆 Gérer le tap sur une notification
  Future<void> _handleNotificationTap(NotificationModel notification) async {
    if (!notification.isRead) {
      await NotificationService.markAsRead(notification.id);
    }
    
    // Gérer les actions spécifiques selon le type
    final action = notification.data['action'] as String?;
    if (action == 'review_account_request') {
      _navigateToAccountValidation(notification);
    }
  }

  /// 🔄 Marquer toutes les notifications comme lues
  Future<void> _markAllAsRead(String userId) async {
    try {
      await NotificationService.markAllAsRead(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toutes les notifications ont été marquées comme lues'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🔗 Naviguer vers la validation des comptes
  void _navigateToAccountValidation(NotificationModel notification) {
    Navigator.pushNamed(context, '/admin/account-validation');
  }
}
