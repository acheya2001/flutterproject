import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/config/app_routes.dart';
import '../../auth/providers/hierarchical_auth_provider.dart';
import 'contract_management_screen.dart';
import 'database_stats_screen.dart';
// import '../../insurance/screens/insurance_admin_screen.dart'; // Supprimé

class HierarchicalAgentDashboard extends ConsumerWidget {
  const HierarchicalAgentDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(hierarchicalAuthProvider);
    final agent = authState.currentAgent;
    final agencyStats = ref.watch(agencyStatsProvider);
    final isResponsable = ref.watch(isResponsableProvider);

    if (agent == null) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Tableau de Bord'),
        body: const Center(
          child: Text('Aucun agent connecté'),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Tableau de Bord Agent',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(hierarchicalAuthProvider.notifier).refreshData(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(hierarchicalAuthProvider.notifier).signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.userTypeSelection);
              }
            },
          ),
        ],
      ),
      body: authState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête hiérarchique
                  _buildHierarchicalHeader(agent, authState),
                  const SizedBox(height: 32),

                  // Statistiques de l'agence
                  _buildAgencyStats(agencyStats),
                  const SizedBox(height: 32),

                  // Cartes de fonctionnalités
                  _buildFeatureCards(context, isResponsable),
                  const SizedBox(height: 32),

                  // Informations de l'agent
                  _buildAgentInfo(agent),
                ],
              ),
            ),
    );
  }

  Widget _buildHierarchicalHeader(agent, authState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
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
                  color: Colors.blue[600],
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
                        color: Colors.blue[700],
                      ),
                    ),
                    Text(
                      '${agent.prenom} ${agent.nom}',
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
          
          // Hiérarchie
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildHierarchyRow(Icons.business, agent.compagnie, 'Compagnie'),
                const SizedBox(height: 8),
                _buildHierarchyRow(Icons.location_city, agent.agenceNom, 'Agence'),
                const SizedBox(height: 8),
                _buildHierarchyRow(Icons.location_on, agent.gouvernorat, 'Gouvernorat'),
                const SizedBox(height: 8),
                _buildHierarchyRow(Icons.work, agent.poste, 'Poste'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHierarchyRow(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildAgencyStats(Map<String, String> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistiques de l\'Agence',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard('Agents', stats['agents'] ?? '0', Icons.people, Colors.blue)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Contrats', stats['contrats_total'] ?? '0', Icons.description, Colors.green)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard('Actifs', stats['contrats_actifs'] ?? '0', Icons.check_circle, Colors.green)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Taux', stats['taux_activation'] ?? '0%', Icons.trending_up, Colors.orange)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
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

  Widget _buildFeatureCards(BuildContext context, bool isResponsable) {
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
              title: 'Mes Contrats',
              subtitle: 'Gérer mes contrats d\'assurance',
              icon: Icons.description,
              color: Colors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContractManagementScreen()),
              ),
            ),
            _buildFeatureCard(
              context,
              title: 'Vérification',
              subtitle: 'Vérifier les véhicules',
              icon: Icons.search,
              color: Colors.blue,
              onTap: () => Navigator.pushNamed(context, AppRoutes.assureurVehicleVerification),
            ),
            if (isResponsable) ...[
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
                subtitle: 'Gestion hiérarchie',
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
            ] else ...[
              _buildFeatureCard(
                context,
                title: 'Rapports',
                subtitle: 'Mes rapports d\'activité',
                icon: Icons.assessment,
                color: Colors.orange,
                onTap: () => _showComingSoon(context),
              ),
              _buildFeatureCard(
                context,
                title: 'Support',
                subtitle: 'Aide et assistance',
                icon: Icons.help,
                color: Colors.teal,
                onTap: () => _showComingSoon(context),
              ),
            ],
          ],
        ),
      ],
    );
  }

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
              colors: [Colors.white, color.withOpacity(0.05)],
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
                  color: color.withOpacity(0.1),
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

  Widget _buildAgentInfo(agent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations Agent',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Email', agent.email),
          _buildInfoRow('Téléphone', agent.telephone),
          _buildInfoRow('Matricule', agent.matricule),
          _buildInfoRow('Statut', agent.statut),
          if (agent.dateEmbauche != null)
            _buildInfoRow('Date d\'embauche', agent.dateEmbauche!.toLocal().toString().split(' ')[0]),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚧 Fonctionnalité bientôt disponible'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
