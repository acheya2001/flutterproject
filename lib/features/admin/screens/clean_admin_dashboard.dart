import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hierarchical_structure.dart';
import '../services/hierarchical_admin_service.dart';
import 'clean_demandes_screen.dart';
import 'super_admin_dashboard.dart';

/// 🎯 Dashboard admin propre et moderne
class CleanAdminDashboard extends StatefulWidget {
  const CleanAdminDashboard({super.key});

  @override
  State<CleanAdminDashboard> createState() => _CleanAdminDashboardState();
}

class _CleanAdminDashboardState extends State<CleanAdminDashboard> {
  AdminUser? _currentAdmin;
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);

    try {
      // Obtenir l'admin actuel depuis Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final adminDoc = await FirebaseFirestore.instance
            .collection('admins_users')
            .doc(user.uid)
            .get();

        if (adminDoc.exists) {
          final adminData = adminDoc.data()!;
          final adminType = adminData['type'] as String;

          // Rediriger vers le bon dashboard selon le type
          if (adminType == 'super_admin') {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const SuperAdminDashboard(),
                ),
              );
            }
            return;
          }

          // Pour les autres types d'admin, continuer avec le dashboard normal
          final admin = AdminUser.fromMap(adminData);
          final stats = await HierarchicalAdminService.getAdminStats(admin);
          setState(() {
            _currentAdmin = admin;
            _stats = stats;
          });
        }
      }
    } catch (e) {
      print('❌ Erreur _loadAdminData: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentAdmin == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Erreur: Admin non trouvé'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Retour à la connexion'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_getAdminTitle()),
        backgroundColor: _getAdminColor(),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAdminData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAdminData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 20),
              _buildStatsGrid(),
              const SizedBox(height: 20),
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [_getAdminColor(), _getAdminColor().withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(_getAdminIcon(), color: _getAdminColor()),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenue, ${_currentAdmin!.prenom} ${_currentAdmin!.nom}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getAdminSubtitle(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _currentAdmin!.email,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Demandes en Attente',
          _stats['demandesEnAttente']?.toString() ?? '0',
          Icons.pending_actions,
          Colors.orange,
        ),
        _buildStatCard(
          'Demandes Approuvées',
          _stats['demandesApprouvees']?.toString() ?? '0',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Total Demandes',
          _stats['totalDemandes']?.toString() ?? '0',
          Icons.description,
          Colors.blue,
        ),
        _buildStatCard(
          'Agents Actifs',
          _stats['totalAgents']?.toString() ?? '0',
          Icons.people,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
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
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions Rapides',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          'Gérer les Demandes',
          'Approuver ou rejeter les demandes d\'inscription',
          Icons.pending_actions,
          Colors.orange,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CleanDemandesScreen(admin: _currentAdmin!),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          'Voir les Agents',
          'Liste des agents de votre ${_currentAdmin!.type == AdminType.agence ? 'agence' : 'compagnie'}',
          Icons.people,
          Colors.blue,
          () {
            // TODO: Implémenter la liste des agents
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Liste des agents à implémenter')),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          'Système d\'Assurance',
          'Gérer les compagnies, agences et initialiser le système',
          Icons.business,
          Colors.green,
          () => Navigator.pushNamed(context, '/insurance/system-init'),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          '🧪 Test Formulaire Professionnel',
          'Tester le formulaire de demande de compte professionnel',
          Icons.science,
          Colors.purple,
          () => Navigator.pushNamed(context, '/professional-request'),
        ),

      ],
    );
  }

  Widget _buildActionButton(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  String _getAdminTitle() {
    switch (_currentAdmin!.type) {
      case AdminType.superAdmin:
        return '👑 Super Administrateur';
      case AdminType.compagnie:
        return '🏢 Admin Compagnie';
      case AdminType.agence:
        return '🏪 Admin Agence';
    }
  }

  String _getAdminSubtitle() {
    switch (_currentAdmin!.type) {
      case AdminType.superAdmin:
        return 'Gestion globale du système';
      case AdminType.compagnie:
        return 'Gestion de la compagnie';
      case AdminType.agence:
        return 'Gestion de l\'agence';
    }
  }

  Color _getAdminColor() {
    switch (_currentAdmin!.type) {
      case AdminType.superAdmin:
        return Colors.red;
      case AdminType.compagnie:
        return Colors.blue;
      case AdminType.agence:
        return Colors.green;
    }
  }

  IconData _getAdminIcon() {
    switch (_currentAdmin!.type) {
      case AdminType.superAdmin:
        return Icons.admin_panel_settings;
      case AdminType.compagnie:
        return Icons.business;
      case AdminType.agence:
        return Icons.store;
    }
  }

  Future<void> _logout() async {
    await HierarchicalAdminService.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
