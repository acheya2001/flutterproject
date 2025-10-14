import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/agent_dashboard_notification_service.dart';
import '../../../services/constat_agent_notification_service.dart';

/// 🔔 Widget des notifications pour le dashboard agent
class AgentNotificationsWidget extends StatefulWidget {
  const AgentNotificationsWidget({super.key});

  @override
  State<AgentNotificationsWidget> createState() => _AgentNotificationsWidgetState();
}

class _AgentNotificationsWidgetState extends State<AgentNotificationsWidget> {
  final String? _agentId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (_agentId == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Erreur: Agent non connecté'),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.blue[800]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                StreamBuilder<int>(
                  stream: AgentDashboardNotificationService.compterNotificationsNonLues(_agentId!),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Liste des notifications
          Container(
            height: 300,
            child: StreamBuilder<QuerySnapshot>(
              stream: AgentDashboardNotificationService.getNotificationsAgent(_agentId!),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Erreur: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notifications = snapshot.data?.docs ?? [];

                // Trier côté client par date de création (plus récent en premier)
                notifications.sort((a, b) {
                  final dateA = a.data()['dateCreation'] as Timestamp?;
                  final dateB = b.data()['dateCreation'] as Timestamp?;
                  if (dateA == null && dateB == null) return 0;
                  if (dateA == null) return 1;
                  if (dateB == null) return -1;
                  return dateB.compareTo(dateA);
                });

                if (notifications.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'Aucune notification',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notificationDoc = notifications[index];
                    final notificationData = notificationDoc.data() as Map<String, dynamic>;
                    return _buildNotificationCard(notificationDoc.id, notificationData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Widget d'une carte de notification
  Widget _buildNotificationCard(String notificationId, Map<String, dynamic> data) {
    final type = data['type'] as String? ?? 'general';
    final titre = data['titre'] as String? ?? 'Notification';
    final message = data['message'] as String? ?? '';
    final lu = data['lu'] as bool? ?? false;
    final dateCreation = data['dateCreation'];
    final donnees = data['donnees'] as Map<String, dynamic>? ?? {};

    final icone = AgentDashboardNotificationService.getIconeNotification(type);
    final couleurHex = AgentDashboardNotificationService.getCouleurNotification(type);
    final couleur = _hexToColor(couleurHex);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: lu ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: lu ? BorderSide.none : BorderSide(color: couleur, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _gererClicNotification(notificationId, data),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: couleur.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    icone,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: lu ? FontWeight.normal : FontWeight.bold,
                        color: lu ? Colors.grey[600] : Colors.black87,
                      ),
                    ),
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      AgentDashboardNotificationService.formaterDate(dateCreation),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Indicateur non lu
              if (!lu)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: couleur,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎯 Gérer le clic sur une notification
  void _gererClicNotification(String notificationId, Map<String, dynamic> data) async {
    // Marquer comme lue
    await AgentDashboardNotificationService.marquerCommeLue(notificationId);

    final type = data['type'] as String? ?? 'general';
    final donnees = data['donnees'] as Map<String, dynamic>? ?? {};

    switch (type) {
      case 'nouveau_constat':
        _ouvrirConstat(donnees);
        break;
      default:
        _afficherDetailNotification(data);
    }
  }

  /// 📄 Ouvrir le détail d'un constat
  void _ouvrirConstat(Map<String, dynamic> donnees) {
    final codeConstat = donnees['codeConstat'] as String? ?? '';
    final clientNom = donnees['clientNom'] as String? ?? '';
    final pdfUrl = donnees['pdfUrl'] as String? ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📄 Constat $codeConstat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client: $clientNom'),
            const SizedBox(height: 8),
            Text('Code: $codeConstat'),
            const SizedBox(height: 16),
            if (pdfUrl.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _telechargerPDF(pdfUrl),
                  icon: const Icon(Icons.download),
                  label: const Text('Télécharger PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// 📋 Afficher le détail d'une notification générale
  void _afficherDetailNotification(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['titre'] ?? 'Notification'),
        content: Text(data['message'] ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// 📥 Télécharger le PDF
  Future<void> _telechargerPDF(String pdfUrl) async {
    try {
      final uri = Uri.parse(pdfUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Impossible d\'ouvrir le lien';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur ouverture PDF: $e')),
      );
    }
  }

  /// 🎨 Convertir une couleur hexadécimale en Color
  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.grey;
    }
  }
}
