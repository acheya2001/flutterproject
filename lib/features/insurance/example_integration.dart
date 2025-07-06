import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/insurance_navigation.dart';
import 'services/notification_service.dart';
import 'utils/insurance_styles.dart';

/// 📱 Exemple d'intégration des fonctionnalités d'assurance dans l'app principale
class InsuranceIntegrationExample extends StatefulWidget {
  const InsuranceIntegrationExample({Key? key}) : super(key: key);

  @override
  State<InsuranceIntegrationExample> createState() => _InsuranceIntegrationExampleState();
}

class _InsuranceIntegrationExampleState extends State<InsuranceIntegrationExample> {
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadNotificationCount();
  }

  Future<void> _initializeNotifications() async {
    await InsuranceNotificationService.initializeLocalNotifications();
  }

  Future<void> _loadNotificationCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Écouter les notifications en temps réel
      InsuranceNotificationService.getUserNotifications(user.uid).listen((notifications) {
        final unreadCount = notifications.where((n) => !n['isRead']).length;
        if (mounted) {
          setState(() {
            _notificationCount = unreadCount;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '🏠 Constat Tunisie',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Badge de notification
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: _showNotifications,
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: InsuranceNavigation.buildNotificationBadge(context, _notificationCount),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section de bienvenue
            _buildWelcomeSection(),
            const SizedBox(height: 24),

            // Section des fonctionnalités principales
            _buildMainFeaturesSection(),
            const SizedBox(height: 24),

            // Section assurance
            _buildInsuranceSection(),
            const SizedBox(height: 24),

            // Section actions rapides
            _buildQuickActionsSection(),
          ],
        ),
      ),
    );
  }

  /// 👋 Section de bienvenue
  Widget _buildWelcomeSection() {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? user?.email?.split('@').first ?? 'Utilisateur';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: InsuranceStyles.primaryGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '👋 Bonjour $userName !',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gérez vos assurances et déclarez vos accidents en toute simplicité',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
            ),
          ),
          if (_notificationCount > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Vous avez $_notificationCount nouvelle(s) notification(s)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 🎯 Section des fonctionnalités principales
  Widget _buildMainFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🎯 Fonctionnalités Principales',
          style: InsuranceStyles.titleMedium,
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildFeatureCard(
              title: 'Déclaration',
              subtitle: 'Accident',
              icon: Icons.report_problem,
              color: Colors.red,
              onTap: () => _showComingSoon('Déclaration d\'accident'),
            ),
            _buildFeatureCard(
              title: 'Collaboration',
              subtitle: 'Multi-conducteurs',
              icon: Icons.group,
              color: Colors.purple,
              onTap: () => _showComingSoon('Collaboration'),
            ),
            _buildFeatureCard(
              title: 'Reconstruction',
              subtitle: 'IA Vidéo',
              icon: Icons.smart_toy,
              color: Colors.orange,
              onTap: () => _showComingSoon('Reconstruction IA'),
            ),
            _buildFeatureCard(
              title: 'Historique',
              subtitle: 'Mes constats',
              icon: Icons.history,
              color: Colors.green,
              onTap: () => _showComingSoon('Historique'),
            ),
          ],
        ),
      ],
    );
  }

  /// 🛡️ Section assurance
  Widget _buildInsuranceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🛡️ Gestion Assurance',
          style: InsuranceStyles.titleMedium,
        ),
        const SizedBox(height: 16),
        InsuranceNavigation.buildInsuranceCard(context),
      ],
    );
  }

  /// ⚡ Section actions rapides
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚡ Actions Rapides',
          style: InsuranceStyles.titleMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                'Mes Véhicules',
                Icons.directions_car,
                Colors.blue,
                () => InsuranceNavigation.navigateToMyVehicles(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                'Urgence',
                Icons.emergency,
                Colors.red,
                () => _showEmergencyContacts(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// 🔔 Afficher les notifications
  void _showNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

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
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.notifications, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: InsuranceNotificationService.getUserNotifications(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Aucune notification'),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final notification = snapshot.data![index];
                      return _buildNotificationItem(notification);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isRead = notification['isRead'] ?? false;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isRead ? Colors.grey[200] : Colors.blue[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.notifications,
          color: isRead ? Colors.grey[600] : Colors.blue[600],
        ),
      ),
      title: Text(
        notification['title'] ?? 'Notification',
        style: TextStyle(
          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Text(notification['message'] ?? ''),
      trailing: isRead ? null : Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
      ),
      onTap: () async {
        if (!isRead) {
          await InsuranceNotificationService.markAsRead(notification['id']);
        }
        if (mounted) {
          Navigator.pop(context);
          // Traiter l'action de la notification
        }
      },
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Fonctionnalité à venir'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showEmergencyContacts() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚨 Contacts d\'Urgence'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.local_police, color: Colors.blue),
              title: Text('Police'),
              subtitle: Text('197'),
            ),
            ListTile(
              leading: Icon(Icons.local_hospital, color: Colors.red),
              title: Text('SAMU'),
              subtitle: Text('190'),
            ),
            ListTile(
              leading: Icon(Icons.fire_truck, color: Colors.orange),
              title: Text('Protection Civile'),
              subtitle: Text('198'),
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
}
