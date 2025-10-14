import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/super_admin_hierarchy_service.dart';
import '../widgets/cleanup_admin_widget.dart';
import 'workflow_test_screen.dart';

/// 👑 Dashboard Super Admin avec vue hiérarchique intégrée
class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({Key? key}) : super(key: key);

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  List<Map<String, dynamic>> _compagnies = [];
  Map<String, dynamic> _globalStats = {};
  bool _isLoading = true;
  Set<String> _expandedCompagnies = {}; // Pour gérer l'expansion des compagnies

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadData();
    });
  }

  /// 📊 Charger toutes les données
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('🔄 Début chargement données Super Admin...');

      // Test direct Firestore pour voir si les compagnies existent
      final compagniesSnapshot = await FirebaseFirestore.instance
          .collection('compagnies_assurance')
          .get();

      debugPrint('📊 Test direct Firestore: ${compagniesSnapshot.docs.length} compagnies trouvées');

      // Charger la hiérarchie complète et les stats globales
      final hierarchy = await SuperAdminHierarchyService.getCompleteHierarchy();
      final stats = await SuperAdminHierarchyService.getGlobalStats();

      if (mounted) setState(() {
        _compagnies = hierarchy;
        _globalStats = stats;
      });

      debugPrint('🏢 Compagnies chargées via service: ${_compagnies.length}');
      debugPrint('📊 Stats globales: $_globalStats');

      for (var compagnie in _compagnies) {
        debugPrint('  - ${compagnie['nom']}: ${(compagnie['agences'] as List?)?.length ?? 0} agences');
      }

      // Si aucune compagnie, afficher un message d'aide
      if (_compagnies.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ℹ️ Aucune compagnie trouvée. Créez d\'abord des compagnies d\'assurance.'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 5),
          ),
        );
      }

    } catch (e) {
      debugPrint('❌ Erreur chargement données: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          '👑 Super Administration',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 20,
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
          // BOUTON PDF DEMO - GROS ET VISIBLE
          Container(
            margin: EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/demo-pdf'),
              icon: Icon(Icons.picture_as_pdf, color: Colors.white),
              label: Text('PDF DEMO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/test-pdf'),
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            tooltip: 'Test PDF',
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WorkflowTestScreen(),
              ),
            ),
            icon: const Icon(Icons.bug_report, color: Colors.white),
            tooltip: 'Test Workflow',
          ),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Actualiser',
          ),
          IconButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/user-type-selection');
            },
            icon: const Icon(Icons.exit_to_app_rounded, color: Colors.white),
            tooltip: 'Retour',
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/demo-pdf'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('PDF DÉMO'),
        tooltip: 'Générer PDF de démonstration complet',
      ),
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
          Text('Chargement du tableau de bord...'),
        ],
      ),
    );
  }

  /// 📱 Contenu principal
  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistiques globales
          _buildGlobalStatsCard(),
          const SizedBox(height: 24),

          // 🧹 Outils de nettoyage des données
          const CleanupAdminWidget(),
          const SizedBox(height: 24),

          // Section Compagnies avec vue hiérarchique
          _buildCompagniesSection(),
        ],
      ),
    );
  }

  /// 📊 Carte des statistiques globales
  Widget _buildGlobalStatsCard() {
    return Container(
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
          const Row(
            children: [
              Icon(Icons.analytics_rounded, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                '📊 Statistiques Globales',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Statistiques en grille
          Row(
            children: [
              Expanded(child: _buildStatItem('Compagnies', _globalStats['totalCompagnies']?.toString() ?? '0', Icons.business_rounded)),
              Expanded(child: _buildStatItem('Agences', _globalStats['totalAgences']?.toString() ?? '0', Icons.store_rounded)),
              Expanded(child: _buildStatItem('Admins Agence', _globalStats['adminAgences']?.toString() ?? '0', Icons.admin_panel_settings_rounded)),
              Expanded(child: _buildStatItem('Agents', _globalStats['agents']?.toString() ?? '0', Icons.people_rounded)),
            ],
          ),

          const SizedBox(height: 20),

          // Bouton PDF Démo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/demo-pdf'),
              icon: const Icon(Icons.auto_awesome, size: 24),
              label: const Text(
                '🇹🇳 GÉNÉRER PDF DÉMO COMPLET',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📈 Item de statistique
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 🏢 Section Compagnies avec vue hiérarchique
  Widget _buildCompagniesSection() {
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
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: Color(0xFF667EEA),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  '🏢 Compagnies d\'Assurance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (_compagnies.isEmpty) ...[
            _buildEmptyState(),
          ] else ...[
            ...(_compagnies.map((compagnie) => _buildCompagnieCard(compagnie))),
          ],
        ],
      ),
    );
  }

  /// 📭 État vide
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.business_rounded,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune compagnie enregistrée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les compagnies d\'assurance et leurs agences apparaîtront ici.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 🏢 Carte de compagnie avec expansion pour agences
  Widget _buildCompagnieCard(Map<String, dynamic> compagnie) {
    final compagnieId = compagnie['id'];
    final isExpanded = _expandedCompagnies.contains(compagnieId);
    final agences = compagnie['agences'] as List<Map<String, dynamic>>? ?? [];
    final stats = compagnie['stats'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // En-tête de la compagnie
          Container(
            padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.business_rounded,
                      color: Color(0xFF667EEA),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          compagnie['nom'] ?? 'Nom non défini',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Code: ${compagnie['code'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildMiniStat('Agences', stats['totalAgences']?.toString() ?? '0', Colors.blue),
                            const SizedBox(width: 12),
                            _buildMiniStat('Avec Admin', stats['agencesAvecAdmin']?.toString() ?? '0', Colors.green),
                            const SizedBox(width: 12),
                            _buildMiniStat('Agents', stats['totalAgents']?.toString() ?? '0', Colors.orange),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedCompagnies.remove(compagnieId);
                        } else {
                          _expandedCompagnies.add(compagnieId);
                        }
                      });
                    },
                    icon: Icon(
                      isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      size: 16,
                    ),
                    label: Text(
                      isExpanded ? 'Masquer' : 'Voir agences',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667EEA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
            ),

          // Section des agences (expandable)
          if (isExpanded) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.store_rounded, color: Color(0xFF059669), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Agences de ${compagnie['nom']} (${agences.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (agences.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Aucune agence créée pour cette compagnie',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ...agences.map((agence) => _buildAgenceItem(agence)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 📊 Mini statistique
  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 🏪 Item d'agence avec admin
  Widget _buildAgenceItem(Map<String, dynamic> agence) {
    final adminAgence = agence['adminAgence'] as Map<String, dynamic>?;
    final hasAdmin = adminAgence != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête agence
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasAdmin ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.store_rounded,
                  color: hasAdmin ? Colors.green : Colors.orange,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agence['nom'] ?? 'Nom non défini',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'Code: ${agence['code'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasAdmin ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasAdmin ? 'AVEC ADMIN' : 'SANS ADMIN',
                  style: TextStyle(
                    color: hasAdmin ? Colors.green : Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Informations de l'agence
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAgenceInfo('📍 Adresse', agence['adresse'] ?? 'Non définie'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAgenceInfo('📧 Email', agence['emailContact'] ?? 'Non défini'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildAgenceInfo('📞 Téléphone', agence['telephone'] ?? 'Non défini'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAgenceInfo('🗺️ Gouvernorat', agence['gouvernorat'] ?? 'Non défini'),
              ),
            ],
          ),

          // Admin agence si présent
          if (hasAdmin) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.admin_panel_settings_rounded, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Admin Agence Affecté',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.green.withOpacity(0.1),
                        child: Text(
                          '${adminAgence!['prenom']?[0] ?? ''}${adminAgence['nom']?[0] ?? ''}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${adminAgence['prenom'] ?? ''} ${adminAgence['nom'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              adminAgence['email'] ?? 'Email non défini',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (adminAgence['telephone'] != null)
                              Text(
                                adminAgence['telephone'],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        adminAgence['isActive'] == true ? Icons.check_circle : Icons.cancel,
                        color: adminAgence['isActive'] == true ? Colors.green : Colors.red,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 📋 Information d'agence
  Widget _buildAgenceInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF1F2937),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

}

