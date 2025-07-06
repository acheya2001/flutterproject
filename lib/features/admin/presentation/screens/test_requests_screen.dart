import 'package:flutter/material.dart';
import '../../../../core/theme/modern_theme.dart';

/// 🧪 Écran de test simple pour les demandes
class TestRequestsScreen extends StatelessWidget {
  const TestRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Test - Gestion des Demandes'),
        backgroundColor: ModernTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ModernTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.pending_actions,
                      color: ModernTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Interface de test',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ModernTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vérification du fonctionnement de l\'interface',
                          style: TextStyle(
                            color: ModernTheme.textLight,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // État du système
            _buildStatusCard('Firestore', 'Connexion en cours...', Icons.cloud, Colors.orange),
            const SizedBox(height: 12),
            _buildStatusCard('Interface', 'Fonctionnelle ✅', Icons.check_circle, Colors.green),
            const SizedBox(height: 12),
            _buildStatusCard('Navigation', 'OK ✅', Icons.navigation, Colors.green),
            
            const SizedBox(height: 24),
            
            // Actions de test
            Text(
              'Actions de test',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ModernTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildTestButton(
              'Tester la soumission',
              'Aller à l\'écran de demande',
              Icons.send,
              () => Navigator.pushNamed(context, '/professional-request'),
            ),
            const SizedBox(height: 12),
            _buildTestButton(
              'Vérifier Firestore',
              'Ouvrir la console Firebase',
              Icons.storage,
              () => _showFirestoreInfo(context),
            ),
            const SizedBox(height: 12),
            _buildTestButton(
              'Interface complète',
              'Retour à l\'interface normale',
              Icons.dashboard,
              () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, String status, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: color,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            status,
            style: TextStyle(
              color: ModernTheme.textLight,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ModernTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: ModernTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: ModernTheme.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: ModernTheme.textLight,
            ),
          ],
        ),
      ),
    );
  }

  void _showFirestoreInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Information Firestore'),
        content: const Text(
          'Pour résoudre les problèmes Firestore :\n\n'
          '1. Vérifier la connexion internet\n'
          '2. Vérifier les règles Firestore\n'
          '3. Créer des index si nécessaire\n'
          '4. Vérifier la collection "demandes_professionnels"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
