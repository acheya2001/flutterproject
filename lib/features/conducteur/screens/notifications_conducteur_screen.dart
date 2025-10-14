import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/conducteur_notification_service.dart';

/// 🔔 Écran des notifications pour le conducteur
class NotificationsConducteurScreen extends StatefulWidget {
  final Map<String, dynamic> conducteurData;

  const NotificationsConducteurScreen({
    super.key,
    required this.conducteurData,
  });

  @override
  State<NotificationsConducteurScreen> createState() => _NotificationsConducteurScreenState();
}

class _NotificationsConducteurScreenState extends State<NotificationsConducteurScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  bool _showOnlyUnread = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  /// 📋 Charger les notifications
  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications = await ConducteurNotificationService.getNotifications(
        conducteurId: widget.conducteurData['uid'] ?? widget.conducteurData['id'] ?? '',
        limit: 50,
        onlyUnread: _showOnlyUnread,
      );

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });

    } catch (e) {
      debugPrint('[NOTIFICATIONS] ❌ Erreur chargement: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Notifications'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          // Filtre lu/non lu
          IconButton(
            icon: Icon(_showOnlyUnread ? Icons.mark_email_read : Icons.mark_email_unread),
            onPressed: () {
              setState(() {
                _showOnlyUnread = !_showOnlyUnread;
              });
              _loadNotifications();
            },
            tooltip: _showOnlyUnread ? 'Voir toutes' : 'Voir non lues',
          ),
          // Marquer toutes comme lues
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _marquerToutesCommeLues,
            tooltip: 'Marquer toutes comme lues',
          ),
          // Actualiser
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barre de filtres
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Row(
                    children: [
                      Icon(
                        _showOnlyUnread ? Icons.filter_alt : Icons.filter_alt_off,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _showOnlyUnread ? 'Notifications non lues' : 'Toutes les notifications',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_notifications.length} notification(s)',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Liste des notifications
                Expanded(
                  child: _notifications.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final notification = _notifications[index];
                            return _buildNotificationCard(notification);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  /// 📭 État vide
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showOnlyUnread ? Icons.mark_email_read : Icons.notifications_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _showOnlyUnread 
                ? 'Aucune notification non lue'
                : 'Aucune notification',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _showOnlyUnread
                ? 'Toutes vos notifications ont été lues'
                : 'Vous n\'avez pas encore de notifications',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔔 Carte de notification
  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final bool isRead = notification['lu'] ?? false;
    final String type = notification['type'] ?? '';
    final String icon = ConducteurNotificationService.getNotificationIcon(type);
    final Color color = _getNotificationColor(type);
    final String timeAgo = ConducteurNotificationService.formatNotificationDate(notification['dateCreation']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 1 : 3,
      color: isRead ? Colors.white : Colors.blue[50],
      child: InkWell(
        onTap: () => _ouvrirNotification(notification),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  // Icône de type
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Titre et temps
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification['titre'] ?? 'Notification',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            color: isRead ? Colors.grey[700] : Colors.black,
                          ),
                        ),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Indicateur non lu
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Message
              Text(
                notification['message'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: isRead ? Colors.grey[600] : Colors.grey[800],
                ),
              ),

              // Informations supplémentaires
              if (notification['codeConstat'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Constat: ${notification['codeConstat']}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 🎨 Obtenir la couleur de la notification
  Color _getNotificationColor(String type) {
    switch (type) {
      case 'expert_assigne':
        return Colors.blue;
      case 'expertise_terminee':
        return Colors.green;
      case 'document_disponible':
        return Colors.purple;
      case 'rappel':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// 📖 Ouvrir une notification
  Future<void> _ouvrirNotification(Map<String, dynamic> notification) async {
    final String notificationId = notification['id'];
    final String conducteurId = widget.conducteurData['uid'] ?? widget.conducteurData['id'] ?? '';

    // Marquer comme lue si pas encore lu
    if (!(notification['lu'] ?? false)) {
      await ConducteurNotificationService.marquerCommeLue(notificationId, conducteurId);
      
      // Mettre à jour localement
      setState(() {
        notification['lu'] = true;
      });
    }

    // Afficher les détails
    showDialog(
      context: context,
      builder: (context) => _NotificationDetailsDialog(notification: notification),
    );
  }

  /// ✅ Marquer toutes les notifications comme lues
  Future<void> _marquerToutesCommeLues() async {
    try {
      final conducteurId = widget.conducteurData['uid'] ?? widget.conducteurData['id'] ?? '';
      
      final success = await ConducteurNotificationService.marquerToutesCommeLues(conducteurId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Toutes les notifications ont été marquées comme lues'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Recharger les notifications
        _loadNotifications();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Erreur lors du marquage'),
            backgroundColor: Colors.red,
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
  }
}

/// 📋 Dialogue des détails de notification
class _NotificationDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> notification;

  const _NotificationDetailsDialog({required this.notification});

  @override
  Widget build(BuildContext context) {
    final String type = notification['type'] ?? '';
    final String icon = ConducteurNotificationService.getNotificationIcon(type);
    final expertData = notification['expertData'];

    return AlertDialog(
      title: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              notification['titre'] ?? 'Notification',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Message
              Text(
                notification['message'] ?? '',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),

              // Détails de l'expert si disponible
              if (expertData != null) ...[
                const Text(
                  'Détails de l\'expert :',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Nom', expertData['nom'] ?? 'N/A'),
                      _buildDetailRow('Code', expertData['codeExpert'] ?? 'N/A'),
                      _buildDetailRow('Téléphone', expertData['telephone'] ?? 'N/A'),
                      _buildDetailRow('Email', expertData['email'] ?? 'N/A'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Informations supplémentaires
              if (notification['codeConstat'] != null)
                _buildDetailRow('Code constat', notification['codeConstat']),
              if (notification['delaiInterventionHeures'] != null)
                _buildDetailRow('Délai d\'intervention', '${notification['delaiInterventionHeures']} heures'),
              if (notification['commentaire'] != null && notification['commentaire'].isNotEmpty)
                _buildDetailRow('Commentaire', notification['commentaire']),
              
              _buildDetailRow('Date', ConducteurNotificationService.formatNotificationDate(notification['dateCreation'])),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
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
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
