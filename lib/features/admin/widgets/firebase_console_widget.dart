import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 🌐 Widget pour accéder à la console Firebase
class FirebaseConsoleWidget extends StatelessWidget {
  const FirebaseConsoleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.cloud, color: Colors.orange[700], size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Console Firebase',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        'Accédez directement à vos données',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              '🔍 Vérifiez vos données directement dans la console Firebase :',
              style: TextStyle(fontSize: 14),
            ),
            
            const SizedBox(height: 12),
            
            // Liens rapides
            _buildQuickLink(
              '📊 Firestore Database',
              'Voir toutes vos collections et documents',
              'https://console.firebase.google.com/project/constattunisiemail-462921/firestore',
              Icons.storage,
              Colors.blue,
            ),
            
            const SizedBox(height: 8),
            
            _buildQuickLink(
              '👥 Authentication',
              'Gérer les utilisateurs connectés',
              'https://console.firebase.google.com/project/constattunisiemail-462921/authentication',
              Icons.people,
              Colors.green,
            ),
            
            const SizedBox(height: 8),
            
            _buildQuickLink(
              '📈 Analytics',
              'Statistiques d\'utilisation',
              'https://console.firebase.google.com/project/constattunisiemail-462921/analytics',
              Icons.analytics,
              Colors.purple,
            ),
            
            const SizedBox(height: 16),
            
            // Instructions
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
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700], size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Comment vérifier vos données',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Cliquez sur "Firestore Database"\n'
                    '2. Vérifiez les collections:\n'
                    '   • vehicules_assures\n'
                    '   • constats\n'
                    '   • assureurs_compagnies\n'
                    '   • analytics\n'
                    '3. Cliquez sur une collection pour voir les documents\n'
                    '4. Vérifiez que les données sont réalistes',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔗 Lien rapide
  Widget _buildQuickLink(
    String title,
    String description,
    String url,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// 🌐 Lancer une URL
  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Impossible d\'ouvrir le lien');
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'ouverture du lien: $e');
    }
  }
}
