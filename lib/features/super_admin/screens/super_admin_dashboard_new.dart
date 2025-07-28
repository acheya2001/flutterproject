import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'global_agence_management_screen.dart';
import 'sync_demo_screen.dart';

/// 👑 Dashboard Super Admin avec vue globale
class SuperAdminDashboardNew extends StatefulWidget {
  const SuperAdminDashboardNew({Key? key}) : super(key: key);

  @override
  State<SuperAdminDashboardNew> createState() => _SuperAdminDashboardNewState();
}

class _SuperAdminDashboardNewState extends State<SuperAdminDashboardNew> {
  Map<String, dynamic> _globalStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGlobalStats();
  }

  /// 📊 Charger les statistiques globales
  Future<void> _loadGlobalStats() async {
    setState(() => _isLoading = true);
    
    try {
      // Compter les compagnies
      final compagniesSnapshot = await FirebaseFirestore.instance
          .collection('compagnies')
          .get();
      
      // Compter les agences
      final agencesSnapshot = await FirebaseFirestore.instance
          .collection('agences')
          .get();
      
      // Compter les utilisateurs par rôle
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      
      final adminCompagnies = usersSnapshot.docs.where((doc) => 
          doc.data()['role'] == 'admin_compagnie').length;
      final adminAgences = usersSnapshot.docs.where((doc) => 
          doc.data()['role'] == 'admin_agence').length;
      final agents = usersSnapshot.docs.where((doc) => 
          doc.data()['role'] == 'agent').length;
      final experts = usersSnapshot.docs.where((doc) => 
          doc.data()['role'] == 'expert').length;
      final conducteurs = usersSnapshot.docs.where((doc) => 
          doc.data()['role'] == 'conducteur').length;
      
      // Compter les agences avec/sans admin
      final agencesAvecAdmin = agencesSnapshot.docs.where((doc) => 
          doc.data()['hasAdminAgence'] == true).length;
      final agencesSansAdmin = agencesSnapshot.docs.where((doc) => 
          doc.data()['hasAdminAgence'] != true).length;
      
      setState(() {
        _globalStats = {
          'totalCompagnies': compagniesSnapshot.docs.length,
          'totalAgences': agencesSnapshot.docs.length,
          'agencesAvecAdmin': agencesAvecAdmin,
          'agencesSansAdmin': agencesSansAdmin,
          'totalUtilisateurs': usersSnapshot.docs.length,
          'adminCompagnies': adminCompagnies,
          'adminAgences': adminAgences,
          'agents': agents,
          'experts': experts,
          'conducteurs': conducteurs,
        };
      });
    } catch (e) {
      debugPrint('Erreur chargement stats: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildDashboardContent(),
    );
  }

  /// 🎨 AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        '👑 Super Admin - Synchronisation Active',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontSize: 18,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _loadGlobalStats,
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          tooltip: 'Actualiser',
        ),
        IconButton(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pushReplacementNamed(context, '/login');
          },
          icon: const Icon(Icons.logout_rounded, color: Colors.white),
          tooltip: 'Déconnexion',
        ),
      ],
    );
  }

  /// ⏳ État de chargement
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
          ),
          SizedBox(height: 16),
          Text(
            'Chargement des données...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// 📱 Contenu du dashboard
  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistiques globales
          _buildGlobalStatsSection(),
          const SizedBox(height: 24),
          
          // Actions principales
          _buildMainActionsSection(),
          const SizedBox(height: 24),
          
          // Gestion des utilisateurs
          _buildUserManagementSection(),
          const SizedBox(height: 24),
          
          // Gestion des agences
          _buildAgencyManagementSection(),
        ],
      ),
    );
  }

  /// 📊 Section statistiques globales
  Widget _buildGlobalStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Vue d\'Ensemble',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          
          // Première ligne de stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Compagnies',
                  _globalStats['totalCompagnies']?.toString() ?? '0',
                  Icons.business_rounded,
                  const Color(0xFF667EEA),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Agences',
                  _globalStats['totalAgences']?.toString() ?? '0',
                  Icons.store_rounded,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Utilisateurs',
                  _globalStats['totalUtilisateurs']?.toString() ?? '0',
                  Icons.people_rounded,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Deuxième ligne de stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Avec Admin',
                  _globalStats['agencesAvecAdmin']?.toString() ?? '0',
                  Icons.admin_panel_settings_rounded,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Sans Admin',
                  _globalStats['agencesSansAdmin']?.toString() ?? '0',
                  Icons.person_off_rounded,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Experts',
                  _globalStats['experts']?.toString() ?? '0',
                  Icons.engineering_rounded,
                  Colors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🎯 Section actions principales
  Widget _buildMainActionsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🚀 Actions Principales',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildActionCard(
                '🌍 Vue Globale Agences',
                Icons.business_center_rounded,
                const Color(0xFF667EEA),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GlobalAgenceManagementScreen(),
                  ),
                ),
              ),

              // Nouvelle carte pour la synchronisation
              _buildSyncCard(),
              _buildActionCard(
                'Gestion Utilisateurs',
                Icons.people_rounded,
                Colors.green,
                () => _showComingSoon('Gestion Utilisateurs'),
              ),
              _buildActionCard(
                'Statistiques BI',
                Icons.analytics_rounded,
                Colors.blue,
                () => _showComingSoon('Statistiques BI'),
              ),
              _buildActionCard(
                'Paramètres Système',
                Icons.settings_rounded,
                Colors.orange,
                () => _showComingSoon('Paramètres Système'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 👥 Section gestion utilisateurs
  Widget _buildUserManagementSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '👥 Répartition des Utilisateurs',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildUserTypeCard(
                  'Admin Compagnies',
                  _globalStats['adminCompagnies']?.toString() ?? '0',
                  Icons.business_rounded,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUserTypeCard(
                  'Admin Agences',
                  _globalStats['adminAgences']?.toString() ?? '0',
                  Icons.store_rounded,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUserTypeCard(
                  'Agents',
                  _globalStats['agents']?.toString() ?? '0',
                  Icons.person_rounded,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🏪 Section gestion agences
  Widget _buildAgencyManagementSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🏪 Gestion des Agences',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GlobalAgenceManagementScreen(),
                  ),
                ),
                icon: const Icon(Icons.launch_rounded, size: 16),
                label: const Text('Voir Tout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildAgencyStatusCard(
                  'Agences avec Admin',
                  _globalStats['agencesAvecAdmin']?.toString() ?? '0',
                  Icons.admin_panel_settings_rounded,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAgencyStatusCard(
                  'Agences sans Admin',
                  _globalStats['agencesSansAdmin']?.toString() ?? '0',
                  Icons.person_off_rounded,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📊 Carte de statistique
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 🎯 Carte d'action
  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  /// 👤 Carte type d'utilisateur
  Widget _buildUserTypeCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 🏪 Carte statut agence
  Widget _buildAgencyStatusCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🚧 Afficher "Bientôt disponible"
  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🚧 $feature'),
        content: const Text('Cette fonctionnalité sera bientôt disponible !'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// 🔄 Carte de synchronisation avec les admins compagnie
  Widget _buildSyncCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.sync_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔄 Synchronisation Temps Réel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Suivez les créations des admins compagnie',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Statistiques de synchronisation
          FutureBuilder<Map<String, int>>(
            future: _getSyncStats(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final stats = snapshot.data!;
                return Row(
                  children: [
                    Expanded(
                      child: _buildSyncStat(
                        'Agences créées',
                        stats['agencesCreated']?.toString() ?? '0',
                        Icons.business_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSyncStat(
                        'Admins auto-créés',
                        stats['adminsAutoCreated']?.toString() ?? '0',
                        Icons.person_add_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSyncStat(
                        'Aujourd\'hui',
                        stats['todayCreations']?.toString() ?? '0',
                        Icons.today_rounded,
                      ),
                    ),
                  ],
                );
              }
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            },
          ),

          const SizedBox(height: 20),

          // Boutons d'accès
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GlobalAgenceManagementScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.visibility_rounded, size: 16),
                  label: const Text('Vue Globale', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF059669),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SyncDemoScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.sync_rounded, size: 16),
                  label: const Text('Démo Sync', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.9),
                    foregroundColor: const Color(0xFF059669),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📊 Statistique de synchronisation
  Widget _buildSyncStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 📈 Obtenir les statistiques de synchronisation
  Future<Map<String, int>> _getSyncStats() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // Agences créées par admin compagnie
      final agencesQuery = await FirebaseFirestore.instance
          .collection('agences')
          .where('origin', isEqualTo: 'admin_compagnie')
          .get();

      // Admins auto-créés
      final adminsQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin_agence')
          .where('origin', isEqualTo: 'auto_creation')
          .get();

      // Créations d'aujourd'hui
      final todayAgencesQuery = await FirebaseFirestore.instance
          .collection('agences')
          .where('origin', isEqualTo: 'admin_compagnie')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      final todayAdminsQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin_agence')
          .where('origin', isEqualTo: 'auto_creation')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      return {
        'agencesCreated': agencesQuery.docs.length,
        'adminsAutoCreated': adminsQuery.docs.length,
        'todayCreations': todayAgencesQuery.docs.length + todayAdminsQuery.docs.length,
      };
    } catch (e) {
      debugPrint('Erreur stats sync: $e');
      return {
        'agencesCreated': 0,
        'adminsAutoCreated': 0,
        'todayCreations': 0,
      };
    }
  }
}
