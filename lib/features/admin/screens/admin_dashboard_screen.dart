import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../models/agent_validation_model.dart';
import '../models/admin_model.dart';
import '../../database/screens/database_setup_screen.dart';

import 'agent_validation_screen.dart';
import 'admin_demandes_screen.dart';
import 'admin_hierarchy_setup_screen.dart';

/// 👨‍💼 Écran principal d'administration
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  // Statistiques
  int _demandesEnAttente = 0;
  int _demandesApprouvees = 0;
  int _demandesRejetees = 0;
  int _totalUtilisateurs = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      setState(() => _isLoading = true);

      // Charger les statistiques de validation
      final validationsSnapshot = await FirebaseFirestore.instance
          .collection('agents_validation')
          .get();

      int enAttente = 0;
      int approuvees = 0;
      int rejetees = 0;

      for (final doc in validationsSnapshot.docs) {
        final validation = AgentValidationModel.fromFirestore(doc);
        switch (validation.statut) {
          case ValidationStatus.enAttente:
            enAttente++;
            break;
          case ValidationStatus.approuve:
            approuvees++;
            break;
          case ValidationStatus.rejete:
            rejetees++;
            break;
        }
      }

      // Charger le nombre total d'utilisateurs
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      setState(() {
        _demandesEnAttente = enAttente;
        _demandesApprouvees = approuvees;
        _demandesRejetees = rejetees;
        _totalUtilisateurs = usersSnapshot.docs.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Administration',
        backgroundColor: Colors.deepPurple,
      ),
      body: RefreshIndicator(
        onRefresh: _loadStatistics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête admin
              _buildAdminHeader(user),
              
              const SizedBox(height: 24),
              
              // Statistiques principales
              _buildMainStatistics(),
              
              const SizedBox(height: 24),
              
              // Actions rapides
              _buildQuickActions(),
              
              const SizedBox(height: 24),
              
              // Demandes récentes
              _buildRecentRequests(),
            ],
          ),
        ),
      ),
    );
  }

  /// 👨‍💼 En-tête administrateur
  Widget _buildAdminHeader(user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple[50]!, Colors.deepPurple[100]!],
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple[600],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Administrateur: ${user?.prenom} ${user?.nom}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Supervision et validation du système',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.deepPurple[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📊 Statistiques principales
  Widget _buildMainStatistics() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.deepPurple),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📊 Statistiques Système',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard('En Attente', _demandesEnAttente.toString(), Colors.orange, Icons.pending),
            _buildStatCard('Approuvées', _demandesApprouvees.toString(), Colors.green, Icons.check_circle),
            _buildStatCard('Rejetées', _demandesRejetees.toString(), Colors.red, Icons.cancel),
            _buildStatCard('Utilisateurs', _totalUtilisateurs.toString(), Colors.blue, Icons.people),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// ⚡ Actions rapides
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚡ Actions Rapides',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildActionCard(
              'Demandes d\'Inscription',
              'Approuver les agents',
              Icons.pending_actions,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminDemandesScreen(),
                ),
              ),
            ),
            _buildActionCard(
              'Gestion Permissions',
              'Modifier les permissions',
              Icons.admin_panel_settings,
              Colors.blue,
              () => Navigator.pushNamed(context, '/admin/permissions'),
            ),
            _buildActionCard(
              'Statistiques',
              'Rapports détaillés',
              Icons.analytics,
              Colors.purple,
              () => _showComingSoon(),
            ),
            _buildActionCard(
              'Base de Données',
              'Configuration Firebase',
              Icons.storage,
              Colors.deepOrange,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DatabaseSetupScreen(),
                ),
              ),
            ),

            const SizedBox(height: 12),

            _buildActionCard(
              'Tests Assurance',
              'Tester le système complet',
              Icons.science,
              Colors.purple,
              () => Navigator.pushNamed(context, '/test/insurance'),
            ),

            // Nouveaux écrans d'administration professionnelle
            _buildActionCard(
              'Gestion Compagnies',
              'Gérer les compagnies d\'assurance',
              Icons.business,
              Colors.blue,
              () => Navigator.pushNamed(context, '/admin/compagnies'),
            ),
            _buildActionCard(
              'Config Hiérarchie',
              'Système d\'approbation complexe',
              Icons.admin_panel_settings,
              Colors.red,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminHierarchySetupScreen(),
                ),
              ),
            ),
            _buildActionCard(
              'Test Système Admin',
              'Tester la hiérarchie administrative',
              Icons.admin_panel_settings,
              Colors.red,
              () => Navigator.pushNamed(context, '/admin/test'),
            ),
            _buildActionCard(
              'Initialisation',
              'Initialiser le super admin',
              Icons.rocket_launch,
              Colors.green,
              () => Navigator.pushNamed(context, '/admin/init'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📋 Demandes récentes
  Widget _buildRecentRequests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '📋 Demandes Récentes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AgentValidationScreen(),
                ),
              ),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('agents_validation')
              .where('statut', isEqualTo: 'en_attente')
              .orderBy('createdAt', descending: true)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Aucune demande en attente',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                ),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final validation = AgentValidationModel.fromFirestore(doc);
                return _buildRequestCard(validation);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRequestCard(AgentValidationModel validation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.person_add, color: Colors.orange[700], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  validation.nomComplet,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${validation.compagnieDemandee} - ${validation.delegation}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${validation.joursDepuisCreation}j',
            style: TextStyle(
              fontSize: 12,
              color: validation.isUrgente ? Colors.red : Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚧 Fonctionnalité bientôt disponible'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
