import 'package:flutter/material.dart';
import '../services/notification_service.dart';

/// 🔔 Badge de notification avec compteur
class NotificationBadge extends StatelessWidget {
  final String userId;
  final String userType;
  final Widget child;
  final VoidCallback? onTap;

  const NotificationBadge({
    super.key,
    required this.userId,
    required this.userType,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: NotificationService.streamUnreadCount(userId, userType),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        
        return GestureDetector(
          onTap: onTap,
          child: Stack(
            children: [
              child,
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
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
          ),
        );
      },
    );
  }
}

/// 📋 Liste des notifications
class NotificationsList extends StatelessWidget {
  final String userId;
  final String userType;

  const NotificationsList({
    super.key,
    required this.userId,
    required this.userType,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: NotificationService.streamUserNotifications(userId, userType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Aucune notification',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return NotificationTile(
              notification: notification,
              onTap: () => _handleNotificationTap(context, notification),
            );
          },
        );
      },
    );
  }

  void _handleNotificationTap(BuildContext context, Map<String, dynamic> notification) {
    // Marquer comme lue
    if (!notification['isRead']) {
      NotificationService.markAsRead(notification['id']);
    }

    // Navigation selon le type de notification
    final type = notification['type'] as String;
    final data = notification['data'] as Map<String, dynamic>? ?? {};

    switch (type) {
      case 'new_vehicle_pending':
        Navigator.pushNamed(
          context,
          '/agent/pending-vehicles',
          arguments: data,
        );
        break;
      case 'vehicle_validated':
      case 'vehicle_rejected':
        Navigator.pushNamed(
          context,
          '/conducteur/vehicles',
          arguments: data,
        );
        break;
      case 'constat_invitation':
        Navigator.pushNamed(
          context,
          '/constat/officiel',
          arguments: {'constatsId': data['constatsId']},
        );
        break;
      case 'constat_finalized':
        Navigator.pushNamed(
          context,
          '/agent/constats',
          arguments: data,
        );
        break;
    }
  }
}

/// 📄 Tuile de notification
class NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback? onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = notification['isRead'] as bool? ?? false;
    final type = notification['type'] as String;
    final title = notification['title'] as String;
    final message = notification['message'] as String;
    final createdAt = notification['createdAt'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isRead ? Colors.white : Colors.blue[50],
      child: ListTile(
        leading: _getNotificationIcon(type),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (createdAt != null)
              Text(
                _formatDate(createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        trailing: !isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    IconData iconData;
    Color color;

    switch (type) {
      case 'new_vehicle_pending':
        iconData = Icons.directions_car;
        color = Colors.orange;
        break;
      case 'vehicle_validated':
        iconData = Icons.check_circle;
        color = Colors.green;
        break;
      case 'vehicle_rejected':
        iconData = Icons.cancel;
        color = Colors.red;
        break;
      case 'constat_invitation':
        iconData = Icons.description;
        color = Colors.blue;
        break;
      case 'constat_finalized':
        iconData = Icons.assignment_turned_in;
        color = Colors.purple;
        break;
      default:
        iconData = Icons.notifications;
        color = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(iconData, color: color),
    );
  }

  String _formatDate(dynamic timestamp) {
    try {
      DateTime date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else {
        date = timestamp.toDate();
      }

      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}j';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}min';
      } else {
        return 'Maintenant';
      }
    } catch (e) {
      return '';
    }
  }
}
