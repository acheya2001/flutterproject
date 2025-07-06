// lib/features/assureur/screens/assureur_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_routes.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../features/auth/providers/auth_provider.dart';
// import '../../insurance/screens/insurance_admin_screen.dart'; // Supprimé
import 'database_stats_screen.dart';

class AssureurHomeScreen extends ConsumerWidget {
  const AssureurHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authProviderInstance = ref.watch(authProvider);
    final user = authProviderInstance.currentUser;
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Tableau de bord',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProviderInstance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de bienvenue
            _buildWelcomeHeader(user),

            const SizedBox(height: 32),

            // Cartes de fonctionnalités
            _buildFeatureCards(context),

            const SizedBox(height: 32),

            // Statistiques rapides
            _buildQuickStats(),
          ],
        ),
      ),
    );
  }

  /// 👋 En-tête de bienvenue
  Widget _buildWelcomeHeader(user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.green[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.business, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenue,',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green[700],
                      ),
                    ),
                    Text(
                      '${user?.prenom} ${user?.nom}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Tableau de bord assureur',
            style: TextStyle(
              fontSize: 16,
              color: Colors.green[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Cartes de fonctionnalités
  Widget _buildFeatureCards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fonctionnalités',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildFeatureCard(
              context,
              title: 'Gestion Contrats',
              subtitle: 'Gérer les contrats d\'assurance',
              icon: Icons.description,
              color: Colors.green,
              onTap: () => Navigator.pushNamed(context, AppRoutes.contractManagement),
            ),
            _buildFeatureCard(
              context,
              title: 'Vérification Véhicules',
              subtitle: 'Vérifier les contrats d\'assurance',
              icon: Icons.search,
              color: Colors.blue,
              onTap: () => Navigator.pushNamed(context, AppRoutes.assureurVehicleVerification),
            ),
            _buildFeatureCard(
              context,
              title: 'Gestion Sinistres',
              subtitle: 'Traiter les déclarations',
              icon: Icons.assignment,
              color: Colors.orange,
              onTap: () => _showComingSoon(context),
            ),
            _buildFeatureCard(
              context,
              title: 'Statistiques DB',
              subtitle: 'Voir les données système',
              icon: Icons.analytics,
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DatabaseStatsScreen()),
              ),
            ),
            _buildFeatureCard(
              context,
              title: 'Administration',
              subtitle: 'Gestion hiérarchie assurance',
              icon: Icons.admin_panel_settings,
              color: Colors.indigo,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: const Text('Admin Assurance')),
                    body: const Center(
                      child: Text('🚧 Interface admin assurance à implémenter'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 🎯 Carte de fonctionnalité
  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.white, color.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📊 Statistiques rapides
  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aperçu rapide',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard('Contrats actifs', '1,234', Colors.green)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('En attente', '56', Colors.orange)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard('Sinistres ce mois', '89', Colors.red)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Nouveaux clients', '23', Colors.blue)),
          ],
        ),
      ],
    );
  }

  /// 📊 Carte de statistique
  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  /// 🚧 Afficher "Bientôt disponible"
  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚧 Fonctionnalité bientôt disponible'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}