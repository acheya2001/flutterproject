import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/admin_agence_service.dart';
import '../../../services/admin_agence_diagnostic_service.dart';
import 'agence_info_screen.dart';
import 'agents_management_screen.dart';

/// 🏢 Dashboard Admin Agence - Version Moderne
class AdminAgenceDashboard extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const AdminAgenceDashboard({
    Key? key,
    this.userData,
  }) : super(key: key);

  @override
  State<AdminAgenceDashboard> createState() => _AdminAgenceDashboardState();
}

class _AdminAgenceDashboardState extends State<AdminAgenceDashboard> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _agenceData;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _agents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadAllData();
    });
  }

  /// 📊 Charger toutes les données
  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('[ADMIN_AGENCE_DASHBOARD] 🔄 Début chargement données...');
      debugPrint('[ADMIN_AGENCE_DASHBOARD] 👤 UserData: ${widget.userData}');

      // Charger les informations de l'agence
      final agenceInfo = await AdminAgenceService.getAgenceInfo(widget.userData!['uid']);

      if (agenceInfo != null) {
        debugPrint('[ADMIN_AGENCE_DASHBOARD] ✅ Agence trouvée: ${agenceInfo['nom']}');
        _agenceData = agenceInfo;

        // Charger les statistiques
        final stats = await AdminAgenceService.getAgenceStats(agenceInfo['id']);
        _stats = stats;
        debugPrint('[ADMIN_AGENCE_DASHBOARD] 📊 Stats chargées: $stats');

        // Charger les agents
        final agents = await AdminAgenceService.getAgentsOfAgence(agenceInfo['id']);
        _agents = agents;
        debugPrint('[ADMIN_AGENCE_DASHBOARD] 👥 ${agents.length} agents chargés');
      } else {
        debugPrint('[ADMIN_AGENCE_DASHBOARD] ❌ Aucune agence trouvée pour cet admin');
      }

    } catch (e, stackTrace) {
      debugPrint('[ADMIN_AGENCE_DASHBOARD] ❌ Erreur chargement données: $e');
      debugPrint('[ADMIN_AGENCE_DASHBOARD] 📍 StackTrace: $stackTrace');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading ? _buildLoadingScreen() : _buildMainContent(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  /// 🔄 Écran de chargement
  Widget _buildLoadingScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Chargement du dashboard...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📱 Contenu principal
  Widget _buildMainContent() {
    if (_agenceData == null) {
      return _buildErrorScreen();
    }

    switch (_selectedIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return AgenceInfoScreen(
          agenceData: _agenceData!,
          onAgenceUpdated: _loadAllData,
        );
      case 2:
        return AgentsManagementScreen(
          agenceData: _agenceData!,
          userData: widget.userData!,
        );
      default:
        return _buildHomeScreen();
    }
  }

  /// ❌ Écran d'erreur
  Widget _buildErrorScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.business_center_outlined,
                color: Colors.white,
                size: 80,
              ),
              const SizedBox(height: 30),
              const Text(
                'Configuration Agence Manquante',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                'Votre compte admin agence n\'est pas encore associé à une agence.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Informations de débogage
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations du compte :',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Email: ${widget.userData?['email'] ?? 'Non défini'}',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                    ),
                    Text(
                      'Rôle: ${widget.userData?['role'] ?? 'Non défini'}',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                    ),
                    Text(
                      'UID: ${widget.userData?['uid'] ?? 'Non défini'}',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Charge de travail des agents
              _buildAgentsWorkloadSection(),
              const SizedBox(height: 30),

              // Actions
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _repairConfiguration,
                      icon: const Icon(Icons.build),
                      label: const Text('Réparer Configuration'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loadAllData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showDiagnosticReport,
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Rapport Diagnostic'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showLogoutDialog,
                      icon: const Icon(Icons.logout),
                      label: const Text('Se Déconnecter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🏠 Écran d'accueil du dashboard
  Widget _buildHomeScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header avec informations de l'agence
            _buildHeader(),
            
            // Contenu principal avec statistiques
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Statistiques principales
                      _buildStatsCards(),
                      const SizedBox(height: 30),
                      
                      // Actions rapides
                      _buildQuickActions(),
                      const SizedBox(height: 30),

                      // Véhicules en attente
                      _buildPendingVehicles(),
                      const SizedBox(height: 30),

                      // Véhicules approuvés (à affecter)
                      _buildApprovedVehicles(),
                      const SizedBox(height: 30),

                      // Véhicules affectés
                      _buildAssignedVehicles(),
                      const SizedBox(height: 30),

                      // Dernières activités
                      _buildRecentActivities(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📋 Header avec informations de l'agence
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour ${widget.userData!['prenom']} !',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _agenceData!['nom'] ?? 'Agence',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _agenceData!['compagnieInfo']?['nom'] ?? 'Compagnie',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _showLogoutDialog,
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📊 Cartes de statistiques
  Widget _buildStatsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vue d\'ensemble',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Agents',
                '${_stats['totalAgents'] ?? 0}',
                Icons.people_rounded,
                const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildStatCard(
                'Agents Actifs',
                '${_stats['activeAgents'] ?? 0}',
                Icons.person_rounded,
                const Color(0xFF059669),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 📈 Carte de statistique individuelle
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
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
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
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
          'Actions Rapides',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Ajouter Agent',
                Icons.person_add_rounded,
                const Color(0xFF667EEA),
                () => setState(() => _selectedIndex = 2),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildActionCard(
                'Modifier Agence',
                Icons.edit_rounded,
                const Color(0xFF10B981),
                () => setState(() => _selectedIndex = 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Réinitialiser Mot de Passe Agent',
                Icons.lock_reset_rounded,
                const Color(0xFFEF4444),
                () => Navigator.pushNamed(context, '/admin-agence/agent-password-reset'),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Container(), // Espace vide pour l'alignement
            ),
          ],
        ),
      ],
    );
  }

  /// 🎯 Carte d'action rapide
  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 📝 Dernières activités
  Widget _buildRecentActivities() {
    final recentActionsRaw = _stats['recentActions'] ?? [];
    final recentActions = <Map<String, dynamic>>[];

    // Convertir en sécurité
    if (recentActionsRaw is List) {
      for (final item in recentActionsRaw) {
        if (item is Map<String, dynamic>) {
          recentActions.add(item);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dernières Activités',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 15),
        if (recentActions.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Aucune activité récente',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ] else ...[
          ...recentActions.take(3).map((action) => _buildActivityItem(action)),
        ],
      ],
    );
  }

  /// 📋 Item d'activité
  Widget _buildActivityItem(Map<String, dynamic> action) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.person_add_rounded,
              color: Color(0xFF10B981),
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action['description'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Il y a quelques instants',
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

  /// 🔽 Navigation en bas
  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF10B981),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.business_rounded),
          label: 'Mon Agence',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_rounded),
          label: 'Agents',
        ),
      ],
    );
  }

  /// 🚪 Afficher le dialogue de déconnexion
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Déconnexion'),
          ],
        ),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/user-type-selection',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// 🔧 Réparer la configuration automatiquement
  Future<void> _repairConfiguration() async {
    try {
      // Afficher un dialogue de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Réparation en cours...'),
            ],
          ),
        ),
      );

      final success = await AdminAgenceDiagnosticService.repairAdminAgence(widget.userData!['uid']);

      if (mounted) Navigator.pop(context); // Fermer le dialogue de chargement

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Configuration réparée avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Recharger les données
        await _loadAllData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Impossible de réparer automatiquement'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Fermer le dialogue de chargement
      debugPrint('[ADMIN_AGENCE_DASHBOARD] ❌ Erreur réparation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 📊 Afficher le rapport de diagnostic
  Future<void> _showDiagnosticReport() async {
    try {
      final report = await AdminAgenceDiagnosticService.getDiagnosticReport(widget.userData!['uid']);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text('Rapport de Diagnostic'),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                report,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
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
    } catch (e) {
      debugPrint('[ADMIN_AGENCE_DASHBOARD] ❌ Erreur rapport: $e');
    }
  }

  /// 🚗 Section véhicules en attente
  Widget _buildPendingVehicles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.pending_actions,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Véhicules en attente d\'approbation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('vehicules')
              .where('etatCompte', isEqualTo: 'En attente')
              .where('agenceAssuranceId', isEqualTo: _agenceData!['id'])
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Erreur de chargement',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Chargement des véhicules...'),
                  ],
                ),
              );
            }

            final vehicules = snapshot.data?.docs ?? [];

            if (vehicules.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Aucun véhicule en attente',
                      style: TextStyle(color: Colors.green.shade700),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                ...vehicules.take(3).map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildVehicleCard(doc.id, data);
                }),
                if (vehicules.length > 3)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fonctionnalité complète en cours de développement'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                      child: Text('Voir tous les ${vehicules.length} véhicules'),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// ✅ Section véhicules approuvés (à affecter)
  Widget _buildApprovedVehicles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Véhicules approuvés (à affecter)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('vehicules')
              .where('etatCompte', isEqualTo: 'Approuvé par Admin')
              .where('agenceAssuranceId', isEqualTo: _agenceData!['id'])
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Erreur de chargement',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Chargement des véhicules approuvés...'),
                  ],
                ),
              );
            }

            final vehicules = snapshot.data?.docs ?? [];

            if (vehicules.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Tous les véhicules approuvés sont affectés',
                      style: TextStyle(color: Colors.green.shade700),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                ...vehicules.take(3).map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildApprovedVehicleCard(doc.id, data);
                }),
                if (vehicules.length > 3)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fonctionnalité complète en cours de développement'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      child: Text('Voir tous les ${vehicules.length} véhicules approuvés'),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// 📋 Section véhicules affectés aux agents
  Widget _buildAssignedVehicles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.assignment_ind,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Véhicules affectés aux agents',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('vehicules')
              .where('etatCompte', isEqualTo: 'Affecté à Agent')
              .where('agenceAssuranceId', isEqualTo: _agenceData!['id'])
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Erreur de chargement',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Chargement des véhicules affectés...'),
                  ],
                ),
              );
            }

            final vehicules = snapshot.data?.docs ?? [];

            if (vehicules.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Aucun véhicule affecté pour le moment',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                ...vehicules.take(3).map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildAssignedVehicleCard(doc.id, data);
                }),
                if (vehicules.length > 3)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fonctionnalité complète en cours de développement'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      },
                      child: Text('Voir tous les ${vehicules.length} véhicules affectés'),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// ✅ Carte d'un véhicule approuvé (à affecter)
  Widget _buildApprovedVehicleCard(String vehicleId, Map<String, dynamic> data) {
    final approvedAt = (data['dateApprobation'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.check_circle,
              color: Colors.green.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data['marque'] ?? 'N/A'} ${data['modele'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${data['prenomProprietaire'] ?? 'N/A'} ${data['nomProprietaire'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (approvedAt != null)
                  Text(
                    'Approuvé le ${approvedAt.day}/${approvedAt.month}/${approvedAt.year}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            height: 32,
            child: ElevatedButton(
              onPressed: () => _showAssignAgentDialog(vehicleId, data),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: const TextStyle(fontSize: 11),
              ),
              child: const Text('Affecter'),
            ),
          ),
        ],
      ),
    );
  }

  /// 🚗 Carte d'un véhicule en attente
  Widget _buildVehicleCard(String vehicleId, Map<String, dynamic> data) {
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.directions_car,
              color: Colors.orange.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data['marque'] ?? 'N/A'} ${data['modele'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${data['prenomProprietaire'] ?? 'N/A'} ${data['nomProprietaire'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (createdAt != null)
                  Text(
                    'Demandé le ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _approveVehicle(vehicleId, data),
                    icon: const Icon(Icons.check, color: Colors.green, size: 18),
                    tooltip: 'Approuver et Affecter',
                  ),
                  IconButton(
                    onPressed: () => _rejectVehicle(vehicleId, data),
                    icon: const Icon(Icons.close, color: Colors.red, size: 18),
                    tooltip: 'Rejeter',
                  ),
                ],
              ),
              SizedBox(
                width: 80,
                height: 28,
                child: ElevatedButton(
                  onPressed: () => _showAssignAgentDialog(vehicleId, data),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                  child: const Text('Affecter'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📋 Carte d'un véhicule affecté
  Widget _buildAssignedVehicleCard(String vehicleId, Map<String, dynamic> data) {
    final assignedAt = (data['dateAffectation'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.assignment_ind,
              color: Colors.blue.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data['marque'] ?? 'N/A'} ${data['modele'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${data['prenomProprietaire'] ?? 'N/A'} ${data['nomProprietaire'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.person, size: 12, color: Colors.blue.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Agent: ${data['agentAffecteNom'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (assignedAt != null)
                  Text(
                    'Affecté le ${assignedAt.day}/${assignedAt.month}/${assignedAt.year}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              'Affecté',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Approuver et affecter un véhicule automatiquement
  Future<void> _approveVehicle(String vehicleId, Map<String, dynamic> data) async {
    // D'abord, charger les agents et leur charge de travail
    final agents = await _loadAgentsWithWorkload();

    if (agents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Aucun agent disponible dans cette agence'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Trouver l'agent avec la charge de travail la plus faible
    final bestAgent = _findBestAgent(agents);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Expanded(child: Text('Approuver et Affecter')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Véhicule: ${data['marque']} ${data['modele']}'),
            Text('Propriétaire: ${data['prenomProprietaire']} ${data['nomProprietaire']}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      const Text(
                        'Agent recommandé (charge minimale):',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('👤 ${bestAgent['prenom']} ${bestAgent['nom']}'),
                  Text('📊 Charge actuelle: ${bestAgent['workload']} dossiers'),
                  Text('📧 ${bestAgent['email']}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Le véhicule sera approuvé et automatiquement affecté à cet agent.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approuver et Affecter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // 1. Approuver le véhicule ET l'affecter en une seule transaction
        await FirebaseFirestore.instance
            .collection('vehicules')
            .doc(vehicleId)
            .update({
          'etatCompte': 'Affecté à Agent',
          'dateApprobation': FieldValue.serverTimestamp(),
          'approuvePar': _agenceData!['id'],
          'agentAffecteId': bestAgent['id'],
          'agentAffecteNom': '${bestAgent['prenom']} ${bestAgent['nom']}',
          'agentAffecteEmail': bestAgent['email'],
          'dateAffectation': FieldValue.serverTimestamp(),
          'affectePar': _agenceData!['id'],
          'affecteParNom': _agenceData!['adminAgenceNom'],
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 2. Mettre à jour les statistiques de l'agent
        await _updateAgentWorkload(bestAgent['id'], 1);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Véhicule approuvé et affecté à ${bestAgent['prenom']} ${bestAgent['nom']}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// ❌ Rejeter un véhicule
  Future<void> _rejectVehicle(String vehicleId, Map<String, dynamic> data) async {
    final TextEditingController reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Text('Rejeter le véhicule'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pourquoi rejetez-vous le véhicule ${data['marque']} ${data['modele']} ?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison du rejet *',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez saisir une raison'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('vehicules')
            .doc(vehicleId)
            .update({
          'etatCompte': 'Rejeté par Admin',
          'raisonRejet': reasonController.text.trim(),
          'dateRejet': FieldValue.serverTimestamp(),
          'rejetePar': _agenceData!['id'],
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Véhicule rejeté'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// 👤 Dialog pour affecter un agent
  Future<void> _showAssignAgentDialog(String vehicleId, Map<String, dynamic> data) async {
    // Charger la liste des agents de l'agence
    final agents = await _loadAgenceAgents();

    if (agents.isEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 8),
                Text('Aucun agent disponible'),
              ],
            ),
            content: const Text(
              'Aucun agent n\'est disponible dans cette agence pour traiter ce dossier.\n\n'
              'Le véhicule reste approuvé et peut être affecté plus tard.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Compris'),
              ),
            ],
          ),
        );
      }
      return;
    }

    String? selectedAgentId;

    final shouldAssign = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.assignment_ind, color: Colors.blue),
              SizedBox(width: 8),
              Text('Affecter à un agent'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Voulez-vous affecter ce véhicule à un agent ?'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.directions_car, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${data['marque']} ${data['modele']} - ${data['prenomProprietaire']} ${data['nomProprietaire']}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sélectionnez un agent :',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedAgentId,
                decoration: const InputDecoration(
                  labelText: 'Agent responsable',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                items: agents.map((agent) {
                  return DropdownMenuItem<String>(
                    value: agent['id'],
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            '${agent['prenom']?[0] ?? ''}${agent['nom']?[0] ?? ''}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${agent['prenom']} ${agent['nom']}'),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (mounted) setState(() {
                    selectedAgentId = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Plus tard'),
            ),
            ElevatedButton(
              onPressed: selectedAgentId != null
                  ? () => Navigator.of(context).pop(true)
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Affecter', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (shouldAssign == true && selectedAgentId != null) {
      await _assignVehicleToAgent(vehicleId, selectedAgentId!, agents);
    }
  }

  /// 👥 Charger la liste des agents de l'agence
  Future<List<Map<String, dynamic>>> _loadAgenceAgents() async {
    try {
      final agentsQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('agenceId', isEqualTo: _agenceData!['id'])
          .where('statut', isEqualTo: 'actif')
          .get();

      final agents = <Map<String, dynamic>>[];

      for (final doc in agentsQuery.docs) {
        final agentData = doc.data();
        agentData['id'] = doc.id;
        agents.add(agentData);
      }

      return agents;
    } catch (e) {
      debugPrint('[ADMIN_AGENCE] ❌ Erreur chargement agents: $e');
      return [];
    }
  }

  /// 📋 Affecter un véhicule à un agent
  Future<void> _assignVehicleToAgent(String vehicleId, String agentId, List<Map<String, dynamic>> agents) async {
    try {
      final selectedAgent = agents.firstWhere((agent) => agent['id'] == agentId);

      await FirebaseFirestore.instance
          .collection('vehicules')
          .doc(vehicleId)
          .update({
        'etatCompte': 'Affecté à Agent',
        'agentAffecteId': agentId,
        'agentAffecteNom': '${selectedAgent['prenom']} ${selectedAgent['nom']}',
        'agentAffecteEmail': selectedAgent['email'],
        'dateAffectation': FieldValue.serverTimestamp(),
        'affectePar': _agenceData!['id'],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Véhicule affecté à ${selectedAgent['prenom']} ${selectedAgent['nom']}'),
            backgroundColor: Colors.blue,
            action: SnackBarAction(
              label: 'Voir',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Naviguer vers les véhicules affectés
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de l\'affectation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 📊 Charger les agents avec leur charge de travail
  Future<List<Map<String, dynamic>>> _loadAgentsWithWorkload() async {
    try {
      // Récupérer tous les agents actifs de l'agence
      final agentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('agenceId', isEqualTo: _agenceData!['id'])
          .where('status', isEqualTo: 'actif')
          .get();

      List<Map<String, dynamic>> agentsWithWorkload = [];

      for (final agentDoc in agentsSnapshot.docs) {
        final agentData = agentDoc.data();

        // Compter les véhicules affectés mais non traités
        final vehiculesAffectesSnapshot = await FirebaseFirestore.instance
            .collection('vehicules')
            .where('agentAffecteId', isEqualTo: agentDoc.id)
            .where('etatCompte', isEqualTo: 'Affecté à Agent')
            .get();

        // Compter les contrats actifs gérés par l'agent
        final contratsActifsSnapshot = await FirebaseFirestore.instance
            .collection('contrats')
            .where('agentId', isEqualTo: agentDoc.id)
            .where('statutContrat', isEqualTo: 'Actif')
            .get();

        // Calculer la charge totale
        final workload = vehiculesAffectesSnapshot.docs.length + contratsActifsSnapshot.docs.length;

        agentsWithWorkload.add({
          'id': agentDoc.id,
          'nom': agentData['nom'],
          'prenom': agentData['prenom'],
          'email': agentData['email'],
          'workload': workload,
          'vehiculesAffectes': vehiculesAffectesSnapshot.docs.length,
          'contratsActifs': contratsActifsSnapshot.docs.length,
        });
      }

      // Trier par charge de travail croissante
      agentsWithWorkload.sort((a, b) => a['workload'].compareTo(b['workload']));

      print('🔍 [WORKLOAD] Agents avec charge de travail:');
      for (final agent in agentsWithWorkload) {
        print('🔍 [WORKLOAD] ${agent['prenom']} ${agent['nom']}: ${agent['workload']} dossiers (${agent['vehiculesAffectes']} véhicules + ${agent['contratsActifs']} contrats)');
      }

      return agentsWithWorkload;
    } catch (e) {
      print('❌ [WORKLOAD] Erreur chargement agents: $e');
      return [];
    }
  }

  /// 🎯 Trouver le meilleur agent (charge minimale)
  Map<String, dynamic> _findBestAgent(List<Map<String, dynamic>> agents) {
    // L'agent avec la charge la plus faible est déjà en premier (trié)
    final bestAgent = agents.first;

    print('🎯 [BEST_AGENT] Agent sélectionné: ${bestAgent['prenom']} ${bestAgent['nom']} (${bestAgent['workload']} dossiers)');

    return bestAgent;
  }

  /// 📈 Mettre à jour la charge de travail d'un agent
  Future<void> _updateAgentWorkload(String agentId, int increment) async {
    try {
      // Cette méthode peut être utilisée pour maintenir des statistiques
      // Pour l'instant, nous comptons en temps réel, mais on pourrait optimiser
      // en maintenant un compteur dans le document agent

      final agentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(agentId)
          .get();

      if (agentDoc.exists) {
        final currentWorkload = agentDoc.data()?['workload'] ?? 0;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(agentId)
            .update({
          'workload': currentWorkload + increment,
          'lastAssignedAt': FieldValue.serverTimestamp(),
        });

        print('📈 [WORKLOAD] Agent $agentId: workload mis à jour (+$increment)');
      }
    } catch (e) {
      print('❌ [WORKLOAD] Erreur mise à jour workload: $e');
    }
  }

  /// 📊 Section charge de travail des agents
  Widget _buildAgentsWorkloadSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.orange.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Charge de Travail des Agents',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    Text(
                      'Répartition automatique basée sur la charge',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Liste des agents avec charge
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _loadAgentsWithWorkload(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Chargement des statistiques...',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Erreur de chargement des statistiques',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final agents = snapshot.data ?? [];

              if (agents.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun agent dans cette agence',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: agents.map((agent) => _buildAgentWorkloadCard(agent)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 👤 Carte de charge de travail d'un agent
  Widget _buildAgentWorkloadCard(Map<String, dynamic> agent) {
    final workload = agent['workload'] as int;
    final vehiculesAffectes = agent['vehiculesAffectes'] as int;
    final contratsActifs = agent['contratsActifs'] as int;

    // Déterminer la couleur selon la charge
    Color statusColor;
    String statusText;
    if (workload == 0) {
      statusColor = Colors.green;
      statusText = 'Disponible';
    } else if (workload <= 3) {
      statusColor = Colors.orange;
      statusText = 'Charge normale';
    } else {
      statusColor = Colors.red;
      statusText = 'Charge élevée';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar et infos agent
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.person,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Informations
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${agent['prenom']} ${agent['nom']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  agent['email'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Statistiques
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$workload',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              const Text(
                'dossiers',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$vehiculesAffectes véhicules',
                style: const TextStyle(fontSize: 10),
              ),
              Text(
                '$contratsActifs contrats',
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

